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
    return _sessionFromAuthResponse(json);
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
    return _sessionFromAuthResponse(json);
  }

  Future<bool> checkHealth() async {
    try {
      final Map<String, Object?> json = _asJsonMap(
        await _apiClient.get('health'),
      );
      return json['status'] == 'ok';
    } catch (_) {
      return false;
    }
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

  void clearSession() {
    _apiClient.clearAccessToken();
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

  SpetoSession _sessionFromAuthResponse(Map<String, Object?> json) {
    final Map<String, Object?> user = _asJsonMap(json['user']);
    final Map<String, Object?> tokens = _asJsonMap(json['tokens']);
    final String accessToken = tokens['accessToken']! as String;
    _apiClient.setAccessToken(accessToken);
    return SpetoSession(
      email: user['email']! as String,
      displayName: user['displayName']! as String,
      phone: user['phone']! as String? ?? '',
      authToken: accessToken,
      lastLoginIso: DateTime.now().toIso8601String(),
      avatarUrl: user['avatarUrl'] as String? ?? '',
      notificationsEnabled: user['notificationsEnabled'] as bool? ?? true,
      role: _enumByApiName(
        SpetoUserRole.values,
        user['role'] as String?,
        fallback: SpetoUserRole.customer,
      ),
      vendorScopes:
          ((user['vendorScopes'] as List<Object?>?) ?? const <Object?>[])
              .map((Object? item) => item! as String)
              .toList(growable: false),
    );
  }
}

String _normalizeEnumToken(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }
  return value.trim().replaceAll(RegExp(r'[\s_-]+'), '').toLowerCase();
}

T _enumByApiName<T extends Enum>(
  List<T> values,
  String? rawValue, {
  required T fallback,
}) {
  final String normalizedRawValue = _normalizeEnumToken(rawValue);
  for (final T value in values) {
    if (_normalizeEnumToken(value.name) == normalizedRawValue) {
      return value;
    }
  }
  return fallback;
}

String _contentBlockTypeApiName(SpetoContentBlockType type) {
  return switch (type) {
    SpetoContentBlockType.homeHero => 'HOME_HERO',
    SpetoContentBlockType.quickFilter => 'QUICK_FILTER',
    SpetoContentBlockType.discoveryFilter => 'DISCOVERY_FILTER',
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
