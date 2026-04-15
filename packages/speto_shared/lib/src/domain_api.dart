import 'models.dart';
import 'remote_api.dart';

class SpetoRemoteDomainApi {
  SpetoRemoteDomainApi(this._apiClient);

  final SpetoRemoteApiClient _apiClient;

  Future<SpetoSession> login({
    required String email,
    required String password,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'auth/login',
        body: <String, Object?>{'email': email, 'password': password},
      ),
    );
    return _apiClient.consumeAuthResponse(json);
  }

  Future<SpetoSession> register({
    required String email,
    required String displayName,
    required String phone,
    required String password,
    String? studentEmail,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'auth/register',
        body: <String, Object?>{
          'email': email,
          'displayName': displayName,
          'phone': phone,
          'password': password,
          if (studentEmail != null && studentEmail.trim().isNotEmpty)
            'studentEmail': studentEmail,
        },
      ),
    );
    return _apiClient.consumeAuthResponse(json);
  }

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
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'auth/operator-register',
        body: <String, Object?>{
          'storefrontType': _storefrontTypeApiName(storefrontType),
          'business': <String, Object?>{
            'name': businessName,
            'category': businessCategory,
            'subtitle': businessSubtitle,
            'imageUrl': businessImageUrl,
            'city': city,
            'district': district,
            'pickupPointLabel': pickupPointLabel,
            'pickupPointAddress': pickupPointAddress,
            'workingHoursLabel': workingHoursLabel,
            'workingDays': workingDays,
            'taxNumber': taxNumber,
            'taxOffice': taxOffice,
          },
          'operator': <String, Object?>{
            'email': email,
            'password': password,
            'displayName': displayName,
            'phone': phone,
          },
          'bankAccount': <String, Object?>{
            'holderName': holderName,
            'bankName': bankName,
            'iban': iban,
          },
          'consents': <String, Object?>{
            'termsAccepted': termsAccepted,
            'privacyAccepted': privacyAccepted,
            'marketingOptIn': marketingOptIn,
          },
          'notifications': <String, Object?>{
            'newOrders': notifyNewOrders,
            'cancellations': notifyCancellations,
            'lowStock': notifyLowStock,
            'campaignTips': notifyCampaignTips,
            'sms': notifySms,
            'push': notifyPush,
          },
        },
      ),
    );
    return _apiClient.consumeAuthResponse(json);
  }

  Future<bool> checkHealth() async {
    return _apiClient.checkHealth();
  }

  Future<SpetoCatalogBootstrap> fetchCatalogBootstrap() async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get('catalog/bootstrap'),
    );
    return SpetoCatalogBootstrap.fromJson(json);
  }

  Future<SpetoCatalogVendor> fetchCatalogVendor(String vendorId) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get('catalog/vendors/${Uri.encodeComponent(vendorId)}'),
    );
    return SpetoCatalogVendor.fromJson(json);
  }

  Future<List<SpetoCatalogVendor>> fetchCatalogAdminVendors({
    String? vendorId,
  }) async {
    final Object? response = await _apiClient.get(
      'catalog/admin/vendors',
      queryParameters: <String, String?>{'vendorId': vendorId},
    );
    return _mapList(response, SpetoCatalogVendor.fromJson);
  }

  Future<SpetoCatalogVendor> createCatalogVendor(
    Map<String, Object?> payload,
  ) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post('catalog/admin/vendors', body: payload),
    );
    return SpetoCatalogVendor.fromJson(json);
  }

  Future<SpetoCatalogVendor> updateCatalogVendor(
    String vendorId,
    Map<String, Object?> payload,
  ) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.patch(
        'catalog/admin/vendors/${Uri.encodeComponent(vendorId)}',
        body: payload,
      ),
    );
    return SpetoCatalogVendor.fromJson(json);
  }

  Future<List<SpetoCatalogSection>> updateCatalogSection(
    String sectionId,
    Map<String, Object?> payload,
  ) async {
    final Object? response = await _apiClient.patch(
      'catalog/admin/sections/${Uri.encodeComponent(sectionId)}',
      body: payload,
    );
    return _mapList(response, SpetoCatalogSection.fromJson);
  }

  Future<List<SpetoCatalogSection>> createCatalogSection(
    Map<String, Object?> payload,
  ) async {
    final Object? response = await _apiClient.post(
      'catalog/admin/sections',
      body: payload,
    );
    return _mapList(response, SpetoCatalogSection.fromJson);
  }

  Future<List<SpetoCatalogProduct>> fetchCatalogAdminProducts({
    String? vendorId,
  }) async {
    final Object? response = await _apiClient.get(
      'catalog/admin/products',
      queryParameters: <String, String?>{'vendorId': vendorId},
    );
    return _mapList(response, SpetoCatalogProduct.fromJson);
  }

  Future<SpetoCatalogVendor> createCatalogProduct(
    Map<String, Object?> payload,
  ) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post('catalog/admin/products', body: payload),
    );
    return SpetoCatalogVendor.fromJson(json);
  }

  Future<SpetoCatalogVendor> updateCatalogProduct(
    String productId,
    Map<String, Object?> payload,
  ) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.patch(
        'catalog/admin/products/${Uri.encodeComponent(productId)}',
        body: payload,
      ),
    );
    return SpetoCatalogVendor.fromJson(json);
  }

  Future<List<SpetoCatalogEvent>> fetchCatalogAdminEvents() async {
    final Object? response = await _apiClient.get('catalog/admin/events');
    return _mapList(response, SpetoCatalogEvent.fromJson);
  }

  Future<SpetoCatalogEvent> updateCatalogEvent(
    String eventId,
    Map<String, Object?> payload,
  ) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.patch(
        'catalog/admin/events/${Uri.encodeComponent(eventId)}',
        body: payload,
      ),
    );
    return SpetoCatalogEvent.fromJson(json);
  }

  Future<List<SpetoCatalogContentBlock>> fetchCatalogContentBlocks({
    SpetoContentBlockType? type,
  }) async {
    final Object? response = await _apiClient.get(
      'catalog/admin/content-blocks',
      queryParameters: <String, String?>{
        'type': type == null ? null : _contentBlockTypeApiName(type),
      },
    );
    return _mapList(response, SpetoCatalogContentBlock.fromJson);
  }

  Future<List<SpetoCatalogContentBlock>> updateCatalogContentBlock(
    String blockId,
    Map<String, Object?> payload,
  ) async {
    final Object? response = await _apiClient.patch(
      'catalog/admin/content-blocks/${Uri.encodeComponent(blockId)}',
      body: payload,
    );
    return _mapList(response, SpetoCatalogContentBlock.fromJson);
  }

  void setSession(SpetoSession? session) {
    _apiClient.setSession(session);
  }

  SpetoSession mergeSession(SpetoSession session) {
    return _apiClient.mergeSession(session);
  }

  bool shouldRefreshSession({
    Duration threshold = const Duration(seconds: 30),
  }) {
    return _apiClient.shouldRefreshSession(threshold: threshold);
  }

  Future<SpetoSession?> refreshSession({
    String? refreshToken,
    bool notifyListeners = true,
  }) {
    return _apiClient.refreshSession(
      refreshToken: refreshToken,
      notifyListeners: notifyListeners,
    );
  }

  Future<void> logout({String? refreshToken}) async {
    final String normalizedRefreshToken = refreshToken?.trim() ?? '';
    if (normalizedRefreshToken.isNotEmpty) {
      await _apiClient.post(
        'auth/logout',
        body: <String, Object?>{'refreshToken': normalizedRefreshToken},
      );
    }
    clearSession();
  }

  void clearSession() {
    _apiClient.clearSession();
  }

  Future<bool> requestPasswordReset(String email) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'auth/password/request',
        body: <String, Object?>{'email': email},
      ),
    );
    return json['exists'] == true;
  }

  Future<bool> hasAccountForEmail(String email) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'auth/account-exists',
        body: <String, Object?>{'email': email},
      ),
    );
    return json['exists'] == true;
  }

  Future<bool> updatePassword({
    required String email,
    required String password,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'auth/password/update',
        body: <String, Object?>{'email': email, 'password': password},
      ),
    );
    return json['success'] == true;
  }

  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'auth/password/verify-otp',
        body: <String, Object?>{'email': email, 'code': code},
      ),
    );
    return json['verified'] == true;
  }

  Future<List<SpetoHappyHourOffer>> fetchHappyHourOffers() async {
    final Object? response = await _apiClient.get('offers/happy-hour');
    return _mapList(response, SpetoHappyHourOffer.fromJson);
  }

  Future<SpetoHappyHourOffer> fetchHappyHourOffer(String offerId) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get('offers/happy-hour/${Uri.encodeComponent(offerId)}'),
    );
    return SpetoHappyHourOffer.fromJson(json);
  }

  Future<SpetoRemoteSnapshot> fetchSnapshot() async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get('me/snapshot'),
    );
    final Map<String, Object?> profile = _asJsonMap(json['profile']);
    final Map<String, Object?> wallet = _asJsonMap(json['wallet']);
    return SpetoRemoteSnapshot(
      profile: SpetoRemoteUserProfile.fromJson(profile),
      addresses: _mapList(json['addresses'], SpetoAddress.fromJson),
      paymentCards: _mapList(json['paymentMethods'], SpetoPaymentCard.fromJson),
      activeOrders: _mapList(json['activeOrders'], SpetoOrder.fromJson),
      historyOrders: _mapList(json['historyOrders'], SpetoOrder.fromJson),
      supportTickets: _mapList(
        json['supportTickets'],
        SpetoSupportTicket.fromJson,
      ),
      ownedTickets: _mapList(wallet['ownedTickets'], SpetoEventTicket.fromJson),
      proPointsBalance: (wallet['balance'] as num?)?.toDouble() ?? 0,
      favoriteRestaurantIds: _stringList(wallet['favoriteRestaurantIds']),
      favoriteEventIds: _stringList(wallet['favoriteEventIds']),
      favoriteMarketIds: _stringList(wallet['favoriteMarketIds']),
      followedOrganizerIds: _stringList(wallet['followedOrganizerIds']),
      orderRatings: _stringIntMap(wallet['orderRatings']),
    );
  }

  Future<SpetoRemoteUserProfile> updateProfile({
    required String displayName,
    required String email,
    required String phone,
    required String avatarUrl,
    required bool notificationsEnabled,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.patch(
        'me',
        body: <String, Object?>{
          'displayName': displayName,
          'email': email,
          'phone': phone,
          'avatarUrl': avatarUrl,
          'notificationsEnabled': notificationsEnabled,
        },
      ),
    );
    return SpetoRemoteUserProfile.fromJson(json);
  }

  Future<SpetoAddress> saveAddress(SpetoAddress address) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post('me/addresses', body: address.toJson()),
    );
    return SpetoAddress.fromJson(json);
  }

  Future<void> deleteAddress(String id) async {
    await _apiClient.delete('me/addresses/${Uri.encodeComponent(id)}');
  }

  Future<SpetoPaymentCard> savePaymentCard(SpetoPaymentCard card) async {
    final Map<String, Object?> body = <String, Object?>{
      ...card.toJson(),
      'token': card.id,
    };
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post('me/payment-methods', body: body),
    );
    return SpetoPaymentCard.fromJson(json);
  }

  Future<void> deletePaymentCard(String id) async {
    await _apiClient.delete('me/payment-methods/${Uri.encodeComponent(id)}');
  }

  Future<SpetoSupportTicket> createSupportTicket({
    required String subject,
    required String message,
    required String channel,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'support/tickets',
        body: <String, Object?>{
          'subject': subject,
          'message': message,
          'channel': channel,
        },
      ),
    );
    return SpetoSupportTicket.fromJson(json);
  }

  Future<List<SpetoSupportTicket>> fetchSupportTickets() async {
    final Object? response = await _apiClient.get('support/tickets');
    return _mapList(response, SpetoSupportTicket.fromJson);
  }

  Future<void> updatePreference({
    required String entityType,
    required String entityId,
    required bool enabled,
  }) async {
    await _apiClient.post(
      'me/preferences',
      body: <String, Object?>{
        'entityType': entityType,
        'entityId': entityId,
        'enabled': enabled,
      },
    );
  }

  Future<SpetoOrder> checkout({
    required List<SpetoCartItem> cartItems,
    required String pickupPointLabel,
    required String paymentMethodLabel,
    String? paymentMethodToken,
    String promoCode = '',
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'orders/checkout',
        body: <String, Object?>{
          'fulfillmentMode': 'PICKUP',
          'pickupPointId': pickupPointLabel,
          'paymentMethodToken': paymentMethodToken,
          'paymentMethodLabel': paymentMethodLabel,
          'promoCode': promoCode.isEmpty ? null : promoCode,
          'items': cartItems
              .map(
                (SpetoCartItem item) => <String, Object?>{
                  'productId': item.id,
                  'quantity': item.quantity,
                  'vendor': item.vendor,
                  'title': item.title,
                  'image': item.image,
                  'unitPrice': item.unitPrice,
                },
              )
              .toList(),
        },
      ),
    );
    return SpetoOrder.fromJson(json);
  }

  Future<SpetoOrder> completeOrder(String orderId) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post('orders/${Uri.encodeComponent(orderId)}/complete'),
    );
    return SpetoOrder.fromJson(json);
  }

  Future<void> rateOrder({required String orderId, required int stars}) async {
    await _apiClient.post(
      'orders/${Uri.encodeComponent(orderId)}/rating',
      body: <String, Object?>{'stars': stars},
    );
  }

  Future<SpetoEventTicket> redeemEventTicket({
    required String eventId,
    required String seat,
    required String zone,
    required String gate,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'wallet/redeem/${Uri.encodeComponent(eventId)}',
        body: <String, Object?>{'seat': seat, 'zone': zone, 'gate': gate},
      ),
    );
    return SpetoEventTicket.fromJson(json);
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete('me');
  }

  Future<SpetoInventorySnapshot> fetchInventorySnapshot({
    String? vendorId,
    String? query,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get(
        'inventory/dashboard',
        queryParameters: <String, String?>{
          'vendorId': vendorId,
          'query': query,
        },
      ),
    );
    return SpetoInventorySnapshot.fromJson(json);
  }

  Future<List<SpetoInventoryItem>> fetchInventoryItems({
    String? vendorId,
    String? query,
  }) async {
    final Object? response = await _apiClient.get(
      'inventory/items',
      queryParameters: <String, String?>{'vendorId': vendorId, 'query': query},
    );
    return _mapList(response, SpetoInventoryItem.fromJson);
  }

  Future<SpetoInventoryItem> fetchInventoryItem(String id) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get('inventory/items/${Uri.encodeComponent(id)}'),
    );
    return SpetoInventoryItem.fromJson(json);
  }

  Future<SpetoInventoryItem> adjustInventoryItem({
    required String id,
    required int quantityDelta,
    required String reason,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'inventory/items/${Uri.encodeComponent(id)}/adjust',
        body: <String, Object?>{
          'quantityDelta': quantityDelta,
          'reason': reason,
        },
      ),
    );
    return SpetoInventoryItem.fromJson(json);
  }

  Future<SpetoInventoryItem> restockInventoryItem({
    required String id,
    required int quantity,
    required String note,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'inventory/items/${Uri.encodeComponent(id)}/restock',
        body: <String, Object?>{'quantity': quantity, 'note': note},
      ),
    );
    return SpetoInventoryItem.fromJson(json);
  }

  Future<List<SpetoInventoryMovement>> fetchInventoryMovements({
    String? vendorId,
    String? productId,
  }) async {
    final Object? response = await _apiClient.get(
      'inventory/movements',
      queryParameters: <String, String?>{
        'vendorId': vendorId,
        'productId': productId,
      },
    );
    return _mapList(response, SpetoInventoryMovement.fromJson);
  }

  Future<List<SpetoOpsOrder>> fetchOpsOrders({String? vendorId}) async {
    final Object? response = await _apiClient.get(
      'ops/orders',
      queryParameters: <String, String?>{'vendorId': vendorId},
    );
    return _mapList(response, SpetoOrder.fromJson);
  }

  Future<SpetoOpsOrder> updateOpsOrderStatus(
    String orderId,
    SpetoOpsOrderStage stage,
  ) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.patch(
        'ops/orders/${Uri.encodeComponent(orderId)}/status',
        body: <String, Object?>{'status': stage.name.toUpperCase()},
      ),
    );
    return SpetoOrder.fromJson(json);
  }

  Future<List<SpetoIntegrationConnection>> fetchIntegrations({
    String? vendorId,
  }) async {
    final Object? response = await _apiClient.get(
      'integrations',
      queryParameters: <String, String?>{'vendorId': vendorId},
    );
    return _mapList(response, SpetoIntegrationConnection.fromJson);
  }

  Future<SpetoIntegrationConnection> createIntegration({
    required String vendorId,
    required String name,
    required String provider,
    required SpetoIntegrationType type,
    required String baseUrl,
    required String locationId,
    required Map<String, String> skuMappings,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'integrations',
        body: <String, Object?>{
          'vendorId': vendorId,
          'name': name,
          'provider': provider,
          'type': type.name.toUpperCase(),
          'baseUrl': baseUrl,
          'locationId': locationId,
          'skuMappings': skuMappings,
        },
      ),
    );
    return SpetoIntegrationConnection.fromJson(json);
  }

  Future<SpetoIntegrationSyncStatus> syncIntegration(String id) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post('integrations/${Uri.encodeComponent(id)}/sync'),
    );
    return SpetoIntegrationSyncStatus.fromJson(json);
  }

  Future<SpetoVendorFinanceSummary> fetchFinanceSummary({
    String? vendorId,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get(
        'ops/finance/summary',
        queryParameters: <String, String?>{'vendorId': vendorId},
      ),
    );
    return SpetoVendorFinanceSummary.fromJson(json);
  }

  Future<List<SpetoVendorBankAccount>> fetchFinanceAccounts({
    String? vendorId,
  }) async {
    final Object? response = await _apiClient.get(
      'ops/finance/accounts',
      queryParameters: <String, String?>{'vendorId': vendorId},
    );
    return _mapList(response, SpetoVendorBankAccount.fromJson);
  }

  Future<SpetoVendorBankAccount> createFinanceAccount({
    required String vendorId,
    required String holderName,
    required String bankName,
    required String iban,
    bool? isDefault,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'ops/finance/accounts',
        body: <String, Object?>{
          'vendorId': vendorId,
          'holderName': holderName,
          'bankName': bankName,
          'iban': iban,
          if (isDefault != null) 'isDefault': isDefault,
        },
      ),
    );
    return SpetoVendorBankAccount.fromJson(json);
  }

  Future<SpetoVendorPayout> createPayout({
    required String vendorId,
    required String bankAccountId,
    required double amount,
    String? note,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'ops/finance/payouts',
        body: <String, Object?>{
          'vendorId': vendorId,
          'bankAccountId': bankAccountId,
          'amount': amount,
          if (note != null && note.trim().isNotEmpty) 'note': note,
        },
      ),
    );
    return SpetoVendorPayout.fromJson(json);
  }

  Future<SpetoVendorCampaignSummary> fetchCampaignSummary({
    String? vendorId,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.get(
        'ops/campaigns/summary',
        queryParameters: <String, String?>{'vendorId': vendorId},
      ),
    );
    return SpetoVendorCampaignSummary.fromJson(json);
  }

  Future<List<SpetoVendorCampaign>> fetchCampaigns({String? vendorId}) async {
    final Object? response = await _apiClient.get(
      'ops/campaigns',
      queryParameters: <String, String?>{'vendorId': vendorId},
    );
    return _mapList(response, SpetoVendorCampaign.fromJson);
  }

  Future<SpetoVendorCampaign> createCampaign({
    required String vendorId,
    required SpetoCampaignKind kind,
    required String title,
    String? description,
    SpetoCampaignStatus? status,
    String? startsAt,
    String? endsAt,
    String? scheduleLabel,
    String? badgeLabel,
    int? discountPercent,
    double? discountedPrice,
    List<String>? productIds,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'ops/campaigns',
        body: <String, Object?>{
          'vendorId': vendorId,
          'kind': _campaignKindApiName(kind),
          'title': title,
          if (description != null) 'description': description,
          if (status != null) 'status': _campaignStatusApiName(status),
          if (startsAt != null) 'startsAt': startsAt,
          if (endsAt != null) 'endsAt': endsAt,
          if (scheduleLabel != null) 'scheduleLabel': scheduleLabel,
          if (badgeLabel != null) 'badgeLabel': badgeLabel,
          if (discountPercent != null) 'discountPercent': discountPercent,
          if (discountedPrice != null) 'discountedPrice': discountedPrice,
          if (productIds != null) 'productIds': productIds,
        },
      ),
    );
    return SpetoVendorCampaign.fromJson(json);
  }

  Future<SpetoVendorCampaign> updateCampaign({
    required String campaignId,
    SpetoCampaignKind? kind,
    String? title,
    String? description,
    SpetoCampaignStatus? status,
    String? startsAt,
    String? endsAt,
    String? scheduleLabel,
    String? badgeLabel,
    int? discountPercent,
    double? discountedPrice,
    List<String>? productIds,
  }) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.patch(
        'ops/campaigns/${Uri.encodeComponent(campaignId)}',
        body: <String, Object?>{
          if (kind != null) 'kind': _campaignKindApiName(kind),
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (status != null) 'status': _campaignStatusApiName(status),
          if (startsAt != null) 'startsAt': startsAt,
          if (endsAt != null) 'endsAt': endsAt,
          if (scheduleLabel != null) 'scheduleLabel': scheduleLabel,
          if (badgeLabel != null) 'badgeLabel': badgeLabel,
          if (discountPercent != null) 'discountPercent': discountPercent,
          if (discountedPrice != null) 'discountedPrice': discountedPrice,
          if (productIds != null) 'productIds': productIds,
        },
      ),
    );
    return SpetoVendorCampaign.fromJson(json);
  }

  Future<SpetoVendorCampaign> toggleCampaign(String campaignId) async {
    final Map<String, Object?> json = _asJsonMap(
      await _apiClient.post(
        'ops/campaigns/${Uri.encodeComponent(campaignId)}/toggle',
      ),
    );
    return SpetoVendorCampaign.fromJson(json);
  }
}

