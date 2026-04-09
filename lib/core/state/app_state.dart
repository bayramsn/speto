import 'dart:async';
import 'package:flutter/material.dart';
import '../../src/core/models.dart';
import '../../src/core/bootstrap.dart';
import '../../src/core/domain_api.dart';
import '../constants/app_images.dart';
import '../data/default_data.dart';

const int jazzNightPointsCost = 650;
const int potteryWorkshopPointsCost = 420;

class SpetoAppState extends ChangeNotifier {
  SpetoAppState({
    required SpetoAuthRepository authRepository,
    required SpetoCommerceRepository commerceRepository,
    SpetoRemoteDomainApi? domainApi,
    SpetoSession? session,
    SpetoRegistrationDraft? registrationDraft,
    String? passwordResetEmail,
    SpetoCommerceSnapshot? commerceSnapshot,
  }) : _authRepository = authRepository,
       _commerceRepository = commerceRepository,
       _domainApi = domainApi,
       _session = session,
       _pendingRegistration = registrationDraft,
       _passwordResetEmail = passwordResetEmail,
       _cartItems = List<SpetoCartItem>.of(
         initialCommerceSnapshot(commerceSnapshot).cartItems,
       ),
       _activeOrders = List<SpetoOrder>.of(
         initialCommerceSnapshot(commerceSnapshot).activeOrders,
       ),
       _historyOrders = List<SpetoOrder>.of(
         initialCommerceSnapshot(commerceSnapshot).historyOrders,
       ),
       _selectedOrderId = initialCommerceSnapshot(
         commerceSnapshot,
       ).selectedOrderId,
       _proPointsBalance = initialCommerceSnapshot(
         commerceSnapshot,
       ).proPointsBalance,
       _ownedTickets = List<SpetoEventTicket>.of(
         initialCommerceSnapshot(commerceSnapshot).ownedTickets,
       ),
       _selectedTicketId = initialCommerceSnapshot(
         commerceSnapshot,
       ).selectedTicketId,
       _addresses = List<SpetoAddress>.of(
         initialCommerceSnapshot(commerceSnapshot).addresses,
       ),
       _paymentCards = List<SpetoPaymentCard>.of(
         initialCommerceSnapshot(commerceSnapshot).paymentCards,
       ),
       _supportTickets = List<SpetoSupportTicket>.of(
         initialCommerceSnapshot(commerceSnapshot).supportTickets,
       ),
       _favoriteRestaurantIds = Set<String>.of(
         initialCommerceSnapshot(commerceSnapshot).favoriteRestaurantIds,
       ),
       _favoriteEventIds = Set<String>.of(
         initialCommerceSnapshot(commerceSnapshot).favoriteEventIds,
       ),
       _followedOrganizerIds = Set<String>.of(
         initialCommerceSnapshot(commerceSnapshot).followedOrganizerIds,
       ),
       _orderRatings = Map<String, int>.of(
         initialCommerceSnapshot(commerceSnapshot).orderRatings,
       );

  final SpetoAuthRepository _authRepository;
  final SpetoCommerceRepository _commerceRepository;
  final SpetoRemoteDomainApi? _domainApi;
  List<SpetoCartItem> _cartItems;
  final List<SpetoOrder> _activeOrders;
  final List<SpetoOrder> _historyOrders;
  String? _selectedOrderId;
  double _proPointsBalance;
  final List<SpetoEventTicket> _ownedTickets;
  String? _selectedTicketId;
  final List<SpetoAddress> _addresses;
  final List<SpetoPaymentCard> _paymentCards;
  final List<SpetoSupportTicket> _supportTickets;
  final Set<String> _favoriteRestaurantIds;
  final Set<String> _favoriteEventIds;
  final Set<String> _followedOrganizerIds;
  final Map<String, int> _orderRatings;
  final Map<String, SpetoInventoryItem> _inventoryByProductId =
      <String, SpetoInventoryItem>{};
  SpetoSession? _session;
  SpetoRegistrationDraft? _pendingRegistration;
  String? _passwordResetEmail;
  bool _passwordResetOtpVerified = false;
  ThemeMode _themeMode = ThemeMode.dark;

