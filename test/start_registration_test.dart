import 'package:flutter_test/flutter_test.dart';
import 'package:speto_shared/speto_shared.dart';

import 'package:speto/core/state/app_state.dart';
import 'package:speto/src/core/bootstrap.dart';

class _ThrowingAuthRepository implements SpetoAuthRepository {
  SpetoRegistrationDraft? draft;
  SpetoSession? session;

  @override
  Future<void> clearPasswordResetEmail() async {
    throw Exception('expected cleanup failure');
  }

  @override
  Future<String?> readPasswordResetEmail() async => null;

  @override
  Future<SpetoRegistrationDraft?> readRegistrationDraft() async => draft;

  @override
  Future<SpetoSession?> readSession() async => null;

  @override
  Future<void> rememberPasswordResetEmail(String email) async {}

  @override
  Future<void> writeRegistrationDraft(SpetoRegistrationDraft? nextDraft) async {
    draft = nextDraft;
  }

  @override
  Future<void> writeSession(SpetoSession? session) async {
    this.session = session;
  }
}

class _FakeDomainApi extends SpetoRemoteDomainApi {
  _FakeDomainApi({
    this.onRegister,
    this.onLogin,
    this.onFetchSnapshot,
    this.onFetchInventoryItems,
    this.onFetchHappyHourOffers,
    this.onCheckout,
  }) : super(SpetoRemoteApiClient(baseUrl: 'http://127.0.0.1:4000/api'));

  final Future<SpetoSession> Function({
    required String email,
    required String displayName,
    required String phone,
    required String password,
    String? studentEmail,
  })?
  onRegister;
  final Future<SpetoSession> Function({
    required String email,
    required String password,
  })?
  onLogin;
  final Future<SpetoRemoteSnapshot> Function()? onFetchSnapshot;
  final Future<List<SpetoInventoryItem>> Function()? onFetchInventoryItems;
  final Future<List<SpetoHappyHourOffer>> Function()? onFetchHappyHourOffers;
  final Future<SpetoOrder> Function({
    required List<SpetoCartItem> cartItems,
    required String pickupPointLabel,
    required String paymentMethodLabel,
    String? paymentMethodToken,
    String promoCode,
  })?
  onCheckout;

  @override
  Future<SpetoSession> register({
    required String email,
    required String displayName,
    required String phone,
    required String password,
    String? studentEmail,
  }) {
    return onRegister!(
      email: email,
      displayName: displayName,
      phone: phone,
      password: password,
      studentEmail: studentEmail,
    );
  }

  @override
  Future<SpetoSession> login({
    required String email,
    required String password,
  }) {
    return onLogin!(email: email, password: password);
  }

  @override
  Future<SpetoRemoteSnapshot> fetchSnapshot() {
    return onFetchSnapshot!();
  }

  @override
  Future<List<SpetoInventoryItem>> fetchInventoryItems({
    String? vendorId,
    String? query,
  }) {
    return onFetchInventoryItems?.call() ??
        Future<List<SpetoInventoryItem>>.value(const <SpetoInventoryItem>[]);
  }

  @override
  Future<List<SpetoHappyHourOffer>> fetchHappyHourOffers() {
    return onFetchHappyHourOffers?.call() ??
        Future<List<SpetoHappyHourOffer>>.value(const <SpetoHappyHourOffer>[]);
  }

  @override
  Future<SpetoOrder> checkout({
    required List<SpetoCartItem> cartItems,
    required String pickupPointLabel,
    required String paymentMethodLabel,
    String? paymentMethodToken,
    String promoCode = '',
  }) {
    return onCheckout!(
      cartItems: cartItems,
      pickupPointLabel: pickupPointLabel,
      paymentMethodLabel: paymentMethodLabel,
      paymentMethodToken: paymentMethodToken,
      promoCode: promoCode,
    );
  }
}

SpetoSession _buildSession({
  required String email,
  String displayName = 'Debug User',
  String phone = '5551234567',
}) {
  return SpetoSession(
    email: email,
    displayName: displayName,
    phone: phone,
    authToken: 'debug-token',
    lastLoginIso: DateTime(2026).toIso8601String(),
  );
}

SpetoRemoteSnapshot _emptySnapshot(String email) {
  return SpetoRemoteSnapshot(
    profile: SpetoRemoteUserProfile(
      email: email,
      displayName: 'Debug User',
      phone: '5551234567',
      avatarUrl: '',
      notificationsEnabled: true,
    ),
    addresses: const <SpetoAddress>[],
    paymentCards: const <SpetoPaymentCard>[],
    activeOrders: const <SpetoOrder>[],
    historyOrders: const <SpetoOrder>[],
    supportTickets: const <SpetoSupportTicket>[],
    ownedTickets: const <SpetoEventTicket>[],
    proPointsBalance: 0,
    favoriteRestaurantIds: const <String>[],
    favoriteEventIds: const <String>[],
    favoriteMarketIds: const <String>[],
    followedOrganizerIds: const <String>[],
    orderRatings: const <String, int>{},
  );
}

