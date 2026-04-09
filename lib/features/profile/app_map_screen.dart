import 'package:flutter/material.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';

class AppMapScreen extends StatelessWidget {
  const AppMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, List<_ScreenLink>>>
    groups = <MapEntry<String, List<_ScreenLink>>>[
      const MapEntry<String, List<_ScreenLink>>('Giriş & Tanıtım', _authLinks),
      const MapEntry<String, List<_ScreenLink>>(
        'Keşfet & Market',
        _marketLinks,
      ),
      const MapEntry<String, List<_ScreenLink>>('Etkinlikler', _eventLinks),
      const MapEntry<String, List<_ScreenLink>>('Sipariş & Sepet', _orderLinks),
      const MapEntry<String, List<_ScreenLink>>(
        'Profil & Yardım',
        _profileLinks,
      ),
    ];
    return SpetoScreenScaffold(
      title: 'Uygulama Haritası',
      background: Palette.base,
      showBottomNav: false,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: groups.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == groups.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SpetoCard(
                radius: 20,
                color: Palette.cardWarm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Renk Paleti',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const <Widget>[
                        PaletteSwatch(color: Palette.red, label: '#FF3D00'),
                        PaletteSwatch(color: Palette.base, label: '#121212'),
                        PaletteSwatch(
                          color: Palette.aubergine,
                          label: '#221010',
                        ),
                        PaletteSwatch(color: Palette.yellow, label: '#FFC629'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          final MapEntry<String, List<_ScreenLink>> group = groups[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == groups.length - 1 ? 0 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  group.key,
                  style: context.spetoSectionTitleStyle(),
                ),
                const SizedBox(height: 12),
                SpetoCard(
                  radius: 20,
                  color: Palette.card,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: group.value
                        .map(
                          (_ScreenLink link) => ListTile(
                            dense: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: const Icon(
                              Icons.circle,
                              size: 10,
                              color: Palette.red,
                            ),
                            title: Text(
                              link.label,
                              style: context.spetoCardTitleStyle(),
                            ),
                            subtitle: Text(
                              link.subtitle,
                              style: context.spetoMetaStyle(),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Palette.muted,
                            ),
                            onTap: () => openScreen(context, link.screen),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScreenLink {
  const _ScreenLink(this.label, this.subtitle, this.screen);

  final String label;
  final String subtitle;
  final SpetoScreen screen;
}

const List<_ScreenLink> _authLinks = <_ScreenLink>[
  _ScreenLink(
    'Onboarding',
    'İlk açılış ve tanıtım ekranı',
    SpetoScreen.onboardingMarket,
  ),
  _ScreenLink('Giriş Yap', 'E-posta veya telefon ile giriş', SpetoScreen.login),
  _ScreenLink(
    'Öğrenci Kayıt',
    'Öğrenci hesabı oluşturma',
    SpetoScreen.studentRegister,
  ),
];

const List<_ScreenLink> _marketLinks = <_ScreenLink>[
  _ScreenLink('Ana Sayfa', 'Keşfet ve kampanya akışı', SpetoScreen.home),
  _ScreenLink(
    'Restoran Listesi',
    'Restoran ve menü tarama',
    SpetoScreen.restaurantList,
  ),
  _ScreenLink(
    'Market Listesi',
    'Market ve süpermarket seçkisi',
    SpetoScreen.marketList,
  ),
  _ScreenLink('Happy Hour', 'Günün fırsat menüleri', SpetoScreen.happyHourList),
];

const List<_ScreenLink> _eventLinks = <_ScreenLink>[
  _ScreenLink(
    'Etkinlik Keşfet',
    'Konser, tiyatro ve festival',
    SpetoScreen.eventsDiscovery,
  ),
  _ScreenLink(
    'Etkinlik Detay',
    'Seçilen etkinliğin bilgileri',
    SpetoScreen.eventDetail,
  ),
  _ScreenLink(
    'Bilet Başarı',
    'Bilet satın alma onay ekranı',
    SpetoScreen.ticketSuccess,
  ),
  _ScreenLink(
    'Dijital Bilet',
    'QR kodlu bilet görünümü',
    SpetoScreen.digitalTicket,
  ),
];

const List<_ScreenLink> _orderLinks = <_ScreenLink>[
  _ScreenLink('Sepetim', 'Ürün ve ödeme özeti', SpetoScreen.happyHourCheckout),
  _ScreenLink(
    'Sipariş Geçmişi',
    'Geçmiş ve aktif siparişler',
    SpetoScreen.orderHistory,
  ),
  _ScreenLink(
    'Sipariş Takip',
    'Canlı sipariş durumu',
    SpetoScreen.orderTracking,
  ),
  _ScreenLink(
    'Sipariş Fişi',
    'Sipariş detay ve puanlama',
    SpetoScreen.orderReceipt,
  ),
];

const List<_ScreenLink> _profileLinks = <_ScreenLink>[
  _ScreenLink(
    'Hesap Ayarları',
    'Profil ve bildirim tercihleri',
    SpetoScreen.accountSettings,
  ),
  _ScreenLink('Adreslerim', 'Kayıtlı gel-al tercihleri', SpetoScreen.addresses),
  _ScreenLink(
    'Ödeme Yöntemleri',
    'Kart ve ödeme araçları',
    SpetoScreen.paymentMethods,
  ),
  _ScreenLink('Pro Puan', 'Puan bakiyesi ve kazanımlar', SpetoScreen.proPoints),
  _ScreenLink(
    'Yardım Merkezi',
    'SSS ve destek kanalları',
    SpetoScreen.helpCenter,
  ),
];

class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