  List<SpetoCartItem> get cartItems =>
      List<SpetoCartItem>.unmodifiable(_cartItems);
  List<SpetoOrder> get activeOrders =>
      List<SpetoOrder>.unmodifiable(_activeOrders);
  List<SpetoOrder> get historyOrders =>
      List<SpetoOrder>.unmodifiable(_historyOrders);
  bool get hasCart => _cartItems.isNotEmpty;
  int get cartCount => _cartItems.fold<int>(
    0,
    (int total, SpetoCartItem item) => total + item.quantity,
  );
  double get cartSubtotal => _cartItems.fold<double>(
    0,
    (double total, SpetoCartItem item) => total + item.totalPrice,
  );
  double get loyaltyDiscount => 0;
  double get cartTotal => cartSubtotal;
  bool get isAuthenticated => _session != null;
  ThemeMode get themeMode => _themeMode;
  SpetoSession? get session => _session;
  SpetoRegistrationDraft? get pendingRegistration => _pendingRegistration;
  String? get pendingPasswordResetEmail => _passwordResetEmail;
  bool get isPasswordResetOtpVerified => _passwordResetOtpVerified;
  String get displayName => _session?.displayName ?? 'Speto Kullanıcısı';
  String get avatarUrl => _session?.avatarUrl.isNotEmpty == true
      ? _session!.avatarUrl
      : AppImages.profile;
  bool get notificationsEnabled => _session?.notificationsEnabled ?? true;
  double get proPointsBalance => _proPointsBalance;
  List<SpetoAddress> get addresses =>
      List<SpetoAddress>.unmodifiable(_addresses);
  List<SpetoPaymentCard> get paymentCards =>
      List<SpetoPaymentCard>.unmodifiable(_paymentCards);
  List<SpetoSupportTicket> get supportTickets =>
      List<SpetoSupportTicket>.unmodifiable(_supportTickets);
  List<SpetoInventoryItem> get inventoryItems =>
      List<SpetoInventoryItem>.unmodifiable(_inventoryByProductId.values);
  bool isRestaurantFavorite(String id) => _favoriteRestaurantIds.contains(id);
  bool isEventFavorite(String id) => _favoriteEventIds.contains(id);
  bool isOrganizerFollowed(String id) => _followedOrganizerIds.contains(id);
  int? ratingForOrder(String id) => _orderRatings[id];
  SpetoInventoryItem? inventoryForProduct(String productId) =>
      _inventoryByProductId[productId];

  SpetoStockStatus? stockStatusForProduct(String productId) =>
      inventoryForProduct(productId)?.stockStatus;

  bool canPurchaseProduct(String productId, {int quantity = 1}) {
    final SpetoInventoryItem? inventoryItem = inventoryForProduct(productId);
    if (inventoryItem == null) {
      return true;
    }
    if (!inventoryItem.stockStatus.canPurchase) {
      return false;
    }
    return inventoryItem.stockStatus.availableQuantity >= quantity;
  }

  String? stockWarningForProduct(String productId, {int quantity = 1}) {
    final SpetoInventoryItem? inventoryItem = inventoryForProduct(productId);
    if (inventoryItem == null) {
      return null;
    }
    final int available = inventoryItem.stockStatus.availableQuantity;
    if (available <= 0) {
      return '${inventoryItem.title} şu anda stokta yok.';
    }
    if (available < quantity) {
      return 'Yalnızca $available adet ${inventoryItem.title} kaldı.';
    }
    return null;
  }
  List<SpetoEventTicket> get ownedTickets =>
      List<SpetoEventTicket>.unmodifiable(_ownedTickets);
  SpetoAddress? get primaryAddress {
    for (final SpetoAddress address in _addresses) {
      if (address.isPrimary) {
        return address;
      }
    }
    if (_addresses.isNotEmpty) {
      return _addresses.first;
    }
    return null;
  }

  SpetoPaymentCard? get defaultPaymentCard {
    for (final SpetoPaymentCard card in _paymentCards) {
      if (card.isDefault) {
        return card;
      }
    }
    if (_paymentCards.isNotEmpty) {
      return _paymentCards.first;
    }
    return null;
  }

  SpetoEventTicket? get selectedTicket {
    if (_selectedTicketId != null) {
      for (final SpetoEventTicket ticket in _ownedTickets) {
        if (ticket.id == _selectedTicketId) {
          return ticket;
        }
      }
    }
    if (_ownedTickets.isNotEmpty) {
      return _ownedTickets.first;
    }
    return null;
  }

