import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import '../../widgets/vendor_picker_button.dart';

enum ProductScreenMode { restaurant, market }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.mode});

  final ProductScreenMode? mode;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const List<_ProductImageOption>
  _marketImagePresets = <_ProductImageOption>[
    _ProductImageOption(
      label: 'Manav reyonu',
      url:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=900&q=80',
    ),
    _ProductImageOption(
      label: 'Süt ve kahvaltılık',
      url:
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=900&q=80',
    ),
    _ProductImageOption(
      label: 'Atıştırmalık',
      url:
          'https://images.unsplash.com/photo-1585238342024-78d387f4a707?auto=format&fit=crop&w=900&q=80',
    ),
    _ProductImageOption(
      label: 'Hazır gıda',
      url:
          'https://images.unsplash.com/photo-1506084868230-bb9d95c24759?auto=format&fit=crop&w=900&q=80',
    ),
  ];
  static const List<_ProductImageOption>
  _restaurantImagePresets = <_ProductImageOption>[
    _ProductImageOption(
      label: 'Burger tabağı',
      url:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
    ),
    _ProductImageOption(
      label: 'Pizza servisi',
      url:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    ),
    _ProductImageOption(
      label: 'Tatlı seçkisi',
      url:
          'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=900&q=80',
    ),
    _ProductImageOption(
      label: 'İçecek',
      url:
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=900&q=80',
    ),
  ];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final ProductScreenMode resolvedMode =
        widget.mode ??
        (controller.isRestaurantMode
            ? ProductScreenMode.restaurant
            : ProductScreenMode.market);
    final Map<String, SpetoInventoryItem> inventoryByProductId =
        <String, SpetoInventoryItem>{
          for (final item in controller.inventoryItems) item.id: item,
        };
    final String query = _searchController.text.trim().toLowerCase();
    final List<SpetoCatalogProduct> visibleProducts = controller.products
        .where((product) {
          if (query.isEmpty) {
            return true;
          }
          return product.title.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query) ||
              product.sectionLabel.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        title: Row(
          children: <Widget>[
            Icon(
              resolvedMode == ProductScreenMode.restaurant
                  ? Icons.restaurant
                  : Icons.inventory_2,
              color: AppColors.emerald700,
            ),
            const SizedBox(width: 8),
            Text(
              resolvedMode == ProductScreenMode.restaurant
                  ? 'Yönetici Paneli'
                  : 'Ürünler',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.emerald800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          VendorPickerButton(controller: controller),
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: AppColors.emerald700,
            ),
            onPressed: () => _showProductDialog(context, controller),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: AppColors.slate400),
                  hintText: 'Ürün ara...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: resolvedMode == ProductScreenMode.restaurant
          ? _buildRestaurantLayout(
              controller,
              visibleProducts,
              inventoryByProductId,
            )
          : _buildMarketLayout(
              controller,
              visibleProducts,
              inventoryByProductId,
            ),
    );
  }

  Widget _buildRestaurantLayout(
    StockAppController controller,
    List<SpetoCatalogProduct> products,
    Map<String, SpetoInventoryItem> inventoryByProductId,
  ) {
    final int activeCount = products.where((p) => !p.isArchived).length;
    final int archivedCount = products.where((p) => p.isArchived).length;
    final int campaignCount = controller.campaignSummary?.campaigns.length ?? 0;

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 120, left: 24, right: 24),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            const Column(
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
                  'Mağaza envanterinizi yönetin',
                  style: TextStyle(fontSize: 14, color: AppColors.slate500),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _showProductDialog(context, controller),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Yeni Ekle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: <Widget>[
            _buildStatCard(
              'Toplam',
              '${products.length}',
              Icons.inventory_2,
              AppColors.surfaceContainerHigh,
              AppColors.primary,
            ),
            _buildStatCard(
              'Aktif',
              '$activeCount',
              Icons.check_circle,
              AppColors.primaryContainer.withValues(alpha: 0.2),
              AppColors.primary,
            ),
            _buildStatCard(
              'Pasif',
              '$archivedCount',
              Icons.cancel,
              const Color(0xFFFFDAD6).withValues(alpha: 0.5),
              AppColors.error,
            ),
            _buildStatCard(
              'Kampanya',
              '$campaignCount',
              Icons.campaign,
              const Color(0xFFFFB59D).withValues(alpha: 0.4),
              const Color(0xFF98472A),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (products.isEmpty)
          const _EmptyProductsCard()
        else
          for (final product in products)
            _buildRestaurantProductCard(
              context,
              controller,
              product,
              inventoryByProductId[product.id],
            ),
      ],
    );
  }

  Widget _buildMarketLayout(
    StockAppController controller,
    List<SpetoCatalogProduct> products,
    Map<String, SpetoInventoryItem> inventoryByProductId,
  ) {
    final int expiringCount =
        controller.campaignSummary?.criticalProductCount ?? 0;
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 120, left: 16, right: 16),
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _buildMarketStatCard(
                'Toplam Ürün',
                '${products.length}',
                AppColors.emerald700,
              ),
              _buildMarketStatCard(
                'Stok Azalan',
                '${controller.inventorySnapshot?.lowStockCount ?? 0}',
                AppColors.error,
              ),
              _buildMarketStatCard(
                'SKT Yaklaşan',
                '$expiringCount',
                const Color(0xFFD97706),
              ),
              _buildMarketStatCard(
                'Kampanyada',
                '${controller.campaignSummary?.activeCount ?? 0}',
                AppColors.emerald500,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          const _EmptyProductsCard()
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.75,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: products
                .map(
                  (product) => _buildMarketProductCard(
                    context,
                    controller,
                    product,
                    inventoryByProductId[product.id],
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconBg,
    Color iconCol,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconCol, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantProductCard(
    BuildContext context,
    StockAppController controller,
    SpetoCatalogProduct product,
    SpetoInventoryItem? inventoryItem,
  ) {
    final bool lowStock =
        product.stockStatus.lowStock || !product.stockStatus.isInStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              imageUrl: product.imageUrl,
              label: product.title,
              badge: lowStock
                  ? _ImageBadge(
                      label: product.stockStatus.isInStock
                          ? 'Azaldı'
                          : 'Tükendi',
                      backgroundColor: product.stockStatus.isInStock
                          ? const Color(0xFFFFF1D6)
                          : const Color(0xFFFEE2E2),
                      foregroundColor: product.stockStatus.isInStock
                          ? const Color(0xFF92400E)
                          : AppColors.error,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.isArchived
                            ? const Color(0xFFF1F5F9)
                            : AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.isArchived ? 'PASİF' : 'AKTİF',
                        style: TextStyle(
                          color: product.isArchived
                              ? AppColors.slate500
                              : AppColors.emerald800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  product.displaySubtitle.isEmpty
                      ? product.sectionLabel
                      : product.displaySubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      product.priceText,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Stok: ${inventoryItem?.availableQuantity ?? product.stockStatus.availableQuantity}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _showRestockDialog(context, controller, product.id),
                        child: const Text('Stok Girişi'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showProductDialog(
                        context,
                        controller,
                        product: product,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStatCard(String title, String value, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketProductCard(
    BuildContext context,
    StockAppController controller,
    SpetoCatalogProduct product,
    SpetoInventoryItem? inventoryItem,
  ) {
    final int availableQuantity =
        inventoryItem?.availableQuantity ??
        product.stockStatus.availableQuantity;
    final String badgeText = !product.stockStatus.isInStock
        ? 'Tükendi'
        : product.stockStatus.lowStock
        ? 'Stok Azalıyor'
        : product.displayBadge;
    final Color badgeColor = !product.stockStatus.isInStock
        ? AppColors.error
        : product.stockStatus.lowStock
        ? const Color(0xFFD97706)
        : AppColors.emerald700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _ProductImagePreview(
                imageUrl: product.imageUrl,
                label: product.title,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            product.priceText,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stok: $availableQuantity',
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 8),
          if (badgeText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                _showRestockDialog(context, controller, product.id),
            child: const Text('Stoğu Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context,
    StockAppController controller, {
    SpetoCatalogProduct? product,
  }) async {
    final TextEditingController titleController = TextEditingController(
      text: product?.title ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: product?.unitPrice.toStringAsFixed(2) ?? '',
    );
    final TextEditingController subtitleController = TextEditingController(
      text: product?.displaySubtitle ?? '',
    );
    final List<String> categoryOptions = _categoryOptions(controller, product);
    final List<String> sectionOptions = _sectionOptions(
      controller,
      product,
      categoryOptions,
    );
    final List<_ProductImageOption> imageOptions = _imageOptions(
      controller,
      product,
    );
    String selectedCategory = _initialSelection(
      currentValue: product?.category ?? '',
      options: categoryOptions,
      fallback:
          controller.selectedVendor?.cuisine ??
          (controller.isRestaurantMode ? 'Restoran' : 'Market'),
    );
    String selectedSection = _initialSelection(
      currentValue: product?.sectionLabel ?? '',
      options: sectionOptions,
      fallback: sectionOptions.first,
    );
    String selectedImageUrl = _initialImageUrl(
      currentValue: product?.imageUrl ?? '',
      options: imageOptions,
    );
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(product == null ? 'Yeni Ürün' : 'Ürünü Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Ürün adı'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Açıklama'),
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categoryOptions
                          .map(
                            (String option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSection,
                      decoration: const InputDecoration(labelText: 'Bölüm'),
                      items: sectionOptions
                          .map(
                            (String option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedSection = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _ImagePickerField(
                      selectedUrl: selectedImageUrl,
                      options: imageOptions,
                      onTap: () async {
                        final String? pickedImage = await _showImagePickerSheet(
                          context,
                          options: imageOptions,
                          selectedUrl: selectedImageUrl,
                        );
                        if (pickedImage == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedImageUrl = pickedImage;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Alt metin'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Fiyat'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved == true) {
      await controller.saveProduct(
        productId: product?.id,
        title: titleController.text,
        description: descriptionController.text,
        sectionLabel: selectedSection,
        category: selectedCategory,
        unitPrice:
            double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
        imageUrl: selectedImageUrl,
        displaySubtitle: subtitleController.text,
      );
    }
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    subtitleController.dispose();
  }

  List<String> _categoryOptions(
    StockAppController controller,
    SpetoCatalogProduct? product,
  ) {
    final Set<String> options = <String>{};
    final SpetoCatalogVendor? vendor = controller.selectedVendor;
    final List<String> fallbackOptions = controller.isRestaurantMode
        ? const <String>[
            'Burger',
            'Pizza',
            'Tavuk',
            'Tatlı',
            'İçecek',
            'Menü',
            'Kahve',
          ]
        : const <String>[
            'Market',
            'Süt & Kahvaltılık',
            'Atıştırmalık',
            'İçecek',
            'Meyve & Sebze',
            'Hazır Gıda',
            'Unlu Mamuller',
          ];

    if (product != null && product.category.trim().isNotEmpty) {
      options.add(product.category.trim());
    }
    if (vendor != null) {
      if (vendor.cuisine.trim().isNotEmpty) {
        options.add(vendor.cuisine.trim());
      }
      if (vendor.storefrontType == SpetoStorefrontType.market) {
        options.add('Market');
      }
    }
    for (final SpetoCatalogProduct item in controller.products) {
      if (item.category.trim().isNotEmpty) {
        options.add(item.category.trim());
      }
    }
    options.addAll(fallbackOptions);
    return _sortedOptions(options, fallback: fallbackOptions.first);
  }

  List<String> _sectionOptions(
    StockAppController controller,
    SpetoCatalogProduct? product,
    List<String> categoryOptions,
  ) {
    final Set<String> options = <String>{};
    final SpetoCatalogVendor? vendor = controller.selectedVendor;

    if (product != null && product.sectionLabel.trim().isNotEmpty) {
      options.add(product.sectionLabel.trim());
    }
    if (vendor != null) {
      for (final SpetoCatalogSection section in vendor.sections) {
        if (section.label.trim().isNotEmpty) {
          options.add(section.label.trim());
        }
      }
    }
    for (final SpetoCatalogProduct item in controller.products) {
      if (item.sectionLabel.trim().isNotEmpty) {
        options.add(item.sectionLabel.trim());
      }
    }
    if (options.isEmpty) {
      options.addAll(categoryOptions);
    }
    if (options.isEmpty) {
      options.add('Genel');
    }
    return _sortedOptions(options, fallback: 'Genel');
  }

  List<String> _sortedOptions(Set<String> options, {required String fallback}) {
    final List<String> values = options
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    values.sort((String left, String right) => left.compareTo(right));
    if (values.isEmpty) {
      return <String>[fallback];
    }
    return values;
  }

  String _initialSelection({
    required String currentValue,
    required List<String> options,
    required String fallback,
  }) {
    final String normalizedCurrent = currentValue.trim();
    if (normalizedCurrent.isNotEmpty) {
      return normalizedCurrent;
    }
    if (options.isNotEmpty) {
      return options.first;
    }
    return fallback;
  }

  List<_ProductImageOption> _imageOptions(
    StockAppController controller,
    SpetoCatalogProduct? product,
  ) {
    final Map<String, _ProductImageOption> optionsByUrl =
        <String, _ProductImageOption>{};
    void addOption(_ProductImageOption option) {
      if (option.url.trim().isEmpty) {
        return;
      }
      optionsByUrl.putIfAbsent(option.url, () => option);
    }

    final SpetoCatalogVendor? vendor = controller.selectedVendor;
    if (vendor != null && vendor.image.trim().isNotEmpty) {
      addOption(
        _ProductImageOption(
          label: '${vendor.title} kapak görseli',
          url: vendor.image,
        ),
      );
    }
    if (product != null && product.imageUrl.trim().isNotEmpty) {
      addOption(
        _ProductImageOption(
          label: '${product.title} mevcut fotoğrafı',
          url: product.imageUrl,
        ),
      );
    }
    for (final SpetoCatalogProduct item in controller.products) {
      if (item.imageUrl.trim().isNotEmpty) {
        addOption(_ProductImageOption(label: item.title, url: item.imageUrl));
      }
    }
    final List<_ProductImageOption> presets = controller.isRestaurantMode
        ? _restaurantImagePresets
        : _marketImagePresets;
    for (final _ProductImageOption option in presets) {
      addOption(option);
    }
    return optionsByUrl.values.toList(growable: false);
  }

  String _initialImageUrl({
    required String currentValue,
    required List<_ProductImageOption> options,
  }) {
    final String normalizedCurrent = currentValue.trim();
    if (normalizedCurrent.isNotEmpty) {
      return normalizedCurrent;
    }
    if (options.isEmpty) {
      return '';
    }
    return options.first.url;
  }

  Future<String?> _showImagePickerSheet(
    BuildContext context, {
    required List<_ProductImageOption> options,
    required String selectedUrl,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Fotoğraf seç',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
                title: const Text('Fotoğraf kullanma'),
                trailing: selectedUrl.isEmpty
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(''),
              ),
              for (final _ProductImageOption option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      option.url,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.slate100,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  title: Text(option.label),
                  subtitle: Text(
                    option.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: option.url == selectedUrl
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(option.url),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRestockDialog(
    BuildContext context,
    StockAppController controller,
    String productId,
  ) async {
    final TextEditingController qtyController = TextEditingController(
      text: '10',
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stok Girişi'),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Miktar'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await controller.restockInventory(
        productId: productId,
        quantity: int.tryParse(qtyController.text) ?? 0,
        note: 'SepetPro İşyeri manuel giriş',
      );
    }
    qtyController.dispose();
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.selectedUrl,
    required this.options,
    required this.onTap,
  });

  final String selectedUrl;
  final List<_ProductImageOption> options;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _ProductImageOption? selectedOption = options
        .cast<_ProductImageOption?>()
        .firstWhere(
          (_ProductImageOption? option) => option?.url == selectedUrl,
          orElse: () => null,
        );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fotoğraf',
          suffixIcon: Icon(Icons.expand_more),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: selectedUrl.isEmpty
                  ? Container(
                      width: 56,
                      height: 56,
                      color: AppColors.slate100,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined),
                    )
                  : Image.network(
                      selectedUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.slate100,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedOption?.label ??
                    (selectedUrl.isEmpty
                        ? 'Listeden fotoğraf seç'
                        : selectedUrl),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImageOption {
  const _ProductImageOption({required this.label, required this.url});

  final String label;
  final String url;
}

class _ProductImagePreview extends StatelessWidget {
  const _ProductImagePreview({
    required this.imageUrl,
    required this.label,
    this.badge,
  });

  final String imageUrl;
  final String label;
  final _ImageBadge? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
        ),
        if (badge != null)
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badge!.backgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!.label,
                style: TextStyle(
                  color: badge!.foregroundColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageBadge {
  const _ImageBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Gösterilecek ürün bulunamadı.',
        style: TextStyle(
          color: AppColors.slate500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
