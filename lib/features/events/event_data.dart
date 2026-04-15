import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../src/core/models.dart';
import '../../src/core/remote_api.dart';
import '../../features/home/home_data.dart';
import '../../features/marketplace/market_store_screen.dart';
import '../../features/restaurant/restaurant_data.dart';

class EventExperience {
  const EventExperience({
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

  factory EventExperience.fromJson(Map<String, Object?> json) {
    return EventExperience(
      id: json['id']! as String,
      title: json['title']! as String,
      venue: json['venue']! as String,
      district: json['district']! as String,
      dateLabel: json['dateLabel']! as String,
      timeLabel: json['timeLabel']! as String,
      image: json['image']! as String,
      pointsCost: (json['pointsCost']! as num).toInt(),
      primaryTag: json['primaryTag']! as String,
      secondaryTag: json['secondaryTag']! as String,
      description: json['description']! as String,
      organizer: json['organizer']! as String,
      participantLabel: json['participantLabel']! as String,
      ticketCategory: json['ticketCategory']! as String,
      locationTitle: json['locationTitle']! as String,
      locationSubtitle: json['locationSubtitle']! as String,
    );
  }
}

List<EventExperience> eventCatalog = <EventExperience>[];
List<RestaurantCardData> restaurantCards = <RestaurantCardData>[];
List<String> eventFilters = const <String>['Hepsi'];

const String _catalogBootstrapCacheKey = 'speto.catalog.bootstrap';

EventExperience? get featuredEventExperience =>
    eventByIdOrNull('event-galata-jazz') ??
    (eventCatalog.isNotEmpty ? eventCatalog.first : null);

SpetoEventTicket? get featuredEventTicket {
  final EventExperience? e = featuredEventExperience;
  if (e == null) {
    return null;
  }
  return SpetoEventTicket(
    id: e.id,
    title: e.title,
    venue: e.venue,
    dateLabel: e.dateLabel,
    timeLabel: e.timeLabel,
    zone: 'VIP',
    seat: 'A12',
    gate: 'G3',
    code: 'SPT-${e.id.hashCode.abs().toString().padLeft(6, '0')}',
    image: e.image,
    pointsCost: e.pointsCost,
  );
}

List<String> defaultEventFilters() {
  return <String>['Hepsi', 'Konser', 'Tiyatro', 'Festival', 'Atölye', 'Sinema'];
}

EventExperience? eventByIdOrNull(String id) {
  for (final EventExperience item in eventCatalog) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}

bool isSupportedEventExperience(EventExperience item) {
  final String normalized = <String>[
    item.title,
    item.description,
    item.primaryTag,
    item.secondaryTag,
    item.organizer,
  ].join(' ').toLowerCase();
  if (normalized.contains('kampüs') ||
      normalized.contains('campus') ||
      normalized.contains('topluluk') ||
      normalized.contains('networking') ||
      normalized.contains('buluşma')) {
    return false;
  }
  switch (item.primaryTag) {
    case 'Konser':
    case 'Tiyatro':
    case 'Festival':
    case 'Atölye':
    case 'Sinema':
      return true;
    default:
      return false;
  }
}

List<EventExperience> eventsForCategory(String category) {
  if (eventCatalog.isEmpty) {
    return const <EventExperience>[];
  }
  if (category == 'Hepsi') {
    return eventCatalog;
  }
  final List<EventExperience> matches = eventCatalog
      .where((EventExperience item) => item.primaryTag == category)
      .toList();
  if (matches.isNotEmpty) {
    return matches;
  }
  return eventCatalog.take(3).toList();
}

Future<void> initializeSpetoCatalog() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  try {
    final SpetoRemoteApiClient apiClient = SpetoRemoteApiClient();
    final Map<String, Object?> bootstrapJson = _asJsonMap(
      await apiClient.get('catalog/bootstrap'),
    );
    await prefs.setString(_catalogBootstrapCacheKey, jsonEncode(bootstrapJson));
    _applyBootstrap(SpetoCatalogBootstrap.fromJson(bootstrapJson));
    return;
  } catch (_) {}

  final String? cachedBootstrap = prefs.getString(_catalogBootstrapCacheKey);
  if (cachedBootstrap != null) {
    try {
      _applyBootstrap(
        SpetoCatalogBootstrap.fromJson(_asJsonMap(jsonDecode(cachedBootstrap))),
      );
      return;
    } catch (_) {}
  }

  _clearCatalogRuntime();
}

void _applyBootstrap(SpetoCatalogBootstrap bootstrap) {
  final List<EventExperience> events = bootstrap.events
      .map(_eventExperienceFromCatalog)
      .where(isSupportedEventExperience)
      .toList(growable: false);
  final List<RestaurantCardData> restaurants = bootstrap.restaurants
      .map(_restaurantCardFromVendor)
      .toList(growable: false);
  final List<MarketStoreData> markets = bootstrap.markets
      .map(_marketStoreFromVendor)
      .toList(growable: false);
  final Map<String, Map<String, List<MenuListItem>>> runtimeMenus =
      <String, Map<String, List<MenuListItem>>>{
        for (final SpetoCatalogVendor vendor in bootstrap.restaurants)
          vendor.id: <String, List<MenuListItem>>{
            for (final SpetoCatalogSection section in vendor.sections)
              section.label: section.products
                  .map(_menuItemFromCatalogProduct)
                  .toList(growable: false),
          },
      };

  eventCatalog = events;
  restaurantCards = restaurants;
  marketStores
    ..clear()
    ..addAll(markets);
  setRuntimeRestaurantMenuSections(runtimeMenus);
  _applyHomeContent(bootstrap.home);
  eventFilters = _deriveEventFilters(events);
}

void _applyHomeContent(SpetoCatalogHomeContent home) {
  final List<HomeHeroData> heroes = home.heroes
      .where((SpetoCatalogContentBlock block) => block.isActive)
      .map(_homeHeroFromBlock)
      .toList(growable: false);
  final List<HomeQuickFilter> quickFilters = home.quickFilters
      .where((SpetoCatalogContentBlock block) => block.isActive)
      .map(_homeQuickFilterFromBlock)
      .toList(growable: false);
  final List<String> discoveryFilters = home.discoveryFilters
      .where((SpetoCatalogContentBlock block) => block.isActive)
      .map((SpetoCatalogContentBlock block) => block.title)
      .where((String label) => label.trim().isNotEmpty)
      .toList(growable: false);

  homeHeroCards
    ..clear()
    ..addAll(heroes);
  homeQuickFilters
    ..clear()
    ..addAll(quickFilters);
  filterChips
    ..clear()
    ..addAll(
      discoveryFilters.isEmpty ? <String>['Hepsi'] : discoveryFilters,
    );
}

void _clearCatalogRuntime() {
  eventCatalog = <EventExperience>[];
  restaurantCards = <RestaurantCardData>[];
  eventFilters = const <String>['Hepsi'];
  marketStores.clear();
  clearRuntimeRestaurantMenuSections();
  homeHeroCards.clear();
  homeQuickFilters.clear();
  filterChips
    ..clear()
    ..addAll(<String>['Hepsi']);
}

List<String> _deriveEventFilters(List<EventExperience> events) {
  final Set<String> categories = <String>{};
  for (final EventExperience event in events) {
    if (event.primaryTag.trim().isNotEmpty) {
      categories.add(event.primaryTag.trim());
    }
  }
  if (categories.isEmpty) {
    return const <String>['Hepsi'];
  }
  return <String>['Hepsi', ...categories];
}

RestaurantCardData _restaurantCardFromVendor(SpetoCatalogVendor vendor) {
  return RestaurantCardData(
    id: vendor.id,
    title: vendor.title,
    image: vendor.image,
    cuisine: vendor.cuisine,
    etaMin: vendor.etaMin,
    etaMax: vendor.etaMax,
    ratingValue: vendor.ratingValue,
    promo: vendor.promoLabel.isNotEmpty ? vendor.promoLabel : vendor.badge,
    studentFriendly: vendor.studentFriendly,
  );
}

EventExperience _eventExperienceFromCatalog(SpetoCatalogEvent event) {
  return EventExperience(
    id: event.id,
    title: event.title,
    venue: event.venue,
    district: event.district,
    dateLabel: event.dateLabel,
    timeLabel: event.timeLabel,
    image: event.image,
    pointsCost: event.pointsCost,
    primaryTag: event.primaryTag,
    secondaryTag: event.secondaryTag,
    description: event.description,
    organizer: event.organizer,
    participantLabel: event.participantLabel,
    ticketCategory: event.ticketCategory,
    locationTitle: event.locationTitle,
    locationSubtitle: event.locationSubtitle,
  );
}

MarketStoreData _marketStoreFromVendor(SpetoCatalogVendor vendor) {
  return MarketStoreData(
    id: vendor.id,
    title: vendor.title,
    subtitle: vendor.subtitle,
    meta: vendor.meta,
    image: vendor.image,
    badge: vendor.badge,
    rewardLabel: vendor.rewardLabel,
    ratingLabel: vendor.ratingLabel,
    distanceLabel: vendor.distanceLabel,
    etaLabel: vendor.etaLabel,
    promoLabel: vendor.promoLabel,
    workingHoursLabel: vendor.workingHoursLabel,
    minOrderLabel: vendor.minOrderLabel,
    deliveryWindowLabel: vendor.deliveryWindowLabel,
    reviewCountLabel: vendor.reviewCountLabel,
    announcement: vendor.announcement,
    bundleTitle: vendor.bundleTitle,
    bundleDescription: vendor.bundleDescription,
    bundlePrice: vendor.bundlePrice,
    heroTitle: vendor.heroTitle,
    heroSubtitle: vendor.heroSubtitle,
    highlights: vendor.highlights
        .map(_storeHighlightFromVendorHighlight)
        .toList(growable: false),
    sections: <String, List<MenuListItem>>{
      for (final SpetoCatalogSection section in vendor.sections)
        section.label: section.products
            .map(_menuItemFromCatalogProduct)
            .toList(growable: false),
    },
  );
}

StoreHighlightData _storeHighlightFromVendorHighlight(
  SpetoCatalogVendorHighlight highlight,
) {
  return StoreHighlightData(highlight.label, _iconDataForKey(highlight.icon));
}

MenuListItem _menuItemFromCatalogProduct(SpetoCatalogProduct product) {
  return MenuListItem(
    product.title,
    product.displaySubtitle.isNotEmpty
        ? product.displaySubtitle
        : product.description,
    product.priceText.isNotEmpty
        ? product.priceText
        : '${product.unitPrice.toStringAsFixed(0)} TL',
    product.imageUrl.isNotEmpty ? product.imageUrl : product.image,
    id: product.id,
  );
}

HomeHeroData _homeHeroFromBlock(SpetoCatalogContentBlock block) {
  return HomeHeroData(
    title: block.title,
    subtitle: block.subtitle,
    badge: block.badge,
    image: block.imageUrl,
    actionLabel: block.actionLabel,
    screen: _screenForName(block.screen),
  );
}

HomeQuickFilter _homeQuickFilterFromBlock(SpetoCatalogContentBlock block) {
  return HomeQuickFilter(
    label: block.title,
    icon: _iconDataForKey(block.iconKey),
    screen: _screenForName(block.screen),
    highlight: block.highlight,
  );
}

SpetoScreen _screenForName(String name) {
  for (final SpetoScreen screen in SpetoScreen.values) {
    if (screen.name == name) {
      return screen;
    }
  }
  return SpetoScreen.home;
}

IconData _iconDataForKey(String key) {
  return switch (key) {
    'near_me_rounded' => Icons.near_me_rounded,
    'workspace_premium_rounded' => Icons.workspace_premium_rounded,
    'nightlife_rounded' => Icons.nightlife_rounded,
    'shopping_basket_rounded' => Icons.shopping_basket_rounded,
    'local_drink_outlined' => Icons.local_drink_outlined,
    'shopping_bag_outlined' => Icons.shopping_bag_outlined,
    'storefront_outlined' => Icons.storefront_outlined,
    'ac_unit_rounded' => Icons.ac_unit_rounded,
    'dinner_dining_outlined' => Icons.dinner_dining_outlined,
    'sell_outlined' => Icons.sell_outlined,
    'flash_on_outlined' => Icons.flash_on_outlined,
    'inventory_2_outlined' => Icons.inventory_2_outlined,
    'eco_outlined' => Icons.eco_outlined,
    'grid_view_rounded' => Icons.grid_view_rounded,
    _ => Icons.auto_awesome_outlined,
  };
}

Map<String, Object?> _asJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw const FormatException('Expected JSON object');
}

