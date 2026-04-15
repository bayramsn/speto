import 'package:flutter/material.dart';
import '../../src/core/models.dart';
import '../constants/app_images.dart';
import '../theme/palette.dart';
import '../state/app_state.dart';
import '../navigation/screen_enum.dart';
import '../navigation/navigator.dart';
import '../../features/restaurant/restaurant_data.dart';
// TODO: SpetoToast import will be added after it is extracted from speto_app.dart.
// import '../../shared/widgets/speto_toast.dart';

SpetoScreen screenForNav(NavSection section) {
  switch (section) {
    case NavSection.explore:
      return SpetoScreen.home;
    case NavSection.orders:
      return SpetoScreen.orderHistory;
    case NavSection.basket:
      return SpetoScreen.happyHourCheckout;
    case NavSection.points:
      return SpetoScreen.proPoints;
    case NavSection.profile:
      return SpetoScreen.accountSettings;
  }
}

const SpetoCartItem happyHourBurgerTemplate = SpetoCartItem(
  id: 'mega-burger-menu',
  vendor: 'Burger King Kadıköy',
  title: 'Mega Burger Menü',
  image: AppImages.burgerHero,
  unitPrice: 85,
);

const SpetoCartItem pepperoniPizzaTemplate = SpetoCartItem(
  id: 'pepperoni-pizza-slice',
  vendor: 'Pizza Bulls',
  title: 'Pepperonili Pizza Dilimi',
  image: AppImages.pizza,
  unitPrice: 100,
);

SpetoCartItem megaBurgerCartItem({int quantity = 1}) =>
    happyHourBurgerTemplate.copyWith(quantity: quantity);

SpetoCartItem pepperoniPizzaCartItem({int quantity = 1}) =>
    pepperoniPizzaTemplate.copyWith(quantity: quantity);

List<SpetoHappyHourOffer> defaultHappyHourOffers() {
  return const <SpetoHappyHourOffer>[
    SpetoHappyHourOffer(
      id: 'mega-burger-menu',
      productId: 'mega-burger-menu',
      vendorId: 'vendor-burger-yiyelim',
      vendorName: 'Burger Yiyelim',
      vendorSubtitle: 'Burger ve hızlı pickup menüleri',
      title: 'Mega Burger Menü',
      subtitle: 'Çifte köfte, cheddar ve patates',
      description:
          'Çifte dana köfte, cheddar, özel sos ve çıtır patatesle hazırlanan hızlı pickup menüsü.',
      imageUrl: AppImages.burgerHero,
      badge: 'Happy Hour Özel',
      discountedPrice: 85,
      discountedPriceText: '85 TL',
      originalPrice: 120,
      originalPriceText: '120 TL',
      discountPercent: 29,
      expiresInMinutes: 45,
      rewardPoints: 50,
      claimCount: 24,
      locationTitle: 'Kadıköy Merkez Şubesi',
      locationSubtitle: '0,4 km uzaklıkta • 23:00\'a kadar açık',
      sectionLabel: 'Burger',
      stockStatus: SpetoStockStatus(
        isInStock: true,
        availableQuantity: 12,
        lowStock: false,
        canPurchase: true,
      ),
    ),
    SpetoHappyHourOffer(
      id: 'pepperoni-pizza-slice',
      productId: 'pepperoni-pizza-slice',
      vendorId: 'vendor-pizza-bulls',
      vendorName: 'Pizza Bulls',
      vendorSubtitle: 'İnce hamur ve fırın sıcaklığında servis',
      title: 'Pepperonili Pizza Dilimi',
      subtitle: 'Tek dilim + içecek fırsatı',
      description:
          'Pepperoni, mozzarella ve günlük hazırlanan sos ile sunulan hızlı servis pizza dilimi.',
      imageUrl: AppImages.pizza,
      badge: 'Akşam Fırsatı',
      discountedPrice: 79,
      discountedPriceText: '79 TL',
      originalPrice: 109,
      originalPriceText: '109 TL',
      discountPercent: 28,
      expiresInMinutes: 62,
      rewardPoints: 40,
      claimCount: 18,
      locationTitle: 'Bostancı Gel-Al Noktası',
      locationSubtitle: '0,8 km uzaklıkta • 22:30\'a kadar açık',
      sectionLabel: 'Pizza',
      stockStatus: SpetoStockStatus(
        isInStock: true,
        availableQuantity: 9,
        lowStock: false,
        canPurchase: true,
      ),
    ),
    SpetoHappyHourOffer(
      id: 'market-iced-latte-bundle',
      productId: 'market-iced-latte-bundle',
      vendorId: 'vendor-happy-hour-market',
      vendorName: 'Happy Hour Market',
      vendorSubtitle: 'Soğuk içecek ve hazır tüketim rafı',
      title: 'Iced Latte + Kruvasan',
      subtitle: 'Kahve molası için hızlı paket',
      description:
          'Soğuk latte ve tereyağlı kruvasan ile hazırlanan kısa mola paketi.',
      imageUrl: AppImages.nightlife,
      badge: 'Kampüs Molası',
      discountedPrice: 69,
      discountedPriceText: '69 TL',
      originalPrice: 94,
      originalPriceText: '94 TL',
      discountPercent: 27,
      expiresInMinutes: 54,
      rewardPoints: 35,
      claimCount: 31,
      locationTitle: 'Moda Gel-Al Noktası',
      locationSubtitle: '0,6 km uzaklıkta • 00:00\'a kadar açık',
      sectionLabel: 'İçecek',
      stockStatus: SpetoStockStatus(
        isInStock: true,
        availableQuantity: 7,
        lowStock: true,
        canPurchase: true,
      ),
    ),
  ];
}

