import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speto_shared/speto_shared.dart';
import 'package:stock_app/src/app/stock_app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login rejects non-vendor sessions', () async {
    final FakeStockDomainApi api = FakeStockDomainApi()
      ..healthResult = true
      ..loginResult = _session(role: SpetoUserRole.customer);
    final StockAppController controller = await _bootstrapController(api);

    final bool success = await controller.login(
      email: 'customer@speto.app',
      password: 'customer123',
    );

    expect(success, isFalse);
    expect(
      controller.authError,
      contains('Yönetici hesapları bu uygulamayı kullanamaz'),
    );
  });

  test('registerOperator resets draft and loads vendor data', () async {
    final SpetoCatalogVendor restaurantVendor = _vendor(
      id: 'vendor-restaurant',
      title: 'Sepet Burger',
      storefrontType: SpetoStorefrontType.restaurant,
    );
    final FakeStockDomainApi api = FakeStockDomainApi()
      ..healthResult = true
      ..registerResult = _session(
        role: SpetoUserRole.vendor,
        vendorScopes: const <String>['vendor-restaurant'],
      )
      ..vendorsResponse = <SpetoCatalogVendor>[restaurantVendor]
      ..inventorySnapshots['vendor-restaurant'] = _snapshot(
        vendorId: 'vendor-restaurant',
      )
      ..inventoryItemsByVendor['vendor-restaurant'] = <SpetoInventoryItem>[
        _inventoryItem(vendorId: 'vendor-restaurant', title: 'Burger Ekmeği'),
      ]
      ..ordersByVendor['vendor-restaurant'] = <SpetoOpsOrder>[
        _order(vendor: 'Sepet Burger', vendorId: 'vendor-restaurant'),
      ]
      ..productsByVendor['vendor-restaurant'] = <SpetoCatalogProduct>[
        _product(vendorId: 'vendor-restaurant', vendorName: 'Sepet Burger'),
      ]
      ..campaignSummaries['vendor-restaurant'] = _campaignSummary(
        vendorId: 'vendor-restaurant',
        storefrontType: SpetoStorefrontType.restaurant,
      )
      ..financeSummaries['vendor-restaurant'] = _financeSummary(
        vendorId: 'vendor-restaurant',
      );
    final StockAppController controller = await _bootstrapController(api);

    controller.registrationDraft.storefrontType =
        SpetoStorefrontType.restaurant;
    controller.registrationDraft.businessName = 'Sepet Burger';
    controller.registrationDraft.businessCategory = 'Burger';
    controller.registrationDraft.businessSubtitle = 'Kampüs burger evi';
    controller.registrationDraft.businessImageUrl =
        'https://example.com/burger.jpg';
    controller.registrationDraft.pickupPointLabel = 'Ön Tezgah';
    controller.registrationDraft.pickupPointAddress =
        'Mühendislik Fakültesi önü';
    controller.registrationDraft.operatorEmail = 'ops@sepetburger.app';
    controller.registrationDraft.operatorPassword = 'vendor123';
    controller.registrationDraft.operatorDisplayName = 'Sepet Burger Operasyon';
    controller.registrationDraft.operatorPhone = '+90 555 100 10 10';
    controller.registrationDraft.bankHolderName = 'Sepet Burger Ltd.';
    controller.registrationDraft.bankName = 'İş Bankası';
    controller.registrationDraft.iban = 'TR100006200000000001234567';
    controller.registrationDraft.termsAccepted = true;
    controller.registrationDraft.privacyAccepted = true;
    controller.registrationDraft.notifyNewOrders = true;
    controller.registrationDraft.notifyCancellations = true;
    controller.registrationDraft.notifyLowStock = true;

    final bool success = await controller.registerOperator();

    expect(success, isTrue);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.selectedVendorId, 'vendor-restaurant');
    expect(controller.isRestaurantMode, isTrue);
    expect(controller.registrationDraft.businessName, isEmpty);
    expect(api.lastRegisteredBusinessName, 'Sepet Burger');
    expect(api.lastRegisteredStorefrontType, SpetoStorefrontType.restaurant);
  });

  test(
    'bootstrap keeps vendor data scoped to the logged-in business',
    () async {
      final FakeStockDomainApi api = FakeStockDomainApi()
        ..vendorsResponse = <SpetoCatalogVendor>[
          _vendor(
            id: 'meydan-market',
            vendorId: 'vendor-market',
            title: 'Meydan Market',
            storefrontType: SpetoStorefrontType.market,
          ),
          _vendor(
            id: 'sepet-burger',
            vendorId: 'vendor-restaurant',
            title: 'Sepet Burger',
            storefrontType: SpetoStorefrontType.restaurant,
          ),
        ]
        ..inventorySnapshots['vendor-market'] = _snapshot(
          vendorId: 'vendor-market',
        )
        ..inventorySnapshots['vendor-restaurant'] = _snapshot(
          vendorId: 'vendor-restaurant',
        )
        ..inventoryItemsByVendor['vendor-market'] = <SpetoInventoryItem>[
          _inventoryItem(vendorId: 'vendor-market', title: 'Ayran'),
        ]
        ..inventoryItemsByVendor['vendor-restaurant'] = <SpetoInventoryItem>[
          _inventoryItem(vendorId: 'vendor-restaurant', title: 'Burger'),
        ]
        ..ordersByVendor['vendor-market'] = <SpetoOpsOrder>[
          _order(vendor: 'Meydan Market', vendorId: 'vendor-market'),
        ]
        ..ordersByVendor['vendor-restaurant'] = <SpetoOpsOrder>[
          _order(vendor: 'Sepet Burger', vendorId: 'vendor-restaurant'),
        ]
        ..productsByVendor['vendor-market'] = <SpetoCatalogProduct>[
          _product(vendorId: 'vendor-market', vendorName: 'Meydan Market'),
        ]
        ..productsByVendor['vendor-restaurant'] = <SpetoCatalogProduct>[
          _product(vendorId: 'vendor-restaurant', vendorName: 'Sepet Burger'),
        ]
        ..campaignSummaries['vendor-market'] = _campaignSummary(
          vendorId: 'vendor-market',
          storefrontType: SpetoStorefrontType.market,
        )
        ..campaignSummaries['vendor-restaurant'] = _campaignSummary(
          vendorId: 'vendor-restaurant',
          storefrontType: SpetoStorefrontType.restaurant,
        )
        ..financeSummaries['vendor-market'] = _financeSummary(
          vendorId: 'vendor-market',
        )
        ..financeSummaries['vendor-restaurant'] = _financeSummary(
          vendorId: 'vendor-restaurant',
        );

      final StockAppController controller = await _bootstrapController(
        api,
        storedSession: _session(
          role: SpetoUserRole.vendor,
          vendorScopes: const <String>['vendor-restaurant'],
        ),
      );

      expect(controller.selectedVendorId, 'vendor-restaurant');
      expect(controller.storefrontType, SpetoStorefrontType.restaurant);
      expect(controller.financeSummary?.vendorId, 'vendor-restaurant');
      expect(api.fetchedInventoryVendorIds, everyElement('vendor-restaurant'));
    },
  );

  test('saveProduct sends category payload for the selected vendor', () async {
    final FakeStockDomainApi api = FakeStockDomainApi()
      ..vendorsResponse = <SpetoCatalogVendor>[
        _vendor(
          id: 'meydan-market',
          vendorId: 'vendor-market',
          title: 'Meydan Market',
          storefrontType: SpetoStorefrontType.market,
        ),
      ]
      ..inventorySnapshots['vendor-market'] = _snapshot(
        vendorId: 'vendor-market',
      )
      ..productsByVendor['vendor-market'] = <SpetoCatalogProduct>[
        _product(vendorId: 'vendor-market', vendorName: 'Meydan Market'),
      ]
      ..campaignSummaries['vendor-market'] = _campaignSummary(
        vendorId: 'vendor-market',
      )
      ..financeSummaries['vendor-market'] = _financeSummary(
        vendorId: 'vendor-market',
      );

    final StockAppController controller = await _bootstrapController(
      api,
      storedSession: _session(
        role: SpetoUserRole.vendor,
        vendorScopes: const <String>['vendor-market'],
      ),
    );

    await controller.saveProduct(
      title: 'Yeni Ürün',
      description: 'Deneme ürün',
      sectionLabel: 'Atıştırmalık',
      category: 'Market',
      unitPrice: 29.9,
      displaySubtitle: 'Günlük',
    );

    expect(api.lastCreatedProductPayload, isNotNull);
    expect(api.lastCreatedProductPayload!['vendorId'], 'vendor-market');
    expect(api.lastCreatedProductPayload!['category'], 'Market');
    expect(api.lastCreatedProductPayload!.containsKey('kind'), isFalse);
  });
}

