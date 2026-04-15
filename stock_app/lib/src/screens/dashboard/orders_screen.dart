import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import '../../widgets/vendor_picker_button.dart';
import 'orders_filter_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'Tümü';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final List<SpetoOpsOrder> filteredOrders = controller.orders
        .where((order) {
          final String query = _searchController.text.trim().toLowerCase();
          final bool matchesQuery =
              query.isEmpty ||
              order.vendor.toLowerCase().contains(query) ||
              order.items.any(
                (item) => item.title.toLowerCase().contains(query),
              ) ||
              order.pickupCode.toLowerCase().contains(query);
          if (!matchesQuery) {
            return false;
          }
          return switch (_selectedTab) {
            'Yeni' => order.opsStatus == SpetoOpsOrderStage.created,
            'Hazırlanıyor' =>
              order.opsStatus == SpetoOpsOrderStage.accepted ||
                  order.opsStatus == SpetoOpsOrderStage.preparing,
            'Hazır' => order.opsStatus == SpetoOpsOrderStage.ready,
            'Tamamlananlar' => order.opsStatus == SpetoOpsOrderStage.completed,
            _ => true,
          };
        })
        .toList(growable: false);

    final int newOrders = controller.orders
        .where((order) => order.opsStatus == SpetoOpsOrderStage.created)
        .length;
    final int activeOrders = controller.orders
        .where((order) => order.status == SpetoOrderStatus.active)
        .length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.reorder, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Siparişler',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          VendorPickerButton(controller: controller),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.slate700),
            onPressed: controller.isLoading ? null : controller.refreshData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            icon: Icon(
                              Icons.search,
                              color: AppColors.slate400,
                              size: 20,
                            ),
                            hintText: 'Siparişler',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.85,
                            child: const OrdersFilterScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.slate200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: AppColors.slate600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    _buildTab('Tümü'),
                    _buildTab('Yeni'),
                    _buildTab('Hazırlanıyor'),
                    _buildTab('Hazır'),
                    _buildTab('Tamamlananlar'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 120,
          left: 20,
          right: 20,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _buildSummaryCard(
                  'Toplam Sipariş',
                  '${controller.orders.length}',
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Aktif Sipariş',
                  '$activeOrders',
                  Icons.receipt_long,
                  hasArrow: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (newOrders > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFFFEDD5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.error, color: Color(0xFFF97316)),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '$newOrders yeni sipariş',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text: ' bekliyor',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.slate400),
                ],
              ),
            ),
          if (newOrders > 0) const SizedBox(height: 24),
          const Text(
            'Sipariş Listesi',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (filteredOrders.isEmpty)
            const _EmptyOrdersCard()
          else
            for (final order in filteredOrders)
              _buildOrderCard(order, controller),
        ],
      ),
    );
  }

  Widget _buildTab(String text) {
    final bool isActive = _selectedTab == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = text),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.emerald50 : Colors.transparent,
          border: isActive ? Border.all(color: AppColors.emerald100) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? AppColors.emerald600 : AppColors.slate500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon, {
    bool hasArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.slate100),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.emerald600, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (hasArrow)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.slate400,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(SpetoOpsOrder order, StockAppController controller) {
    final bool isRestaurant =
        controller.storefrontType == SpetoStorefrontType.restaurant;
    final bool isBusy = controller.isBusy('order:${order.id}');
    final bool canAccept = order.opsStatus == SpetoOpsOrderStage.created;
    final bool canCancel =
        order.opsStatus != SpetoOpsOrderStage.completed &&
        order.opsStatus != SpetoOpsOrderStage.cancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.slate100),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRestaurant
                          ? const Color(0xFFFFF7ED)
                          : AppColors.emerald50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isRestaurant ? Icons.restaurant : Icons.local_mall,
                      color: isRestaurant
                          ? const Color(0xFFC2410C)
                          : AppColors.emerald700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 170,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          order.pickupCode.isEmpty
                              ? order.id
                              : 'Sipariş #${order.pickupCode}',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.items.map((item) => item.title).join(' + '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.vendor,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    order.placedAtLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slate400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₺${order.payableTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.opsStatus.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.emerald600,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: isBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(
                    canAccept ? 'Siparişi Onayla' : 'İlerle',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: isBusy
                      ? null
                      : () {
                          final SpetoOpsOrderStage stage = canAccept
                              ? SpetoOpsOrderStage.accepted
                              : order.opsStatus == SpetoOpsOrderStage.accepted
                              ? SpetoOpsOrderStage.preparing
                              : order.opsStatus == SpetoOpsOrderStage.preparing
                              ? SpetoOpsOrderStage.ready
                              : SpetoOpsOrderStage.completed;
                          controller.updateOrderStatus(order.id, stage);
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text(
                    'Siparişi İptal Et',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: !canCancel || isBusy
                      ? null
                      : () {
                          controller.updateOrderStatus(
                            order.id,
                            SpetoOpsOrderStage.cancelled,
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      child: const Text(
        'Bu filtre için sipariş bulunamadı.',
        style: TextStyle(
          color: AppColors.slate500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
