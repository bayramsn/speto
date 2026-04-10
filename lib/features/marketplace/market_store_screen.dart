import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_images.dart';
import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../src/core/models.dart';
import '../../features/restaurant/restaurant_data.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';
import '../../shared/widgets/widgets.dart';

class MarketStoreScreen extends StatefulWidget {
  const MarketStoreScreen({super.key, required this.store});

  final MarketStoreData store;

  @override
  State<MarketStoreScreen> createState() => MarketStoreScreenState();
}

class MarketStoreScreenState extends State<MarketStoreScreen> {
  late final TextEditingController _searchController;
  late String _selectedSection;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        final String nextValue = _searchController.text;
        if (nextValue == _searchQuery) {
          return;
        }
        setState(() {
          _searchQuery = nextValue;
        });
      });
    final Map<String, List<MenuListItem>> sections = _normalizedMarketSections(
      widget.store,
    );
    _selectedSection = sections.keys.isNotEmpty ? sections.keys.first : 'Tümü';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMarketItem(
    BuildContext context,
    MarketStoreData store, {
    required String id,
    required String title,
    required String image,
    required double price,
  }) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    HapticFeedback.lightImpact();
    final bool added = appState.addToCart(
      SpetoCartItem(
        id: id,
        vendor: store.title,
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
      message: '$title sepete eklendi.',
      icon: Icons.shopping_basket_outlined,
    );
  }

  MarketStoreData _resolveStore() {
    return marketStoreById(widget.store.id) ?? widget.store;
  }

  List<MenuListItem> _visibleProducts(
    Map<String, List<MenuListItem>> sections,
    String selectedSection,
  ) {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return sections[selectedSection] ?? const <MenuListItem>[];
    }
    return dedupeMarketItems(
      sections.entries
          .where((MapEntry<String, List<MenuListItem>> entry) {
            return entry.key != 'Tümü';
          })
          .expand((MapEntry<String, List<MenuListItem>> entry) => entry.value)
          .where((item) {
            final String searchable = '${item.title} ${item.description}'
                .toLowerCase();
            return searchable.contains(query);
          })
          .toList(),
    );
  }

  Widget _storeCompactMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Palette.orange),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeThumb(
    String image, {
    required double size,
    required double radius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                Image.network(
                  AppImages.market,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) => Container(
                        width: size,
                        height: size,
                        color: Palette.card,
                      ),
                ),
      ),
    );
  }

  Widget _statPill(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Palette.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Palette.orange.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Palette.orange),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Palette.orange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartFooter(BuildContext context, SpetoAppState appState) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Palette.cardWarm.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(appState.cartTotal),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                onTap: () => openScreen(context, SpetoScreen.happyHourCheckout),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final MarketStoreData store = _resolveStore();
    final Map<String, List<MenuListItem>> sections = _normalizedMarketSections(
      store,
    );
    final List<String> sectionLabels = sections.keys.toList();
    final String effectiveSelectedSection = sectionLabels.contains(_selectedSection)
        ? _selectedSection
        : (sectionLabels.isNotEmpty ? sectionLabels.first : 'Tümü');
    final List<MenuListItem> visibleProducts = _visibleProducts(
      sections,
      effectiveSelectedSection,
    );
    return SpetoScreenScaffold(
      showBack: false,
      showBottomNav: true,
      activeNav: NavSection.explore,
      background: Palette.aubergine,
      footer: appState.hasCart ? _cartFooter(context, appState) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        store.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.promoLabel,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                roundButton(
                  context,
                  icon: Icons.share_outlined,
                  onTap: () => copyShareLinkToClipboard(
                    context,
                    path: 'markets/${slugify(store.title)}',
                    successMessage: 'Market bağlantısı panoya kopyalandı.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Palette.cardWarm,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.search_rounded, color: Palette.soft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      cursorColor: Palette.orange,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Markette ara',
                        hintStyle: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Palette.soft),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Palette.soft,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SpetoCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              radius: 18,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF261914), Color(0xFF131417)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _storeThumb(store.image, size: 38, radius: 11),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          store.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _statPill(
                              context,
                              icon: Icons.star_rounded,
                              label: store.ratingLabel,
                            ),
                            _storeCompactMetric(
                              context,
                              icon: Icons.shopping_bag_outlined,
                              label: 'Gel-Al',
                            ),
                            _storeCompactMetric(
                              context,
                              icon: Icons.remove_shopping_cart_rounded,
                              label: 'Minimum Sepet Tutarı Yok',
                            ),
                            _storeCompactMetric(
                              context,
                              icon: Icons.schedule_rounded,
                              label: store.workingHoursLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sectionLabels.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 22),
                itemBuilder: (BuildContext context, int index) {
                  final String section = sectionLabels[index];
                  final bool active = section == effectiveSelectedSection;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSection = section),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          section,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: active ? Colors.white : Palette.soft,
                                fontWeight: active
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: active ? 28 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Palette.orange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Palette.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _searchQuery.isEmpty
                    ? effectiveSelectedSection
                    : 'Arama Sonuçları',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Palette.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? '${store.title} içinde ${visibleProducts.length} ürün'
                  : '"$_searchQuery" için ${visibleProducts.length} sonuç',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
            ),
            const SizedBox(height: 18),
            if (visibleProducts.isEmpty)
              SpetoCard(
                radius: 24,
                color: Palette.cardWarm,
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.search_off_rounded,
                      size: 34,
                      color: Palette.orange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sonuç bulunamadı',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aramayı temizleyip farklı bir ürün ya da kategori deneyebilirsin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Palette.soft,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.60,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final MenuListItem item = visibleProducts[index];
                  return SpetoCard(
                    radius: 24,
                    color: Palette.cardWarm,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                item.image,
                                height: 118,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                      BuildContext context,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) => Container(
                                      height: 118,
                                      color: Palette.card,
                                    ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _addMarketItem(
                                  context,
                                  store,
                                  id: item.id.isNotEmpty
                                      ? item.id
                                      : 'market-product-${store.id}-${slugify(item.title)}',
                                  title: item.title,
                                  image: item.image,
                                  price: menuBasePrice(item.price),
                                ),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Palette.orange,
                                    shape: BoxShape.circle,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Palette.orange.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Palette.base,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Palette.soft, height: 1.28),
                        ),
                        const Spacer(),
                        Text(
                          item.price,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Palette.orange,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<MenuListItem>> _normalizedMarketSections(
  MarketStoreData store,
) {
  final Map<String, List<MenuListItem>> normalized =
      <String, List<MenuListItem>>{};
  final List<MenuListItem> allItems = <MenuListItem>[];
  for (final MapEntry<String, List<MenuListItem>> entry
      in store.sections.entries) {
    normalized[entry.key] = entry.value;
    allItems.addAll(entry.value);
  }
  normalized['Tümü'] = dedupeMarketItems(allItems);
  return <String, List<MenuListItem>>{
    'Tümü': normalized['Tümü']!,
    ...normalized..remove('Tümü'),
  };
}

String _marketExpiry(String date) => 'Son Tüketim Tarihi: $date';

final Map<String, MenuListItem> _marketProductCatalog = <String, MenuListItem>{
  'Günlük Süt': MenuListItem(
    'Günlük Süt',
    _marketExpiry('07.04.2026'),
    '36 TL',
    MarketImages.milk,
  ),
  'Paket Yoğurt': MenuListItem(
    'Paket Yoğurt',
    _marketExpiry('14.04.2026'),
    '44 TL',
    MarketImages.yogurtPack,
  ),
  'Lor Peyniri': MenuListItem(
    'Lor Peyniri',
    _marketExpiry('12.04.2026'),
    '52 TL',
    MarketImages.softCheesePack,
  ),
  'Taze Kaşar Peyniri': MenuListItem(
    'Taze Kaşar Peyniri',
    _marketExpiry('18.04.2026'),
    '95 TL',
    MarketImages.toastCheese,
  ),
  'Labne Peyniri': MenuListItem(
    'Labne Peyniri',
    _marketExpiry('16.04.2026'),
    '49 TL',
    MarketImages.softCheesePack,
  ),
  'Kaymak': MenuListItem(
    'Kaymak',
    _marketExpiry('09.04.2026'),
    '67 TL',
    MarketImages.softCheesePack,
  ),
  'Tereyağı': MenuListItem(
    'Tereyağı',
    _marketExpiry('24.04.2026'),
    '119 TL',
    MarketImages.butterPack,
  ),
  'Süzme Yoğurt': MenuListItem(
    'Süzme Yoğurt',
    _marketExpiry('17.04.2026'),
    '58 TL',
    MarketImages.yogurtPack,
  ),
  'Kefir': MenuListItem(
    'Kefir',
    _marketExpiry('11.04.2026'),
    '39 TL',
    MarketImages.kefirBottle,
  ),
  'Ayran': MenuListItem(
    'Ayran',
    _marketExpiry('10.04.2026'),
    '18 TL',
    MarketImages.kefirBottle,
  ),
  'Meyveli Yoğurt': MenuListItem(
    'Meyveli Yoğurt',
    _marketExpiry('13.04.2026'),
    '24 TL',
    MarketImages.yogurtPack,
  ),
  'Krem Peynir': MenuListItem(
    'Krem Peynir',
    _marketExpiry('19.04.2026'),
    '54 TL',
    MarketImages.softCheesePack,
  ),
  'Üçgen Peynir': MenuListItem(
    'Üçgen Peynir',
    _marketExpiry('22.04.2026'),
    '44 TL',
    MarketImages.softCheesePack,
  ),
  'Beyaz Peynir (Vakumlu paket)': MenuListItem(
    'Beyaz Peynir (Vakumlu paket)',
    _marketExpiry('28.04.2026'),
    '109 TL',
    MarketImages.softCheesePack,
  ),
  'Çeçil Peyniri': MenuListItem(
    'Çeçil Peyniri',
    _marketExpiry('21.04.2026'),
    '72 TL',
    MarketImages.toastCheese,
  ),
  'Örgü Peyniri': MenuListItem(
    'Örgü Peyniri',
    _marketExpiry('20.04.2026'),
    '76 TL',
    MarketImages.toastCheese,
  ),
  'Sıvı Krema': MenuListItem(
    'Sıvı Krema',
    _marketExpiry('26.04.2026'),
    '42 TL',
    MarketImages.kefirBottle,
  ),
  'Yumurta': MenuListItem(
    'Yumurta',
    _marketExpiry('19.04.2026'),
    '84 TL',
    MarketImages.eggs,
  ),
  'Paket Tavuk Göğsü': MenuListItem(
    'Paket Tavuk Göğsü',
    _marketExpiry('07.04.2026'),
    '129 TL',
    MarketImages.chickenPack,
  ),
  'Paket Tavuk But/Baget': MenuListItem(
    'Paket Tavuk But/Baget',
    _marketExpiry('08.04.2026'),
    '118 TL',
    MarketImages.chickenPack,
  ),
  'Tavuk Kanat': MenuListItem(
    'Tavuk Kanat',
    _marketExpiry('08.04.2026'),
    '124 TL',
    MarketImages.chickenPack,
  ),
  'Hazır Paket Kıyma': MenuListItem(
    'Hazır Paket Kıyma',
    _marketExpiry('07.04.2026'),
    '169 TL',
    MarketImages.beefPack,
  ),
  'Paket Kuşbaşı Et': MenuListItem(
    'Paket Kuşbaşı Et',
    _marketExpiry('08.04.2026'),
    '229 TL',
    MarketImages.beefPack,
  ),
  'Dana Sosis': MenuListItem(
    'Dana Sosis',
    _marketExpiry('16.04.2026'),
    '87 TL',
    MarketImages.sausagePack,
  ),
  'Piliç Sosis': MenuListItem(
    'Piliç Sosis',
    _marketExpiry('15.04.2026'),
    '74 TL',
    MarketImages.sausagePack,
  ),
  'Dilimli Salam': MenuListItem(
    'Dilimli Salam',
    _marketExpiry('17.04.2026'),
    '63 TL',
    MarketImages.deliPack,
  ),
  'Fıstıklı Salam': MenuListItem(
    'Fıstıklı Salam',
    _marketExpiry('18.04.2026'),
    '76 TL',
    MarketImages.deliPack,
  ),
  'Isıl İşlem Görmüş Sucuk': MenuListItem(
    'Isıl İşlem Görmüş Sucuk',
    _marketExpiry('26.04.2026'),
    '129 TL',
    MarketImages.sausagePack,
  ),
  'Hindi Füme': MenuListItem(
    'Hindi Füme',
    _marketExpiry('18.04.2026'),
    '82 TL',
    MarketImages.deliPack,
  ),
  'Pastırma': MenuListItem(
    'Pastırma',
    _marketExpiry('21.04.2026'),
    '169 TL',
    MarketImages.deliPack,
  ),
  'Paket Kavurma': MenuListItem(
    'Paket Kavurma',
    _marketExpiry('27.04.2026'),
    '189 TL',
    MarketImages.deliPack,
  ),
  'Piliç Nugget': MenuListItem(
    'Piliç Nugget',
    _marketExpiry('20.04.2026'),
    '96 TL',
    MarketImages.chickenPack,
  ),
  'Hazır Şinitzel': MenuListItem(
    'Hazır Şinitzel',
    _marketExpiry('14.04.2026'),
    '109 TL',
    MarketImages.chickenPack,
  ),
  'Pişmiş Hazır Döner (Paketli)': MenuListItem(
    'Pişmiş Hazır Döner (Paketli)',
    _marketExpiry('12.04.2026'),
    '119 TL',
    MarketImages.donerPack,
  ),
  'Hazır Köfte (Kasap köfte/İnegöl köfte)': MenuListItem(
    'Hazır Köfte (Kasap köfte/İnegöl köfte)',
    _marketExpiry('09.04.2026'),
    '134 TL',
    MarketImages.beefPack,
  ),
  'Kültür Mantarı': MenuListItem(
    'Kültür Mantarı',
    _marketExpiry('07.04.2026'),
    '39 TL',
    MarketImages.mushroomPack,
  ),
  'Paket Maydanoz': MenuListItem(
    'Paket Maydanoz',
    _marketExpiry('06.04.2026'),
    '14 TL',
    MarketImages.herbBundle,
  ),
  'Dereotu': MenuListItem(
    'Dereotu',
    _marketExpiry('06.04.2026'),
    '14 TL',
    MarketImages.herbBundle,
  ),
  'Roka': MenuListItem(
    'Roka',
    _marketExpiry('06.04.2026'),
    '16 TL',
    MarketImages.greensPack,
  ),
  'Taze Nane': MenuListItem(
    'Taze Nane',
    _marketExpiry('06.04.2026'),
    '15 TL',
    MarketImages.herbBundle,
  ),
  'Yeşil Soğan': MenuListItem(
    'Yeşil Soğan',
    _marketExpiry('07.04.2026'),
    '18 TL',
    MarketImages.herbBundle,
  ),
  'Ispanak (Paketli/Yıkanmış)': MenuListItem(
    'Ispanak (Paketli/Yıkanmış)',
    _marketExpiry('08.04.2026'),
    '28 TL',
    MarketImages.spinachPack,
  ),
  'Çarliston Biber': MenuListItem(
    'Çarliston Biber',
    _marketExpiry('09.04.2026'),
    '32 TL',
    MarketImages.pepperPack,
  ),
  'Sivri Biber': MenuListItem(
    'Sivri Biber',
    _marketExpiry('09.04.2026'),
    '31 TL',
    MarketImages.pepperPack,
  ),
  'Domates (Salkım)': MenuListItem(
    'Domates (Salkım)',
    _marketExpiry('10.04.2026'),
    '42 TL',
    MarketImages.tomatoes,
  ),
  'Salatalık': MenuListItem(
    'Salatalık',
    _marketExpiry('09.04.2026'),
    '26 TL',
    MarketImages.cucumbers,
  ),
  'Çilek': MenuListItem(
    'Çilek',
    _marketExpiry('07.04.2026'),
    '59 TL',
    MarketImages.strawberriesPack,
  ),
  'Marul/Kıvırcık': MenuListItem(
    'Marul/Kıvırcık',
    _marketExpiry('07.04.2026'),
    '29 TL',
    MarketImages.greensPack,
  ),
  'Brokoli (Streç film kaplı)': MenuListItem(
    'Brokoli (Streç film kaplı)',
    _marketExpiry('10.04.2026'),
    '37 TL',
    MarketImages.broccoliPack,
  ),
  'Semizotu': MenuListItem(
    'Semizotu',
    _marketExpiry('06.04.2026'),
    '18 TL',
    MarketImages.greensPack,
  ),
  'Taze Yufka': MenuListItem(
    'Taze Yufka',
    _marketExpiry('08.04.2026'),
    '36 TL',
    MarketImages.wrapPack,
  ),
  'Paket Ekmek (Tam buğday/Çavdar)': MenuListItem(
    'Paket Ekmek (Tam buğday/Çavdar)',
    _marketExpiry('11.04.2026'),
    '32 TL',
    MarketImages.bread,
  ),
  'Hamburger Ekmeği': MenuListItem(
    'Hamburger Ekmeği',
    _marketExpiry('10.04.2026'),
    '34 TL',
    MarketImages.toastBread,
  ),
  'Sandviç Ekmeği': MenuListItem(
    'Sandviç Ekmeği',
    _marketExpiry('10.04.2026'),
    '33 TL',
    MarketImages.toastBread,
  ),
  'Lavaş/Tortilla': MenuListItem(
    'Lavaş/Tortilla',
    _marketExpiry('18.04.2026'),
    '46 TL',
    MarketImages.wrapPack,
  ),
  'Milföy Hamuru': MenuListItem(
    'Milföy Hamuru',
    _marketExpiry('20.04.2026'),
    '42 TL',
    MarketImages.pastryPack,
  ),
  'Hazır Üçgen Yufka': MenuListItem(
    'Hazır Üçgen Yufka',
    _marketExpiry('17.04.2026'),
    '38 TL',
    MarketImages.pastryPack,
  ),
  'Paket Simit': MenuListItem(
    'Paket Simit',
    _marketExpiry('07.04.2026'),
    '29 TL',
    MarketImages.bread,
  ),
  'Kremalı Yaş Pasta (Reyondaki)': MenuListItem(
    'Kremalı Yaş Pasta (Reyondaki)',
    _marketExpiry('07.04.2026'),
    '159 TL',
    MarketImages.cakeSlice,
  ),
  'Ekler (Paketli)': MenuListItem(
    'Ekler (Paketli)',
    _marketExpiry('08.04.2026'),
    '56 TL',
    MarketImages.cakeSlice,
  ),
  'Sütlaç (Paketli/Hazır)': MenuListItem(
    'Sütlaç (Paketli/Hazır)',
    _marketExpiry('10.04.2026'),
    '34 TL',
    MarketImages.puddingCup,
  ),
  'Supangle/Puding (Hazır)': MenuListItem(
    'Supangle/Puding (Hazır)',
    _marketExpiry('14.04.2026'),
    '32 TL',
    MarketImages.puddingCup,
  ),
  'Paketli Humus': MenuListItem(
    'Paketli Humus',
    _marketExpiry('14.04.2026'),
    '44 TL',
    MarketImages.mezePack,
  ),
  'Paketli Haydari': MenuListItem(
    'Paketli Haydari',
    _marketExpiry('12.04.2026'),
    '42 TL',
    MarketImages.mezePack,
  ),
  'Amerikan Salatası (Paketli)': MenuListItem(
    'Amerikan Salatası (Paketli)',
    _marketExpiry('10.04.2026'),
    '39 TL',
    MarketImages.deliSaladPack,
  ),
  'Rus Salatası (Paketli)': MenuListItem(
    'Rus Salatası (Paketli)',
    _marketExpiry('10.04.2026'),
    '39 TL',
    MarketImages.deliSaladPack,
  ),
  'Şakşuka (Hazır paket)': MenuListItem(
    'Şakşuka (Hazır paket)',
    _marketExpiry('11.04.2026'),
    '41 TL',
    MarketImages.deliSaladPack,
  ),
  'Hazır Çiğ Köfte (Vakumlu paket)': MenuListItem(
    'Hazır Çiğ Köfte (Vakumlu paket)',
    _marketExpiry('12.04.2026'),
    '49 TL',
    MarketImages.mezePack,
  ),
  'Taze Makarna (Buzdolabı reyonu)': MenuListItem(
    'Taze Makarna (Buzdolabı reyonu)',
    _marketExpiry('15.04.2026'),
    '69 TL',
    MarketImages.freshPastaPack,
  ),
  'Soğuk Sandviç (Üçgen paket)': MenuListItem(
    'Soğuk Sandviç (Üçgen paket)',
    _marketExpiry('07.04.2026'),
    '47 TL',
    MarketImages.sandwichPack,
  ),
};

List<MenuListItem> marketProducts(List<String> titles) {
  return titles.map((title) => _marketProductCatalog[title]!).toList();
}

MarketStoreData? marketStoreById(String id) {
  for (final MarketStoreData store in marketStores) {
    if (store.id == id) {
      return store;
    }
  }
  return null;
}

final List<MarketStoreData> marketStores = <MarketStoreData>[
  MarketStoreData(
    id: 'migros-jet',
    title: 'Migros Jet',
    subtitle: 'Günlük mahalle marketi seçkisi',
    meta: 'Gel-Al • 18 dk hazır',
    image: MarketImages.migrosStore,
    badge: '24 Saat',
    rewardLabel: 'Gel-Al',
    ratingLabel: '4.8',
    distanceLabel: '0.7 km',
    etaLabel: '18 dk',
    promoLabel: 'Süt, manav ve hazır tüketim',
    workingHoursLabel: '08:00-02:00',
    minOrderLabel: 'Yok',
    deliveryWindowLabel: 'Hazır olduğunda',
    reviewCountLabel: '126',
    announcement:
        'Siparişin kısa raf ömürlü ürünler için öncelikli hazırlanır ve hazır olduğunda bildirim düşer.',
    bundleTitle: 'Mahalle Kahvaltı Sepeti',
    bundleDescription:
        'Süt, ekmek, yumurta ve günlük tüketim ürünlerinden oluşan pratik sepet.',
    bundlePrice: '139 TL',
    heroTitle: 'Migros Jet ile günlük market alışverişi hızlandı',
    heroSubtitle:
        'Süt, kahvaltılık, manav ve hazır ürünler kısa sürede hazırlanır; mağazadan teslim alınır.',
    highlights: <StoreHighlightData>[
      StoreHighlightData('Günlük süt', Icons.local_drink_outlined),
      StoreHighlightData('Hazır teslim', Icons.shopping_bag_outlined),
      StoreHighlightData('Mahalle şubesi', Icons.storefront_outlined),
    ],
    sections: <String, List<MenuListItem>>{
      'Süt & Kahvaltılık': marketProducts(<String>[
        'Günlük Süt',
        'Paket Yoğurt',
        'Taze Kaşar Peyniri',
        'Kefir',
        'Ayran',
        'Yumurta',
      ]),
      'Et & Şarküteri': marketProducts(<String>[
        'Dana Sosis',
        'Piliç Sosis',
        'Piliç Nugget',
      ]),
      'Manav': marketProducts(<String>[
        'Domates (Salkım)',
        'Salatalık',
        'Çilek',
      ]),
      'Unlu Mamuller': marketProducts(<String>[
        'Paket Ekmek (Tam buğday/Çavdar)',
        'Hamburger Ekmeği',
        'Paket Simit',
        'Supangle/Puding (Hazır)',
      ]),
      'Hazır Gıda': marketProducts(<String>[
        'Paketli Humus',
        'Hazır Çiğ Köfte (Vakumlu paket)',
        'Soğuk Sandviç (Üçgen paket)',
        'Taze Makarna (Buzdolabı reyonu)',
      ]),
    },
  ),
  MarketStoreData(
    id: 'macrocenter-express',
    title: 'Macrocenter Express',
    subtitle: 'Premium kahvaltılık ve şarküteri',
    meta: 'Gel-Al • 22 dk hazır',
    image: MarketImages.macroStore,
    badge: 'Premium',
    rewardLabel: 'Gel-Al',
    ratingLabel: '4.9',
    distanceLabel: '1.1 km',
    etaLabel: '22 dk',
    promoLabel: 'Şarküteri, peynir ve taze reyon',
    workingHoursLabel: '09:00-23:30',
    minOrderLabel: 'Yok',
    deliveryWindowLabel: 'Hazır olduğunda',
    reviewCountLabel: '84',
    announcement:
        'Şarküteri ve soğuk zincir ürünler siparişin için ayrı soğuk alanda hazırlanır.',
    bundleTitle: 'Premium Kahvaltı Sepeti',
    bundleDescription:
        'Peynir, kaymak, taze yufka ve hazır meze ile güçlü bir sabah seçkisi.',
    bundlePrice: '229 TL',
    heroTitle: 'Macrocenter Express ile soğuk reyon seçkisi tek ekranda',
    heroSubtitle:
        'Premium kahvaltılık, et-şarküteri ve hazır soğuk ürünler mağazadan hızlı teslim için hazırlanır.',
    highlights: <StoreHighlightData>[
      StoreHighlightData('Premium reyon', Icons.workspace_premium_rounded),
      StoreHighlightData('Soğuk zincir', Icons.ac_unit_rounded),
      StoreHighlightData('Hazır meze', Icons.dinner_dining_outlined),
    ],
    sections: <String, List<MenuListItem>>{
      'Süt & Kahvaltılık': marketProducts(<String>[
        'Paket Yoğurt',
        'Lor Peyniri',
        'Taze Kaşar Peyniri',
        'Labne Peyniri',
        'Kaymak',
        'Tereyağı',
        'Süzme Yoğurt',
        'Meyveli Yoğurt',
        'Krem Peynir',
        'Beyaz Peynir (Vakumlu paket)',
        'Çeçil Peyniri',
        'Sıvı Krema',
      ]),
      'Et & Şarküteri': marketProducts(<String>[
        'Paket Kuşbaşı Et',
        'Hindi Füme',
        'Pastırma',
        'Paket Kavurma',
        'Pişmiş Hazır Döner (Paketli)',
      ]),
      'Manav': marketProducts(<String>[
        'Kültür Mantarı',
        'Paket Maydanoz',
        'Roka',
        'Çilek',
        'Brokoli (Streç film kaplı)',
      ]),
      'Unlu Mamuller': marketProducts(<String>[
        'Taze Yufka',
        'Lavaş/Tortilla',
        'Kremalı Yaş Pasta (Reyondaki)',
        'Ekler (Paketli)',
        'Sütlaç (Paketli/Hazır)',
      ]),
      'Hazır Gıda': marketProducts(<String>[
        'Paketli Humus',
        'Paketli Haydari',
        'Amerikan Salatası (Paketli)',
      ]),
    },
  ),
  MarketStoreData(
    id: 'file-market',
    title: 'File Market',
    subtitle: 'Ekonomik günlük temel ürünler',
    meta: 'Gel-Al • 12 dk hazır',
    image: MarketImages.fileStore,
    badge: 'İndirim',
    rewardLabel: 'Gel-Al',
    ratingLabel: '4.7',
    distanceLabel: '0.3 km',
    etaLabel: '12 dk',
    promoLabel: 'Bütçe dostu temel stoklar',
    workingHoursLabel: '08:30-01:00',
    minOrderLabel: 'Yok',
    deliveryWindowLabel: 'Hazır olduğunda',
    reviewCountLabel: '214',
    announcement:
        'Günlük tüketim ürünleri hızlı akışta toplanır ve mağaza girişinde teslim edilir.',
    bundleTitle: 'Ekonomik Temel Sepet',
    bundleDescription:
        'Süt, et ürünleri, ekmek ve manav reyonundan günlük temel ihtiyaç seçkisi.',
    bundlePrice: '179 TL',
    heroTitle: 'File Market ile temel ihtiyaçları sade ve hızlı topla',
    heroSubtitle:
        'Bütçe dostu süt, et, manav ve unlu mamuller aynı market akışında hazırlanır.',
    highlights: <StoreHighlightData>[
      StoreHighlightData('Ekonomik seri', Icons.sell_outlined),
      StoreHighlightData('Hızlı raf', Icons.flash_on_outlined),
      StoreHighlightData('Temel ürün', Icons.inventory_2_outlined),
    ],
    sections: <String, List<MenuListItem>>{
      'Süt & Kahvaltılık': marketProducts(<String>[
        'Günlük Süt',
        'Süzme Yoğurt',
        'Kefir',
        'Ayran',
        'Üçgen Peynir',
        'Yumurta',
      ]),
      'Et & Şarküteri': marketProducts(<String>[
        'Paket Tavuk Göğsü',
        'Hazır Paket Kıyma',
        'Hazır Şinitzel',
        'Hazır Köfte (Kasap köfte/İnegöl köfte)',
      ]),
      'Manav': marketProducts(<String>[
        'Dereotu',
        'Taze Nane',
        'Yeşil Soğan',
        'Ispanak (Paketli/Yıkanmış)',
        'Çarliston Biber',
        'Sivri Biber',
        'Marul/Kıvırcık',
        'Semizotu',
      ]),
      'Unlu Mamuller': marketProducts(<String>[
        'Paket Ekmek (Tam buğday/Çavdar)',
        'Sandviç Ekmeği',
        'Milföy Hamuru',
        'Hazır Üçgen Yufka',
      ]),
      'Hazır Gıda': marketProducts(<String>[
        'Rus Salatası (Paketli)',
        'Şakşuka (Hazır paket)',
        'Soğuk Sandviç (Üçgen paket)',
      ]),
    },
  ),
  MarketStoreData(
    id: 'carrefoursa-mini',
    title: 'CarrefourSA Mini',
    subtitle: 'Taze manav ve geniş reyon seçkisi',
    meta: 'Gel-Al • 16 dk hazır',
    image: MarketImages.carrefourStore,
    badge: 'Taze',
    rewardLabel: 'Gel-Al',
    ratingLabel: '4.7',
    distanceLabel: '0.9 km',
    etaLabel: '16 dk',
    promoLabel: 'Taze manav ve geniş günlük stok',
    workingHoursLabel: '09:00-23:00',
    minOrderLabel: 'Yok',
    deliveryWindowLabel: 'Hazır olduğunda',
    reviewCountLabel: '93',
    announcement:
        'Taze reyon ve paketli ürünler ayrı toplanır; hazır olduğunda mağazadan alınır.',
    bundleTitle: 'Günlük Taze Sepet',
    bundleDescription:
        'Manav, şarküteri ve unlu mamullerden dengeli günlük alışveriş paketi.',
    bundlePrice: '199 TL',
    heroTitle: 'CarrefourSA Mini ile taze ürünleri tek seferde topla',
    heroSubtitle:
        'Manav, kahvaltılık, et-şarküteri ve hazır gıda reyonları mağazadan al için hızlı hazırlanır.',
    highlights: <StoreHighlightData>[
      StoreHighlightData('Taze raf', Icons.eco_outlined),
      StoreHighlightData('Geniş seçenek', Icons.grid_view_rounded),
      StoreHighlightData('Hızlı teslim', Icons.shopping_bag_outlined),
    ],
    sections: <String, List<MenuListItem>>{
      'Süt & Kahvaltılık': marketProducts(<String>[
        'Günlük Süt',
        'Paket Yoğurt',
        'Labne Peyniri',
        'Krem Peynir',
        'Örgü Peyniri',
        'Sıvı Krema',
      ]),
      'Et & Şarküteri': marketProducts(<String>[
        'Paket Tavuk But/Baget',
        'Tavuk Kanat',
        'Dilimli Salam',
        'Fıstıklı Salam',
        'Isıl İşlem Görmüş Sucuk',
        'Piliç Nugget',
      ]),
      'Manav': marketProducts(<String>[
        'Kültür Mantarı',
        'Ispanak (Paketli/Yıkanmış)',
        'Çarliston Biber',
        'Domates (Salkım)',
        'Salatalık',
        'Brokoli (Streç film kaplı)',
      ]),
      'Unlu Mamuller': marketProducts(<String>[
        'Taze Yufka',
        'Paket Ekmek (Tam buğday/Çavdar)',
        'Lavaş/Tortilla',
        'Milföy Hamuru',
        'Ekler (Paketli)',
        'Sütlaç (Paketli/Hazır)',
      ]),
      'Hazır Gıda': marketProducts(<String>[
        'Paketli Haydari',
        'Hazır Çiğ Köfte (Vakumlu paket)',
        'Taze Makarna (Buzdolabı reyonu)',
      ]),
    },
  ),
  MarketStoreData(
    id: 'sok-market',
    title: 'ŞOK Market',
    subtitle: 'Uygun fiyatlı temel ihtiyaç seçkisi',
    meta: 'Gel-Al • 11 dk hazır',
    image: MarketImages.sokStore,
    badge: 'Avantaj',
    rewardLabel: 'Gel-Al',
    ratingLabel: '4.6',
    distanceLabel: '0.5 km',
    etaLabel: '11 dk',
    promoLabel: 'Uygun fiyatlı günlük ürünler',
    workingHoursLabel: '08:30-22:30',
    minOrderLabel: 'Yok',
    deliveryWindowLabel: 'Hazır olduğunda',
    reviewCountLabel: '178',
    announcement:
        'Temel ihtiyaç sepetleri hızlı toplanır; mahalle şubesinden sıra beklemeden teslim alınır.',
    bundleTitle: 'Mahalle Temel İhtiyaç Sepeti',
    bundleDescription:
        'Süt, ekmek, manav ve hazır ürünlerden uygun fiyatlı günlük kombin.',
    bundlePrice: '149 TL',
    heroTitle: 'ŞOK Market ile mahalle alışverişini hızla tamamla',
    heroSubtitle:
        'Uygun fiyatlı süt, et, manav ve hazır ürünler kısa hazırlık süresiyle mağazada seni bekler.',
    highlights: <StoreHighlightData>[
      StoreHighlightData('Avantajlı fiyat', Icons.local_offer_outlined),
      StoreHighlightData('Mahalle şubesi', Icons.store_outlined),
      StoreHighlightData('Hızlı toplama', Icons.timer_outlined),
    ],
    sections: <String, List<MenuListItem>>{
      'Süt & Kahvaltılık': marketProducts(<String>[
        'Lor Peyniri',
        'Taze Kaşar Peyniri',
        'Meyveli Yoğurt',
        'Üçgen Peynir',
        'Yumurta',
      ]),
      'Et & Şarküteri': marketProducts(<String>[
        'Dana Sosis',
        'Piliç Sosis',
        'Hazır Şinitzel',
        'Hazır Köfte (Kasap köfte/İnegöl köfte)',
      ]),
      'Manav': marketProducts(<String>[
        'Dereotu',
        'Yeşil Soğan',
        'Sivri Biber',
        'Domates (Salkım)',
        'Salatalık',
        'Marul/Kıvırcık',
      ]),
      'Unlu Mamuller': marketProducts(<String>[
        'Hamburger Ekmeği',
        'Sandviç Ekmeği',
        'Hazır Üçgen Yufka',
        'Paket Simit',
        'Supangle/Puding (Hazır)',
      ]),
      'Hazır Gıda': marketProducts(<String>[
        'Amerikan Salatası (Paketli)',
        'Rus Salatası (Paketli)',
        'Şakşuka (Hazır paket)',
        'Soğuk Sandviç (Üçgen paket)',
      ]),
    },
  ),
  MarketStoreData(
    id: 'a101-hizli',
    title: 'A101 Hızlı',
    subtitle: 'Hızlı temel stok ve günlük soğuk reyon',
    meta: 'Gel-Al • 14 dk hazır',
    image: MarketImages.a101Store,
    badge: 'Pratik',
    rewardLabel: 'Gel-Al',
    ratingLabel: '4.5',
    distanceLabel: '1.2 km',
    etaLabel: '14 dk',
    promoLabel: 'Temel stok ve şarküteri odağı',
    workingHoursLabel: '09:00-22:00',
    minOrderLabel: 'Yok',
    deliveryWindowLabel: 'Hazır olduğunda',
    reviewCountLabel: '147',
    announcement:
        'Soğuk reyon ve şarküteri ürünleri mağaza içinde kısa sürede hazırlanır.',
    bundleTitle: 'Soğuk Reyon Sepeti',
    bundleDescription:
        'Peynir, şarküteri, meze ve taze makarnadan oluşan hızlı akşam sepeti.',
    bundlePrice: '189 TL',
    heroTitle: 'A101 Hızlı ile günlük stok alışverişi tek ekranda',
    heroSubtitle:
        'Şarküteri, kahvaltılık ve hazır gıdalar tek akışta seçilir; mağazadan kolay teslim alınır.',
    highlights: <StoreHighlightData>[
      StoreHighlightData('Soğuk reyon', Icons.kitchen_outlined),
      StoreHighlightData('Şarküteri', Icons.set_meal_outlined),
      StoreHighlightData('Pratik teslim', Icons.flash_on_outlined),
    ],
    sections: <String, List<MenuListItem>>{
      'Süt & Kahvaltılık': marketProducts(<String>[
        'Kaymak',
        'Tereyağı',
        'Beyaz Peynir (Vakumlu paket)',
        'Çeçil Peyniri',
        'Örgü Peyniri',
      ]),
      'Et & Şarküteri': marketProducts(<String>[
        'Paket Tavuk Göğsü',
        'Hazır Paket Kıyma',
        'Isıl İşlem Görmüş Sucuk',
        'Hindi Füme',
        'Pastırma',
        'Paket Kavurma',
        'Pişmiş Hazır Döner (Paketli)',
      ]),
      'Manav': marketProducts(<String>[
        'Paket Maydanoz',
        'Roka',
        'Taze Nane',
        'Çilek',
        'Semizotu',
      ]),
      'Unlu Mamuller': marketProducts(<String>[
        'Kremalı Yaş Pasta (Reyondaki)',
      ]),
      'Hazır Gıda': marketProducts(<String>[
        'Paketli Humus',
        'Paketli Haydari',
        'Hazır Çiğ Köfte (Vakumlu paket)',
        'Taze Makarna (Buzdolabı reyonu)',
      ]),
    },
  ),
];

class MarketStoreData {
  const MarketStoreData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.image,
    required this.badge,
    required this.rewardLabel,
    required this.ratingLabel,
    required this.distanceLabel,
    required this.etaLabel,
    required this.promoLabel,
    required this.workingHoursLabel,
    required this.minOrderLabel,
    required this.deliveryWindowLabel,
    required this.reviewCountLabel,
    required this.announcement,
    required this.bundleTitle,
    required this.bundleDescription,
    required this.bundlePrice,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.highlights,
    required this.sections,
  });

  final String id;
  final String title;
  final String subtitle;
  final String meta;
  final String image;
  final String badge;
  final String rewardLabel;
  final String ratingLabel;
  final String distanceLabel;
  final String etaLabel;
  final String promoLabel;
  final String workingHoursLabel;
  final String minOrderLabel;
  final String deliveryWindowLabel;
  final String reviewCountLabel;
  final String announcement;
  final String bundleTitle;
  final String bundleDescription;
  final String bundlePrice;
  final String heroTitle;
  final String heroSubtitle;
  final List<StoreHighlightData> highlights;
  final Map<String, List<MenuListItem>> sections;

  String get heroTag => 'market-store-$id';

  double get bundlePriceValue => menuBasePrice(bundlePrice);
}

class StoreHighlightData {
  const StoreHighlightData(this.label, this.icon);

  final String label;
  final IconData icon;
}