Future<StockAppController> _bootstrapController(
  FakeStockDomainApi api, {
  SpetoSession? storedSession,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (storedSession != null)
      'stock_app.session': jsonEncode(storedSession.toJson()),
  });
  final StockAppController controller = StockAppController(
    sharedPreferencesLoader: SharedPreferences.getInstance,
    apiResolver: (SpetoSession? session) async => (api: api, client: null),
  );
  await controller.bootstrap();
  return controller;
}

class FakeStockDomainApi extends SpetoRemoteDomainApi {
  FakeStockDomainApi()
    : super(SpetoRemoteApiClient(baseUrl: 'http://localhost:4000/api'));

  bool healthResult = true;
  SpetoSession? loginResult;
  SpetoSession? registerResult;
  String? lastRegisteredBusinessName;
  SpetoStorefrontType? lastRegisteredStorefrontType;
  List<SpetoCatalogVendor> vendorsResponse = const <SpetoCatalogVendor>[];
  final Map<String, SpetoInventorySnapshot> inventorySnapshots =
      <String, SpetoInventorySnapshot>{};
  final Map<String, List<SpetoInventoryItem>> inventoryItemsByVendor =
      <String, List<SpetoInventoryItem>>{};
  final Map<String, List<SpetoOpsOrder>> ordersByVendor =
      <String, List<SpetoOpsOrder>>{};
  final Map<String, List<SpetoCatalogProduct>> productsByVendor =
      <String, List<SpetoCatalogProduct>>{};
  final Map<String, SpetoVendorCampaignSummary> campaignSummaries =
      <String, SpetoVendorCampaignSummary>{};
  final Map<String, SpetoVendorFinanceSummary> financeSummaries =
      <String, SpetoVendorFinanceSummary>{};
  final List<String?> fetchedInventoryVendorIds = <String?>[];
  Map<String, Object?>? lastCreatedProductPayload;

