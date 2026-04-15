import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/providers.dart';
import 'core/state/app_state.dart';
import 'features/events/event_data.dart';
import 'src/core/bootstrap.dart';

class SpetoApp extends ConsumerStatefulWidget {
  SpetoApp({super.key, SpetoBootstrap? bootstrap})
    : bootstrap = bootstrap ?? SpetoBootstrap.ephemeral();

  final SpetoBootstrap bootstrap;

  @override
  ConsumerState<SpetoApp> createState() => _SpetoAppState();
}

class _SpetoAppState extends ConsumerState<SpetoApp>
    with WidgetsBindingObserver {
  static const Duration _runtimeRefreshInterval = Duration(seconds: 60);

  bool _runtimeRefreshInFlight = false;
  Timer? _runtimeRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRuntimeRefreshTimer();
    unawaited(_refreshRuntimeData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runtimeRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRuntimeRefreshTimer();
      unawaited(_refreshRuntimeData());
      return;
    }
    _runtimeRefreshTimer?.cancel();
    _runtimeRefreshTimer = null;
  }

  Future<void> _refreshRuntimeData() async {
    if (_runtimeRefreshInFlight) {
      return;
    }
    _runtimeRefreshInFlight = true;
    try {
      await initializeSpetoCatalog();
      await ref.read(appStateProvider).refreshDomainState();
      if (mounted) {
        setState(() {});
      }
    } finally {
      _runtimeRefreshInFlight = false;
    }
  }

  void _startRuntimeRefreshTimer() {
    if (_runtimeRefreshTimer != null) {
      return;
    }
    _runtimeRefreshTimer = Timer.periodic(_runtimeRefreshInterval, (_) {
      unawaited(_refreshRuntimeData());
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final router = ref.watch(goRouterProvider);

    // Keep the SpetoAppScope for backward compatibility with screens
    // that still use SpetoAppScope.of(context).
    return SpetoAppScope(
      notifier: appState,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SepetPro',
        themeMode: appState.themeMode,
        theme: AppTheme.build(isDark: false),
        darkTheme: AppTheme.build(isDark: true),

        // Localization
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),

        // GoRouter
        routerConfig: router,

        builder: (BuildContext context, Widget? child) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          return ColoredBox(
            color: isDark ? Palette.base : PaletteLight.base,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
