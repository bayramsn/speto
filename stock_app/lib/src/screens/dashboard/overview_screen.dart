import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

DateTime? _parseOverviewPlacedAt(SpetoOpsOrder order) {
  final Match? match = RegExp(
    r'(\d{2})\.(\d{2})\.(\d{4})\s*•\s*(\d{2}):(\d{2})',
  ).firstMatch(order.placedAtLabel);
  if (match == null) {
    return null;
  }
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

bool _isTodayOrder(SpetoOpsOrder order) {
  final DateTime? placedAt = _parseOverviewPlacedAt(order);
  if (placedAt == null) {
    return order.placedAtLabel.toLowerCase().contains('bugün');
  }
  return _isSameDay(placedAt, DateTime.now());
}

String _currency(double value) {
  final String normalized = value.toStringAsFixed(2).replaceAll('.', ',');
  return '₺$normalized';
}

String _compactTimeLabel(SpetoOpsOrder order) {
  final DateTime? placedAt = _parseOverviewPlacedAt(order);
  if (placedAt != null) {
    final Duration difference = DateTime.now().difference(placedAt);
    if (difference.inMinutes < 60) {
      return '${math.max(1, difference.inMinutes)} dk';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} sa';
    }
    return '${placedAt.hour.toString().padLeft(2, '0')}:${placedAt.minute.toString().padLeft(2, '0')}';
  }
  final List<String> parts = order.placedAtLabel.split('•');
  return parts.length > 1 ? parts.last.trim() : order.etaLabel;
}

String _orderLabel(SpetoOpsOrder order) {
  final String trimmedCode = order.pickupCode.trim();
  if (trimmedCode.isNotEmpty) {
    return 'Sipariş #${trimmedCode.toUpperCase()}';
  }
  return 'Sipariş #${order.id.split('-').last.toUpperCase()}';
}

String _orderItemsPreview(SpetoOpsOrder order) {
  if (order.items.isEmpty) {
    return 'Sipariş içeriği bekleniyor';
  }
  return order.items
      .map((SpetoCartItem item) => item.title.trim())
      .where((String title) => title.isNotEmpty)
      .join(' + ');
}

String? _statusLabel(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => 'YENI',
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => 'HAZIRLANIYOR',
    SpetoOpsOrderStage.ready => 'HAZIR',
    SpetoOpsOrderStage.cancelled => 'IPTAL',
    SpetoOpsOrderStage.completed => null,
  };
}

Color _statusBackground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => AppColors.success,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => AppColors.amber100,
    SpetoOpsOrderStage.ready => AppColors.emerald50,
    SpetoOpsOrderStage.cancelled => AppColors.red50,
    SpetoOpsOrderStage.completed => Colors.transparent,
  };
}

Color _statusForeground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => Colors.white,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => AppColors.amber900,
    SpetoOpsOrderStage.ready => AppColors.brandGreen,
    SpetoOpsOrderStage.cancelled => AppColors.red500,
    SpetoOpsOrderStage.completed => AppColors.bodyText,
  };
}

Color _orderIconBackground(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => AppColors.emerald50,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => AppColors.slate100,
    SpetoOpsOrderStage.ready => AppColors.emerald50,
    SpetoOpsOrderStage.completed => AppColors.slate100,
    SpetoOpsOrderStage.cancelled => AppColors.red50,
  };
}

Color _orderIconColor(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => AppColors.success,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => AppColors.slate600,
    SpetoOpsOrderStage.ready => AppColors.success,
    SpetoOpsOrderStage.completed => AppColors.slate600,
    SpetoOpsOrderStage.cancelled => AppColors.red500,
  };
}

IconData _orderIcon(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => Icons.stars_rounded,
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => Icons.receipt_long_rounded,
    SpetoOpsOrderStage.ready => Icons.check_circle_outline_rounded,
    SpetoOpsOrderStage.completed => Icons.person_outline_rounded,
    SpetoOpsOrderStage.cancelled => Icons.close_rounded,
  };
}

int _trendPercent(List<SpetoOpsOrder> orders) {
  final DateTime now = DateTime.now();
  final int todayCount = orders.where(_isTodayOrder).length;
  final int yesterdayCount = orders.where((SpetoOpsOrder order) {
    final DateTime? placedAt = _parseOverviewPlacedAt(order);
    if (placedAt == null) {
      return false;
    }
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    return _isSameDay(placedAt, yesterday);
  }).length;
  if (todayCount == 0 && yesterdayCount == 0) {
    return 18;
  }
  if (yesterdayCount == 0) {
    return math.max(18, todayCount * 6);
  }
  final double growth = ((todayCount - yesterdayCount) / yesterdayCount) * 100;
  return growth.round().clamp(4, 99);
}

