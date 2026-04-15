import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final List<SpetoIntegrationConnection> integrations =
        controller.integrations;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.emerald700),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Entegrasyonlar',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.onSurface,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.slate500),
            onPressed: () => _showCreateIntegrationDialog(context, controller),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: <Widget>[
          const Text(
            'MAĞAZA YÖNETİMİ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sisteminizi\nGüçlendirin.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.emerald700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İşletmenizi dijital dünyaya bağlayın ve tüm süreçleri tek bir merkezden yönetin.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slate500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (integrations.isEmpty)
            const _EmptyIntegrationsCard()
          else
            for (final integration in integrations) ...<Widget>[
              _buildIntegrationCard(controller, integration),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(
    StockAppController controller,
    SpetoIntegrationConnection integration,
  ) {
    final bool isConnected =
        integration.health != SpetoIntegrationHealth.failed;
    final Color mainColor = integration.type == SpetoIntegrationType.pos
        ? AppColors.primaryContainer
        : Colors.orange;
    final String status = integration.lastSync.completedAtLabel.isEmpty
        ? 'Henüz senkron yok'
        : integration.lastSync.completedAtLabel;
    return Container(
      padding: const EdgeInsets.all(20),
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
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    integration.type == SpetoIntegrationType.pos
                        ? Icons.point_of_sale
                        : Icons.account_balance,
                    color: mainColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        integration.name,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${integration.provider} • $status',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          isConnected
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        integration.health.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          controller.isBusy('integration:${integration.id}')
                          ? null
                          : () => controller.syncIntegration(integration.id),
                      child: const Text('Senkron Et'),
                    ),
                  ],
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE7E8E9),
                    foregroundColor: AppColors.slate600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => controller.syncIntegration(integration.id),
                  child: const Text(
                    'Tekrar Dene',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _showCreateIntegrationDialog(
    BuildContext context,
    StockAppController controller,
  ) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController providerController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    SpetoIntegrationType selectedType = SpetoIntegrationType.pos;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Entegrasyon Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Bağlantı adı',
                      ),
                    ),
                    TextField(
                      controller: providerController,
                      decoration: const InputDecoration(labelText: 'Sağlayıcı'),
                    ),
                    DropdownButtonFormField<SpetoIntegrationType>(
                      initialValue: selectedType,
                      items: SpetoIntegrationType.values
                          .map(
                            (type) => DropdownMenuItem<SpetoIntegrationType>(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (SpetoIntegrationType? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() => selectedType = value);
                      },
                    ),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: 'Base URL'),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasyon ID',
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
      await controller.createIntegration(
        name: nameController.text,
        provider: providerController.text,
        type: selectedType,
        baseUrl: urlController.text,
        locationId: locationController.text,
      );
    }

    nameController.dispose();
    providerController.dispose();
    urlController.dispose();
    locationController.dispose();
  }
}

class _EmptyIntegrationsCard extends StatelessWidget {
  const _EmptyIntegrationsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.add_link, color: AppColors.slate400, size: 40),
          SizedBox(height: 12),
          Text(
            'Henüz entegrasyon bağlantısı yok.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Yeni bir POS veya ERP bağlantısı ekleyerek başlayabilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
