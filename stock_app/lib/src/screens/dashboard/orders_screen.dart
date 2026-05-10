import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'order_details_screen.dart';
import 'order_ui.dart';
import 'orders_filter_screen.dart';

const List<String> _orderTabs = <String>[
  'Tümü',
  'Yeni',
  'Hazırlanıyor',
  'Hazır',
  'Tamamlananlar',
  'İptal',
];

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _calendarMonthsAgo(DateTime value, int months) {
  final DateTime monthStart = DateTime(value.year, value.month - months, 1);
  final int daysInMonth = DateTime(
    monthStart.year,
    monthStart.month + 1,
    0,
  ).day;
  final int day = value.day > daysInMonth ? daysInMonth : value.day;
  return DateTime(monthStart.year, monthStart.month, day);
}

bool _isWithinDateRange(
  DateTime value, {
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  return !value.isBefore(startInclusive) && value.isBefore(endExclusive);
}

bool _matchesDateFilter(SpetoOpsOrder order, String dateFilter) {
  if (dateFilter == 'Tümü') {
    return true;
  }
  final DateTime? placedAt = parseOrderPlacedAt(order);
  if (placedAt == null) {
    return false;
  }

  final DateTime today = _startOfDay(DateTime.now());
  final DateTime tomorrow = today.add(const Duration(days: 1));

  return switch (dateFilter) {
    'Bugün' => _isWithinDateRange(
      placedAt,
      startInclusive: today,
      endExclusive: tomorrow,
    ),
    'Dün' => _isWithinDateRange(
      placedAt,
      startInclusive: today.subtract(const Duration(days: 1)),
      endExclusive: today,
    ),
    'Son 7 Gün' => _isWithinDateRange(
      placedAt,
      startInclusive: today.subtract(const Duration(days: 6)),
      endExclusive: tomorrow,
    ),
    'Son 30 Gün' => _isWithinDateRange(
      placedAt,
      startInclusive: today.subtract(const Duration(days: 29)),
      endExclusive: tomorrow,
    ),
    'Son 3 Ay' => _isWithinDateRange(
      placedAt,
      startInclusive: _calendarMonthsAgo(today, 3),
      endExclusive: tomorrow,
    ),
    'Son 1 Yıl' => _isWithinDateRange(
      placedAt,
      startInclusive: _calendarMonthsAgo(today, 12),
      endExclusive: tomorrow,
    ),
    _ => true,
  };
}

String _normalizeFilterToken(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

bool _matchesPaymentFilter(SpetoOpsOrder order, String paymentFilter) {
  if (paymentFilter == 'Tümü') {
    return true;
  }
  final String normalizedPayment = _normalizeFilterToken(order.paymentMethod);
  final String normalizedFilter = _normalizeFilterToken(paymentFilter);
  if (normalizedFilter == 'kredikarti') {
    return normalizedPayment.contains('kredi') ||
        normalizedPayment.contains('card') ||
        normalizedPayment.contains('kart');
  }
  return normalizedPayment.contains(normalizedFilter);
}

String _statusFilterFromTab(String tab) {
  return switch (tab) {
    'Yeni' => 'Yeni',
    'Hazırlanıyor' => 'Hazırlanıyor',
    'Hazır' => 'Hazır',
    'Tamamlananlar' => 'Tamamlandı',
    'İptal' => 'İptal',
    _ => 'Tümü',
  };
}

String _tabFromStatusFilter(String status) {
  return switch (status) {
    'Yeni' => 'Yeni',
    'Hazırlanıyor' => 'Hazırlanıyor',
    'Hazır' => 'Hazır',
    'Tamamlandı' => 'Tamamlananlar',
    'İptal' => 'İptal',
    _ => 'Tümü',
  };
}

bool _matchesOrderTab(SpetoOpsOrder order, String tab) {
  return switch (tab) {
    'Yeni' => order.opsStatus == SpetoOpsOrderStage.created,
    'Hazırlanıyor' => isPreparingOrder(order),
    'Hazır' => order.opsStatus == SpetoOpsOrderStage.ready,
    'Tamamlananlar' => order.opsStatus == SpetoOpsOrderStage.completed,
    'İptal' => order.opsStatus == SpetoOpsOrderStage.cancelled,
    _ => true,
  };
}

int _compareOrders(SpetoOpsOrder a, SpetoOpsOrder b) {
  final int stageCompare = orderStageRank(a).compareTo(orderStageRank(b));
  if (stageCompare != 0) {
    return stageCompare;
  }
  final DateTime? aPlacedAt = parseOrderPlacedAt(a);
  final DateTime? bPlacedAt = parseOrderPlacedAt(b);
  if (aPlacedAt != null && bPlacedAt != null) {
    return bPlacedAt.compareTo(aPlacedAt);
  }
  if (aPlacedAt != null) {
    return -1;
  }
  if (bPlacedAt != null) {
    return 1;
  }
  return a.id.compareTo(b.id);
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDateFilter = 'Tümü';
  String _selectedPaymentFilter = 'Tümü';
  String _selectedTab = 'Tümü';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final String query = _searchController.text.trim().toLowerCase();
    final List<SpetoOpsOrder> filteredOrders =
        controller.orders
            .where((SpetoOpsOrder order) {
              final bool matchesQuery =
                  query.isEmpty ||
                  orderTitle(order).toLowerCase().contains(query) ||
                  orderItemsPreview(order).toLowerCase().contains(query) ||
                  orderPersonLabel(order).toLowerCase().contains(query) ||
                  orderMetaLine(order).toLowerCase().contains(query);
              if (!matchesQuery) {
                return false;
              }
              if (!_matchesDateFilter(order, _selectedDateFilter)) {
                return false;
              }
              if (!_matchesPaymentFilter(order, _selectedPaymentFilter)) {
                return false;
              }
              return _matchesOrderTab(order, _selectedTab);
            })
            .toList(growable: false)
          ..sort(_compareOrders);

    final int todayOrders = controller.orders
        .where((SpetoOpsOrder order) => _matchesDateFilter(order, 'Bugün'))
        .length;
    final int activeOrders = controller.orders
        .where((SpetoOpsOrder order) => !isTerminalOrder(order))
        .length;
    final int newOrders = controller.orders
        .where(
          (SpetoOpsOrder order) =>
              order.opsStatus == SpetoOpsOrderStage.created,
        )
        .length;

    return Scaffold(
      backgroundColor: AppColors.ordersSurface,
      body: Column(
        children: <Widget>[
          _OrdersHeader(
            showNotificationDot: newOrders > 0,
            isLoading: controller.isLoading,
            onRefresh: controller.refreshData,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                children: <Widget>[
                  _SearchAndFilterRow(
                    controller: _searchController,
                    onChanged: () => setState(() {}),
                    onOpenFilters: () => _openFilters(context),
                    hasActiveFilters:
                        _selectedDateFilter != 'Tümü' ||
                        _selectedPaymentFilter != 'Tümü' ||
                        _selectedTab != 'Tümü',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 51,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _orderTabs.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String tab = _orderTabs[index];
                        return _OrderTabChip(
                          label: tab,
                          isActive: _selectedTab == tab,
                          onTap: () {
                            setState(() {
                              _selectedTab = tab;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.event_note_rounded,
                          title: 'Bugünkü Sipariş',
                          value: '$todayOrders',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.notifications_none_rounded,
                          title: 'Aktif Sipariş',
                          value: '$activeOrders',
                        ),
                      ),
                    ],
                  ),
                  if (newOrders > 0) ...<Widget>[
                    const SizedBox(height: 16),
                    _AlertBanner(
                      newOrders: newOrders,
                      onTap: () {
                        setState(() {
                          _selectedTab = 'Yeni';
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _OrdersListHeader(
                    title: 'Tüm Siparişler',
                    onFilterTap: () => _openFilters(context),
                  ),
                  const SizedBox(height: 12),
                  if (filteredOrders.isEmpty)
                    const _EmptyOrdersCard()
                  else
                    ...filteredOrders.map(
                      (SpetoOpsOrder order) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OrderCard(
                          order: order,
                          isBusy: controller.isBusy('order:${order.id}'),
                          onPrimaryTap: () async {
                            final SpetoOpsOrderStage? nextStage =
                                nextOrderStage(order);
                            if (nextStage == null) {
                              return;
                            }
                            await controller.updateOrderStatus(
                              order.id,
                              nextStage,
                            );
                          },
                          onCancelTap:
                              order.opsStatus == SpetoOpsOrderStage.created
                              ? () async {
                                  await controller.updateOrderStatus(
                                    order.id,
                                    SpetoOpsOrderStage.cancelled,
                                  );
                                }
                              : null,
                          onDetailTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    OrderDetailsScreen(orderId: order.id),
                              ),
                            );
                          },
                        ),
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

  Future<void> _openFilters(BuildContext context) async {
    final OrdersFilterResult? result =
        await showModalBottomSheet<OrdersFilterResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: OrdersFilterScreen(
              initialDate: _selectedDateFilter,
              initialPayment: _selectedPaymentFilter,
              initialStatus: _statusFilterFromTab(_selectedTab),
            ),
          ),
        );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _selectedDateFilter = result.dateFilter;
      _selectedPaymentFilter = result.paymentFilter;
      _selectedTab = _tabFromStatusFilter(result.statusFilter);
    });
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.showNotificationDot,
    required this.isLoading,
    required this.onRefresh,
  });

  final bool showNotificationDot;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, topInset + 11.5, 24, 11.5),
          decoration: BoxDecoration(
            color: const Color(0xCCF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: AppColors.slate200.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Siparişler',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: -0.5,
                      color: AppColors.inkStrong,
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
                    : Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: AppColors.slate600,
                          ),
                          if (showNotificationDot)
                            Positioned(
                              top: 0,
                              right: -0.02,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.orange500,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
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
  }
}

class _SearchAndFilterRow extends StatelessWidget {
  const _SearchAndFilterRow({
    required this.controller,
    required this.onChanged,
    required this.onOpenFilters,
    required this.hasActiveFilters,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onOpenFilters;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.search_rounded, color: AppColors.slate400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: 'Siparişler',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: AppColors.inkStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onOpenFilters,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: hasActiveFilters ? AppColors.emerald50 : Colors.white,
              border: Border.all(
                color: hasActiveFilters
                    ? AppColors.emerald100
                    : AppColors.slate200,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_alt_outlined,
              size: 18,
              color: hasActiveFilters
                  ? AppColors.activeNavItemText
                  : AppColors.slate600,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderTabChip extends StatelessWidget {
  const _OrderTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 17 : 8,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.activeNavItemBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: isActive
              ? Border.all(color: AppColors.emerald100)
              : const Border.fromBorderSide(BorderSide.none),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              height: 1.4,
              color: isActive
                  ? AppColors.activeNavItemText
                  : AppColors.slate500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate100),
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
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: AppColors.slate500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.33,
              color: AppColors.inkStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.newOrders, required this.onTap});

  final int newOrders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.orange50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.orange100),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.info_rounded, size: 16, color: AppColors.orange500),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '$newOrders yeni sipariş ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    TextSpan(
                      text: 'bekliyor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersListHeader extends StatelessWidget {
  const _OrdersListHeader({required this.title, required this.onFilterTap});

  final String title;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.55,
            color: AppColors.inkStrong,
          ),
        ),
        TextButton.icon(
          onPressed: onFilterTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          iconAlignment: IconAlignment.end,
          icon: Icon(
            Icons.filter_alt_outlined,
            size: 14,
            color: AppColors.slate500,
          ),
          label: Text(
            'Filtrele',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AppColors.slate500,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isBusy,
    required this.onPrimaryTap,
    required this.onCancelTap,
    required this.onDetailTap,
  });

  final SpetoOpsOrder order;
  final bool isBusy;
  final Future<void> Function() onPrimaryTap;
  final Future<void> Function()? onCancelTap;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    final bool showDualActions = order.opsStatus == SpetoOpsOrderStage.created;
    final bool showSingleAction = !showDualActions && !isTerminalOrder(order);
    final Widget card = Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate100),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: orderIconBackground(order.opsStatus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  orderLeadingIcon(order.opsStatus),
                  color: orderIconForeground(order.opsStatus),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      orderTitle(order),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: AppColors.inkStrong,
                      ),
                    ),
                    Text(
                      orderItemsPreview(order),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      orderPersonLabel(order),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    orderRelativeTimeLabel(order),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orderCurrency(order.payableTotal),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.55,
                      color: AppColors.inkStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: orderListStatusBackground(order.opsStatus),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      orderListStatusLabel(order.opsStatus),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: orderListStatusForeground(order.opsStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (showDualActions || showSingleAction) ...<Widget>[
            const SizedBox(height: 16),
            if (showDualActions)
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CardActionButton(
                      label: 'Sipariş Onayla',
                      backgroundColor: AppColors.success,
                      icon: Icons.check_circle_outline_rounded,
                      isBusy: isBusy,
                      onTap: isBusy ? null : onPrimaryTap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CardActionButton(
                      label: 'Sipariş İptal Et',
                      backgroundColor: orderCancelRed,
                      icon: Icons.cancel_outlined,
                      isBusy: isBusy,
                      onTap: isBusy || onCancelTap == null ? null : onCancelTap,
                    ),
                  ),
                ],
              )
            else
              _CardActionButton(
                label: orderPrimaryActionLabel(order),
                backgroundColor: orderPrimaryActionBackground(order),
                icon: orderPrimaryActionIcon(order),
                isBusy: isBusy,
                onTap: isBusy ? null : onPrimaryTap,
                expand: true,
              ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF8FAFC)),
          const SizedBox(height: 13),
          InkWell(
            onTap: onDetailTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Sipariş Detayı',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.33,
                      color: AppColors.activeNavItemText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: AppColors.activeNavItemText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(opacity: orderCardOpacity(order.opsStatus), child: card);
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.backgroundColor,
    required this.icon,
    required this.isBusy,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final Color backgroundColor;
  final IconData icon;
  final bool isBusy;
  final Future<void> Function()? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      width: expand ? double.infinity : null,
      height: 40,
      child: ElevatedButton(
        onPressed: onTap == null ? null : () => onTap!(),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slate200,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (expand) {
      return button;
    }
    return button;
  }
}

class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Bu filtre için sipariş bulunamadı.',
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
