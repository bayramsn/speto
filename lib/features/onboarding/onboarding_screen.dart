import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_images.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import 'onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.step});

  final int step;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.step;
    _pageController = PageController(initialPage: widget.step);
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  double _parallaxOffset = 0;

  void _onScroll() {
    setState(() {
      _parallaxOffset = (_pageController.page ?? 0) - _currentPage;
    });
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingModel currentModel = onboardingModels[_currentPage];
    return Scaffold(
      backgroundColor: Palette.ink,
      body: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            top: -60,
            left: -80 + (_parallaxOffset * -40),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: currentModel.gradient.colors.first.withValues(
                  alpha: 0.18,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            bottom: -120,
            right: -70 + (_parallaxOffset * 40),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: currentModel.gradient.colors.last.withValues(
                  alpha: 0.18,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: <Widget>[
                      AnimatedOpacity(
                        opacity: _currentPage > 0 ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: roundButton(
                          context,
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            if (_currentPage > 0) {
                              _goToPage(_currentPage - 1);
                            }
                          },
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => openRootScreen(context, SpetoScreen.login),
                        child: Text(
                          'Geç',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingModels.length,
                    onPageChanged: (int page) {
                      setState(() => _currentPage = page);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final OnboardingModel model = onboardingModels[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final double heroHeight = math.min(
                                  310,
                                  constraints.maxHeight * 0.52,
                                );
                                final bool compactLayout =
                                    constraints.maxHeight < 760;
                                final double titleSize =
                                    compactLayout ? 22 : 26;
                                final double subtitleSize =
                                    compactLayout ? 13 : 14.5;
                                return Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: <Widget>[
                                    SizedBox(
                                      height: heroHeight,
                                      child: Center(
                                        child: _OnboardingHero(
                                          step: index,
                                          model: model,
                                        ),
                                      ),
                                    ),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth,
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 280,
                                            ),
                                            child: Text(
                                              model.caption,
                                              key: ValueKey<String>(
                                                'cap-$index',
                                              ),
                                              style: context.spetoOverlineStyle(
                                                color:
                                                    model.gradient.colors.last,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            model.title,
                                            maxLines: 3,
                                            overflow: TextOverflow.visible,
                                            textAlign: TextAlign.center,
                                            style: context.spetoFeatureTitleStyle(
                                              fontSize: titleSize,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            model.subtitle,
                                            maxLines: 3,
                                            textAlign: TextAlign.center,
                                            style: context.spetoDescriptionStyle(
                                              fontSize: subtitleSize,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 48),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    math.max(16, MediaQuery.paddingOf(context).bottom + 12),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          onboardingModels.length,
                          (int index) {
                            final bool active = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 32 : 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: active
                                    ? currentModel.gradient.colors.last
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      SpetoPrimaryButton(
                        label: currentModel.primary,
                        icon: _currentPage == onboardingModels.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.chevron_right_rounded,
                        onTap: () {
                          if (_currentPage == onboardingModels.length - 1) {
                            openRootScreen(context, SpetoScreen.login);
                          } else {
                            _goToPage(_currentPage + 1);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      SpetoSecondaryButton(
                        label: _currentPage == onboardingModels.length - 1
                            ? 'Girişe Geç'
                            : 'Bu adımı atla',
                        onTap: () => openRootScreen(
                          context,
                          _currentPage == onboardingModels.length - 1
                              ? SpetoScreen.login
                              : SpetoScreen.login,
                        ),
                      ),
                    ],
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

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({required this.step, required this.model});

  final int step;
  final OnboardingModel model;

  @override
  Widget build(BuildContext context) {
    final Color accent = model.gradient.colors.last;
    return SizedBox(
      width: 342,
      height: 342,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              gradient: model.gradient,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 56,
                ),
              ],
            ),
          ),
          if (step == 0)
            Positioned(
              top: 20,
              right: 18,
              child: _floatingInfo(
                icon: Icons.local_grocery_store_outlined,
                text: 'Taze ürünler',
              ),
            ),
          if (step == 1)
            Positioned(
              top: 8,
              right: 0,
              child: _floatingImageCard(AppImages.burger, 130, 'Restoran'),
            ),
          if (step == 2)
            Positioned(
              top: 0,
              child: Transform.rotate(
                angle: -0.08,
                child: Container(
                  width: 300,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF4E0016), Color(0xFFFF7A00)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_bar_rounded,
                      color: Colors.white,
                      size: 88,
                    ),
                  ),
                ),
              ),
            ),
          if (step == 3)
            Positioned(
              top: 46,
              child: Container(
                width: 270,
                height: 186,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 88,
                  ),
                ),
              ),
            ),
          if (step == 4)
            Positioned(
              top: 18,
              child: Container(
                width: 206,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Palette.yellow,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '2.450 Puan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aktif avantajlar hazır',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Palette.soft,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          if (step == 0)
            Positioned(
              bottom: 10,
              left: 0,
              child: _floatingImageCard(AppImages.market, 146, 'Konumlar'),
            ),
          if (step == 1)
            Positioned(
              bottom: 16,
              left: 12,
              child: _floatingImageCard(AppImages.pizza, 136, 'Gel-Al'),
            ),
          if (step == 3)
            Positioned(
              bottom: 20,
              left: 18,
              child: _floatingInfo(
                icon: Icons.discount_rounded,
                text: 'Öğrenci fırsatı',
              ),
            ),
          if (step == 4)
            Positioned(
              top: 54,
              right: 36,
              child: _floatingInfo(
                icon: Icons.monetization_on_rounded,
                text: '+50 Pro',
              ),
            ),
          Positioned(
            child: Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                color: Palette.surface,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(model.icon, size: 82, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingInfo({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingImageCard(String url, double size, String label) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) =>
                    Container(color: Palette.cardWarm),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