SpetoCommerceSnapshot initialCommerceSnapshot(SpetoCommerceSnapshot? snapshot) {
  return normalizeCommerceSnapshot(snapshot ?? defaultCommerceSnapshot());
}

SpetoCommerceSnapshot normalizeCommerceSnapshot(
  SpetoCommerceSnapshot snapshot,
) {
  return SpetoCommerceSnapshot(
    cartItems: snapshot.cartItems.map(_normalizeCartItem).toList(),
    activeOrders: snapshot.activeOrders.map(_normalizeOrder).toList(),
    historyOrders: snapshot.historyOrders.map(_normalizeOrder).toList(),
    selectedOrderId: snapshot.selectedOrderId,
    proPointsBalance: snapshot.proPointsBalance,
    ownedTickets: snapshot.ownedTickets.map(_normalizeTicket).toList(),
    selectedTicketId: snapshot.selectedTicketId,
    addresses: snapshot.addresses.map(_normalizeAddress).toList(),
    paymentCards: snapshot.paymentCards.map(_normalizePaymentCard).toList(),
    supportTickets: snapshot.supportTickets
        .map(_normalizeSupportTicket)
        .toList(),
    favoriteRestaurantIds: List<String>.of(snapshot.favoriteRestaurantIds),
    favoriteEventIds: List<String>.of(snapshot.favoriteEventIds),
    favoriteMarketIds: List<String>.of(snapshot.favoriteMarketIds),
    followedOrganizerIds: List<String>.of(snapshot.followedOrganizerIds),
    orderRatings: Map<String, int>.of(snapshot.orderRatings),
    profileDisplayName: _translateUserFacingText(snapshot.profileDisplayName),
    profilePhone: snapshot.profilePhone,
    profileAvatarUrl: snapshot.profileAvatarUrl,
    profileNotificationsEnabled: snapshot.profileNotificationsEnabled,
  );
}

SpetoCartItem _normalizeCartItem(SpetoCartItem item) {
  return SpetoCartItem(
    id: item.id,
    vendor: _translateUserFacingText(item.vendor),
    title: _translateUserFacingText(item.title),
    image: item.image,
    unitPrice: item.unitPrice,
    quantity: item.quantity,
  );
}

SpetoOrder _normalizeOrder(SpetoOrder order) {
  return SpetoOrder(
    id: order.id,
    vendor: _translateUserFacingText(order.vendor),
    image: order.image,
    items: order.items.map(_normalizeCartItem).toList(),
    placedAtLabel: _translateUserFacingText(order.placedAtLabel),
    etaLabel: _translateUserFacingText(order.etaLabel),
    status: order.status,
    actionLabel: _translateUserFacingText(order.actionLabel),
    pickupCode: order.pickupCode,
    rewardPoints: order.rewardPoints,
    deliveryMode: _translateUserFacingText(order.deliveryMode),
    deliveryAddress: _translateUserFacingText(order.deliveryAddress),
    paymentMethod: _translateUserFacingText(order.paymentMethod),
    promoCode: _translateUserFacingText(order.promoCode),
    deliveryFee: order.deliveryFee,
    discountAmount: order.discountAmount,
  );
}

