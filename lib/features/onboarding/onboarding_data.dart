import 'package:flutter/material.dart';

import '../../core/navigation/screen_enum.dart';

class OnboardingModel {
  const OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.primary,
    required this.icon,
    required this.gradient,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final String caption;
  final String primary;
  final IconData icon;
  final LinearGradient gradient;
  final SpetoScreen screen;
}

class ScreenLink {
  const ScreenLink(this.label, this.subtitle, this.screen);

  final String label;
  final String subtitle;
  final SpetoScreen screen;
}

const List<OnboardingModel> onboardingModels = <OnboardingModel>[
  OnboardingModel(
    title: 'Mahalle esnafı ve marketleri\ntek ekranda topla',
    subtitle:
        'Manavdan süpermarkete tüm yerel dükkanları listele, taze ürünlerle dolu sepetini güvenle doldur.',
    caption: 'MARKET',
    primary: 'İleri',
    icon: Icons.shopping_basket_rounded,
    gradient: LinearGradient(
      colors: <Color>[Color(0xFFFFC629), Color(0xFFFF8A00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    screen: SpetoScreen.onboardingMarket,
  ),
  OnboardingModel(
    title: 'Restoran keyfini dilediğin\nyere hızla taşı',
    subtitle:
        'Menünü uygulamadan seç, paketini restorana vardığında sıraya girmeden hemen teslim al',
    caption: 'RESTORAN',
    primary: 'İleri',
    icon: Icons.local_dining_rounded,
    gradient: LinearGradient(
      colors: <Color>[Color(0xFF2A0D0D), Color(0xFFFF5A1F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    screen: SpetoScreen.onboardingRestaurant,
  ),
  OnboardingModel(
    title: 'Yakınındaki flaş indirimleri\nanında değerlendir',
    subtitle:
        'Sadece belirli saatlerde geçerli olan dev fırsatları kaçırma; avantajlı ürünleri yerinden teslim al veya mekanda tadını çıkar.',
    caption: 'HAPPY HOUR',
    primary: 'İleri',
    icon: Icons.local_fire_department_rounded,
    gradient: LinearGradient(
      colors: <Color>[Color(0xFFFF214F), Color(0xFFFF8A00)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    screen: SpetoScreen.onboardingDeals,
  ),
  OnboardingModel(
    title: 'Öğrenci dostu avantajları\ngörünür kıl',
    subtitle:
        'Öğrenci kimliğini dijitalden doğrula, sadece gençlere özel tanımlanan dev fırsatları dükkandan kap.',
    caption: 'ÖĞRENCİ',
    primary: 'İleri',
    icon: Icons.school_rounded,
    gradient: LinearGradient(
      colors: <Color>[Color(0xFF422B22), Color(0xFFFF5F55)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    screen: SpetoScreen.onboardingStudent,
  ),
  OnboardingModel(
    title: 'Pro puanlarını hemen\nbiletlere dönüştür',
    subtitle:
        'Alışverişlerinden gelen puanları biriktir, hayalindeki bileti uygulama içinden saniyeler içinde al.',
    caption: 'PRO',
    primary: 'Hemen Başla',
    icon: Icons.stars_rounded,
    gradient: LinearGradient(
      colors: <Color>[Color(0xFF261200), Color(0xFFFFA800)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    screen: SpetoScreen.onboardingPro,
  ),
];
