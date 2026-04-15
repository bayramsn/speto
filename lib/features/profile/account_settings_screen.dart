import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/constants/app_images.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/navigation/navigator.dart';
import '../../core/state/app_state.dart';
import '../../src/core/models.dart';
import '../../shared/widgets/widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _initialized = false;
  bool _notificationsEnabled = true;
  String _selectedAvatarUrl = AppImages.profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final SpetoAppState appState = SpetoAppScope.of(context);
    final SpetoSession? session = appState.session;
    _nameController.text = session?.displayName ?? '';
    _emailController.text = session?.email ?? '';
    _phoneController.text = session?.phone ?? '';
    _selectedAvatarUrl = appState.avatarUrl;
    _notificationsEnabled = appState.notificationsEnabled;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(SpetoAppState appState) async {
    await appState.updateProfile(
      displayName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      avatarUrl: _selectedAvatarUrl,
      notificationsEnabled: _notificationsEnabled,
    );
    if (!mounted) {
      return;
    }
    SpetoToast.show(
      context,
      message: 'Profil bilgileri kalıcı olarak güncellendi.',
      icon: Icons.save_outlined,
    );
  }

  Future<void> _pickAvatar() async {
    final String? avatar = await _showAvatarPickerSheet(
      context,
      currentAvatar: _selectedAvatarUrl,
    );
    if (!mounted || avatar == null) {
      return;
    }
    setState(() => _selectedAvatarUrl = avatar);
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return SpetoScreenScaffold(
      title: 'Hesap Ayarları',
      background: Palette.aubergine,
      showBottomNav: true,
      activeNav: NavSection.profile,
      footer: SafeArea(
        top: false,
        child: Container(
          color: Palette.aubergine,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SpetoPrimaryButton(
                  label: 'Değişiklikleri Kaydet',
                  icon: Icons.save_outlined,
                  onTap: () => _saveProfile(appState),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await appState.signOut();
                  if (!context.mounted) {
                    return;
                  }
                  openRootScreen(context, SpetoScreen.login);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Palette.cardWarm,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Palette.red),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Column(
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Palette.cardWarm,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Palette.cardWarm,
                              width: 4,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(_selectedAvatarUrl),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: Palette.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Palette.aubergine,
                                width: 4,
                              ),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Profil Fotoğrafını Düzenle',
                      style: context.spetoCardTitleStyle(color: Palette.red),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            LabeledField(
              label: 'Ad Soyad',
              icon: Icons.person_outline_rounded,
              controller: _nameController,
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'E-posta',
              icon: Icons.mail_outline_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'Telefon Numarası',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            Text(
              'HIZLI ERİŞİM',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Palette.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SpetoCard(
              radius: 18,
              color: Palette.cardWarm,
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SettingTile(
                    icon: Icons.location_on_outlined,
                    label: 'Adreslerim',
                    onTap: () => openScreen(context, SpetoScreen.addresses),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  SettingTile(
                    icon: Icons.credit_card_rounded,
                    label: 'Ödeme Yöntemleri',
                    onTap: () =>
                        openScreen(context, SpetoScreen.paymentMethods),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  SettingTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Yardım Merkezi',
                    onTap: () => openScreen(context, SpetoScreen.helpCenter),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  SettingTile(
                    icon: Icons.map_outlined,
                    label: 'Uygulama Haritası',
                    onTap: () => openScreen(context, SpetoScreen.appMap),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'GÜVENLİK VE TERCİHLER',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Palette.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SpetoCard(
              radius: 18,
              color: Palette.cardWarm,
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SettingTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Şifre Değiştir',
                    onTap: () => openScreen(context, SpetoScreen.resetPassword),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  SettingTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Karanlık Tema',
                    onTap: () => appState.toggleTheme(),
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (bool _) => appState.toggleTheme(),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  SettingTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Bildirimler',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (bool value) async {
                        setState(() => _notificationsEnabled = value);
                        await appState.setNotificationsEnabled(value);
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final bool shouldDelete = await _showDeleteAccountDialog(
                    context,
                  );
                  if (!shouldDelete || !context.mounted) {
                    return;
                  }
                  await appState.deleteAccount();
                  if (!context.mounted) {
                    return;
                  }
                  openRootScreen(context, SpetoScreen.login);
                },
                child: Text(
                  'Hesabımı Sil',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
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

Future<String?> _showAvatarPickerSheet(
  BuildContext context, {
  String? currentAvatar,
}) async {
  const List<String> avatars = <String>[
    'https://i.pravatar.cc/150?img=1',
    'https://i.pravatar.cc/150?img=2',
    'https://i.pravatar.cc/150?img=3',
    'https://i.pravatar.cc/150?img=4',
    'https://i.pravatar.cc/150?img=5',
    'https://i.pravatar.cc/150?img=6',
    'https://i.pravatar.cc/150?img=7',
    'https://i.pravatar.cc/150?img=8',
  ];
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Palette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Profil Fotoğrafı Seç',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: avatars
                  .map(
                    (String url) => GestureDetector(
                      onTap: () => Navigator.of(context).pop(url),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(url),
                        child: url == currentAvatar
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> _showDeleteAccountDialog(BuildContext context) async {
  final bool? shouldDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Palette.cardWarm,
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Yerel oturum ve kayıtlı profil verileri silinecek. Bu işlem geri alınamaz.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Palette.red),
            child: const Text('Sil'),
          ),
        ],
      );
    },
  );
  return shouldDelete ?? false;
}
