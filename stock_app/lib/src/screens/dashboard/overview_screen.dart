import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import '../../widgets/vendor_picker_button.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final SpetoCatalogVendor? vendor = controller.selectedVendor;
    final inventory = controller.inventorySnapshot;
    final finance = controller.financeSummary;
    final campaigns = controller.campaignSummary;
    final List<SpetoOpsOrder> latestOrders = controller.orders.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Row(
          children: <Widget>[
            const Icon(Icons.storefront, color: AppColors.emerald700, size: 24),
            const SizedBox(width: 8),
            const Text(
              'SepetPro İşyerim',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.emerald700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          VendorPickerButton(controller: controller),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.slate500),
            onPressed: controller.isLoading ? null : controller.refreshData,
          ),
        ],
      ),
      body: controller.isLoading && vendor == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ).copyWith(bottom: 120),
              children: <Widget>[
                const Text(
                  'Genel Bakış',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.dashboardError != null && vendor == null)
                  _ErrorBanner(message: controller.dashboardError!),
                if (vendor != null) _buildVendorBanner(vendor),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const <Widget>[
                    Text(
                      'Bugün Genel Bakış',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: <Widget>[
                    _buildStatCard(
                      'Açık Sipariş',
                      '${inventory?.openOrdersCount ?? 0}',
                      Icons.shopping_basket,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      'Mevcut Bakiye',
                      _currency(finance?.availableBalance ?? 0),
                      Icons.payments,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      'Düşük Stok',
                      '${inventory?.lowStockCount ?? 0}',
                      Icons.takeout_dining,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Aktif Kampanya',
                      '${campaigns?.activeCount ?? 0}',
                      Icons.campaign,
                      AppColors.emerald500,
                      isOutlined: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const <Widget>[
                    Text(
                      'Yeni Siparişler',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (latestOrders.isEmpty)
                  const _EmptyCard(message: 'Henüz sipariş bulunmuyor.')
                else
                  for (final order in latestOrders) ...<Widget>[
                    _buildOrderListItem(order, controller.storefrontType),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
    );
  }

  Widget _buildVendorBanner(SpetoCatalogVendor vendor) {
    final pickup = vendor.pickupPoints.isNotEmpty
        ? vendor.pickupPoints.first
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              vendor.storefrontType == SpetoStorefrontType.restaurant
                  ? Icons.restaurant
                  : Icons.local_grocery_store,
              color: AppColors.emerald600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  vendor.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        pickup?.label.isNotEmpty == true
                            ? pickup!.label
                            : vendor.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vendor.isActive ? 'Açık' : 'Pasif',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emerald600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  vendor.workingHoursLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isOutlined = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isOutlined ? Border.all(color: AppColors.emerald200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isOutlined ? color : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isOutlined ? Colors.white : color,
              size: 18,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderListItem(
    SpetoOpsOrder order,
    SpetoStorefrontType storefrontType,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: storefrontType == SpetoStorefrontType.restaurant
                    ? AppColors.emerald50
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                storefrontType == SpetoStorefrontType.restaurant
                    ? Icons.restaurant
                    : Icons.local_grocery_store,
                color: storefrontType == SpetoStorefrontType.restaurant
                    ? AppColors.emerald600
                    : AppColors.slate400,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    order.vendor,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.items
                        .map((SpetoCartItem item) => item.title)
                        .take(2)
                        .join(' + '),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  _currency(order.payableTotal),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.placedAtLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _currency(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    return '₺${parts.first},${parts.last}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.slate500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