String _contentBlockTypeApiName(SpetoContentBlockType type) {
  return switch (type) {
    SpetoContentBlockType.homeHero => 'HOME_HERO',
    SpetoContentBlockType.quickFilter => 'QUICK_FILTER',
    SpetoContentBlockType.discoveryFilter => 'DISCOVERY_FILTER',
  };
}

String _storefrontTypeApiName(SpetoStorefrontType type) {
  return switch (type) {
    SpetoStorefrontType.restaurant => 'RESTAURANT',
    SpetoStorefrontType.market => 'MARKET',
  };
}

String _campaignKindApiName(SpetoCampaignKind kind) {
  return switch (kind) {
    SpetoCampaignKind.happyHour => 'HAPPY_HOUR',
    SpetoCampaignKind.discount => 'DISCOUNT',
    SpetoCampaignKind.clearance => 'CLEARANCE',
    SpetoCampaignKind.bundle => 'BUNDLE',
  };
}

String _campaignStatusApiName(SpetoCampaignStatus status) {
  return switch (status) {
    SpetoCampaignStatus.draft => 'DRAFT',
    SpetoCampaignStatus.active => 'ACTIVE',
    SpetoCampaignStatus.paused => 'PAUSED',
    SpetoCampaignStatus.completed => 'COMPLETED',
  };
}

Map<String, Object?> _asJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw const FormatException('Expected JSON object payload from backend');
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson,
) {
  final Object? unwrapped = _unwrapData(value);
  final List<Object?> list = (unwrapped as List<Object?>?) ?? const <Object?>[];
  return list
      .map((Object? item) => fromJson(_asJsonMap(item)))
      .toList(growable: false);
}

List<String> _stringList(Object? value) {
  return ((value as List<Object?>?) ?? const <Object?>[])
      .map((Object? item) => item! as String)
      .toList(growable: false);
}

Map<String, int> _stringIntMap(Object? value) {
  return ((value as Map<Object?, Object?>?) ?? const <Object?, Object?>{})
      .map<String, int>(
        (Object? key, Object? item) =>
            MapEntry<String, int>(key! as String, (item! as num).toInt()),
      );
}

Object? _unwrapData(Object? response) {
  if (response == null) {
    return null;
  }
  if (response is Map<String, Object?>) {
    return response['data'] ?? response;
  }
  if (response is Map) {
    return response['data'] ?? response;
  }
  return response;
}
