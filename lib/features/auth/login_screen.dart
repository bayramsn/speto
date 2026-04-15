import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(SpetoAppState appState) async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      SpetoToast.show(
        context,
        message: 'E-posta ve şifre alanları gerekli.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    final bool signedIn = await appState.signIn(
      email: email,
      password: password,
    );
    if (!signedIn) {
      if (!mounted) {
        return;
      }
      SpetoToast.show(
        context,
        message: 'Bu e-posta için geçerli bir hesap veya şifre bulunamadı.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    openRootScreen(context, SpetoScreen.home);
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return Scaffold(
      backgroundColor: Palette.base,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactLayout = constraints.maxHeight < 760;
            final double topPadding = compactLayout ? 8 : 12;
            final double bottomPadding = math.max(
              compactLayout ? 16 : 24,
              MediaQuery.paddingOf(context).bottom + (compactLayout ? 12 : 20),
            );
            final double heroSize = compactLayout ? 108 : 128;
            final double heroIconSize = compactLayout ? 46 : 54;
            final double headerGap = compactLayout ? 20 : 28;
            final double heroGap = compactLayout ? 18 : 22;
            final double introGap = compactLayout ? 20 : 28;
            final double fieldGap = compactLayout ? 14 : 18;
            final double sectionGap = compactLayout ? 18 : 24;
            final double buttonHeight = compactLayout ? 52 : 56;
            final double titleFontSize = compactLayout ? 17 : 18;
            final double descriptionFontSize = compactLayout ? 13 : 14;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(
                    0,
                    constraints.maxHeight - topPadding - bottomPadding,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        roundButton(
                          context,
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => openRootScreen(
                            context,
                            SpetoScreen.onboardingPro,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Giriş Yap',
                            textAlign: TextAlign.center,
                            style: context.spetoScreenTitleStyle(
                              fontSize: titleFontSize,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    SizedBox(height: headerGap),
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Container(
                            width: heroSize,
                            height: heroSize,
                            decoration: BoxDecoration(
                              color: Palette.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Icon(
                              Icons.shopping_cart_checkout_rounded,
                              color: Palette.red,
                              size: heroIconSize,
                            ),
                          ),
                          Positioned(
                            right: compactLayout ? -4 : -6,
                            bottom: compactLayout ? 8 : 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: compactLayout ? 8 : 10,
                                vertical: compactLayout ? 5 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Palette.red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'PRO',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: heroGap),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          children: <Widget>[
                            Text(
                              'Sipariş, gel-al ve Pro avantajların için hesabına giriş yap.',
                              textAlign: TextAlign.center,
                              style: context.spetoDescriptionStyle(
                                fontSize: descriptionFontSize,
                              ),
                            ),
                            SizedBox(height: introGap),
                            LabeledField(
                              label: 'E-Posta Adresiniz',
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: fieldGap),
                            LabeledField(
                              label: 'Şifreniz',
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              trailing: GestureDetector(
                                onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Palette.muted,
                                  size: 20,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => openScreen(
                                  context,
                                  SpetoScreen.forgotPassword,
                                ),
                                child: const Text('Şifremi Unuttum'),
                              ),
                            ),
                            SpetoPrimaryButton(
                              label: 'Giriş Yap',
                              height: buttonHeight,
                              onTap: () => _submit(appState),
                            ),
                            SizedBox(height: sectionGap),
                            Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                text: 'Hesabınız yok mu? ',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.white60),
                                children: <InlineSpan>[
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => openScreen(
                                        context,
                                        SpetoScreen.register,
                                      ),
                                      child: const Text(
                                        'Kayıt Olun',
                                        style: TextStyle(
                                          color: Palette.red,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            SpetoCard(
                              radius: 18,
                              color: Palette.cardWarm,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Palette.red.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_outlined,
                                      color: Palette.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Bu sürümde yalnız gerçek e-posta ve şifre ile giriş desteklenir. Simülatif sosyal giriş akışları kaldırıldı.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Palette.soft,
                                            height: 1.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