  @override
  Future<bool> checkHealth() async => healthResult;

  @override
  Future<SpetoSession> login({
    required String email,
    required String password,
  }) async {
    return loginResult ?? _session();
  }

  @override
  Future<SpetoSession> registerOperator({
    required SpetoStorefrontType storefrontType,
    required String businessName,
    required String businessCategory,
    required String businessSubtitle,
    required String businessImageUrl,
    String city = '',
    String district = '',
    required String pickupPointLabel,
    required String pickupPointAddress,
    required String workingHoursLabel,
    List<Map<String, Object?>> workingDays = const <Map<String, Object?>>[],
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required String holderName,
    required String bankName,
    required String iban,
    String taxNumber = '',
    String taxOffice = '',
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool marketingOptIn,
    required bool notifyNewOrders,
    required bool notifyCancellations,
    required bool notifyLowStock,
    required bool notifyCampaignTips,
    bool notifySms = false,
    bool notifyPush = true,
  }) async {
    lastRegisteredBusinessName = businessName;
    lastRegisteredStorefrontType = storefrontType;
    return registerResult ?? _session(role: SpetoUserRole.vendor);
  }

  @override
  Future<List<SpetoCatalogVendor>> fetchCatalogAdminVendors({
    String? vendorId,
  }) async {
    return vendorsResponse;
  }

  @override
  Future<SpetoInventorySnapshot> fetchInventorySnapshot({
    String? vendorId,
    String? query,
  }) async {
    fetchedInventoryVendorIds.add(vendorId);
    return inventorySnapshots[vendorId] ?? _snapshot(vendorId: vendorId ?? '');
  }

  @override
  Future<List<SpetoInventoryItem>> fetchInventoryItems({
    String? vendorId,
    String? query,
  }) async {
    return inventoryItemsByVendor[vendorId] ?? const <SpetoInventoryItem>[];
  }

  @override
  Future<List<SpetoOpsOrder>> fetchOpsOrders({String? vendorId}) async {
    return ordersByVendor[vendorId] ?? const <SpetoOpsOrder>[];
  }

  @override
  Future<List<SpetoCatalogProduct>> fetchCatalogAdminProducts({
    String? vendorId,
  }) async {
    return productsByVendor[vendorId] ?? const <SpetoCatalogProduct>[];
  }

