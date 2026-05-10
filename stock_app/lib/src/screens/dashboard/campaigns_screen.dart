import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'campaign_payment_screens.dart';
import 'support_center_screen.dart';

enum CampaignsScreenMode { updated, past }

bool get _restrictCampaignsToOtherBusinesses => true;

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({
    super.key,
    this.mode,
    this.onOpenProducts,
    this.onBack,
  });

  final CampaignsScreenMode? mode;
  final VoidCallback? onOpenProducts;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);

    if (controller.isOtherBusinessMode) {
      return _buildOtherBusinessScaffold(context, controller);
    }

    if (_restrictCampaignsToOtherBusinesses) {
      return _CampaignsRestrictedAccessScreen(onBack: onBack);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: <Widget>[
          _CampaignsTopBar(
            isLoading: controller.isLoading,
            onRefresh: controller.refreshData,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshData,
              edgeOffset: 12,
              child: _buildUpdatedLayout(context, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherBusinessScaffold(
    BuildContext context,
    StockAppController controller,
  ) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: <Widget>[
          _OtherBusinessCampaignsTopBar(
            isLoading: controller.isLoading,
            onRefresh: controller.refreshData,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshData,
              edgeOffset: 12,
              child: _buildOtherBusinessLayout(context, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherBusinessLayout(
    BuildContext context,
    StockAppController controller,
  ) {
    final _OtherBusinessCampaignPerformance performance =
        _buildOtherBusinessCampaignPerformance(controller.orders);
    final _OtherBusinessFeatureCampaignData featureCampaign =
        _buildOtherBusinessFeatureCampaign(controller.campaignSummary);
    final List<_OtherBusinessActiveCampaignData> activeCampaigns =
        _buildOtherBusinessActiveCampaigns(controller.campaignSummary);
    final List<_OtherBusinessPastCampaignData> pastCampaigns =
        _buildOtherBusinessPastCampaigns(controller.campaignSummary);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      children: <Widget>[
        _OtherBusinessCampaignPerformanceCard(model: performance),
        const SizedBox(height: 32),
        _OtherBusinessFeatureCampaignCard(
          data: featureCampaign,
          onTap: () => _showCreateCampaignDialog(
            context,
            controller,
            defaultKind: featureCampaign.defaultKind,
          ),
        ),
        const SizedBox(height: 32),
        _OtherBusinessCampaignSection(
          title: 'Aktif Kampanyalar',
          spacing: 16,
          children: activeCampaigns
              .map(
                (_OtherBusinessActiveCampaignData campaign) =>
                    _OtherBusinessActiveCampaignCard(
                      data: campaign,
                      onTap: campaign.campaign == null
                          ? null
                          : () => _showCampaignDetailScreen(
                              context,
                              controller,
                              campaign.campaign!,
                            ),
                    ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 32),
        _OtherBusinessCampaignSection(
          title: 'Geçmiş Kampanyalar',
          spacing: 12,
          children: pastCampaigns
              .map(
                (_OtherBusinessPastCampaignData campaign) =>
                    _OtherBusinessPastCampaignCard(
                      data: campaign,
                      onTap: campaign.campaign == null
                          ? null
                          : () => _showCampaignDetailScreen(
                              context,
                              controller,
                              campaign.campaign!,
                            ),
                    ),
              )
              .toList(growable: false),
        ),
        if (controller.dashboardError != null) ...<Widget>[
          const SizedBox(height: 24),
          _CampaignsInlineNotice(message: controller.dashboardError!),
        ],
        if (controller.isLoading &&
            controller.orders.isEmpty &&
            (controller.campaignSummary?.campaigns.isEmpty ?? true))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildUpdatedLayout(
    BuildContext context,
    StockAppController controller,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: <Widget>[
        _CampaignsSalesCard(model: _buildChartModel(controller.orders)),
        const SizedBox(height: 28),
        _CampaignsSectionHeader(
          title: 'Bugün Bitecek Ürünler',
          actionLabel: 'Tümünü Gör',
        ),
        const SizedBox(height: 12),
        _CampaignsExpiringProductsCard(
          items: _buildInventoryHighlights(controller),
        ),
        const SizedBox(height: 28),
        Text(
          'Hızlı İşlemler',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _CampaignsQuickActionButton(
          icon: Icons.add_circle_outline_rounded,
          title: 'Yeni Ürün Ekle',
          onTap: onOpenProducts,
        ),
        const SizedBox(height: 8),
        _CampaignsQuickActionButton(
          icon: Icons.campaign_outlined,
          title: 'Kampanya Başlat',
          onTap: () => _showCreateCampaignDialog(context, controller),
        ),
        const SizedBox(height: 8),
        _CampaignsQuickActionButton(
          icon: Icons.fact_check_outlined,
          title: 'Stoğu Güncelle',
          onTap: onOpenProducts,
        ),
        if (controller.dashboardError != null) ...<Widget>[
          const SizedBox(height: 20),
          _CampaignsInlineNotice(message: controller.dashboardError!),
        ],
        if (controller.isLoading &&
            controller.orders.isEmpty &&
            controller.inventoryItems.isEmpty &&
            controller.products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _showCreateCampaignDialog(
    BuildContext context,
    StockAppController controller, {
    SpetoCampaignKind defaultKind = SpetoCampaignKind.discount,
  }) async {
    final bool? openPayment = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _CampaignEditorScreen(
          controller: controller,
          defaultKind: defaultKind,
        ),
      ),
    );
    if (openPayment == true && context.mounted) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          fullscreenDialog: true,
          builder: (BuildContext context) => const CampaignPaymentIbanScreen(),
        ),
      );
    }
  }

  Future<void> _showCampaignDetailScreen(
    BuildContext context,
    StockAppController controller,
    SpetoVendorCampaign campaign,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _CampaignEditorScreen(
          controller: controller,
          campaign: campaign,
          defaultKind: campaign.kind,
        ),
      ),
    );
  }
}

class _CampaignsRestrictedAccessScreen extends StatelessWidget {
  const _CampaignsRestrictedAccessScreen({this.onBack});

  final VoidCallback? onBack;

  void _goBack(BuildContext context) {
    final VoidCallback? callback = onBack;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _openSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SupportCenterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _CampaignsRestrictedHeader(onBack: () => _goBack(context)),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double canvasHeight = constraints.maxHeight < 812
                      ? 812
                      : constraints.maxHeight;
                  final double contentWidth = constraints.maxWidth < 390
                      ? constraints.maxWidth - 48
                      : 342;
                  final double contentLeft =
                      (constraints.maxWidth - contentWidth) / 2;

                  return SingleChildScrollView(
                    physics: constraints.maxHeight < 812
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: canvasHeight,
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            left: contentLeft,
                            top: 114,
                            width: contentWidth,
                            height: 488,
                            child: _CampaignsRestrictedContent(
                              onBack: () => _goBack(context),
                              onSupport: () => _openSupport(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignsRestrictedHeader extends StatelessWidget {
  const _CampaignsRestrictedHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 24,
            top: 16,
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onBack,
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'Kampanyalar',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 28 / 18,
                letterSpacing: -0.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignsRestrictedContent extends StatelessWidget {
  const _CampaignsRestrictedContent({
    required this.onBack,
    required this.onSupport,
  });

  final VoidCallback onBack;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _CampaignsRestrictedGraphic()),
        ),
        Positioned(
          top: 160,
          left: 0,
          right: 0,
          child: Column(
            children: <Widget>[
              Text(
                'Erişim Kısıtlı',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kampanyalar özelliği yalnızca "Diğer İşletme"\n'
                'olarak kayıtlı işletmelere açıktır. Bu özelliği\n'
                'kullanmak için işletme türünüzün uygun olması\n'
                'gerekmektedir.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: AppColors.bodyText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 26 / 16,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 360,
          left: 0,
          right: 0,
          child: Column(
            children: <Widget>[
              _CampaignsRestrictedButton(
                label: 'Destek Al',
                isPrimary: true,
                onTap: onSupport,
              ),
              const SizedBox(height: 16),
              _CampaignsRestrictedButton(
                label: 'Geri Dön',
                isPrimary: false,
                onTap: onBack,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampaignsRestrictedGraphic extends StatelessWidget {
  const _CampaignsRestrictedGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      height: 136,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 4,
            top: 0,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppColors.success.withValues(alpha: 0.20),
                            AppColors.success.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 37,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF6C7B6D),
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignsRestrictedButton extends StatelessWidget {
  const _CampaignsRestrictedButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: isPrimary ? null : AppColors.surfaceContainerLow,
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[AppColors.primary, AppColors.success],
                  )
                : null,
            borderRadius: radius,
            boxShadow: isPrimary
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isPrimary ? Colors.white : AppColors.onSurface,
                fontSize: 16,
                fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                height: 24 / 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignEditorScreen extends StatefulWidget {
  const _CampaignEditorScreen({
    required this.controller,
    required this.defaultKind,
    this.campaign,
  });

  final StockAppController controller;
  final SpetoCampaignKind defaultKind;
  final SpetoVendorCampaign? campaign;

  @override
  State<_CampaignEditorScreen> createState() => _CampaignEditorScreenState();
}

class _CampaignEditorScreenState extends State<_CampaignEditorScreen> {
  static const Color _createInputColor = Color(0xFFE1E3E4);
  static const Color _detailInputColor = Color(0xFFE7E8E9);
  static const Color _placeholderColor = Color(0xFFBBCBBB);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _stockLimitController;
  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _codeFocusNodes;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isSaving = false;

  bool get _isEdit => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final SpetoVendorCampaign? campaign = widget.campaign;
    _titleController = TextEditingController(text: campaign?.title ?? '');
    _descriptionController = TextEditingController(
      text: campaign?.description ?? '',
    );
    _imageUrlController = TextEditingController(text: campaign?.imageUrl ?? '');
    _stockLimitController = TextEditingController(
      text: campaign == null || campaign.stockLimit <= 0
          ? ''
          : campaign.stockLimit.toString(),
    );
    _startsAt = _parseCampaignEditorDate(campaign?.startsAt);
    _endsAt = _parseCampaignEditorDate(campaign?.endsAt);
    final String campaignCode = campaign == null ? '' : campaign.badgeLabel;
    _codeControllers = List<TextEditingController>.generate(
      4,
      (int index) => TextEditingController(
        text: index < campaignCode.length
            ? campaignCode[index].toUpperCase()
            : '',
      ),
    );
    _codeFocusNodes = List<FocusNode>.generate(4, (_) => FocusNode());
    _imageUrlController.addListener(_refreshImagePreview);
  }

  @override
  void dispose() {
    _imageUrlController.removeListener(_refreshImagePreview);
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _stockLimitController.dispose();
    for (final TextEditingController controller in _codeControllers) {
      controller.dispose();
    }
    for (final FocusNode node in _codeFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _refreshImagePreview() {
    if (mounted && _isEdit) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool edit = _isEdit;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _CampaignEditorHeader(
              title: edit ? 'Kampanya Detayı / Düzenle' : 'Kampanya Oluştur',
              isEdit: edit,
              isSaving: _isSaving,
              onBack: () => Navigator.of(context).maybePop(),
              onSave: _saveCampaign,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: edit ? _buildEditBody() : _buildCreateBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                _campaignTextField(
                  label: 'Kampanya Başlığı',
                  controller: _titleController,
                  hintText: 'Örn: Hafta Sonu İndirimi',
                  fillColor: _createInputColor,
                  radius: 12,
                  validator: _requiredValidator,
                  labelInset: 4,
                ),
                const SizedBox(height: 24),
                _campaignTextField(
                  label: 'Açıklama',
                  controller: _descriptionController,
                  hintText: 'Kampanya detaylarını girin...',
                  fillColor: _createInputColor,
                  radius: 12,
                  height: 120,
                  maxLines: null,
                  validator: _requiredValidator,
                  labelInset: 4,
                ),
                const SizedBox(height: 24),
                _campaignDateField(
                  label: 'Başlangıç Saati',
                  value: _startsAt,
                  fillColor: _createInputColor,
                  radius: 12,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickDateTime(isStart: true),
                  labelInset: 4,
                ),
                const SizedBox(height: 24),
                _campaignDateField(
                  label: 'Bitiş Saati',
                  value: _endsAt,
                  fillColor: _createInputColor,
                  radius: 12,
                  icon: Icons.event_outlined,
                  onTap: () => _pickDateTime(isStart: false),
                  labelInset: 4,
                ),
                const SizedBox(height: 24),
                _campaignTextField(
                  label: 'Kampanya Görseli URL',
                  controller: _imageUrlController,
                  hintText: 'https://ornek.com/gorsel.jpg',
                  fillColor: _createInputColor,
                  radius: 12,
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.image_outlined,
                  validator: _requiredValidator,
                  labelInset: 4,
                ),
                const SizedBox(height: 24),
                _buildCampaignCodeFields(),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _CampaignGradientButton(
            label: 'Kampanya Oluştur',
            icon: Icons.campaign_outlined,
            height: 60,
            borderRadius: 16,
            isLoading: _isSaving,
            onPressed: _saveCampaign,
          ),
        ],
      ),
    );
  }

  Widget _buildEditBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionCard(
            children: <Widget>[
              _sectionTitle('Kampanya Bilgileri'),
              const SizedBox(height: 24),
              _campaignTextField(
                label: 'Kampanya Başlığı',
                isRequired: true,
                controller: _titleController,
                fillColor: _detailInputColor,
                radius: 16,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 24),
              _campaignTextField(
                label: 'Açıklama',
                isRequired: true,
                controller: _descriptionController,
                fillColor: _detailInputColor,
                radius: 16,
                height: 120,
                maxLines: null,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 24),
              _campaignDateField(
                label: 'Başlangıç Tarihi & Saati',
                isRequired: true,
                value: _startsAt,
                fillColor: _detailInputColor,
                radius: 16,
                icon: Icons.calendar_today_outlined,
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 24),
              _campaignDateField(
                label: 'Bitiş Tarihi & Saati',
                isRequired: true,
                value: _endsAt,
                fillColor: _detailInputColor,
                radius: 16,
                icon: Icons.event_outlined,
                onTap: () => _pickDateTime(isStart: false),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _sectionCard(
            children: <Widget>[
              _sectionTitle('Görsel ve Limit'),
              const SizedBox(height: 24),
              _campaignTextField(
                label: 'Kampanya Görseli URL',
                isRequired: true,
                controller: _imageUrlController,
                fillColor: _detailInputColor,
                radius: 16,
                height: 72,
                maxLines: null,
                keyboardType: TextInputType.url,
                prefixIcon: Icons.link_rounded,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 24),
              _CampaignImagePreview(imageUrl: _imageUrlController.text.trim()),
              const SizedBox(height: 24),
              _campaignTextField(
                label: 'Kampanya Stok Limiti',
                controller: _stockLimitController,
                hintText: 'Limit yok',
                fillColor: _detailInputColor,
                radius: 16,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.credit_card_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Boş bırakılırsa kampanya sınırsız kullanım olarak\nkaydedilir.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 16 / 12,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            children: <Widget>[
              SizedBox(
                width: 82,
                height: 56,
                child: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    backgroundColor: _detailInputColor,
                    foregroundColor: AppColors.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'İptal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 24 / 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CampaignGradientButton(
                  label: 'Kaydet',
                  icon: Icons.check_rounded,
                  height: 56,
                  borderRadius: 12,
                  isLoading: _isSaving,
                  onPressed: _saveCampaign,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 36 / 24,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _campaignTextField({
    required String label,
    required TextEditingController controller,
    required Color fillColor,
    required double radius,
    String? hintText,
    bool isRequired = false,
    double labelInset = 0,
    double? height,
    int? maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    final InputDecoration decoration = InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _placeholderColor,
      ),
      filled: true,
      fillColor: fillColor,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: AppColors.bodyText, size: 18),
      contentPadding: EdgeInsets.fromLTRB(
        prefixIcon == null ? 16 : 0,
        height == null ? 12 : 12,
        16,
        height == null ? 12 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.success, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );

    final TextFormField field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: height == null ? maxLines : null,
      expands: height != null,
      textAlignVertical: height != null ? TextAlignVertical.top : null,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      ),
      decoration: decoration,
      validator: validator,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: labelInset),
          child: _CampaignFieldLabel(label: label, isRequired: isRequired),
        ),
        const SizedBox(height: 8),
        if (height == null) field else SizedBox(height: height, child: field),
      ],
    );
  }

  Widget _campaignDateField({
    required String label,
    required DateTime? value,
    required Color fillColor,
    required double radius,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
    double labelInset = 0,
  }) {
    final bool hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: labelInset),
          child: _CampaignFieldLabel(label: label, isRequired: isRequired),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSaving ? null : onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: AppColors.bodyText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue
                        ? _formatCampaignEditorDate(value)
                        : 'mm / dd / yyyy, --:--',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 24 / 16,
                      color: hasValue
                          ? AppColors.onSurface
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignCodeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: _CampaignFieldLabel(label: 'Kampanya Kodu'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(4, (int index) {
            return Padding(
              padding: EdgeInsets.only(right: index == 3 ? 0 : 16),
              child: SizedBox(
                width: 56,
                height: 56,
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _codeFocusNodes[index],
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _createInputColor,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.success,
                        width: 1.2,
                      ),
                    ),
                  ),
                  onChanged: (String value) => _onCodeChanged(index, value),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = (isStart ? _startsAt : _endsAt) ?? now;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              secondary: AppColors.success,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!mounted || pickedDate == null) {
      return;
    }

    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              secondary: AppColors.success,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!mounted || pickedTime == null) {
      return;
    }

    final DateTime next = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      if (isStart) {
        _startsAt = next;
      } else {
        _endsAt = next;
      }
    });
  }

  void _onCodeChanged(int index, String value) {
    final String normalized = value.toUpperCase();
    if (value != normalized) {
      _codeControllers[index].value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    if (normalized.isNotEmpty && index < _codeFocusNodes.length - 1) {
      _codeFocusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _saveCampaign() async {
    if (_isSaving) {
      return;
    }
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    if (_startsAt == null || _endsAt == null) {
      _showEditorError('Başlangıç ve bitiş tarihini seçin.');
      return;
    }
    if (!_endsAt!.isAfter(_startsAt!)) {
      _showEditorError('Bitiş tarihi başlangıç tarihinden sonra olmalı.');
      return;
    }
    final int? stockLimit = _parseOptionalPositiveInt(
      _stockLimitController.text,
    );
    if (_stockLimitController.text.trim().isNotEmpty && stockLimit == null) {
      _showEditorError('Stok limiti pozitif sayı olmalı.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final SpetoVendorCampaign? campaign = widget.campaign;
      if (campaign == null) {
        await widget.controller.createCampaign(
          kind: widget.defaultKind,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startsAt: _startsAt!.toIso8601String(),
          endsAt: _endsAt!.toIso8601String(),
          stockLimit: stockLimit,
          imageUrl: _imageUrlController.text.trim(),
          badgeLabel: _campaignCode,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        await widget.controller.updateCampaign(
          campaignId: campaign.id,
          kind: campaign.kind,
          status: campaign.status,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startsAt: _startsAt!.toIso8601String(),
          endsAt: _endsAt!.toIso8601String(),
          stockLimit: stockLimit,
          imageUrl: _imageUrlController.text.trim(),
          badgeLabel: campaign.badgeLabel,
          discountPercent: campaign.discountPercent > 0
              ? campaign.discountPercent
              : null,
          discountedPrice: campaign.discountedPrice > 0
              ? campaign.discountedPrice
              : null,
          buyQuantity: campaign.buyQuantity > 0 ? campaign.buyQuantity : null,
          payQuantity: campaign.payQuantity > 0 ? campaign.payQuantity : null,
          productIds: campaign.productIds,
        );
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      }
    } catch (error) {
      if (mounted) {
        _showEditorError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zorunlu alan.';
    }
    return null;
  }

  String get _campaignCode {
    return _codeControllers
        .map((TextEditingController controller) => controller.text.trim())
        .where((String value) => value.isNotEmpty)
        .join()
        .toUpperCase();
  }

  void _showEditorError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CampaignEditorHeader extends StatelessWidget {
  const _CampaignEditorHeader({
    required this.title,
    required this.isEdit,
    required this.isSaving,
    required this.onBack,
    required this.onSave,
  });

  final String title;
  final bool isEdit;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isEdit ? 16 : 24),
      color: isEdit
          ? AppColors.surfaceContainerLow
          : AppColors.surface.withValues(alpha: 0.8),
      child: Row(
        children: <Widget>[
          _CampaignHeaderIconButton(
            icon: Icons.arrow_back_rounded,
            color: AppColors.primary,
            onTap: onBack,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isEdit ? 16 : 0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 28 / 18,
                  color: isEdit ? AppColors.onSurface : AppColors.primary,
                ),
              ),
            ),
          ),
          _CampaignHeaderIconButton(
            icon: Icons.check_rounded,
            color: AppColors.primary,
            isLoading: isSaving,
            onTap: isSaving ? null : onSave,
          ),
        ],
      ),
    );

    if (isEdit) {
      return content;
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: content,
      ),
    );
  }
}

class _CampaignHeaderIconButton extends StatelessWidget {
  const _CampaignHeaderIconButton({
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 18,
        onPressed: onTap,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _CampaignFieldLabel extends StatelessWidget {
  const _CampaignFieldLabel({required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 21 / 14,
          color: AppColors.onSurface,
        ),
        children: <InlineSpan>[
          TextSpan(text: label),
          if (isRequired) ...<InlineSpan>[
            const TextSpan(text: ' '),
            TextSpan(
              text: '*',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 21 / 14,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CampaignGradientButton extends StatelessWidget {
  const _CampaignGradientButton({
    required this.label,
    required this.icon,
    required this.height,
    required this.borderRadius,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.9, -1),
          end: Alignment(0.9, 1),
          colors: <Color>[AppColors.primary, AppColors.success],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: height > 56 ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    height: height > 56 ? 28 / 18 : 24 / 16,
                    color: Colors.white,
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

class _CampaignImagePreview extends StatelessWidget {
  const _CampaignImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 168,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border.all(
            color: _CampaignEditorScreenState._createInputColor.withValues(
              alpha: 0.5,
            ),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) => const _CampaignPreviewFallback(),
              )
            else
              const _CampaignPreviewFallback(),
            Positioned.fill(
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Text(
                      'Önizleme',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignPreviewFallback extends StatelessWidget {
  const _CampaignPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFF5F6F7), Color(0xFFE7E8E9)],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 210,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned(
                top: 29,
                child: Transform.rotate(
                  angle: 0.04,
                  child: Container(
                    width: 180,
                    height: 38,
                    decoration: const BoxDecoration(color: Color(0xFF69BED0)),
                  ),
                ),
              ),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFF96D8DE), Color(0xFF4E9AA8)],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
              ),
              Text(
                'SANA ÖZEL\nFIRSAT',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime? _parseCampaignOrderTime(SpetoOpsOrder order) {
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

DateTime? _parseCampaignEditorDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}

String _formatCampaignEditorDate(DateTime value) {
  final int hour = value.hour;
  final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final String suffix = hour >= 12 ? 'PM' : 'AM';
  return '${_twoDigits(value.month)} / ${_twoDigits(value.day)} / '
      '${value.year}, ${_twoDigits(displayHour)}:${_twoDigits(value.minute)} '
      '$suffix';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

int? _parseOptionalPositiveInt(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  final int? parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

DateTime? _parseInventoryDate(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

class _CampaignsSalesModel {
  const _CampaignsSalesModel({
    required this.labels,
    required this.values,
    required this.selectedIndex,
    required this.selectedAmount,
  });

  final List<String> labels;
  final List<double> values;
  final int selectedIndex;
  final double selectedAmount;
}

enum _CampaignsHighlightStyle { warningChip, dangerChip, link }

class _CampaignsInventoryHighlight {
  const _CampaignsInventoryHighlight({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.style,
    required this.trailingLabel,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final _CampaignsHighlightStyle style;
  final String trailingLabel;
}

class _OtherBusinessCampaignPerformance {
  const _OtherBusinessCampaignPerformance({
    required this.labels,
    required this.barHeights,
    required this.highlightIndex,
    required this.weeklyRevenue,
    required this.trendPercent,
    required this.isTrendPositive,
  });

  final List<String> labels;
  final List<double> barHeights;
  final int highlightIndex;
  final double weeklyRevenue;
  final double trendPercent;
  final bool isTrendPositive;
}

class _OtherBusinessFeatureCampaignData {
  const _OtherBusinessFeatureCampaignData({
    required this.tag,
    required this.title,
    required this.description,
    required this.defaultKind,
  });

  final String tag;
  final String title;
  final String description;
  final SpetoCampaignKind defaultKind;
}

class _OtherBusinessActiveCampaignData {
  const _OtherBusinessActiveCampaignData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.remainingLabel,
    this.campaign,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final String remainingLabel;
  final SpetoVendorCampaign? campaign;
}

class _OtherBusinessPastCampaignData {
  const _OtherBusinessPastCampaignData({
    required this.title,
    required this.periodLabel,
    required this.trailingLabel,
    this.campaign,
  });

  final String title;
  final String periodLabel;
  final String trailingLabel;
  final SpetoVendorCampaign? campaign;
}

_CampaignsSalesModel _buildChartModel(List<SpetoOpsOrder> orders) {
  const List<String> labels = <String>[
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
  final List<int> counts = List<int>.filled(labels.length, 0);
  final List<double> revenues = List<double>.filled(labels.length, 0);
  final DateTime now = DateTime.now();

  for (final SpetoOpsOrder order in orders) {
    final DateTime? placedAt = _parseCampaignOrderTime(order);
    if (placedAt == null) {
      continue;
    }
    if (placedAt.year != now.year ||
        placedAt.month != now.month ||
        placedAt.day != now.day) {
      continue;
    }
    final int hour = placedAt.hour;
    if (hour < 9 || hour > 17) {
      continue;
    }
    final int index = hour - 9;
    counts[index] += 1;
    revenues[index] += order.payableTotal;
  }

  final bool hasData = counts.any((int value) => value > 0);
  if (!hasData) {
    return const _CampaignsSalesModel(
      labels: labels,
      values: <double>[1.4, 2.3, 3.8, 5.1, 6.2, 4.5, 5.4, 4.0, 6.6],
      selectedIndex: 6,
      selectedAmount: 482,
    );
  }

  final int maxCount = counts.reduce(math.max);
  final List<double> normalized = counts
      .map<double>(
        (int value) => value == 0
            ? 0.0
            : math.max(1, ((value / maxCount) * 6.6) + 1.2).toDouble(),
      )
      .toList(growable: false);
  final int selectedIndex = math.min(6, normalized.length - 1);
  final double selectedAmount = revenues[selectedIndex] > 0
      ? revenues[selectedIndex]
      : orders.isNotEmpty
      ? orders.first.payableTotal
      : 482;

  return _CampaignsSalesModel(
    labels: labels,
    values: normalized,
    selectedIndex: selectedIndex,
    selectedAmount: selectedAmount,
  );
}

_OtherBusinessCampaignPerformance _buildOtherBusinessCampaignPerformance(
  List<SpetoOpsOrder> orders,
) {
  const List<String> labels = <String>[
    'PZT',
    'SAL',
    'ÇAR',
    'PER',
    'CUM',
    'CMT',
    'PAZ',
  ];
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime weekStart = today.subtract(Duration(days: today.weekday - 1));
  final DateTime nextWeekStart = weekStart.add(const Duration(days: 7));
  final DateTime previousWeekStart = weekStart.subtract(
    const Duration(days: 7),
  );
  final List<double> weeklyRevenue = List<double>.filled(labels.length, 0);
  double previousWeekRevenue = 0;

  for (final SpetoOpsOrder order in orders) {
    final DateTime? placedAt = _parseCampaignOrderTime(order);
    if (placedAt == null) {
      continue;
    }
    final DateTime orderDay = DateTime(
      placedAt.year,
      placedAt.month,
      placedAt.day,
    );

    if (!orderDay.isBefore(weekStart) && orderDay.isBefore(nextWeekStart)) {
      final int index = orderDay.difference(weekStart).inDays;
      if (index >= 0 && index < weeklyRevenue.length) {
        weeklyRevenue[index] += order.payableTotal;
      }
    } else if (!orderDay.isBefore(previousWeekStart) &&
        orderDay.isBefore(weekStart)) {
      previousWeekRevenue += order.payableTotal;
    }
  }

  if (weeklyRevenue.every((double value) => value <= 0)) {
    return const _OtherBusinessCampaignPerformance(
      labels: labels,
      barHeights: <double>[85.33, 64, 96, 128, 106.66, 85.33, 64],
      highlightIndex: 3,
      weeklyRevenue: 14250,
      trendPercent: 12.4,
      isTrendPositive: true,
    );
  }

  final double maxRevenue = weeklyRevenue.reduce(math.max);
  final double weeklyTotal = weeklyRevenue.fold(
    0,
    (double total, double value) => total + value,
  );
  final List<double> barHeights = weeklyRevenue
      .map((double value) {
        if (value <= 0 || maxRevenue <= 0) {
          return 64.0;
        }
        final double normalized = value / maxRevenue;
        return 64 + (normalized * 64);
      })
      .toList(growable: false);
  final int highlightIndex = weeklyRevenue.indexOf(maxRevenue);
  final double rawTrend = previousWeekRevenue <= 0
      ? 12.4
      : ((weeklyTotal - previousWeekRevenue) / previousWeekRevenue) * 100;

  return _OtherBusinessCampaignPerformance(
    labels: labels,
    barHeights: barHeights,
    highlightIndex: highlightIndex < 0 ? 3 : highlightIndex,
    weeklyRevenue: weeklyTotal,
    trendPercent: rawTrend.abs(),
    isTrendPositive: rawTrend >= 0,
  );
}

_OtherBusinessFeatureCampaignData _buildOtherBusinessFeatureCampaign(
  SpetoVendorCampaignSummary? summary,
) {
  final List<SpetoVendorCampaign> campaigns =
      summary?.campaigns ?? const <SpetoVendorCampaign>[];
  SpetoVendorCampaign? featuredCampaign;
  for (final SpetoVendorCampaign campaign in campaigns) {
    if (campaign.status == SpetoCampaignStatus.active) {
      featuredCampaign = campaign;
      break;
    }
  }

  if (featuredCampaign == null) {
    return const _OtherBusinessFeatureCampaignData(
      tag: 'ÖZEL FIRSAT',
      title: 'Happy Hour',
      description:
          'Müşteriler uygulama üzerinden bir kod alır ve ödeme sırasında %30 '
          'indirim kazanır. Satışları uçurma zamanı!',
      defaultKind: SpetoCampaignKind.happyHour,
    );
  }

  return _OtherBusinessFeatureCampaignData(
    tag: 'ÖZEL FIRSAT',
    title: featuredCampaign.title.trim().isEmpty
        ? 'Happy Hour'
        : featuredCampaign.title.trim(),
    description: featuredCampaign.description.trim().isEmpty
        ? 'Müşteriler uygulama üzerinden bir kod alır ve ödeme sırasında '
              '%30 indirim kazanır. Satışları uçurma zamanı!'
        : featuredCampaign.description.trim(),
    defaultKind: featuredCampaign.kind,
  );
}

List<_OtherBusinessActiveCampaignData> _buildOtherBusinessActiveCampaigns(
  SpetoVendorCampaignSummary? summary,
) {
  final List<SpetoVendorCampaign> activeCampaigns =
      (summary?.campaigns ?? const <SpetoVendorCampaign>[])
          .where((SpetoVendorCampaign campaign) {
            return campaign.status == SpetoCampaignStatus.active;
          })
          .take(2)
          .toList(growable: false);

  if (activeCampaigns.isEmpty) {
    return const <_OtherBusinessActiveCampaignData>[
      _OtherBusinessActiveCampaignData(
        icon: Icons.bakery_dining_rounded,
        title: 'Taze Kruvasan Saati',
        subtitle: 'Tüm kruvasanlarda %20 İndirim',
        statusLabel: 'Aktif',
        remainingLabel: '24s kaldı',
      ),
      _OtherBusinessActiveCampaignData(
        icon: Icons.local_cafe_rounded,
        title: 'Öğleden Sonra Kahvesi',
        subtitle: 'Latte ve Cold Brew 3 Al 2 Öde',
        statusLabel: 'Aktif',
        remainingLabel: '3 gün kaldı',
      ),
    ];
  }

  return activeCampaigns
      .map(
        (SpetoVendorCampaign campaign) => _OtherBusinessActiveCampaignData(
          icon: _campaignIconForOtherBusiness(campaign),
          title: campaign.title.trim().isEmpty
              ? 'Aktif Kampanya'
              : campaign.title.trim(),
          subtitle: campaign.description.trim().isEmpty
              ? _campaignSubtitleFallback(campaign)
              : campaign.description.trim(),
          statusLabel: 'Aktif',
          remainingLabel: _campaignRemainingLabel(campaign),
          campaign: campaign,
        ),
      )
      .toList(growable: false);
}

List<_OtherBusinessPastCampaignData> _buildOtherBusinessPastCampaigns(
  SpetoVendorCampaignSummary? summary,
) {
  final List<SpetoVendorCampaign> pastCampaigns =
      (summary?.campaigns ?? const <SpetoVendorCampaign>[])
          .where((SpetoVendorCampaign campaign) {
            return campaign.status != SpetoCampaignStatus.active;
          })
          .take(2)
          .toList(growable: false);

  if (pastCampaigns.isEmpty) {
    return const <_OtherBusinessPastCampaignData>[
      _OtherBusinessPastCampaignData(
        title: 'Artisan Kek Günleri',
        periodLabel: 'Ocak 2024',
        trailingLabel: '₺8.400 Satış',
      ),
      _OtherBusinessPastCampaignData(
        title: 'Sonbahar Espresso Fırsatı',
        periodLabel: 'Eylül 2023',
        trailingLabel: '₺12.150 Satış',
      ),
    ];
  }

  return pastCampaigns
      .map(
        (SpetoVendorCampaign campaign) => _OtherBusinessPastCampaignData(
          title: campaign.title.trim().isEmpty
              ? 'Geçmiş Kampanya'
              : campaign.title.trim(),
          periodLabel: _campaignPeriodLabel(campaign),
          trailingLabel: _pastCampaignTrailingLabel(campaign),
          campaign: campaign,
        ),
      )
      .toList(growable: false);
}

List<_CampaignsInventoryHighlight> _buildInventoryHighlights(
  StockAppController controller,
) {
  final Map<String, SpetoCatalogProduct> productsById =
      <String, SpetoCatalogProduct>{
        for (final SpetoCatalogProduct product in controller.products)
          product.id: product,
      };

  final List<_CampaignsInventoryCandidate> dynamicItems =
      controller.inventoryItems
          .map((SpetoInventoryItem item) {
            final SpetoCatalogProduct? product = productsById[item.id];
            final DateTime? expiryDate = _parseInventoryDate(
              product?.expiryDate ?? item.expiryDate,
            );
            final int quantity = math.max(0, item.availableQuantity);
            final String unitType = item.unitType.trim().isEmpty
                ? 'adet'
                : item.unitType.trim();
            final String subtitle = '$quantity $unitType';
            final bool expiresToday =
                expiryDate != null &&
                expiryDate.year == DateTime.now().year &&
                expiryDate.month == DateTime.now().month &&
                expiryDate.day == DateTime.now().day;
            final bool expiresSoon =
                expiryDate != null &&
                expiryDate.difference(DateTime.now()).inDays <= 3 &&
                !expiresToday;
            final _CampaignsHighlightStyle style = expiresToday
                ? _CampaignsHighlightStyle.warningChip
                : item.stockStatus.lowStock || !item.stockStatus.isInStock
                ? _CampaignsHighlightStyle.dangerChip
                : _CampaignsHighlightStyle.link;
            final String trailingLabel = expiresToday
                ? 'BUGÜN SKT'
                : style == _CampaignsHighlightStyle.dangerChip
                ? 'STOKTA AZALMA'
                : expiresSoon
                ? 'İndirime Ekle'
                : 'İndirime Ekle';
            return _CampaignsInventoryCandidate(
              highlight: _CampaignsInventoryHighlight(
                title: item.title,
                subtitle: subtitle,
                imageUrl: item.imageUrl.isNotEmpty
                    ? item.imageUrl
                    : (product?.imageUrl.isNotEmpty == true
                          ? product!.imageUrl
                          : product?.image ?? ''),
                style: style,
                trailingLabel: trailingLabel,
              ),
              score: expiresToday
                  ? 100
                  : style == _CampaignsHighlightStyle.dangerChip
                  ? 60
                  : expiresSoon
                  ? 80
                  : 40,
            );
          })
          .toList(growable: false)
        ..sort(
          (
            _CampaignsInventoryCandidate first,
            _CampaignsInventoryCandidate second,
          ) => second.score.compareTo(first.score),
        );

  if (dynamicItems.isNotEmpty) {
    return dynamicItems
        .take(3)
        .map((_CampaignsInventoryCandidate candidate) => candidate.highlight)
        .toList(growable: false);
  }

  return const <_CampaignsInventoryHighlight>[
    _CampaignsInventoryHighlight(
      title: 'Burger Köftesi',
      subtitle: '4 paket',
      imageUrl: '',
      style: _CampaignsHighlightStyle.warningChip,
      trailingLabel: 'BUGÜN SKT',
    ),
    _CampaignsInventoryHighlight(
      title: 'Mozzarella',
      subtitle: '2 paket',
      imageUrl: '',
      style: _CampaignsHighlightStyle.link,
      trailingLabel: 'İndirime Ekle',
    ),
    _CampaignsInventoryHighlight(
      title: 'Kola',
      subtitle: '3 adet',
      imageUrl: '',
      style: _CampaignsHighlightStyle.dangerChip,
      trailingLabel: 'STOKTA AZALMA',
    ),
  ];
}

IconData _campaignIconForOtherBusiness(SpetoVendorCampaign campaign) {
  return switch (campaign.kind) {
    SpetoCampaignKind.bundle => Icons.inventory_2_rounded,
    SpetoCampaignKind.clearance => Icons.sell_rounded,
    SpetoCampaignKind.discount => Icons.percent_rounded,
    SpetoCampaignKind.happyHour => Icons.local_cafe_rounded,
  };
}

String _campaignSubtitleFallback(SpetoVendorCampaign campaign) {
  if (campaign.badgeLabel.trim().isNotEmpty) {
    return campaign.badgeLabel.trim();
  }
  return switch (campaign.kind) {
    SpetoCampaignKind.bundle => 'Seçili ürünlerde paket kampanyası',
    SpetoCampaignKind.clearance => 'Sabit fiyat fırsatı',
    SpetoCampaignKind.discount => 'Seçili ürünlerde indirim kampanyası',
    SpetoCampaignKind.happyHour => 'Yoğun saatlere özel fırsat',
  };
}

String _campaignRemainingLabel(SpetoVendorCampaign campaign) {
  if (campaign.endsAt.trim().isNotEmpty) {
    final DateTime? endsAt = DateTime.tryParse(campaign.endsAt);
    if (endsAt != null) {
      final Duration difference = endsAt.difference(DateTime.now());
      if (!difference.isNegative) {
        final int hours = difference.inHours;
        if (hours < 24) {
          return '${math.max(hours, 1)}s kaldı';
        }
        return '${difference.inDays} gün kaldı';
      }
    }
  }
  if (campaign.scheduleLabel.trim().isNotEmpty) {
    return campaign.scheduleLabel.trim();
  }
  return 'Süre aktif';
}

String _campaignPeriodLabel(SpetoVendorCampaign campaign) {
  final DateTime? referenceDate = DateTime.tryParse(
    campaign.endsAt.trim().isEmpty ? campaign.startsAt : campaign.endsAt,
  );
  if (referenceDate == null) {
    return campaign.scheduleLabel.trim().isEmpty
        ? 'Kampanya Tamamlandı'
        : campaign.scheduleLabel.trim();
  }

  const List<String> months = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  return '${months[referenceDate.month - 1]} ${referenceDate.year}';
}

String _pastCampaignTrailingLabel(SpetoVendorCampaign campaign) {
  if (campaign.discountedPrice > 0 && campaign.stockLimit > 0) {
    final double projectedSales =
        campaign.discountedPrice * campaign.stockLimit.toDouble();
    return '${_formatCurrency(projectedSales)} Satış';
  }
  if (campaign.badgeLabel.trim().isNotEmpty) {
    return campaign.badgeLabel.trim();
  }
  return 'Tamamlandı';
}

class _OtherBusinessCampaignsTopBar extends StatelessWidget {
  const _OtherBusinessCampaignsTopBar({
    required this.isLoading,
    required this.onRefresh,
  });

  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'Kampanyalar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 28 / 18,
              color: AppColors.primary,
            ),
          ),
          SizedBox(
            width: 32,
            height: 36,
            child: IconButton(
              onPressed: isLoading ? null : onRefresh,
              padding: EdgeInsets.zero,
              splashRadius: 18,
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherBusinessCampaignSection extends StatelessWidget {
  const _OtherBusinessCampaignSection({
    required this.title,
    required this.children,
    required this.spacing,
  });

  final String title;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 28 / 18,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        for (int index = 0; index < children.length; index++) ...<Widget>[
          children[index],
          if (index != children.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class _OtherBusinessCampaignPerformanceCard extends StatelessWidget {
  const _OtherBusinessCampaignPerformanceCard({required this.model});

  final _OtherBusinessCampaignPerformance model;

  @override
  Widget build(BuildContext context) {
    final Color trendTextColor = model.isTrendPositive
        ? AppColors.primary
        : AppColors.error;
    final Color trendBackgroundColor = model.isTrendPositive
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.red50;
    final IconData trendIcon = model.isTrendPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1ABBCBBB)),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Haftalık Kampanya Etkisi',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(model.weeklyRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 32 / 24,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trendBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(trendIcon, size: 14, color: trendTextColor),
                    const SizedBox(width: 4),
                    Text(
                      '%${model.trendPercent.toStringAsFixed(1)}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                        color: trendTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OtherBusinessCampaignBarChart(model: model),
        ],
      ),
    );
  }
}

class _OtherBusinessCampaignBarChart extends StatelessWidget {
  const _OtherBusinessCampaignBarChart({required this.model});

  final _OtherBusinessCampaignPerformance model;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int index = 0; index < model.barHeights.length; index++)
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: model.barHeights[index]
                          .clamp(36.0, 128.0)
                          .toDouble(),
                      decoration: BoxDecoration(
                        color: _campaignBarColorForIndex(
                          index,
                          model.highlightIndex,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: model.labels
              .map(
                (String label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 15 / 10,
                      letterSpacing: 0.5,
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _OtherBusinessFeatureCampaignCard extends StatelessWidget {
  const _OtherBusinessFeatureCampaignCard({
    required this.data,
    required this.onTap,
  });

  final _OtherBusinessFeatureCampaignData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 50,
            offset: const Offset(0, 25),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            right: -48,
            bottom: -48,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -16,
            right: -8,
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.tag,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 36 / 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  data.description,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 22.75 / 14,
                    color: const Color(0xFF6BFE9C),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                          spreadRadius: -3,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Kampanya Başlat',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 24 / 16,
                            color: const Color(0xFF005027),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF005027),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtherBusinessActiveCampaignCard extends StatelessWidget {
  const _OtherBusinessActiveCampaignCard({required this.data, this.onTap});

  final _OtherBusinessActiveCampaignData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  data.icon,
                  size: 22,
                  color: const Color(0xFF005027),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 3.5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Kampanya Detayı',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 15 / 10,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 12,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    data.statusLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    data.remainingLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 15 / 10,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherBusinessPastCampaignCard extends StatelessWidget {
  const _OtherBusinessPastCampaignCard({required this.data, this.onTap});

  final _OtherBusinessPastCampaignData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3.5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Kampanya Detayı',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 15 / 10,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 12,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        data.periodLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  data.trailingLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    color: AppColors.onSurface,
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

Color _campaignBarColorForIndex(int index, int highlightIndex) {
  if (index == highlightIndex) {
    return AppColors.success;
  }
  if (index == highlightIndex - 1) {
    return AppColors.success.withValues(alpha: 0.4);
  }
  if (index == highlightIndex + 1) {
    return AppColors.success.withValues(alpha: 0.6);
  }
  return AppColors.surfaceContainerHigh;
}

class _CampaignsTopBar extends StatelessWidget {
  const _CampaignsTopBar({required this.isLoading, required this.onRefresh});

  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, topInset + 15, 24, 15),
          decoration: BoxDecoration(
            color: const Color(0xCCF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
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
                    size: 17,
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

class _CampaignsSalesCard extends StatelessWidget {
  const _CampaignsSalesCard({required this.model});

  final _CampaignsSalesModel model;

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
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEEEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const <Widget>[
                    _CampaignsRangeChip(label: 'Gün', selected: true),
                    _CampaignsRangeChip(label: 'Hafta'),
                    _CampaignsRangeChip(label: 'Ay'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CampaignsChart(model: model),
        ],
      ),
    );
  }
}

class _CampaignsRangeChip extends StatelessWidget {
  const _CampaignsRangeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
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
    );
  }
}

class _CampaignsChart extends StatelessWidget {
  const _CampaignsChart({required this.model});

  final _CampaignsSalesModel model;

  @override
  Widget build(BuildContext context) {
    const List<String> yAxis = <String>['8', '6', '4', '2', '0'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 10,
          height: 192,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: yAxis
                  .map(
                    (String value) => Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: AppColors.bodyText,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 192,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double plotHeight = 168;
                final double maxValue = model.values.reduce(math.max);
                final double selectedX =
                    (constraints.maxWidth / (model.values.length - 1)) *
                    model.selectedIndex;
                final double selectedY =
                    plotHeight -
                    ((model.values[model.selectedIndex] / maxValue) *
                        plotHeight);

                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      bottom: 24,
                      child: CustomPaint(
                        painter: _CampaignsChartPainter(values: model.values),
                      ),
                    ),
                    Positioned(
                      left: math.max(
                        0,
                        math.min(constraints.maxWidth - 48, selectedX - 20),
                      ),
                      top: math.max(0, selectedY - 28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatCurrency(model.selectedAmount),
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: math.max(0, selectedX - 4),
                      top: math.max(0, selectedY - 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.success,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: model.labels
                            .map(
                              (String label) => Text(
                                label,
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  color: AppColors.bodyText,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CampaignsChartPainter extends CustomPainter {
  const _CampaignsChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final double maxValue = values.reduce(math.max);
    final Paint dividerPaint = Paint()
      ..color = const Color(0xFFEDEEEF)
      ..strokeWidth = 1;

    for (int index = 0; index < 4; index++) {
      final double y = (size.height / 4) * index;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dividerPaint);
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = AppColors.onSurface.withValues(alpha: 0.1)
        ..strokeWidth = 1,
    );

    final List<Offset> points = <Offset>[
      for (int index = 0; index < values.length; index++)
        Offset(
          (size.width / (values.length - 1)) * index,
          size.height - ((values[index] / maxValue) * size.height),
        ),
    ];

    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 0; index < points.length - 1; index++) {
      final Offset current = points[index];
      final Offset next = points[index + 1];
      final double controlX = (current.dx + next.dx) / 2;
      linePath.quadraticBezierTo(controlX, current.dy, next.dx, next.dy);
    }

    final Path fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x662ECC71), Color(0x112ECC71)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.success
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CampaignsChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _CampaignsSectionHeader extends StatelessWidget {
  const _CampaignsSectionHeader({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

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
          Text(
            actionLabel!,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.33,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

class _CampaignsExpiringProductsCard extends StatelessWidget {
  const _CampaignsExpiringProductsCard({required this.items});

  final List<_CampaignsInventoryHighlight> items;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: <Widget>[
            for (int index = 0; index < items.length; index++) ...<Widget>[
              _CampaignsExpiringProductRow(item: items[index]),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFFEDEEEF),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CampaignsExpiringProductRow extends StatelessWidget {
  const _CampaignsExpiringProductRow({required this.item});

  final _CampaignsInventoryHighlight item;

  @override
  Widget build(BuildContext context) {
    final bool useChip = item.style != _CampaignsHighlightStyle.link;
    final Color textColor = switch (item.style) {
      _CampaignsHighlightStyle.warningChip => const Color(0xFFC2410C),
      _CampaignsHighlightStyle.dangerChip => const Color(0xFFB91C1C),
      _CampaignsHighlightStyle.link => AppColors.primary,
    };
    final Color backgroundColor = switch (item.style) {
      _CampaignsHighlightStyle.warningChip => AppColors.orange100,
      _CampaignsHighlightStyle.dangerChip => const Color(0xFFFEE2E2),
      _CampaignsHighlightStyle.link => Colors.transparent,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: <Widget>[
          _CampaignsProductThumbnail(
            imageUrl: item.imageUrl,
            title: item.title,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
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
          if (useChip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.trailingLabel,
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            )
          else
            Text(
              item.trailingLabel,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _CampaignsProductThumbnail extends StatelessWidget {
  const _CampaignsProductThumbnail({
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      color: AppColors.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(
        title.toLowerCase().contains('kola')
            ? Icons.local_drink_outlined
            : Icons.inventory_2_outlined,
        color: AppColors.slate600,
        size: 18,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: imageUrl.trim().isEmpty
            ? fallback
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return fallback;
                    },
              ),
      ),
    );
  }
}

class _CampaignsQuickActionButton extends StatelessWidget {
  const _CampaignsQuickActionButton({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
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
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: AppColors.brandGreen),
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
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.bodyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignsInlineNotice extends StatelessWidget {
  const _CampaignsInlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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

class _CampaignsInventoryCandidate {
  const _CampaignsInventoryCandidate({
    required this.highlight,
    required this.score,
  });

  final _CampaignsInventoryHighlight highlight;
  final int score;
}

String _formatCurrency(double value) {
  final String amount = value.toStringAsFixed(2).replaceAll('.', ',');
  return '₺$amount';
}
