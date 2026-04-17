import { BadRequestException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import {
  CampaignKind as PrismaCampaignKind,
  CampaignStatus as PrismaCampaignStatus,
  PayoutStatus as PrismaPayoutStatus,
  Role as PrismaRole,
  StorefrontType as PrismaStorefrontType,
  VendorApprovalStatus as PrismaVendorApprovalStatus,
} from '@prisma/client';

import { AppDataService } from '../src/app-data/app-data.service';

describe('AppDataService stock ops flows', () => {
  let prisma: any;
  let requestContext: any;
  let jwtTokenService: any;
  let service: AppDataService;

  beforeEach(() => {
    prisma = {
      $transaction: jest.fn(),
      user: {
        findUnique: jest.fn(),
      },
      vendor: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findUnique: jest.fn(),
      },
      catalogSection: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      order: {
        findMany: jest.fn(),
      },
      product: {
        findMany: jest.fn(),
      },
      vendorBankAccount: {
        count: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        updateMany: jest.fn(),
      },
      vendorPayout: {
        create: jest.fn(),
        findMany: jest.fn(),
      },
      vendorCampaign: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };
    requestContext = { userId: undefined };
    jwtTokenService = {};
    service = new AppDataService(prisma, requestContext, jwtTokenService);
    jest
      .spyOn(service as any, 'ensureInitialized')
      .mockResolvedValue(undefined);
  });

  it('registerOperator provisions vendor, operator consents and bank account', async () => {
    const tx = {
      vendor: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn(),
      },
      pickupPoint: {
        create: jest.fn(),
      },
      catalogSection: {
        create: jest.fn(),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue({ id: 'usr_vendor_1' }),
        update: jest.fn(),
      },
      vendorBankAccount: {
        create: jest.fn(),
      },
    };
    prisma.$transaction.mockImplementation(
      async (callback: (client: typeof tx) => Promise<unknown>) => callback(tx),
    );
    prisma.user.findUnique.mockResolvedValue({
      id: 'usr_vendor_1',
      email: 'ops@meydan.app',
      passwordHash: 'hashed',
      displayName: 'Meydan Operasyon',
      phone: '+90 555 111 11 11',
      role: PrismaRole.VENDOR,
      vendorId: 'vendor-meydan-market',
      studentVerifiedAt: null,
      termsAcceptedAt: new Date('2026-04-12T09:00:00.000Z'),
      privacyAcceptedAt: new Date('2026-04-12T09:00:00.000Z'),
      marketingOptIn: true,
      opsNotificationPreferences: {
        newOrders: true,
        cancellations: true,
        lowStock: true,
        campaignTips: false,
      },
      notificationsEnabled: true,
      avatarUrl: '',
      createdAt: new Date('2026-04-12T09:00:00.000Z'),
      updatedAt: new Date('2026-04-12T09:00:00.000Z'),
    });
    jest.spyOn(service as any, 'upsertVendorOperator').mockResolvedValue(undefined);
    jest.spyOn(service as any, 'buildSessionResponse').mockResolvedValue({
      user: { id: 'usr_vendor_1' },
      tokens: { accessToken: 'access', refreshToken: 'refresh' },
    });

    const response = await service.registerOperator({
      storefrontType: 'MARKET',
      business: {
        name: 'Meydan Market',
        category: 'Market',
        subtitle: 'Kampüs içi market',
        imageUrl: 'https://example.com/market.jpg',
        city: 'Istanbul',
        district: 'Kadikoy',
        pickupPointLabel: 'Ana kasa',
        pickupPointAddress: 'Kampüs merkez blok',
        workingHoursLabel: 'Pzt-Paz 09:00-22:00',
        workingDays: [
          {
            label: 'Pazartesi',
            shortLabel: 'Pzt',
            isOpen: true,
            openTime: '09:00',
            closeTime: '22:00',
          },
        ],
        taxNumber: '1234567890',
        taxOffice: 'Kadikoy',
      },
      operator: {
        email: 'ops@meydan.app',
        password: 'vendor123',
        displayName: 'Meydan Operasyon',
        phone: '+90 555 111 11 11',
      },
      bankAccount: {
        holderName: 'Meydan Market Ltd.',
        bankName: 'Akbank',
        iban: 'TR100006200000000001234567',
      },
      consents: {
        termsAccepted: true,
        privacyAccepted: true,
        marketingOptIn: true,
      },
      notifications: {
        newOrders: true,
        cancellations: true,
        lowStock: true,
        campaignTips: false,
        sms: false,
        push: true,
      },
    });

    expect(tx.vendor.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: 'vendor-meydan-market',
        name: 'Meydan Market',
        storefrontType: PrismaStorefrontType.MARKET,
        category: 'Market',
        city: 'Istanbul',
        district: 'Kadikoy',
        taxNumber: '1234567890',
        taxOffice: 'Kadikoy',
        workingDays: [
          {
            label: 'Pazartesi',
            shortLabel: 'Pzt',
            isOpen: true,
            openTime: '09:00',
            closeTime: '22:00',
          },
        ],
      }),
    });
    expect((service as any).upsertVendorOperator).toHaveBeenCalledWith(
      tx,
      expect.objectContaining({
        vendorId: 'vendor-meydan-market',
        email: 'ops@meydan.app',
      }),
    );
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'usr_vendor_1' },
      data: expect.objectContaining({
        termsAcceptedAt: expect.any(Date),
        privacyAcceptedAt: expect.any(Date),
        marketingOptIn: true,
        notificationsEnabled: true,
        opsNotificationPreferences: {
          newOrders: true,
          cancellations: true,
          lowStock: true,
          campaignTips: false,
          sms: false,
          push: true,
        },
      }),
    });
    expect(tx.vendorBankAccount.create).toHaveBeenCalledWith({
      data: {
        vendorId: 'vendor-meydan-market',
        holderName: 'Meydan Market Ltd.',
        bankName: 'Akbank',
        iban: 'TR100006200000000001234567',
        isDefault: true,
      },
    });
    expect(response).toEqual({
      user: { id: 'usr_vendor_1' },
      tokens: { accessToken: 'access', refreshToken: 'refresh' },
    });
  });

  it('getVendorFinanceSummary calculates balances from orders and payouts', async () => {
    jest.spyOn(service as any, 'requireCurrentUser').mockResolvedValue({
      id: 'usr_admin_1',
      role: PrismaRole.ADMIN,
    });
    jest
      .spyOn(service as any, 'resolveVendorScope')
      .mockResolvedValue(['vendor-1']);
    prisma.order.findMany.mockResolvedValue([
      { totalAmount: 120 },
      { totalAmount: 55 },
    ]);
    prisma.vendorPayout.findMany.mockResolvedValue([
      {
        id: 'payout-paid',
        vendorId: 'vendor-1',
        bankAccountId: 'bank-1',
        amount: 40,
        status: PrismaPayoutStatus.PAID,
        note: null,
        requestedAt: new Date('2026-04-11T10:00:00.000Z'),
        completedAt: new Date('2026-04-11T10:05:00.000Z'),
      },
      {
        id: 'payout-pending',
        vendorId: 'vendor-1',
        bankAccountId: 'bank-1',
        amount: 20,
        status: PrismaPayoutStatus.PENDING,
        note: 'Beklemede',
        requestedAt: new Date('2026-04-12T08:00:00.000Z'),
        completedAt: null,
      },
    ]);
    prisma.vendorBankAccount.findMany.mockResolvedValue([
      {
        id: 'bank-1',
        vendorId: 'vendor-1',
        holderName: 'Vendor Ltd',
        bankName: 'Akbank',
        iban: 'TR100006200000000001234567',
        isDefault: true,
      },
    ]);

    const summary = await service.getVendorFinanceSummary('vendor-1');

    expect(summary.availableBalance).toBe(115);
    expect(summary.pendingBalance).toBe(20);
    expect(summary.lastPayoutAmount).toBe(40);
    expect(summary.lastPayoutAt).toBe('2026-04-11T10:05:00.000Z');
    expect(summary.bankAccounts).toEqual([
      expect.objectContaining({
        id: 'bank-1',
        maskedIban: 'TR10 **** **** 4567',
      }),
    ]);
  });

  it('createVendorPayout rejects amounts above available balance', async () => {
    jest.spyOn(service as any, 'requireCurrentUser').mockResolvedValue({
      id: 'usr_vendor_1',
      role: PrismaRole.VENDOR,
      vendorId: 'vendor-1',
    });
    prisma.vendorBankAccount.findUnique.mockResolvedValue({
      id: 'bank-1',
      vendorId: 'vendor-1',
    });
    jest.spyOn(service as any, 'getVendorFinanceSummary').mockResolvedValue({
      vendorId: 'vendor-1',
      availableBalance: 80,
      pendingBalance: 0,
      lastPayoutAt: '',
      lastPayoutAmount: 0,
      bankAccounts: [],
    });

    await expect(
      service.createVendorPayout({
        vendorId: 'vendor-1',
        bankAccountId: 'bank-1',
        amount: 120,
        note: 'Haftalık ödeme',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('toggleVendorCampaign flips active campaigns to paused', async () => {
    jest.spyOn(service as any, 'requireCurrentUser').mockResolvedValue({
      id: 'usr_vendor_1',
      role: PrismaRole.VENDOR,
      vendorId: 'vendor-1',
    });
    prisma.vendorCampaign.findUnique.mockResolvedValue({
      id: 'camp-1',
      vendorId: 'vendor-1',
      kind: PrismaCampaignKind.HAPPY_HOUR,
      status: PrismaCampaignStatus.ACTIVE,
      title: 'Öğle Kampanyası',
      description: 'Öğlen indirimi',
      scheduleLabel: '12:00-14:00',
      badgeLabel: 'Happy Hour',
      discountPercent: 25,
      discountedPrice: null,
      startsAt: null,
      endsAt: null,
      productIds: ['prd-1'],
      vendor: {
        id: 'vendor-1',
        storefrontType: PrismaStorefrontType.RESTAURANT,
      },
    });
    prisma.vendorCampaign.update.mockResolvedValue({
      id: 'camp-1',
      vendorId: 'vendor-1',
      kind: PrismaCampaignKind.HAPPY_HOUR,
      status: PrismaCampaignStatus.PAUSED,
      title: 'Öğle Kampanyası',
      description: 'Öğlen indirimi',
      scheduleLabel: '12:00-14:00',
      badgeLabel: 'Happy Hour',
      discountPercent: 25,
      discountedPrice: null,
      startsAt: null,
      endsAt: null,
      productIds: ['prd-1'],
      vendor: {
        id: 'vendor-1',
        storefrontType: PrismaStorefrontType.RESTAURANT,
      },
    });
    jest.spyOn(service as any, 'toVendorCampaignPayloads').mockResolvedValue([
      {
        id: 'camp-1',
        vendorId: 'vendor-1',
        title: 'Öğle Kampanyası',
        description: 'Öğlen indirimi',
        kind: 'HAPPY_HOUR',
        status: 'PAUSED',
        scheduleLabel: '12:00-14:00',
        badgeLabel: 'Happy Hour',
        discountPercent: 25,
        discountedPrice: 0,
        startsAt: '',
        endsAt: '',
        productIds: ['prd-1'],
        productTitles: ['Burger'],
        storefrontType: 'RESTAURANT',
      },
    ]);

    const updated = await service.toggleVendorCampaign('camp-1');

    expect(prisma.vendorCampaign.update).toHaveBeenCalledWith({
      where: { id: 'camp-1' },
      data: { status: PrismaCampaignStatus.PAUSED },
      include: {
        vendor: {
          select: {
            id: true,
            storefrontType: true,
          },
        },
      },
    });
    expect(updated).toEqual(
      expect.objectContaining({
        id: 'camp-1',
        status: 'PAUSED',
      }),
    );
  });

  it('listHappyHourOffers projects active campaign products into public offers', async () => {
    prisma.vendor.findMany.mockResolvedValue([]);
    prisma.vendorCampaign.findMany.mockResolvedValue([
      {
        id: 'camp-1',
        vendorId: 'vendor-1',
        kind: PrismaCampaignKind.HAPPY_HOUR,
        status: PrismaCampaignStatus.ACTIVE,
        title: 'Öğle Happy Hour',
        description: 'Kampüs öğle indirimi',
        startsAt: new Date('2026-04-12T09:00:00.000Z'),
        endsAt: new Date(Date.now() + 45 * 60 * 1000),
        scheduleLabel: '12:00-14:00',
        badgeLabel: 'Happy Hour',
        discountPercent: 25,
        discountedPrice: null,
        productIds: ['prd-1'],
        createdAt: new Date('2026-04-12T09:00:00.000Z'),
        updatedAt: new Date('2026-04-12T10:00:00.000Z'),
        vendor: {
          id: 'vendor-1',
          name: 'Meydan Market',
          subtitle: 'Kampüs marketi',
          category: 'Market',
          imageUrl: 'https://example.com/market.jpg',
          promoLabel: 'Özel',
          distanceLabel: '300 m',
          workingHoursLabel: '09:00-22:00',
          pickupPoints: [
            {
              id: 'pickup-1',
              label: 'Ana Kasa',
              address: 'Kampüs merkez blok',
            },
          ],
          inventory: [
            {
              productId: 'prd-1',
              onHand: 8,
              reserved: 1,
              product: {
                reorderLevel: 5,
                trackStock: true,
                isArchived: false,
              },
            },
          ],
        },
      },
    ]);
    prisma.product.findMany.mockResolvedValue([
      {
        id: 'prd-1',
        vendorId: 'vendor-1',
        title: 'Soğuk Sandviç',
        description: 'Günlük hazırlanır',
        imageUrl: 'https://example.com/sandvic.jpg',
        displaySubtitle: 'Atıştırmalık',
        displayBadge: 'Yeni',
        unitPrice: 100,
        catalogSection: {
          label: 'Atıştırmalık',
        },
      },
    ]);

    const offers = await service.listHappyHourOffers();

    expect(offers).toEqual([
      expect.objectContaining({
        id: 'campaign:camp-1:prd-1',
        productId: 'prd-1',
        vendorId: 'vendor-1',
        title: 'Soğuk Sandviç',
        discountedPrice: 75,
        originalPrice: 100,
        discountPercent: 25,
        badge: 'Happy Hour',
        locationTitle: 'Ana Kasa',
      }),
    ]);
  });

  it('listRestaurants only queries approved active storefront vendors', async () => {
    prisma.vendor.findMany.mockResolvedValue([]);

    const result = await service.listRestaurants();

    expect(result).toEqual([]);
    expect(prisma.vendor.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          storefrontType: PrismaStorefrontType.RESTAURANT,
          isActive: true,
          approvalStatus: PrismaVendorApprovalStatus.APPROVED,
        }),
      }),
    );
  });

  it('getVendorCatalog hides vendors that are not approved for the customer app', async () => {
    prisma.vendor.findFirst.mockResolvedValue(null);

    await expect(service.getVendorCatalog('vendor-suspended')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(prisma.vendor.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          id: 'vendor-suspended',
          isActive: true,
          approvalStatus: PrismaVendorApprovalStatus.APPROVED,
        }),
      }),
    );
  });

  it('listHappyHourOffers only loads approved vendors and visible products', async () => {
    prisma.vendorCampaign.findMany.mockResolvedValue([
      {
        id: 'camp-2',
        vendorId: 'vendor-1',
        kind: PrismaCampaignKind.HAPPY_HOUR,
        status: PrismaCampaignStatus.ACTIVE,
        title: 'Akşam Happy Hour',
        description: 'Sadece görünür ürünler',
        startsAt: null,
        endsAt: null,
        scheduleLabel: '18:00-20:00',
        badgeLabel: 'Happy Hour',
        discountPercent: 20,
        discountedPrice: null,
        productIds: ['prd-1'],
        createdAt: new Date('2026-04-12T09:00:00.000Z'),
        updatedAt: new Date('2026-04-12T10:00:00.000Z'),
        vendor: {
          id: 'vendor-1',
          name: 'Meydan Market',
          subtitle: 'Kampüs marketi',
          category: 'Market',
          imageUrl: 'https://example.com/market.jpg',
          promoLabel: 'Özel',
          distanceLabel: '300 m',
          workingHoursLabel: '09:00-22:00',
          pickupPoints: [],
          inventory: [],
        },
      },
    ]);
    prisma.product.findMany.mockResolvedValue([]);

    const offers = await service.listHappyHourOffers();

    expect(offers).toEqual([]);
    expect(prisma.vendorCampaign.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          kind: PrismaCampaignKind.HAPPY_HOUR,
          status: PrismaCampaignStatus.ACTIVE,
          vendor: {
            is: {
              isActive: true,
              approvalStatus: PrismaVendorApprovalStatus.APPROVED,
            },
          },
        }),
      }),
    );
    expect(prisma.product.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          id: { in: ['prd-1'] },
          isActive: true,
          isArchived: false,
          isVisibleInApp: true,
          vendor: {
            is: {
              isActive: true,
              approvalStatus: PrismaVendorApprovalStatus.APPROVED,
            },
          },
        }),
      }),
    );
  });

  it('rejects vendor scoped requests after the business is suspended in admin', async () => {
    requestContext.userId = 'usr_vendor_1';
    prisma.user.findUnique.mockResolvedValue({
      id: 'usr_vendor_1',
      role: PrismaRole.VENDOR,
      vendorId: 'vendor-1',
      isBanned: false,
      isSuspended: false,
    });
    prisma.vendor.findUnique.mockResolvedValue({
      approvalStatus: PrismaVendorApprovalStatus.SUSPENDED,
      isActive: true,
    });

    await expect(service.listCatalogAdminVendors('vendor-1')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('syncs vendor hero copy when catalog admins rename the business without custom hero overrides', async () => {
    jest.spyOn(service as any, 'requireCurrentUser').mockResolvedValue({
      id: 'usr_vendor_1',
      role: PrismaRole.VENDOR,
      vendorId: 'vendor-1',
    });
    jest.spyOn(service as any, 'assertOpsAccess').mockReturnValue(undefined);
    jest.spyOn(service as any, 'assertVendorAccess').mockReturnValue(undefined);
    jest.spyOn(service as any, 'getVendorCatalog').mockResolvedValue({
      vendorId: 'vendor-1',
      title: 'Yeni Market',
      heroTitle: 'Yeni Market',
      heroSubtitle: 'Yeni alt metin',
    });
    prisma.vendor.findUnique.mockResolvedValue({
      id: 'vendor-1',
      name: 'Eski Market',
      subtitle: 'Eski alt metin',
      heroTitle: 'Eski Market',
      heroSubtitle: 'Eski alt metin',
      slug: 'eski-market',
      pickupPoints: [],
      operators: [],
    });
    const tx = {
      vendor: {
        update: jest.fn(),
      },
    };
    prisma.$transaction.mockImplementation(
      async (callback: (client: typeof tx) => Promise<unknown>) => callback(tx),
    );

    await service.updateCatalogVendor('vendor-1', {
      name: 'Yeni Market',
      subtitle: 'Yeni alt metin',
    });

    expect(tx.vendor.update).toHaveBeenCalledWith({
      where: { id: 'vendor-1' },
      data: expect.objectContaining({
        name: 'Yeni Market',
        subtitle: 'Yeni alt metin',
        heroTitle: 'Yeni Market',
        heroSubtitle: 'Yeni alt metin',
      }),
    });
  });

  it('createCatalogProduct honors sectionLabel instead of forcing the first section', async () => {
    jest.spyOn(service as any, 'requireCurrentUser').mockResolvedValue({
      id: 'usr_vendor_1',
      role: PrismaRole.VENDOR,
      vendorId: 'vendor-1',
    });
    jest.spyOn(service as any, 'getVendorCatalog').mockResolvedValue({
      vendorId: 'vendor-1',
    });
    prisma.vendor.findUnique.mockResolvedValue({
      id: 'vendor-1',
      slug: 'meydan-market',
      category: 'Market',
      pickupPoints: [
        {
          id: 'pickup-1',
          label: 'Ana depo',
        },
      ],
      sections: [
        {
          id: 'section-ilk',
          label: 'Süt & Kahvaltılık',
        },
      ],
    });
    prisma.catalogSection.upsert.mockResolvedValue({
      id: 'section-atistirmalik',
    });
    const tx = {
      product: {
        create: jest.fn().mockResolvedValue({
          id: 'prd-1',
        }),
      },
      inventoryStock: {
        create: jest.fn(),
      },
    };
    prisma.$transaction.mockImplementation(
      async (callback: (client: typeof tx) => Promise<unknown>) => callback(tx),
    );

    await service.createCatalogProduct({
      vendorId: 'vendor-1',
      title: 'Yeni Ürün',
      sectionLabel: 'Atıştırmalık',
      category: 'Market',
      unitPrice: 29.9,
    });

    expect(prisma.catalogSection.upsert).toHaveBeenCalledWith({
      where: {
        vendorId_key: {
          vendorId: 'vendor-1',
          key: 'atistirmalik',
        },
      },
      update: {
        label: 'Atıştırmalık',
        isActive: true,
      },
      create: {
        vendorId: 'vendor-1',
        key: 'atistirmalik',
        label: 'Atıştırmalık',
        displayOrder: 999,
        isActive: true,
      },
    });
    expect(tx.product.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        vendorId: 'vendor-1',
        catalogSectionId: 'section-atistirmalik',
        title: 'Yeni Ürün',
        kind: 'Market',
      }),
    });
  });
});
