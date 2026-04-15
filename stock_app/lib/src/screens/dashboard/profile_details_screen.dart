import 'package:flutter/material.dart';

import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
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
    super.dispose();
  }

  Future<void> _save() async {
    final controller = StockAppScope.of(context);
    await controller.updateBusinessProfile(
      businessName: _businessNameController.text,
      subtitle: _subtitleController.text,
      category: _categoryController.text,
      pickupPointLabel: _pickupLabelController.text,
      pickupPointAddress: _pickupAddressController.text,
      workingHoursLabel: _hoursController.text,
      imageUrl: _imageController.text,
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

  @override
  Widget build(BuildContext context) {
    final controller = StockAppScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil Bilgileri'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Center(
            child: Stack(
              children: <Widget>[
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.slate100,
                  backgroundImage: _imageController.text.trim().isNotEmpty
                      ? NetworkImage(_imageController.text.trim())
                      : null,
                  child: _imageController.text.trim().isEmpty
                      ? const Icon(
                          Icons.store,
                          size: 40,
                          color: AppColors.slate400,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _imageController,
            decoration: const InputDecoration(
              hintText: 'Logo / avatar URL',
              labelText: 'Görsel URL',
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Yetkili Bilgileri',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _businessNameController,
            decoration: const InputDecoration(labelText: 'İşletme Adı'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(labelText: 'Yetkili Ad Soyad'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Telefon Numarası'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'E-posta Adresi'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(labelText: 'Alt Başlık'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Kategori'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pickupLabelController,
            decoration: const InputDecoration(labelText: 'Teslim Noktası'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pickupAddressController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Adres'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hoursController,
            decoration: const InputDecoration(labelText: 'Çalışma Saatleri'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() => _notificationsEnabled = value);
            },
            title: const Text('Bildirimler açık'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed:
                controller.isBusy('profile:update') ||
                    controller.isBusy('profile:user')
                ? null
                : _save,
            child: const Text('Değişiklikleri Kaydet'),
          ),
        ],
      ),
    );
  }
}
