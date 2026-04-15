import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/data/default_data.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import 'restaurant_data.dart';
import 'restaurant_detail_screen.dart';

class MenuItemDetailScreen extends StatelessWidget {
  const MenuItemDetailScreen({
    super.key,
    this.item,
    this.vendor = 'Burger King Kadıköy',
  });

  final MenuListItem? item;
  final String vendor;

  @override
  Widget build(BuildContext context) {
    final MenuListItem? resolvedItem = item;
    if (resolvedItem == null) {
      return SpetoScreenScaffold(
        title: 'Ürün Detayı',
        background: Palette.aubergine,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: SpetoCard(
            radius: 24,
            color: Palette.cardWarm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Gösterilecek ürün bulunamadı',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ürün katalogdan kaldırılmış olabilir veya detay verisi henüz yüklenmemiş olabilir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Palette.soft,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                SpetoPrimaryButton(
                  label: 'Restoranlara Dön',
                  icon: Icons.storefront_outlined,
                  onTap: () =>
                      openRootScreen(context, SpetoScreen.restaurantList),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final List<MapEntry<String, IconData>> highlights = menuHighlightsFor(
      resolvedItem,
    );
    final double itemPrice = menuBasePrice(resolvedItem.price);
    return Scaffold(
      backgroundColor: Palette.aubergine,
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    SpetoImage(
                      url: resolvedItem.image,
                      height: 320,
                      borderRadius: 0,
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
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                                icon: Icons.tune_rounded,
                                onTap: () => showMenuCustomizerSheet(
                                  context,
                                  resolvedItem,
                                  vendor: vendor,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                resolvedItem.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                              ),
                            ),
                            Text(
                              resolvedItem.price,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Palette.red,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          resolvedItem.description,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Palette.soft, height: 1.7),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ürün Özeti',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Palette.muted,
                                letterSpacing: 1,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: highlights
                              .map(
                                (MapEntry<String, IconData> entry) => InfoTag(
                                  label: entry.key,
                                  icon: entry.value,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        SpetoCard(
                          radius: 20,
                          color: Palette.cardWarm,
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Palette.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: Palette.red,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      vendor,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tahmini hazırlanma süresi 12 dk. Gel-Al ve hızlı ödeme ile uyumlu.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Palette.soft),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SpetoCard(
                          radius: 20,
                          color: Palette.cardWarm,
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Palette.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Palette.orange,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Özelleştirme Açık',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Boyut, ekstra malzeme ve servis tercihlerini özelleştir ekranından düzenleyebilirsin.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Palette.soft,
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () =>
                              openRootScreen(context, SpetoScreen.proPoints),
                          child: SpetoCard(
                            radius: 20,
                            color: Palette.cardWarm,
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Palette.green.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Palette.green,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Siparişte Pro avantajı',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bu ürünü içeren restoran siparişlerinde Pro puan kazanma fırsatını görebilirsin.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Palette.soft),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Palette.soft,
                                ),
                              ],
                            ),
                          ),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                color: Palette.aubergine,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => showMenuCustomizerSheet(
                          context,
                          resolvedItem,
                          vendor: vendor,
                        ),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Palette.cardWarm,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Özelleştir',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SpetoPrimaryButton(
                        label: 'Sepete Ekle • ${formatPrice(itemPrice)}',
                        onTap: () => addCartItemAndOpenCheckout(
                          context,
                          SpetoCartItem(
                            id: 'detail-${resolvedItem.title.toLowerCase().replaceAll(' ', '-')}',
                            vendor: vendor,
                            title: resolvedItem.title,
                            image: resolvedItem.image,
                            unitPrice: itemPrice,
                          ),
                          notice: '${resolvedItem.title} sepete eklendi.',
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
}

class InfoTag extends StatelessWidget {
  const InfoTag({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Palette.cardWarm,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Palette.soft),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
