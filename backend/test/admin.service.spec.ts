import {
  OrderStatus,
  PayoutStatus,
  Prisma,
  Role as PrismaRole,
  StorefrontType,
  SupportStatus,
  VendorApprovalStatus,
} from '@prisma/client';

import { AdminService } from '../admin_backend/src/admin/admin.service';

describe('AdminService', () => {
  let prisma: any;
  let service: AdminService;
  const adminUser = {
    id: 'admin-1',
    role: PrismaRole.ADMIN,
  } as any;

  beforeEach(() => {
    prisma = {
      $transaction: jest.fn(),
      vendor: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        findUniqueOrThrow: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      pickupPoint: {
        create: jest.fn(),
        update: jest.fn(),
      },
      user: {
        create: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        updateMany: jest.fn(),
      },
      order: {
        findMany: jest.fn(),
        updateMany: jest.fn(),
      },
      product: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      inventoryStock: {
        create: jest.fn(),
        update: jest.fn(),
      },
      adminAuditLog: {
        create: jest.fn(),
        findMany: jest.fn(),
      },
      adminNotification: {
        findMany: jest.fn(),
      },
      supportTicket: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      supportTicketMessage: {
        create: jest.fn(),
      },
      vendorBankAccount: {
        findUnique: jest.fn(),
      },
      vendorPayout: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        findMany: jest.fn(),
      },
    };
    service = new AdminService(prisma);
  });

  it('updates business approval and active state for suspension flows', async () => {
    const tx = {
      vendor: { update: jest.fn() },
      pickupPoint: { update: jest.fn() },
    };
    prisma.vendor.findUnique.mockResolvedValue({
      id: 'vendor-1',
      name: 'Kampus Kafe',
      category: 'Kafe',
      city: 'Istanbul',
      district: 'Kadikoy',
      storefrontType: StorefrontType.MARKET,
      imageUrl: null,
      isActive: true,
      approvalStatus: VendorApprovalStatus.APPROVED,
      suspendedReason: null,
      createdAt: new Date('2026-04-01T09:00:00.000Z'),
      pickupPoints: [
        {
          id: 'pickup-1',
          label: 'Eski teslim noktası',
          address: 'Eski adres',
        },
      ],
      operators: [],
      _count: { products: 10, orders: 4, campaigns: 2, events: 1 },
    });
    prisma.$transaction.mockImplementation(async (callback: (client: typeof tx) => Promise<unknown>) =>
      callback(tx),
    );
    jest.spyOn(service, 'getBusinessProfile').mockResolvedValue({
      business: {
        id: 'vendor-1',
        name: 'Kampus Kafe',
        category: 'Kafe',
        storefrontType: 'MARKET',
        city: 'Istanbul',
        district: 'Kadikoy',
        imageUrl: '',
        isActive: false,
        approvalStatus: 'SUSPENDED',
        suspendedReason: 'Eksik belge',
        createdAt: '2026-04-01T09:00:00.000Z',
        operatorsCount: 0,
        productsCount: 10,
        ordersCount: 4,
        activeCampaigns: 2,
        eventsCount: 1,
        pendingOrders: 0,
      },
      subtitle: '',
      city: 'Istanbul',
      district: 'Kadikoy',
      imageUrl: '',
      announcement: '',
      workingHoursLabel: '',
      pickupPoints: [],
      operators: [],
      bankAccounts: [],
    });

    await service.updateBusiness(adminUser, 'vendor-1', {
      approvalStatus: 'SUSPENDED',
      isActive: false,
      suspendedReason: 'Eksik belge',
      pickupPointLabel: 'Yeni teslim noktası',
    });

    expect(tx.vendor.update).toHaveBeenCalledWith({
      where: { id: 'vendor-1' },
      data: expect.objectContaining({
        approvalStatus: VendorApprovalStatus.SUSPENDED,
        isActive: false,
        suspendedReason: 'Eksik belge',
      }),
    });
    expect(tx.pickupPoint.update).toHaveBeenCalledWith({
      where: { id: 'pickup-1' },
      data: { label: 'Yeni teslim noktası' },
    });
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        adminUserId: 'admin-1',
        action: 'business.update',
        entityType: 'vendor',
        entityId: 'vendor-1',
      }),
    });
  });

  it('creates business products with selected category, section and image', async () => {
    jest.spyOn(service as any, 'ensureVendor').mockResolvedValue({
      id: 'vendor-1',
      category: 'Kafe',
      pickupPoints: [{ label: 'Ana bar' }],
    });
    jest.spyOn(service as any, 'ensureSection').mockResolvedValue(undefined);
    jest.spyOn(service as any, 'ensureUniqueSku').mockResolvedValue('LATTE-001');
    jest.spyOn(service as any, 'getProductById').mockResolvedValue({
      id: 'product-1',
      title: 'Latte',
    });
    prisma.product.create.mockResolvedValue({
      id: 'product-1',
      vendorId: 'vendor-1',
      catalogSectionId: 'section-1',
      title: 'Latte',
      description: 'Kahve',
      unitPrice: new Prisma.Decimal(95),
      imageUrl: 'https://cdn.example.com/products/latte.png',
      kind: 'Kahve',
      sku: 'LATTE-001',
      barcode: null,
      externalCode: null,
      displaySubtitle: null,
      displayBadge: null,
      displayOrder: 0,
      isFeatured: false,
      isVisibleInApp: true,
      trackStock: true,
      reorderLevel: 3,
      isArchived: false,
      catalogSection: null,
      inventory: [],
      createdAt: new Date('2026-04-15T09:00:00.000Z'),
      updatedAt: new Date('2026-04-15T09:00:00.000Z'),
    });

    await service.createBusinessProduct(adminUser, 'vendor-1', {
      title: 'Latte',
      description: 'Kahve',
      unitPrice: '95',
      category: 'Kahve',
      sectionId: 'section-1',
      imageUrl: 'https://cdn.example.com/products/latte.png',
      initialStock: '12',
    });

    expect(prisma.product.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        vendorId: 'vendor-1',
        catalogSectionId: 'section-1',
        title: 'Latte',
        unitPrice: new Prisma.Decimal(95),
        imageUrl: 'https://cdn.example.com/products/latte.png',
        kind: 'Kahve',
        sku: 'LATTE-001',
      }),
      include: {
        catalogSection: true,
        inventory: true,
      },
    });
    expect(prisma.inventoryStock.create).toHaveBeenCalledWith({
      data: {
        productId: 'product-1',
        vendorId: 'vendor-1',
        locationId: 'vendor-1:main',
        locationLabel: 'Ana bar',
        onHand: 12,
        reserved: 0,
      },
    });
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        adminUserId: 'admin-1',
        action: 'product.create',
        entityType: 'product',
        entityId: 'product-1',
      }),
    });
  });

  it('updates business products with dropdown-driven category and stock changes', async () => {
    const tx = {
      product: { update: jest.fn() },
      inventoryStock: { update: jest.fn() },
    };
    prisma.product.findUnique.mockResolvedValue({
      id: 'product-1',
      vendorId: 'vendor-1',
      displayOrder: 0,
      isFeatured: false,
      isVisibleInApp: true,
      trackStock: true,
      reorderLevel: 3,
      isArchived: false,
      inventory: [{ id: 'inventory-1', onHand: 5 }],
    });
    prisma.$transaction.mockImplementation(async (callback: (client: typeof tx) => Promise<unknown>) =>
      callback(tx),
    );
    jest.spyOn(service as any, 'ensureSection').mockResolvedValue(undefined);
    jest.spyOn(service as any, 'getProductById').mockResolvedValue({
      id: 'product-1',
      title: 'Latte',
      category: 'Tatli',
    });

    await service.updateBusinessProduct(adminUser, 'vendor-1', 'product-1', {
      category: 'Tatli',
      sectionId: 'section-2',
      initialStock: '18',
      isArchived: true,
      imageUrl: 'https://cdn.example.com/products/latte-updated.jpg',
    });

    expect(tx.product.update).toHaveBeenCalledWith({
      where: { id: 'product-1' },
      data: expect.objectContaining({
        kind: 'Tatli',
        catalogSectionId: 'section-2',
        isArchived: true,
        imageUrl: 'https://cdn.example.com/products/latte-updated.jpg',
      }),
    });
    expect(tx.inventoryStock.update).toHaveBeenCalledWith({
      where: { id: 'inventory-1' },
      data: { onHand: 18 },
    });
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        adminUserId: 'admin-1',
        action: 'product.update',
        entityType: 'product',
        entityId: 'product-1',
      }),
    });
  });

  it('lists orders with advanced filters and bounded pagination', async () => {
    prisma.order.findMany.mockResolvedValue([
      {
        id: 'order-1',
        vendorId: 'vendor-1',
        pickupCode: 'SP-100',
        status: OrderStatus.READY,
        totalAmount: new Prisma.Decimal(120),
        createdAt: new Date('2026-04-15T12:00:00.000Z'),
        vendor: { id: 'vendor-1', name: 'Kampus Kafe' },
        user: { id: 'user-1', displayName: 'Ali Veli', email: 'ali@example.com' },
        pickupPoint: { label: 'Ana nokta' },
        items: [{ title: 'Latte', quantity: 2 }],
      },
    ]);

    const result = await service.listOrders({
      status: 'READY',
      vendorId: 'vendor-1',
      q: 'ali',
      take: '25',
    });

    expect(prisma.order.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: OrderStatus.READY,
          vendorId: 'vendor-1',
          OR: expect.any(Array),
        }),
        take: 25,
      }),
    );
    expect(Array.isArray(result)).toBe(true);
    if (!Array.isArray(result)) {
      throw new Error('Expected listOrders without page/pageSize to return an array.');
    }
    expect(result[0]).toEqual(
      expect.objectContaining({
        id: 'order-1',
        vendorName: 'Kampus Kafe',
        itemCount: 2,
      }),
    );
  });

  it('bulk updates businesses and writes an audit record', async () => {
    prisma.vendor.updateMany.mockResolvedValue({ count: 2 });

    await expect(
      service.bulkUpdateBusinesses(adminUser, {
        vendorIds: ['vendor-1', 'vendor-2', 'vendor-1'],
        patch: {
          approvalStatus: 'SUSPENDED',
          isActive: false,
          suspendedReason: 'Belge eksik',
        },
      }),
    ).resolves.toEqual({ updatedCount: 2 });

    expect(prisma.vendor.updateMany).toHaveBeenCalledWith({
      where: { id: { in: ['vendor-1', 'vendor-2'] } },
      data: {
        approvalStatus: VendorApprovalStatus.SUSPENDED,
        isActive: false,
        suspendedReason: 'Belge eksik',
      },
    });
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        action: 'business.bulk.update',
        entityType: 'vendor',
        entityId: 'bulk',
      }),
    });
  });

  it('lists audit logs with admin metadata', async () => {
    prisma.adminAuditLog.findMany.mockResolvedValue([
      {
        id: 'audit-1',
        adminUserId: 'admin-1',
        action: 'business.update',
        entityType: 'vendor',
        entityId: 'vendor-1',
        metadata: { isActive: false },
        createdAt: new Date('2026-04-15T13:00:00.000Z'),
        adminUser: {
          id: 'admin-1',
          email: 'admin@speto.app',
          displayName: 'Speto Admin',
        },
      },
    ]);

    const result = await service.listAuditLogs({
      entityType: 'vendor',
      q: 'business',
      limit: '10',
    });

    expect(prisma.adminAuditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          entityType: { contains: 'vendor', mode: 'insensitive' },
          OR: expect.any(Array),
        }),
        take: 10,
      }),
    );
    expect(result).toEqual([
      expect.objectContaining({
        id: 'audit-1',
        adminUserEmail: 'admin@speto.app',
        action: 'business.update',
      }),
    ]);
  });

  it('exports business rows as csv without using localhost-only assumptions', async () => {
    jest.spyOn(service, 'listBusinesses').mockResolvedValue([
      {
        id: 'vendor-1',
        name: 'Kampus, Kafe',
        category: 'Kafe',
        storefrontType: 'MARKET',
        city: 'Istanbul',
        district: 'Kadikoy',
        imageUrl: '',
        isActive: true,
        approvalStatus: 'APPROVED',
        suspendedReason: '',
        createdAt: '2026-04-15T12:00:00.000Z',
        operatorsCount: 1,
        productsCount: 20,
        ordersCount: 3,
        activeCampaigns: 2,
        eventsCount: 0,
        pendingOrders: 1,
      },
    ] as any);

    const csv = await service.exportBusinesses();

    expect(csv).toContain('id,name,category');
    expect(csv).toContain('"Kampus, Kafe"');
  });

  it('returns typed unconfigured upload intent when no provider is configured', async () => {
    const previousProvider = process.env.ADMIN_UPLOAD_PROVIDER;
    delete process.env.ADMIN_UPLOAD_PROVIDER;
    let intent: Awaited<ReturnType<AdminService['createUploadIntent']>>;
    try {
      intent = await service.createUploadIntent({
        fileName: 'latte.png',
        contentType: 'image/png',
        folder: 'products',
      });
    } finally {
      if (previousProvider === undefined) {
        delete process.env.ADMIN_UPLOAD_PROVIDER;
      } else {
        process.env.ADMIN_UPLOAD_PROVIDER = previousProvider;
      }
    }

    expect(intent).toEqual(
      expect.objectContaining({
        configured: false,
        uploadUrl: null,
        publicUrl: null,
        requested: {
          fileName: 'latte.png',
          contentType: 'image/png',
          folder: 'products',
        },
      }),
    );
  });

  it('creates support ticket messages and moves the ticket into progress', async () => {
    prisma.supportTicket.findUnique.mockResolvedValue({ id: 'ticket-1' });
    prisma.supportTicketMessage.create.mockResolvedValue({
      id: 'message-1',
      ticketId: 'ticket-1',
      authorId: 'admin-1',
      body: 'Kullanıcıya dönüş yapıldı.',
      isInternal: false,
      createdAt: new Date('2026-04-15T14:00:00.000Z'),
      author: {
        id: 'admin-1',
        displayName: 'Speto Admin',
        email: 'admin@speto.app',
        role: PrismaRole.ADMIN,
      },
    });

    const message = await service.createSupportTicketMessage(adminUser, 'ticket-1', {
      body: 'Kullanıcıya dönüş yapıldı.',
    });

    expect(prisma.supportTicketMessage.create).toHaveBeenCalledWith({
      data: {
        ticketId: 'ticket-1',
        authorId: 'admin-1',
        body: 'Kullanıcıya dönüş yapıldı.',
        isInternal: false,
      },
      include: {
        author: {
          select: { id: true, displayName: true, email: true, role: true },
        },
      },
    });
    expect(prisma.supportTicket.update).toHaveBeenCalledWith({
      where: { id: 'ticket-1' },
      data: { status: SupportStatus.IN_PROGRESS },
    });
    expect(message).toEqual(
      expect.objectContaining({
        id: 'message-1',
        authorRole: PrismaRole.ADMIN,
      }),
    );
  });

  it('creates manual payouts against a vendor bank account', async () => {
    jest.spyOn(service as any, 'ensureVendor').mockResolvedValue({ id: 'vendor-1' });
    jest.spyOn(service, 'getFinanceSummary').mockResolvedValue({ recentPayouts: [] } as any);
    prisma.vendorBankAccount.findUnique.mockResolvedValue({
      id: 'bank-1',
      vendorId: 'vendor-1',
    });
    prisma.vendorPayout.create.mockResolvedValue({
      id: 'payout-1',
      vendorId: 'vendor-1',
      bankAccountId: 'bank-1',
      amount: new Prisma.Decimal(250),
      status: PayoutStatus.PENDING,
    });

    await service.createPayout(adminUser, {
      vendorId: 'vendor-1',
      bankAccountId: 'bank-1',
      amount: '250',
      note: 'Haftalık ödeme',
    });

    expect(prisma.vendorPayout.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        vendorId: 'vendor-1',
        bankAccountId: 'bank-1',
        amount: new Prisma.Decimal(250),
        status: PayoutStatus.PENDING,
        note: 'Haftalık ödeme',
      }),
    });
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        action: 'payout.create',
        entityType: 'vendor-payout',
        entityId: 'payout-1',
      }),
    });
  });

  it('includes delivery logs when listing notifications', async () => {
    prisma.adminNotification.findMany.mockResolvedValue([
      {
        id: 'notification-1',
        title: 'Bakim Bildirimi',
        body: 'Sistem 23:00 itibariyla bakima alinacak.',
        audience: 'ALL_USERS',
        status: 'SENT',
        scheduledAt: null,
        sentAt: new Date('2026-04-15T12:05:00.000Z'),
        createdAt: new Date('2026-04-15T12:00:00.000Z'),
        updatedAt: new Date('2026-04-15T12:05:00.000Z'),
        createdByAdmin: {
          displayName: 'Speto Admin',
          email: 'admin@speto.app',
        },
        deliveryLogs: [
          {
            id: 'delivery-1',
            notificationId: 'notification-1',
            provider: 'unconfigured',
            status: 'NOT_CONFIGURED',
            target: null,
            errorMessage: 'Notification provider configured değil',
            createdAt: new Date('2026-04-15T12:05:00.000Z'),
          },
        ],
      },
    ]);

    const result = await service.listNotifications({ limit: '10' });

    expect(Array.isArray(result)).toBe(true);
    if (!Array.isArray(result)) {
      throw new Error('Expected notifications list without paging to return an array.');
    }
    expect(result[0]).toEqual(
      expect.objectContaining({
        id: 'notification-1',
        deliveryLogs: [
          expect.objectContaining({
            provider: 'unconfigured',
            status: 'NOT_CONFIGURED',
          }),
        ],
      }),
    );
  });

  it('exposes payout notes in finance summary rows', async () => {
    prisma.vendor.findMany.mockResolvedValue([
      {
        id: 'vendor-1',
        name: 'Kampus Kafe',
      },
    ]);
    prisma.order.findMany.mockResolvedValue([
      {
        vendorId: 'vendor-1',
        totalAmount: new Prisma.Decimal(500),
      },
    ]);
    prisma.vendorPayout.findMany.mockResolvedValue([
      {
        id: 'payout-1',
        vendorId: 'vendor-1',
        amount: new Prisma.Decimal(200),
        status: PayoutStatus.PAID,
        requestedAt: new Date('2026-04-15T10:00:00.000Z'),
        completedAt: new Date('2026-04-15T11:00:00.000Z'),
        note: 'Haftalık ödeme',
        vendor: { id: 'vendor-1', name: 'Kampus Kafe' },
        bankAccount: { bankName: 'Yapi Kredi', iban: 'TR00 0000 0000 0000 0000 00' },
      },
    ]);

    const summary = await service.getFinanceSummary();

    expect(summary.recentPayouts[0]).toEqual(
      expect.objectContaining({
        id: 'payout-1',
        note: 'Haftalık ödeme',
      }),
    );
  });
});
