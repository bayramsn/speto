import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';

enum _ChartRange { day, week, month }

DateTime? _parseOverviewDetailsDate(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final DateTime? direct = DateTime.tryParse(trimmed);
  if (direct != null) {
    return direct;
  }
  final Match? match = RegExp(
    r'(\d{2})\.(\d{2})\.(\d{4})(?:\s*•\s*(\d{2}):(\d{2}))?',
  ).firstMatch(trimmed);
  if (match == null) {
    return null;
  }
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.parse(match.group(4) ?? '0'),
    int.parse(match.group(5) ?? '0'),
  );
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _detailsCurrency(double value) {
  return '₺${value.toStringAsFixed(0).replaceAll('.', ',')}';
}

String _detailsQuantityLabel(_InventorySpotlightItem item) {
  final String unit = item.unitLabel.trim().isEmpty ? 'adet' : item.unitLabel;
  return '${item.quantity} $unit';
}

String _productImage(SpetoCatalogProduct product) {
  final String image = product.imageUrl.trim();
  if (image.isNotEmpty) {
    return image;
  }
  return product.image.trim();
}

_ChartSeries _buildChartSeries(List<SpetoOpsOrder> orders, _ChartRange range) {
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
    case _ChartRange.day:
      labels = dayLabels;
      rawValues = List<double>.filled(labels.length, 0);
      for (final SpetoOpsOrder order in orders) {
        if (order.opsStatus == SpetoOpsOrderStage.cancelled) {
          continue;
        }
        final DateTime? placedAt = _parseOverviewDetailsDate(
          order.placedAtLabel,
        );
        if (placedAt == null || !_isSameDay(placedAt, now)) {
          continue;
        }
        final int bucket = placedAt.hour - 9;
        if (bucket >= 0 && bucket < rawValues.length) {
          rawValues[bucket] += order.payableTotal;
        }
      }
      break;
    case _ChartRange.week:
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
        final DateTime? placedAt = _parseOverviewDetailsDate(
          order.placedAtLabel,
        );
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
    case _ChartRange.month:
      labels = monthLabels;
      rawValues = List<double>.filled(labels.length, 0);
      final DateTime firstMonth = DateTime(now.year, now.month - 5, 1);
      for (final SpetoOpsOrder order in orders) {
        if (order.opsStatus == SpetoOpsOrderStage.cancelled) {
          continue;
        }
        final DateTime? placedAt = _parseOverviewDetailsDate(
          order.placedAtLabel,
        );
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
        .map((double value) => value <= 0 ? 0.0 : (value / maxValue) * 6.8)
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

  return _ChartSeries(
    labels: labels,
    values: normalizedValues,
    tooltipValues: tooltipValues,
    highlightedIndex: highlightedIndex,
  );
}

List<_InventorySpotlightItem> _buildInventorySpotlightItems(
  StockAppController controller,
) {
  final DateTime today = DateTime.now();
  final List<_InventoryCandidate> candidates = <_InventoryCandidate>[
    for (final SpetoInventoryItem item in controller.inventoryItems)
      if (!item.isArchived)
        _InventoryCandidate(
          id: item.id,
          title: item.title,
          imageUrl: item.imageUrl,
          quantity: item.availableQuantity > 0
              ? item.availableQuantity
              : item.onHand,
          unitLabel: item.unitType,
          expiryDate: _parseOverviewDetailsDate(item.expiryDate),
          lowStock:
              item.stockStatus.lowStock ||
              item.availableQuantity <= math.max(3, item.reorderLevel),
        ),
    for (final SpetoCatalogProduct product in controller.products)
      if (!product.isArchived)
        _InventoryCandidate(
          id: product.id,
          title: product.title,
          imageUrl: _productImage(product),
          quantity: product.stockStatus.availableQuantity,
          unitLabel: product.unitType,
          expiryDate: _parseOverviewDetailsDate(product.expiryDate),
          lowStock:
              product.stockStatus.lowStock ||
              product.stockStatus.availableQuantity <=
                  math.max(3, product.reorderLevel),
        ),
  ];

  if (candidates.isEmpty) {
    return const <_InventorySpotlightItem>[
      _InventorySpotlightItem(
        title: 'Burger Köftesi',
        quantity: 4,
        unitLabel: 'paket',
        accent: _InventoryAccent.expiring,
      ),
      _InventorySpotlightItem(
        title: 'Mozzarella',
        quantity: 2,
        unitLabel: 'paket',
        accent: _InventoryAccent.discount,
      ),
      _InventorySpotlightItem(
        title: 'Kola',
        quantity: 3,
        unitLabel: 'adet',
        accent: _InventoryAccent.lowStock,
      ),
    ];
  }

  final Set<String> usedIds = <String>{};
  final List<_InventorySpotlightItem> items = <_InventorySpotlightItem>[];

  _InventoryCandidate? takeCandidate(Iterable<_InventoryCandidate> source) {
    for (final _InventoryCandidate candidate in source) {
      if (usedIds.add(candidate.id)) {
        return candidate;
      }
    }
    return null;
  }

  final List<_InventoryCandidate> sortedByExpiry =
      candidates
          .where((candidate) => candidate.expiryDate != null)
          .toList(growable: false)
        ..sort(
          (_InventoryCandidate first, _InventoryCandidate second) =>
              first.expiryDate!.compareTo(second.expiryDate!),
        );
  final _InventoryCandidate? expiringCandidate =
      takeCandidate(
        sortedByExpiry.where(
          (_InventoryCandidate candidate) =>
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
      _InventorySpotlightItem(
        title: expiringCandidate.title,
        quantity: math.max(1, expiringCandidate.quantity),
        unitLabel: expiringCandidate.unitLabel,
        imageUrl: expiringCandidate.imageUrl,
        accent:
            expiringCandidate.expiryDate != null &&
                _isSameDay(expiringCandidate.expiryDate!, today)
            ? _InventoryAccent.expiring
            : _InventoryAccent.warning,
      ),
    );
  }

  final _InventoryCandidate? discountCandidate =
      takeCandidate(candidates.where((candidate) => candidate.quantity > 0)) ??
      takeCandidate(candidates);
  if (discountCandidate != null) {
    items.add(
      _InventorySpotlightItem(
        title: discountCandidate.title,
        quantity: math.max(1, discountCandidate.quantity),
        unitLabel: discountCandidate.unitLabel,
        imageUrl: discountCandidate.imageUrl,
        accent: _InventoryAccent.discount,
      ),
    );
  }

  final _InventoryCandidate? lowStockCandidate =
      takeCandidate(candidates.where((candidate) => candidate.lowStock)) ??
      takeCandidate(candidates);
  if (lowStockCandidate != null) {
    items.add(
      _InventorySpotlightItem(
        title: lowStockCandidate.title,
        quantity: math.max(1, lowStockCandidate.quantity),
        unitLabel: lowStockCandidate.unitLabel,
        imageUrl: lowStockCandidate.imageUrl,
        accent: _InventoryAccent.lowStock,
      ),
    );
  }

  while (items.length < 3) {
    items.add(
      const _InventorySpotlightItem(
        title: 'Stok Güncellemesi',
        quantity: 1,
        unitLabel: 'adet',
        accent: _InventoryAccent.discount,
      ),
    );
  }

  return items;
}

class OverviewDetailsScreen extends StatefulWidget {
  const OverviewDetailsScreen({super.key});

  @override
  State<OverviewDetailsScreen> createState() => _OverviewDetailsScreenState();
}

class _OverviewDetailsScreenState extends State<OverviewDetailsScreen> {
  _ChartRange _selectedRange = _ChartRange.day;

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final _ChartSeries chartSeries = _buildChartSeries(
      controller.orders,
      _selectedRange,
    );
    final List<_InventorySpotlightItem> inventoryItems =
        _buildInventorySpotlightItems(controller);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.surface,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (int index) => Navigator.of(context).pop(index),
      ),
      body: Column(
        children: <Widget>[
          _OverviewDetailsHeader(
            isLoading: controller.isLoading,
            onRefresh: controller.refreshData,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
                children: <Widget>[
                  _SalesChartCard(
                    selectedRange: _selectedRange,
                    onRangeSelected: (_ChartRange range) {
                      setState(() {
                        _selectedRange = range;
                      });
                    },
                    series: chartSeries,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Bugün Bitecek Ürünler',
                    actionLabel: 'Tümünü Gör',
                    onTap: () => Navigator.of(context).pop(2),
                  ),
                  const SizedBox(height: 12),
                  _InventorySpotlightCard(
                    items: inventoryItems,
                    onDiscountTap: () => Navigator.of(context).pop(3),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Hızlı İşlemler'),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Yeni Ürün Ekle',
                    onTap: () => Navigator.of(context).pop(2),
                  ),
                  const SizedBox(height: 8),
                  _QuickActionTile(
                    icon: Icons.campaign_outlined,
                    title: 'Kampanya Başlat',
                    onTap: () => Navigator.of(context).pop(3),
                  ),
                  const SizedBox(height: 8),
                  _QuickActionTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Stoğu Güncelle',
                    onTap: () => Navigator.of(context).pop(2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDetailsHeader extends StatelessWidget {
  const _OverviewDetailsHeader({
    required this.isLoading,
    required this.onRefresh,
  });

  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        border: Border(
          bottom: BorderSide(color: AppColors.slate200.withValues(alpha: 0.35)),
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
                size: 20,
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
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.slate400.withValues(alpha: 0.9),
                    ),
                  )
                : Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.slate400,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onTap});

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.55,
            color: AppColors.onSurface,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionLabel!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({
    required this.selectedRange,
    required this.onRangeSelected,
    required this.series,
  });

  final _ChartRange selectedRange;
  final ValueChanged<_ChartRange> onRangeSelected;
  final _ChartSeries series;

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
                    for (final _ChartRange range in _ChartRange.values)
                      _ChartRangeChip(
                        label: switch (range) {
                          _ChartRange.day => 'Gün',
                          _ChartRange.week => 'Hafta',
                          _ChartRange.month => 'Ay',
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
          _SalesChart(series: series),
        ],
      ),
    );
  }
}

class _ChartRangeChip extends StatelessWidget {
  const _ChartRangeChip({
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

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.series});

  final _ChartSeries series;

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
                                painter: _SalesChartPainter(
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
                                    _detailsCurrency(
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

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter({required this.values});

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
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _InventorySpotlightCard extends StatelessWidget {
  const _InventorySpotlightCard({
    required this.items,
    required this.onDiscountTap,
  });

  final List<_InventorySpotlightItem> items;
  final VoidCallback onDiscountTap;

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
              child: _InventorySpotlightRow(
                item: items[index],
                onTap: items[index].accent == _InventoryAccent.discount
                    ? onDiscountTap
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _InventorySpotlightRow extends StatelessWidget {
  const _InventorySpotlightRow({required this.item, this.onTap});

  final _InventorySpotlightItem item;
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
            _InventoryThumb(imageUrl: item.imageUrl),
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
                    _detailsQuantityLabel(item),
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
              _InventoryAccent.expiring => _SpotlightPill(
                label: 'BUGÜN SKT',
                backgroundColor: AppColors.orange100,
                textColor: const Color(0xFFC2410C),
              ),
              _InventoryAccent.warning => _SpotlightPill(
                label: 'SKT YAKIN',
                backgroundColor: AppColors.orange100,
                textColor: const Color(0xFFC2410C),
              ),
              _InventoryAccent.discount => Text(
                'İndirime Ekle',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: AppColors.primary,
                ),
              ),
              _InventoryAccent.lowStock => _SpotlightPill(
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

class _InventoryThumb extends StatelessWidget {
  const _InventoryThumb({this.imageUrl});

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

class _SpotlightPill extends StatelessWidget {
  const _SpotlightPill({
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

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

class _ChartSeries {
  const _ChartSeries({
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

class _InventoryCandidate {
  const _InventoryCandidate({
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

enum _InventoryAccent { expiring, warning, discount, lowStock }

class _InventorySpotlightItem {
  const _InventorySpotlightItem({
    required this.title,
    required this.quantity,
    required this.unitLabel,
    required this.accent,
    this.imageUrl,
  });

  final String title;
  final int quantity;
  final String unitLabel;
  final _InventoryAccent accent;
  final String? imageUrl;
}
