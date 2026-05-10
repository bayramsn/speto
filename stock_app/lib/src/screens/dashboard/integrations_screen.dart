import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  static const List<_IntegrationPreset> _presets = <_IntegrationPreset>[
    _IntegrationPreset(
      id: 'register_pos',
      title: 'Yazarkasa POS',
      description: 'Ödeme sistemleri\nentegrasyonu',
      icon: Icons.point_of_sale_rounded,
      iconColor: AppColors.primary,
      iconBackground: Color(0x1A2ECC71),
      type: SpetoIntegrationType.pos,
      defaultProvider: 'Nebim POS',
      defaultActionLabel: 'Ayarlar',
      previewConnected: true,
    ),
    _IntegrationPreset(
      id: 'adisyon_pos',
      title: 'Adisyon POS',
      description: 'Restoran yönetim\nterminali',
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF5875B2),
      iconBackground: Color(0x1AA8BCFE),
      type: SpetoIntegrationType.pos,
      defaultProvider: 'Adisyon POS',
      defaultActionLabel: 'Ayarlar',
      previewConnected: false,
    ),
    _IntegrationPreset(
      id: 'accounting',
      title: 'Muhasebe',
      description: 'E-Fatura ve finansal\ntakip',
      icon: Icons.account_balance_outlined,
      iconColor: Color(0xFFB65E3C),
      iconBackground: Color(0x1AFF9875),
      type: SpetoIntegrationType.erp,
      defaultProvider: 'Logo ERP',
      defaultActionLabel: 'Yönet',
      previewConnected: false,
    ),
    _IntegrationPreset(
      id: 'qr_menu',
      title: 'QR Menü',
      description: 'Dijital menü ve sipariş',
      icon: Icons.qr_code_2_rounded,
      iconColor: AppColors.primary,
      iconBackground: Color(0x1A2ECC71),
      type: SpetoIntegrationType.pos,
      defaultProvider: 'QR Menü',
      defaultActionLabel: 'Yönet',
      previewConnected: true,
      compactHeight: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final List<_ResolvedIntegrationCard> cards = _resolveCards(
      controller.integrations,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double horizontalInset = constraints.maxWidth > 720
                ? (constraints.maxWidth - 672) / 2
                : 24;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                16,
                horizontalInset,
                40,
              ),
              children: <Widget>[
                _HeaderRow(onBack: () => Navigator.pop(context)),
                const SizedBox(height: 16),
                const _EditorialSection(),
                const SizedBox(height: 32),
                for (final _ResolvedIntegrationCard card in cards) ...<Widget>[
                  _IntegrationCard(
                    card: card,
                    isBusy:
                        card.integration != null &&
                        controller.isBusy(
                          'integration:${card.integration!.id}',
                        ),
                    onTapAction: () async {
                      if (card.integration != null) {
                        await _showIntegrationManagementDialog(
                          context,
                          controller,
                          card,
                        );
                        return;
                      }
                      await _showCreateIntegrationDialog(
                        context,
                        controller,
                        card.preset,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                _ApiDocumentationCard(onTap: () => _showApiDocsNotice(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_ResolvedIntegrationCard> _resolveCards(
    List<SpetoIntegrationConnection> integrations,
  ) {
    final List<SpetoIntegrationConnection> remaining =
        List<SpetoIntegrationConnection>.from(integrations);
    final bool usePreviewState = remaining.isEmpty;

    return _presets
        .map((_IntegrationPreset preset) {
          SpetoIntegrationConnection? match;

          final int exactIndex = remaining.indexWhere(
            (SpetoIntegrationConnection integration) =>
                _matchesPreset(preset, integration),
          );
          if (exactIndex != -1) {
            match = remaining.removeAt(exactIndex);
          } else {
            final int fallbackIndex = remaining.indexWhere(
              (SpetoIntegrationConnection integration) =>
                  _matchesFallbackType(preset, integration),
            );
            if (fallbackIndex != -1) {
              match = remaining.removeAt(fallbackIndex);
            }
          }

          final bool connected =
              (match != null &&
                  match.health != SpetoIntegrationHealth.failed) ||
              (usePreviewState && preset.previewConnected);

          return _ResolvedIntegrationCard(
            preset: preset,
            integration: match,
            isConnected: connected,
          );
        })
        .toList(growable: false);
  }

  bool _matchesPreset(
    _IntegrationPreset preset,
    SpetoIntegrationConnection integration,
  ) {
    final String haystack = '${integration.name} ${integration.provider}'
        .toLowerCase();
    return switch (preset.id) {
      'register_pos' =>
        haystack.contains('yazarkasa') ||
            haystack.contains('kasa') ||
            haystack.contains('nebim'),
      'adisyon_pos' =>
        haystack.contains('adisyon') ||
            haystack.contains('masa') ||
            haystack.contains('terminal'),
      'accounting' =>
        haystack.contains('muhasebe') ||
            haystack.contains('logo') ||
            haystack.contains('fatura'),
      'qr_menu' => haystack.contains('qr') || haystack.contains('menü'),
      _ => false,
    };
  }

  bool _matchesFallbackType(
    _IntegrationPreset preset,
    SpetoIntegrationConnection integration,
  ) {
    if (preset.id == 'accounting') {
      return integration.type == SpetoIntegrationType.erp;
    }
    if (preset.id == 'qr_menu') {
      return false;
    }
    return integration.type == SpetoIntegrationType.pos;
  }

  Future<void> _showCreateIntegrationDialog(
    BuildContext context,
    StockAppController controller,
    _IntegrationPreset preset,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: preset.title,
    );
    final TextEditingController providerController = TextEditingController(
      text: preset.defaultProvider,
    );
    final TextEditingController urlController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    SpetoIntegrationType selectedType = preset.type;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                '${preset.title} Bağlantısı',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: providerController,
                      decoration: const InputDecoration(labelText: 'Sağlayıcı'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SpetoIntegrationType>(
                      initialValue: selectedType,
                      items: SpetoIntegrationType.values
                          .map(
                            (SpetoIntegrationType type) =>
                                DropdownMenuItem<SpetoIntegrationType>(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                ),
                          )
                          .toList(growable: false),
                      onChanged: (SpetoIntegrationType? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                  child: const Text('Bağla'),
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

  Future<void> _showIntegrationManagementDialog(
    BuildContext context,
    StockAppController controller,
    _ResolvedIntegrationCard card,
  ) async {
    final SpetoIntegrationConnection? integration = card.integration;
    if (integration == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            card.preset.title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _IntegrationDetailLine(
                label: 'Sağlayıcı',
                value: integration.provider,
              ),
              const SizedBox(height: 12),
              _IntegrationDetailLine(
                label: 'Base URL',
                value: integration.baseUrl,
              ),
              const SizedBox(height: 12),
              _IntegrationDetailLine(
                label: 'Lokasyon ID',
                value: integration.locationId,
              ),
              const SizedBox(height: 12),
              _IntegrationDetailLine(
                label: 'Son durum',
                value: integration.lastSync.completedAtLabel.isEmpty
                    ? 'Henüz senkron yok'
                    : integration.lastSync.completedAtLabel,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await controller.syncIntegration(integration.id);
              },
              child: const Text('Senkron Et'),
            ),
          ],
        );
      },
    );
  }

  void _showApiDocsNotice(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'API dokümanı bağlantısı backend tarafında tanımlandığında buradan açılacak.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onBack,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Hesap Ayarları',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 28 / 18,
            letterSpacing: -0.45,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EditorialSection extends StatelessWidget {
  const _EditorialSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'MAĞAZA YÖNETİMİ',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
            letterSpacing: 0.35,
            color: AppColors.bodyText,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Sisteminizi\nGüçlendirin.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 36 / 30,
            letterSpacing: -0.75,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: 320,
          child: Text(
            'İşletmenizi dijital dünyaya bağlayın ve tüm\nsüreçleri tek bir merkezden yönetin.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 26 / 16,
              color: AppColors.bodyText,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({
    required this.card,
    required this.isBusy,
    required this.onTapAction,
  });

  final _ResolvedIntegrationCard card;
  final bool isBusy;
  final VoidCallback onTapAction;

  @override
  Widget build(BuildContext context) {
    final _IntegrationPreset preset = card.preset;
    final double height = preset.compactHeight ? 96 : 104;

    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  width: preset.compactHeight ? 56 : 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: preset.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    preset.icon,
                    size: preset.compactHeight ? 22.5 : 25,
                    color: preset.iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        preset.title,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 24 / 16,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        preset.description,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 20 / 14,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          card.isConnected
              ? _ConnectedIntegrationAction(
                  label: preset.defaultActionLabel,
                  isBusy: isBusy,
                  onTap: onTapAction,
                )
              : _ConnectButton(isBusy: isBusy, onTap: onTapAction),
        ],
      ),
    );
  }
}

class _ConnectedIntegrationAction extends StatelessWidget {
  const _ConnectedIntegrationAction({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'BAĞLANDI',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 16.5 / 11,
              letterSpacing: 0.55,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isBusy ? null : onTap,
          child: Text(
            isBusy ? 'Yükleniyor' : label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: AppColors.bodyText,
              decoration: TextDecoration.underline,
              decorationColor: Color(0x4D006D37),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isBusy ? null : onTap,
        child: Container(
          width: 99,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE7E8E9),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            isBusy ? 'Bekleyin' : 'Bağlantı\nYap',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 18 / 12,
              color: AppColors.bodyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _ApiDocumentationCard extends StatelessWidget {
  const _ApiDocumentationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x4DBBCBBB),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.add_link_rounded,
            size: 30,
            color: AppColors.primary.withValues(alpha: 0.40),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aradığınızı bulamadınız mı?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 292,
            child: Text(
              'API dokümantasyonumuzu inceleyerek\nkendi özel entegrasyonunuzu\ngeliştirebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                color: AppColors.bodyText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'API Dokümanı',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 10,
                    color: AppColors.primary,
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

class _IntegrationDetailLine extends StatelessWidget {
  const _IntegrationDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _IntegrationPreset {
  const _IntegrationPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.type,
    required this.defaultProvider,
    required this.defaultActionLabel,
    required this.previewConnected,
    this.compactHeight = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final SpetoIntegrationType type;
  final String defaultProvider;
  final String defaultActionLabel;
  final bool previewConnected;
  final bool compactHeight;
}

class _ResolvedIntegrationCard {
  const _ResolvedIntegrationCard({
    required this.preset,
    required this.integration,
    required this.isConnected,
  });

  final _IntegrationPreset preset;
  final SpetoIntegrationConnection? integration;
  final bool isConnected;
}
