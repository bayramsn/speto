import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../shared/widgets/widgets.dart';
import 'home_data.dart';

Future<void> showDiscoverySearchSheet(BuildContext context) {
  final BuildContext rootContext = context;
  final List<Map<String, Object>> suggestions = <Map<String, Object>>[
    <String, Object>{
      'title': 'Burger Yiyelim',
      'subtitle': 'Yakınında sıcak gel-al menüler',
      'icon': Icons.lunch_dining_rounded,
      'screen': SpetoScreen.restaurantList,
    },
    <String, Object>{
      'title': "Galata'da Caz Gecesi",
      'subtitle': 'Pro ile açılan etkinlik',
      'icon': Icons.music_note_rounded,
      'screen': SpetoScreen.eventDetail,
    },
    <String, Object>{
      'title': 'Fırsat saati kampanyaları',
      'subtitle': 'Kısa süreli kampanyalar',
      'icon': Icons.local_fire_department_rounded,
      'screen': SpetoScreen.happyHourList,
    },
  ];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.94,
        child: Container(
          decoration: const BoxDecoration(
            color: Palette.base,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Keşfet ve Ara',
                            style: context.spetoSectionTitleStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                        roundButton(
                          context,
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.search_rounded, color: Palette.soft),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Burger, kampanya, etkinlik...',
                              style: context.spetoDescriptionStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_voice_outlined,
                            color: Palette.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hızlı Geçiş',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Palette.muted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: homeQuickFilters.map((HomeQuickFilter item) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            openScreen(rootContext, item.screen);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: item.highlight
                                  ? Palette.cardWarm
                                  : Palette.card,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: item.highlight
                                    ? Palette.orange.withValues(alpha: 0.24)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  item.icon,
                                  size: 16,
                                  color: item.highlight
                                      ? Palette.orange
                                      : Palette.soft,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.label,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: item.highlight
                                            ? Palette.orange
                                            : Palette.soft,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Trend Aramalar',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Palette.muted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: suggestions.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final Map<String, Object> item = suggestions[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              openScreen(
                                rootContext,
                                item['screen']! as SpetoScreen,
                              );
                            },
                            child: SpetoCard(
                              radius: 22,
                              color: Palette.cardWarm,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Palette.red.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      item['icon']! as IconData,
                                      color: Palette.red,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          item['title']! as String,
                                          style: context.spetoCardTitleStyle(),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['subtitle']! as String,
                                          style: context.spetoMetaStyle(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_outward_rounded,
                                    color: Palette.soft,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late final PageController _heroController = PageController(
    viewportFraction: 0.9,
  );
  int _heroIndex = 0;
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return SpetoScreenScaffold(
      showBack: false,
      showBottomNav: true,
      activeNav: NavSection.explore,
      background: Palette.ink,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Palette.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -70,
            top: 240,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Palette.orange.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          RefreshIndicator(
            color: Palette.red,
            backgroundColor: Palette.cardWarm,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
              child: _isRefreshing
                  ? _buildSkeletonContent()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'İyi akşamlar, ${appState.displayName.split(' ').first}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 1.05,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.place_outlined,
                                        color: Palette.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        appState.primaryAddress?.label ??
                                            'Gel-al noktası seçin',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Palette.soft),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _floatingIconButton(
                              context,
                              icon: Icons.search_rounded,
                              onTap: () => showDiscoverySearchSheet(context),
                            ),
                            const SizedBox(width: 10),
                            _floatingIconButton(
                              context,
                              icon: Icons.map_outlined,
                              onTap: () =>
                                  openScreen(context, SpetoScreen.appMap),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        GestureDetector(
                          onTap: () =>
                              openRootScreen(context, SpetoScreen.proPoints),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.09),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Palette.orange.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: Palette.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            'Pro Cüzdan',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '2 etkinlik açabilecek bakiyen hazır.',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Palette.soft,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Palette.orange.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            formatPoints(
                                              appState.proPointsBalance,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: Palette.orange,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                            color: Palette.orange,
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
                        const SizedBox(height: 28),
                        const SectionHeader(
                          title: 'Hızlı Alanlar',
                          action: 'TÜMÜ',
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _serviceCard(
                                context,
                                title: 'Market',
                                subtitle:
                                    'Mahalle marketlerini tek ekranda keşfet',
                                image: AppImages.market,
                                badge: 'Yeni',
                                onTap: () =>
                                    openScreen(context, SpetoScreen.marketList),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _serviceCard(
                                context,
                                title: 'Restoran',
                                subtitle: 'Canlı menü ve hızlı gel-al',
                                image: AppImages.burger,
                                badge: '15 dk',
                                onTap: () => openScreen(
                                  context,
                                  SpetoScreen.restaurantList,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _serviceCard(
                                context,
                                title: 'Happy Hour',
                                subtitle:
                                    'Saatlik sıcak teklifler ve hızlı sepetler',
                                image: AppImages.burgerHero,
                                badge: '00:45',
                                onTap: () => openScreen(
                                  context,
                                  SpetoScreen.happyHourList,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _serviceCard(
                                context,
                                title: 'Etkinlikler',
                                subtitle: 'Pro ile açılan sosyal akış',
                                image: AppImages.nightlife,
                                badge: 'Pro',
                                onTap: () => openScreen(
                                  context,
                                  SpetoScreen.eventsDiscovery,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 430,
                          child: PageView.builder(
                            controller: _heroController,
                            onPageChanged: (int value) {
                              setState(() {
                                _heroIndex = value;
                              });
                            },
                            itemCount: homeHeroCards.length,
                            itemBuilder: (BuildContext context, int index) {
                              final HomeHeroData hero = homeHeroCards[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == homeHeroCards.length - 1
                                      ? 0
                                      : 14,
                                ),
                                child: GestureDetector(
                                  onTap: () => openScreen(context, hero.screen),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Palette.red.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 26,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        SpetoImage(
                                          url: hero.image,
                                          height: 430,
                                          borderRadius: 40,
                                          overlay: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: <Color>[
                                                  Colors.black.withValues(
                                                    alpha: 0.10,
                                                  ),
                                                  Colors.black.withValues(
                                                    alpha: 0.74,
                                                  ),
                                                  Colors.black.withValues(
                                                    alpha: 0.92,
                                                  ),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 28,
                                          right: 28,
                                          top: 26,
                                          child: Row(
                                            children: <Widget>[
                                              LabelChip(
                                                label: hero.badge,
                                                background: Colors.white
                                                    .withValues(alpha: 0.14),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Palette.base
                                                      .withValues(alpha: 0.44),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  '${index + 1}/${homeHeroCards.length}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: 28,
                                          right: 28,
                                          bottom: 28,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                hero.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      height: 1.0,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                hero.subtitle,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      color: Palette.soft,
                                                      height: 1.5,
                                                    ),
                                              ),
                                              const SizedBox(height: 18),
                                              Row(
                                                children: <Widget>[
                                                  _heroMetric(
                                                    context,
                                                    icon: Icons
                                                        .local_fire_department,
                                                    label: 'Canlı kampanya',
                                                  ),
                                                  const SizedBox(width: 10),
                                                  _heroMetric(
                                                    context,
                                                    icon: Icons
                                                        .workspace_premium_rounded,
                                                    label: 'Özel erişim',
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              SpetoPrimaryButton(
                                                label: hero.actionLabel,
                                                icon:
                                                    Icons.arrow_forward_rounded,
                                                onTap: () => openScreen(
                                                  context,
                                                  hero.screen,
                                                ),
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
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(
                            homeHeroCards.length,
                            (int index) {
                              final bool active = index == _heroIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: active ? 30 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active ? Palette.red : Palette.border,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header skeleton
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 200,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Palette.cardWarm,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SpetoShimmer(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 160,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Palette.cardWarm,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const SpetoShimmer(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        // Search skeleton
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Palette.cardWarm,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const SpetoShimmer(),
        ),
        const SizedBox(height: 16),
        // Chips skeleton
        SizedBox(
          height: 42,
          child: Row(
            children: List<Widget>.generate(4, (int i) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 76,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Palette.cardWarm,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SpetoShimmer(),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 26),
        // Hero card skeleton
        Container(
          height: 430,
          decoration: BoxDecoration(
            color: Palette.cardWarm,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const SpetoShimmer(),
        ),
        const SizedBox(height: 28),
        // Service cards skeleton
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                height: 184,
                decoration: BoxDecoration(
                  color: Palette.cardWarm,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const SpetoShimmer(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 184,
                decoration: BoxDecoration(
                  color: Palette.cardWarm,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const SpetoShimmer(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _floatingIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _heroMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Palette.orange),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String image,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 184,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            SpetoImage(
              url: image,
              height: 184,
              borderRadius: 28,
              overlay: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded, size: 18),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Palette.soft.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w100,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
