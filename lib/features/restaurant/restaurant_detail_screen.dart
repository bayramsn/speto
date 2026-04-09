import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';
import 'restaurant_data.dart';
import '../../features/events/event_data.dart';
import 'menu_item_detail_screen.dart';

class TabChip extends StatelessWidget {
  const TabChip({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Palette.red.withValues(alpha: 0.12)
              : Palette.cardWarm,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? Palette.red.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: active ? Palette.red : Palette.soft,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, this.restaurantId});

  final String? restaurantId;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  String _selectedMenuTab = 'Popüler';

  RestaurantCardData _resolveRestaurant() {
    for (final RestaurantCardData item in restaurantCards) {
      if (item.id == widget.restaurantId) {
        return item;
      }
    }
    if (restaurantCards.isNotEmpty) {
      return restaurantCards.first;
    }
    return defaultRestaurantCatalog().first;
  }

  void _openMenuItemDetail(BuildContext context, MenuListItem item) {
    final RestaurantCardData restaurant = _resolveRestaurant();
    Navigator.of(context).push(
      spetoRoute(MenuItemDetailScreen(item: item, vendor: restaurant.title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RestaurantCardData restaurant = _resolveRestaurant();
    final SpetoAppState appState = SpetoAppScope.of(context);
    final bool isFavorite = appState.isRestaurantFavorite(restaurant.id);
    final Map<String, List<MenuListItem>> menuSections =
        restaurantMenuSectionsFor(restaurant);
    final List<String> menuTabs = menuSections.keys.toList();
    final List<MenuListItem> selectedItems =
        menuSections[_selectedMenuTab] ?? const <MenuListItem>[];
    return Scaffold(
      backgroundColor: Palette.aubergine,
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 288,
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
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Palette.red : Colors.white,
                      onTap: () {
                        final bool willFavorite = !appState
                            .isRestaurantFavorite(restaurant.id);
                        appState.toggleRestaurantFavorite(restaurant.id);
                        SpetoToast.show(
                          context,
                          message: willFavorite
                              ? '${restaurant.title} favorilere eklendi.'
                              : '${restaurant.title} favorilerden çıkarıldı.',
                          icon: willFavorite
                              ? Icons.favorite_rounded
                              : Icons.heart_broken_outlined,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: roundButton(
                      context,
                      icon: Icons.share_outlined,
                      onTap: () => copyShareLinkToClipboard(
                        context,
                        path: 'restaurants/${slugify(restaurant.title)}',
                        successMessage:
                            'Restoran bağlantısı panoya kopyalandı.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      SpetoImage(
                        url: restaurant.image,
                        height: 288,
                        borderRadius: 0,
                        heroTag: restaurant.image,
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
                        bottom: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              restaurant.title,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${restaurant.cuisine} • ${restaurant.etaLabel} hazır • Gel-Al',
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
                padding: const EdgeInsets.only(bottom: 120),
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
                          Row(
                            children: <Widget>[
                              IconMetric(
                                icon: Icons.star_rounded,
                                value: restaurant.ratingLabel,
                                label: 'Puan',
                              ),
                              const SizedBox(width: 12),
                              const IconMetric(
                                icon: Icons.room_outlined,
                                value: '1.2 km',
                                label: 'Mesafe',
                              ),
                              const SizedBox(width: 12),
                              IconMetric(
                                icon: Icons.schedule_rounded,
                                value: restaurant.etaLabel,
                                label: 'Gel-Al',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 46,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: menuTabs.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(width: 12),
                              itemBuilder: (BuildContext context, int index) {
                                final String tab = menuTabs[index];
                                return TabChip(
                                  label: tab,
                                  active: tab == _selectedMenuTab,
                                  onTap: () =>
                                      setState(() => _selectedMenuTab = tab),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '$_selectedMenuTab kategorisi • ${selectedItems.length} ürün',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Palette.soft),
                          ),
                          const SizedBox(height: 24),
                          _menuSection(
                            context,
                            title: _selectedMenuTab,
                            items: selectedItems,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () => openRootScreen(
                          context,
                          SpetoScreen.happyHourCheckout,
                        ),
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: Palette.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${appState.cartCount}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      appState.hasCart
                                          ? 'Sepeti Aç'
                                          : 'Ürün Seç',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 24),
                                child: Text(
                                  formatPrice(appState.cartTotal),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _menuSection(
    BuildContext context, {
    required String title,
    required List<MenuListItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (MenuListItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => _openMenuItemDetail(context, item),
              child: SpetoCard(
                radius: 18,
                color: Palette.cardWarm,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Palette.soft),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Text(
                                item.price,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Palette.red,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    showMenuCustomizerSheet(context, item),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Palette.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.image,
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) => Container(
                              width: 112,
                              height: 112,
                              color: Palette.card,
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
    );
  }
}

Future<void> showMenuCustomizerSheet(
  BuildContext context,
  MenuListItem item, {
  String vendor = 'Burger King Kadıköy',
}) {
  final BuildContext rootContext = context;
  final SpetoAppState appState = SpetoAppScope.of(context);
  String selectedSize = 'Orta';
  final Set<String> selectedExtras = <String>{'Patates'};
  const Map<String, double> sizeAdjustments = <String, double>{
    'Küçük': 0,
    'Orta': 18,
    'Büyük': 34,
  };
  const Map<String, double> extras = <String, double>{
    'Patates': 22,
    'Cheddar Peyniri': 16,
    'Acılı Sos': 8,
  };

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          final double total =
              menuBasePrice(item.price) +
              sizeAdjustments[selectedSize]! +
              selectedExtras.fold<double>(
                0,
                (double sum, String extra) => sum + extras[extra]!,
              );
          return FractionallySizedBox(
            heightFactor: 0.78,
            child: Container(
              decoration: const BoxDecoration(
                color: Palette.base,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Palette.soft, height: 1.5),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Boyut',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Palette.muted,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: sizeAdjustments.keys.map((String size) {
                                final bool active = size == selectedSize;
                                return TabChip(
                                  label:
                                      '$size ${sizeAdjustments[size] == 0 ? '' : '+${formatPrice(sizeAdjustments[size]!)}'}',
                                  active: active,
                                  onTap: () =>
                                      modalSetState(() => selectedSize = size),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Ekstralar',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Palette.muted,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ...extras.entries.map((
                              MapEntry<String, double> entry,
                            ) {
                              final bool selected = selectedExtras.contains(
                                entry.key,
                              );
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == extras.keys.last
                                      ? 0
                                      : 10,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    modalSetState(() {
                                      if (selected) {
                                        selectedExtras.remove(entry.key);
                                      } else {
                                        selectedExtras.add(entry.key);
                                      }
                                    });
                                  },
                                  child: SpetoCard(
                                    radius: 18,
                                    color: selected
                                        ? Palette.cardWarm
                                        : Palette.card,
                                    borderColor: selected
                                        ? Palette.red.withValues(alpha: 0.22)
                                        : Colors.white.withValues(alpha: 0.05),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '+${formatPrice(entry.value)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Palette.orange,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: selected
                                              ? Palette.red
                                              : Palette.faint,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      decoration: BoxDecoration(
                        color: Palette.base,
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'Toplam',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Palette.muted),
                              ),
                              const Spacer(),
                              Text(
                                formatPrice(total),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SpetoPrimaryButton(
                            label:
                                'Sepete Ekle ve Devam Et • ${formatPrice(total)}',
                            icon: Icons.shopping_bag_outlined,
                            onTap: () {
                              final SpetoCartItem
                              configuredItem = SpetoCartItem(
                                id: '${item.title.toLowerCase().replaceAll(' ', '-')}-${selectedSize.toLowerCase()}',
                                vendor: vendor,
                                title:
                                    '${item.title} • $selectedSize ${selectedExtras.isEmpty ? '' : '• ${selectedExtras.join(', ')}'}',
                                image: item.image,
                                unitPrice: total,
                              );
                              final bool added = appState.addToCart(
                                configuredItem,
                              );
                              if (!added) {
                                SpetoToast.show(
                                  rootContext,
                                  message:
                                      appState.stockWarningForProduct(
                                            configuredItem.id,
                                          ) ??
                                          'Ürün stokta yok.',
                                  icon: Icons.inventory_2_outlined,
                                );
                                return;
                              }
                              Navigator.of(context).pop();
                              SpetoToast.show(
                                rootContext,
                                message:
                                    '${item.title} özelleştirilerek sepete eklendi.',
                                icon: Icons.shopping_cart_outlined,
                              );
                              Future<void>.delayed(
                                const Duration(milliseconds: 320),
                                () {
                                  if (rootContext.mounted) {
                                    openRootScreen(
                                      rootContext,
                                      SpetoScreen.happyHourCheckout,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void copyShareLinkToClipboard(
  BuildContext context, {
  required String path,
  required String successMessage,
}) {
  SpetoToast.show(context, message: successMessage, icon: Icons.copy_rounded);
}
