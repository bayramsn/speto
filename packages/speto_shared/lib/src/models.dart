enum SpetoUserRole { customer, admin, vendor }

enum SpetoOrderStatus { active, completed, cancelled }

enum SpetoOpsOrderStage {
  created,
  accepted,
  preparing,
  ready,
  completed,
  cancelled,
}

enum SpetoInventoryMovementType {
  sale,
  manualAdjustment,
  restock,
  posSync,
  reservation,
  release,
}

enum SpetoIntegrationType { pos, erp }

enum SpetoIntegrationHealth { healthy, warning, failed }

enum SpetoSyncRunStatus { idle, running, success, failed }

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

class SpetoStockStatus {
  const SpetoStockStatus({
    required this.isInStock,
    required this.availableQuantity,
    required this.lowStock,
    required this.canPurchase,
  });

  final bool isInStock;
  final int availableQuantity;
  final bool lowStock;
  final bool canPurchase;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isInStock': isInStock,
      'availableQuantity': availableQuantity,
      'lowStock': lowStock,
      'canPurchase': canPurchase,
    };
  }

  factory SpetoStockStatus.fromJson(Map<String, Object?> json) {
    return SpetoStockStatus(
      isInStock: json['isInStock'] as bool? ?? false,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      lowStock: json['lowStock'] as bool? ?? false,
      canPurchase: json['canPurchase'] as bool? ?? false,
    );
  }
}

class SpetoCartItem {
  const SpetoCartItem({
    required this.id,
    required this.vendor,
    required this.title,
    required this.image,
    required this.unitPrice,
    this.quantity = 1,
  });

  final String id;
  final String vendor;
  final String title;
  final String image;
  final double unitPrice;
  final int quantity;

  double get totalPrice => unitPrice * quantity;

  SpetoCartItem copyWith({int? quantity}) {
    return SpetoCartItem(
      id: id,
      vendor: vendor,
      title: title,
      image: image,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'vendor': vendor,
      'title': title,
      'image': image,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }

  factory SpetoCartItem.fromJson(Map<String, Object?> json) {
    return SpetoCartItem(
      id: json['id']! as String,
      vendor: json['vendor']! as String,
      title: json['title']! as String,
      image: json['image']! as String,
      unitPrice: (json['unitPrice']! as num).toDouble(),
      quantity: json['quantity']! as int,
    );
  }
}

class SpetoOrder {
  const SpetoOrder({
    required this.id,
    required this.vendor,
    required this.image,
    required this.items,
    required this.placedAtLabel,
    required this.etaLabel,
    required this.status,
    required this.actionLabel,
    this.vendorId = '',
    this.pickupPointId = '',
    this.opsStatus = SpetoOpsOrderStage.created,
    this.pickupCode = 'A2B7',
    this.rewardPoints = 50.0,
    this.deliveryMode = 'Gel-Al',
    this.deliveryAddress = '',
    this.paymentMethod = 'Apple Pay',
    this.promoCode = '',
    this.deliveryFee = 0,
    this.discountAmount = 0,
  });

  final String id;
  final String vendor;
  final String image;
  final List<SpetoCartItem> items;
  final String placedAtLabel;
  final String etaLabel;
  final SpetoOrderStatus status;
  final String actionLabel;
  final String vendorId;
  final String pickupPointId;
  final SpetoOpsOrderStage opsStatus;
  final String pickupCode;
  final double rewardPoints;
  final String deliveryMode;
  final String deliveryAddress;
  final String paymentMethod;
  final String promoCode;
  final double deliveryFee;
  final double discountAmount;

  int get itemCount => items.fold<int>(
    0,
    (int total, SpetoCartItem item) => total + item.quantity,
  );

  double get totalPrice => items.fold<double>(
    0,
    (double total, SpetoCartItem item) => total + item.totalPrice,
  );

  double get payableTotal => totalPrice + deliveryFee - discountAmount;