  Future<bool> signIn({
    String email = '',
    String password = '',
    String? displayName,
    String? phone,
    String? avatarUrl,
    bool trustedProvider = false,
  }) async {
    final String normalizedEmail = email.trim();
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      try {
        _session = await domainApi.login(
          email: normalizedEmail,
          password: password,
        );
        await _authRepository.writeAccountPassword(normalizedEmail, password);
        await _authRepository.writeSession(_session);
        await _loadSnapshotForSession(_session);
        await _persistCommerceSnapshot();
        notifyListeners();
        return true;
      } catch (_) {
        // Fall back to the mirrored local credential store when backend auth
        // is temporarily unavailable or out of sync with demo data.
      }
    }
    final String? storedPassword = await _authRepository.readAccountPassword(
      normalizedEmail,
    );
    if (!trustedProvider &&
        (storedPassword == null || storedPassword != password)) {
      return false;
    }
    final SpetoSession? previousSession =
        _session != null &&
            _session!.email.toLowerCase() == normalizedEmail.toLowerCase()
        ? _session
        : null;
    final DateTime now = DateTime.now();
    _session = SpetoSession(
      email: normalizedEmail,
      displayName: displayName != null && displayName.trim().isNotEmpty
          ? displayName.trim()
          : previousSession?.displayName ??
                displayNameFromEmail(normalizedEmail),
      phone: phone != null && phone.trim().isNotEmpty
          ? phone.trim()
          : previousSession?.phone ?? '',
      authToken: 'local-${password.hashCode}-${now.millisecondsSinceEpoch}',
      lastLoginIso: now.toIso8601String(),
      avatarUrl: avatarUrl ?? previousSession?.avatarUrl ?? AppImages.profile,
      notificationsEnabled: previousSession?.notificationsEnabled ?? true,
    );
    if (trustedProvider) {
      await _authRepository.writeAccountPassword(normalizedEmail, password);
    }
    await _authRepository.writeSession(_session);
    await _loadSnapshotForSession(_session);
    await _persistCommerceSnapshot();
    notifyListeners();
    return true;
  }

  Future<bool> hasAccountForEmail(String email) async {
    final String normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return false;
    }
    final String? storedPassword = await _authRepository.readAccountPassword(
      normalizedEmail,
    );
    return storedPassword != null;
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> startRegistration({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _pendingRegistration = SpetoRegistrationDraft(
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
    );
    await _authRepository.writeRegistrationDraft(_pendingRegistration);
    notifyListeners();
  }

  Future<void> verifyOtpCode(String code) async {
    final SpetoRegistrationDraft? draft = _pendingRegistration;
    if (draft == null) {
      return;
    }
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      _session = await domainApi.register(
        email: draft.email,
        displayName: draft.fullName,
        phone: draft.phone,
        password: draft.password,
        studentEmail: _studentEmailFor(draft.email),
      );
    } else {
      final DateTime now = DateTime.now();
      _session = SpetoSession(
        email: draft.email,
        displayName: draft.fullName,
        phone: draft.phone,
        authToken: 'otp-$code-${now.millisecondsSinceEpoch}',
        lastLoginIso: now.toIso8601String(),
      );
    }
    _pendingRegistration = null;
    await _authRepository.writeRegistrationDraft(null);
    await _authRepository.writeAccountPassword(draft.email, draft.password);
    await _authRepository.writeSession(_session);
    await _loadSnapshotForSession(_session);
    await _persistCommerceSnapshot();
    notifyListeners();
  }

  Future<bool> requestPasswordReset({
    String email = 'ornek@sepetpro.com',
  }) async {
    final String normalizedEmail = email.trim();
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    final bool hasAccount = domainApi != null
        ? await domainApi.requestPasswordReset(normalizedEmail)
        : await hasAccountForEmail(normalizedEmail);
    if (!hasAccount) {
      _passwordResetEmail = null;
      _passwordResetOtpVerified = false;
      await _authRepository.clearPasswordResetEmail();
      notifyListeners();
      return false;
    }
    _passwordResetEmail = normalizedEmail;
    _passwordResetOtpVerified = false;
    await _authRepository.rememberPasswordResetEmail(normalizedEmail);
    notifyListeners();
    return true;
  }

  Future<bool> verifyPasswordResetOtp(String code) async {
    final String normalizedCode = code.trim();
    if (normalizedCode.length < 5) {
      return false;
    }
    final String? resetEmail =
        _passwordResetEmail ?? await _authRepository.readPasswordResetEmail();
    if (resetEmail == null || resetEmail.trim().isEmpty) {
      return false;
    }
    _passwordResetEmail = resetEmail;
    _passwordResetOtpVerified = true;
    notifyListeners();
    return true;
  }

  Future<bool> updatePassword({String password = 'StrongPass123'}) async {
    if (_pendingRegistration != null) {
      _pendingRegistration = SpetoRegistrationDraft(
        fullName: _pendingRegistration!.fullName,
        email: _pendingRegistration!.email,
        phone: _pendingRegistration!.phone,
        password: password,
      );
      await _authRepository.writeRegistrationDraft(_pendingRegistration);
      notifyListeners();
      return true;
    }
    if (_session != null) {
      final SpetoSession session = _session!;
      final SpetoRemoteDomainApi? domainApi = _domainApi;
      if (domainApi != null) {
        final bool updated = await domainApi.updatePassword(
          email: session.email,
          password: password,
        );
        if (!updated) {
          return false;
        }
      }
      await _authRepository.writeAccountPassword(session.email, password);
      notifyListeners();
      return true;
    }
    final String? resetEmail = await _authRepository.readPasswordResetEmail();
    if (resetEmail == null ||
        resetEmail.trim().isEmpty ||
        !_passwordResetOtpVerified) {
      return false;
    }
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      final bool updated = await domainApi.updatePassword(
        email: resetEmail,
        password: password,
      );
      if (!updated) {
        return false;
      }
    }
    await _authRepository.writeAccountPassword(resetEmail, password);
    await _authRepository.clearPasswordResetEmail();
    _passwordResetEmail = null;
    _passwordResetOtpVerified = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    final SpetoSession? session = _session;
    if (session != null) {
      final String? storedPassword = await _authRepository.readAccountPassword(
        session.email,
      );
      if (storedPassword == null) {
        await _authRepository.writeAccountPassword(
          session.email,
          'password123',
        );
      }
    }
    _replaceCommerceState(initialCommerceSnapshot(null));
    _session = null;
    _pendingRegistration = null;
    _passwordResetEmail = null;
    _passwordResetOtpVerified = false;
    await _authRepository.writeSession(null);
    await _authRepository.clearPasswordResetEmail();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
    required String phone,
    String? avatarUrl,
    bool? notificationsEnabled,
  }) async {
    final SpetoSession? session = _session;
    if (session == null) {
      return;
    }
    final String previousEmail = session.email;
    final String nextEmail = email.trim();
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      final SpetoRemoteUserProfile remoteProfile = await domainApi
          .updateProfile(
            displayName: displayName.trim(),
            email: nextEmail,
            phone: phone.trim(),
            avatarUrl: avatarUrl ?? session.avatarUrl,
            notificationsEnabled:
                notificationsEnabled ?? session.notificationsEnabled,
          );
      _session = _sessionFromRemoteProfile(
        remoteProfile,
        currentSession: session,
      );
    } else {
      _session = session.copyWith(
        displayName: displayName.trim(),
        email: nextEmail,
        phone: phone.trim(),
        avatarUrl: avatarUrl,
        notificationsEnabled: notificationsEnabled,
      );
    }
    if (previousEmail.toLowerCase() != nextEmail.toLowerCase()) {
      final String? storedPassword = await _authRepository.readAccountPassword(
        previousEmail,
      );
      if (storedPassword != null) {
        await _authRepository.writeAccountPassword(nextEmail, storedPassword);
        await _authRepository.deleteAccountPassword(previousEmail);
      }
    }
    await _authRepository.writeSession(_session);
    await _persistCommerceSnapshot();
    notifyListeners();
  }

  void toggleRestaurantFavorite(String id) {
    if (_favoriteRestaurantIds.contains(id)) {
      _favoriteRestaurantIds.remove(id);
    } else {
      _favoriteRestaurantIds.add(id);
    }
    _commitCommerce();
  }

  void toggleEventFavorite(String id) {
    if (_favoriteEventIds.contains(id)) {
      _favoriteEventIds.remove(id);
    } else {
      _favoriteEventIds.add(id);
    }
    _commitCommerce();
  }

  void toggleOrganizerFollow(String organizerId) {
    if (_followedOrganizerIds.contains(organizerId)) {
      _followedOrganizerIds.remove(organizerId);
    } else {
      _followedOrganizerIds.add(organizerId);
    }
    _commitCommerce();
  }

  void rateOrder(String orderId, int stars) {
    _orderRatings[orderId] = stars;
    _commitCommerce();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final SpetoSession? session = _session;
    if (session == null) {
      return;
    }
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      final SpetoRemoteUserProfile remoteProfile = await domainApi
          .updateProfile(
            displayName: session.displayName,
            email: session.email,
            phone: session.phone,
            avatarUrl: session.avatarUrl,
            notificationsEnabled: value,
          );
      _session = _sessionFromRemoteProfile(
        remoteProfile,
        currentSession: session,
      );
    } else {
      _session = session.copyWith(notificationsEnabled: value);
    }
    await _authRepository.writeSession(_session);
    await _persistCommerceSnapshot();
    notifyListeners();
  }

  Future<void> saveAddress(SpetoAddress address) async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    final SpetoAddress nextAddress = domainApi != null
        ? await domainApi.saveAddress(address)
        : address;
    _saveAddressLocally(nextAddress);
    notifyListeners();
    await _persistCommerceSnapshot();
  }

  Future<void> setPrimaryAddress(String id) async {
    final SpetoAddress? address = _findAddressById(id);
    if (address == null) {
      return;
    }
    await saveAddress(address.copyWith(isPrimary: true));
  }

  Future<void> deleteAddress(String id) async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      await domainApi.deleteAddress(id);
    }
    _addresses.removeWhere((SpetoAddress address) => address.id == id);
    if (_addresses.isNotEmpty &&
        !_addresses.any((SpetoAddress a) => a.isPrimary)) {
      _addresses[0] = _addresses[0].copyWith(isPrimary: true);
    }
    notifyListeners();
    await _persistCommerceSnapshot();
  }

  Future<void> savePaymentCard(SpetoPaymentCard card) async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    final SpetoPaymentCard nextCard = domainApi != null
        ? await domainApi.savePaymentCard(card)
        : card;
    _savePaymentCardLocally(nextCard);
    notifyListeners();
    await _persistCommerceSnapshot();
  }

  Future<void> setDefaultPaymentCard(String id) async {
    final SpetoPaymentCard? card = _findPaymentCardById(id);
    if (card == null) {
      return;
    }
    await savePaymentCard(card.copyWith(isDefault: true));
  }

  Future<void> deletePaymentCard(String id) async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      await domainApi.deletePaymentCard(id);
    }
    _paymentCards.removeWhere((SpetoPaymentCard card) => card.id == id);
    if (_paymentCards.isNotEmpty &&
        !_paymentCards.any((SpetoPaymentCard card) => card.isDefault)) {
      _paymentCards[0] = _paymentCards[0].copyWith(isDefault: true);
    }
    notifyListeners();
    await _persistCommerceSnapshot();
  }

  Future<void> createSupportTicket({
    required String subject,
    required String message,
    required String channel,
  }) async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    final SpetoSupportTicket ticket = domainApi != null
        ? await domainApi.createSupportTicket(
            subject: subject.trim(),
            message: message.trim(),
            channel: channel,
          )
        : _buildSupportTicketLocally(
            subject: subject.trim(),
            message: message.trim(),
            channel: channel,
          );
    _supportTickets.insert(0, ticket);
    notifyListeners();
    await _persistCommerceSnapshot();
  }

  Future<void> deleteAccount() async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      await domainApi.deleteAccount();
    }
    final SpetoCommerceSnapshot resetSnapshot = normalizeCommerceSnapshot(
      defaultCommerceSnapshot(),
    );
    final String? commerceScope = _commerceScopeKey(_session);
    _session = null;
    _pendingRegistration = null;
    _replaceCommerceState(resetSnapshot);
    await _authRepository.writeSession(null);
    await _authRepository.writeRegistrationDraft(null);
    if (commerceScope != null) {
      await _authRepository.deleteAccountPassword(commerceScope);
    }
    await _authRepository.clearPasswordResetEmail();
    await _commerceRepository.writeSnapshot(
      resetSnapshot,
      scopeKey: commerceScope,
    );
    notifyListeners();
  }

  SpetoOrder? get selectedOrder {
    final SpetoOrder? order = _findOrderById(_selectedOrderId);
    if (order != null) {
      return order;
    }
    if (_activeOrders.isNotEmpty) {
      return _activeOrders.first;
    }
    if (_historyOrders.isNotEmpty) {
      return _historyOrders.first;
    }
    return null;
  }

  bool addToCart(SpetoCartItem item) {
    final int index = _cartItems.indexWhere(
      (SpetoCartItem line) => line.id == item.id,
    );
    final int nextQuantity = index >= 0
        ? _cartItems[index].quantity + item.quantity
        : item.quantity;
    if (!canPurchaseProduct(item.id, quantity: nextQuantity)) {
      return false;
    }
    if (index >= 0) {
      final SpetoCartItem existing = _cartItems[index];
      _cartItems[index] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      _cartItems.add(item);
    }
    _commitCommerce();
    return true;
  }

  void updateCartItemQuantity(String id, int quantity) {
    final int index = _cartItems.indexWhere(
      (SpetoCartItem item) => item.id == id,
    );
    if (index < 0) {
      return;
    }
    if (quantity <= 0) {
      _cartItems.removeAt(index);
    } else {
      if (!canPurchaseProduct(id, quantity: quantity)) {
        return;
      }
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
    }
    _commitCommerce();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((SpetoCartItem item) => item.id == id);
    _commitCommerce();
  }

  void clearCart() {
    _cartItems = <SpetoCartItem>[];
    _commitCommerce();
  }

  double earnedProPointsForTotal(double total) {
    return double.parse((total * 0.01).toStringAsFixed(2));
  }

  Future<SpetoOrder> checkout({
    required String deliveryMode,
    required String deliveryAddress,
    required String paymentMethod,
    String promoCode = '',
    double deliveryFee = 0,
    double discountAmount = 0,
  }) async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      final SpetoOrder order = await domainApi.checkout(
        cartItems: _cartItems,
        pickupPointLabel: deliveryAddress,
        paymentMethodLabel: paymentMethod,
        paymentMethodToken: defaultPaymentCard?.id,
        promoCode: promoCode,
      );
      _activeOrders.insert(0, order);
      _selectedOrderId = order.id;
      _proPointsBalance += order.rewardPoints;
      _cartItems = <SpetoCartItem>[];
      await _refreshInventoryFromBackend();
      notifyListeners();
      await _persistCommerceSnapshot();
      return order;
    }
    final DateTime now = DateTime.now();
    final String orderId = 'order-${now.microsecondsSinceEpoch}';
    final String pickupCode =
        'S${(now.millisecond + now.second).toString().padLeft(3, '0')}';
    const String normalizedDeliveryMode = 'Gel-Al';
    final double payableTotal =
        _cartItems.fold<double>(
          0,
          (double total, SpetoCartItem item) => total + item.totalPrice,
        ) +
        deliveryFee -
        discountAmount;
    final double rewardPoints = earnedProPointsForTotal(payableTotal);
    final SpetoOrder order = SpetoOrder(
      id: orderId,
      vendor: _cartItems.first.vendor,
      image: _cartItems.first.image,
      items: _cartItems.map((SpetoCartItem item) => item.copyWith()).toList(),
      placedAtLabel:
          'Bugün • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      etaLabel: '12 dk',
      status: SpetoOrderStatus.active,
      actionLabel: 'Takibi Gör',
      pickupCode: pickupCode,
      rewardPoints: rewardPoints,
      deliveryMode: normalizedDeliveryMode,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
    );
    _activeOrders.insert(0, order);
    _selectedOrderId = order.id;
    _proPointsBalance += rewardPoints;
    _cartItems = <SpetoCartItem>[];
    _commitCommerce();
    return order;
  }

  void selectOrder(SpetoOrder order) {
    _selectedOrderId = order.id;
    _commitCommerce();
  }

  void reorder(SpetoOrder order) {
    _selectedOrderId = order.id;
    _cartItems = order.items
        .map((SpetoCartItem item) => item.copyWith())
        .toList();
    _commitCommerce();
  }

  Future<void> completeSelectedOrder() async {
    final SpetoOrder? order = selectedOrder;
    if (order == null) {
      return;
    }
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      final SpetoOrder completed = await domainApi.completeOrder(order.id);
      _applyCompletedOrder(completed);
      await _refreshInventoryFromBackend();
      notifyListeners();
      await _persistCommerceSnapshot();
      return;
    }
    final int index = _activeOrders.indexWhere(
      (SpetoOrder item) => item.id == order.id,
    );
    if (index < 0) {
      return;
    }
    final SpetoOrder completed = order.copyWith(
      status: SpetoOrderStatus.completed,
      actionLabel: 'Detayları Gör',
      etaLabel: 'Teslim edildi',
    );
    _activeOrders.removeAt(index);
    _historyOrders.insert(0, completed);
    _selectedOrderId = completed.id;
    _commitCommerce();
  }

  bool canPurchaseTicket(int pointsCost) => _proPointsBalance >= pointsCost;

  Future<bool> purchaseEventTicket({
    required String eventId,
    required String title,
    required String venue,
    required String dateLabel,
    required String timeLabel,
    required String image,
    required int pointsCost,
    String seat = 'A12',
    String zone = 'VIP',
    String gate = 'G3',
  }) async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi != null) {
      try {
        final SpetoEventTicket ticket = await domainApi.redeemEventTicket(
          eventId: eventId,
          seat: seat,
          zone: zone,
          gate: gate,
        );
        _proPointsBalance -= pointsCost;
        _ownedTickets.insert(0, ticket);
        _selectedTicketId = ticket.id;
        notifyListeners();
        await _persistCommerceSnapshot();
        return true;
      } catch (_) {
        return false;
      }
    }
    if (!canPurchaseTicket(pointsCost)) {
      return false;
    }
    final DateTime now = DateTime.now();
    final SpetoEventTicket ticket = SpetoEventTicket(
      id: 'ticket-${now.microsecondsSinceEpoch}',
      title: title,
      venue: venue,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      zone: zone,
      seat: seat,
      gate: gate,
      code:
          'QR-${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}-GALATA',
      image: image,
      pointsCost: pointsCost,
    );
    _proPointsBalance -= pointsCost;
    _ownedTickets.insert(0, ticket);
    _selectedTicketId = ticket.id;
    _commitCommerce();
    return true;
  }

  void selectTicket(SpetoEventTicket ticket) {
    _selectedTicketId = ticket.id;
    _commitCommerce();
  }

  String? _commerceScopeKey(SpetoSession? session) => session?.email;

  Future<void> _loadSnapshotForSession(SpetoSession? session) async {
    final SpetoCommerceSnapshot snapshot = initialCommerceSnapshot(
      await _commerceRepository.readSnapshot(
        scopeKey: _commerceScopeKey(session),
      ),
    );
    _replaceCommerceState(snapshot);
    if (session != null) {
      _session = session.copyWith(
        displayName: snapshot.profileDisplayName.isNotEmpty
            ? snapshot.profileDisplayName
            : session.displayName,
        phone: snapshot.profilePhone.isNotEmpty
            ? snapshot.profilePhone
            : session.phone,
        avatarUrl: snapshot.profileAvatarUrl.isNotEmpty
            ? snapshot.profileAvatarUrl
            : session.avatarUrl,
        notificationsEnabled: snapshot.profileNotificationsEnabled,
      );
      if (_domainApi != null) {
        await _syncDomainStateFromBackend();
      }
      await _authRepository.writeSession(_session);
    }
  }

  void _replaceCommerceState(SpetoCommerceSnapshot snapshot) {
    _cartItems = List<SpetoCartItem>.of(snapshot.cartItems);
    _activeOrders
      ..clear()
      ..addAll(snapshot.activeOrders);
    _historyOrders
      ..clear()
      ..addAll(snapshot.historyOrders);
    _selectedOrderId = snapshot.selectedOrderId;
    _proPointsBalance = snapshot.proPointsBalance;
    _ownedTickets
      ..clear()
      ..addAll(snapshot.ownedTickets);
    _selectedTicketId = snapshot.selectedTicketId;
    _addresses
      ..clear()
      ..addAll(snapshot.addresses);
    _paymentCards
      ..clear()
      ..addAll(snapshot.paymentCards);
    _supportTickets
      ..clear()
      ..addAll(snapshot.supportTickets);
    _favoriteRestaurantIds
      ..clear()
      ..addAll(snapshot.favoriteRestaurantIds);
    _favoriteEventIds
      ..clear()
      ..addAll(snapshot.favoriteEventIds);
    _followedOrganizerIds
      ..clear()
      ..addAll(snapshot.followedOrganizerIds);
    _orderRatings
      ..clear()
      ..addAll(snapshot.orderRatings);
  }

  SpetoOrder? _findOrderById(String? id) {
    if (id == null) {
      return null;
    }
    for (final SpetoOrder order in _activeOrders) {
      if (order.id == id) {
        return order;
      }
    }
    for (final SpetoOrder order in _historyOrders) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  void _commitCommerce() {
    notifyListeners();
    unawaited(_persistCommerceSnapshot());
  }

  Future<void> _persistCommerceSnapshot() {
    return _commerceRepository.writeSnapshot(
      _snapshotFromState(),
      scopeKey: _commerceScopeKey(_session),
    );
  }

  Future<void> _syncDomainStateFromBackend() async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    final SpetoSession? currentSession = _session;
    if (domainApi == null || currentSession == null) {
      return;
    }
    final SpetoRemoteSnapshot snapshot = await domainApi.fetchSnapshot();
    await _refreshInventoryFromBackend();
    _session = _sessionFromRemoteProfile(
      snapshot.profile,
      currentSession: currentSession,
    );
    _addresses
      ..clear()
      ..addAll(snapshot.addresses);
    _paymentCards
      ..clear()
      ..addAll(snapshot.paymentCards);
    _activeOrders
      ..clear()
      ..addAll(snapshot.activeOrders);
    _historyOrders
      ..clear()
      ..addAll(snapshot.historyOrders);
    _supportTickets
      ..clear()
      ..addAll(snapshot.supportTickets);
    _ownedTickets
      ..clear()
      ..addAll(snapshot.ownedTickets);
    _proPointsBalance = snapshot.proPointsBalance;
    if (_selectedOrderId != null && _findOrderById(_selectedOrderId) == null) {
      _selectedOrderId = _activeOrders.isNotEmpty
          ? _activeOrders.first.id
          : _historyOrders.isNotEmpty
          ? _historyOrders.first.id
          : null;
    }
    if (_selectedTicketId != null &&
        !_ownedTickets.any(
          (SpetoEventTicket ticket) => ticket.id == _selectedTicketId,
        )) {
      _selectedTicketId = _ownedTickets.isNotEmpty
          ? _ownedTickets.first.id
          : null;
    }
  }

  Future<void> _refreshInventoryFromBackend() async {
    final SpetoRemoteDomainApi? domainApi = _domainApi;
    if (domainApi == null) {
      _inventoryByProductId.clear();
      return;
    }
    final List<SpetoInventoryItem> items = await domainApi.fetchInventoryItems();
    _inventoryByProductId
      ..clear()
      ..addEntries(
        items.map(
          (SpetoInventoryItem item) =>
              MapEntry<String, SpetoInventoryItem>(item.id, item),
        ),
      );
  }

  SpetoSession _sessionFromRemoteProfile(
    SpetoRemoteUserProfile profile, {
    required SpetoSession currentSession,
  }) {
    return currentSession.copyWith(
      email: profile.email,
      displayName: profile.displayName,
      phone: profile.phone,
      avatarUrl: profile.avatarUrl,
      notificationsEnabled: profile.notificationsEnabled,
    );
  }

  void _saveAddressLocally(SpetoAddress address) {
    final int index = _addresses.indexWhere(
      (SpetoAddress item) => item.id == address.id,
    );
    final SpetoAddress normalized = address.copyWith(
      label: address.label.trim(),
      address: address.address.trim(),
    );
    if (normalized.isPrimary) {
      for (int i = 0; i < _addresses.length; i += 1) {
        _addresses[i] = _addresses[i].copyWith(isPrimary: false);
      }
    }
    if (index >= 0) {
      _addresses[index] = normalized;
    } else {
      _addresses.add(
        normalized.copyWith(
          isPrimary: _addresses.isEmpty || normalized.isPrimary,
        ),
      );
    }
  }

  SpetoAddress? _findAddressById(String id) {
    for (final SpetoAddress address in _addresses) {
      if (address.id == id) {
        return address;
      }
    }
    return null;
  }

  void _savePaymentCardLocally(SpetoPaymentCard card) {
    final int index = _paymentCards.indexWhere(
      (SpetoPaymentCard item) => item.id == card.id,
    );
    final SpetoPaymentCard normalized = card.copyWith(
      brand: card.brand.trim().toUpperCase(),
      last4: card.last4.trim(),
      expiry: card.expiry.trim(),
      holderName: card.holderName.trim(),
    );
    if (normalized.isDefault) {
      for (int i = 0; i < _paymentCards.length; i += 1) {
        _paymentCards[i] = _paymentCards[i].copyWith(isDefault: false);
      }
    }
    if (index >= 0) {
      _paymentCards[index] = normalized;
    } else {
      _paymentCards.add(
        normalized.copyWith(
          isDefault: _paymentCards.isEmpty || normalized.isDefault,
        ),
      );
    }
  }

  SpetoPaymentCard? _findPaymentCardById(String id) {
    for (final SpetoPaymentCard card in _paymentCards) {
      if (card.id == id) {
        return card;
      }
    }
    return null;
  }

  SpetoSupportTicket _buildSupportTicketLocally({
    required String subject,
    required String message,
    required String channel,
  }) {
    final DateTime now = DateTime.now();
    return SpetoSupportTicket(
      id: 'support-${now.microsecondsSinceEpoch}',
      subject: subject,
      message: message,
      channel: channel,
      createdAtLabel:
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
  }

  void _applyCompletedOrder(SpetoOrder completed) {
    _activeOrders.removeWhere((SpetoOrder item) => item.id == completed.id);
    _historyOrders.removeWhere((SpetoOrder item) => item.id == completed.id);
    _historyOrders.insert(0, completed);
    _selectedOrderId = completed.id;
  }

  String? _studentEmailFor(String email) {
    final String normalized = email.trim().toLowerCase();
    if (RegExp(r'^[^@\s]+@[^@\s]+\.edu(\.tr)?$').hasMatch(normalized)) {
      return normalized;
    }
    return null;
  }

  SpetoCommerceSnapshot _snapshotFromState() {
    return SpetoCommerceSnapshot(
      cartItems: _cartItems
          .map((SpetoCartItem item) => item.copyWith())
          .toList(),
      activeOrders: _activeOrders
          .map((SpetoOrder order) => order.copyWith())
          .toList(),
      historyOrders: _historyOrders
          .map((SpetoOrder order) => order.copyWith())
          .toList(),
      selectedOrderId: _selectedOrderId,
      proPointsBalance: _proPointsBalance,
      ownedTickets: List<SpetoEventTicket>.of(_ownedTickets),
      selectedTicketId: _selectedTicketId,
      addresses: _addresses
          .map((SpetoAddress address) => address.copyWith())
          .toList(),
      paymentCards: _paymentCards
          .map((SpetoPaymentCard card) => card.copyWith())
          .toList(),
      supportTickets: _supportTickets
          .map((SpetoSupportTicket ticket) => ticket.copyWith())
          .toList(),
      favoriteRestaurantIds: _favoriteRestaurantIds.toList(),
      favoriteEventIds: _favoriteEventIds.toList(),
      followedOrganizerIds: _followedOrganizerIds.toList(),
      orderRatings: Map<String, int>.of(_orderRatings),
      profileDisplayName: _session?.displayName ?? '',
      profilePhone: _session?.phone ?? '',
      profileAvatarUrl: _session?.avatarUrl ?? '',
      profileNotificationsEnabled: _session?.notificationsEnabled ?? true,
    );
  }
}

class SpetoAppScope extends InheritedNotifier<SpetoAppState> {
  const SpetoAppScope({
    super.key,
    required SpetoAppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static SpetoAppState of(BuildContext context) {
    final SpetoAppScope? scope = context
        .dependOnInheritedWidgetOfExactType<SpetoAppScope>();
    assert(scope != null, 'SpetoAppScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
