import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'market_products_content.dart';

enum ProductScreenMode { restaurant, market }

const List<String> _restaurantCategorySuggestions = <String>[
  'Burger',
  'Pizza',
  'İçecek',
  'Tatlı',
  'Salata',
  'Wrap',
  'Menü',
];
const List<String> _restaurantPortionSuggestions = <String>[
  'Tek Porsiyon',
  '1.5 Porsiyon',
  'Aile Boy',
  'Küçük Boy',
  'Orta Boy',
  'Büyük Boy',
];
const String _restaurantPrepAliasPrefix = 'restaurantPrep:';
const String _restaurantExtrasAliasPrefix = 'restaurantExtras:';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.mode, this.onBack});

  final ProductScreenMode? mode;
  final VoidCallback? onBack;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);

    final Map<String, SpetoInventoryItem> inventoryByProductId =
        <String, SpetoInventoryItem>{
          for (final item in controller.inventoryItems) item.id: item,
        };
    final String query = _searchController.text.trim().toLowerCase();
    final List<SpetoCatalogProduct> searchableProducts = controller.products
        .where((SpetoCatalogProduct product) {
          if (query.isEmpty) {
            return true;
          }
          final String haystack =
              '${product.title} ${product.category} ${product.sectionLabel} '
                      '${product.displaySubtitle} ${product.description}'
                  .toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);

    final ProductScreenMode resolvedMode =
        widget.mode ??
        (controller.isRestaurantMode
            ? ProductScreenMode.restaurant
            : ProductScreenMode.market);
    final bool isRestaurantMode = resolvedMode == ProductScreenMode.restaurant;

    if (!isRestaurantMode) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: MarketProductsContent(
          products: searchableProducts,
          inventoryByProductId: inventoryByProductId,
          onAddProduct: () => _openRestaurantProductForm(context, controller),
          onEditProduct: (SpetoCatalogProduct product) {
            _openRestaurantProductForm(context, controller, product: product);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: _buildRestaurantClassicLayout(
          context,
          controller,
          products: searchableProducts,
          inventoryByProductId: inventoryByProductId,
        ),
      ),
    );
  }

  Widget _buildRestaurantClassicLayout(
    BuildContext context,
    StockAppController controller, {
    required List<SpetoCatalogProduct> products,
    required Map<String, SpetoInventoryItem> inventoryByProductId,
  }) {
    final int activeCount = products.where((SpetoCatalogProduct product) {
      return !product.isArchived;
    }).length;
    final int archivedCount = products.where((SpetoCatalogProduct product) {
      return product.isArchived;
    }).length;
    final int campaignCount = products.where((SpetoCatalogProduct product) {
      return (product.discountedPrice > 0 &&
              product.discountedPrice < product.unitPrice) ||
          product.displayBadge.trim().isNotEmpty;
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Ürünler',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Restoran menünüzü yönetin',
                    style: TextStyle(fontSize: 14, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              onPressed: () => _openRestaurantProductForm(context, controller),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Yeni Ekle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppColors.slate400),
              hintText: 'Menüde ara...',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.45,
          children: <Widget>[
            _buildOverviewStatCard(
              const _OverviewMetric(
                title: 'TOPLAM',
                value: '',
                icon: Icons.inventory_2_outlined,
                iconBackgroundColor: Color(0xFFEFFAF4),
                iconColor: AppColors.emerald700,
              ).copyWith(value: '${products.length}'),
            ),
            _buildOverviewStatCard(
              const _OverviewMetric(
                title: 'AKTİF',
                value: '',
                icon: Icons.check_circle_rounded,
                iconBackgroundColor: Color(0xFFEFFAF4),
                iconColor: AppColors.emerald700,
              ).copyWith(value: '$activeCount'),
            ),
            _buildOverviewStatCard(
              const _OverviewMetric(
                title: 'PASİF',
                value: '',
                icon: Icons.cancel_outlined,
                iconBackgroundColor: Color(0xFFFFF1F1),
                iconColor: Color(0xFFE11D48),
              ).copyWith(value: '$archivedCount'),
            ),
            _buildOverviewStatCard(
              const _OverviewMetric(
                title: 'KAMPANYA',
                value: '',
                icon: Icons.local_offer_outlined,
                iconBackgroundColor: Color(0xFFFFF5E8),
                iconColor: AppColors.amber600,
              ).copyWith(value: '$campaignCount'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (products.isEmpty)
          const _EmptyProductsCard(
            message: 'Gösterilecek restoran ürünü bulunamadı.',
          )
        else
          for (final SpetoCatalogProduct product in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ClassicRestaurantProductCard(
                product: product,
                inventoryItem: inventoryByProductId[product.id],
                onEdit: () => _openRestaurantProductForm(
                  context,
                  controller,
                  product: product,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildOverviewStatCard(_OverviewMetric metric) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1ABBCBBB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32.667,
            height: 32.667,
            decoration: BoxDecoration(
              color: metric.iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, color: metric.iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            metric.title,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.33,
              letterSpacing: 0.6,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.33,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildRestaurantCategoryOptions(
    StockAppController controller,
    Iterable<SpetoCatalogProduct> products,
  ) {
    final List<String> options = <String>[];

    void addOption(String value) {
      final String normalized = value.trim();
      if (normalized.isEmpty || options.contains(normalized)) {
        return;
      }
      options.add(normalized);
    }

    for (final SpetoCatalogProduct product in products) {
      addOption(_restaurantCategoryLabel(product));
    }
    final String cuisine = controller.selectedVendor?.cuisine ?? '';
    addOption(cuisine);
    for (final String suggestion in _restaurantCategorySuggestions) {
      addOption(suggestion);
    }
    return options;
  }

  List<String> _buildRestaurantPortionOptions(
    Iterable<SpetoCatalogProduct> products,
  ) {
    final List<String> options = <String>[];

    void addOption(String value) {
      final String normalized = value.trim();
      if (normalized.isEmpty || options.contains(normalized)) {
        return;
      }
      options.add(normalized);
    }

    for (final SpetoCatalogProduct product in products) {
      addOption(product.sectionLabel);
    }
    for (final String suggestion in _restaurantPortionSuggestions) {
      addOption(suggestion);
    }
    return options;
  }

  Future<void> _openRestaurantProductForm(
    BuildContext context,
    StockAppController controller, {
    SpetoCatalogProduct? product,
  }) async {
    final bool? didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _RestaurantProductFormScreen(
          controller: controller,
          product: product,
          categoryOptions: _buildRestaurantCategoryOptions(
            controller,
            controller.products,
          ),
          portionOptions: _buildRestaurantPortionOptions(controller.products),
        ),
      ),
    );
    if (didSave == true && mounted) {
      setState(() {});
    }
  }
}

class _OverviewMetric {
  const _OverviewMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;

  _OverviewMetric copyWith({
    String? title,
    String? value,
    IconData? icon,
    Color? iconBackgroundColor,
    Color? iconColor,
  }) {
    return _OverviewMetric(
      title: title ?? this.title,
      value: value ?? this.value,
      icon: icon ?? this.icon,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}

class _ClassicRestaurantProductCard extends StatelessWidget {
  const _ClassicRestaurantProductCard({
    required this.product,
    required this.inventoryItem,
    required this.onEdit,
  });

  final SpetoCatalogProduct product;
  final SpetoInventoryItem? inventoryItem;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bool isArchived = product.isArchived;
    final int availableQuantity =
        inventoryItem?.availableQuantity ??
        product.stockStatus.availableQuantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.slate100),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _ProductImagePreview(
              imageUrl: _restaurantProductImage(product, inventoryItem),
              label: product.title,
              borderRadius: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isArchived
                            ? const Color(0xFFF1F5F9)
                            : AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isArchived ? 'PASİF' : 'AKTİF',
                        style: TextStyle(
                          color: isArchived
                              ? AppColors.slate500
                              : AppColors.emerald800,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _restaurantProductSubtitle(product),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        product.priceText.isEmpty
                            ? _formatCurrency(product.unitPrice)
                            : product.priceText,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      'Stok: $availableQuantity',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.slate200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Düzenle'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantProductFormScreen extends StatefulWidget {
  const _RestaurantProductFormScreen({
    required this.controller,
    required this.categoryOptions,
    required this.portionOptions,
    this.product,
  });

  final StockAppController controller;
  final SpetoCatalogProduct? product;
  final List<String> categoryOptions;
  final List<String> portionOptions;

  @override
  State<_RestaurantProductFormScreen> createState() =>
      _RestaurantProductFormScreenState();
}

class _RestaurantProductFormScreenState
    extends State<_RestaurantProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentInfoController;
  late final TextEditingController _portionController;
  late final TextEditingController _prepMinutesController;
  late final TextEditingController _extrasController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountedPriceController;
  late final TextEditingController _imageUrlController;
  String? _selectedCategory;
  String? _selectedPortion;
  bool _isSaving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final SpetoCatalogProduct? product = widget.product;
    _titleController = TextEditingController(text: product?.title ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _contentInfoController = TextEditingController(
      text: product?.displaySubtitle ?? '',
    );
    _portionController = TextEditingController(
      text: product?.sectionLabel ?? '',
    );
    _prepMinutesController = TextEditingController(
      text: _extractRestaurantAliasValue(
        product?.legacyAliases ?? const <String>[],
        _restaurantPrepAliasPrefix,
      ),
    );
    _extrasController = TextEditingController(
      text: _extractRestaurantAliasValue(
        product?.legacyAliases ?? const <String>[],
        _restaurantExtrasAliasPrefix,
      ),
    );
    _priceController = TextEditingController(
      text: product == null ? '' : _formatDecimalInput(product.unitPrice),
    );
    _discountedPriceController = TextEditingController(
      text: product == null || product.discountedPrice <= 0
          ? ''
          : _formatDecimalInput(product.discountedPrice),
    );
    _imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    _selectedCategory = _resolveInitialDropdownValue(
      product?.category ?? '',
      widget.categoryOptions,
    );
    _selectedPortion = _resolveInitialDropdownValue(
      product?.sectionLabel ?? '',
      widget.portionOptions,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentInfoController.dispose();
    _portionController.dispose();
    _prepMinutesController.dispose();
    _extrasController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      _buildBasicSection(),
                      const SizedBox(height: 20),
                      _buildClassificationSection(),
                      const SizedBox(height: 20),
                      _buildPricingSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: Text(
              _isEdit ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _isEdit ? AppColors.onSurface : AppColors.emerald700,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: _isEdit
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSection() {
    return _RestaurantFormSection(
      title: 'Temel Bilgiler',
      children: <Widget>[
        _RestaurantTextField(
          controller: _titleController,
          label: 'Ürün / Menü Adı',
          hintText: _isEdit
              ? 'Örn: Karışık Pizza'
              : 'Örn: Sızma Zeytinyağlı 1L',
          isRequired: true,
          enabled: !_isSaving,
          validator: _requiredValidator('Ürün / Menü Adı'),
        ),
        _RestaurantTextField(
          controller: _descriptionController,
          label: 'Açıklama',
          hintText: 'Ürününüzü detaylıca anlatın...',
          isRequired: true,
          enabled: !_isSaving,
          maxLines: 3,
          validator: _requiredValidator('Açıklama'),
        ),
        _RestaurantTextField(
          controller: _contentInfoController,
          label: 'İçerik Bilgisi',
          hintText: _isEdit
              ? 'Örn: Domates sos, mozzarella, sucuk, sosis, mantar...'
              : 'Ürünün içindekiler...',
          isRequired: _isEdit,
          enabled: !_isSaving,
          maxLines: 3,
          validator: _isEdit ? _requiredValidator('İçerik Bilgisi') : null,
        ),
      ],
    );
  }

  Widget _buildClassificationSection() {
    final List<String> categoryOptions = <String>[
      ...widget.categoryOptions,
      if (!_containsValue(widget.categoryOptions, _selectedCategory))
        _selectedCategory ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
    final List<String> portionOptions = <String>[
      ...widget.portionOptions,
      if (!_containsValue(widget.portionOptions, _selectedPortion))
        _selectedPortion ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);

    return _RestaurantFormSection(
      title: _isEdit
          ? 'Sınıflandırma ve Görsel'
          : 'Sınıflandırma ve Özellikler',
      children: <Widget>[
        _RestaurantDropdownField(
          label: 'Kategori',
          hintText: 'Kategori Seçin',
          isRequired: true,
          enabled: !_isSaving,
          value: _selectedCategory,
          items: categoryOptions,
          onChanged: (String? value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Kategori zorunludur';
            }
            return null;
          },
        ),
        if (_isEdit)
          _RestaurantDropdownField(
            label: 'Porsiyon / Boyut',
            hintText: 'Seçiniz',
            isRequired: true,
            enabled: !_isSaving,
            value: _selectedPortion,
            items: portionOptions,
            onChanged: (String? value) {
              setState(() {
                _selectedPortion = value;
              });
            },
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Porsiyon / Boyut zorunludur';
              }
              return null;
            },
          )
        else
          _RestaurantTextField(
            controller: _portionController,
            label: 'Porsiyon / Boyut',
            hintText: 'Örn: 1.5 Porsiyon, Büyük Boy',
            enabled: !_isSaving,
          ),
        if (_isEdit)
          _RestaurantTextField(
            controller: _imageUrlController,
            label: 'Ürün Görseli URL',
            hintText: 'https://ornek.com/gorsel.jpg',
            isRequired: true,
            enabled: !_isSaving,
            keyboardType: TextInputType.url,
            prefixIcon: Icons.link_rounded,
            validator: _requiredValidator('Ürün Görseli URL'),
          ),
        _RestaurantTextField(
          controller: _prepMinutesController,
          label: _isEdit ? 'Hazırlık Süresi (Dakika)' : 'Hazırlık Süresi',
          hintText: 'Ör: 15',
          isRequired: _isEdit,
          enabled: !_isSaving,
          keyboardType: TextInputType.number,
          suffixText: _isEdit ? null : 'dk',
          validator: _isEdit
              ? _wholeNumberValidator('Hazırlık Süresi')
              : _optionalWholeNumberValidator,
        ),
        _RestaurantTextField(
          controller: _extrasController,
          label: 'Ekstra Seçenekler',
          hintText: _isEdit
              ? 'Örn: Ekstra peynir, ince hamur (Virgül ile ayırın)'
              : 'Örn: Acısız, Bol Soslu',
          enabled: !_isSaving,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return _RestaurantFormSection(
      title: _isEdit ? 'Fiyatlandırma ve Detaylar' : 'Fiyatlandırma ve Görsel',
      children: <Widget>[
        _RestaurantTextField(
          controller: _priceController,
          label: 'Fiyat',
          hintText: '0,00',
          isRequired: true,
          enabled: !_isSaving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.currency_lira_rounded,
          validator: _priceValidator('Fiyat'),
        ),
        _RestaurantTextField(
          controller: _discountedPriceController,
          label: 'İndirimli Fiyat',
          hintText: '0,00',
          enabled: !_isSaving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.currency_lira_rounded,
          validator: _optionalPriceValidator,
        ),
        if (!_isEdit)
          _RestaurantTextField(
            controller: _imageUrlController,
            label: 'Ürün Görseli URL',
            hintText: 'https://ornek.com/gorsel.jpg',
            isRequired: true,
            enabled: !_isSaving,
            keyboardType: TextInputType.url,
            prefixIcon: Icons.link_rounded,
            validator: _requiredValidator('Ürün Görseli URL'),
          ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isEdit
            ? Row(
                children: <Widget>[
                  Expanded(
                    child: _SecondaryActionButton(
                      label: 'İptal',
                      isEnabled: !_isSaving,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _PrimaryGradientButton(
                      label: 'Kaydet',
                      icon: Icons.check_rounded,
                      isLoading: _isSaving,
                      onPressed: _saveProduct,
                    ),
                  ),
                ],
              )
            : _PrimaryGradientButton(
                label: 'Kaydet',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSaving,
                onPressed: _saveProduct,
              ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_isSaving || _formKey.currentState?.validate() != true) {
      return;
    }

    final SpetoCatalogProduct? product = widget.product;
    final String portionValue = _isEdit
        ? (_selectedPortion ?? '').trim()
        : _portionController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.controller.saveProduct(
        productId: product?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        sectionLabel: portionValue,
        category: (_selectedCategory ?? '').trim(),
        unitPrice: _parseDecimal(_priceController.text) ?? 0,
        imageUrl: _imageUrlController.text.trim(),
        displaySubtitle: _contentInfoController.text.trim(),
        displayBadge: product?.displayBadge ?? '',
        discountedPrice: _discountedPriceController.text.trim().isEmpty
            ? 0
            : _parseDecimal(_discountedPriceController.text) ?? 0,
        unitType: product?.unitType ?? 'adet',
        expiryDate: product?.expiryDate ?? '',
        legacyAliases: _mergeRestaurantLegacyAliases(
          product?.legacyAliases ?? const <String>[],
          prepMinutes: _prepMinutesController.text,
          extras: _extrasController.text,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_formatErrorMessage(error))));
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String? Function(String?) _requiredValidator(String label) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$label zorunludur';
      }
      return null;
    };
  }

  String? Function(String?) _priceValidator(String label) {
    return (String? value) {
      final double? parsed = _parseDecimal(value ?? '');
      if (parsed == null) {
        return '$label zorunludur';
      }
      if (parsed < 0) {
        return '$label negatif olamaz';
      }
      return null;
    };
  }

  String? Function(String?) _wholeNumberValidator(String label) {
    return (String? value) {
      final int? parsed = int.tryParse(value?.trim() ?? '');
      if (parsed == null) {
        return '$label zorunludur';
      }
      if (parsed < 0) {
        return '$label negatif olamaz';
      }
      return null;
    };
  }

  String? _optionalWholeNumberValidator(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final int? parsed = int.tryParse(normalized);
    if (parsed == null) {
      return 'Geçerli bir sayı girin';
    }
    if (parsed < 0) {
      return 'Negatif değer kullanılamaz';
    }
    return null;
  }

  String? _optionalPriceValidator(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final double? parsed = _parseDecimal(normalized);
    if (parsed == null) {
      return 'Geçerli bir fiyat girin';
    }
    if (parsed < 0) {
      return 'Negatif fiyat kullanılamaz';
    }
    return null;
  }
}

class _RestaurantFormSection extends StatelessWidget {
  const _RestaurantFormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          for (int index = 0; index < children.length; index++) ...<Widget>[
            children[index],
            if (index != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _RestaurantTextField extends StatelessWidget {
  const _RestaurantTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.suffixText,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label: label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _restaurantInputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixText: suffixText,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _RestaurantDropdownField extends StatelessWidget {
  const _RestaurantDropdownField({
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
  });

  final String label;
  final String hintText;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label: label, isRequired: isRequired),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value?.trim().isEmpty ?? true ? null : value,
          isExpanded: true,
          decoration: _restaurantInputDecoration(hintText: hintText),
          items: items
              .map(
                (String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: enabled ? onChanged : null,
          validator: validator,
          hint: Text(
            hintText,
            style: const TextStyle(color: AppColors.slate400),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.isRequired});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        children: <InlineSpan>[
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF068D46), Color(0xFF2ECC71)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.emerald700.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.isEnabled,
    required this.onPressed,
  });

  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImagePreview extends StatelessWidget {
  const _ProductImagePreview({
    required this.imageUrl,
    required this.label,
    this.borderRadius = 20,
  });

  final String imageUrl;
  final String label;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl.trim().isEmpty
          ? Container(
              color: AppColors.slate100,
              alignment: Alignment.center,
              child: Icon(
                Icons.inventory_2_outlined,
                color: AppColors.slate400,
                size: 28,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.slate100,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.slate400,
                  size: 28,
                ),
              ),
            ),
    );
  }
}

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard({this.message = 'Gösterilecek ürün bulunamadı.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.slate500,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
      ),
    );
  }
}

InputDecoration _restaurantInputDecoration({
  String? hintText,
  IconData? prefixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: AppColors.slate400),
    filled: true,
    fillColor: const Color(0xFFF0F2F4),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: AppColors.slate400, size: 18),
    suffixText: suffixText,
    suffixStyle: const TextStyle(
      color: AppColors.slate500,
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.emerald200),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}

String _restaurantCategoryLabel(SpetoCatalogProduct product) {
  final String category = product.category.trim();
  if (category.isNotEmpty) {
    return category;
  }
  final String section = product.sectionLabel.trim();
  if (section.isNotEmpty) {
    return section;
  }
  return 'Diğer';
}

String _restaurantProductSubtitle(SpetoCatalogProduct product) {
  final String section = product.sectionLabel.trim();
  final String category = product.category.trim();
  if (section.isNotEmpty && section.toLowerCase() != category.toLowerCase()) {
    return section;
  }
  final String subtitle = product.displaySubtitle.trim();
  if (subtitle.isNotEmpty) {
    return subtitle;
  }
  final String description = product.description.trim();
  if (description.isNotEmpty) {
    return description;
  }
  return _restaurantCategoryLabel(product);
}

String _restaurantProductImage(
  SpetoCatalogProduct product,
  SpetoInventoryItem? inventoryItem,
) {
  final String imageUrl = product.imageUrl.trim();
  if (imageUrl.isNotEmpty) {
    return imageUrl;
  }
  final String inventoryImage = inventoryItem?.imageUrl.trim() ?? '';
  if (inventoryImage.isNotEmpty) {
    return inventoryImage;
  }
  return product.image.trim();
}

String _extractRestaurantAliasValue(List<String> aliases, String prefix) {
  for (final String alias in aliases) {
    if (alias.startsWith(prefix)) {
      return alias.substring(prefix.length);
    }
  }
  return '';
}

List<String> _mergeRestaurantLegacyAliases(
  List<String> aliases, {
  required String prepMinutes,
  required String extras,
}) {
  final List<String> merged = aliases
      .where(
        (String alias) =>
            !alias.startsWith(_restaurantPrepAliasPrefix) &&
            !alias.startsWith(_restaurantExtrasAliasPrefix),
      )
      .toList(growable: true);
  final String prep = prepMinutes.trim();
  final String extrasValue = extras.trim();
  if (prep.isNotEmpty) {
    merged.add('$_restaurantPrepAliasPrefix$prep');
  }
  if (extrasValue.isNotEmpty) {
    merged.add('$_restaurantExtrasAliasPrefix$extrasValue');
  }
  return merged;
}

bool _containsValue(List<String> options, String? value) {
  if (value == null || value.trim().isEmpty) {
    return false;
  }
  return options.contains(value.trim());
}

String? _resolveInitialDropdownValue(String value, List<String> options) {
  final String normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  if (options.contains(normalized)) {
    return normalized;
  }
  return normalized;
}

double? _parseDecimal(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.'));
}

String _formatDecimalInput(double value) {
  final bool hasFraction = value % 1 != 0;
  return value.toStringAsFixed(hasFraction ? 2 : 0).replaceAll('.', ',');
}

String _formatCurrency(double value) {
  final bool hasFraction = value % 1 != 0;
  final String amount = value
      .toStringAsFixed(hasFraction ? 2 : 0)
      .replaceAll('.', ',');
  return '₺$amount';
}

String _formatErrorMessage(Object error) {
  final String message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message;
}
