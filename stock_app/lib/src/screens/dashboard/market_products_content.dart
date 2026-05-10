import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../theme/app_colors.dart';

class MarketProductsContent extends StatefulWidget {
  const MarketProductsContent({
    super.key,
    required this.products,
    required this.inventoryByProductId,
    required this.onAddProduct,
    required this.onEditProduct,
  });

  final List<SpetoCatalogProduct> products;
  final Map<String, SpetoInventoryItem> inventoryByProductId;
  final VoidCallback onAddProduct;
  final ValueChanged<SpetoCatalogProduct> onEditProduct;

  @override
  State<MarketProductsContent> createState() => _MarketProductsContentState();
}

enum _MarketProductsFilter { all, inStock, lowStock, expiringSoon }

class _MarketProductsContentState extends State<MarketProductsContent> {
  _MarketProductsFilter _selectedFilter = _MarketProductsFilter.all;

  @override
  Widget build(BuildContext context) {
    final List<SpetoCatalogProduct> activeProducts = widget.products
        .where((SpetoCatalogProduct product) => !product.isArchived)
        .toList(growable: false);
    final _MarketMetrics metrics = _MarketMetrics.fromProducts(
      activeProducts,
      widget.inventoryByProductId,
    );
    final List<SpetoCatalogProduct> filteredProducts = _filterProducts(
      activeProducts,
    );
    final List<SpetoCatalogProduct> displayedProducts = filteredProducts
        .take(4)
        .toList(growable: false);
    final _MarketHighlightData? highlight = _pickHighlight(activeProducts);

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 76, 16, 140),
        children: <Widget>[
          _MarketStatsRow(metrics: metrics),
          const SizedBox(height: 24),
          _MarketTabs(
            selectedFilter: _selectedFilter,
            onSelected: (_MarketProductsFilter filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _AddProductTile(onTap: widget.onAddProduct),
              ...displayedProducts.map(
                (SpetoCatalogProduct product) => _MarketProductTile(
                  product: product,
                  inventoryItem: widget.inventoryByProductId[product.id],
                  onEdit: () => widget.onEditProduct(product),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (highlight != null)
            _MarketHighlightSection(
              data: highlight,
              onViewAll: () {
                setState(() {
                  _selectedFilter = _MarketProductsFilter.expiringSoon;
                });
              },
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  List<SpetoCatalogProduct> _filterProducts(
    List<SpetoCatalogProduct> products,
  ) {
    final List<SpetoCatalogProduct> sortedProducts = products.toList(
      growable: false,
    )..sort(_compareProducts);
    return sortedProducts
        .where((SpetoCatalogProduct product) {
          return switch (_selectedFilter) {
            _MarketProductsFilter.all => true,
            _MarketProductsFilter.inStock => _availableQuantity(product) > 0,
            _MarketProductsFilter.lowStock => _isLowStock(product),
            _MarketProductsFilter.expiringSoon => _isExpiringSoon(product),
          };
        })
        .toList(growable: false);
  }

  int _compareProducts(SpetoCatalogProduct left, SpetoCatalogProduct right) {
    final int priorityDifference =
        _productPriority(right) - _productPriority(left);
    if (priorityDifference != 0) {
      return priorityDifference;
    }
    return left.displayOrder.compareTo(right.displayOrder);
  }

  int _productPriority(SpetoCatalogProduct product) {
    if (_expiresToday(product)) {
      return 4;
    }
    if (_hasDiscount(product)) {
      return 3;
    }
    if (_isLowStock(product)) {
      return 2;
    }
    if (_isExpiringSoon(product)) {
      return 1;
    }
    return 0;
  }

  _MarketHighlightData? _pickHighlight(List<SpetoCatalogProduct> products) {
    if (products.isEmpty) {
      return null;
    }
    final List<SpetoCatalogProduct> rankedProducts = products.toList(
      growable: false,
    )..sort(_compareProducts);
    final SpetoCatalogProduct product = rankedProducts.first;
    final SpetoInventoryItem? inventoryItem =
        widget.inventoryByProductId[product.id];
    final int availableQuantity = _availableQuantity(product);
    final bool lowStock = _isLowStock(product);
    final bool expiringToday = _expiresToday(product);
    final String badgeLabel = lowStock
        ? 'KRITIK\nSTOK'
        : expiringToday
        ? 'BUGÜN\nSON'
        : 'SKT\nYAKIN';
    final Color badgeBackground = lowStock
        ? const Color(0x1ABA1A1A)
        : const Color(0x1AF59E0B);
    final Color badgeForeground = lowStock
        ? AppColors.error
        : const Color(0xFFD97706);
    final String remainingUnit = _uppercaseFirst(
      (inventoryItem?.unitType ?? product.unitType).trim(),
    );
    final int targetStock = math.max(
      1,
      math.max(product.reorderLevel, availableQuantity + 4),
    );
    final double progress = availableQuantity <= 0
        ? 0.08
        : math.max(0.12, math.min(1, availableQuantity / targetStock));

    return _MarketHighlightData(
      product: product,
      title: product.title.trim().isEmpty ? 'Ürün' : product.title,
      badgeLabel: badgeLabel,
      badgeBackground: badgeBackground,
      badgeForeground: badgeForeground,
      remainingText: 'Kalan: $availableQuantity\n$remainingUnit',
      progress: progress,
    );
  }

  bool _hasDiscount(SpetoCatalogProduct product) {
    return product.discountedPrice > 0 &&
        product.discountedPrice < product.unitPrice;
  }

  bool _isLowStock(SpetoCatalogProduct product) {
    if (!product.stockStatus.isInStock) {
      return true;
    }
    return product.stockStatus.lowStock ||
        _availableQuantity(product) <= math.max(3, product.reorderLevel);
  }

  bool _expiresToday(SpetoCatalogProduct product) {
    final int? days = _daysUntilExpiry(product);
    return days != null && days <= 0;
  }

  bool _isExpiringSoon(SpetoCatalogProduct product) {
    final int? days = _daysUntilExpiry(product);
    return days != null && days <= 3;
  }

  int? _daysUntilExpiry(SpetoCatalogProduct product) {
    final DateTime? expiryDate = _expiryDate(product);
    if (expiryDate == null) {
      return null;
    }
    final DateTime today = DateTime.now();
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final DateTime normalizedExpiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    return normalizedExpiry.difference(normalizedToday).inDays;
  }

  DateTime? _expiryDate(SpetoCatalogProduct product) {
    final String rawDate =
        (widget.inventoryByProductId[product.id]?.expiryDate ??
                product.expiryDate)
            .trim();
    if (rawDate.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawDate);
  }

  int _availableQuantity(SpetoCatalogProduct product) {
    return widget.inventoryByProductId[product.id]?.availableQuantity ??
        product.stockStatus.availableQuantity;
  }
}

class _MarketMetrics {
  const _MarketMetrics({
    required this.totalCount,
    required this.lowStockCount,
    required this.expiringCount,
    required this.campaignCount,
  });

  final int totalCount;
  final int lowStockCount;
  final int expiringCount;
  final int campaignCount;

  factory _MarketMetrics.fromProducts(
    List<SpetoCatalogProduct> products,
    Map<String, SpetoInventoryItem> inventoryByProductId,
  ) {
    int lowStockCount = 0;
    int expiringCount = 0;
    int campaignCount = 0;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    for (final SpetoCatalogProduct product in products) {
      final int availableQuantity =
          inventoryByProductId[product.id]?.availableQuantity ??
          product.stockStatus.availableQuantity;
      final bool lowStock =
          !product.stockStatus.isInStock ||
          product.stockStatus.lowStock ||
          availableQuantity <= math.max(3, product.reorderLevel);
      if (lowStock) {
        lowStockCount++;
      }

      final String rawDate =
          (inventoryByProductId[product.id]?.expiryDate ?? product.expiryDate)
              .trim();
      final DateTime? expiryDate = rawDate.isEmpty
          ? null
          : DateTime.tryParse(rawDate);
      if (expiryDate != null) {
        final DateTime normalizedExpiry = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        );
        if (normalizedExpiry.difference(today).inDays <= 3) {
          expiringCount++;
        }
      }

      if (product.discountedPrice > 0 &&
              product.discountedPrice < product.unitPrice ||
          product.displayBadge.trim().isNotEmpty) {
        campaignCount++;
      }
    }

    return _MarketMetrics(
      totalCount: products.length,
      lowStockCount: lowStockCount,
      expiringCount: expiringCount,
      campaignCount: campaignCount,
    );
  }
}

class _MarketStatsRow extends StatelessWidget {
  const _MarketStatsRow({required this.metrics});

  final _MarketMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final List<_MetricCardData> cards = <_MetricCardData>[
      _MetricCardData(
        title: 'TOPLAM ÜRÜN',
        value: '${metrics.totalCount}',
        valueColor: AppColors.emerald700,
      ),
      _MetricCardData(
        title: 'STOK AZALAN',
        value: '${metrics.lowStockCount}',
        valueColor: AppColors.error,
      ),
      _MetricCardData(
        title: 'SKT YAKLAŞAN',
        value: '${metrics.expiringCount}',
        valueColor: AppColors.amber600,
      ),
      _MetricCardData(
        title: 'KAMPANYADA',
        value: '${metrics.campaignCount}',
        valueColor: AppColors.emerald500,
      ),
    ];

    return SizedBox(
      height: 94.5,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final _MetricCardData card = cards[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.slate100),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  card.title,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: 0.55,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.33,
                    color: card.valueColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color valueColor;
}

class _MarketTabs extends StatelessWidget {
  const _MarketTabs({required this.selectedFilter, required this.onSelected});

  final _MarketProductsFilter selectedFilter;
  final ValueChanged<_MarketProductsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<(_MarketProductsFilter, String)> options =
        <(_MarketProductsFilter, String)>[
          (_MarketProductsFilter.all, 'Tümü'),
          (_MarketProductsFilter.inStock, 'Stokta Var'),
          (_MarketProductsFilter.lowStock, 'Azalan'),
          (_MarketProductsFilter.expiringSoon, 'SKT Yaklaşan'),
        ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(4),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final (_MarketProductsFilter, String) option = options[index];
          final bool isSelected = option.$1 == selectedFilter;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(option.$1),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: Center(
                  child: Text(
                    option.$2,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      height: 1.43,
                      color: isSelected
                          ? AppColors.emerald700
                          : AppColors.slate500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddProductTile extends StatelessWidget {
  const _AddProductTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 171,
      height: 254.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.emerald600,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.emerald500),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.18),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ürün Ekle',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'YENI STOK GIRIŞI',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.5,
                    color: const Color(0xFFD1FAE5),
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

class _MarketProductTile extends StatelessWidget {
  const _MarketProductTile({
    required this.product,
    required this.inventoryItem,
    required this.onEdit,
  });

  final SpetoCatalogProduct product;
  final SpetoInventoryItem? inventoryItem;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final double visiblePrice =
        product.discountedPrice > 0 &&
            product.discountedPrice < product.unitPrice
        ? product.discountedPrice
        : product.unitPrice;
    final int availableQuantity =
        inventoryItem?.availableQuantity ??
        product.stockStatus.availableQuantity;
    final int? daysUntilExpiry = _daysUntilExpiry(product, inventoryItem);
    final bool expiresToday = daysUntilExpiry != null && daysUntilExpiry <= 0;
    final bool expiringSoon = daysUntilExpiry != null && daysUntilExpiry <= 3;
    final bool lowStock =
        !product.stockStatus.isInStock ||
        product.stockStatus.lowStock ||
        availableQuantity <= math.max(3, product.reorderLevel);
    final bool hasDiscount =
        product.discountedPrice > 0 &&
        product.discountedPrice < product.unitPrice;
    final int discountPercent = hasDiscount && product.unitPrice > 0
        ? ((1 - (product.discountedPrice / product.unitPrice)) * 100).round()
        : 0;

    return SizedBox(
      width: 171,
      height: 254,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Stack(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 137,
                        height: 137,
                        child: _ProductImage(
                          imageUrl: _productImage(product, inventoryItem),
                          title: product.title,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.title.trim().isEmpty ? 'Ürün' : product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.43,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3.5),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _formatCurrency(visiblePrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.56,
                              color: AppColors.emerald700,
                            ),
                          ),
                        ),
                        if (hasDiscount && !expiresToday && !expiringSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '%$discountPercent',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: AppColors.emerald700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3.5),
                    if (expiresToday || expiringSoon)
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.schedule_rounded,
                            size: 10,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              expiresToday ? 'BUGÜN SON' : 'SKT YAKLAŞIYOR',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (lowStock)
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.trending_down_rounded,
                            size: 11,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              product.stockStatus.isInStock
                                  ? 'STOK AZALIYOR'
                                  : 'TÜKENDİ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _stockLabel(
                          availableQuantity,
                          inventoryItem?.unitType ?? product.unitType,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: AppColors.slate400,
                        ),
                      ),
                  ],
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.82),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onEdit,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.slate100),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static DateTime? _expiryDate(
    SpetoCatalogProduct product,
    SpetoInventoryItem? inventoryItem,
  ) {
    final String rawDate = (inventoryItem?.expiryDate ?? product.expiryDate)
        .trim();
    if (rawDate.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawDate);
  }

  static int? _daysUntilExpiry(
    SpetoCatalogProduct product,
    SpetoInventoryItem? inventoryItem,
  ) {
    final DateTime? expiryDate = _expiryDate(product, inventoryItem);
    if (expiryDate == null) {
      return null;
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime normalizedExpiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    return normalizedExpiry.difference(today).inDays;
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: AppColors.slate100,
        alignment: Alignment.center,
        child: Icon(
          Icons.inventory_2_outlined,
          color: AppColors.slate400,
          size: 28,
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              Container(
                color: AppColors.slate100,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.slate400,
                  size: 28,
                ),
              ),
      semanticLabel: title,
    );
  }
}

class _MarketHighlightSection extends StatelessWidget {
  const _MarketHighlightSection({required this.data, required this.onViewAll});

  final _MarketHighlightData data;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Bugün Bitecek Ürünler',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.56,
                  letterSpacing: -0.45,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'TÜMÜNÜ GÖR',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                  letterSpacing: 1.2,
                  color: AppColors.emerald700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 114,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _ProductImage(
                    imageUrl: _productImage(data.product, null),
                    title: data.title,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                            color: data.badgeBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            data.badgeLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              color: data.badgeForeground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.remainingText,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                              color: AppColors.slate500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: data.progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.emerald50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.emerald700,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarketHighlightData {
  const _MarketHighlightData({
    required this.product,
    required this.title,
    required this.badgeLabel,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.remainingText,
    required this.progress,
  });

  final SpetoCatalogProduct product;
  final String title;
  final String badgeLabel;
  final Color badgeBackground;
  final Color badgeForeground;
  final String remainingText;
  final double progress;
}

String _productImage(
  SpetoCatalogProduct product,
  SpetoInventoryItem? inventoryItem,
) {
  final String primary = product.imageUrl.trim();
  if (primary.isNotEmpty) {
    return primary;
  }
  final String secondary = inventoryItem?.imageUrl.trim() ?? '';
  if (secondary.isNotEmpty) {
    return secondary;
  }
  return product.image.trim();
}

String _formatCurrency(double value) {
  return '₺${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _stockLabel(int quantity, String unitType) {
  final String normalizedUnit = unitType.trim().isEmpty
      ? 'Adet'
      : _uppercaseFirst(unitType.trim());
  return 'Stok: $quantity $normalizedUnit';
}

String _uppercaseFirst(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
