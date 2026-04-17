import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/main.dart';
import 'package:stock_app/src/app/stock_app_controller.dart';
import 'package:stock_app/src/screens/dashboard/home_screen.dart';
import 'package:speto_shared/speto_shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows login warning when backend is unreachable', (
    WidgetTester tester,
  ) async {
    final StockAppController controller = StockAppController(
      initialBootstrapping: false,
      initialBackendReachable: false,
    );

    await tester.pumpWidget(StockApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('SepetPro İşyerim'), findsOneWidget);
    expect(
      find.text('Sunucu başlatılıyor olabilir. Biraz bekleyip tekrar deneyin.'),
      findsOneWidget,
    );
  });

  testWidgets('routes authenticated users to the home shell', (
    WidgetTester tester,
  ) async {
    final StockAppController controller = StockAppController(
      initialSession: SpetoSession(
        email: 'ops@speto.app',
        displayName: 'Speto Ops',
        phone: '+90 555 000 00 00',
        authToken: 'access-token',
        refreshToken: 'refresh-token',
        lastLoginIso: DateTime(2026, 4, 12).toIso8601String(),
        role: SpetoUserRole.vendor,
        vendorScopes: const <String>['vendor-market'],
      ),
      initialBootstrapping: false,
      initialBackendReachable: true,
    );
    controller.vendors = <SpetoCatalogVendor>[
      SpetoCatalogVendor(
        id: 'vendor-market',
        vendorId: 'vendor-market',
        storefrontType: SpetoStorefrontType.market,
        title: 'Meydan Market',
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
        heroTitle: 'Meydan Market',
        heroSubtitle: 'Günlük operasyon',
        cuisine: 'Market',
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
          availableQuantity: 8,
          lowStock: false,
          canPurchase: true,
        ),
      ),
    ];
    controller.selectedVendorId = 'vendor-market';
    controller.inventorySnapshot = const SpetoInventorySnapshot(
      items: <SpetoInventoryItem>[],
      totalItems: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
      openOrdersCount: 0,
      integrationErrorCount: 0,
      pendingSyncCount: 0,
      totalAvailableUnits: 0,
    );
    controller.campaignSummary = const SpetoVendorCampaignSummary(
      vendorId: 'vendor-market',
      activeCount: 0,
      draftCount: 0,
      pausedCount: 0,
      criticalProductCount: 0,
      campaigns: <SpetoVendorCampaign>[],
    );
    controller.financeSummary = const SpetoVendorFinanceSummary(
      vendorId: 'vendor-market',
      availableBalance: 0,
      pendingBalance: 0,
      lastPayoutAt: '',
      lastPayoutAmount: 0,
      bankAccounts: <SpetoVendorBankAccount>[],
    );
    controller.userProfile = const SpetoRemoteUserProfile(
      email: 'ops@speto.app',
      displayName: 'Speto Ops',
      phone: '+90 555 000 00 00',
      avatarUrl: '',
      notificationsEnabled: true,
    );

    await tester.pumpWidget(StockApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
