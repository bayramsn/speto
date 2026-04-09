import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../core/data/default_data.dart';
import '../../shared/widgets/widgets.dart';
import 'market_store_screen.dart';

class MarketListScreen extends StatefulWidget {
  const MarketListScreen({super.key});

  @override
  State<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends State<MarketListScreen> {
  late final PageController _campaignController;
  final Set<String> _favoriteMarketIds = <String>{};
  int _campaignIndex = 0;

  List<MarketCampaignData> get _campaigns => <MarketCampaignData>[
    MarketCampaignData(
      store: marketStores[0],
      title: 'Kahvaltılık ve Manav Raflarında Yeni Haftalık Fırsatlar',
      subtitle:
          'Migros Jet tarafında süt, taze sebze ve hazır tüketim seçkisi bu hafta önde.',
      badge: 'Bu Gece',
      image: MarketImages.freshProduceBanner,
    ),
    MarketCampaignData(
      store: marketStores[1],
      title: 'Premium Şarküteri ve Kahvaltılık Seçkiler',
      subtitle:
          'Macrocenter Express tarafında peynir, meze ve taze reyon akışı öne çıkıyor.',
      badge: 'Sabah Rotası',
      image: MarketImages.breakfastBanner,
    ),
    MarketCampaignData(
      store: marketStores[2],
      title: 'Ekonomik Market Haftası',
      subtitle:
          'File Market günlük ihtiyaçları daha sade ve uygun fiyatlı topluyor.',
      badge: 'Öğrenci Seçkisi',
      image: MarketImages.discountBanner,
    ),
    MarketCampaignData(
      store: marketStores[3],
      title: 'Taze Manav ve Mahalle Alışverişi',
      subtitle:
          'CarrefourSA Mini için manav, kahvaltılık ve hazır gıda seçkisi öne çıkıyor.',
      badge: 'Günlük İhtiyaç',
      image: MarketImages.groceryAisleBanner,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _campaignController = PageController(viewportFraction: 0.93);
  }

  @override
  void dispose() {
    _campaignController.dispose();
    super.dispose();
  }

  void _openStore(BuildContext context, MarketStoreData store) {
    Navigator.of(context).push(spetoRoute(MarketStoreScreen(store: store)));
  }

  void _toggleFavorite(String storeId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favoriteMarketIds.contains(storeId)) {
        _favoriteMarketIds.remove(storeId);
      } else {
        _favoriteMarketIds.add(storeId);
      }
    });
  }

  Widget _storeAvatar(String image, {double size = 52}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipOval(
        child: Image.network(
          image,
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) =>
                  Image.network(
                    AppImages.market,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) => Container(color: Palette.card),
                  ),
        ),
      ),
    );
  }

  Widget _marketInfoLine(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool fillWidth = false,
    int maxLines = 1,
  }) {
    return Container(
      width: fillWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Palette.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketRatingChip(BuildContext context, String ratingLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Palette.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.star_rounded, size: 14, color: Palette.orange),
          const SizedBox(width: 5),
          Text(
            ratingLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Palette.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignCard(BuildContext context, MarketCampaignData campaign) {
    return GestureDetector(
      onTap: () => _openStore(context, campaign.store),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            SpetoImage(
              url: campaign.image,
              height: 184,
              borderRadius: 30,
              overlay: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Palette.base.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  campaign.badge,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Palette.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    campaign.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Palette.soft,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      _storeAvatar(campaign.store.image, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          campaign.store.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Palette.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marketSelectionCard(BuildContext context, MarketStoreData store) {
    final bool favorite = _favoriteMarketIds.contains(store.id);
    return GestureDetector(
      onTap: () => _openStore(context, store),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF2A1814), Color(0xFF17171A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _storeAvatar(store.image),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    store.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _marketRatingChip(context, store.ratingLabel),
                const SizedBox(width: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleFavorite(store.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 19,
                      color: favorite ? Palette.red : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 6,
                  child: _marketInfoLine(
                    context,
                    icon: Icons.remove_shopping_cart_rounded,
                    label: 'Minimum Sepet Tutarı Yok',
                    fillWidth: true,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _marketInfoLine(
                    context,
                    icon: Icons.schedule_rounded,
                    label: store.workingHoursLabel,
                    fillWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MarketCampaignData> campaigns = _campaigns;
    return SpetoScreenScaffold(
      showBack: false,
      showBottomNav: true,
      activeNav: NavSection.explore,
      background: Palette.aubergine,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                roundButton(
                  context,
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Text(
                  'Marketler',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bütün marketleri tek sayfada gör, seç ve mağaza içine gir.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 184,
              child: PageView.builder(
                controller: _campaignController,
                itemCount: campaigns.length,
                onPageChanged: (int index) {
                  setState(() => _campaignIndex = index);
                },
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == campaigns.length - 1 ? 0 : 12,
                    ),
                    child: _campaignCard(context, campaigns[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(campaigns.length, (int index) {
                  final bool active = index == _campaignIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Palette.red : Palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: marketStores.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return _marketSelectionCard(context, marketStores[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MarketCampaignData {
  const MarketCampaignData({
    required this.store,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.image,
  });

  final MarketStoreData store;
  final String title;
  final String subtitle;
  final String badge;
  final String image;
}

