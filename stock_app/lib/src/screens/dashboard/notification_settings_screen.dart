import 'package:flutter/material.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _initialized = false;
  bool _saving = false;
  late StockNotificationSettings _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _settings = StockAppScope.of(context).notificationSettings;
    _initialized = true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
    });
    try {
      await StockAppScope.of(context).updateNotificationSettings(_settings);
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const _ScreenHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 672),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const _EditorialHeader(),
                          const SizedBox(height: 32),
                          _PreferenceSection(
                            title: 'SIPARIŞ YÖNETİMİ',
                            children: <Widget>[
                              _NotificationPreferenceTile(
                                title: 'Yeni Sipariş',
                                subtitle:
                                    'Yeni bir sipariş geldiğinde anlık\nbildirim al.',
                                icon: Icons.shopping_cart_outlined,
                                iconColor: AppColors.primary,
                                iconBackground: AppColors.success.withValues(
                                  alpha: 0.10,
                                ),
                                value: _settings.newOrders,
                                onChanged: (bool value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      newOrders: value,
                                    );
                                  });
                                },
                              ),
                              _NotificationPreferenceTile(
                                title: 'İptal Sipariş',
                                subtitle:
                                    'Müşteri siparişi iptal ettiğinde\nbilgilendir.',
                                icon: Icons.cancel_outlined,
                                iconColor: const Color(0xFFE52421),
                                iconBackground: const Color(0x1AFFDAD6),
                                value: _settings.cancelledOrders,
                                onChanged: (bool value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      cancelledOrders: value,
                                    );
                                  });
                                },
                              ),
                              _NotificationPreferenceTile(
                                title: 'Hazır Sipariş',
                                subtitle: 'Gel - Al hazır sipariş uyarıları.',
                                icon: Icons.check_circle_outline_rounded,
                                iconColor: const Color(0xFF5875B2),
                                iconBackground: const Color(0x33A8BCFE),
                                value: _settings.readyOrders,
                                onChanged: (bool value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      readyOrders: value,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _PreferenceSection(
                            title: 'ENVANTER & FIRSATLAR',
                            children: <Widget>[
                              _NotificationPreferenceTile(
                                title: 'Kampanyalar',
                                subtitle: 'Yeni kampanya ve indirim dönemleri.',
                                icon: Icons.campaign_outlined,
                                iconColor: const Color(0xFFB65E3C),
                                iconBackground: const Color(0x33FF9875),
                                value: _settings.campaigns,
                                onChanged: (bool value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      campaigns: value,
                                    );
                                  });
                                },
                              ),
                              _NotificationPreferenceTile(
                                title: 'SKT Uyarıları',
                                subtitle:
                                    'Son kullanma tarihi yaklaşan ürünler.',
                                icon: Icons.history_toggle_off_rounded,
                                iconColor: const Color(0xFFE52421),
                                iconBackground: const Color(0x1AFFDAD6),
                                value: _settings.expiryAlerts,
                                onChanged: (bool value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      expiryAlerts: value,
                                    );
                                  });
                                },
                              ),
                              _NotificationPreferenceTile(
                                title: 'Happy Hour',
                                subtitle:
                                    'Mağazanızın yoğun olduğu saat\nhatırlatmaları.',
                                icon: Icons.auto_awesome_outlined,
                                iconColor: AppColors.primary,
                                iconBackground: AppColors.success.withValues(
                                  alpha: 0.10,
                                ),
                                value: _settings.happyHour,
                                onChanged: (bool value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      happyHour: value,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          Center(
                            child: _NotificationSaveButton(
                              isLoading: _saving,
                              onTap: _saving ? null : _save,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: <Widget>[
          _HeaderBackButton(onTap: () => Navigator.pop(context)),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Bildirim Tercihleri',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 36 / 30,
            letterSpacing: -0.75,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 6.875),
        Text(
          'Mağaza operasyonlarınızla ilgili anlık güncellemeleri\nnasıl almak istediğinizi belirleyin.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 22.75 / 14,
            color: AppColors.bodyText,
          ),
        ),
      ],
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 16 / 12,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _NotificationPreferenceTile extends StatelessWidget {
  const _NotificationPreferenceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 24 / 16,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _NotificationSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.success : const Color(0xFFE1E3E4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: value ? Colors.white : const Color(0xFFD1D5DB),
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

class _NotificationSaveButton extends StatelessWidget {
  const _NotificationSaveButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment(-0.95, -0.16),
          end: Alignment(1, 0.16),
          colors: <Color>[AppColors.primary, AppColors.success],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.30),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (isLoading)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.save_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                const SizedBox(width: 8),
                const Text(
                  'Kaydet',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
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