SpetoEventTicket _normalizeTicket(SpetoEventTicket ticket) {
  return SpetoEventTicket(
    id: ticket.id,
    title: _translateUserFacingText(ticket.title),
    venue: _translateUserFacingText(ticket.venue),
    dateLabel: ticket.dateLabel,
    timeLabel: ticket.timeLabel,
    zone: _translateUserFacingText(ticket.zone),
    seat: ticket.seat,
    gate: ticket.gate,
    code: ticket.code,
    image: ticket.image,
    pointsCost: ticket.pointsCost,
  );
}

SpetoAddress _normalizeAddress(SpetoAddress address) {
  return address.copyWith(
    label: _translateUserFacingText(address.label),
    address: _translateUserFacingText(address.address),
  );
}

SpetoPaymentCard _normalizePaymentCard(SpetoPaymentCard card) {
  return card.copyWith(
    brand: _translateUserFacingText(card.brand),
    holderName: _translateUserFacingText(card.holderName),
  );
}

SpetoSupportTicket _normalizeSupportTicket(SpetoSupportTicket ticket) {
  return ticket.copyWith(
    subject: _translateUserFacingText(ticket.subject),
    message: _translateUserFacingText(ticket.message),
    channel: _translateUserFacingText(ticket.channel),
    createdAtLabel: _translateUserFacingText(ticket.createdAtLabel),
    status: _translateUserFacingText(ticket.status),
  );
}

String _translateUserFacingText(String text) {
  const List<MapEntry<String, String>> replacements =
      <MapEntry<String, String>>[
        MapEntry('Fırsat Saati Marketi', 'Happy Hour Market'),
        MapEntry('Fırsat Saati', 'Happy Hour'),
        MapEntry('Jazz Night at Galata', "Galata'da Caz Gecesi"),
        MapEntry('Galata Jazz Night', "Galata'da Caz Gecesi"),
        MapEntry('Burger King Kadikoy', 'Burger King Kadıköy'),
        MapEntry('Happy Hour Market', 'Happy Hour Market'),
        MapEntry('Market Firsat Paketi', 'Market Happy Hour Paketi'),
        MapEntry('Double Cheeseburger', 'Çifte Peynirli Burger'),
        MapEntry('Mega Burger Menu', 'Mega Burger Menü'),
        MapEntry('Double Whopper Menu', 'Double Whopper Menü'),
        MapEntry('Pepperoni Pizza Slice', 'Pepperonili Pizza Dilimi'),
        MapEntry('Pepperoni Slice Combo', 'Pepperonili Dilim Menü'),
        MapEntry('BBQ Platter', 'Barbekü Tabağı'),
        MapEntry('Sushi Box', 'Suşi Kutusu'),
        MapEntry('Lounge', 'Salon'),
        MapEntry('Bugun', 'Bugün'),
        MapEntry('Takibi Gor', 'Takibi Gör'),
        MapEntry('Detaylari Gor', 'Detayları Gör'),
        MapEntry('Gel-Al Kodunu Gor', 'Gel-Al Kodunu Gör'),
        MapEntry('Hazirlaniyor', 'Hazırlanıyor'),
        MapEntry('Tamamlandi', 'Tamamlandı'),
        MapEntry('Iptal', 'İptal'),
      ];

  String translated = text;
  for (final MapEntry<String, String> entry in replacements) {
    translated = translated.replaceAll(entry.key, entry.value);
  }
  return translated;
}

SpetoCommerceSnapshot defaultCommerceSnapshot() {
  return SpetoCommerceSnapshot(
    cartItems: const <SpetoCartItem>[],
    activeOrders: const <SpetoOrder>[],
    historyOrders: const <SpetoOrder>[],
    selectedOrderId: null,
    proPointsBalance: 0,
    ownedTickets: const <SpetoEventTicket>[],
    selectedTicketId: null,
    addresses: const <SpetoAddress>[],
    paymentCards: const <SpetoPaymentCard>[],
    supportTickets: const <SpetoSupportTicket>[],
    favoriteRestaurantIds: const <String>[],
    favoriteEventIds: const <String>[],
    favoriteMarketIds: const <String>[],
    followedOrganizerIds: const <String>[],
    orderRatings: const <String, int>{},
    profileDisplayName: '',
    profilePhone: '',
    profileAvatarUrl: '',
    profileNotificationsEnabled: true,
  );
}

