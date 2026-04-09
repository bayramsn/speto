import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../shared/widgets/widgets.dart';
import 'restaurant_data.dart';
import '../../features/events/event_data.dart';
import 'restaurant_detail_screen.dart';

const List<String> _restaurantFilters = <String>[
  'Sıralama',
  'Puanı Yüksek',
  'Öğrenci',
];

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  int _selectedFilterIndex = 0;

  List<RestaurantCardData> get _visibleRestaurants {
    final List<RestaurantCardData> restaurants = List<RestaurantCardData>.of(
      restaurantCards,
    );
    switch (_selectedFilterIndex) {
      case 1:
        return restaurants
            .where((RestaurantCardData item) => item.ratingValue >= 4.8)
            .toList()
          ..sort(
            (RestaurantCardData a, RestaurantCardData b) =>
                b.ratingValue.compareTo(a.ratingValue),
          );
      case 2:
        return restaurants
            .where((RestaurantCardData item) => item.studentFriendly)
            .toList();
      default:
        return restaurants;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final List<RestaurantCardData> data = _visibleRestaurants;
    return SpetoScreenScaffold(
      showBack: false,
      showBottomNav: true,
      activeNav: NavSection.explore,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 12),
            Text(
              'Gel-Al Noktası',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Palette.muted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Text(
                  appState.primaryAddress?.label ?? 'Şube seçin',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Palette.red,
                ),
                const Spacer(),
                roundButton(
                  context,
                  icon: Icons.notifications_none_rounded,
                  onTap: () => openScreen(context, SpetoScreen.helpCenter),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => showDiscoverySearchSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Palette.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.search_rounded, color: Palette.faint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Restoran veya yemek ara...',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Palette.faint),
                      ),
                    ),
                    const Icon(Icons.tune_rounded, color: Palette.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _restaurantFilters.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 10),
                itemBuilder: (_, int index) {
                  final bool active = index == _selectedFilterIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? Palette.cardWarm : Palette.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? Palette.red.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (index < 3)
                            Icon(
                              Icons.tune_rounded,
                              size: 12,
                              color: active ? Palette.red : Palette.soft,
                            ),
                          if (index < 3) const SizedBox(width: 6),
                          Text(
                            _restaurantFilters[index],
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: active ? Colors.white : Palette.soft,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Yakındaki Restoranlar',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${data.length} mekan • ${_restaurantFilters[_selectedFilterIndex]} filtresi aktif',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              SpetoCard(
                radius: 20,
                color: Palette.cardWarm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Bu filtre için sonuç bulunamadı',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Farklı bir filtre seçerek daha fazla restoran görüntüleyebilirsin.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Palette.soft,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...data.map(
                (RestaurantCardData item) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      spetoRoute(
                        RestaurantDetailScreen(restaurantId: item.id),
                      ),
                    ),
                    child: SpetoCard(
                      padding: EdgeInsets.zero,
                      radius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Stack(
                            children: <Widget>[
                              SpetoImage(
                                url: item.image,
                                height: 176,
                                borderRadius: 24,
                                heroTag: item.image,
                              ),
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Palette.base.withValues(
                                      alpha: 0.74,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.promo,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    final bool willFavorite = !appState
                                        .isRestaurantFavorite(item.id);
                                    appState.toggleRestaurantFavorite(item.id);
                                    SpetoToast.show(
                                      context,
                                      message: willFavorite
                                          ? '${item.title} favorilere eklendi.'
                                          : '${item.title} favorilerden çıkarıldı.',
                                      icon: willFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.heart_broken_outlined,
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0x80000000),
                                    child: Icon(
                                      appState.isRestaurantFavorite(item.id)
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 16,
                                      color:
                                          appState.isRestaurantFavorite(item.id)
                                          ? Palette.red
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Palette.cardWarm,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            item.ratingLabel,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 12,
                                            color: Palette.orange,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    _metaTag(
                                      context,
                                      Icons.room_outlined,
                                      item.cuisine,
                                    ),
                                    const SizedBox(width: 12),
                                    _metaTag(
                                      context,
                                      Icons.timer_outlined,
                                      '${item.etaLabel} hazır',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: <Widget>[
                                          _metaTag(
                                            context,
                                            Icons.shopping_bag_outlined,
                                            'Gel-Al',
                                          ),
                                          _metaTag(
                                            context,
                                            Icons.remove_shopping_cart_rounded,
                                            'Minimum Sepet Tutarı Yok',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Menüyü Aç',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Palette.soft),
                                    ),
                                  ],
                                ),
                              ],
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
      ),
    );
  }

  Widget _metaTag(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: Palette.muted),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Palette.soft),
        ),
      ],
    );
  }
}

void showDiscoverySearchSheet(BuildContext context) {
  // Placeholder for discovery search sheet
}
