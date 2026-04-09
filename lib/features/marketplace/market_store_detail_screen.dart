import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/restaurant/restaurant_data.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';
import '../../features/restaurant/menu_item_detail_screen.dart';
import 'market_store_screen.dart';

class MarketStoreDetailScreen extends StatefulWidget {
  const MarketStoreDetailScreen({super.key, required this.store});

  final MarketStoreData store;

  @override
  State<MarketStoreDetailScreen> createState() =>
      MarketStoreDetailScreenState();
}

class MarketStoreDetailScreenState extends State<MarketStoreDetailScreen> {
  late String _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.store.sections.keys.first;
  }

  void _addMarketItem(
    BuildContext context, {
    required String id,
    required String title,
    required String image,
    required double price,
    required String notice,
  }) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    HapticFeedback.lightImpact();
    final bool added = appState.addToCart(
      SpetoCartItem(
        id: id,
        vendor: widget.store.title,
        title: title,
        image: image,
        unitPrice: price,
      ),
    );
    if (!added) {
      SpetoToast.show(
        context,
        message: appState.stockWarningForProduct(id) ?? 'Ürün stokta yok.',
        icon: Icons.inventory_2_outlined,
      );
      return;
    }
    SpetoToast.show(
      context,
      message: notice,
      icon: Icons.shopping_basket_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final MarketStoreData store = widget.store;
    final List<String> sectionLabels = store.sections.keys.toList();
    final List<MenuListItem> selectedItems =
        store.sections[_selectedSection] ?? const <MenuListItem>[];
    return Scaffold(
      backgroundColor: Palette.aubergine,
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 296,
                pinned: true,
                backgroundColor: Palette.aubergine,
                leadingWidth: 72,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: roundButton(
                    context,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: roundButton(
                      context,
                      icon: Icons.share_outlined,
                      onTap: () => copyShareLinkToClipboard(
                        context,
                        path: 'markets/${slugify(store.title)}',
                        successMessage: 'Market bağlantısı panoya kopyalandı.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 8,
                      right: 16,
                    ),
                    child: roundButton(
                      context,
                      icon: Icons.location_on_outlined,
                      onTap: () => openScreen(context, SpetoScreen.appMap),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      SpetoImage(
                        url: store.image,
                        height: 296,
                        borderRadius: 0,
                        heroTag: store.heroTag,
                        overlay: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Palette.base.withValues(alpha: 0.18),
                                Palette.aubergine,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 38,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            LabelChip(
                              label: store.badge,
                              background: Palette.orange.withValues(
                                alpha: 0.18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              store.title,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              store.promoLabel,
                              style: const TextStyle(color: Palette.soft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: appState.hasCart ? 120 : 40),
                sliver: SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: const BoxDecoration(
                        color: Palette.aubergine,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            store.heroTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            store.heroSubtitle,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Palette.soft, height: 1.6),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: <Widget>[
                              IconMetric(
                                icon: Icons.star_rounded,
                                value: store.ratingLabel,
                                label: 'Puan',
                              ),
                              const SizedBox(width: 12),
                              IconMetric(
                                icon: Icons.room_outlined,
                                value: store.distanceLabel,
                                label: 'Mesafe',
                              ),
                              const SizedBox(width: 12),
                              IconMetric(
                                icon: Icons.schedule_rounded,
                                value: store.etaLabel,
                                label: 'Hazır',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SpetoCard(
                            radius: 22,
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF2B1D16),
                                Color(0xFF151416),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Palette.orange.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_basket_rounded,
                                    color: Palette.orange,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        store.bundleTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        store.bundleDescription,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Palette.soft),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _addMarketItem(
                                    context,
                                    id: 'market-bundle-${store.id}',
                                    title: store.bundleTitle,
                                    image: store.image,
                                    price: store.bundlePriceValue,
                                    notice:
                                        '${store.bundleTitle} sepete eklendi.',
                                  ),
                                  child: Text(store.bundlePrice),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: store.highlights
                                .map(
                                  (StoreHighlightData entry) => InfoTag(
                                    label: entry.label,
                                    icon: entry.icon,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 46,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: sectionLabels.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(width: 12),
                              itemBuilder: (BuildContext context, int index) {
                                final String label = sectionLabels[index];
                                final bool active = label == _selectedSection;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedSection = label),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Palette.orange.withValues(
                                              alpha: 0.12,
                                            )
                                          : Palette.cardWarm,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: active
                                            ? Palette.orange.withValues(
                                                alpha: 0.24,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.04,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: active
                                                ? Palette.orange
                                                : Palette.soft,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '$_selectedSection kategorisi • ${selectedItems.length} ürün',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Palette.soft),
                          ),
                          const SizedBox(height: 20),
                          ...selectedItems.map(
                            (MenuListItem item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SpetoCard(
                                radius: 22,
                                color: Palette.cardWarm,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Palette.soft,
                                                  height: 1.3,
                                                ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: <Widget>[
                                              Text(
                                                item.price,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: Palette.orange,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                              const Spacer(),
                                              TextButton.icon(
                                                onPressed: () => _addMarketItem(
                                                  context,
                                                  id: 'market-product-${store.id}-${slugify(item.title)}',
                                                  title: item.title,
                                                  image: item.image,
                                                  price: menuBasePrice(
                                                    item.price,
                                                  ),
                                                  notice:
                                                      '${item.title} sepete eklendi.',
                                                ),
                                                icon: const Icon(
                                                  Icons
                                                      .add_shopping_cart_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text('Ekle'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        item.image,
                                        width: 94,
                                        height: 94,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                              BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace,
                                            ) => Container(
                                              width: 94,
                                              height: 94,
                                              color: Palette.card,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (appState.hasCart)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: Palette.cardWarm.withValues(alpha: 0.96),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${appState.cartCount} ürün sepette',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatPrice(appState.cartTotal),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Palette.orange,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SpetoPrimaryButton(
                          label: 'Sepeti Aç',
                          onTap: () => openRootScreen(
                            context,
                            SpetoScreen.happyHourCheckout,
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

class ListingCardData {
  const ListingCardData({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.price,
    required this.image,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String price;
  final String image;
}
