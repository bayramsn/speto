import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_images.dart';
import '../../core/state/app_state.dart';
import '../../src/core/models.dart';
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

List<EventExperience> eventCatalog = defaultEventCatalog();
List<RestaurantCardData> restaurantCards = defaultRestaurantCatalog();

EventExperience get featuredEventExperience =>
    eventById('event-galata-jazz');

SpetoEventTicket get featuredEventTicket {
  final EventExperience e = featuredEventExperience;
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

const List<String> eventFilters = <String>[
  'Hepsi',
  'Konser',
  'Tiyatro',
  'Festival',
  'Atölye',
  'Sinema',
];

EventExperience eventById(String id) {
  for (final EventExperience item in eventCatalog) {
    if (item.id == id) {
      return item;
    }
  }
  return eventCatalog.first;
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
  final List<EventExperience> matches = eventCatalog
      .where((EventExperience item) => item.primaryTag == category)
      .toList();
  if (matches.isNotEmpty) {
    return matches;
  }
  return eventCatalog.take(3).toList();
}

Future<void> initializeSpetoCatalog() async {
  try {
    final String raw = await rootBundle.loadString('assets/data/catalog.json');
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return;
    }
    final List<EventExperience> events =
        (decoded['events'] as List<Object?>? ?? const <Object?>[])
            .map(
              (Object? item) =>
                  EventExperience.fromJson(item! as Map<String, Object?>),
            )
            .where(isSupportedEventExperience)
            .toList();
    final List<RestaurantCardData> restaurants =
        (decoded['restaurants'] as List<Object?>? ?? const <Object?>[])
            .map(
              (Object? item) =>
                  RestaurantCardData.fromJson(item! as Map<String, Object?>),
            )
            .toList();
    if (events.isNotEmpty) {
      eventCatalog = events;
    }
    if (restaurants.isNotEmpty) {
      restaurantCards = restaurants;
    }
  } catch (_) {
    eventCatalog = defaultEventCatalog();
    restaurantCards = defaultRestaurantCatalog();
  }
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