List<EventExperience> defaultEventCatalog() {
  return const <EventExperience>[
    EventExperience(
      id: 'event-galata-jazz',
      title: "Galata'da Caz Gecesi",
      venue: 'Galata Sahnesi',
      district: 'Beyoğlu, İstanbul',
      dateLabel: '24 Eki 2026',
      timeLabel: '19:00',
      image: AppImages.jazz,
      pointsCost: jazzNightPointsCost,
      primaryTag: 'Konser',
      secondaryTag: 'VIP',
      description:
          'Galata Kulesi meydanında unutulmaz bir caz ve gastronomi akşamı. Dünya sahnesinden müzisyenler ve özel menüler aynı gecede buluşuyor.',
      organizer: 'Jazz Collective',
      participantLabel: '120+',
      ticketCategory: 'VIP',
      locationTitle: 'Galata Kulesi Meydanı',
      locationSubtitle: 'Beyoğlu, İstanbul',
    ),
    EventExperience(
      id: 'event-rooftop-akustik',
      title: 'Rooftop Akustik Gecesi',
      venue: 'Frankhan Teras',
      district: 'Karaköy, İstanbul',
      dateLabel: '25 Eki 2026',
      timeLabel: '20:30',
      image:
          'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 520,
      primaryTag: 'Konser',
      secondaryTag: 'Akustik',
      description:
          'Şehir ışıklarının üzerinde kurulan teras sahnede akustik performanslar ve sınırlı sayıda ayakta bilet aynı gecede buluşuyor.',
      organizer: 'Rooftop Sessions',
      participantLabel: '90+',
      ticketCategory: 'Ayakta',
      locationTitle: 'Frankhan Teras Sahnesi',
      locationSubtitle: 'Karaköy, İstanbul',
    ),
    EventExperience(
      id: 'event-soho-indie-session',
      title: 'Soho Indie Session',
      venue: 'Babylon Foyer',
      district: 'Beyoğlu, İstanbul',
      dateLabel: '27 Eki 2026',
      timeLabel: '21:00',
      image:
          'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 480,
      primaryTag: 'Konser',
      secondaryTag: 'Ayakta',
      description:
          'Bağımsız müzik sahnesinden üç farklı grup aynı gecede kısa setlerle sahne alıyor. Hızlı giriş ve lounge alanı dahil.',
      organizer: 'Soho Sounds',
      participantLabel: '180+',
      ticketCategory: 'Genel Katılım',
      locationTitle: 'Babylon Foyer',
      locationSubtitle: 'Beyoğlu, İstanbul',
    ),
    EventExperience(
      id: 'event-macbeth-stage',
      title: 'Macbeth Sahne Uyarlaması',
      venue: 'Zorlu PSM',
      district: 'Beşiktaş, İstanbul',
      dateLabel: '26 Eki 2026',
      timeLabel: '20:00',
      image:
          'https://images.unsplash.com/photo-1503095396549-807759245b35?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 540,
      primaryTag: 'Tiyatro',
      secondaryTag: 'Prömiyer',
      description:
          'Klasik Macbeth metni çağdaş sahneleme, canlı müzik geçişleri ve güçlü oyuncu kadrosuyla yeniden yorumlanıyor.',
      organizer: 'PSM Tiyatro',
      participantLabel: '220',
      ticketCategory: 'Orkestra',
      locationTitle: 'Zorlu PSM Turkcell Sahnesi',
      locationSubtitle: 'Beşiktaş, İstanbul',
    ),
    EventExperience(
      id: 'event-summer-night-comedy',
      title: 'Bir Yaz Gecesi Komedisi',
      venue: 'Moda Sahnesi',
      district: 'Kadıköy, İstanbul',
      dateLabel: '29 Eki 2026',
      timeLabel: '19:30',
      image:
          'https://images.unsplash.com/photo-1518998053901-5348d3961a04?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 410,
      primaryTag: 'Tiyatro',
      secondaryTag: 'Komedi',
      description:
          'Tempolu sahne geçişleri ve canlı anlatımıyla modern bir romantik komedi uyarlaması. Kampüs sonrası ideal akşam planı.',
      organizer: 'Moda Tiyatro Topluluğu',
      participantLabel: '140',
      ticketCategory: 'Salon',
      locationTitle: 'Moda Sahnesi',
      locationSubtitle: 'Kadıköy, İstanbul',
    ),
    EventExperience(
      id: 'event-improv-night',
      title: 'Doğaçlama Gece Seansı',
      venue: 'Kadıköy Boa Sahne',
      district: 'Kadıköy, İstanbul',
      dateLabel: '30 Eki 2026',
      timeLabel: '21:15',
      image:
          'https://images.unsplash.com/photo-1505236858219-8359eb29e329?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 360,
      primaryTag: 'Tiyatro',
      secondaryTag: 'İnteraktif',
      description:
          'Seyircinin yön verdiği kısa oyunlar, doğaçlama skeçler ve sahne üstü mini yarışmalarla ilerleyen enerjik gece.',
      organizer: 'Boa Improv',
      participantLabel: '95',
      ticketCategory: 'Sahne Önü',
      locationTitle: 'Boa Sahne',
      locationSubtitle: 'Kadıköy, İstanbul',
    ),
    EventExperience(
      id: 'event-kadikoy-food-fest',
      title: 'Kadıköy Lezzet Festivali',
      venue: 'Festival Park',
      district: 'Kadıköy, İstanbul',
      dateLabel: '28 Eki 2026',
      timeLabel: '14:00',
      image:
          'https://images.unsplash.com/photo-1528605248644-14dd04022da1?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 300,
      primaryTag: 'Festival',
      secondaryTag: 'Açık Hava',
      description:
          'Sokak lezzetleri, DJ setleri ve öğrenci dostu tadım alanlarıyla gün boyu süren şehir festivali deneyimi.',
      organizer: 'City Flavor Week',
      participantLabel: '500+',
      ticketCategory: 'Festival Giriş',
      locationTitle: 'Kadıköy Festival Park',
      locationSubtitle: 'Kadıköy, İstanbul',
    ),
    EventExperience(
      id: 'event-vintage-design-fest',
      title: 'Vintage Tasarım Fest',
      venue: 'Bomontiada Avlu',
      district: 'Şişli, İstanbul',
      dateLabel: '31 Eki 2026',
      timeLabel: '13:00',
      image:
          'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 340,
      primaryTag: 'Festival',
      secondaryTag: 'Tasarım',
      description:
          'Bağımsız tasarımcı stantları, plak seçkileri ve mini workshop alanlarıyla gün boyu süren yaratıcı festival.',
      organizer: 'Design District',
      participantLabel: '280+',
      ticketCategory: 'Festival Pass',
      locationTitle: 'Bomontiada Avlu',
      locationSubtitle: 'Şişli, İstanbul',
    ),
    EventExperience(
      id: 'event-bahar-renk-festivali',
      title: 'Bahar Renk Festivali',
      venue: 'Life Park',
      district: 'Sarıyer, İstanbul',
      dateLabel: '02 Kas 2026',
      timeLabel: '15:00',
      image:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 390,
      primaryTag: 'Festival',
      secondaryTag: 'DJ Set',
      description:
          'Açık hava sahnesi, renk temalı deneyim alanları ve gün batımına uzanan DJ performanslarıyla canlı festival akışı.',
      organizer: 'Color Vibe',
      participantLabel: '620+',
      ticketCategory: 'Genel Katılım',
      locationTitle: 'Life Park Ana Sahne',
      locationSubtitle: 'Sarıyer, İstanbul',
    ),
    EventExperience(
      id: 'event-pottery-workshop',
      title: 'Seramik Atölyesi',
      venue: 'Bomontiada',
      district: 'Şişli, İstanbul',
      dateLabel: '26 Eki 2026',
      timeLabel: '18:30',
      image: AppImages.pottery,
      pointsCost: potteryWorkshopPointsCost,
      primaryTag: 'Atölye',
      secondaryTag: 'Sınırlı Kontenjan',
      description:
          'Seramik sanatçılarıyla iki saatlik uygulamalı workshop. Kendi kupanı şekillendirip fırınlanmak üzere bırakıyorsun.',
      organizer: 'Clay Studio Istanbul',
      participantLabel: '48',
      ticketCategory: 'Workshop',
      locationTitle: 'Bomontiada Tasarım Alanı',
      locationSubtitle: 'Şişli, İstanbul',
    ),
    EventExperience(
      id: 'event-analog-photo-workshop',
      title: 'Analog Fotoğraf Atölyesi',
      venue: 'Minoa Pera',
      district: 'Beyoğlu, İstanbul',
      dateLabel: '27 Eki 2026',
      timeLabel: '18:00',
      image:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 430,
      primaryTag: 'Atölye',
      secondaryTag: 'Uygulamalı',
      description:
          '35mm makineler, film yükleme ve kadraj egzersizleriyle başlayan uygulamalı atölyede çekim pratiği de yapılıyor.',
      organizer: 'Lab 35mm',
      participantLabel: '32',
      ticketCategory: 'Workshop',
      locationTitle: 'Minoa Pera Studio',
      locationSubtitle: 'Beyoğlu, İstanbul',
    ),
    EventExperience(
      id: 'event-cocktail-workshop',
      title: 'Kokteyl Workshop',
      venue: 'Feriye',
      district: 'Ortaköy, İstanbul',
      dateLabel: '01 Kas 2026',
      timeLabel: '19:00',
      image:
          'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 460,
      primaryTag: 'Atölye',
      secondaryTag: 'Mixology',
      description:
          'Bar ekibiyle üç imza kokteyl hazırladığın, ölçü ve sunum tekniklerini denediğin akşam workshop deneyimi.',
      organizer: 'Feriye Lab',
      participantLabel: '40',
      ticketCategory: 'Workshop',
      locationTitle: 'Feriye Workshop Barı',
      locationSubtitle: 'Ortaköy, İstanbul',
    ),
    EventExperience(
      id: 'event-open-air-cinema',
      title: 'Açık Hava Film Gecesi',
      venue: 'KüçükÇiftlik Park',
      district: 'Şişli, İstanbul',
      dateLabel: '25 Eki 2026',
      timeLabel: '21:00',
      image:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 260,
      primaryTag: 'Sinema',
      secondaryTag: 'Açık Hava',
      description:
          'Battaniye alanı, kulaklıklı sessiz izleme bölümü ve geceye özel atıştırmalık standlarıyla açık hava gösterimi.',
      organizer: 'Open Screen',
      participantLabel: '340+',
      ticketCategory: 'Film Gecesi',
      locationTitle: 'KüçükÇiftlik Park',
      locationSubtitle: 'Şişli, İstanbul',
    ),
    EventExperience(
      id: 'event-midnight-horror',
      title: 'Gece Yarısı Korku Seansı',
      venue: 'Atlas 1948',
      district: 'Beyoğlu, İstanbul',
      dateLabel: '30 Eki 2026',
      timeLabel: '23:45',
      image:
          'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 280,
      primaryTag: 'Sinema',
      secondaryTag: 'Gece Seansı',
      description:
          'Özel kurgu korku seçkisi, sürpriz kısa film gösterimi ve gece seansına özel fuaye deneyimi ile ilerliyor.',
      organizer: 'Midnight Club',
      participantLabel: '170',
      ticketCategory: 'Salon',
      locationTitle: 'Atlas 1948 Sineması',
      locationSubtitle: 'Beyoğlu, İstanbul',
    ),
    EventExperience(
      id: 'event-short-film-selection',
      title: 'Bağımsız Kısa Film Seçkisi',
      venue: 'Kadıköy Sineması',
      district: 'Kadıköy, İstanbul',
      dateLabel: '03 Kas 2026',
      timeLabel: '20:00',
      image:
          'https://images.unsplash.com/photo-1513106580091-1d82408b8cd6?auto=format&fit=crop&w=1200&q=80',
      pointsCost: 240,
      primaryTag: 'Sinema',
      secondaryTag: 'Seçki',
      description:
          'Yeni dönem yönetmenlerinden oluşan kısa film seçkisi, yönetmen söyleşisi ve fuaye buluşmasıyla tamamlanıyor.',
      organizer: 'Short Cut Nights',
      participantLabel: '130',
      ticketCategory: 'Seans',
      locationTitle: 'Kadıköy Sineması',
      locationSubtitle: 'Kadıköy, İstanbul',
    ),
  ];
}