  SpetoOrder copyWith({
    String? placedAtLabel,
    String? etaLabel,
    SpetoOrderStatus? status,
    String? actionLabel,
    String? vendorId,
    String? pickupPointId,
    SpetoOpsOrderStage? opsStatus,
    String? pickupCode,
    double? rewardPoints,
    String? deliveryMode,
    String? deliveryAddress,
    String? paymentMethod,
    String? promoCode,
    double? deliveryFee,
    double? discountAmount,
  }) {
    return SpetoOrder(
      id: id,
      vendor: vendor,
      image: image,
      items: items.map((SpetoCartItem item) => item.copyWith()).toList(),
      placedAtLabel: placedAtLabel ?? this.placedAtLabel,
      etaLabel: etaLabel ?? this.etaLabel,
      status: status ?? this.status,
      actionLabel: actionLabel ?? this.actionLabel,
      vendorId: vendorId ?? this.vendorId,
      pickupPointId: pickupPointId ?? this.pickupPointId,
      opsStatus: opsStatus ?? this.opsStatus,
      pickupCode: pickupCode ?? this.pickupCode,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoCode: promoCode ?? this.promoCode,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'vendor': vendor,
      'image': image,
      'items': items.map((SpetoCartItem item) => item.toJson()).toList(),
      'placedAtLabel': placedAtLabel,
      'etaLabel': etaLabel,
      'status': status.name,
      'actionLabel': actionLabel,
      'vendorId': vendorId,
      'pickupPointId': pickupPointId,
      'opsStatus': opsStatus.name,
      'pickupCode': pickupCode,
      'rewardPoints': rewardPoints,
      'deliveryMode': deliveryMode,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'promoCode': promoCode,
      'deliveryFee': deliveryFee,
      'discountAmount': discountAmount,
    };
  }

  factory SpetoOrder.fromJson(Map<String, Object?> json) {
    return SpetoOrder(
      id: json['id']! as String,
      vendor: json['vendor']! as String,
      image: json['image']! as String,
      items: (json['items']! as List<Object?>)
          .map(
            (Object? item) =>
                SpetoCartItem.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
      placedAtLabel: json['placedAtLabel']! as String,
      etaLabel: json['etaLabel']! as String,
      status: _enumByApiName(
        SpetoOrderStatus.values,
        json['status'] as String?,
        fallback: SpetoOrderStatus.active,
      ),
      actionLabel: json['actionLabel']! as String,
      vendorId: json['vendorId'] as String? ?? '',
      pickupPointId: json['pickupPointId'] as String? ?? '',
      opsStatus: _enumByApiName(
        SpetoOpsOrderStage.values,
        json['opsStatus'] as String?,
        fallback: SpetoOpsOrderStage.created,
      ),
      pickupCode: json['pickupCode']! as String,
      rewardPoints: (json['rewardPoints'] as num?)?.toDouble() ?? 0,
      deliveryMode: json['deliveryMode'] as String? ?? 'Gel-Al',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'Apple Pay',
      promoCode: json['promoCode'] as String? ?? '',
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

typedef SpetoOpsOrder = SpetoOrder;

class SpetoEventTicket {
  const SpetoEventTicket({
    required this.id,
    required this.title,
    required this.venue,
    required this.dateLabel,
    required this.timeLabel,
    required this.zone,
    required this.seat,
    required this.gate,
    required this.code,
    required this.image,
    required this.pointsCost,
  });

  final String id;
  final String title;
  final String venue;
  final String dateLabel;
  final String timeLabel;
  final String zone;
  final String seat;
  final String gate;
  final String code;
  final String image;
  final int pointsCost;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'venue': venue,
      'dateLabel': dateLabel,
      'timeLabel': timeLabel,
      'zone': zone,
      'seat': seat,
      'gate': gate,
      'code': code,
      'image': image,
      'pointsCost': pointsCost,
    };
  }

  factory SpetoEventTicket.fromJson(Map<String, Object?> json) {
    return SpetoEventTicket(
      id: json['id']! as String,
      title: json['title']! as String,
      venue: json['venue']! as String,
      dateLabel: json['dateLabel']! as String,
      timeLabel: json['timeLabel']! as String,
      zone: json['zone']! as String,
      seat: json['seat']! as String,
      gate: json['gate']! as String,
      code: json['code']! as String,
      image: json['image']! as String,
      pointsCost: json['pointsCost']! as int,
    );
  }
}

class SpetoAddress {
  const SpetoAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.iconKey,
    this.isPrimary = false,
  });