String formatPrice(double price) {
  final bool whole = price == price.roundToDouble();
  return '${whole ? price.toStringAsFixed(0) : price.toStringAsFixed(2)} TL';
}

String formatPointValue(num value) {
  final double normalized = value.toDouble();
  final bool whole = normalized == normalized.roundToDouble();
  return whole ? normalized.toStringAsFixed(0) : normalized.toStringAsFixed(2);
}

String formatPoints(num value) => '${formatPointValue(value)} Pro';

String orderStatusLabel(SpetoOrderStatus status) {
  switch (status) {
    case SpetoOrderStatus.active:
      return 'Hazırlanıyor';
    case SpetoOrderStatus.completed:
      return 'Tamamlandı';
    case SpetoOrderStatus.cancelled:
      return 'İptal';
  }
}

Color orderStatusColor(SpetoOrderStatus status) {
  switch (status) {
    case SpetoOrderStatus.active:
      return Palette.orange;
    case SpetoOrderStatus.completed:
      return Palette.green;
    case SpetoOrderStatus.cancelled:
      return Palette.crimson;
  }
}

void addCartItemAndOpenCheckout(
  BuildContext context,
  SpetoCartItem item, {
  String? notice,
}) {
  final SpetoAppState appState = SpetoAppScope.of(context);
  final bool added = appState.addToCart(item);
  if (!added) {
    return;
  }
  // TODO: Uncomment after SpetoToast is extracted from speto_app.dart.
  // SpetoToast.show(
  //   context,
  //   message: notice ?? '${item.title} sepete eklendi.',
  //   icon: Icons.shopping_cart_outlined,
  // );
  openScreen(context, SpetoScreen.happyHourCheckout);
}

double menuBasePrice(String priceLabel) {
  return double.tryParse(priceLabel.replaceAll(' TL', '').trim()) ?? 0;
}

List<MapEntry<String, IconData>> menuHighlightsFor(MenuListItem item) {
  final String searchable = '${item.title} ${item.description}'.toLowerCase();
  if (searchable.contains('çay') || searchable.contains('kola')) {
    return const <MapEntry<String, IconData>>[
      MapEntry<String, IconData>('Serin servis', Icons.ac_unit_rounded),
      MapEntry<String, IconData>('Günlük hazırlık', Icons.local_drink_outlined),
      MapEntry<String, IconData>('Gel-Al uyumlu', Icons.storefront_outlined),
    ];
  }
  if (searchable.contains('sundae') ||
      searchable.contains('kurabiye') ||
      searchable.contains('çikolata')) {
    return const <MapEntry<String, IconData>>[
      MapEntry<String, IconData>('Tatlı molası', Icons.icecream_outlined),
      MapEntry<String, IconData>('Paylaşılabilir', Icons.groups_rounded),
      MapEntry<String, IconData>('Hızlı servis', Icons.timer_outlined),
    ];
  }
  return const <MapEntry<String, IconData>>[
    MapEntry<String, IconData>('Taze hazırlanır', Icons.restaurant_outlined),
    MapEntry<String, IconData>('Şubede servis', Icons.storefront_outlined),
    MapEntry<String, IconData>('Gel-Al uyumlu', Icons.bolt_rounded),
  ];
}

String slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String displayNameFromEmail(String email) {
  final String localPart = email.split('@').first.trim();
  if (localPart.isEmpty) {
    return 'SepetPro Kullanıcısı';
  }
  final List<String> words = localPart
      .split(RegExp(r'[._-]+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return 'SepetPro Kullanıcısı';
  }
  return words
      .map(
        (String part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String maskEmailAddress(String email) {
  final List<String> parts = email.split('@');
  if (parts.length != 2) {
    return email;
  }
  final String local = parts.first.trim();
  final String domain = parts.last.trim();
  if (local.isEmpty) {
    return '***@$domain';
  }
  if (local.length <= 2) {
    return '${local[0]}***@$domain';
  }
  final String visibleTail = local.length > 4
      ? local.substring(local.length - 2)
      : '';
  return '${local.substring(0, 2)}***$visibleTail@$domain';
}
