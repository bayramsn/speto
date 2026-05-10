import 'package:flutter/material.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  static const String _coverAssetPath = 'assets/profile/profile_cover.png';
  static const String _avatarPlaceholderPath =
      'assets/profile/profile_avatar_placeholder.png';

  late final TextEditingController _businessNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _pickupLabelController;
  late final TextEditingController _pickupAddressController;
  late final TextEditingController _hoursController;
  late final TextEditingController _imageController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _taxOfficeController;
  late final TextEditingController _descriptionController;

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _subtitleController = TextEditingController();
    _categoryController = TextEditingController();
    _pickupLabelController = TextEditingController();
    _pickupAddressController = TextEditingController();
    _hoursController = TextEditingController();
    _imageController = TextEditingController();
    _taxNumberController = TextEditingController();
    _taxOfficeController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = StockAppScope.of(context);
    final vendor = controller.selectedVendor;
    final profile = controller.userProfile;
    _businessNameController.text = vendor?.title ?? '';
    _displayNameController.text = profile?.displayName ?? '';
    _phoneController.text = profile?.phone ?? '';
    _emailController.text = profile?.email ?? '';
    _subtitleController.text = vendor?.subtitle ?? '';
    _categoryController.text = vendor?.cuisine.isNotEmpty == true
        ? vendor!.cuisine
        : vendor?.meta ?? '';
    _pickupLabelController.text = vendor?.pickupPoints.isNotEmpty == true
        ? vendor!.pickupPoints.first.label
        : '';
    _pickupAddressController.text = vendor?.pickupPoints.isNotEmpty == true
        ? vendor!.pickupPoints.first.address
        : '';
    _hoursController.text = vendor?.workingHoursLabel ?? '';
    _imageController.text = vendor?.image ?? profile?.avatarUrl ?? '';
    _taxNumberController.text = vendor?.taxNumber ?? '';
    _taxOfficeController.text = vendor?.taxOffice ?? '';
    _descriptionController.text = _resolveDescription(controller);
    _notificationsEnabled = profile?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _subtitleController.dispose();
    _categoryController.dispose();
    _pickupLabelController.dispose();
    _pickupAddressController.dispose();
    _hoursController.dispose();
    _imageController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final controller = StockAppScope.of(context);
    await controller.updateBusinessProfile(
      businessName: _businessNameController.text,
      subtitle: _subtitleController.text,
      category: _categoryController.text,
      pickupPointLabel: _pickupLabelController.text,
      pickupPointAddress: _pickupAddressController.text,
      workingHoursLabel: _hoursController.text,
      imageUrl: _imageController.text,
      taxNumber: _taxNumberController.text,
      taxOffice: _taxOfficeController.text,
      announcement: _descriptionController.text,
    );
    await controller.updateOperatorProfile(
      displayName: _displayNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      notificationsEnabled: _notificationsEnabled,
      avatarUrl: _imageController.text,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _editBusinessImage() async {
    final TextEditingController dialogController = TextEditingController(
      text: _imageController.text,
    );
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'İşletme Görseli',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: dialogController,
            decoration: const InputDecoration(
              labelText: 'Logo URL',
              hintText: 'https://...',
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, dialogController.text),
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
    dialogController.dispose();
    if (value == null) {
      return;
    }
    setState(() {
      _imageController.text = value.trim();
    });
  }

  String _resolveDescription(StockAppController controller) {
    final vendor = controller.selectedVendor;
    final List<String> candidates = <String>[
      vendor?.announcement ?? '',
      vendor?.heroSubtitle ?? '',
      vendor?.subtitle ?? '',
      vendor?.meta ?? '',
    ];
    return candidates.firstWhere(
      (String value) => value.trim().isNotEmpty,
      orElse: () => '',
    );
  }

  ImageProvider<Object> _logoProvider() {
    final String imageUrl = _imageController.text.trim();
    if (imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage(_avatarPlaceholderPath);
  }

  @override
  Widget build(BuildContext context) {
    final controller = StockAppScope.of(context);
    final bool isSaving =
        controller.isBusy('profile:update') ||
        controller.isBusy('profile:user');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: <Widget>[
                  _HeaderBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
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
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        _ProfileHeroSection(
                          logoProvider: _logoProvider(),
                          coverAssetPath: _coverAssetPath,
                          onEditCover: _editBusinessImage,
                          onEditLogo: _editBusinessImage,
                        ),
                        const SizedBox(height: 32),
                        _ProfileInputField(
                          label: 'İşletme Adı',
                          controller: _businessNameController,
                        ),
                        const SizedBox(height: 20),
                        _ProfileInputField(
                          label: 'Şube Adı',
                          controller: _pickupLabelController,
                        ),
                        const SizedBox(height: 20),
                        _ProfileInputField(
                          label: 'Telefon',
                          controller: _phoneController,
                          icon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _ProfileInputField(
                          label: 'E-posta',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _ProfileInputField(
                          label: 'Adres',
                          controller: _pickupAddressController,
                          icon: Icons.location_on_outlined,
                          keyboardType: TextInputType.streetAddress,
                          minLines: 2,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        _ProfileInputField(
                          label: 'Vergi No',
                          controller: _taxNumberController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        _ProfileInputField(
                          label: 'Vergi Dairesi',
                          controller: _taxOfficeController,
                        ),
                        const SizedBox(height: 20),
                        _ProfileInputField(
                          label: 'Açıklama',
                          controller: _descriptionController,
                          minLines: 3,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        _SaveButton(
                          isLoading: isSaving,
                          onTap: isSaving ? null : _save,
                        ),
                      ],
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

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          width: 32,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.brandGreen,
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroSection extends StatelessWidget {
  const _ProfileHeroSection({
    required this.logoProvider,
    required this.coverAssetPath,
    required this.onEditCover,
    required this.onEditLogo,
  });

  final ImageProvider<Object> logoProvider;
  final String coverAssetPath;
  final VoidCallback onEditCover;
  final VoidCallback onEditLogo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: AssetImage(coverAssetPath),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: _HeroActionButton(
                size: 48,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                iconColor: AppColors.bodyText,
                icon: Icons.add_photo_alternate_outlined,
                onTap: onEditCover,
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                      image: DecorationImage(
                        image: logoProvider,
                        fit: BoxFit.cover,
                        onError: (_, _) {},
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: _HeroActionButton(
                    size: 36,
                    backgroundColor: AppColors.primary,
                    iconColor: Colors.white,
                    icon: Icons.edit_outlined,
                    onTap: onEditLogo,
                    borderRadius: 12,
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

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.size,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.onTap,
    this.borderRadius = 999,
  });

  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      shadowColor: Colors.black.withValues(alpha: 0.10),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size == 48 ? 22 : 15, color: iconColor),
        ),
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  const _ProfileInputField({
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final bool isMultiline = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
              color: AppColors.bodyText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 24 / 16,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(
                icon == null ? 20 : 48,
                16,
                20,
                isMultiline ? 16 : 16,
              ),
              prefixIcon: icon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(icon, size: 16, color: AppColors.bodyText),
                    ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment(-0.98, -0.20),
          end: Alignment(1, 0.20),
          colors: <Color>[AppColors.primary, AppColors.success],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: SizedBox(
            height: 68,
            width: double.infinity,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 28 / 18,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
