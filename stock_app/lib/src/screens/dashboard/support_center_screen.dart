import 'package:flutter/material.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double horizontalInset = constraints.maxWidth > 816
                ? (constraints.maxWidth - 768) / 2
                : 24;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                16,
                horizontalInset,
                128,
              ),
              children: <Widget>[
                _SupportHeader(onBack: () => Navigator.pop(context)),
                const SizedBox(height: 32),
                const _HeroSection(),
                const SizedBox(height: 32),
                _SupportActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Canlı Destek',
                  description: 'Müşteri temsilcilerimizle anında\nsohbet edin.',
                  ctaLabel: 'Hemen Başlat',
                  decorationIcon: Icons.mode_comment_rounded,
                  onTap: () => _showLiveSupportNotice(context),
                ),
                const SizedBox(height: 16),
                _SupportActionCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Destek Talebi Oluştur',
                  description: 'Sorununuzu detaylandırın,\nçözüm üretelim.',
                  ctaLabel: 'Talep Aç',
                  decorationIcon: Icons.confirmation_number_rounded,
                  onTap: () => _showTicketDialog(context, controller),
                ),
                const SizedBox(height: 32),
                const _ExploreSection(),
                const SizedBox(height: 32),
                const _ResponseTimeCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLiveSupportNotice(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Canlı destek bağlantısı yakında aktif olacak.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showTicketDialog(
    BuildContext context,
    StockAppController controller,
  ) async {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Destek Talebi Oluştur',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Konu',
                    hintText: 'Örn. Sipariş senkron sorunu',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mesaj',
                    hintText: 'Sorununuzu detaylıca anlatın',
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
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.createSupportTicket(
        subject: subjectController.text,
        message: messageController.text,
      );
    }

    subjectController.dispose();
    messageController.dispose();
  }
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(999),
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
          ),
        ),
        const SizedBox(width: 12),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 8, height: 8),
            ),
            SizedBox(width: 8),
            Text(
              'Canlı Destek Hattı',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 16.5 / 11,
                color: AppColors.bodyText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Size nasıl yardımcı olabiliriz?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 32 / 24,
            letterSpacing: -0.60,
            color: AppColors.onSurface,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Sorularınıza hızlı cevaplar bulun veya ekibimize\nulaşın.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
            color: AppColors.bodyText,
          ),
        ),
        SizedBox(height: 16),
        _SearchBar(),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7E8E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const TextField(
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Yardım dökümanlarında ara...',
          hintStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C7B6D),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.bodyText,
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(48, 17, 16, 17),
          isCollapsed: true,
        ),
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.decorationIcon,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String ctaLabel;
  final IconData decorationIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 215,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -2,
                right: -6,
                child: Icon(
                  decorationIcon,
                  size: 110,
                  color: const Color(0xFFE7E8E9),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 28 / 18,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 19.5 / 12,
                      color: AppColors.bodyText,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        ctaLabel,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 16 / 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 8,
                        color: AppColors.primary,
                      ),
                    ],
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

class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'KEŞFET',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
              letterSpacing: 1.4,
              color: AppColors.bodyText,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ExploreListItem(
          icon: Icons.question_mark_rounded,
          title: 'Yardım Merkezi',
          subtitle: 'Kılavuzlar ve öğreticiler',
          onTap: () => _showComingSoon(context, 'Yardım Merkezi'),
        ),
        const SizedBox(height: 12),
        _ExploreListItem(
          icon: Icons.quiz_outlined,
          title: 'SSS',
          subtitle: 'Sıkça sorulan sorular',
          onTap: () => _showComingSoon(context, 'SSS'),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title içeriği yakında eklenecek.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ExploreListItem extends StatelessWidget {
  const _ExploreListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F5),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 16.5 / 11,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.bodyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponseTimeCard extends StatelessWidget {
  const _ResponseTimeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0x80F3F4F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.10),
                    blurRadius: 32,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.20),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ortalama Yanıt Süresi: 5 dakika',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Operasyonel yoğunluğuna bağlı olarak yanıt\nsüresi değişkenlik gösterebilir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 19.5 / 12,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
