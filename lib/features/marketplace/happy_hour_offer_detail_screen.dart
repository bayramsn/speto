import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/constants/app_images.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';

class HappyHourOfferDetailScreen extends StatelessWidget {
  const HappyHourOfferDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return Scaffold(
      backgroundColor: Palette.aubergine,
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    SpetoImage(
                      url: AppImages.burgerHero,
                      height: 320,
                      borderRadius: 0,
                      heroTag: AppImages.burgerHero,
                      overlay: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.black.withValues(alpha: 0.15),
                              Palette.aubergine,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            roundButton(
                              context,
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            roundButton(
                              context,
                              icon: Icons.share_outlined,
                              onTap: () => copyShareLinkToClipboard(
                                context,
                                path: 'offers/firsat-saati-burger',
                                successMessage:
                                    'Fırsat bağlantısı panoya kopyalandı.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: const LabelChip(
                        label: 'Happy Hour Özel',
                        color: Palette.crimson,
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Palette.aubergine,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Column(
                            children: <Widget>[
                              Text(
                                'TEKLİFİN BİTMESİNE',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Palette.crimson.withValues(
                                        alpha: 0.8,
                                      ),
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _timeBox(context, '01', 'Saat'),
                                  _separator(context),
                                  _timeBox(context, '45', 'Dak', active: true),
                                  _separator(context),
                                  _timeBox(context, '22', 'Sn'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Mega Burger\nMenüsü',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Text(
                              '85 TL',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Palette.crimson,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '120 TL',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Palette.faint,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Palette.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '+50 Puan',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Palette.orange,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, color: Color(0x22FFFFFF)),
                        Text(
                          'AÇIKLAMA',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Palette.muted,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tam kıvamında ızgaralanmış çift dana köftesi, erimiş cheddar peyniri, karamelize soğan, taze marul ve özel SepetPro sosuyla hazırlanır. Çıtır patates ve soğuk içecek ile servis edilir.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Palette.soft, height: 1.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Devamını oku',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Palette.crimson,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 22),
                        SpetoCard(
                          radius: 16,
                          color: Palette.cardWarm,
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Palette.crimson.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: Palette.crimson,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Kadıköy Merkez Şubesi',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '0,4 km uzaklıkta • 23:00\'a kadar açık',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Palette.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.navigation_outlined,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SpetoImage(
                                url:
                                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1000&q=80',
                                height: 96,
                                borderRadius: 12,
                                overlay: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Palette.red,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.location_pin,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Gel-Al',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: Palette.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bu fiyattan yalnızca 5 adet kaldı!',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Palette.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: Palette.cardWarm.withValues(alpha: 0.94),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Toplam Tutar',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Palette.muted),
                        ),
                        Text(
                          '85 TL',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SpetoPrimaryButton(
                        label: appState.hasCart
                            ? 'Sepete Ekle ve Devam Et'
                            : 'Hemen Al',
                        icon: Icons.arrow_forward_rounded,
                        onTap: () => addCartItemAndOpenCheckout(
                          context,
                          megaBurgerCartItem(),
                          notice: 'Mega Burger Menü sepete eklendi.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(
    BuildContext context,
    String value,
    String label, {
    bool active = false,
  }) {
    return Column(
      children: <Widget>[
        Container(
          width: 48,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.cardWarm,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: active ? Palette.crimson : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Palette.muted),
        ),
      ],
    );
  }

  Widget _separator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

