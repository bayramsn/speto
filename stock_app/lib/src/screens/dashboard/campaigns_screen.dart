import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import '../../widgets/vendor_picker_button.dart';

enum CampaignsScreenMode { updated, past }

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key, this.mode});

  final CampaignsScreenMode? mode;

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final CampaignsScreenMode resolvedMode =
        mode ??
        (controller.isRestaurantMode
            ? CampaignsScreenMode.updated
            : CampaignsScreenMode.past);
    return Scaffold(
      backgroundColor: resolvedMode == CampaignsScreenMode.updated
          ? const Color(0xFFF8F9FA)
          : AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Row(
          children: <Widget>[
            Icon(
              resolvedMode == CampaignsScreenMode.updated
                  ? Icons.storefront
                  : Icons.menu,
              color: AppColors.emerald700,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              resolvedMode == CampaignsScreenMode.updated
                  ? 'SepetPro İşyerim'
                  : 'Kampanyalar',
              style: const TextStyle(
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
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.slate500,
            ),
            onPressed: () => _showCreateCampaignDialog(context, controller),
          ),
        ],
      ),
      body: resolvedMode == CampaignsScreenMode.updated
          ? _buildUpdatedLayout(context, controller)
          : _buildPastLayout(context, controller),
    );
  }

  Widget _buildUpdatedLayout(
    BuildContext context,
    StockAppController controller,
  ) {
    final List<SpetoVendorCampaign> campaigns =
        controller.campaignSummary?.campaigns ?? const <SpetoVendorCampaign>[];
    final List<SpetoInventoryItem> criticalItems = controller.inventoryItems
        .where(
          (item) => item.stockStatus.lowStock || !item.stockStatus.isInStock,
        )
        .take(3)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ).copyWith(bottom: 120),
      children: <Widget>[
        _buildSectionHeader('Aktif Kampanyalar', 'Tümünü Gör'),
        const SizedBox(height: 12),
        if (campaigns.isEmpty)
          const _EmptyCampaignsCard(message: 'Aktif kampanya bulunmuyor.')
        else
          for (final campaign in campaigns)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCampaignCard(controller, campaign),
            ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Kampanya Özeti',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${controller.campaignSummary?.activeCount ?? 0} aktif',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emerald700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _metricCard(
                      'Taslak',
                      '${controller.campaignSummary?.draftCount ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      'Duraklatıldı',
                      '${controller.campaignSummary?.pausedCount ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      'Kritik Ürün',
                      '${controller.campaignSummary?.criticalProductCount ?? 0}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Bugün Bitecek Ürünler', 'Tümünü Gör'),
        const SizedBox(height: 12),
        if (criticalItems.isEmpty)
          const _EmptyCampaignsCard(message: 'Kritik stokta ürün yok.')
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: criticalItems
                  .map((item) => _buildCriticalItem(item))
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionItem(
          Icons.campaign,
          'Kampanya Başlat',
          () => _showCreateCampaignDialog(context, controller),
        ),
        const SizedBox(height: 8),
        _buildActionItem(
          Icons.timer,
          'Happy Hour Aç/Kapat',
          () => _showCreateCampaignDialog(
            context,
            controller,
            defaultKind: SpetoCampaignKind.happyHour,
          ),
        ),
      ],
    );
  }

  Widget _buildPastLayout(BuildContext context, StockAppController controller) {
    final List<SpetoVendorCampaign> campaigns =
        controller.campaignSummary?.campaigns ?? const <SpetoVendorCampaign>[];
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ).copyWith(bottom: 120),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Haftalık Kampanya Etkisi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${controller.campaignSummary?.activeCount ?? 0} aktif',
                      style: const TextStyle(
                        color: AppColors.emerald700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '₺${(controller.financeSummary?.availableBalance ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Performans özeti aktif kampanya gelirini temsil eder.',
                  style: TextStyle(color: AppColors.slate400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Aktif Kampanyalar',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (campaigns.isEmpty)
          const _EmptyCampaignsCard(message: 'Aktif kampanya bulunmuyor.')
        else
          for (final campaign in campaigns)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCampaignCard(controller, campaign),
            ),
      ],
    );
  }

  Widget _buildCampaignCard(
    StockAppController controller,
    SpetoVendorCampaign campaign,
  ) {
    final bool enabled = campaign.status == SpetoCampaignStatus.active;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  campaign.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.schedule,
                      size: 12,
                      color: AppColors.slate500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      campaign.scheduleLabel.isEmpty
                          ? 'Takvim tanımsız'
                          : campaign.scheduleLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate500,
                      ),
                    ),
                    if (campaign.badgeLabel.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          campaign.badgeLabel,
                          style: const TextStyle(
                            color: Color(0xFFC2410C),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (campaign.productTitles.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    campaign.productTitles.take(2).join(', '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: controller.isBusy('campaign:${campaign.id}')
                ? null
                : (_) => controller.toggleCampaign(campaign.id),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalItem(SpetoInventoryItem item) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Stok: ${item.availableQuantity}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: item.stockStatus.isInStock
                  ? const Color(0xFFFFEDD5)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.stockStatus.isInStock ? 'Kritik stok' : 'Tükendi',
              style: TextStyle(
                color: item.stockStatus.isInStock
                    ? const Color(0xFFC2410C)
                    : const Color(0xFFB91C1C),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.emerald700, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: AppColors.emerald700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateCampaignDialog(
    BuildContext context,
    StockAppController controller, {
    SpetoCampaignKind defaultKind = SpetoCampaignKind.discount,
  }) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController scheduleController = TextEditingController();
    final TextEditingController badgeController = TextEditingController();
    final TextEditingController discountController = TextEditingController(
      text: '20',
    );
    SpetoCampaignKind selectedKind = defaultKind;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Kampanya Başlat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<SpetoCampaignKind>(
                      initialValue: selectedKind,
                      items: SpetoCampaignKind.values
                          .map(
                            (kind) => DropdownMenuItem<SpetoCampaignKind>(
                              value: kind,
                              child: Text(kind.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (SpetoCampaignKind? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() => selectedKind = value);
                      },
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Başlık'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Açıklama'),
                    ),
                    TextField(
                      controller: scheduleController,
                      decoration: const InputDecoration(
                        labelText: 'Saat aralığı / zaman etiketi',
                      ),
                    ),
                    TextField(
                      controller: badgeController,
                      decoration: const InputDecoration(
                        labelText: 'Rozet etiketi',
                      ),
                    ),
                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'İndirim yüzdesi',
                      ),
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

    if (confirmed == true) {
      await controller.createCampaign(
        kind: selectedKind,
        title: titleController.text,
        description: descriptionController.text,
        scheduleLabel: scheduleController.text,
        badgeLabel: badgeController.text,
        discountPercent: int.tryParse(discountController.text),
        productIds: controller.products
            .take(2)
            .map((product) => product.id)
            .toList(),
      );
    }

    titleController.dispose();
    descriptionController.dispose();
    scheduleController.dispose();
    badgeController.dispose();
    discountController.dispose();
  }
}

class _EmptyCampaignsCard extends StatelessWidget {
  const _EmptyCampaignsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
