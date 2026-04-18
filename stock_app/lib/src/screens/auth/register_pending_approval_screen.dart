import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class RegisterPendingApprovalScreen extends StatelessWidget {
  const RegisterPendingApprovalScreen({super.key});

  void _returnToLogin(BuildContext context) {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        toolbarHeight: 64,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => _returnToLogin(context),
        ),
        centerTitle: true,
        title: const Text(
          'Kayıt Başarılı',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            height: 28 / 18,
            color: AppColors.primary,
          ),
        ),
        actions: const <Widget>[SizedBox(width: 56)],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 39, 24, 80),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Container(
                width: double.infinity,
                height: 663,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.activeNavItemColor.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.activeNavItemColor.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 32,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: AppColors.activeNavItemColor,
                              size: 54,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Aramıza Hoş Geldiniz!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 32 / 24,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Başvurunuz başarıyla alınmıştır.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 22.75 / 14,
                              color: Color(0xFF3D4A3E),
                            ),
                          ),
                          const SizedBox(height: 64),
                          const Text(
                            'SepetPro ekibi tarafından yapılan\n'
                            'değerlendirme sonrasında başvuru\n'
                            'sonucunuz tarafınıza SMS ile\n'
                            'bildirilecektir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Başvurunuz onaylandığında,\n'
                            'belirlediğiniz e-posta adresi ve\n'
                            'şifreniz ile hesabınıza giriş yaparak\n'
                            'ürünlerinizi yüklemeye\n'
                            'başlayabilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          _GradientActionButton(
                            label: 'Giriş Yap',
                            onPressed: () => _returnToLogin(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.activeNavItemColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.activeNavItemColor.withValues(alpha: 0.39),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 24 / 16,
          ),
        ),
      ),
    );
  }
}