  final String id;
  final String label;
  final String address;
  final String iconKey;
  final bool isPrimary;

  SpetoAddress copyWith({
    String? label,
    String? address,
    String? iconKey,
    bool? isPrimary,
  }) {
    return SpetoAddress(
      id: id,
      label: label ?? this.label,
      address: address ?? this.address,
      iconKey: iconKey ?? this.iconKey,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'address': address,
      'iconKey': iconKey,
      'isPrimary': isPrimary,
    };
  }

  factory SpetoAddress.fromJson(Map<String, Object?> json) {
    return SpetoAddress(
      id: json['id']! as String,
      label: json['label']! as String,
      address: json['address']! as String,
      iconKey: json['iconKey'] as String? ?? 'location',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class SpetoPaymentCard {
  const SpetoPaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.holderName,
    this.isDefault = false,
  });

  final String id;
  final String brand;
  final String last4;
  final String expiry;
  final String holderName;
  final bool isDefault;

  SpetoPaymentCard copyWith({
    String? brand,
    String? last4,
    String? expiry,
    String? holderName,
    bool? isDefault,
  }) {
    return SpetoPaymentCard(
      id: id,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiry: expiry ?? this.expiry,
      holderName: holderName ?? this.holderName,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'brand': brand,
      'last4': last4,
      'expiry': expiry,
      'holderName': holderName,
      'isDefault': isDefault,
    };
  }

  factory SpetoPaymentCard.fromJson(Map<String, Object?> json) {
    return SpetoPaymentCard(
      id: json['id']! as String,
      brand: json['brand']! as String,
      last4: json['last4']! as String,
      expiry: json['expiry']! as String,
      holderName: json['holderName'] as String? ?? 'Kart Sahibi',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class SpetoSupportTicket {
  const SpetoSupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.channel,
    required this.createdAtLabel,
    this.status = 'Açık',
  });

  final String id;
  final String subject;
  final String message;
  final String channel;
  final String createdAtLabel;
  final String status;

  SpetoSupportTicket copyWith({
    String? subject,
    String? message,
    String? channel,
    String? createdAtLabel,
    String? status,
  }) {
    return SpetoSupportTicket(
      id: id,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      channel: channel ?? this.channel,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'subject': subject,
      'message': message,
      'channel': channel,
      'createdAtLabel': createdAtLabel,
      'status': status,
    };
  }

  factory SpetoSupportTicket.fromJson(Map<String, Object?> json) {
    return SpetoSupportTicket(
      id: json['id']! as String,
      subject: json['subject']! as String,
      message: json['message']! as String,
      channel: json['channel']! as String,
      createdAtLabel: json['createdAtLabel']! as String,
      status: json['status'] as String? ?? 'Açık',
    );
  }
}

class SpetoSession {
  const SpetoSession({
    required this.email,
    required this.displayName,
    required this.phone,
    required this.authToken,
    required this.lastLoginIso,
    this.avatarUrl = '',
    this.notificationsEnabled = true,
    this.role = SpetoUserRole.customer,
    this.vendorScopes = const <String>[],
  });

  final String email;
  final String displayName;
  final String phone;
  final String authToken;
  final String lastLoginIso;
  final String avatarUrl;
  final bool notificationsEnabled;
  final SpetoUserRole role;
  final List<String> vendorScopes;

  SpetoSession copyWith({
    String? email,
    String? displayName,
    String? phone,
    String? authToken,
    String? lastLoginIso,
    String? avatarUrl,
    bool? notificationsEnabled,
    SpetoUserRole? role,
    List<String>? vendorScopes,
  }) {
    return SpetoSession(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      authToken: authToken ?? this.authToken,
      lastLoginIso: lastLoginIso ?? this.lastLoginIso,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      role: role ?? this.role,
      vendorScopes: vendorScopes ?? this.vendorScopes,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'authToken': authToken,
      'lastLoginIso': lastLoginIso,
      'avatarUrl': avatarUrl,
      'notificationsEnabled': notificationsEnabled,
      'role': role.name,
      'vendorScopes': vendorScopes,
    };
  }

  factory SpetoSession.fromJson(Map<String, Object?> json) {
    return SpetoSession(
      email: json['email']! as String,
      displayName: json['displayName']! as String,
      phone: json['phone']! as String,
      authToken: json['authToken']! as String,
      lastLoginIso: json['lastLoginIso']! as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      role: _enumByApiName(
        SpetoUserRole.values,
        json['role'] as String?,
        fallback: SpetoUserRole.customer,
      ),
      vendorScopes: ((json['vendorScopes'] as List<Object?>?) ??
              const <Object?>[])
          .map((Object? item) => item! as String)
          .toList(growable: false),
    );
  }
}

class SpetoRegistrationDraft {
  const SpetoRegistrationDraft({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }

  factory SpetoRegistrationDraft.fromJson(Map<String, Object?> json) {
    return SpetoRegistrationDraft(
      fullName: json['fullName']! as String,
      email: json['email']! as String,
      phone: json['phone']! as String,
      password: json['password']! as String,
    );
  }
}

class SpetoCommerceSnapshot {
  const SpetoCommerceSnapshot({
    required this.cartItems,
    required this.activeOrders,
    required this.historyOrders,
    required this.selectedOrderId,
    required this.proPointsBalance,
    required this.ownedTickets,
    required this.selectedTicketId,
    required this.addresses,
    required this.paymentCards,
    required this.supportTickets,
    required this.favoriteRestaurantIds,
    required this.favoriteEventIds,
    required this.followedOrganizerIds,
    required this.orderRatings,
    required this.profileDisplayName,
    required this.profilePhone,
    required this.profileAvatarUrl,
    required this.profileNotificationsEnabled,
  });

  final List<SpetoCartItem> cartItems;
  final List<SpetoOrder> activeOrders;
  final List<SpetoOrder> historyOrders;
  final String? selectedOrderId;
  final double proPointsBalance;
  final List<SpetoEventTicket> ownedTickets;
  final String? selectedTicketId;
  final List<SpetoAddress> addresses;
  final List<SpetoPaymentCard> paymentCards;
  final List<SpetoSupportTicket> supportTickets;
  final List<String> favoriteRestaurantIds;
  final List<String> favoriteEventIds;
  final List<String> followedOrganizerIds;
  final Map<String, int> orderRatings;
  final String profileDisplayName;
  final String profilePhone;
  final String profileAvatarUrl;
  final bool profileNotificationsEnabled;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'cartItems': cartItems
          .map((SpetoCartItem item) => item.toJson())
          .toList(),
      'activeOrders': activeOrders
          .map((SpetoOrder order) => order.toJson())
          .toList(),
      'historyOrders': historyOrders
          .map((SpetoOrder order) => order.toJson())
          .toList(),
      'selectedOrderId': selectedOrderId,
      'proPointsBalance': proPointsBalance,
      'ownedTickets': ownedTickets
          .map((SpetoEventTicket ticket) => ticket.toJson())
          .toList(),
      'selectedTicketId': selectedTicketId,
      'addresses': addresses
          .map((SpetoAddress address) => address.toJson())
          .toList(),
      'paymentCards': paymentCards
          .map((SpetoPaymentCard card) => card.toJson())
          .toList(),
      'supportTickets': supportTickets
          .map((SpetoSupportTicket ticket) => ticket.toJson())
          .toList(),
      'favoriteRestaurantIds': favoriteRestaurantIds,
      'favoriteEventIds': favoriteEventIds,
      'followedOrganizerIds': followedOrganizerIds,
      'orderRatings': orderRatings,
      'profileDisplayName': profileDisplayName,
      'profilePhone': profilePhone,
      'profileAvatarUrl': profileAvatarUrl,
      'profileNotificationsEnabled': profileNotificationsEnabled,
    };
  }

  factory SpetoCommerceSnapshot.fromJson(Map<String, Object?> json) {
    return SpetoCommerceSnapshot(
      cartItems: ((json['cartItems'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoCartItem.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
      activeOrders:
          ((json['activeOrders'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoOrder.fromJson(item! as Map<String, Object?>),
              )
              .toList(),
      historyOrders:
          ((json['historyOrders'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoOrder.fromJson(item! as Map<String, Object?>),
              )
              .toList(),
      selectedOrderId: json['selectedOrderId'] as String?,
      proPointsBalance: (json['proPointsBalance'] as num?)?.toDouble() ?? 0,
      ownedTickets:
          ((json['ownedTickets'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoEventTicket.fromJson(item! as Map<String, Object?>),
              )
              .toList(),
      selectedTicketId: json['selectedTicketId'] as String?,
      addresses: ((json['addresses'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoAddress.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
      paymentCards:
          ((json['paymentCards'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoPaymentCard.fromJson(item! as Map<String, Object?>),
              )
              .toList(),
      supportTickets:
          ((json['supportTickets'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoSupportTicket.fromJson(item! as Map<String, Object?>),
              )
              .toList(),
      favoriteRestaurantIds:
          ((json['favoriteRestaurantIds'] as List<Object?>?) ??
                  const <Object?>[])
              .map((Object? item) => item! as String)
              .toList(),
      favoriteEventIds:
          ((json['favoriteEventIds'] as List<Object?>?) ?? const <Object?>[])
              .map((Object? item) => item! as String)
              .toList(),
      followedOrganizerIds:
          ((json['followedOrganizerIds'] as List<Object?>?) ??
                  const <Object?>[])
              .map((Object? item) => item! as String)
              .toList(),
      orderRatings:
          ((json['orderRatings'] as Map<Object?, Object?>?) ??
                  const <Object?, Object?>{})
              .map<String, int>(
                (Object? key, Object? value) => MapEntry<String, int>(
                  key! as String,
                  (value! as num).toInt(),
                ),
              ),
      profileDisplayName: json['profileDisplayName'] as String? ?? '',
      profilePhone: json['profilePhone'] as String? ?? '',
      profileAvatarUrl: json['profileAvatarUrl'] as String? ?? '',
      profileNotificationsEnabled:
          json['profileNotificationsEnabled'] as bool? ?? true,
    );
  }
}

class SpetoRemoteSnapshot {
  const SpetoRemoteSnapshot({
    required this.profile,
    required this.addresses,
    required this.paymentCards,
    required this.activeOrders,
    required this.historyOrders,
    required this.supportTickets,
    required this.ownedTickets,
    required this.proPointsBalance,
  });

  final SpetoRemoteUserProfile profile;
  final List<SpetoAddress> addresses;
  final List<SpetoPaymentCard> paymentCards;
  final List<SpetoOrder> activeOrders;
  final List<SpetoOrder> historyOrders;
  final List<SpetoSupportTicket> supportTickets;
  final List<SpetoEventTicket> ownedTickets;
  final double proPointsBalance;
}

class SpetoRemoteUserProfile {
  const SpetoRemoteUserProfile({
    required this.email,
    required this.displayName,
    required this.phone,
    required this.avatarUrl,
    required this.notificationsEnabled,
  });

  final String email;
  final String displayName;
  final String phone;
  final String avatarUrl;
  final bool notificationsEnabled;

  factory SpetoRemoteUserProfile.fromJson(Map<String, Object?> json) {
    return SpetoRemoteUserProfile(
      email: json['email']! as String,
      displayName: json['displayName']! as String,
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }
}

class SpetoInventoryItem {
  const SpetoInventoryItem({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.unitPrice,
    required this.sku,
    required this.barcode,
    required this.locationId,
    required this.locationLabel,
    required this.trackStock,
    required this.reorderLevel,
    required this.isArchived,
    required this.onHand,
    required this.reserved,
    required this.stockStatus,
    this.externalCode = '',
  });

  final String id;
  final String vendorId;
  final String vendorName;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final double unitPrice;
  final String sku;
  final String barcode;
  final String locationId;
  final String locationLabel;
  final bool trackStock;
  final int reorderLevel;
  final bool isArchived;
  final int onHand;
  final int reserved;
  final SpetoStockStatus stockStatus;
  final String externalCode;

  int get availableQuantity => stockStatus.availableQuantity;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'unitPrice': unitPrice,
      'sku': sku,
      'barcode': barcode,
      'locationId': locationId,
      'locationLabel': locationLabel,
      'trackStock': trackStock,
      'reorderLevel': reorderLevel,
      'isArchived': isArchived,
      'onHand': onHand,
      'reserved': reserved,
      'stockStatus': stockStatus.toJson(),
      'externalCode': externalCode,
    };
  }

  factory SpetoInventoryItem.fromJson(Map<String, Object?> json) {
    return SpetoInventoryItem(
      id: json['id']! as String,
      vendorId: json['vendorId']! as String,
      vendorName: json['vendorName']! as String,
      title: json['title']! as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      locationId: json['locationId'] as String? ?? '',
      locationLabel: json['locationLabel'] as String? ?? '',
      trackStock: json['trackStock'] as bool? ?? true,
      reorderLevel: (json['reorderLevel'] as num?)?.toInt() ?? 0,
      isArchived: json['isArchived'] as bool? ?? false,
      onHand: (json['onHand'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      stockStatus: SpetoStockStatus.fromJson(
        _asJsonMap(json['stockStatus']),
      ),
      externalCode: json['externalCode'] as String? ?? '',
    );
  }
}

class SpetoInventoryMovement {
  const SpetoInventoryMovement({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.vendorId,
    required this.vendorName,
    required this.type,
    required this.quantityDelta,
    required this.previousOnHand,
    required this.nextOnHand,
    required this.previousReserved,
    required this.nextReserved,
    required this.createdAtLabel,
    this.note = '',
    this.orderId = '',
  });

  final String id;
  final String productId;
  final String productTitle;
  final String vendorId;
  final String vendorName;
  final SpetoInventoryMovementType type;
  final int quantityDelta;
  final int previousOnHand;
  final int nextOnHand;
  final int previousReserved;
  final int nextReserved;
  final String createdAtLabel;
  final String note;
  final String orderId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'type': type.name,
      'quantityDelta': quantityDelta,
      'previousOnHand': previousOnHand,
      'nextOnHand': nextOnHand,
      'previousReserved': previousReserved,
      'nextReserved': nextReserved,
      'createdAtLabel': createdAtLabel,
      'note': note,
      'orderId': orderId,
    };
  }

  factory SpetoInventoryMovement.fromJson(Map<String, Object?> json) {
    return SpetoInventoryMovement(
      id: json['id']! as String,
      productId: json['productId']! as String,
      productTitle: json['productTitle']! as String,
      vendorId: json['vendorId']! as String,
      vendorName: json['vendorName']! as String,
      type: _enumByApiName(
        SpetoInventoryMovementType.values,
        json['type'] as String?,
        fallback: SpetoInventoryMovementType.manualAdjustment,
      ),
      quantityDelta: (json['quantityDelta'] as num?)?.toInt() ?? 0,
      previousOnHand: (json['previousOnHand'] as num?)?.toInt() ?? 0,
      nextOnHand: (json['nextOnHand'] as num?)?.toInt() ?? 0,
      previousReserved: (json['previousReserved'] as num?)?.toInt() ?? 0,
      nextReserved: (json['nextReserved'] as num?)?.toInt() ?? 0,
      createdAtLabel: json['createdAtLabel']! as String,
      note: json['note'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
    );
  }
}

class SpetoInventorySnapshot {
  const SpetoInventorySnapshot({
    required this.items,
    required this.totalItems,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.openOrdersCount,
    required this.integrationErrorCount,
    required this.pendingSyncCount,
    required this.totalAvailableUnits,
  });

  final List<SpetoInventoryItem> items;
  final int totalItems;
  final int lowStockCount;
  final int outOfStockCount;
  final int openOrdersCount;
  final int integrationErrorCount;
  final int pendingSyncCount;
  final int totalAvailableUnits;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'items': items.map((SpetoInventoryItem item) => item.toJson()).toList(),
      'totalItems': totalItems,
      'lowStockCount': lowStockCount,
      'outOfStockCount': outOfStockCount,
      'openOrdersCount': openOrdersCount,
      'integrationErrorCount': integrationErrorCount,
      'pendingSyncCount': pendingSyncCount,
      'totalAvailableUnits': totalAvailableUnits,
    };
  }

  factory SpetoInventorySnapshot.fromJson(Map<String, Object?> json) {
    return SpetoInventorySnapshot(
      items: ((json['items'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoInventoryItem.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (json['outOfStockCount'] as num?)?.toInt() ?? 0,
      openOrdersCount: (json['openOrdersCount'] as num?)?.toInt() ?? 0,
      integrationErrorCount:
          (json['integrationErrorCount'] as num?)?.toInt() ?? 0,
      pendingSyncCount: (json['pendingSyncCount'] as num?)?.toInt() ?? 0,
      totalAvailableUnits: (json['totalAvailableUnits'] as num?)?.toInt() ?? 0,
    );
  }
}

class SpetoIntegrationSyncStatus {
  const SpetoIntegrationSyncStatus({
    required this.connectionId,
    required this.status,
    required this.startedAtLabel,
    required this.completedAtLabel,
    required this.processedCount,
    this.errorMessage = '',
  });

  final String connectionId;
  final SpetoSyncRunStatus status;
  final String startedAtLabel;
  final String completedAtLabel;
  final int processedCount;
  final String errorMessage;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'connectionId': connectionId,
      'status': status.name,
      'startedAtLabel': startedAtLabel,
      'completedAtLabel': completedAtLabel,
      'processedCount': processedCount,
      'errorMessage': errorMessage,
    };
  }

  factory SpetoIntegrationSyncStatus.fromJson(Map<String, Object?> json) {
    return SpetoIntegrationSyncStatus(
      connectionId: json['connectionId']! as String,
      status: _enumByApiName(
        SpetoSyncRunStatus.values,
        json['status'] as String?,
        fallback: SpetoSyncRunStatus.idle,
      ),
      startedAtLabel: json['startedAtLabel'] as String? ?? '',
      completedAtLabel: json['completedAtLabel'] as String? ?? '',
      processedCount: (json['processedCount'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String? ?? '',
    );
  }
}

class SpetoIntegrationConnection {
  const SpetoIntegrationConnection({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.name,
    required this.provider,
    required this.type,
    required this.baseUrl,
    required this.locationId,
    required this.health,
    required this.lastSync,
    required this.skuMappings,
  });

  final String id;
  final String vendorId;
  final String vendorName;
  final String name;
  final String provider;
  final SpetoIntegrationType type;
  final String baseUrl;
  final String locationId;
  final SpetoIntegrationHealth health;
  final SpetoIntegrationSyncStatus lastSync;
  final Map<String, String> skuMappings;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'name': name,
      'provider': provider,
      'type': type.name,
      'baseUrl': baseUrl,
      'locationId': locationId,
      'health': health.name,
      'lastSync': lastSync.toJson(),
      'skuMappings': skuMappings,
    };
  }

  factory SpetoIntegrationConnection.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> skuMappingsJson = _asJsonMap(
      json['skuMappings'] ?? const <String, Object?>{},
    );
    return SpetoIntegrationConnection(
      id: json['id']! as String,
      vendorId: json['vendorId']! as String,
      vendorName: json['vendorName']! as String,
      name: json['name']! as String,
      provider: json['provider']! as String,
      type: _enumByApiName(
        SpetoIntegrationType.values,
        json['type'] as String?,
        fallback: SpetoIntegrationType.erp,
      ),
      baseUrl: json['baseUrl'] as String? ?? '',
      locationId: json['locationId'] as String? ?? '',
      health: _enumByApiName(
        SpetoIntegrationHealth.values,
        json['health'] as String?,
        fallback: SpetoIntegrationHealth.healthy,
      ),
      lastSync: SpetoIntegrationSyncStatus.fromJson(
        _asJsonMap(json['lastSync']),
      ),
      skuMappings: skuMappingsJson.map<String, String>(
        (String key, Object? value) =>
            MapEntry<String, String>(key, value?.toString() ?? ''),
      ),
    );
  }
}

Map<String, Object?> _asJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw const FormatException('Expected JSON object payload');
}
