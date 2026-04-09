import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import 'register_screen.dart';

// ---------------------------------------------------------------------------
// Social sign-in draft model & bottom sheet
// ---------------------------------------------------------------------------

class SocialSignInDraft {
  const SocialSignInDraft({required this.email, required this.displayName});

  final String email;
  final String displayName;
}

String displayNameFromEmail(String email) {
  final String localPart = email.split('@').first.trim();
  if (localPart.isEmpty) {
    return 'Speto Kullanıcısı';
  }
  final List<String> words = localPart
      .split(RegExp(r'[._-]+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return 'Speto Kullanıcısı';
  }
  return words
      .map(
        (String part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

Future<SocialSignInDraft?> showSocialSignInSheet(
  BuildContext context, {
  required String providerLabel,
}) async {
  final BuildContext rootContext = context;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final SocialSignInDraft?
  result = await showModalBottomSheet<SocialSignInDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.62,
        child: Container(
          decoration: const BoxDecoration(
            color: Palette.base,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '$providerLabel ile Devam Et',
                      style: context.spetoSectionTitleStyle(fontSize: 19),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bu demo akışta sağlayıcı hesabını yerel olarak eşleştiriyoruz.',
                      style: context.spetoDescriptionStyle(),
                    ),
                    const SizedBox(height: 18),
                    LabeledField(
                      label: 'E-posta',
                      icon: Icons.mail_outline_rounded,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Ad Soyad',
                      icon: Icons.person_outline_rounded,
                      controller: nameController,
                    ),
                    const SizedBox(height: 22),
                    SpetoPrimaryButton(
                      label: 'Devam Et',
                      icon: Icons.arrow_forward_rounded,
                      onTap: () {
                        final String email = emailController.text.trim();
                        final String name = nameController.text.trim();
                        if (email.isEmpty) {
                          SpetoToast.show(
                            rootContext,
                            message: 'Sosyal giriş için e-posta gerekli.',
                            icon: Icons.info_outline_rounded,
                          );
                          return;
                        }
                        Navigator.of(context).pop(
                          SocialSignInDraft(
                            email: email,
                            displayName: name.isEmpty
                                ? displayNameFromEmail(email)
                                : name,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  emailController.dispose();
  nameController.dispose();
  return result;
}

// ---------------------------------------------------------------------------
// Google brand icon helper
// ---------------------------------------------------------------------------

Widget googleBrandIcon({double size = 22}) {
  return ShaderMask(
    shaderCallback: (Rect bounds) {
      return const SweepGradient(
        colors: <Color>[
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
      ).createShader(bounds);
    },
    child: FaIcon(FontAwesomeIcons.google, color: Colors.white, size: size),
  );
}

// ---------------------------------------------------------------------------
// LoginScreen
// ---------------------------------------------------------------------------

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

  Future<void> _socialSignIn(
    SpetoAppState appState, {
    required String provider,
    required String providerLabel,
  }) async {
    final SocialSignInDraft? draft = await showSocialSignInSheet(
      context,
      providerLabel: providerLabel,
    );
    if (draft == null) {
      return;
    }
    final bool hasAccount = await appState.hasAccountForEmail(draft.email);
    if (hasAccount) {
      await appState.signIn(
        email: draft.email,
        password: 'social-$provider',
        displayName: draft.displayName,
        trustedProvider: true,
      );
      if (!mounted) {
        return;
      }
      openRootScreen(context, SpetoScreen.home);
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      spetoRoute(
        RegisterScreen(
          prefillName: draft.displayName,
          prefillEmail: draft.email,
          socialProviderKey: provider,
          socialProviderLabel: providerLabel,
        ),
      ),
    );
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
            final double socialGap = compactLayout ? 14 : 18;
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
                          onTap: () =>
                              openRootScreen(context, SpetoScreen.onboardingPro),
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
                            Text(
                              'Sosyal hesaplarınla devam et',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Colors.white54,
                                    letterSpacing: 0.5,
                                    height: 1.6,
                                  ),
                            ),
                            SizedBox(height: socialGap),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                _SocialBubble(
                                  backgroundColor: Colors.white,
                                  child: googleBrandIcon(size: 22),
                                  onTap: () => _socialSignIn(
                                    appState,
                                    provider: 'google',
                                    providerLabel: 'Google',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _SocialBubble(
                                  backgroundColor: Colors.black,
                                  child: const FaIcon(
                                    FontAwesomeIcons.apple,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onTap: () => _socialSignIn(
                                    appState,
                                    provider: 'apple',
                                    providerLabel: 'Apple',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _SocialBubble(
                                  backgroundColor: const Color(0xFF1877F2),
                                  child: const FaIcon(
                                    FontAwesomeIcons.facebookF,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onTap: () => _socialSignIn(
                                    appState,
                                    provider: 'facebook',
                                    providerLabel: 'Facebook',
                                  ),
                                ),
                              ],
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

// ---------------------------------------------------------------------------
// _SocialBubble
// ---------------------------------------------------------------------------

class _SocialBubble extends StatelessWidget {
  const _SocialBubble({
    required this.child,
    required this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SocialProviderCard (used by RegisterScreen too, so public)
// ---------------------------------------------------------------------------

class SocialProviderCard extends StatelessWidget {
  const SocialProviderCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SpetoCard(
        radius: 16,
        color: Palette.cardWarm,
        child: Row(
          children: <Widget>[
            SizedBox(width: 22, height: 22, child: Center(child: icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Palette.soft),
          ],
        ),
      ),
    );
  }
}
