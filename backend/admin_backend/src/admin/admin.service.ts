import { createHash } from 'node:crypto';

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminNotificationAudience,
  AdminNotificationStatus,
  CampaignKind,
  CampaignStatus,
  OrderStatus,
  PayoutStatus,
  Prisma,
  Role as PrismaRole,
  StorefrontType,
  SupportPriority,
  SupportStatus,
  User as PrismaUser,
  VendorApprovalStatus,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service';

type JsonRecord = Record<string, unknown>;
type CsvValue = string | number | boolean | null | undefined;
type CsvRow = Record<string, CsvValue>;

const SETTINGS_DEFAULTS = {
  maintenanceMode: false,
  supportEmail: 'destek@sepetpro.app',
  supportPhone: '+90 850 000 00 00',
  announcementBanner: '',
  defaultCommissionRate: 12,
  notificationsEnabled: true,
};

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboardSummary() {
    const [businesses, orders, campaigns, users, supportOpenCount] = await Promise.all([
      this.prisma.vendor.findMany({
        include: {
          operators: {
            select: {
              id: true,
            },
          },
          _count: {
            select: {
              products: true,
              orders: true,
              campaigns: true,
              events: true,
            },
          },
        },
        orderBy: [{ displayOrder: 'asc' }, { createdAt: 'desc' }],
      }),
      this.prisma.order.findMany({
        include: {
          vendor: {
            select: { id: true, name: true },
          },
          user: {
            select: { id: true, email: true, displayName: true },
          },
          pickupPoint: {
            select: { label: true },
          },
          items: true,
        },
        orderBy: { createdAt: 'desc' },
        take: 6,
      }),
      this.prisma.vendorCampaign.findMany({
        include: {
          vendor: {
            select: { id: true, name: true, storefrontType: true },
          },
        },
        orderBy: { updatedAt: 'desc' },
        take: 6,
      }),
      this.prisma.user.findMany({
        where: { role: { not: PrismaRole.ADMIN } },
        select: {
          id: true,
          role: true,
        },
      }),
      this.prisma.supportTicket.count({
        where: { status: { in: [SupportStatus.OPEN, SupportStatus.IN_PROGRESS] } },
      }),
    ]);

    const completedOrders = await this.prisma.order.findMany({
      where: { status: OrderStatus.COMPLETED },
      select: { totalAmount: true },
    });

    return {
      metrics: {
        grossVolume: completedOrders.reduce(
          (total, order) => total + Number(order.totalAmount),
          0,
        ),
        totalBusinesses: businesses.length,
        activeBusinesses: businesses.filter(
          (business) =>
            business.isActive &&
            business.approvalStatus === VendorApprovalStatus.APPROVED,
        ).length,
        pendingBusinesses: businesses.filter(
          (business) => business.approvalStatus === VendorApprovalStatus.PENDING,
        ).length,
        totalUsers: users.length,
        activeCampaigns: campaigns.filter(
          (campaign) => campaign.status === CampaignStatus.ACTIVE,
        ).length,
        openSupportTickets: supportOpenCount,
      },
      recentBusinesses: businesses.slice(0, 5).map((business) => this.toBusinessListItem(business)),
      recentOrders: orders.map((order) => this.toOrderPayload(order)),
      topCampaigns: campaigns.map((campaign) => this.toCampaignPayload(campaign)),
    };
  }

  async listBusinesses(query: JsonRecord = {}) {
    const where: Prisma.VendorWhereInput = {};
    const search = this.optionalString(query.q || query.search);
    const approvalStatus = this.optionalVendorApprovalStatus(query.approvalStatus);
    const storefrontType = this.optionalStorefrontType(query.storefrontType);
    const isActive = this.optionalBoolean(query.isActive);
    const city = this.optionalString(query.city);
    const district = this.optionalString(query.district);

    if (approvalStatus) {
      where.approvalStatus = approvalStatus;
    }
    if (storefrontType) {
      where.storefrontType = storefrontType;
    }
    if (isActive !== undefined) {
      where.isActive = isActive;
    }
    if (city) {
      where.city = { contains: city, mode: 'insensitive' };
    }
    if (district) {
      where.district = { contains: district, mode: 'insensitive' };
    }
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { category: { contains: search, mode: 'insensitive' } },
        { city: { contains: search, mode: 'insensitive' } },
        { district: { contains: search, mode: 'insensitive' } },
      ];
    }

    const paging = this.parsePaging(query);
    const findArgs = {
      where,
      include: {
        operators: {
          select: { id: true },
        },
        _count: {
          select: {
            products: true,
            orders: true,
            campaigns: true,
            events: true,
          },
        },
      },
      orderBy: [{ displayOrder: 'asc' as const }, { createdAt: 'desc' as const }],
      take: paging?.pageSize ?? this.parseTake(query.take ?? query.limit, 250),
      ...(paging ? { skip: (paging.page - 1) * paging.pageSize } : {}),
    };
    const [businesses, total] = await Promise.all([
      this.prisma.vendor.findMany(findArgs),
      paging ? this.prisma.vendor.count({ where }) : Promise.resolve(0),
    ]);
    const activeOrderCounts = await this.getOpenOrderCountByVendor();
    const items = businesses.map((business) =>
      this.toBusinessListItem(business, activeOrderCounts.get(business.id) ?? 0),
    );
    return paging ? this.toPagedResponse(items, total, paging) : items;
  }

  async createBusiness(adminUser: PrismaUser, payload: JsonRecord) {
    const name = this.requireString(payload.name, 'İşletme adı zorunludur');
    const storefrontType = this.parseStorefrontType(payload.storefrontType);
    const slug = await this.ensureUniqueVendorSlug(
      this.slugify(this.optionalString(payload.slug) || name),
    );
    const approvalStatus = this.parseVendorApprovalStatus(payload.approvalStatus, true);
    const category =
      this.optionalString(payload.category) ||
      (storefrontType === StorefrontType.MARKET ? 'Market' : 'Restoran');

    const created = await this.prisma.$transaction(async (tx) => {
      const vendor = await tx.vendor.create({
        data: {
          name,
          slug,
          category,
          city: this.optionalString(payload.city) || null,
          district: this.optionalString(payload.district) || null,
          storefrontType,
          subtitle: this.optionalString(payload.subtitle) || null,
          imageUrl: this.optionalString(payload.imageUrl) || null,
          announcement: this.optionalString(payload.announcement) || null,
          workingHoursLabel: this.optionalString(payload.workingHoursLabel) || null,
          isActive: this.parseBoolean(payload.isActive, true),
          approvalStatus,
        },
      });

      await tx.pickupPoint.create({
        data: {
          vendorId: vendor.id,
          label: this.optionalString(payload.pickupPointLabel) || 'Ana teslim noktası',
          address:
            this.optionalString(payload.pickupPointAddress) || 'Adres bilgisi henüz girilmedi',
          isActive: true,
        },
      });

      const operatorEmail = this.optionalString(payload.operatorEmail);
      if (operatorEmail) {
        const password = this.requireString(
          payload.operatorPassword,
          'Operatör şifresi zorunludur',
        );
        await tx.user.create({
          data: {
            email: operatorEmail.toLowerCase(),
            passwordHash: await bcrypt.hash(password, 10),
            displayName:
              this.optionalString(payload.operatorDisplayName) || `${name} Operasyon`,
            phone: this.optionalString(payload.operatorPhone) || null,
            role: PrismaRole.VENDOR,
            vendorId: vendor.id,
            notificationsEnabled: true,
          },
        });
      }

      return tx.vendor.findUniqueOrThrow({
        where: { id: vendor.id },
        include: {
          operators: { select: { id: true } },
          _count: {
            select: {
              products: true,
              orders: true,
              campaigns: true,
              events: true,
            },
          },
        },
      });
    });

    await this.logAction(adminUser.id, 'business.create', 'vendor', created.id, {
      name: created.name,
    });
    return this.toBusinessListItem(created, 0);
  }

  async updateBusiness(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    const existing = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        pickupPoints: {
          orderBy: { createdAt: 'asc' },
        },
        operators: { select: { id: true } },
        _count: {
          select: {
            products: true,
            orders: true,
            campaigns: true,
            events: true,
          },
        },
      },
    });
    if (!existing) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.vendor.update({
        where: { id: vendorId },
        data: {
          ...(payload.name !== undefined ? { name: this.requireString(payload.name, 'İşletme adı zorunludur') } : {}),
          ...(payload.category !== undefined
            ? { category: this.requireString(payload.category, 'Kategori zorunludur') }
            : {}),
          ...(payload.storefrontType !== undefined
            ? { storefrontType: this.parseStorefrontType(payload.storefrontType) }
            : {}),
          ...(payload.city !== undefined ? { city: this.optionalString(payload.city) || null } : {}),
          ...(payload.district !== undefined
            ? { district: this.optionalString(payload.district) || null }
            : {}),
          ...(payload.subtitle !== undefined
            ? { subtitle: this.optionalString(payload.subtitle) || null }
            : {}),
          ...(payload.imageUrl !== undefined
            ? { imageUrl: this.optionalString(payload.imageUrl) || null }
            : {}),
          ...(payload.announcement !== undefined
            ? { announcement: this.optionalString(payload.announcement) || null }
            : {}),
          ...(payload.workingHoursLabel !== undefined
            ? { workingHoursLabel: this.optionalString(payload.workingHoursLabel) || null }
            : {}),
          ...(payload.isActive !== undefined
            ? { isActive: this.parseBoolean(payload.isActive, existing.isActive) }
            : {}),
          ...(payload.approvalStatus !== undefined
            ? { approvalStatus: this.parseVendorApprovalStatus(payload.approvalStatus) }
            : {}),
          ...(payload.suspendedReason !== undefined
            ? { suspendedReason: this.optionalString(payload.suspendedReason) || null }
            : {}),
        },
      });

      const pickupPoint = existing.pickupPoints[0];
      if (pickupPoint && (payload.pickupPointLabel !== undefined || payload.pickupPointAddress !== undefined)) {
        await tx.pickupPoint.update({
          where: { id: pickupPoint.id },
          data: {
            ...(payload.pickupPointLabel !== undefined
              ? { label: this.optionalString(payload.pickupPointLabel) || pickupPoint.label }
              : {}),
            ...(payload.pickupPointAddress !== undefined
              ? {
                  address:
                    this.optionalString(payload.pickupPointAddress) || pickupPoint.address,
                }
              : {}),
          },
        });
      }
    });

    await this.logAction(adminUser.id, 'business.update', 'vendor', vendorId, payload);
    return this.getBusinessProfile(vendorId);
  }

  async bulkUpdateBusinesses(adminUser: PrismaUser, payload: JsonRecord) {
    const vendorIds = this.requiredIdArray(payload.vendorIds || payload.ids, 'İşletme seçimi zorunludur');
    const patch = this.objectPayload(payload.patch || payload);
    const data: Prisma.VendorUpdateManyMutationInput = {
      ...(patch.isActive !== undefined
        ? { isActive: this.parseBoolean(patch.isActive, true) }
        : {}),
      ...(patch.approvalStatus !== undefined
        ? { approvalStatus: this.parseVendorApprovalStatus(patch.approvalStatus) }
        : {}),
      ...(patch.suspendedReason !== undefined
        ? { suspendedReason: this.optionalString(patch.suspendedReason) || null }
        : {}),
    };
    if (Object.keys(data).length === 0) {
      throw new BadRequestException('Toplu işletme güncellemesi için alan gönderilmedi');
    }
    const result = await this.prisma.vendor.updateMany({
      where: { id: { in: vendorIds } },
      data,
    });
    await this.logAction(adminUser.id, 'business.bulk.update', 'vendor', 'bulk', {
      vendorIds,
      data,
      updatedCount: result.count,
    });
    return { updatedCount: result.count };
  }

  async getBusinessOverview(vendorId: string) {
    const [profile, orders, products, campaigns, bankAccounts] = await Promise.all([
      this.getBusinessProfile(vendorId),
      this.listBusinessOrders(vendorId),
      this.listBusinessProducts(vendorId),
      this.listBusinessCampaigns(vendorId),
      this.prisma.vendorBankAccount.findMany({
        where: { vendorId },
        orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
      }),
    ]);

    const grossRevenue = orders
      .filter((order) => order.status === OrderStatus.COMPLETED)
      .reduce((total, order) => total + order.totalAmount, 0);
    const lowStockProducts = products.products.filter(
      (product) =>
        product.trackStock &&
        product.availableQuantity > 0 &&
        product.availableQuantity <= product.reorderLevel,
    );

    return {
      business: profile.business,
      operators: profile.operators,
      pickupPoints: profile.pickupPoints,
      metrics: {
        grossRevenue,
        totalOrders: orders.length,
        activeOrders: orders.filter((order) => this.isOpenOrder(order.status)).length,
        totalProducts: products.products.length,
        activeCampaigns: campaigns.filter(
          (campaign) => campaign.status === CampaignStatus.ACTIVE,
        ).length,
        lowStockProducts: lowStockProducts.length,
      },
      recentOrders: orders.slice(0, 6),
      lowStockProducts: lowStockProducts.slice(0, 6),
      bankAccounts: bankAccounts.map((account) => ({
        id: account.id,
        holderName: account.holderName,
        bankName: account.bankName,
        iban: account.iban,
        isDefault: account.isDefault,
      })),
    };
  }

  async listBusinessOrders(vendorId: string) {
    await this.ensureVendor(vendorId);
    const orders = await this.prisma.order.findMany({
      where: { vendorId },
      include: {
        vendor: {
          select: { id: true, name: true },
        },
        user: {
          select: { id: true, displayName: true, email: true },
        },
        pickupPoint: {
          select: { label: true },
        },
        items: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    return orders.map((order) => this.toOrderPayload(order));
  }

  async updateBusinessOrderStatus(
    adminUser: PrismaUser,
    vendorId: string,
    orderId: string,
    payload: JsonRecord,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, vendorId: true },
    });
    if (!order || order.vendorId !== vendorId) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }

    const status = this.parseOrderStatus(payload.status);
    await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status,
        etaLabel: this.etaLabelForStatus(status),
      },
    });
    await this.logAction(adminUser.id, 'order.status.update', 'order', orderId, {
      status,
      vendorId,
    });
    return this.getOrderById(orderId);
  }

  async bulkUpdateOrderStatus(adminUser: PrismaUser, payload: JsonRecord) {
    const orderIds = this.requiredIdArray(payload.orderIds || payload.ids, 'Sipariş seçimi zorunludur');
    const status = this.parseOrderStatus(payload.status);
    const result = await this.prisma.order.updateMany({
      where: { id: { in: orderIds } },
      data: {
        status,
        etaLabel: this.etaLabelForStatus(status),
      },
    });
    await this.logAction(adminUser.id, 'order.bulk.status.update', 'order', 'bulk', {
      orderIds,
      status,
      updatedCount: result.count,
    });
    return { updatedCount: result.count };
  }

  async listBusinessSections(vendorId: string) {
    await this.ensureVendor(vendorId);
    const sections = await this.prisma.catalogSection.findMany({
      where: { vendorId },
      orderBy: [{ displayOrder: 'asc' }, { label: 'asc' }],
    });
    return sections.map((section) => ({
      id: section.id,
      key: section.key,
      label: section.label,
      displayOrder: section.displayOrder,
      isActive: section.isActive,
      createdAt: section.createdAt.toISOString(),
      updatedAt: section.updatedAt.toISOString(),
    }));
  }

  async createBusinessSection(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    await this.ensureVendor(vendorId);
    const label = this.requireString(payload.label, 'Bölüm adı zorunludur');
    const key = await this.ensureUniqueSectionKey(
      vendorId,
      this.slugify(this.optionalString(payload.key) || label),
    );
    const section = await this.prisma.catalogSection.create({
      data: {
        vendorId,
        label,
        key,
        displayOrder: this.parseInteger(payload.displayOrder, 0),
        isActive: this.parseBoolean(payload.isActive, true),
      },
    });
    await this.logAction(adminUser.id, 'section.create', 'catalog-section', section.id, {
      vendorId,
      label,
    });
    return {
      id: section.id,
      key: section.key,
      label: section.label,
      displayOrder: section.displayOrder,
      isActive: section.isActive,
      createdAt: section.createdAt.toISOString(),
      updatedAt: section.updatedAt.toISOString(),
    };
  }

  async updateBusinessSection(
    adminUser: PrismaUser,
    vendorId: string,
    sectionId: string,
    payload: JsonRecord,
  ) {
    const existing = await this.prisma.catalogSection.findUnique({
      where: { id: sectionId },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Section ${sectionId} not found`);
    }

    const nextKey =
      payload.key !== undefined
        ? await this.ensureUniqueSectionKey(
            vendorId,
            this.slugify(this.requireString(payload.key, 'Bölüm anahtarı zorunludur')),
            sectionId,
          )
        : undefined;
    const updated = await this.prisma.catalogSection.update({
      where: { id: sectionId },
      data: {
        ...(payload.label !== undefined
          ? { label: this.requireString(payload.label, 'Bölüm adı zorunludur') }
          : {}),
        ...(nextKey ? { key: nextKey } : {}),
        ...(payload.displayOrder !== undefined
          ? { displayOrder: this.parseInteger(payload.displayOrder, existing.displayOrder) }
          : {}),
        ...(payload.isActive !== undefined
          ? { isActive: this.parseBoolean(payload.isActive, existing.isActive) }
          : {}),
      },
    });
    await this.logAction(adminUser.id, 'section.update', 'catalog-section', sectionId, payload);
    return {
      id: updated.id,
      key: updated.key,
      label: updated.label,
      displayOrder: updated.displayOrder,
      isActive: updated.isActive,
      createdAt: updated.createdAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString(),
    };
  }

  async listBusinessProducts(vendorId: string) {
    const vendor = await this.ensureVendor(vendorId);
    const [sections, products] = await Promise.all([
      this.listBusinessSections(vendorId),
      this.prisma.product.findMany({
        where: { vendorId },
        include: {
          catalogSection: true,
          inventory: true,
        },
        orderBy: [{ displayOrder: 'asc' }, { title: 'asc' }],
      }),
    ]);
    const categories = Array.from(
      new Set<string>(
        [vendor.category, ...products.map((product) => product.kind)]
          .map((item) => item.trim())
          .filter((item) => item.length > 0),
      ),
    );

    return {
      businessId: vendorId,
      sections,
      categories,
      products: products.map((product) => this.toProductPayload(product)),
    };
  }

  async createBusinessProduct(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    const vendor = await this.ensureVendor(vendorId);
    const sectionId = this.optionalString(payload.sectionId);
    if (sectionId) {
      await this.ensureSection(vendorId, sectionId);
    }

    const title = this.requireString(payload.title, 'Ürün adı zorunludur');
    const unitPrice = this.parseDecimal(payload.unitPrice, 'Ürün fiyatı zorunludur');
    const sku = await this.ensureUniqueSku(
      this.optionalString(payload.sku) || `${this.slugify(title)}-${Date.now()}`,
    );
    const product = await this.prisma.product.create({
      data: {
        vendorId,
        catalogSectionId: sectionId || null,
        title,
        description: this.optionalString(payload.description) || null,
        unitPrice,
        imageUrl: this.optionalImageUrl(payload.imageUrl) || null,
        kind: this.optionalString(payload.category) || vendor.category,
        sku,
        barcode: this.optionalString(payload.barcode) || null,
        externalCode: this.optionalString(payload.externalCode) || null,
        displaySubtitle: this.optionalString(payload.displaySubtitle) || null,
        displayBadge: this.optionalString(payload.displayBadge) || null,
        displayOrder: this.parseInteger(payload.displayOrder, 0),
        isFeatured: this.parseBoolean(payload.isFeatured, false),
        isVisibleInApp: this.parseBoolean(payload.isVisibleInApp, true),
        trackStock: this.parseBoolean(payload.trackStock, true),
        reorderLevel: this.parseInteger(payload.reorderLevel, 3),
        isArchived: this.parseBoolean(payload.isArchived, false),
      },
      include: {
        catalogSection: true,
        inventory: true,
      },
    });

    await this.prisma.inventoryStock.create({
      data: {
        productId: product.id,
        vendorId,
        locationId: `${vendorId}:main`,
        locationLabel: vendor.pickupPoints[0]?.label ?? 'Ana depo',
        onHand: this.parseInteger(payload.initialStock, 0),
        reserved: 0,
      },
    });
    await this.logAction(adminUser.id, 'product.create', 'product', product.id, {
      vendorId,
      title,
    });
    return this.getProductById(product.id);
  }

  async updateBusinessProduct(
    adminUser: PrismaUser,
    vendorId: string,
    productId: string,
    payload: JsonRecord,
  ) {
    const existing = await this.prisma.product.findUnique({
      where: { id: productId },
      include: {
        inventory: true,
      },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Product ${productId} not found`);
    }
    const sectionId = this.optionalString(payload.sectionId);
    if (sectionId) {
      await this.ensureSection(vendorId, sectionId);
    }
    if (payload.sku !== undefined && this.optionalString(payload.sku)) {
      await this.ensureUniqueSku(this.requireString(payload.sku, 'SKU zorunludur'), productId);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.product.update({
        where: { id: productId },
        data: {
          ...(payload.title !== undefined
            ? { title: this.requireString(payload.title, 'Ürün adı zorunludur') }
            : {}),
          ...(payload.description !== undefined
            ? { description: this.optionalString(payload.description) || null }
            : {}),
          ...(payload.unitPrice !== undefined
            ? { unitPrice: this.parseDecimal(payload.unitPrice, 'Ürün fiyatı zorunludur') }
            : {}),
          ...(payload.imageUrl !== undefined
            ? { imageUrl: this.optionalImageUrl(payload.imageUrl) || null }
            : {}),
          ...(payload.category !== undefined
            ? { kind: this.requireString(payload.category, 'Kategori zorunludur') }
            : {}),
          ...(payload.sku !== undefined
            ? { sku: this.requireString(payload.sku, 'SKU zorunludur') }
            : {}),
          ...(payload.barcode !== undefined
            ? { barcode: this.optionalString(payload.barcode) || null }
            : {}),
          ...(payload.externalCode !== undefined
            ? { externalCode: this.optionalString(payload.externalCode) || null }
            : {}),
          ...(payload.displaySubtitle !== undefined
            ? { displaySubtitle: this.optionalString(payload.displaySubtitle) || null }
            : {}),
          ...(payload.displayBadge !== undefined
            ? { displayBadge: this.optionalString(payload.displayBadge) || null }
            : {}),
          ...(payload.displayOrder !== undefined
            ? { displayOrder: this.parseInteger(payload.displayOrder, existing.displayOrder) }
            : {}),
          ...(payload.isFeatured !== undefined
            ? { isFeatured: this.parseBoolean(payload.isFeatured, existing.isFeatured) }
            : {}),
          ...(payload.isVisibleInApp !== undefined
            ? {
                isVisibleInApp: this.parseBoolean(
                  payload.isVisibleInApp,
                  existing.isVisibleInApp,
                ),
              }
            : {}),
          ...(payload.trackStock !== undefined
            ? { trackStock: this.parseBoolean(payload.trackStock, existing.trackStock) }
            : {}),
          ...(payload.reorderLevel !== undefined
            ? { reorderLevel: this.parseInteger(payload.reorderLevel, existing.reorderLevel) }
            : {}),
          ...(payload.isArchived !== undefined
            ? { isArchived: this.parseBoolean(payload.isArchived, existing.isArchived) }
            : {}),
          ...(payload.sectionId !== undefined
            ? { catalogSectionId: sectionId || null }
            : {}),
        },
      });

      if (payload.initialStock !== undefined && existing.inventory[0]) {
        await tx.inventoryStock.update({
          where: { id: existing.inventory[0].id },
          data: {
            onHand: this.parseInteger(payload.initialStock, existing.inventory[0].onHand),
          },
        });
      }
    });

    await this.logAction(adminUser.id, 'product.update', 'product', productId, payload);
    return this.getProductById(productId);
  }

  async deleteBusinessProduct(adminUser: PrismaUser, vendorId: string, productId: string) {
    const existing = await this.prisma.product.findUnique({
      where: { id: productId },
      select: { id: true, vendorId: true, title: true },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Product ${productId} not found`);
    }

    await this.prisma.product.update({
      where: { id: productId },
      data: {
        isArchived: true,
        isActive: false,
        isVisibleInApp: false,
      },
    });
    await this.logAction(adminUser.id, 'product.delete', 'product', productId, {
      vendorId,
      title: existing.title,
      mode: 'soft-archive',
    });
    return { deleted: true, mode: 'soft-archive' };
  }

  async listBusinessCampaigns(vendorId: string) {
    await this.ensureVendor(vendorId);
    const [products, campaigns] = await Promise.all([
      this.prisma.product.findMany({
        where: { vendorId },
        select: { id: true, title: true },
      }),
      this.prisma.vendorCampaign.findMany({
        where: { vendorId },
        include: {
          vendor: {
            select: { id: true, name: true, storefrontType: true },
          },
        },
        orderBy: [{ updatedAt: 'desc' }, { createdAt: 'desc' }],
      }),
    ]);
    const productTitleById = new Map(products.map((product) => [product.id, product.title]));
    return campaigns.map((campaign) => this.toCampaignPayload(campaign, productTitleById));
  }

  async createBusinessCampaign(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    await this.ensureVendor(vendorId);
    const productIds = await this.resolveVendorProductIds(
      vendorId,
      this.stringArray(payload.productIds),
    );
    const campaign = await this.prisma.vendorCampaign.create({
      data: {
        vendorId,
        kind: this.parseCampaignKind(payload.kind),
        status: this.parseCampaignStatus(payload.status, true),
        title: this.requireString(payload.title, 'Kampanya başlığı zorunludur'),
        description: this.optionalString(payload.description) || null,
        startsAt: this.optionalDate(payload.startsAt),
        endsAt: this.optionalDate(payload.endsAt),
        scheduleLabel: this.optionalString(payload.scheduleLabel) || null,
        badgeLabel: this.optionalString(payload.badgeLabel) || null,
        discountPercent: this.optionalInteger(payload.discountPercent),
        discountedPrice:
          payload.discountedPrice !== undefined && payload.discountedPrice !== null
            ? this.parseDecimal(payload.discountedPrice, 'İndirimli fiyat geçersiz')
            : null,
        productIds,
      },
      include: {
        vendor: {
          select: { id: true, name: true, storefrontType: true },
        },
      },
    });
    await this.logAction(adminUser.id, 'campaign.create', 'campaign', campaign.id, {
      vendorId,
      title: campaign.title,
    });
    return this.getCampaignById(campaign.id);
  }

  async updateBusinessCampaign(
    adminUser: PrismaUser,
    vendorId: string,
    campaignId: string,
    payload: JsonRecord,
  ) {
    const existing = await this.prisma.vendorCampaign.findUnique({
      where: { id: campaignId },
      include: {
        vendor: {
          select: { id: true, name: true, storefrontType: true },
        },
      },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Campaign ${campaignId} not found`);
    }

    const nextProductIds =
      payload.productIds !== undefined
        ? await this.resolveVendorProductIds(vendorId, this.stringArray(payload.productIds))
        : undefined;
    await this.prisma.vendorCampaign.update({
      where: { id: campaignId },
      data: {
        ...(payload.kind !== undefined ? { kind: this.parseCampaignKind(payload.kind) } : {}),
        ...(payload.status !== undefined
          ? { status: this.parseCampaignStatus(payload.status) }
          : {}),
        ...(payload.title !== undefined
          ? { title: this.requireString(payload.title, 'Kampanya başlığı zorunludur') }
          : {}),
        ...(payload.description !== undefined
          ? { description: this.optionalString(payload.description) || null }
          : {}),
        ...(payload.startsAt !== undefined
          ? {
              startsAt: this.requiredDate(
                payload.startsAt,
                'Başlangıç tarihi zorunludur',
              ),
            }
          : {}),
        ...(payload.endsAt !== undefined ? { endsAt: this.optionalDate(payload.endsAt) } : {}),
        ...(payload.scheduleLabel !== undefined
          ? { scheduleLabel: this.optionalString(payload.scheduleLabel) || null }
          : {}),
        ...(payload.badgeLabel !== undefined
          ? { badgeLabel: this.optionalString(payload.badgeLabel) || null }
          : {}),
        ...(payload.discountPercent !== undefined
          ? { discountPercent: this.optionalInteger(payload.discountPercent) }
          : {}),
        ...(payload.discountedPrice !== undefined
          ? {
              discountedPrice:
                payload.discountedPrice == null
                  ? null
                  : this.parseDecimal(payload.discountedPrice, 'İndirimli fiyat geçersiz'),
            }
          : {}),
        ...(nextProductIds !== undefined ? { productIds: nextProductIds } : {}),
      },
    });
    await this.logAction(adminUser.id, 'campaign.update', 'campaign', campaignId, payload);
    return this.getCampaignById(campaignId);
  }

  async toggleBusinessCampaign(adminUser: PrismaUser, vendorId: string, campaignId: string) {
    const existing = await this.prisma.vendorCampaign.findUnique({
      where: { id: campaignId },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Campaign ${campaignId} not found`);
    }
    const nextStatus =
      existing.status === CampaignStatus.ACTIVE ? CampaignStatus.PAUSED : CampaignStatus.ACTIVE;
    await this.prisma.vendorCampaign.update({
      where: { id: campaignId },
      data: { status: nextStatus },
    });
    await this.logAction(adminUser.id, 'campaign.toggle', 'campaign', campaignId, {
      vendorId,
      status: nextStatus,
    });
    return this.getCampaignById(campaignId);
  }

  async deleteBusinessCampaign(adminUser: PrismaUser, vendorId: string, campaignId: string) {
    const existing = await this.prisma.vendorCampaign.findUnique({
      where: { id: campaignId },
      select: { id: true, vendorId: true, title: true },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Campaign ${campaignId} not found`);
    }
    await this.prisma.vendorCampaign.delete({ where: { id: campaignId } });
    await this.logAction(adminUser.id, 'campaign.delete', 'campaign', campaignId, {
      vendorId,
      title: existing.title,
    });
    return { deleted: true };
  }

  async getBusinessProfile(vendorId: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        pickupPoints: {
          orderBy: { createdAt: 'asc' },
        },
        bankAccounts: {
          orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
        },
        operators: {
          orderBy: { createdAt: 'asc' },
          select: {
            id: true,
            email: true,
            displayName: true,
            phone: true,
            role: true,
            notificationsEnabled: true,
            createdAt: true,
          },
        },
        _count: {
          select: {
            products: true,
            orders: true,
            campaigns: true,
            events: true,
          },
        },
      },
    });
    if (!vendor) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }

    return {
      business: this.toBusinessListItem(vendor),
      subtitle: vendor.subtitle ?? '',
      city: vendor.city ?? '',
      district: vendor.district ?? '',
      imageUrl: vendor.imageUrl ?? '',
      announcement: vendor.announcement ?? '',
      workingHoursLabel: vendor.workingHoursLabel ?? '',
      pickupPoints: vendor.pickupPoints.map((point) => ({
        id: point.id,
        label: point.label,
        address: point.address,
        isActive: point.isActive,
      })),
      operators: vendor.operators.map((operator) => ({
        id: operator.id,
        email: operator.email,
        displayName: operator.displayName,
        phone: operator.phone ?? '',
        role: operator.role,
        notificationsEnabled: operator.notificationsEnabled,
        createdAt: operator.createdAt.toISOString(),
      })),
      bankAccounts: vendor.bankAccounts.map((account) => ({
        id: account.id,
        holderName: account.holderName,
        bankName: account.bankName,
        iban: account.iban,
        isDefault: account.isDefault,
      })),
    };
  }

  async updateBusinessProfile(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    await this.updateBusiness(adminUser, vendorId, payload);
    await this.logAction(adminUser.id, 'business.profile.update', 'vendor', vendorId, payload);
    return this.getBusinessProfile(vendorId);
  }

  async createBusinessPickupPoint(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    await this.ensureVendor(vendorId);
    const point = await this.prisma.pickupPoint.create({
      data: {
        vendorId,
        label: this.requireString(payload.label, 'Teslim noktası etiketi zorunludur'),
        address: this.requireString(payload.address, 'Teslim noktası adresi zorunludur'),
        isActive: this.parseBoolean(payload.isActive, true),
      },
    });
    await this.logAction(adminUser.id, 'pickup-point.create', 'pickup-point', point.id, {
      vendorId,
    });
    return this.getBusinessProfile(vendorId);
  }

  async updateBusinessPickupPoint(
    adminUser: PrismaUser,
    vendorId: string,
    pickupPointId: string,
    payload: JsonRecord,
  ) {
    const existing = await this.prisma.pickupPoint.findUnique({
      where: { id: pickupPointId },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Pickup point ${pickupPointId} not found`);
    }
    await this.prisma.pickupPoint.update({
      where: { id: pickupPointId },
      data: {
        ...(payload.label !== undefined
          ? { label: this.requireString(payload.label, 'Teslim noktası etiketi zorunludur') }
          : {}),
        ...(payload.address !== undefined
          ? { address: this.requireString(payload.address, 'Teslim noktası adresi zorunludur') }
          : {}),
        ...(payload.isActive !== undefined
          ? { isActive: this.parseBoolean(payload.isActive, existing.isActive) }
          : {}),
      },
    });
    await this.logAction(adminUser.id, 'pickup-point.update', 'pickup-point', pickupPointId, {
      vendorId,
      payload,
    });
    return this.getBusinessProfile(vendorId);
  }

  async createBusinessOperator(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    await this.ensureVendor(vendorId);
    const password = this.optionalString(payload.password);
    if (!password) {
      throw new BadRequestException('Operatör şifresi zorunludur');
    }
    const operator = await this.prisma.user.create({
      data: {
        email: this.requireString(payload.email, 'Operatör e-postası zorunludur').toLowerCase(),
        passwordHash: await bcrypt.hash(password, 10),
        displayName: this.requireString(payload.displayName, 'Operatör adı zorunludur'),
        phone: this.optionalString(payload.phone) || null,
        role: PrismaRole.VENDOR,
        vendorId,
        notificationsEnabled: this.parseBoolean(payload.notificationsEnabled, true),
      },
    });
    await this.logAction(adminUser.id, 'operator.create', 'user', operator.id, {
      vendorId,
      email: operator.email,
    });
    return this.getBusinessProfile(vendorId);
  }

  async updateBusinessOperator(
    adminUser: PrismaUser,
    vendorId: string,
    operatorId: string,
    payload: JsonRecord,
  ) {
    const existing = await this.prisma.user.findUnique({
      where: { id: operatorId },
    });
    if (!existing || existing.vendorId !== vendorId || existing.role !== PrismaRole.VENDOR) {
      throw new NotFoundException(`Operator ${operatorId} not found`);
    }
    await this.prisma.user.update({
      where: { id: operatorId },
      data: {
        ...(payload.email !== undefined
          ? { email: this.requireString(payload.email, 'Operatör e-postası zorunludur').toLowerCase() }
          : {}),
        ...(payload.displayName !== undefined
          ? { displayName: this.requireString(payload.displayName, 'Operatör adı zorunludur') }
          : {}),
        ...(payload.phone !== undefined ? { phone: this.optionalString(payload.phone) || null } : {}),
        ...(payload.notificationsEnabled !== undefined
          ? {
              notificationsEnabled: this.parseBoolean(
                payload.notificationsEnabled,
                existing.notificationsEnabled,
              ),
            }
          : {}),
        ...(payload.password !== undefined && this.optionalString(payload.password)
          ? { passwordHash: await bcrypt.hash(this.requireString(payload.password, 'Şifre zorunludur'), 10) }
          : {}),
        ...(payload.isSuspended !== undefined
          ? { isSuspended: this.parseBoolean(payload.isSuspended, existing.isSuspended) }
          : {}),
      },
    });
    await this.logAction(adminUser.id, 'operator.update', 'user', operatorId, {
      vendorId,
      payload,
    });
    return this.getBusinessProfile(vendorId);
  }

  async createBusinessBankAccount(adminUser: PrismaUser, vendorId: string, payload: JsonRecord) {
    await this.ensureVendor(vendorId);
    const isDefault = this.parseBoolean(payload.isDefault, false);
    const created = await this.prisma.$transaction(async (tx) => {
      if (isDefault) {
        await tx.vendorBankAccount.updateMany({
          where: { vendorId },
          data: { isDefault: false },
        });
      }
      return tx.vendorBankAccount.create({
        data: {
          vendorId,
          holderName: this.requireString(payload.holderName, 'Hesap sahibi zorunludur'),
          bankName: this.requireString(payload.bankName, 'Banka adı zorunludur'),
          iban: this.requireString(payload.iban, 'IBAN zorunludur'),
          isDefault,
        },
      });
    });
    await this.logAction(adminUser.id, 'bank-account.create', 'vendor-bank-account', created.id, {
      vendorId,
    });
    return this.getBusinessProfile(vendorId);
  }

  async updateBusinessBankAccount(
    adminUser: PrismaUser,
    vendorId: string,
    bankAccountId: string,
    payload: JsonRecord,
  ) {
    const existing = await this.prisma.vendorBankAccount.findUnique({
      where: { id: bankAccountId },
    });
    if (!existing || existing.vendorId !== vendorId) {
      throw new NotFoundException(`Bank account ${bankAccountId} not found`);
    }
    await this.prisma.$transaction(async (tx) => {
      if (payload.isDefault !== undefined && this.parseBoolean(payload.isDefault, existing.isDefault)) {
        await tx.vendorBankAccount.updateMany({
          where: { vendorId },
          data: { isDefault: false },
        });
      }
      await tx.vendorBankAccount.update({
        where: { id: bankAccountId },
        data: {
          ...(payload.holderName !== undefined
            ? { holderName: this.requireString(payload.holderName, 'Hesap sahibi zorunludur') }
            : {}),
          ...(payload.bankName !== undefined
            ? { bankName: this.requireString(payload.bankName, 'Banka adı zorunludur') }
            : {}),
          ...(payload.iban !== undefined
            ? { iban: this.requireString(payload.iban, 'IBAN zorunludur') }
            : {}),
          ...(payload.isDefault !== undefined
            ? { isDefault: this.parseBoolean(payload.isDefault, existing.isDefault) }
            : {}),
        },
      });
    });
    await this.logAction(adminUser.id, 'bank-account.update', 'vendor-bank-account', bankAccountId, {
      vendorId,
      payload,
    });
    return this.getBusinessProfile(vendorId);
  }

  async listOrders(query: JsonRecord = {}) {
    const search = this.optionalString(query.q || query.search);
    const status = this.optionalOrderStatus(query.status);
    const vendorId = this.optionalString(query.vendorId);
    const userId = this.optionalString(query.userId);
    const createdAt = this.dateRangeFilter(query.createdFrom || query.from, query.createdTo || query.to);
    const where: Prisma.OrderWhereInput = {
      ...(status ? { status } : {}),
      ...(vendorId ? { vendorId } : {}),
      ...(userId ? { userId } : {}),
      ...(createdAt ? { createdAt } : {}),
      ...(search
        ? {
            OR: [
              { pickupCode: { contains: search, mode: 'insensitive' } },
              { promoCode: { contains: search, mode: 'insensitive' } },
              {
                vendor: {
                  is: { name: { contains: search, mode: 'insensitive' } },
                },
              },
              {
                user: {
                  is: {
                    OR: [
                      { email: { contains: search, mode: 'insensitive' } },
                      { displayName: { contains: search, mode: 'insensitive' } },
                    ],
                  },
                },
              },
            ],
          }
        : {}),
    };

    const paging = this.parsePaging(query);
    const findArgs = {
      where,
      include: {
        vendor: {
          select: { id: true, name: true },
        },
        user: {
          select: { id: true, displayName: true, email: true },
        },
        pickupPoint: {
          select: { label: true },
        },
        items: true,
      },
      orderBy: { createdAt: 'desc' as const },
      take: paging?.pageSize ?? this.parseTake(query.take ?? query.limit, 250),
      ...(paging ? { skip: (paging.page - 1) * paging.pageSize } : {}),
    };
    const [orders, total] = await Promise.all([
      this.prisma.order.findMany(findArgs),
      paging ? this.prisma.order.count({ where }) : Promise.resolve(0),
    ]);
    const items = orders.map((order) => this.toOrderPayload(order));
    return paging ? this.toPagedResponse(items, total, paging) : items;
  }

  async listUsers(query: JsonRecord = {}) {
    const search = this.optionalString(query.q || query.search);
    const role = this.optionalUserRole(query.role);
    const isBanned = this.optionalBoolean(query.isBanned);
    const isSuspended = this.optionalBoolean(query.isSuspended);
    const vendorId = this.optionalString(query.vendorId);
    const where: Prisma.UserWhereInput = {
      role: role ? role : { not: PrismaRole.ADMIN },
      ...(vendorId ? { vendorId } : {}),
      ...(isBanned !== undefined ? { isBanned } : {}),
      ...(isSuspended !== undefined ? { isSuspended } : {}),
      ...(search
        ? {
            OR: [
              { email: { contains: search, mode: 'insensitive' } },
              { displayName: { contains: search, mode: 'insensitive' } },
              { phone: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const paging = this.parsePaging(query);
    const [users, orderCounts, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: paging?.pageSize ?? this.parseTake(query.take ?? query.limit, 250),
        ...(paging ? { skip: (paging.page - 1) * paging.pageSize } : {}),
      }),
      this.prisma.order.findMany({
        select: { userId: true },
      }),
      paging ? this.prisma.user.count({ where }) : Promise.resolve(0),
    ]);
    const ordersByUserId = orderCounts.reduce((acc, order) => {
      acc.set(order.userId, (acc.get(order.userId) ?? 0) + 1);
      return acc;
    }, new Map<string, number>());

    const items = users.map((user) => ({
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      phone: user.phone ?? '',
      role: user.role,
      vendorId: user.vendorId,
      notificationsEnabled: user.notificationsEnabled,
      isSuspended: user.isSuspended,
      suspendedReason: user.suspendedReason ?? '',
      isBanned: user.isBanned,
      bannedReason: user.bannedReason ?? '',
      marketingOptIn: user.marketingOptIn,
      createdAt: user.createdAt.toISOString(),
      lastLoginAt: user.lastLoginAt?.toISOString() ?? null,
      ordersCount: ordersByUserId.get(user.id) ?? 0,
    }));
    return paging ? this.toPagedResponse(items, total, paging) : items;
  }

  async createUser(adminUser: PrismaUser, payload: JsonRecord) {
    const password = this.requireString(payload.password, 'Şifre zorunludur');
    const user = await this.prisma.user.create({
      data: {
        email: this.requireString(payload.email, 'E-posta zorunludur').toLowerCase(),
        passwordHash: await bcrypt.hash(password, 10),
        displayName: this.requireString(payload.displayName, 'İsim zorunludur'),
        phone: this.optionalString(payload.phone) || null,
        role: this.parseUserRole(payload.role),
        vendorId: this.optionalString(payload.vendorId) || null,
        notificationsEnabled: this.parseBoolean(payload.notificationsEnabled, true),
        isSuspended: this.parseBoolean(payload.isSuspended, false),
        suspendedReason: this.optionalString(payload.suspendedReason) || null,
        isBanned: this.parseBoolean(payload.isBanned, false),
        bannedReason: this.optionalString(payload.bannedReason) || null,
        marketingOptIn: this.parseBoolean(payload.marketingOptIn, false),
      },
    });
    await this.logAction(adminUser.id, 'user.create', 'user', user.id, {
      email: user.email,
      role: user.role,
    });
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      phone: user.phone ?? '',
      role: user.role,
      vendorId: user.vendorId,
      notificationsEnabled: user.notificationsEnabled,
      isSuspended: user.isSuspended,
      suspendedReason: user.suspendedReason ?? '',
      isBanned: user.isBanned,
      bannedReason: user.bannedReason ?? '',
      marketingOptIn: user.marketingOptIn,
      createdAt: user.createdAt.toISOString(),
      lastLoginAt: user.lastLoginAt?.toISOString() ?? null,
      ordersCount: 0,
    };
  }

  async updateUser(adminUser: PrismaUser, userId: string, payload: JsonRecord) {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!existing) {
      throw new NotFoundException(`User ${userId} not found`);
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(payload.email !== undefined
          ? { email: this.requireString(payload.email, 'E-posta zorunludur').toLowerCase() }
          : {}),
        ...(payload.displayName !== undefined
          ? { displayName: this.requireString(payload.displayName, 'İsim zorunludur') }
          : {}),
        ...(payload.phone !== undefined ? { phone: this.optionalString(payload.phone) || null } : {}),
        ...(payload.role !== undefined ? { role: this.parseUserRole(payload.role) } : {}),
        ...(payload.vendorId !== undefined
          ? { vendorId: this.optionalString(payload.vendorId) || null }
          : {}),
        ...(payload.notificationsEnabled !== undefined
          ? {
              notificationsEnabled: this.parseBoolean(
                payload.notificationsEnabled,
                existing.notificationsEnabled,
              ),
            }
          : {}),
        ...(payload.isSuspended !== undefined
          ? { isSuspended: this.parseBoolean(payload.isSuspended, existing.isSuspended) }
          : {}),
        ...(payload.suspendedReason !== undefined
          ? { suspendedReason: this.optionalString(payload.suspendedReason) || null }
          : {}),
        ...(payload.isBanned !== undefined
          ? { isBanned: this.parseBoolean(payload.isBanned, existing.isBanned) }
          : {}),
        ...(payload.bannedReason !== undefined
          ? { bannedReason: this.optionalString(payload.bannedReason) || null }
          : {}),
        ...(payload.marketingOptIn !== undefined
          ? { marketingOptIn: this.parseBoolean(payload.marketingOptIn, existing.marketingOptIn) }
          : {}),
        ...(payload.password !== undefined && this.optionalString(payload.password)
          ? { passwordHash: await bcrypt.hash(this.requireString(payload.password, 'Şifre zorunludur'), 10) }
          : {}),
      },
    });
    await this.logAction(adminUser.id, 'user.update', 'user', userId, payload);
    const users = await this.listUsers();
    return Array.isArray(users) ? users.find((user) => user.id === userId) : undefined;
  }

  async bulkUpdateUsers(adminUser: PrismaUser, payload: JsonRecord) {
    const userIds = this.requiredIdArray(payload.userIds || payload.ids, 'Kullanıcı seçimi zorunludur');
    const patch = this.objectPayload(payload.patch || payload);
    const data: Prisma.UserUpdateManyMutationInput = {
      ...(patch.notificationsEnabled !== undefined
        ? { notificationsEnabled: this.parseBoolean(patch.notificationsEnabled, true) }
        : {}),
      ...(patch.isSuspended !== undefined
        ? { isSuspended: this.parseBoolean(patch.isSuspended, false) }
        : {}),
      ...(patch.suspendedReason !== undefined
        ? { suspendedReason: this.optionalString(patch.suspendedReason) || null }
        : {}),
      ...(patch.isBanned !== undefined
        ? { isBanned: this.parseBoolean(patch.isBanned, false) }
        : {}),
      ...(patch.bannedReason !== undefined
        ? { bannedReason: this.optionalString(patch.bannedReason) || null }
        : {}),
      ...(patch.marketingOptIn !== undefined
        ? { marketingOptIn: this.parseBoolean(patch.marketingOptIn, false) }
        : {}),
    };
    if (Object.keys(data).length === 0) {
      throw new BadRequestException('Toplu kullanıcı güncellemesi için alan gönderilmedi');
    }
    const result = await this.prisma.user.updateMany({
      where: { id: { in: userIds } },
      data,
    });
    await this.logAction(adminUser.id, 'user.bulk.update', 'user', 'bulk', {
      userIds,
      data,
      updatedCount: result.count,
    });
    return { updatedCount: result.count };
  }

  async listEvents(query: JsonRecord = {}) {
    const search = this.optionalString(query.q || query.search);
    const isActive = this.optionalBoolean(query.isActive);
    const where: Prisma.EventWhereInput = {
      ...(isActive !== undefined ? { isActive } : {}),
      ...(search
        ? {
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { venue: { contains: search, mode: 'insensitive' } },
              { district: { contains: search, mode: 'insensitive' } },
              { vendor: { is: { name: { contains: search, mode: 'insensitive' } } } },
            ],
          }
        : {}),
    };
    const paging = this.parsePaging(query);
    const findArgs = {
      where,
      include: {
        vendor: {
          select: { id: true, name: true },
        },
      },
      orderBy: { startsAt: 'asc' as const },
      take: paging?.pageSize ?? this.parseTake(query.take ?? query.limit, 250),
      ...(paging ? { skip: (paging.page - 1) * paging.pageSize } : {}),
    } satisfies Prisma.EventFindManyArgs;
    const [events, total] = await Promise.all([
      this.prisma.event.findMany(findArgs),
      paging ? this.prisma.event.count({ where }) : Promise.resolve(0),
    ]);
    const items = events.map((event) => ({
      id: event.id,
      vendorId: event.vendorId,
      vendorName: event.vendor.name,
      title: event.title,
      venue: event.venue,
      district: event.district ?? '',
      imageUrl: event.imageUrl ?? '',
      startsAt: event.startsAt.toISOString(),
      pointsCost: event.pointsCost,
      capacity: event.capacity,
      remainingCount: event.remainingCount,
      primaryTag: event.primaryTag ?? '',
      secondaryTag: event.secondaryTag ?? '',
      description: event.description ?? '',
      organizer: event.organizer ?? '',
      isActive: event.isActive,
      createdAt: event.createdAt.toISOString(),
    }));
    return paging ? this.toPagedResponse(items, total, paging) : items;
  }

  async createEvent(adminUser: PrismaUser, payload: JsonRecord) {
    const vendorId = this.requireString(payload.vendorId, 'İşletme seçimi zorunludur');
    const vendor = await this.ensureVendor(vendorId);
    const event = await this.prisma.event.create({
      data: {
        vendorId,
        title: this.requireString(payload.title, 'Etkinlik adı zorunludur'),
        venue: this.requireString(payload.venue, 'Mekan zorunludur'),
        district: this.optionalString(payload.district) || vendor.district || null,
        imageUrl: this.optionalString(payload.imageUrl) || null,
        startsAt: this.requiredDate(payload.startsAt, 'Başlangıç tarihi zorunludur'),
        pointsCost: this.parseInteger(payload.pointsCost, 0),
        capacity: this.parseInteger(payload.capacity, 50),
        remainingCount: this.parseInteger(payload.remainingCount, this.parseInteger(payload.capacity, 50)),
        primaryTag: this.optionalString(payload.primaryTag) || null,
        secondaryTag: this.optionalString(payload.secondaryTag) || null,
        description: this.optionalString(payload.description) || null,
        organizer: this.optionalString(payload.organizer) || vendor.name,
        participantLabel: this.optionalString(payload.participantLabel) || null,
        ticketCategory: this.optionalString(payload.ticketCategory) || null,
        locationTitle: this.optionalString(payload.locationTitle) || vendor.name,
        locationSubtitle: this.optionalString(payload.locationSubtitle) || vendor.city || null,
        isFeatured: this.parseBoolean(payload.isFeatured, false),
        isActive: this.parseBoolean(payload.isActive, true),
      },
      include: {
        vendor: {
          select: { id: true, name: true },
        },
      },
    });
    await this.logAction(adminUser.id, 'event.create', 'event', event.id, {
      vendorId,
      title: event.title,
    });
    return {
      id: event.id,
      vendorId: event.vendorId,
      vendorName: event.vendor.name,
      title: event.title,
      venue: event.venue,
      district: event.district ?? '',
      imageUrl: event.imageUrl ?? '',
      startsAt: event.startsAt.toISOString(),
      pointsCost: event.pointsCost,
      capacity: event.capacity,
      remainingCount: event.remainingCount,
      primaryTag: event.primaryTag ?? '',
      secondaryTag: event.secondaryTag ?? '',
      description: event.description ?? '',
      organizer: event.organizer ?? '',
      isActive: event.isActive,
      createdAt: event.createdAt.toISOString(),
    };
  }

  async updateEvent(adminUser: PrismaUser, eventId: string, payload: JsonRecord) {
    const existing = await this.prisma.event.findUnique({
      where: { id: eventId },
      include: {
        vendor: {
          select: { id: true, name: true },
        },
      },
    });
    if (!existing) {
      throw new NotFoundException(`Event ${eventId} not found`);
    }
    await this.prisma.event.update({
      where: { id: eventId },
        data: {
        ...(payload.vendorId !== undefined
          ? {
              vendor: {
                connect: {
                  id: this.requireString(payload.vendorId, 'İşletme zorunludur'),
                },
              },
            }
          : {}),
        ...(payload.title !== undefined
          ? { title: this.requireString(payload.title, 'Etkinlik adı zorunludur') }
          : {}),
        ...(payload.venue !== undefined
          ? { venue: this.requireString(payload.venue, 'Mekan zorunludur') }
          : {}),
        ...(payload.district !== undefined
          ? { district: this.optionalString(payload.district) || null }
          : {}),
        ...(payload.imageUrl !== undefined
          ? { imageUrl: this.optionalString(payload.imageUrl) || null }
          : {}),
        ...(payload.startsAt !== undefined
          ? {
              startsAt: this.requiredDate(
                payload.startsAt,
                'Başlangıç tarihi zorunludur',
              ),
            }
          : {}),
        ...(payload.pointsCost !== undefined
          ? { pointsCost: this.parseInteger(payload.pointsCost, existing.pointsCost) }
          : {}),
        ...(payload.capacity !== undefined
          ? { capacity: this.parseInteger(payload.capacity, existing.capacity) }
          : {}),
        ...(payload.remainingCount !== undefined
          ? {
              remainingCount: this.parseInteger(
                payload.remainingCount,
                existing.remainingCount,
              ),
            }
          : {}),
        ...(payload.primaryTag !== undefined
          ? { primaryTag: this.optionalString(payload.primaryTag) || null }
          : {}),
        ...(payload.secondaryTag !== undefined
          ? { secondaryTag: this.optionalString(payload.secondaryTag) || null }
          : {}),
        ...(payload.description !== undefined
          ? { description: this.optionalString(payload.description) || null }
          : {}),
        ...(payload.organizer !== undefined
          ? { organizer: this.optionalString(payload.organizer) || null }
          : {}),
        ...(payload.isActive !== undefined
          ? { isActive: this.parseBoolean(payload.isActive, existing.isActive) }
          : {}),
      },
    });
    await this.logAction(adminUser.id, 'event.update', 'event', eventId, payload);
    const events = await this.listEvents();
    return Array.isArray(events) ? events.find((event) => event.id === eventId) : undefined;
  }

  async deleteEvent(adminUser: PrismaUser, eventId: string) {
    const existing = await this.prisma.event.findUnique({
      where: { id: eventId },
      select: { id: true, vendorId: true, title: true },
    });
    if (!existing) {
      throw new NotFoundException(`Event ${eventId} not found`);
    }
    await this.prisma.event.delete({ where: { id: eventId } });
    await this.logAction(adminUser.id, 'event.delete', 'event', eventId, {
      vendorId: existing.vendorId,
      title: existing.title,
    });
    return { deleted: true };
  }

  async getFinanceSummary() {
    const [businesses, completedOrders, payouts] = await Promise.all([
      this.prisma.vendor.findMany({
        orderBy: { name: 'asc' },
      }),
      this.prisma.order.findMany({
        where: { status: OrderStatus.COMPLETED },
        select: {
          vendorId: true,
          totalAmount: true,
        },
      }),
      this.prisma.vendorPayout.findMany({
        include: {
          vendor: {
            select: { id: true, name: true },
          },
          bankAccount: {
            select: { bankName: true, iban: true },
          },
        },
        orderBy: { requestedAt: 'desc' },
      }),
    ]);

    const revenueByVendor = completedOrders.reduce((acc, order) => {
      acc.set(order.vendorId, (acc.get(order.vendorId) ?? 0) + Number(order.totalAmount));
      return acc;
    }, new Map<string, number>());

    const payoutsByVendor = payouts.reduce((acc, payout) => {
      const current = acc.get(payout.vendorId) ?? { paid: 0, pending: 0, lastPayoutAt: '' };
      if (payout.status === PayoutStatus.PAID) {
        current.paid += Number(payout.amount);
        current.lastPayoutAt = payout.completedAt?.toISOString() ?? current.lastPayoutAt;
      } else if (payout.status === PayoutStatus.PENDING) {
        current.pending += Number(payout.amount);
      }
      acc.set(payout.vendorId, current);
      return acc;
    }, new Map<string, { paid: number; pending: number; lastPayoutAt: string }>());

    return {
      grossVolume: completedOrders.reduce(
        (total, order) => total + Number(order.totalAmount),
        0,
      ),
      completedOrders: completedOrders.length,
      totalPayouts: payouts
        .filter((payout) => payout.status === PayoutStatus.PAID)
        .reduce((total, payout) => total + Number(payout.amount), 0),
      pendingPayouts: payouts
        .filter((payout) => payout.status === PayoutStatus.PENDING)
        .reduce((total, payout) => total + Number(payout.amount), 0),
      vendorBalances: businesses.map((business) => {
        const revenue = revenueByVendor.get(business.id) ?? 0;
        const payoutSummary = payoutsByVendor.get(business.id) ?? {
          paid: 0,
          pending: 0,
          lastPayoutAt: '',
        };
        return {
          vendorId: business.id,
          vendorName: business.name,
          availableBalance: Math.max(0, revenue - payoutSummary.paid - payoutSummary.pending),
          pendingPayouts: payoutSummary.pending,
          lastPayoutAt: payoutSummary.lastPayoutAt || null,
        };
      }),
      recentPayouts: payouts.slice(0, 10).map((payout) => ({
        id: payout.id,
        vendorId: payout.vendorId,
        vendorName: payout.vendor.name,
        amount: Number(payout.amount),
        status: payout.status,
        requestedAt: payout.requestedAt.toISOString(),
        completedAt: payout.completedAt?.toISOString() ?? null,
        bankName: payout.bankAccount.bankName,
        iban: payout.bankAccount.iban,
        note: payout.note ?? null,
      })),
    };
  }

  async createPayout(adminUser: PrismaUser, payload: JsonRecord) {
    const vendorId = this.requireString(payload.vendorId, 'İşletme seçimi zorunludur');
    await this.ensureVendor(vendorId);
    const bankAccountId = this.requireString(payload.bankAccountId, 'Banka hesabı zorunludur');
    const bankAccount = await this.prisma.vendorBankAccount.findUnique({
      where: { id: bankAccountId },
    });
    if (!bankAccount || bankAccount.vendorId !== vendorId) {
      throw new BadRequestException('Banka hesabı işletmeye ait değil');
    }
    const payout = await this.prisma.vendorPayout.create({
      data: {
        vendorId,
        bankAccountId,
        amount: this.parseDecimal(payload.amount, 'Payout tutarı geçersiz'),
        status: this.parsePayoutStatus(payload.status, PayoutStatus.PENDING),
        note: this.optionalString(payload.note) || null,
        completedAt:
          this.parsePayoutStatus(payload.status, PayoutStatus.PENDING) === PayoutStatus.PAID
            ? new Date()
            : null,
      },
    });
    await this.logAction(adminUser.id, 'payout.create', 'vendor-payout', payout.id, {
      vendorId,
      bankAccountId,
      amount: String(payout.amount),
      status: payout.status,
      providerMode: 'manual',
    });
    return this.getFinanceSummary();
  }

  async updatePayout(adminUser: PrismaUser, payoutId: string, payload: JsonRecord) {
    const existing = await this.prisma.vendorPayout.findUnique({
      where: { id: payoutId },
    });
    if (!existing) {
      throw new NotFoundException(`Payout ${payoutId} not found`);
    }
    const status =
      payload.status !== undefined
        ? this.parsePayoutStatus(payload.status, existing.status)
        : existing.status;
    await this.prisma.vendorPayout.update({
      where: { id: payoutId },
      data: {
        ...(payload.amount !== undefined
          ? { amount: this.parseDecimal(payload.amount, 'Payout tutarı geçersiz') }
          : {}),
        ...(payload.note !== undefined ? { note: this.optionalString(payload.note) || null } : {}),
        ...(payload.status !== undefined ? { status } : {}),
        ...(status === PayoutStatus.PAID && existing.completedAt == null
          ? { completedAt: new Date() }
          : {}),
        ...(status !== PayoutStatus.PAID ? { completedAt: null } : {}),
      },
    });
    await this.logAction(adminUser.id, 'payout.update', 'vendor-payout', payoutId, {
      status,
      providerMode: 'manual',
    });
    return this.getFinanceSummary();
  }

  async getReportsOverview() {
    const [completedOrders, businesses, activeCampaigns, orderItems] = await Promise.all([
      this.prisma.order.findMany({
        where: { status: OrderStatus.COMPLETED },
        select: {
          id: true,
          totalAmount: true,
          createdAt: true,
        },
      }),
      this.prisma.vendor.findMany({
        where: { isActive: true },
        select: { id: true, name: true },
      }),
      this.prisma.vendorCampaign.count({
        where: { status: CampaignStatus.ACTIVE },
      }),
      this.prisma.orderItem.findMany({
        include: {
          product: {
            include: {
              vendor: {
                select: { id: true, name: true },
              },
            },
          },
          order: {
            select: { status: true },
          },
        },
      }),
    ]);

    const topProductsMap = new Map<
      string,
      {
        productId: string;
        title: string;
        vendorName: string;
        quantity: number;
        revenue: number;
      }
    >();
    for (const item of orderItems) {
      if (item.order.status !== OrderStatus.COMPLETED) {
        continue;
      }
      const current = topProductsMap.get(item.productId) ?? {
        productId: item.productId,
        title: item.title,
        vendorName: item.product.vendor.name,
        quantity: 0,
        revenue: 0,
      };
      current.quantity += item.quantity;
      current.revenue += item.quantity * Number(item.unitPrice);
      topProductsMap.set(item.productId, current);
    }

    const grossVolume = completedOrders.reduce(
      (total, order) => total + Number(order.totalAmount),
      0,
    );

    return {
      grossVolume,
      averageOrderValue: completedOrders.length > 0 ? grossVolume / completedOrders.length : 0,
      completedOrders: completedOrders.length,
      activeBusinesses: businesses.length,
      activeCampaigns,
      topProducts: Array.from(topProductsMap.values())
        .sort((left, right) => right.quantity - left.quantity)
        .slice(0, 10),
      dailyRevenue: this.buildDailyRevenueSeries(completedOrders),
    };
  }

  async listNotifications(query: JsonRecord = {}) {
    const search = this.optionalString(query.q || query.search);
    const status = this.optionalNotificationStatus(query.status);
    const audience = this.optionalNotificationAudience(query.audience);
    const createdAt = this.dateRangeFilter(query.createdFrom || query.from, query.createdTo || query.to);
    const where: Prisma.AdminNotificationWhereInput = {
      ...(status ? { status } : {}),
      ...(audience ? { audience } : {}),
      ...(createdAt ? { createdAt } : {}),
      ...(search
        ? {
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { body: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const paging = this.parsePaging(query);
    const findArgs = {
      where,
      include: {
        createdByAdmin: {
          select: { displayName: true, email: true },
        },
        deliveryLogs: {
          orderBy: { createdAt: 'desc' as const },
          take: 5,
        },
      },
      orderBy: { createdAt: 'desc' as const },
      take: paging?.pageSize ?? this.parseTake(query.take ?? query.limit, 250),
      ...(paging ? { skip: (paging.page - 1) * paging.pageSize } : {}),
    } satisfies Prisma.AdminNotificationFindManyArgs;
    const [notifications, total] = await Promise.all([
      this.prisma.adminNotification.findMany(findArgs),
      paging ? this.prisma.adminNotification.count({ where }) : Promise.resolve(0),
    ]);
    const items = notifications.map((notification) => ({
      id: notification.id,
      title: notification.title,
      body: notification.body,
      audience: notification.audience,
      status: notification.status,
      scheduledAt: notification.scheduledAt?.toISOString() ?? null,
      sentAt: notification.sentAt?.toISOString() ?? null,
      createdAt: notification.createdAt.toISOString(),
      updatedAt: notification.updatedAt.toISOString(),
      createdByName: notification.createdByAdmin.displayName,
      createdByEmail: notification.createdByAdmin.email,
      deliveryLogs: notification.deliveryLogs.map((log) => ({
        id: log.id,
        notificationId: log.notificationId,
        provider: log.provider,
        status: log.status,
        target: log.target ?? null,
        errorMessage: log.errorMessage ?? null,
        createdAt: log.createdAt.toISOString(),
      })),
    }));
    return paging ? this.toPagedResponse(items, total, paging) : items;
  }

  async createNotification(adminUser: PrismaUser, payload: JsonRecord) {
    const status = this.parseNotificationStatus(payload.status, true);
    const notification = await this.prisma.adminNotification.create({
      data: {
        title: this.requireString(payload.title, 'Bildirim başlığı zorunludur'),
        body: this.requireString(payload.body, 'Bildirim içeriği zorunludur'),
        audience: this.parseNotificationAudience(payload.audience),
        status,
        scheduledAt: this.optionalDate(payload.scheduledAt),
        sentAt: status === AdminNotificationStatus.SENT ? new Date() : null,
        ...(payload.payload !== undefined
          ? { payload: this.toNullableJson(payload.payload) }
          : {}),
        createdByAdminId: adminUser.id,
      },
      include: {
        createdByAdmin: {
          select: { displayName: true, email: true },
        },
      },
    });
    await this.logAction(adminUser.id, 'notification.create', 'notification', notification.id, {
      title: notification.title,
    });
    if (notification.status === AdminNotificationStatus.SENT) {
      await this.logNotificationDeliveryPlaceholder(notification.id);
    }
    return {
      id: notification.id,
      title: notification.title,
      body: notification.body,
      audience: notification.audience,
      status: notification.status,
      scheduledAt: notification.scheduledAt?.toISOString() ?? null,
      sentAt: notification.sentAt?.toISOString() ?? null,
      createdAt: notification.createdAt.toISOString(),
      updatedAt: notification.updatedAt.toISOString(),
      createdByName: notification.createdByAdmin.displayName,
      createdByEmail: notification.createdByAdmin.email,
      deliveryLogs: [],
    };
  }

  async updateNotification(adminUser: PrismaUser, notificationId: string, payload: JsonRecord) {
    const existing = await this.prisma.adminNotification.findUnique({
      where: { id: notificationId },
      include: {
        createdByAdmin: {
          select: { displayName: true, email: true },
        },
      },
    });
    if (!existing) {
      throw new NotFoundException(`Notification ${notificationId} not found`);
    }
    const nextStatus =
      payload.status !== undefined
        ? this.parseNotificationStatus(payload.status)
        : existing.status;
    const updated = await this.prisma.adminNotification.update({
      where: { id: notificationId },
      data: {
        ...(payload.title !== undefined
          ? { title: this.requireString(payload.title, 'Bildirim başlığı zorunludur') }
          : {}),
        ...(payload.body !== undefined
          ? { body: this.requireString(payload.body, 'Bildirim içeriği zorunludur') }
          : {}),
        ...(payload.audience !== undefined
          ? { audience: this.parseNotificationAudience(payload.audience) }
          : {}),
        ...(payload.status !== undefined ? { status: nextStatus } : {}),
        ...(payload.scheduledAt !== undefined
          ? { scheduledAt: this.optionalDate(payload.scheduledAt) }
          : {}),
        ...(payload.payload !== undefined
          ? { payload: this.toNullableJson(payload.payload) }
          : {}),
        ...(nextStatus === AdminNotificationStatus.SENT && existing.sentAt == null
          ? { sentAt: new Date() }
          : {}),
      },
      include: {
        createdByAdmin: {
          select: { displayName: true, email: true },
        },
      },
    });
    await this.logAction(adminUser.id, 'notification.update', 'notification', notificationId, payload);
    if (updated.status === AdminNotificationStatus.SENT && existing.sentAt == null) {
      await this.logNotificationDeliveryPlaceholder(updated.id);
    }
    return {
      id: updated.id,
      title: updated.title,
      body: updated.body,
      audience: updated.audience,
      status: updated.status,
      scheduledAt: updated.scheduledAt?.toISOString() ?? null,
      sentAt: updated.sentAt?.toISOString() ?? null,
      createdAt: updated.createdAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString(),
      createdByName: updated.createdByAdmin.displayName,
      createdByEmail: updated.createdByAdmin.email,
      deliveryLogs: [],
    };
  }

  async deleteNotification(adminUser: PrismaUser, notificationId: string) {
    const existing = await this.prisma.adminNotification.findUnique({
      where: { id: notificationId },
      select: { id: true, title: true },
    });
    if (!existing) {
      throw new NotFoundException(`Notification ${notificationId} not found`);
    }
    await this.prisma.adminNotification.delete({ where: { id: notificationId } });
    await this.logAction(adminUser.id, 'notification.delete', 'notification', notificationId, {
      title: existing.title,
    });
    return { deleted: true };
  }

  async listSupportTickets(query: JsonRecord = {}) {
    const search = this.optionalString(query.q || query.search);
    const status = this.optionalSupportStatus(query.status);
    const priority = this.optionalSupportPriority(query.priority);
    const channel = this.optionalString(query.channel);
    const createdAt = this.dateRangeFilter(query.createdFrom || query.from, query.createdTo || query.to);
    const where: Prisma.SupportTicketWhereInput = {
      ...(status ? { status } : {}),
      ...(priority ? { priority } : {}),
      ...(channel ? { channel: { contains: channel, mode: 'insensitive' } } : {}),
      ...(createdAt ? { createdAt } : {}),
      ...(search
        ? {
            OR: [
              { subject: { contains: search, mode: 'insensitive' } },
              { message: { contains: search, mode: 'insensitive' } },
              {
                user: {
                  is: {
                    OR: [
                      { email: { contains: search, mode: 'insensitive' } },
                      { displayName: { contains: search, mode: 'insensitive' } },
                    ],
                  },
                },
              },
            ],
          }
        : {}),
    };
    const paging = this.parsePaging(query);
    const findArgs = {
      where,
      include: {
        user: {
          select: { id: true, displayName: true, email: true },
        },
        assignedAdmin: {
          select: { id: true, displayName: true, email: true },
        },
      },
      orderBy: { updatedAt: 'desc' as const },
      take: paging?.pageSize ?? this.parseTake(query.take ?? query.limit, 250),
      ...(paging ? { skip: (paging.page - 1) * paging.pageSize } : {}),
    } satisfies Prisma.SupportTicketFindManyArgs;
    const [tickets, total] = await Promise.all([
      this.prisma.supportTicket.findMany(findArgs),
      paging ? this.prisma.supportTicket.count({ where }) : Promise.resolve(0),
    ]);
    const items = tickets.map((ticket) => ({
      id: ticket.id,
      userId: ticket.userId,
      userName: ticket.user.displayName,
      userEmail: ticket.user.email,
      subject: ticket.subject,
      message: ticket.message,
      channel: ticket.channel,
      status: ticket.status,
      priority: ticket.priority,
      assignedAdminId: ticket.assignedAdminId ?? null,
      assignedAdminName: ticket.assignedAdmin?.displayName ?? '',
      assignedAdminEmail: ticket.assignedAdmin?.email ?? '',
      createdAt: ticket.createdAt.toISOString(),
      updatedAt: ticket.updatedAt.toISOString(),
    }));
    return paging ? this.toPagedResponse(items, total, paging) : items;
  }

  async updateSupportTicket(adminUser: PrismaUser, ticketId: string, payload: JsonRecord) {
    const existing = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: {
        user: {
          select: { id: true, displayName: true, email: true },
        },
        assignedAdmin: {
          select: { id: true, displayName: true, email: true },
        },
      },
    });
    if (!existing) {
      throw new NotFoundException(`Support ticket ${ticketId} not found`);
    }
    const updated = await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        ...(payload.subject !== undefined
          ? { subject: this.requireString(payload.subject, 'Konu zorunludur') }
          : {}),
        ...(payload.message !== undefined
          ? { message: this.requireString(payload.message, 'Mesaj zorunludur') }
          : {}),
        ...(payload.channel !== undefined
          ? { channel: this.requireString(payload.channel, 'Kanal zorunludur') }
          : {}),
        ...(payload.status !== undefined
          ? { status: this.parseSupportStatus(payload.status) }
          : {}),
        ...(payload.priority !== undefined
          ? { priority: this.parseSupportPriority(payload.priority) }
          : {}),
      },
      include: {
        user: {
          select: { id: true, displayName: true, email: true },
        },
        assignedAdmin: {
          select: { id: true, displayName: true, email: true },
        },
      },
    });
    await this.logAction(adminUser.id, 'support.update', 'support-ticket', ticketId, payload);
    return {
      id: updated.id,
      userId: updated.userId,
      userName: updated.user.displayName,
      userEmail: updated.user.email,
      subject: updated.subject,
      message: updated.message,
      channel: updated.channel,
      status: updated.status,
      priority: updated.priority,
      assignedAdminId: updated.assignedAdminId ?? null,
      assignedAdminName: updated.assignedAdmin?.displayName ?? '',
      assignedAdminEmail: updated.assignedAdmin?.email ?? '',
      createdAt: updated.createdAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString(),
    };
  }

  async getSupportTicket(ticketId: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: {
        user: {
          select: { id: true, displayName: true, email: true },
        },
        assignedAdmin: {
          select: { id: true, displayName: true, email: true },
        },
        messages: {
          include: {
            author: {
              select: { id: true, displayName: true, email: true, role: true },
            },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    if (!ticket) {
      throw new NotFoundException(`Support ticket ${ticketId} not found`);
    }
    return {
      id: ticket.id,
      userId: ticket.userId,
      userName: ticket.user.displayName,
      userEmail: ticket.user.email,
      subject: ticket.subject,
      message: ticket.message,
      channel: ticket.channel,
      status: ticket.status,
      priority: ticket.priority,
      assignedAdminId: ticket.assignedAdminId ?? null,
      assignedAdminName: ticket.assignedAdmin?.displayName ?? '',
      assignedAdminEmail: ticket.assignedAdmin?.email ?? '',
      createdAt: ticket.createdAt.toISOString(),
      updatedAt: ticket.updatedAt.toISOString(),
      messages: ticket.messages.map((message) => ({
        id: message.id,
        ticketId: message.ticketId,
        authorId: message.authorId,
        authorName: message.author.displayName,
        authorEmail: message.author.email,
        authorRole: message.author.role,
        body: message.body,
        isInternal: message.isInternal,
        createdAt: message.createdAt.toISOString(),
      })),
    };
  }

  async updateSupportTicketAssignment(
    adminUser: PrismaUser,
    ticketId: string,
    payload: JsonRecord,
  ) {
    const assignedAdminId = this.optionalString(payload.assignedAdminId);
    if (assignedAdminId) {
      const assignedAdmin = await this.prisma.user.findUnique({
        where: { id: assignedAdminId },
      });
      if (!assignedAdmin || assignedAdmin.role !== PrismaRole.ADMIN) {
        throw new BadRequestException('Atanacak admin bulunamadı');
      }
    }
    await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        assignedAdminId: assignedAdminId || null,
        ...(payload.priority !== undefined
          ? { priority: this.parseSupportPriority(payload.priority) }
          : {}),
      },
    });
    await this.logAction(adminUser.id, 'support.assignment.update', 'support-ticket', ticketId, {
      assignedAdminId: assignedAdminId || null,
      priority: payload.priority,
    });
    return this.getSupportTicket(ticketId);
  }

  async createSupportTicketMessage(
    adminUser: PrismaUser,
    ticketId: string,
    payload: JsonRecord,
  ) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      select: { id: true },
    });
    if (!ticket) {
      throw new NotFoundException(`Support ticket ${ticketId} not found`);
    }
    const message = await this.prisma.supportTicketMessage.create({
      data: {
        ticketId,
        authorId: adminUser.id,
        body: this.requireString(payload.body, 'Mesaj zorunludur'),
        isInternal: this.parseBoolean(payload.isInternal, false),
      },
      include: {
        author: {
          select: { id: true, displayName: true, email: true, role: true },
        },
      },
    });
    await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        ...(payload.status !== undefined
          ? { status: this.parseSupportStatus(payload.status) }
          : { status: SupportStatus.IN_PROGRESS }),
      },
    });
    await this.logAction(adminUser.id, 'support.message.create', 'support-ticket', ticketId, {
      messageId: message.id,
      isInternal: message.isInternal,
    });
    return {
      id: message.id,
      ticketId: message.ticketId,
      authorId: message.authorId,
      authorName: message.author.displayName,
      authorEmail: message.author.email,
      authorRole: message.author.role,
      body: message.body,
      isInternal: message.isInternal,
      createdAt: message.createdAt.toISOString(),
    };
  }

  createUploadIntent(payload: JsonRecord) {
    const provider = (process.env.ADMIN_UPLOAD_PROVIDER ?? '').trim();
    if (!provider) {
      return {
        configured: false,
        provider: null,
        uploadUrl: null,
        publicUrl: null,
        fields: {},
        message: 'Upload provider configured değil. Şimdilik güvenli URL alanı kullanın.',
        requested: {
          fileName: this.optionalString(payload.fileName),
          contentType: this.optionalString(payload.contentType),
          folder: this.optionalString(payload.folder) || 'admin',
        },
      };
    }
    return {
      configured: false,
      provider,
      uploadUrl: null,
      publicUrl: null,
      fields: {},
      message: `${provider} upload adapter henüz bağlanmadı.`,
      requested: {
        fileName: this.optionalString(payload.fileName),
        contentType: this.optionalString(payload.contentType),
        folder: this.optionalString(payload.folder) || 'admin',
      },
    };
  }

  async getSettings() {
    const settings = await this.prisma.platformSetting.findMany();
    const merged = { ...SETTINGS_DEFAULTS };
    for (const setting of settings) {
      if (setting.key in merged) {
        (merged as Record<string, unknown>)[setting.key] = setting.value;
      }
    }
    return merged;
  }

  async updateSettings(adminUser: PrismaUser, payload: JsonRecord) {
    const nextSettings = {
      maintenanceMode: this.parseBoolean(
        payload.maintenanceMode,
        SETTINGS_DEFAULTS.maintenanceMode,
      ),
      supportEmail:
        this.optionalString(payload.supportEmail) || SETTINGS_DEFAULTS.supportEmail,
      supportPhone:
        this.optionalString(payload.supportPhone) || SETTINGS_DEFAULTS.supportPhone,
      announcementBanner:
        this.optionalString(payload.announcementBanner) ||
        SETTINGS_DEFAULTS.announcementBanner,
      defaultCommissionRate: this.parseInteger(
        payload.defaultCommissionRate,
        SETTINGS_DEFAULTS.defaultCommissionRate,
      ),
      notificationsEnabled: this.parseBoolean(
        payload.notificationsEnabled,
        SETTINGS_DEFAULTS.notificationsEnabled,
      ),
    };

    await this.prisma.$transaction(
      Object.entries(nextSettings).map(([key, value]) =>
        this.prisma.platformSetting.upsert({
          where: { key },
          update: {
            value,
            updatedByAdminId: adminUser.id,
          },
          create: {
            key,
            value,
            updatedByAdminId: adminUser.id,
          },
        }),
      ),
    );

    await this.logAction(adminUser.id, 'settings.update', 'platform-setting', 'global', nextSettings);
    return nextSettings;
  }

  async listAuditLogs(query: JsonRecord = {}) {
    const action = this.optionalString(query.action);
    const entityType = this.optionalString(query.entityType);
    const entityId = this.optionalString(query.entityId);
    const adminUserId = this.optionalString(query.adminUserId);
    const createdAt = this.dateRangeFilter(query.createdFrom || query.from, query.createdTo || query.to);
    const search = this.optionalString(query.q || query.search);
    const where: Prisma.AdminAuditLogWhereInput = {
        ...(action ? { action: { contains: action, mode: 'insensitive' } } : {}),
        ...(entityType ? { entityType: { contains: entityType, mode: 'insensitive' } } : {}),
        ...(entityId ? { entityId } : {}),
        ...(adminUserId ? { adminUserId } : {}),
        ...(createdAt ? { createdAt } : {}),
        ...(search
          ? {
              OR: [
                { action: { contains: search, mode: 'insensitive' } },
                { entityType: { contains: search, mode: 'insensitive' } },
                { entityId: { contains: search, mode: 'insensitive' } },
              ],
            }
          : {}),
      };
    const paging = this.parsePaging(query);
    const findArgs = {
      where,
      include: {
        adminUser: {
          select: { id: true, email: true, displayName: true },
        },
      },
      orderBy: { createdAt: 'desc' as const },
      take: paging?.pageSize ?? this.parseTake(query.take ?? query.limit, 250),
      ...(paging ? { skip: (paging.page - 1) * paging.pageSize } : {}),
    } satisfies Prisma.AdminAuditLogFindManyArgs;
    const [logs, total] = await Promise.all([
      this.prisma.adminAuditLog.findMany(findArgs),
      paging ? this.prisma.adminAuditLog.count({ where }) : Promise.resolve(0),
    ]);
    const items = logs.map((log) => ({
      id: log.id,
      adminUserId: log.adminUserId,
      adminUserName: log.adminUser.displayName,
      adminUserEmail: log.adminUser.email,
      action: log.action,
      entityType: log.entityType,
      entityId: log.entityId ?? '',
      metadata: log.metadata ?? null,
      createdAt: log.createdAt.toISOString(),
    }));
    return paging ? this.toPagedResponse(items, total, paging) : items;
  }

  async exportBusinesses(query: JsonRecord = {}) {
    const businesses = await this.listBusinesses({
      ...query,
      page: undefined,
      pageSize: undefined,
      take: query.take ?? query.limit ?? 1000,
    });
    const rows = Array.isArray(businesses) ? businesses : businesses.items;
    return this.toCsv(
      rows.map((business) => ({
        id: business.id,
        name: business.name,
        category: business.category,
        storefrontType: business.storefrontType,
        city: business.city,
        district: business.district,
        approvalStatus: business.approvalStatus,
        isActive: business.isActive,
        productsCount: business.productsCount,
        ordersCount: business.ordersCount,
        pendingOrders: business.pendingOrders,
        createdAt: business.createdAt,
      })),
    );
  }

  async exportOrders(query: JsonRecord = {}) {
    const orders = await this.listOrders({
      ...query,
      page: undefined,
      pageSize: undefined,
      take: query.take ?? query.limit ?? 1000,
    });
    const rows = Array.isArray(orders) ? orders : orders.items;
    return this.toCsv(
      rows.map((order) => ({
        id: order.id,
        vendorId: order.vendorId,
        vendorName: order.vendorName,
        userId: order.userId,
        userName: order.userName,
        userEmail: order.userEmail,
        pickupCode: order.pickupCode,
        status: order.status,
        totalAmount: order.totalAmount,
        itemCount: order.itemCount,
        createdAt: order.createdAt,
      })),
    );
  }

  async exportUsers(query: JsonRecord = {}) {
    const users = await this.listUsers({
      ...query,
      page: undefined,
      pageSize: undefined,
      take: query.take ?? query.limit ?? 1000,
    });
    const rows = Array.isArray(users) ? users : users.items;
    return this.toCsv(
      rows.map((user) => ({
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        phone: user.phone,
        role: user.role,
        vendorId: user.vendorId,
        isSuspended: user.isSuspended,
        isBanned: user.isBanned,
        marketingOptIn: user.marketingOptIn,
        ordersCount: user.ordersCount,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
      })),
    );
  }

  private async getOrderById(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        vendor: {
          select: { id: true, name: true },
        },
        user: {
          select: { id: true, displayName: true, email: true },
        },
        pickupPoint: {
          select: { label: true },
        },
        items: true,
      },
    });
    if (!order) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }
    return this.toOrderPayload(order);
  }

  private async getProductById(productId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: {
        catalogSection: true,
        inventory: true,
      },
    });
    if (!product) {
      throw new NotFoundException(`Product ${productId} not found`);
    }
    return this.toProductPayload(product);
  }

  private async getCampaignById(campaignId: string) {
    const campaign = await this.prisma.vendorCampaign.findUnique({
      where: { id: campaignId },
      include: {
        vendor: {
          select: { id: true, name: true, storefrontType: true },
        },
      },
    });
    if (!campaign) {
      throw new NotFoundException(`Campaign ${campaignId} not found`);
    }
    const products = await this.prisma.product.findMany({
      where: {
        id: {
          in: this.stringArray(campaign.productIds),
        },
      },
      select: { id: true, title: true },
    });
    return this.toCampaignPayload(
      campaign,
      new Map(products.map((product) => [product.id, product.title])),
    );
  }

  private async ensureVendor(vendorId: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        pickupPoints: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    if (!vendor) {
      throw new NotFoundException(`Vendor ${vendorId} not found`);
    }
    return vendor;
  }

  private async ensureSection(vendorId: string, sectionId: string) {
    const section = await this.prisma.catalogSection.findUnique({
      where: { id: sectionId },
    });
    if (!section || section.vendorId !== vendorId) {
      throw new NotFoundException(`Section ${sectionId} not found`);
    }
    return section;
  }

  private async ensureUniqueVendorSlug(baseSlug: string) {
    let slug = baseSlug || `business-${Date.now()}`;
    let counter = 1;
    while (await this.prisma.vendor.findUnique({ where: { slug } })) {
      counter += 1;
      slug = `${baseSlug}-${counter}`;
    }
    return slug;
  }

  private async ensureUniqueSectionKey(vendorId: string, baseKey: string, currentId?: string) {
    let key = baseKey || `section-${Date.now()}`;
    let counter = 1;
    while (
      await this.prisma.catalogSection.findFirst({
        where: {
          vendorId,
          key,
          ...(currentId ? { id: { not: currentId } } : {}),
        },
      })
    ) {
      counter += 1;
      key = `${baseKey}-${counter}`;
    }
    return key;
  }

  private async ensureUniqueSku(baseSku: string, currentId?: string) {
    let sku = baseSku.trim().toUpperCase();
    let counter = 1;
    while (
      await this.prisma.product.findFirst({
        where: {
          sku,
          ...(currentId ? { id: { not: currentId } } : {}),
        },
      })
    ) {
      counter += 1;
      sku = `${baseSku.trim().toUpperCase()}-${counter}`;
    }
    return sku;
  }

  private async resolveVendorProductIds(vendorId: string, productIds: string[]) {
    if (productIds.length === 0) {
      return [];
    }
    const products = await this.prisma.product.findMany({
      where: {
        vendorId,
        id: { in: productIds },
      },
      select: { id: true },
    });
    return products.map((product) => product.id);
  }

  private async getOpenOrderCountByVendor() {
    const orders = await this.prisma.order.findMany({
      where: {
        status: {
          in: [
            OrderStatus.CREATED,
            OrderStatus.ACCEPTED,
            OrderStatus.PREPARING,
            OrderStatus.READY,
          ],
        },
      },
      select: { vendorId: true },
    });
    return orders.reduce((acc, order) => {
      acc.set(order.vendorId, (acc.get(order.vendorId) ?? 0) + 1);
      return acc;
    }, new Map<string, number>());
  }

  private buildDailyRevenueSeries(
    orders: Array<{
      totalAmount: Prisma.Decimal;
      createdAt: Date;
    }>,
  ) {
    const byDay = new Map<string, number>();
    for (const order of orders) {
      const key = order.createdAt.toISOString().slice(0, 10);
      byDay.set(key, (byDay.get(key) ?? 0) + Number(order.totalAmount));
    }
    return Array.from(byDay.entries())
      .sort(([left], [right]) => left.localeCompare(right))
      .slice(-7)
      .map(([date, total]) => ({ date, total }));
  }

  private toBusinessListItem(
    business: {
      id: string;
      name: string;
      category: string;
      city: string | null;
      district: string | null;
      storefrontType: StorefrontType | null;
      imageUrl: string | null;
      isActive: boolean;
      approvalStatus: VendorApprovalStatus;
      suspendedReason: string | null;
      createdAt: Date;
      operators?: Array<{ id: string }>;
      _count?: {
        products: number;
        orders: number;
        campaigns: number;
        events: number;
      };
    },
    pendingOrders = 0,
  ) {
    return {
      id: business.id,
      name: business.name,
      category: business.category,
      storefrontType: business.storefrontType ?? StorefrontType.MARKET,
      city: business.city ?? '',
      district: business.district ?? '',
      imageUrl: business.imageUrl ?? '',
      isActive: business.isActive,
      approvalStatus: business.approvalStatus,
      suspendedReason: business.suspendedReason ?? '',
      createdAt: business.createdAt.toISOString(),
      operatorsCount: business.operators?.length ?? 0,
      productsCount: business._count?.products ?? 0,
      ordersCount: business._count?.orders ?? 0,
      activeCampaigns: business._count?.campaigns ?? 0,
      eventsCount: business._count?.events ?? 0,
      pendingOrders,
    };
  }

  private toOrderPayload(order: {
    id: string;
    vendorId: string;
    pickupCode: string;
    status: OrderStatus;
    totalAmount: Prisma.Decimal;
    createdAt: Date;
    vendor: { id: string; name: string };
    user: { id: string; displayName: string; email: string };
    pickupPoint: { label: string };
    items: Array<{ title: string; quantity: number }>;
  }) {
    return {
      id: order.id,
      vendorId: order.vendorId,
      vendorName: order.vendor.name,
      userId: order.user.id,
      userName: order.user.displayName,
      userEmail: order.user.email,
      pickupCode: order.pickupCode,
      status: order.status,
      totalAmount: Number(order.totalAmount),
      createdAt: order.createdAt.toISOString(),
      pickupPointLabel: order.pickupPoint.label,
      itemCount: order.items.reduce((sum, item) => sum + item.quantity, 0),
      items: order.items.map((item) => ({
        title: item.title,
        quantity: item.quantity,
      })),
    };
  }

  private toProductPayload(product: {
    id: string;
    vendorId: string;
    title: string;
    description: string | null;
    unitPrice: Prisma.Decimal;
    imageUrl: string | null;
    kind: string;
    sku: string;
    barcode: string | null;
    externalCode: string | null;
    displaySubtitle: string | null;
    displayBadge: string | null;
    displayOrder: number;
    isFeatured: boolean;
    isVisibleInApp: boolean;
    trackStock: boolean;
    reorderLevel: number;
    isArchived: boolean;
    catalogSectionId: string | null;
    catalogSection: { id: string; label: string } | null;
    inventory: Array<{ onHand: number; reserved: number }>;
  }) {
    const onHand = product.inventory.reduce((sum, item) => sum + item.onHand, 0);
    const reserved = product.inventory.reduce((sum, item) => sum + item.reserved, 0);
    return {
      id: product.id,
      vendorId: product.vendorId,
      title: product.title,
      description: product.description ?? '',
      unitPrice: Number(product.unitPrice),
      imageUrl: product.imageUrl ?? '',
      category: product.kind,
      sku: product.sku,
      barcode: product.barcode ?? '',
      externalCode: product.externalCode ?? '',
      displaySubtitle: product.displaySubtitle ?? '',
      displayBadge: product.displayBadge ?? '',
      displayOrder: product.displayOrder,
      isFeatured: product.isFeatured,
      isVisibleInApp: product.isVisibleInApp,
      trackStock: product.trackStock,
      reorderLevel: product.reorderLevel,
      isArchived: product.isArchived,
      sectionId: product.catalogSectionId ?? '',
      sectionLabel: product.catalogSection?.label ?? '',
      availableQuantity: Math.max(0, onHand - reserved),
      reservedQuantity: reserved,
    };
  }

  private toCampaignPayload(
    campaign: {
      id: string;
      vendorId: string;
      title: string;
      description: string | null;
      kind: CampaignKind;
      status: CampaignStatus;
      scheduleLabel: string | null;
      badgeLabel: string | null;
      discountPercent: number | null;
      discountedPrice: Prisma.Decimal | null;
      startsAt: Date | null;
      endsAt: Date | null;
      productIds: Prisma.JsonValue;
      vendor: { id: string; name: string; storefrontType: StorefrontType | null };
    },
    productTitleById = new Map<string, string>(),
  ) {
    const productIds = this.stringArray(campaign.productIds);
    return {
      id: campaign.id,
      vendorId: campaign.vendorId,
      vendorName: campaign.vendor.name,
      storefrontType: campaign.vendor.storefrontType ?? StorefrontType.MARKET,
      title: campaign.title,
      description: campaign.description ?? '',
      kind: campaign.kind,
      status: campaign.status,
      scheduleLabel: campaign.scheduleLabel ?? '',
      badgeLabel: campaign.badgeLabel ?? '',
      discountPercent: campaign.discountPercent ?? 0,
      discountedPrice: campaign.discountedPrice ? Number(campaign.discountedPrice) : 0,
      startsAt: campaign.startsAt?.toISOString() ?? null,
      endsAt: campaign.endsAt?.toISOString() ?? null,
      productIds,
      productTitles: productIds.map((productId) => productTitleById.get(productId) ?? productId),
    };
  }

  private async logAction(
    adminUserId: string,
    action: string,
    entityType: string,
    entityId: string,
    metadata?: unknown,
  ) {
    await this.prisma.adminAuditLog.create({
      data: {
        adminUserId,
        action,
        entityType,
        entityId,
        metadata: metadata as Prisma.InputJsonValue | undefined,
      },
    });
  }

  private async logNotificationDeliveryPlaceholder(notificationId: string) {
    await this.prisma.adminNotificationDeliveryLog.create({
      data: {
        notificationId,
        provider: process.env.ADMIN_NOTIFICATION_PROVIDER || 'unconfigured',
        status: process.env.ADMIN_NOTIFICATION_PROVIDER ? 'QUEUED' : 'NOT_CONFIGURED',
        errorMessage: process.env.ADMIN_NOTIFICATION_PROVIDER
          ? null
          : 'Notification provider configured değil',
      },
    });
  }

  private objectPayload(value: unknown): JsonRecord {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return {};
    }
    return value as JsonRecord;
  }

  private requiredIdArray(value: unknown, message: string) {
    const ids = this.stringArray(value);
    if (ids.length === 0) {
      throw new BadRequestException(message);
    }
    return Array.from(new Set(ids)).slice(0, 500);
  }

  private parseTake(value: unknown, fallback: number) {
    const parsed = this.parseInteger(value, fallback);
    if (parsed <= 0) {
      return fallback;
    }
    return Math.min(parsed, 1000);
  }

  private parsePaging(query: JsonRecord) {
    if (query.page === undefined && query.pageSize === undefined) {
      return null;
    }
    const page = Math.max(1, this.parseInteger(query.page, 1));
    const pageSize = Math.min(100, Math.max(1, this.parseInteger(query.pageSize, 25)));
    return { page, pageSize };
  }

  private toPagedResponse<T>(
    items: T[],
    total: number,
    paging: { page: number; pageSize: number },
  ) {
    return {
      items,
      total,
      page: paging.page,
      pageSize: paging.pageSize,
    };
  }

  private optionalBoolean(value: unknown) {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    return this.parseBoolean(value, false);
  }

  private optionalStorefrontType(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(StorefrontType).includes(normalized as StorefrontType)) {
      return normalized as StorefrontType;
    }
    return undefined;
  }

  private optionalVendorApprovalStatus(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(VendorApprovalStatus).includes(normalized as VendorApprovalStatus)) {
      return normalized as VendorApprovalStatus;
    }
    return undefined;
  }

  private optionalOrderStatus(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(OrderStatus).includes(normalized as OrderStatus)) {
      return normalized as OrderStatus;
    }
    return undefined;
  }

  private optionalUserRole(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(PrismaRole).includes(normalized as PrismaRole)) {
      return normalized as PrismaRole;
    }
    return undefined;
  }

  private optionalNotificationStatus(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (
      Object.values(AdminNotificationStatus).includes(
        normalized as AdminNotificationStatus,
      )
    ) {
      return normalized as AdminNotificationStatus;
    }
    return undefined;
  }

  private optionalNotificationAudience(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (
      Object.values(AdminNotificationAudience).includes(
        normalized as AdminNotificationAudience,
      )
    ) {
      return normalized as AdminNotificationAudience;
    }
    return undefined;
  }

  private optionalSupportStatus(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(SupportStatus).includes(normalized as SupportStatus)) {
      return normalized as SupportStatus;
    }
    return undefined;
  }

  private optionalSupportPriority(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(SupportPriority).includes(normalized as SupportPriority)) {
      return normalized as SupportPriority;
    }
    return undefined;
  }

  private dateRangeFilter(fromValue: unknown, toValue: unknown) {
    const from = this.optionalDate(fromValue);
    const to = this.optionalDate(toValue);
    if (!from && !to) {
      return undefined;
    }
    return {
      ...(from ? { gte: from } : {}),
      ...(to ? { lte: to } : {}),
    };
  }

  private toCsv(rows: CsvRow[]) {
    if (rows.length === 0) {
      return '';
    }
    const headers = Object.keys(rows[0]);
    return [
      headers.join(','),
      ...rows.map((row) =>
        headers.map((header) => this.escapeCsvValue(row[header])).join(','),
      ),
    ].join('\n');
  }

  private escapeCsvValue(value: CsvValue) {
    if (value === undefined || value === null) {
      return '';
    }
    const normalized = String(value);
    if (/["\n,]/.test(normalized)) {
      return `"${normalized.replace(/"/g, '""')}"`;
    }
    return normalized;
  }

  private requireString(value: unknown, message: string) {
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new BadRequestException(message);
    }
    return value.trim();
  }

  private optionalString(value: unknown) {
    return typeof value === 'string' ? value.trim() : '';
  }

  private optionalImageUrl(value: unknown) {
    const imageUrl = this.optionalString(value);
    if (imageUrl.toLowerCase().startsWith('data:')) {
      throw new BadRequestException('Görsel için dosya içeriği değil, güvenli URL gönderilmelidir');
    }
    return imageUrl;
  }

  private parseInteger(value: unknown, fallback: number) {
    if (value === undefined || value === null || value === '') {
      return fallback;
    }
    const parsed = Number.parseInt(String(value), 10);
    if (!Number.isFinite(parsed)) {
      throw new BadRequestException('Sayı değeri geçersiz');
    }
    return parsed;
  }

  private optionalInteger(value: unknown) {
    if (value === undefined || value === null || value === '') {
      return null;
    }
    return this.parseInteger(value, 0);
  }

  private parseDecimal(value: unknown, message: string) {
    const parsed = Number.parseFloat(String(value));
    if (!Number.isFinite(parsed)) {
      throw new BadRequestException(message);
    }
    return new Prisma.Decimal(parsed.toFixed(2));
  }

  private parseBoolean(value: unknown, fallback: boolean) {
    if (value === undefined || value === null || value === '') {
      return fallback;
    }
    if (typeof value === 'boolean') {
      return value;
    }
    const normalized = String(value).trim().toLowerCase();
    if (['true', '1', 'yes', 'evet'].includes(normalized)) {
      return true;
    }
    if (['false', '0', 'no', 'hayir', 'hayır'].includes(normalized)) {
      return false;
    }
    return fallback;
  }

  private requiredDate(value: unknown, message: string) {
    const date = this.optionalDate(value);
    if (!date) {
      throw new BadRequestException(message);
    }
    return date;
  }

  private optionalDate(value: unknown) {
    if (value === undefined || value === null || value === '') {
      return null;
    }
    const date = new Date(String(value));
    if (Number.isNaN(date.getTime())) {
      throw new BadRequestException('Tarih değeri geçersiz');
    }
    return date;
  }

  private parseStorefrontType(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    return normalized === StorefrontType.RESTAURANT
      ? StorefrontType.RESTAURANT
      : StorefrontType.MARKET;
  }

  private parseVendorApprovalStatus(value: unknown, allowDefault = false) {
    const normalized = this.optionalString(value).toUpperCase();
    if (!normalized && allowDefault) {
      return VendorApprovalStatus.APPROVED;
    }
    if (normalized === VendorApprovalStatus.PENDING) {
      return VendorApprovalStatus.PENDING;
    }
    if (normalized === VendorApprovalStatus.REJECTED) {
      return VendorApprovalStatus.REJECTED;
    }
    if (normalized === VendorApprovalStatus.SUSPENDED) {
      return VendorApprovalStatus.SUSPENDED;
    }
    return VendorApprovalStatus.APPROVED;
  }

  private parseOrderStatus(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(OrderStatus).includes(normalized as OrderStatus)) {
      return normalized as OrderStatus;
    }
    throw new BadRequestException('Sipariş durumu geçersiz');
  }

  private parseCampaignKind(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(CampaignKind).includes(normalized as CampaignKind)) {
      return normalized as CampaignKind;
    }
    return CampaignKind.DISCOUNT;
  }

  private parseCampaignStatus(value: unknown, allowDefault = false) {
    const normalized = this.optionalString(value).toUpperCase();
    if (!normalized && allowDefault) {
      return CampaignStatus.ACTIVE;
    }
    if (Object.values(CampaignStatus).includes(normalized as CampaignStatus)) {
      return normalized as CampaignStatus;
    }
    return CampaignStatus.DRAFT;
  }

  private parseUserRole(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (normalized === PrismaRole.VENDOR) {
      return PrismaRole.VENDOR;
    }
    if (normalized === PrismaRole.SUPPORT) {
      return PrismaRole.SUPPORT;
    }
    return PrismaRole.CUSTOMER;
  }

  private parseNotificationStatus(value: unknown, allowDefault = false) {
    const normalized = this.optionalString(value).toUpperCase();
    if (!normalized && allowDefault) {
      return AdminNotificationStatus.DRAFT;
    }
    if (
      Object.values(AdminNotificationStatus).includes(
        normalized as AdminNotificationStatus,
      )
    ) {
      return normalized as AdminNotificationStatus;
    }
    return AdminNotificationStatus.DRAFT;
  }

  private parseNotificationAudience(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (
      Object.values(AdminNotificationAudience).includes(
        normalized as AdminNotificationAudience,
      )
    ) {
      return normalized as AdminNotificationAudience;
    }
    return AdminNotificationAudience.ALL_USERS;
  }

  private parseSupportStatus(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(SupportStatus).includes(normalized as SupportStatus)) {
      return normalized as SupportStatus;
    }
    throw new BadRequestException('Destek durumu geçersiz');
  }

  private parseSupportPriority(value: unknown) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(SupportPriority).includes(normalized as SupportPriority)) {
      return normalized as SupportPriority;
    }
    return SupportPriority.NORMAL;
  }

  private parsePayoutStatus(value: unknown, fallback: PayoutStatus) {
    const normalized = this.optionalString(value).toUpperCase();
    if (Object.values(PayoutStatus).includes(normalized as PayoutStatus)) {
      return normalized as PayoutStatus;
    }
    return fallback;
  }

  private stringArray(value: unknown) {
    if (!Array.isArray(value)) {
      if (
        value &&
        typeof value === 'object' &&
        'map' in (value as Record<string, unknown>) &&
        Array.isArray(value)
      ) {
        return value.map(String);
      }
      if (Array.isArray(value)) {
        return value.map((item) => String(item).trim()).filter(Boolean);
      }
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        return [];
      }
      return [];
    }
    return value.map((item) => String(item).trim()).filter(Boolean);
  }

  private toNullableJson(value: unknown): Prisma.InputJsonValue | typeof Prisma.JsonNull {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return Prisma.JsonNull;
    }
    return value as Prisma.InputJsonValue;
  }

  private slugify(value: string) {
    const normalized = value
      .toLowerCase()
      .replace(/ğ/g, 'g')
      .replace(/ü/g, 'u')
      .replace(/ş/g, 's')
      .replace(/ı/g, 'i')
      .replace(/ö/g, 'o')
      .replace(/ç/g, 'c')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
    return normalized || createHash('sha1').update(value).digest('hex').slice(0, 8);
  }

  private isOpenOrder(status: OrderStatus) {
    return status !== OrderStatus.COMPLETED && status !== OrderStatus.CANCELLED;
  }

  private etaLabelForStatus(status: OrderStatus) {
    if (status === OrderStatus.ACCEPTED) {
      return '10 dk';
    }
    if (status === OrderStatus.PREPARING) {
      return '8 dk';
    }
    if (status === OrderStatus.READY) {
      return 'Hazır';
    }
    if (status === OrderStatus.COMPLETED) {
      return 'Tamamlandı';
    }
    if (status === OrderStatus.CANCELLED) {
      return 'İptal';
    }
    return '12 dk';
  }
}