  @override
  Future<SpetoCatalogVendor> createCatalogProduct(
    Map<String, Object?> payload,
  ) async {
    lastCreatedProductPayload = Map<String, Object?>.from(payload);
    return vendorsResponse.firstWhere(
      (SpetoCatalogVendor vendor) =>
          vendor.vendorId == payload['vendorId'] ||
          vendor.id == payload['vendorId'],
    );
  }

  @override
  Future<List<SpetoIntegrationConnection>> fetchIntegrations({
    String? vendorId,
  }) async {
    return const <SpetoIntegrationConnection>[];
  }

  @override
  Future<SpetoVendorCampaignSummary> fetchCampaignSummary({
    String? vendorId,
  }) async {
    return campaignSummaries[vendorId] ??
        _campaignSummary(vendorId: vendorId ?? '');
  }

  @override
  Future<SpetoVendorFinanceSummary> fetchFinanceSummary({
    String? vendorId,
  }) async {
    return financeSummaries[vendorId] ??
        _financeSummary(vendorId: vendorId ?? '');
  }

  @override
  Future<List<SpetoSupportTicket>> fetchSupportTickets() async {
    return const <SpetoSupportTicket>[];
  }

  @override
  Future<SpetoRemoteSnapshot> fetchSnapshot() async {
    return const SpetoRemoteSnapshot(
      profile: SpetoRemoteUserProfile(
        email: 'ops@speto.app',
        displayName: 'Speto Ops',
        phone: '+90 555 000 00 00',
        avatarUrl: '',
        notificationsEnabled: true,
      ),
      addresses: <SpetoAddress>[],
      paymentCards: <SpetoPaymentCard>[],
      activeOrders: <SpetoOrder>[],
      historyOrders: <SpetoOrder>[],
      supportTickets: <SpetoSupportTicket>[],
      ownedTickets: <SpetoEventTicket>[],
      proPointsBalance: 0,
      favoriteRestaurantIds: <String>[],
      favoriteEventIds: <String>[],
      favoriteMarketIds: <String>[],
      followedOrganizerIds: <String>[],
      orderRatings: <String, int>{},
    );
  }
}

SpetoSession _session({
  SpetoUserRole role = SpetoUserRole.vendor,
  List<String> vendorScopes = const <String>['vendor-market'],
}) {
  return SpetoSession(
    email: 'ops@speto.app',
    displayName: 'Speto Ops',
    phone: '+90 555 000 00 00',
    authToken: 'access-token',
    refreshToken: 'refresh-token',
    lastLoginIso: DateTime(2026, 4, 12).toIso8601String(),
    role: role,
    vendorScopes: vendorScopes,
  );
}

SpetoCatalogVendor _vendor({
  required String id,
  String? vendorId,
  required String title,
  required SpetoStorefrontType storefrontType,
}) {
  return SpetoCatalogVendor(
    id: id,
    vendorId: vendorId ?? id,
    storefrontType: storefrontType,
    title: title,
    subtitle: 'Aktif operasyon',
    meta: 'Kampüs içi',
    image: '',
    badge: '',
    rewardLabel: '',
    ratingLabel: '4.8',
    distanceLabel: '300 m',
    etaLabel: '10 dk',
    promoLabel: '',
    workingHoursLabel: '09:00-22:00',
    minOrderLabel: '',
    deliveryWindowLabel: '',
    reviewCountLabel: '120 değerlendirme',
    announcement: '',
    bundleTitle: '',
    bundleDescription: '',
    bundlePrice: '',
    heroTitle: title,
    heroSubtitle: 'Günlük operasyon',
    cuisine: storefrontType == SpetoStorefrontType.market ? 'Market' : 'Burger',
    etaMin: 10,
    etaMax: 15,
    ratingValue: 4.8,
    promo: '',
    studentFriendly: true,
    isFeatured: true,
    isActive: true,
    pickupPoints: const <SpetoCatalogPickupPoint>[],
    highlights: const <SpetoCatalogVendorHighlight>[],
    operatorAccounts: const <SpetoCatalogOperatorAccount>[],
    sections: const <SpetoCatalogSection>[],
    stockStatus: const SpetoStockStatus(
      isInStock: true,
      availableQuantity: 12,
      lowStock: false,
      canPurchase: true,
    ),
  );
}