enum _OverviewChartRange { day, week, month }

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    this.onOpenOrders,
    this.onOpenProducts,
    this.onOpenCampaigns,
  });

  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenProducts;
  final VoidCallback? onOpenCampaigns;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  _OverviewChartRange _selectedRange = _OverviewChartRange.day;

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final SpetoCatalogVendor? vendor = controller.selectedVendor;
    final List<SpetoOpsOrder> recentOrders = controller.orders.take(3).toList();
    final int todaysOrders = controller.orders.where(_isTodayOrder).length;
    final double todaysRevenue = controller.orders
        .where(
          (SpetoOpsOrder order) =>
              _isTodayOrder(order) &&
              order.opsStatus != SpetoOpsOrderStage.cancelled,
        )
        .fold<double>(
          0,
          (double total, SpetoOpsOrder order) => total + order.payableTotal,
        );
    final int awaitingPickup = controller.orders
        .where(
          (SpetoOpsOrder order) => order.opsStatus == SpetoOpsOrderStage.ready,
        )
        .length;
    final int activeCampaigns = controller.campaignSummary?.activeCount ?? 0;
    final int trendPercent = _trendPercent(controller.orders);
    final _OverviewChartSeries chartSeries = _buildOverviewChartSeries(
      controller.orders,
      _selectedRange,
    );
    final List<_OverviewInventorySpotlightItem> inventoryItems =
        _buildOverviewInventorySpotlightItems(controller);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: <Widget>[
          _DashboardTopBar(
            isLoading: controller.isLoading,
            onRefresh: controller.refreshData,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshData,
              edgeOffset: 12,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 140),
                children: <Widget>[
                  Text(
                    'Genel Bakış',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                      letterSpacing: -0.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.dashboardError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _OverviewErrorBanner(
                        message: controller.dashboardError!,
                      ),
                    ),
                  if (controller.isLoading && vendor == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (vendor == null)
                    const _OverviewEmptyState()
                  else ...<Widget>[
                    _VendorSummaryCard(vendor: vendor),
                    const SizedBox(height: 22),
                    const _SectionHeader(
                      label: 'BUGÜN GENEL BAKIŞ',
                      smallCaps: true,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.375,
                      children: <Widget>[
                        _OverviewMetricCard(
                          icon: Icons.shopping_basket_outlined,
                          iconColor: const Color(0xFF6366F1),
                          iconBackground: const Color(0xFFEEF2FF),
                          title: 'Bugünkü Sipariş',
                          value: '$todaysOrders',
                          badgeLabel: '%$trendPercent',
                          showTrendArrow: true,
                        ),
                        _OverviewMetricCard(
                          icon: Icons.payments_outlined,
                          iconColor: const Color(0xFF14B8A6),
                          iconBackground: const Color(0xFFF0FDFA),
                          title: 'Bugünkü Ciro',
                          value: _currency(todaysRevenue),
                          valueFontSize: 20,
                        ),
                        _OverviewMetricCard(
                          icon: Icons.shopping_bag_outlined,
                          iconColor: AppColors.orange500,
                          iconBackground: AppColors.orange50,
                          title: 'Gel-Al Bekleyen',
                          value: '$awaitingPickup',
                        ),
                        _OverviewMetricCard(
                          icon: Icons.campaign_outlined,
                          iconColor: Colors.white,
                          iconBackground: AppColors.success,
                          title: 'Aktif Kampanya',
                          value: '$activeCampaigns',
                          outlined: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      label: 'Yeni Siparişler',
                      actionLabel: 'Tümünü Gör',
                      onTap: widget.onOpenOrders,
                    ),
                    const SizedBox(height: 8),
                    if (recentOrders.isEmpty)
                      const _OverviewEmptyOrdersCard()
                    else
                      ...recentOrders.map(
                        (SpetoOpsOrder order) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _OverviewOrderCard(order: order),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _OverviewSalesChartCard(
                      selectedRange: _selectedRange,
                      onRangeSelected: (_OverviewChartRange range) {
                        setState(() {
                          _selectedRange = range;
                        });
                      },
                      series: chartSeries,
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      label: 'Bugün Bitecek Ürünler',
                      actionLabel: 'Tümünü Gör',
                      onTap: widget.onOpenProducts,
                    ),
                    const SizedBox(height: 12),
                    _OverviewInventorySpotlightCard(
                      items: inventoryItems,
                      onDiscountTap: widget.onOpenProducts,
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(label: 'Hızlı İşlemler'),
                    const SizedBox(height: 12),
                    _OverviewQuickActionTile(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Yeni Ürün Ekle',
                      onTap: widget.onOpenProducts,
                    ),
                    const SizedBox(height: 8),
                    _OverviewQuickActionTile(
                      icon: Icons.campaign_outlined,
                      title: 'Kampanya Başlat',
                      onTap: widget.onOpenCampaigns,
                    ),
                    const SizedBox(height: 8),
                    _OverviewQuickActionTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Stoğu Güncelle',
                      onTap: widget.onOpenProducts,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _overviewDetailsCurrency(double value) {
  return '₺${value.toStringAsFixed(0).replaceAll('.', ',')}';
}

String _productImage(SpetoCatalogProduct product) {
  final String image = product.imageUrl.trim();
  if (image.isNotEmpty) {
    return image;
  }
  return product.image.trim();
}

_OverviewChartSeries _buildOverviewChartSeries(
  List<SpetoOpsOrder> orders,
  _OverviewChartRange range,
) {
  final DateTime now = DateTime.now();
  const List<double> fallbackValues = <double>[
    1.4,
    2.2,
    3.4,
    4.7,
    6.1,
    4.5,
    5.4,
    4.0,
    6.7,
  ];
  const List<String> dayLabels = <String>[
    '9:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];
  const List<String> weekLabels = <String>[
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];
  const List<String> monthLabels = <String>[
    'Kas',
    'Ara',
    'Oca',
    'Şub',
    'Mar',
    'Nis',
  ];

  List<String> labels;
  List<double> rawValues;

  switch (range) {
    case _OverviewChartRange.day:
      labels = dayLabels;
      rawValues = List<double>.filled(labels.length, 0);
      for (final SpetoOpsOrder order in orders) {
        if (order.opsStatus == SpetoOpsOrderStage.cancelled) {
          continue;
        }
        final DateTime? placedAt = _parseOverviewPlacedAt(order);
        if (placedAt == null || !_isSameDay(placedAt, now)) {
          continue;
        }
        final int bucket = placedAt.hour - 9;
        if (bucket >= 0 && bucket < rawValues.length) {
          rawValues[bucket] += order.payableTotal;
        }
      }
      break;
    case _OverviewChartRange.week:
      labels = weekLabels;
      rawValues = List<double>.filled(labels.length, 0);
      final DateTime weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      for (final SpetoOpsOrder order in orders) {
        if (order.opsStatus == SpetoOpsOrderStage.cancelled) {
          continue;
        }
        final DateTime? placedAt = _parseOverviewPlacedAt(order);
        if (placedAt == null) {
          continue;
        }
        final DateTime day = DateTime(
          placedAt.year,
          placedAt.month,
          placedAt.day,
        );
        final int bucket = day.difference(weekStart).inDays;
        if (bucket >= 0 && bucket < rawValues.length) {
          rawValues[bucket] += order.payableTotal;
        }
      }
      break;
    case _OverviewChartRange.month:
      labels = monthLabels;
      rawValues = List<double>.filled(labels.length, 0);
      final DateTime firstMonth = DateTime(now.year, now.month - 5, 1);
      for (final SpetoOpsOrder order in orders) {
        if (order.opsStatus == SpetoOpsOrderStage.cancelled) {
          continue;
        }
        final DateTime? placedAt = _parseOverviewPlacedAt(order);
        if (placedAt == null) {
          continue;
        }
        final int bucket =
            (placedAt.year - firstMonth.year) * 12 +
            (placedAt.month - firstMonth.month);
        if (bucket >= 0 && bucket < rawValues.length) {
          rawValues[bucket] += order.payableTotal;
        }
      }
      break;
  }

  final bool hasData = rawValues.any((double value) => value > 0);
  final List<double> normalizedValues;
  final List<double> tooltipValues;
  int highlightedIndex;

  if (hasData) {
    final double maxValue = rawValues.reduce(math.max);
    normalizedValues = rawValues
        .map<double>(
          (double value) => value <= 0 ? 0.0 : (value / maxValue) * 6.8,
        )
        .toList(growable: false);
    tooltipValues = rawValues;
    highlightedIndex = rawValues.indexOf(maxValue);
  } else {
    normalizedValues = fallbackValues
        .take(labels.length)
        .toList(growable: false);
    tooltipValues = List<double>.generate(
      labels.length,
      (int index) => 180.0 + index * 42.0,
      growable: false,
    );
    highlightedIndex = math.min(6, labels.length - 1);
  }

  return _OverviewChartSeries(
    labels: labels,
    values: normalizedValues,
    tooltipValues: tooltipValues,
    highlightedIndex: highlightedIndex,
  );
}

List<_OverviewInventorySpotlightItem> _buildOverviewInventorySpotlightItems(
  StockAppController controller,
) {
  final DateTime today = DateTime.now();
  final List<_OverviewInventoryCandidate> candidates =
      <_OverviewInventoryCandidate>[
        for (final SpetoInventoryItem item in controller.inventoryItems)
          if (!item.isArchived)
            _OverviewInventoryCandidate(
              id: item.id,
              title: item.title,
              imageUrl: item.imageUrl,
              quantity: item.availableQuantity > 0
                  ? item.availableQuantity
                  : item.onHand,
              unitLabel: item.unitType,
              expiryDate: DateTime.tryParse(item.expiryDate.trim()),
              lowStock:
                  item.stockStatus.lowStock ||
                  item.availableQuantity <= math.max(3, item.reorderLevel),
            ),
        for (final SpetoCatalogProduct product in controller.products)
          if (!product.isArchived)
            _OverviewInventoryCandidate(
              id: product.id,
              title: product.title,
              imageUrl: _productImage(product),
              quantity: product.stockStatus.availableQuantity,
              unitLabel: product.unitType,
              expiryDate: DateTime.tryParse(product.expiryDate.trim()),
              lowStock:
                  product.stockStatus.lowStock ||
                  product.stockStatus.availableQuantity <=
                      math.max(3, product.reorderLevel),
            ),
      ];

  if (candidates.isEmpty) {
    return const <_OverviewInventorySpotlightItem>[
      _OverviewInventorySpotlightItem(
        title: 'Burger Köftesi',
        quantity: 4,
        unitLabel: 'paket',
        accent: _OverviewInventoryAccent.expiring,
      ),
      _OverviewInventorySpotlightItem(
        title: 'Mozzarella',
        quantity: 2,
        unitLabel: 'paket',
        accent: _OverviewInventoryAccent.discount,
      ),
      _OverviewInventorySpotlightItem(
        title: 'Kola',
        quantity: 3,
        unitLabel: 'adet',
        accent: _OverviewInventoryAccent.lowStock,
      ),
    ];
  }

  final Set<String> usedIds = <String>{};
  final List<_OverviewInventorySpotlightItem> items =
      <_OverviewInventorySpotlightItem>[];

  _OverviewInventoryCandidate? takeCandidate(
    Iterable<_OverviewInventoryCandidate> source,
  ) {
    for (final _OverviewInventoryCandidate candidate in source) {
      if (usedIds.add(candidate.id)) {
        return candidate;
      }
    }
    return null;
  }

  final List<_OverviewInventoryCandidate> sortedByExpiry =
      candidates
          .where((candidate) => candidate.expiryDate != null)
          .toList(growable: false)
        ..sort(
          (
            _OverviewInventoryCandidate first,
            _OverviewInventoryCandidate second,
          ) => first.expiryDate!.compareTo(second.expiryDate!),
        );

  final _OverviewInventoryCandidate? expiringCandidate =
      takeCandidate(
        sortedByExpiry.where(
          (_OverviewInventoryCandidate candidate) =>
              _isSameDay(candidate.expiryDate!, today) ||
              candidate.expiryDate!.isBefore(
                today.add(const Duration(days: 2)),
              ),
        ),
      ) ??
      takeCandidate(sortedByExpiry) ??
      takeCandidate(candidates);
  if (expiringCandidate != null) {
    items.add(
      _OverviewInventorySpotlightItem(
        title: expiringCandidate.title,
        quantity: math.max(1, expiringCandidate.quantity),
        unitLabel: expiringCandidate.unitLabel,
        imageUrl: expiringCandidate.imageUrl,
        accent:
            expiringCandidate.expiryDate != null &&
                _isSameDay(expiringCandidate.expiryDate!, today)
            ? _OverviewInventoryAccent.expiring
            : _OverviewInventoryAccent.warning,
      ),
    );
  }

  final _OverviewInventoryCandidate? discountCandidate =
      takeCandidate(candidates.where((candidate) => candidate.quantity > 0)) ??
      takeCandidate(candidates);
  if (discountCandidate != null) {
    items.add(
      _OverviewInventorySpotlightItem(
        title: discountCandidate.title,
        quantity: math.max(1, discountCandidate.quantity),
        unitLabel: discountCandidate.unitLabel,
        imageUrl: discountCandidate.imageUrl,
        accent: _OverviewInventoryAccent.discount,
      ),
    );
  }

  final _OverviewInventoryCandidate? lowStockCandidate =
      takeCandidate(candidates.where((candidate) => candidate.lowStock)) ??
      takeCandidate(candidates);
  if (lowStockCandidate != null) {
    items.add(
      _OverviewInventorySpotlightItem(
        title: lowStockCandidate.title,
        quantity: math.max(1, lowStockCandidate.quantity),
        unitLabel: lowStockCandidate.unitLabel,
        imageUrl: lowStockCandidate.imageUrl,
        accent: _OverviewInventoryAccent.lowStock,
      ),
    );
  }

  while (items.length < 3) {
    items.add(
      const _OverviewInventorySpotlightItem(
        title: 'Stok Güncellemesi',
        quantity: 1,
        unitLabel: 'adet',
        accent: _OverviewInventoryAccent.discount,
      ),
    );
  }

  return items;
}

class _OverviewSalesChartCard extends StatelessWidget {
  const _OverviewSalesChartCard({
    required this.selectedRange,
    required this.onRangeSelected,
    required this.series,
  });

  final _OverviewChartRange selectedRange;
  final ValueChanged<_OverviewChartRange> onRangeSelected;
  final _OverviewChartSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Satış Grafiği',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: <Widget>[
                    for (final _OverviewChartRange range
                        in _OverviewChartRange.values)
                      _OverviewChartRangeChip(
                        label: switch (range) {
                          _OverviewChartRange.day => 'Gün',
                          _OverviewChartRange.week => 'Hafta',
                          _OverviewChartRange.month => 'Ay',
                        },
                        selected: selectedRange == range,
                        onTap: () => onRangeSelected(range),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OverviewSalesChart(series: series),
        ],
      ),
    );
  }
}

class _OverviewChartRangeChip extends StatelessWidget {
  const _OverviewChartRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.5,
            color: selected ? AppColors.onSurface : AppColors.bodyText,
          ),
        ),
      ),
    );
  }
}

class _OverviewSalesChart extends StatelessWidget {
  const _OverviewSalesChart({required this.series});

  final _OverviewChartSeries series;

  @override
  Widget build(BuildContext context) {
    const double maxAxisValue = 8;
    final double highlightedValue = series.values[series.highlightedIndex];

    return SizedBox(
      height: 192,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                for (final String label in const <String>[
                  '8',
                  '6',
                  '4',
                  '2',
                  '0',
                ])
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: AppColors.bodyText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final double stepX =
                              constraints.maxWidth /
                              math.max(1, series.values.length - 1);
                          final double pointLeft =
                              stepX * series.highlightedIndex - 20;
                          final double pointTop =
                              (1 - highlightedValue / maxAxisValue) *
                              constraints.maxHeight;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              CustomPaint(
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                painter: _OverviewSalesChartPainter(
                                  values: series.values,
                                ),
                              ),
                              Positioned(
                                left: pointLeft
                                    .clamp(0.0, constraints.maxWidth - 40)
                                    .toDouble(),
                                top: math.max(0.0, pointTop - 30).toDouble(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate900,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.16,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _overviewDetailsCurrency(
                                      series.tooltipValues[series
                                          .highlightedIndex],
                                    ),
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (final String label in series.labels)
                      Text(
                        label,
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: AppColors.bodyText,
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
}

class _OverviewSalesChartPainter extends CustomPainter {
  const _OverviewSalesChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const double maxValue = 8;
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFEDEEEF)
      ..strokeWidth = 1;
    final Paint baselinePaint = Paint()
      ..color = const Color(0x1A191C1D)
      ..strokeWidth = 1;
    final Paint linePaint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x662ECC71), Color(0x122ECC71)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final double stepY = size.height / 4;
    for (int index = 0; index < 5; index += 1) {
      final double y = stepY * index;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index == 4 ? baselinePaint : gridPaint,
      );
    }

    final List<Offset> points = <Offset>[
      for (int index = 0; index < values.length; index += 1)
        Offset(
          size.width * (index / math.max(1, values.length - 1)),
          size.height - (values[index] / maxValue) * size.height,
        ),
    ];

    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 0; index < points.length - 1; index += 1) {
      final Offset current = points[index];
      final Offset next = points[index + 1];
      final double controlX = (current.dx + next.dx) / 2;
      linePath.quadraticBezierTo(controlX, current.dy, next.dx, next.dy);
    }

    final Path fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final int highlightedIndex = values.indexOf(values.reduce(math.max));
    for (int index = 0; index < points.length; index += 1) {
      final Offset point = points[index];
      final bool highlighted = index == highlightedIndex;
      canvas.drawCircle(
        point,
        highlighted ? 5.5 : 3.2,
        Paint()..color = AppColors.success,
      );
      if (highlighted) {
        canvas.drawCircle(point, 2.4, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverviewSalesChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _OverviewInventorySpotlightCard extends StatelessWidget {
  const _OverviewInventorySpotlightCard({
    required this.items,
    this.onDiscountTap,
  });

  final List<_OverviewInventorySpotlightItem> items;
  final VoidCallback? onDiscountTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < items.length; index += 1)
            DecoratedBox(
              decoration: BoxDecoration(
                border: index == items.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppColors.surfaceContainerHigh,
                        ),
                      ),
              ),
              child: _OverviewInventorySpotlightRow(
                item: items[index],
                onTap: items[index].accent == _OverviewInventoryAccent.discount
                    ? onDiscountTap
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewInventorySpotlightRow extends StatelessWidget {
  const _OverviewInventorySpotlightRow({required this.item, this.onTap});

  final _OverviewInventorySpotlightItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: <Widget>[
            _OverviewInventoryThumb(imageUrl: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '${item.quantity} ${item.unitLabel.trim().isEmpty ? 'adet' : item.unitLabel}',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            switch (item.accent) {
              _OverviewInventoryAccent.expiring => _OverviewSpotlightPill(
                label: 'BUGÜN SKT',
                backgroundColor: AppColors.orange100,
                textColor: const Color(0xFFC2410C),
              ),
              _OverviewInventoryAccent.warning => _OverviewSpotlightPill(
                label: 'SKT YAKIN',
                backgroundColor: AppColors.orange100,
                textColor: const Color(0xFFC2410C),
              ),
              _OverviewInventoryAccent.discount => Text(
                'İndirime Ekle',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: AppColors.primary,
                ),
              ),
              _OverviewInventoryAccent.lowStock => _OverviewSpotlightPill(
                label: 'STOKTA AZALMA',
                backgroundColor: const Color(0xFFFEE2E2),
                textColor: const Color(0xFFB91C1C),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _OverviewInventoryThumb extends StatelessWidget {
  const _OverviewInventoryThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? trimmed = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: trimmed != null && trimmed.isNotEmpty
            ? Image.network(
                trimmed,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return _placeholder();
                    },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.slate500,
        size: 18,
      ),
    );
  }
}

class _OverviewSpotlightPill extends StatelessWidget {
  const _OverviewSpotlightPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1.5,
          color: textColor,
        ),
      ),
    );
  }
}

class _OverviewQuickActionTile extends StatelessWidget {
  const _OverviewQuickActionTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate600,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewChartSeries {
  const _OverviewChartSeries({
    required this.labels,
    required this.values,
    required this.tooltipValues,
    required this.highlightedIndex,
  });

  final List<String> labels;
  final List<double> values;
  final List<double> tooltipValues;
  final int highlightedIndex;
}

class _OverviewInventoryCandidate {
  const _OverviewInventoryCandidate({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitLabel,
    required this.expiryDate,
    required this.lowStock,
  });

  final String id;
  final String title;
  final String imageUrl;
  final int quantity;
  final String unitLabel;
  final DateTime? expiryDate;
  final bool lowStock;
}

enum _OverviewInventoryAccent { expiring, warning, discount, lowStock }

class _OverviewInventorySpotlightItem {
  const _OverviewInventorySpotlightItem({
    required this.title,
    required this.quantity,
    required this.unitLabel,
    required this.accent,
    this.imageUrl,
  });

  final String title;
  final int quantity;
  final String unitLabel;
  final _OverviewInventoryAccent accent;
  final String? imageUrl;
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({required this.isLoading, required this.onRefresh});

  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: AppColors.slate200.withValues(alpha: 0.28),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.storefront_rounded,
                    color: AppColors.brandGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SepetPro İşyerim',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      letterSpacing: -0.4,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 24,
                  height: 24,
                ),
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.slate400,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorSummaryCard extends StatelessWidget {
  const _VendorSummaryCard({required this.vendor});

  final SpetoCatalogVendor vendor;

  @override
  Widget build(BuildContext context) {
    final SpetoCatalogPickupPoint? pickupPoint = vendor.pickupPoints.isNotEmpty
        ? vendor.pickupPoints.first
        : null;
    final String location = pickupPoint?.label.trim().isNotEmpty == true
        ? pickupPoint!.label
        : vendor.subtitle;
    final bool isOpen = vendor.isActive;
    final Color statusColor = isOpen ? AppColors.success : AppColors.red500;

    return Container(
      constraints: const BoxConstraints(minHeight: 97),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: vendor.image.trim().isEmpty
                  ? _FallbackVendorThumbnail(vendor: vendor)
                  : Image.network(
                      vendor.image,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return _FallbackVendorThumbnail(vendor: vendor);
                          },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  vendor.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 2,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBBCBBB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'Açık' : 'Kapalı',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  vendor.workingHoursLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: AppColors.bodyText,
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

class _FallbackVendorThumbnail extends StatelessWidget {
  const _FallbackVendorThumbnail({required this.vendor});

  final SpetoCatalogVendor vendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.emerald50,
      alignment: Alignment.center,
      child: Icon(
        vendor.storefrontType == SpetoStorefrontType.restaurant
            ? Icons.restaurant_rounded
            : Icons.local_mall_outlined,
        color: AppColors.brandGreen,
        size: 26,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    this.actionLabel,
    this.onTap,
    this.smallCaps = false,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onTap;
  final bool smallCaps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          label,
          style: smallCaps
              ? GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: 1,
                  color: AppColors.bodyText,
                )
              : GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                  color: AppColors.onSurface,
                ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Text(
              actionLabel!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: AppColors.success,
              ),
            ),
          ),
      ],
    );
  }
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    this.badgeLabel,
    this.showTrendArrow = false,
    this.outlined = false,
    this.valueFontSize = 24,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String? badgeLabel;
  final bool showTrendArrow;
  final bool outlined;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(outlined ? 17 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: outlined
            ? Border.all(color: AppColors.emerald200.withValues(alpha: 0.7))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (badgeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (showTrendArrow) ...<Widget>[
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 8,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 1),
                      ],
                      Text(
                        badgeLabel!,
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewOrderCard extends StatelessWidget {
  const _OverviewOrderCard({required this.order});

  final SpetoOpsOrder order;

  @override
  Widget build(BuildContext context) {
    final bool showAccent = order.opsStatus == SpetoOpsOrderStage.created;
    final String? badgeText = _statusLabel(order.opsStatus);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            if (showAccent)
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(999),
                      bottomRight: Radius.circular(999),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(showAccent ? 16 : 12, 12, 12, 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _orderIconBackground(order.opsStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _orderIcon(order.opsStatus),
                      color: _orderIconColor(order.opsStatus),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                _orderLabel(order),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            if (badgeText != null) ...<Widget>[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBackground(order.opsStatus),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  badgeText,
                                  style: GoogleFonts.manrope(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                    letterSpacing: 0.4,
                                    color: _statusForeground(order.opsStatus),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _orderItemsPreview(order),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _currency(order.payableTotal),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.5,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        _compactTimeLabel(order),
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: AppColors.bodyText,
                        ),
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
}

class _OverviewErrorBanner extends StatelessWidget {
  const _OverviewErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange100),
      ),
      child: Text(
        message,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: AppColors.bodyText,
        ),
      ),
    );
  }
}

class _OverviewEmptyState extends StatelessWidget {
  const _OverviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'İşletme bilgisi yüklenemedi.',
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: AppColors.bodyText,
        ),
      ),
    );
  }
}

class _OverviewEmptyOrdersCard extends StatelessWidget {
  const _OverviewEmptyOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Henüz yeni sipariş bulunmuyor.',
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: AppColors.bodyText,
        ),
      ),
    );
  }
}
