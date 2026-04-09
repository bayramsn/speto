import 'package:flutter/material.dart';

import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';

// ---------------------------------------------------------------------------
// Hero card data
// ---------------------------------------------------------------------------

class HomeHeroData {
  const HomeHeroData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.image,
    required this.actionLabel,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String image;
  final String actionLabel;
  final SpetoScreen screen;
}

// ---------------------------------------------------------------------------
// Quick-filter chip data
// ---------------------------------------------------------------------------

class HomeQuickFilter {
  const HomeQuickFilter({
    required this.label,
    required this.icon,
    required this.screen,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final SpetoScreen screen;
  final bool highlight;
}

// ---------------------------------------------------------------------------
// Constant lists
// ---------------------------------------------------------------------------

const List<HomeHeroData> homeHeroCards = <HomeHeroData>[
  HomeHeroData(
    title: "Galata'da Caz Gecesi",
    subtitle: 'Pro puan ile açılan canlı deneyim',
    badge: 'Yeni sezon',
    image: AppImages.concert,
    actionLabel: 'Etkinliğe Git',
    screen: SpetoScreen.eventsDiscovery,
  ),
  HomeHeroData(
    title: 'Akşamüstü Happy Hour',
    subtitle: 'Market ve yeme içme fırsatlarını kaçırma',
    badge: 'Süreli teklif',
    image: AppImages.burgerHero,
    actionLabel: "Happy Hour'a Git",
    screen: SpetoScreen.happyHourList,
  ),
  HomeHeroData(
    title: 'Özel Gel-Al Menüler',
    subtitle: 'Hızlı, sıcak ve öğrenci dostu',
    badge: 'Kadıköy çevresi',
    image: AppImages.burger,
    actionLabel: 'Restoranlara Git',
    screen: SpetoScreen.restaurantList,
  ),
];

const List<HomeQuickFilter> homeQuickFilters = <HomeQuickFilter>[
  HomeQuickFilter(
    label: 'Yakında',
    icon: Icons.near_me_rounded,
    screen: SpetoScreen.restaurantList,
  ),
  HomeQuickFilter(
    label: 'Pro ile',
    icon: Icons.workspace_premium_rounded,
    screen: SpetoScreen.proPoints,
    highlight: true,
  ),
  HomeQuickFilter(
    label: 'Gece',
    icon: Icons.nightlife_rounded,
    screen: SpetoScreen.eventsDiscovery,
  ),
  HomeQuickFilter(
    label: 'Market',
    icon: Icons.shopping_basket_rounded,
    screen: SpetoScreen.marketList,
  ),
];

// ---------------------------------------------------------------------------
// Screen link lists (from the app-map / discovery hub)
// ---------------------------------------------------------------------------

const List<ScreenLink> authLinks = <ScreenLink>[
  ScreenLink(
    'Market Keşfi Tanıtımı',
    'Animasyonlu tanıtım akışı 1',
    SpetoScreen.onboardingMarket,
  ),
  ScreenLink(
    'Restoran ve Gel-Al Tanıtımı',
    'Animasyonlu tanıtım akışı 2',
    SpetoScreen.onboardingRestaurant,
  ),
  ScreenLink(
    'Süreli Fırsatlar Tanıtımı',
    'Animasyonlu tanıtım akışı 3',
    SpetoScreen.onboardingDeals,
  ),
  ScreenLink(
    'Öğrenci Dostu Tanıtım',
    'Animasyonlu tanıtım akışı 4',
    SpetoScreen.onboardingStudent,
  ),
  ScreenLink(
    'Pro Puan Takibi Tanıtımı',
    'Animasyonlu tanıtım akışı 5',
    SpetoScreen.onboardingPro,
  ),
  ScreenLink('Giriş Yap', 'Giriş ekranı', SpetoScreen.login),
  ScreenLink('Kayıt Ol', 'Hesap oluşturma ekranı', SpetoScreen.register),
  ScreenLink(
    'Şifremi Unuttum',
    'Şifre yenileme ekranı',
    SpetoScreen.forgotPassword,
  ),
  ScreenLink(
    'OTP Doğrulama',
    'Tek kullanımlık kod doğrulama ekranı',
    SpetoScreen.otpVerification,
  ),
  ScreenLink('Şifre Sıfırla', 'Yeni şifre formu', SpetoScreen.resetPassword),
  ScreenLink(
    'Şifre Başarı Ekranı',
    'Şifre güncelleme başarı ekranı',
    SpetoScreen.passwordSuccess,
  ),
];

const List<ScreenLink> marketLinks = <ScreenLink>[
  ScreenLink('Ana Sayfa', 'Koyu tema ana gösterge ekranı', SpetoScreen.home),
  ScreenLink(
    'Market Listesi',
    'Market keşif ve sepet listesi',
    SpetoScreen.marketList,
  ),
  ScreenLink(
    'Sepet ve Ödeme',
    'Market siparişi ödeme akışı',
    SpetoScreen.happyHourCheckout,
  ),
  ScreenLink(
    'Restoran Listesi',
    'Restoran liste görünümü',
    SpetoScreen.restaurantList,
  ),
  ScreenLink(
    'Restoran Detayı',
    'Restoran detay görünümü',
    SpetoScreen.restaurantDetail,
  ),
  ScreenLink('Ürün Detayı', 'Menü ürün detayları', SpetoScreen.menuItemDetail),
];

const List<ScreenLink> eventLinks = <ScreenLink>[
  ScreenLink(
    'Etkinlik Keşif',
    'Etkinlik keşif listesi',
    SpetoScreen.eventsDiscovery,
  ),
  ScreenLink(
    'Etkinlik Detayı',
    'Etkinlik detay görünümü',
    SpetoScreen.eventDetail,
  ),
  ScreenLink(
    'Dijital Bilet',
    'Dijital etkinlik bileti',
    SpetoScreen.digitalTicket,
  ),
  ScreenLink('Bilet Başarı', 'Bilet başarı ekranı', SpetoScreen.ticketSuccess),
];

const List<ScreenLink> orderLinks = <ScreenLink>[
  ScreenLink(
    'Sipariş Geçmişi',
    'Sipariş geçmişi listesi',
    SpetoScreen.orderHistory,
  ),
  ScreenLink(
    'Sipariş Takibi',
    'Sipariş takip ekranı',
    SpetoScreen.orderTracking,
  ),
  ScreenLink('Detaylı Fiş', 'Detaylı sipariş fişi', SpetoScreen.orderReceipt),
];

const List<ScreenLink> profileLinks = <ScreenLink>[
  ScreenLink('Adreslerim', 'Adreslerim (Karanlık)', SpetoScreen.addresses),
  ScreenLink(
    'Ödeme Yöntemleri',
    'Ödeme Yöntemleri (Karanlık)',
    SpetoScreen.paymentMethods,
  ),
  ScreenLink(
    'Hesap Ayarları',
    'Hesap ayarları ekranı',
    SpetoScreen.accountSettings,
  ),
  ScreenLink(
    'Yardım Merkezi',
    'Yardım Merkezi (Karanlık)',
    SpetoScreen.helpCenter,
  ),
  ScreenLink(
    'Uygulama Haritası',
    'Uygulama Haritası ve Navigasyon Merkezi',
    SpetoScreen.appMap,
  ),
];

// ---------------------------------------------------------------------------
// Re-usable ScreenLink (mirrors the one in onboarding_data.dart)
// ---------------------------------------------------------------------------

class ScreenLink {
  const ScreenLink(this.label, this.subtitle, this.screen);

  final String label;
  final String subtitle;
  final SpetoScreen screen;
}

// ---------------------------------------------------------------------------
// Filter chips shared across home / happy-hour
// ---------------------------------------------------------------------------

const List<String> filterChips = <String>['Hepsi', 'Burger', 'Tatlı', 'Kahve'];