SpetoInventoryItem _inventoryItem({
  required String vendorId,
  required String title,
}) {
  return SpetoInventoryItem(
    id: 'inv-$vendorId',
    vendorId: vendorId,
    vendorName: vendorId,
    title: title,
    description: '',
    imageUrl: '',
    category: 'General',
    unitPrice: 50,
    sku: 'SKU-$vendorId',
    barcode: '',
    locationId: 'loc-1',
    locationLabel: 'Ana depo',
    trackStock: true,
    reorderLevel: 3,
    isArchived: false,
    onHand: 12,
    reserved: 2,
    stockStatus: const SpetoStockStatus(
      isInStock: true,
      availableQuantity: 10,
      lowStock: false,
      canPurchase: true,
    ),
  );
}

SpetoInventorySnapshot _snapshot({required String vendorId}) {
  return SpetoInventorySnapshot(
    items: <SpetoInventoryItem>[
      _inventoryItem(vendorId: vendorId, title: 'Demo Ürün'),
    ],
    totalItems: 1,
    lowStockCount: 0,
    outOfStockCount: 0,
    openOrdersCount: 1,
    integrationErrorCount: 0,
    pendingSyncCount: 0,
    totalAvailableUnits: 10,
  );
}

SpetoOpsOrder _order({required String vendor, required String vendorId}) {
  return SpetoOrder(
    id: 'order-$vendorId',
    vendor: vendor,
    vendorId: vendorId,
    image: '',
    items: const <SpetoCartItem>[
      SpetoCartItem(
        id: 'item-1',
        vendor: 'Sepeto',
        title: 'Demo Ürün',
        image: '',
        unitPrice: 50,
        quantity: 1,
      ),
    ],
    placedAtLabel: 'Bugün',
    etaLabel: '12 dk',
    status: SpetoOrderStatus.active,
    actionLabel: 'Hazırlanıyor',
  );
}

SpetoCatalogProduct _product({
  required String vendorId,
  required String vendorName,
}) {
  return SpetoCatalogProduct(
    id: 'product-$vendorId',
    vendorId: vendorId,
    vendorName: vendorName,
    sectionId: 'section-1',
    sectionLabel: 'Genel',
    title: 'Demo Ürün',
    description: '',
    image: '',
    imageUrl: '',
    unitPrice: 45,
    priceText: '45 TL',
    category: 'General',
    sku: 'SKU-$vendorId',
    barcode: '',
    externalCode: '',
    displaySubtitle: '',
    displayBadge: '',
    displayOrder: 0,
    isFeatured: false,
    isVisibleInApp: true,
    trackStock: true,
    reorderLevel: 3,
    isArchived: false,
    stockStatus: const SpetoStockStatus(
      isInStock: true,
      availableQuantity: 10,
      lowStock: false,
      canPurchase: true,
    ),
    searchKeywords: const <String>[],
    legacyAliases: const <String>[],
  );
}

SpetoVendorCampaignSummary _campaignSummary({
  required String vendorId,
  SpetoStorefrontType storefrontType = SpetoStorefrontType.market,
}) {
  return SpetoVendorCampaignSummary(
    vendorId: vendorId,
    activeCount: 1,
    draftCount: 0,
    pausedCount: 0,
    criticalProductCount: 0,
    campaigns: <SpetoVendorCampaign>[
      SpetoVendorCampaign(
        id: 'campaign-$vendorId',
        vendorId: vendorId,
        title: 'Happy Hour',
        description: 'Öğle fırsatı',
        kind: SpetoCampaignKind.happyHour,
        status: SpetoCampaignStatus.active,
        scheduleLabel: '12:00-14:00',
        badgeLabel: 'Happy Hour',
        discountPercent: 20,
        discountedPrice: 40,
        startsAt: '',
        endsAt: '',
        productIds: const <String>['product-1'],
        productTitles: const <String>['Demo Ürün'],
        storefrontType: storefrontType,
      ),
    ],
  );
}

SpetoVendorFinanceSummary _financeSummary({required String vendorId}) {
  return SpetoVendorFinanceSummary(
    vendorId: vendorId,
    availableBalance: 250,
    pendingBalance: 40,
    lastPayoutAt: '2026-04-10T12:00:00.000Z',
    lastPayoutAmount: 100,
    bankAccounts: const <SpetoVendorBankAccount>[
      SpetoVendorBankAccount(
        id: 'bank-1',
        vendorId: 'vendor',
        holderName: 'Vendor Ltd.',
        bankName: 'Akbank',
        iban: 'TR100006200000000001234567',
        maskedIban: 'TR10 **** **** 4567',
        isDefault: true,
      ),
    ],
  );
}
