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

enum SpetoStorefrontType { restaurant, market }

enum SpetoPayoutStatus { pending, paid, failed }

enum SpetoCampaignKind { happyHour, discount, clearance, bundle }

enum SpetoCampaignStatus { draft, active, paused, completed }

enum SpetoContentBlockType { homeHero, quickFilter, discoveryFilter }

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

class SpetoCatalogBootstrap {
  const SpetoCatalogBootstrap({
    required this.contentVersion,
    required this.home,
    required this.restaurants,
    required this.markets,
    required this.events,
    required this.featuredRestaurants,
    required this.featuredEvents,
  });

  final String contentVersion;
  final SpetoCatalogHomeContent home;
  final List<SpetoCatalogVendor> restaurants;
  final List<SpetoCatalogVendor> markets;
  final List<SpetoCatalogEvent> events;
  final List<SpetoCatalogVendor> featuredRestaurants;
  final List<SpetoCatalogEvent> featuredEvents;

  factory SpetoCatalogBootstrap.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> featured =
        (json['featured'] as Map<Object?, Object?>? ??
                const <Object?, Object?>{})
            .cast<String, Object?>();
    return SpetoCatalogBootstrap(
      contentVersion: json['contentVersion'] as String? ?? '',
      home: SpetoCatalogHomeContent.fromJson(
        (json['home'] as Map<Object?, Object?>? ?? const <Object?, Object?>{})
            .cast<String, Object?>(),
      ),
      restaurants:
          ((json['restaurants'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoCatalogVendor.fromJson(item! as Map<String, Object?>),
              )
              .toList(growable: false),
      markets: ((json['markets'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoCatalogVendor.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
      events: ((json['events'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoCatalogEvent.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
      featuredRestaurants:
          ((featured['restaurants'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoCatalogVendor.fromJson(item! as Map<String, Object?>),
              )
              .toList(growable: false),
      featuredEvents:
          ((featured['events'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) =>
                    SpetoCatalogEvent.fromJson(item! as Map<String, Object?>),
              )
              .toList(growable: false),
    );
  }
}

class SpetoCatalogHomeContent {
  const SpetoCatalogHomeContent({
    required this.heroes,
    required this.quickFilters,
    required this.discoveryFilters,
  });

  final List<SpetoCatalogContentBlock> heroes;
  final List<SpetoCatalogContentBlock> quickFilters;
  final List<SpetoCatalogContentBlock> discoveryFilters;

  factory SpetoCatalogHomeContent.fromJson(Map<String, Object?> json) {
    return SpetoCatalogHomeContent(
      heroes: ((json['heroes'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) => SpetoCatalogContentBlock.fromJson(
              item! as Map<String, Object?>,
            ),
          )
          .toList(growable: false),
      quickFilters:
          ((json['quickFilters'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) => SpetoCatalogContentBlock.fromJson(
                  item! as Map<String, Object?>,
                ),
              )
              .toList(growable: false),
      discoveryFilters:
          ((json['discoveryFilters'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) => SpetoCatalogContentBlock.fromJson(
                  item! as Map<String, Object?>,
                ),
              )
              .toList(growable: false),
    );
  }
}

class SpetoCatalogContentBlock {
  const SpetoCatalogContentBlock({
    required this.id,
    required this.type,
    required this.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imageUrl,
    required this.actionLabel,
    required this.screen,
    required this.iconKey,
    required this.highlight,
    required this.displayOrder,
    required this.isActive,
    required this.payload,
  });

  final String id;
  final SpetoContentBlockType type;
  final String key;
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  final String actionLabel;
  final String screen;
  final String iconKey;
  final bool highlight;
  final int displayOrder;
  final bool isActive;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'key': key,
      'title': title,
      'subtitle': subtitle,
      'badge': badge,
      'imageUrl': imageUrl,
      'actionLabel': actionLabel,
      'screen': screen,
      'iconKey': iconKey,
      'highlight': highlight,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'payload': payload,
    };
  }

  factory SpetoCatalogContentBlock.fromJson(Map<String, Object?> json) {
    return SpetoCatalogContentBlock(
      id: json['id'] as String? ?? '',
      type: _enumByApiName(
        SpetoContentBlockType.values,
        json['type'] as String?,
        fallback: SpetoContentBlockType.homeHero,
      ),
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      actionLabel: json['actionLabel'] as String? ?? '',
      screen: json['screen'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
      highlight: json['highlight'] as bool? ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      payload:
          (json['payload'] as Map<Object?, Object?>? ??
                  const <Object?, Object?>{})
              .cast<String, Object?>(),
    );
  }
}

class SpetoHappyHourOffer {
  const SpetoHappyHourOffer({
    required this.id,
    required this.productId,
    required this.vendorId,
    required this.vendorName,
    required this.vendorSubtitle,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.badge,
    required this.discountedPrice,
    required this.discountedPriceText,
    required this.originalPrice,
    required this.originalPriceText,
    required this.discountPercent,
    required this.expiresInMinutes,
    required this.rewardPoints,
    required this.claimCount,
    required this.locationTitle,
    required this.locationSubtitle,
    required this.sectionLabel,
    required this.stockStatus,
  });

  final String id;
  final String productId;
  final String vendorId;
  final String vendorName;
  final String vendorSubtitle;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final String badge;
  final double discountedPrice;
  final String discountedPriceText;
  final double originalPrice;
  final String originalPriceText;
  final int discountPercent;
  final int expiresInMinutes;
  final int rewardPoints;
  final int claimCount;
  final String locationTitle;
  final String locationSubtitle;
  final String sectionLabel;
  final SpetoStockStatus stockStatus;

  factory SpetoHappyHourOffer.fromJson(Map<String, Object?> json) {
    return SpetoHappyHourOffer(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      vendorName: json['vendorName'] as String? ?? '',
      vendorSubtitle: json['vendorSubtitle'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble() ?? 0,
      discountedPriceText: json['discountedPriceText'] as String? ?? '',
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
      originalPriceText: json['originalPriceText'] as String? ?? '',
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      expiresInMinutes: (json['expiresInMinutes'] as num?)?.toInt() ?? 0,
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      claimCount: (json['claimCount'] as num?)?.toInt() ?? 0,
      locationTitle: json['locationTitle'] as String? ?? '',
      locationSubtitle: json['locationSubtitle'] as String? ?? '',
      sectionLabel: json['sectionLabel'] as String? ?? '',
      stockStatus: SpetoStockStatus.fromJson(
        (json['stockStatus'] as Map<Object?, Object?>? ??
                const <Object?, Object?>{})
            .cast<String, Object?>(),
      ),
    );
  }
}

class SpetoCatalogPickupPoint {
  const SpetoCatalogPickupPoint({
    required this.id,
    required this.label,
    required this.address,
  });

  final String id;
  final String label;
  final String address;

  factory SpetoCatalogPickupPoint.fromJson(Map<String, Object?> json) {
    return SpetoCatalogPickupPoint(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

class SpetoCatalogVendorHighlight {
  const SpetoCatalogVendorHighlight({
    required this.id,
    required this.label,
    required this.icon,
    required this.displayOrder,
  });

  final String id;
  final String label;
  final String icon;
  final int displayOrder;

  factory SpetoCatalogVendorHighlight.fromJson(Map<String, Object?> json) {
    return SpetoCatalogVendorHighlight(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class SpetoCatalogOperatorAccount {
  const SpetoCatalogOperatorAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phone,
  });

  final String id;
  final String email;
  final String displayName;
  final String phone;

  factory SpetoCatalogOperatorAccount.fromJson(Map<String, Object?> json) {
    return SpetoCatalogOperatorAccount(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class SpetoCatalogVendor {
  const SpetoCatalogVendor({
    required this.id,
    required this.vendorId,
    required this.storefrontType,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.image,
    required this.badge,
    required this.rewardLabel,
    required this.ratingLabel,
    required this.distanceLabel,
    required this.etaLabel,
    required this.promoLabel,
    required this.workingHoursLabel,
    required this.minOrderLabel,
    required this.deliveryWindowLabel,
    required this.reviewCountLabel,
    required this.announcement,
    required this.bundleTitle,
    required this.bundleDescription,
    required this.bundlePrice,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.cuisine,
    required this.etaMin,
    required this.etaMax,
    required this.ratingValue,
    required this.promo,
    required this.studentFriendly,
    required this.isFeatured,
    required this.isActive,
    required this.pickupPoints,
    required this.highlights,
    required this.operatorAccounts,
    required this.sections,
    required this.stockStatus,
  });

  final String id;
  final String vendorId;
  final SpetoStorefrontType storefrontType;
  final String title;
  final String subtitle;
  final String meta;
  final String image;
  final String badge;
  final String rewardLabel;
  final String ratingLabel;
  final String distanceLabel;
  final String etaLabel;
  final String promoLabel;
  final String workingHoursLabel;
  final String minOrderLabel;
  final String deliveryWindowLabel;
  final String reviewCountLabel;
  final String announcement;
  final String bundleTitle;
  final String bundleDescription;
  final String bundlePrice;
  final String heroTitle;
  final String heroSubtitle;
  final String cuisine;
  final int etaMin;
  final int etaMax;
  final double ratingValue;
  final String promo;
  final bool studentFriendly;
  final bool isFeatured;
  final bool isActive;
  final List<SpetoCatalogPickupPoint> pickupPoints;
  final List<SpetoCatalogVendorHighlight> highlights;
  final List<SpetoCatalogOperatorAccount> operatorAccounts;
  final List<SpetoCatalogSection> sections;
  final SpetoStockStatus stockStatus;

  factory SpetoCatalogVendor.fromJson(Map<String, Object?> json) {
    return SpetoCatalogVendor(
      id: json['id'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      storefrontType: _enumByApiName(
        SpetoStorefrontType.values,
        json['storefrontType'] as String?,
        fallback: SpetoStorefrontType.restaurant,
      ),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      meta: json['meta'] as String? ?? '',
      image: json['image'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      rewardLabel: json['rewardLabel'] as String? ?? '',
      ratingLabel: json['ratingLabel'] as String? ?? '',
      distanceLabel: json['distanceLabel'] as String? ?? '',
      etaLabel: json['etaLabel'] as String? ?? '',
      promoLabel: json['promoLabel'] as String? ?? '',
      workingHoursLabel: json['workingHoursLabel'] as String? ?? '',
      minOrderLabel: json['minOrderLabel'] as String? ?? '',
      deliveryWindowLabel: json['deliveryWindowLabel'] as String? ?? '',
      reviewCountLabel: json['reviewCountLabel'] as String? ?? '',
      announcement: json['announcement'] as String? ?? '',
      bundleTitle: json['bundleTitle'] as String? ?? '',
      bundleDescription: json['bundleDescription'] as String? ?? '',
      bundlePrice: json['bundlePrice'] as String? ?? '',
      heroTitle: json['heroTitle'] as String? ?? '',
      heroSubtitle: json['heroSubtitle'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      etaMin: (json['etaMin'] as num?)?.toInt() ?? 0,
      etaMax: (json['etaMax'] as num?)?.toInt() ?? 0,
      ratingValue: (json['ratingValue'] as num?)?.toDouble() ?? 0,
      promo: json['promo'] as String? ?? '',
      studentFriendly: json['studentFriendly'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      pickupPoints:
          ((json['pickupPoints'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) => SpetoCatalogPickupPoint.fromJson(
                  item! as Map<String, Object?>,
                ),
              )
              .toList(growable: false),
      highlights: ((json['highlights'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) => SpetoCatalogVendorHighlight.fromJson(
              item! as Map<String, Object?>,
            ),
          )
          .toList(growable: false),
      operatorAccounts:
          ((json['operatorAccounts'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) => SpetoCatalogOperatorAccount.fromJson(
                  item! as Map<String, Object?>,
                ),
              )
              .toList(growable: false),
      sections: ((json['sections'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoCatalogSection.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
      stockStatus: SpetoStockStatus.fromJson(
        (json['stockStatus'] as Map<Object?, Object?>? ??
                const <Object?, Object?>{})
            .cast<String, Object?>(),
      ),
    );
  }
}

class SpetoCatalogSection {
  const SpetoCatalogSection({
    required this.id,
    required this.key,
    required this.label,
    required this.displayOrder,
    required this.isActive,
    required this.products,
  });

  final String id;
  final String key;
  final String label;
  final int displayOrder;
  final bool isActive;
  final List<SpetoCatalogProduct> products;

  factory SpetoCatalogSection.fromJson(Map<String, Object?> json) {
    return SpetoCatalogSection(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      products: ((json['products'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoCatalogProduct.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
    );
  }
}

class SpetoCatalogProduct {
  const SpetoCatalogProduct({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.sectionId,
    required this.sectionLabel,
    required this.title,
    required this.description,
    required this.image,
    required this.imageUrl,
    required this.unitPrice,
    required this.priceText,
    required this.category,
    required this.sku,
    required this.barcode,
    required this.externalCode,
    required this.displaySubtitle,
    required this.displayBadge,
    required this.displayOrder,
    required this.isFeatured,
    required this.isVisibleInApp,
    required this.trackStock,
    required this.reorderLevel,
    required this.isArchived,
    required this.stockStatus,
    required this.searchKeywords,
    required this.legacyAliases,
  });

  final String id;
  final String vendorId;
  final String vendorName;
  final String sectionId;
  final String sectionLabel;
  final String title;
  final String description;
  final String image;
  final String imageUrl;
  final double unitPrice;
  final String priceText;
  final String category;
  final String sku;
  final String barcode;
  final String externalCode;
  final String displaySubtitle;
  final String displayBadge;
  final int displayOrder;
  final bool isFeatured;
  final bool isVisibleInApp;
  final bool trackStock;
  final int reorderLevel;
  final bool isArchived;
  final SpetoStockStatus stockStatus;
  final List<String> searchKeywords;
  final List<String> legacyAliases;

  factory SpetoCatalogProduct.fromJson(Map<String, Object?> json) {
    return SpetoCatalogProduct(
      id: json['id'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      vendorName: json['vendorName'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      sectionLabel: json['sectionLabel'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      priceText: json['priceText'] as String? ?? '',
      category: json['category'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      externalCode: json['externalCode'] as String? ?? '',
      displaySubtitle: json['displaySubtitle'] as String? ?? '',
      displayBadge: json['displayBadge'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isVisibleInApp: json['isVisibleInApp'] as bool? ?? true,
      trackStock: json['trackStock'] as bool? ?? true,
      reorderLevel: (json['reorderLevel'] as num?)?.toInt() ?? 0,
      isArchived: json['isArchived'] as bool? ?? false,
      stockStatus: SpetoStockStatus.fromJson(
        (json['stockStatus'] as Map<Object?, Object?>? ??
                const <Object?, Object?>{})
            .cast<String, Object?>(),
      ),
      searchKeywords:
          ((json['searchKeywords'] as List<Object?>?) ?? const <Object?>[])
              .map((Object? item) => item! as String)
              .toList(growable: false),
      legacyAliases:
          ((json['legacyAliases'] as List<Object?>?) ?? const <Object?>[])
              .map((Object? item) => item! as String)
              .toList(growable: false),
    );
  }
}

class SpetoCatalogEvent {
  const SpetoCatalogEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.district,
    required this.dateLabel,
    required this.timeLabel,
    required this.image,
    required this.pointsCost,
    required this.primaryTag,
    required this.secondaryTag,
    required this.description,
    required this.organizer,
    required this.participantLabel,
    required this.ticketCategory,
    required this.locationTitle,
    required this.locationSubtitle,
    required this.remainingCount,
    required this.capacity,
    required this.isFeatured,
    required this.isActive,
  });

  final String id;
  final String title;
  final String venue;
  final String district;
  final String dateLabel;
  final String timeLabel;
  final String image;
  final int pointsCost;
  final String primaryTag;
  final String secondaryTag;
  final String description;
  final String organizer;
  final String participantLabel;
  final String ticketCategory;
  final String locationTitle;
  final String locationSubtitle;
  final int remainingCount;
  final int capacity;
  final bool isFeatured;
  final bool isActive;

  factory SpetoCatalogEvent.fromJson(Map<String, Object?> json) {
    return SpetoCatalogEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      district: json['district'] as String? ?? '',
      dateLabel: json['dateLabel'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      image: json['image'] as String? ?? '',
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
      primaryTag: json['primaryTag'] as String? ?? '',
      secondaryTag: json['secondaryTag'] as String? ?? '',
      description: json['description'] as String? ?? '',
      organizer: json['organizer'] as String? ?? '',
      participantLabel: json['participantLabel'] as String? ?? '',
      ticketCategory: json['ticketCategory'] as String? ?? '',
      locationTitle: json['locationTitle'] as String? ?? '',
      locationSubtitle: json['locationSubtitle'] as String? ?? '',
      remainingCount: (json['remainingCount'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
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

class SpetoVendorBankAccount {
  const SpetoVendorBankAccount({
    required this.id,
    required this.vendorId,
    required this.holderName,
    required this.bankName,
    required this.iban,
    required this.maskedIban,
    required this.isDefault,
  });

  final String id;
  final String vendorId;
  final String holderName;
  final String bankName;
  final String iban;
  final String maskedIban;
  final bool isDefault;

  factory SpetoVendorBankAccount.fromJson(Map<String, Object?> json) {
    return SpetoVendorBankAccount(
      id: json['id'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      holderName: json['holderName'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      iban: json['iban'] as String? ?? '',
      maskedIban: json['maskedIban'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class SpetoVendorPayout {
  const SpetoVendorPayout({
    required this.id,
    required this.vendorId,
    required this.bankAccountId,
    required this.amount,
    required this.status,
    required this.note,
    required this.requestedAtLabel,
    required this.completedAtLabel,
  });

  final String id;
  final String vendorId;
  final String bankAccountId;
  final double amount;
  final SpetoPayoutStatus status;
  final String note;
  final String requestedAtLabel;
  final String completedAtLabel;

  factory SpetoVendorPayout.fromJson(Map<String, Object?> json) {
    return SpetoVendorPayout(
      id: json['id'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      bankAccountId: json['bankAccountId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: _enumByApiName(
        SpetoPayoutStatus.values,
        json['status'] as String?,
        fallback: SpetoPayoutStatus.pending,
      ),
      note: json['note'] as String? ?? '',
      requestedAtLabel: json['requestedAtLabel'] as String? ?? '',
      completedAtLabel: json['completedAtLabel'] as String? ?? '',
    );
  }
}

class SpetoVendorFinanceSummary {
  const SpetoVendorFinanceSummary({
    required this.vendorId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.lastPayoutAt,
    required this.lastPayoutAmount,
    required this.bankAccounts,
  });

  final String vendorId;
  final double availableBalance;
  final double pendingBalance;
  final String lastPayoutAt;
  final double lastPayoutAmount;
  final List<SpetoVendorBankAccount> bankAccounts;

  factory SpetoVendorFinanceSummary.fromJson(Map<String, Object?> json) {
    return SpetoVendorFinanceSummary(
      vendorId: json['vendorId'] as String? ?? '',
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0,
      lastPayoutAt: json['lastPayoutAt'] as String? ?? '',
      lastPayoutAmount: (json['lastPayoutAmount'] as num?)?.toDouble() ?? 0,
      bankAccounts:
          ((json['bankAccounts'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (Object? item) => SpetoVendorBankAccount.fromJson(
                  item! as Map<String, Object?>,
                ),
              )
              .toList(growable: false),
    );
  }
}

class SpetoVendorCampaign {
  const SpetoVendorCampaign({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.description,
    required this.kind,
    required this.status,
    required this.scheduleLabel,
    required this.badgeLabel,
    required this.discountPercent,
    required this.discountedPrice,
    required this.startsAt,
    required this.endsAt,
    required this.productIds,
    required this.productTitles,
    required this.storefrontType,
  });

  final String id;
  final String vendorId;
  final String title;
  final String description;
  final SpetoCampaignKind kind;
  final SpetoCampaignStatus status;
  final String scheduleLabel;
  final String badgeLabel;
  final int discountPercent;
  final double discountedPrice;
  final String startsAt;
  final String endsAt;
  final List<String> productIds;
  final List<String> productTitles;
  final SpetoStorefrontType storefrontType;

  factory SpetoVendorCampaign.fromJson(Map<String, Object?> json) {
    return SpetoVendorCampaign(
      id: json['id'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      kind: _enumByApiName(
        SpetoCampaignKind.values,
        json['kind'] as String?,
        fallback: SpetoCampaignKind.happyHour,
      ),
      status: _enumByApiName(
        SpetoCampaignStatus.values,
        json['status'] as String?,
        fallback: SpetoCampaignStatus.draft,
      ),
      scheduleLabel: json['scheduleLabel'] as String? ?? '',
      badgeLabel: json['badgeLabel'] as String? ?? '',
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble() ?? 0,
      startsAt: json['startsAt'] as String? ?? '',
      endsAt: json['endsAt'] as String? ?? '',
      productIds: ((json['productIds'] as List<Object?>?) ?? const <Object?>[])
          .map((Object? item) => item as String)
          .toList(growable: false),
      productTitles:
          ((json['productTitles'] as List<Object?>?) ?? const <Object?>[])
              .map((Object? item) => item as String)
              .toList(growable: false),
      storefrontType: _enumByApiName(
        SpetoStorefrontType.values,
        json['storefrontType'] as String?,
        fallback: SpetoStorefrontType.restaurant,
      ),
    );
  }
}

class SpetoVendorCampaignSummary {
  const SpetoVendorCampaignSummary({
    required this.vendorId,
    required this.activeCount,
    required this.draftCount,
    required this.pausedCount,
    required this.criticalProductCount,
    required this.campaigns,
  });

  final String vendorId;
  final int activeCount;
  final int draftCount;
  final int pausedCount;
  final int criticalProductCount;
  final List<SpetoVendorCampaign> campaigns;

  factory SpetoVendorCampaignSummary.fromJson(Map<String, Object?> json) {
    return SpetoVendorCampaignSummary(
      vendorId: json['vendorId'] as String? ?? '',
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      draftCount: (json['draftCount'] as num?)?.toInt() ?? 0,
      pausedCount: (json['pausedCount'] as num?)?.toInt() ?? 0,
      criticalProductCount:
          (json['criticalProductCount'] as num?)?.toInt() ?? 0,
      campaigns: ((json['campaigns'] as List<Object?>?) ?? const <Object?>[])
          .map(
            (Object? item) =>
                SpetoVendorCampaign.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
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
    this.refreshToken = '',
    this.accessTokenExpiresAt = '',
    this.refreshTokenExpiresAt = '',
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
  final String refreshToken;
  final String accessTokenExpiresAt;
  final String refreshTokenExpiresAt;
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
    String? refreshToken,
    String? accessTokenExpiresAt,
    String? refreshTokenExpiresAt,
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
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
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
      'refreshToken': refreshToken,
      'accessTokenExpiresAt': accessTokenExpiresAt,
      'refreshTokenExpiresAt': refreshTokenExpiresAt,
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
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresAt: json['accessTokenExpiresAt'] as String? ?? '',
      refreshTokenExpiresAt: json['refreshTokenExpiresAt'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      role: _enumByApiName(
        SpetoUserRole.values,
        json['role'] as String?,
        fallback: SpetoUserRole.customer,
      ),
      vendorScopes:
          ((json['vendorScopes'] as List<Object?>?) ?? const <Object?>[])
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
    required this.favoriteMarketIds,
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
  final List<String> favoriteMarketIds;
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
      'favoriteMarketIds': favoriteMarketIds,
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
      favoriteMarketIds:
          ((json['favoriteMarketIds'] as List<Object?>?) ?? const <Object?>[])
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
    required this.favoriteRestaurantIds,
    required this.favoriteEventIds,
    required this.favoriteMarketIds,
    required this.followedOrganizerIds,
    required this.orderRatings,
  });

  final SpetoRemoteUserProfile profile;
  final List<SpetoAddress> addresses;
  final List<SpetoPaymentCard> paymentCards;
  final List<SpetoOrder> activeOrders;
  final List<SpetoOrder> historyOrders;
  final List<SpetoSupportTicket> supportTickets;
  final List<SpetoEventTicket> ownedTickets;
  final double proPointsBalance;
  final List<String> favoriteRestaurantIds;
  final List<String> favoriteEventIds;
  final List<String> favoriteMarketIds;
  final List<String> followedOrganizerIds;
  final Map<String, int> orderRatings;
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
      stockStatus: SpetoStockStatus.fromJson(_asJsonMap(json['stockStatus'])),
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