const SpetoHappyHourOffer _liveHappyHourOffer = SpetoHappyHourOffer(
  id: 'campaign:demo:market-product-kampus-kafe-avocado-bagel',
  productId: 'market-product-kampus-kafe-avocado-bagel',
  vendorId: 'vendor-kampus-kafe',
  vendorName: 'Kampüs Kafe',
  vendorSubtitle: 'Kampüs ürünleri',
  title: 'Avokadolu Bagel',
  subtitle: 'Canlı ürün',
  description: 'Canlı Render katalog ürünü.',
  imageUrl: 'https://example.com/bagel.jpg',
  badge: 'Happy Hour',
  discountedPrice: 110.76,
  discountedPriceText: '110,76 TL',
  originalPrice: 130,
  originalPriceText: '130 TL',
  discountPercent: 15,
  expiresInMinutes: 30,
  rewardPoints: 1,
  claimCount: 1,
  locationTitle: 'Kampüs Kafe Gel-Al Noktası',
  locationSubtitle: 'Kampüs',
  sectionLabel: 'Kampanya',
  stockStatus: SpetoStockStatus(
    isInStock: true,
    availableQuantity: 10,
    lowStock: false,
    canPurchase: true,
  ),
);

void main() {
  test(
    'startRegistration continues when password reset cleanup fails',
    () async {
      final _ThrowingAuthRepository authRepository = _ThrowingAuthRepository();
      final SpetoAppState appState = SpetoAppState(
        authRepository: authRepository,
        commerceRepository: InMemorySpetoCommerceRepository(),
      );

      await appState.startRegistration(
        fullName: 'Debug User',
        email: 'debug@example.com',
        phone: '5551234567',
        password: 'StrongPass123',
      );

      expect(appState.pendingRegistration, isNotNull);
      expect(appState.pendingRegistration!.email, 'debug@example.com');
      expect(authRepository.draft, isNotNull);
    },
  );

  test('verifyOtpCode accepts the default registration OTP code', () async {
    final _ThrowingAuthRepository authRepository = _ThrowingAuthRepository();
    final SpetoAppState appState = SpetoAppState(
      authRepository: authRepository,
      commerceRepository: InMemorySpetoCommerceRepository(),
      domainApi: _FakeDomainApi(
        onRegister:
            ({
              required String email,
              required String displayName,
              required String phone,
              required String password,
              String? studentEmail,
            }) async => _buildSession(
              email: email,
              displayName: displayName,
              phone: phone,
            ),
        onLogin: ({required String email, required String password}) async =>
            _buildSession(email: email),
        onFetchSnapshot: () async => _emptySnapshot('debug@example.com'),
        onFetchInventoryItems: () async => const <SpetoInventoryItem>[],
      ),
    );

    await appState.startRegistration(
      fullName: 'Debug User',
      email: 'debug@example.com',
      phone: '5551234567',
      password: 'StrongPass123',
    );

    final SpetoRegistrationOtpVerificationResult result = await appState
        .verifyOtpCode('12345');

    expect(result, SpetoRegistrationOtpVerificationResult.verified);
    expect(appState.session, isNotNull);
    expect(appState.session!.email, 'debug@example.com');
    expect(appState.pendingRegistration, isNull);
  });

  test('verifyOtpCode reports invalid codes explicitly', () async {
    final _ThrowingAuthRepository authRepository = _ThrowingAuthRepository();
    final SpetoAppState appState = SpetoAppState(
      authRepository: authRepository,
      commerceRepository: InMemorySpetoCommerceRepository(),
    );

    await appState.startRegistration(
      fullName: 'Debug User',
      email: 'debug@example.com',
      phone: '5551234567',
      password: 'StrongPass123',
    );

    final SpetoRegistrationOtpVerificationResult result = await appState
        .verifyOtpCode('99999');

    expect(result, SpetoRegistrationOtpVerificationResult.invalidCode);
    expect(appState.pendingRegistration, isNotNull);
  });

  test(
    'checkout replaces legacy happy hour cart items before remote checkout',
    () async {
      final SpetoAppState appState = SpetoAppState(
        authRepository: InMemorySpetoAuthRepository(),
        commerceRepository: InMemorySpetoCommerceRepository(),
        domainApi: _FakeDomainApi(
          onFetchHappyHourOffers: () async => const <SpetoHappyHourOffer>[
            _liveHappyHourOffer,
          ],
          onCheckout:
              ({
                required List<SpetoCartItem> cartItems,
                required String pickupPointLabel,
                required String paymentMethodLabel,
                String? paymentMethodToken,
                String promoCode = '',
              }) async {
                expect(cartItems, hasLength(1));
                expect(
                  cartItems.single.id,
                  'market-product-kampus-kafe-avocado-bagel',
                );
                expect(cartItems.single.vendor, 'Kampüs Kafe');
                expect(cartItems.single.title, 'Avokadolu Bagel');
                return SpetoOrder(
                  id: 'order-live-product',
                  vendor: cartItems.single.vendor,
                  image: cartItems.single.image,
                  items: cartItems,
                  placedAtLabel: 'Bugün',
                  etaLabel: '12 dk',
                  status: SpetoOrderStatus.active,
                  actionLabel: 'Takibi Gör',
                  pickupCode: 'A123',
                  rewardPoints: 1,
                  deliveryAddress: pickupPointLabel,
                  paymentMethod: paymentMethodLabel,
                );
              },
        ),
      );

      appState.addToCart(
        const SpetoCartItem(
          id: 'mega-burger-menu',
          vendor: 'Burger Yiyelim',
          title: 'Mega Burger Menü',
          image: 'https://example.com/burger.jpg',
          unitPrice: 85,
        ),
      );

      final SpetoOrder order = await appState.checkout(
        deliveryMode: 'Gel-Al',
        deliveryAddress: 'Kampüs Kafe Gel-Al Noktası',
        paymentMethod: 'Apple Pay',
      );

      expect(order.id, 'order-live-product');
      expect(appState.cartItems, isEmpty);
    },
  );

  test('verifyOtpCode surfaces duplicate email failures', () async {
    final _ThrowingAuthRepository authRepository = _ThrowingAuthRepository();
    final Uri registerUri = Uri.parse(
      'http://127.0.0.1:4000/api/auth/register',
    );
    final Uri loginUri = Uri.parse('http://127.0.0.1:4000/api/auth/login');
    final SpetoAppState appState = SpetoAppState(
      authRepository: authRepository,
      commerceRepository: InMemorySpetoCommerceRepository(),
      domainApi: _FakeDomainApi(
        onRegister:
            ({
              required String email,
              required String displayName,
              required String phone,
              required String password,
              String? studentEmail,
            }) async => throw SpetoRemoteApiException(
              'HTTP 400',
              uri: registerUri,
              body: 'Email already registered',
            ),
        onLogin: ({required String email, required String password}) async =>
            throw SpetoRemoteApiException(
              'HTTP 401',
              uri: loginUri,
              body: 'Invalid credentials',
            ),
        onFetchSnapshot: () async => _emptySnapshot('debug@example.com'),
        onFetchInventoryItems: () async => const <SpetoInventoryItem>[],
      ),
    );

    await appState.startRegistration(
      fullName: 'Debug User',
      email: 'debug@example.com',
      phone: '5551234567',
      password: 'StrongPass123',
    );

    final SpetoRegistrationOtpVerificationResult result = await appState
        .verifyOtpCode('12345');

    expect(
      result,
      SpetoRegistrationOtpVerificationResult.emailAlreadyRegistered,
    );
    expect(appState.pendingRegistration, isNotNull);
  });

  test('verifyOtpCode restores the persisted registration draft', () async {
    final _ThrowingAuthRepository authRepository = _ThrowingAuthRepository()
      ..draft = const SpetoRegistrationDraft(
        fullName: 'Debug User',
        email: 'debug@example.com',
        phone: '5551234567',
        password: 'StrongPass123',
      );
    final SpetoAppState appState = SpetoAppState(
      authRepository: authRepository,
      commerceRepository: InMemorySpetoCommerceRepository(),
      domainApi: _FakeDomainApi(
        onRegister:
            ({
              required String email,
              required String displayName,
              required String phone,
              required String password,
              String? studentEmail,
            }) async => _buildSession(
              email: email,
              displayName: displayName,
              phone: phone,
            ),
        onLogin: ({required String email, required String password}) async =>
            _buildSession(email: email),
        onFetchSnapshot: () async => _emptySnapshot('debug@example.com'),
        onFetchInventoryItems: () async => const <SpetoInventoryItem>[],
      ),
    );

    final SpetoRegistrationOtpVerificationResult result = await appState
        .verifyOtpCode('12345');

    expect(result, SpetoRegistrationOtpVerificationResult.verified);
    expect(appState.session, isNotNull);
    expect(appState.pendingRegistration, isNull);
  });
}
