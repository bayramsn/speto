import { Prisma, Role as PrismaRole, StorefrontType, VendorApprovalStatus } from '@prisma/client';

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
        findUnique: jest.fn(),
        findUniqueOrThrow: jest.fn(),
        update: jest.fn(),
      },
      pickupPoint: {
        create: jest.fn(),
        update: jest.fn(),
      },
      user: {
        create: jest.fn(),
      },
      product: {
        create: jest.fn(),
        findUnique: jest.fn(),
      },
      inventoryStock: {
        create: jest.fn(),
        update: jest.fn(),
      },
      adminAuditLog: {
        create: jest.fn(),
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
      imageUrl: 'data:image/png;base64,abc',
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
      imageUrl: 'data:image/png;base64,abc',
      initialStock: '12',
    });

    expect(prisma.product.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        vendorId: 'vendor-1',
        catalogSectionId: 'section-1',
        title: 'Latte',
        unitPrice: new Prisma.Decimal(95),
        imageUrl: 'data:image/png;base64,abc',
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
      imageUrl: 'data:image/jpeg;base64,xyz',
    });

    expect(tx.product.update).toHaveBeenCalledWith({
      where: { id: 'product-1' },
      data: expect.objectContaining({
        kind: 'Tatli',
        catalogSectionId: 'section-2',
        isArchived: true,
        imageUrl: 'data:image/jpeg;base64,xyz',
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
});
