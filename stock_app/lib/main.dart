import 'dart:async';

import 'package:flutter/material.dart';

import 'src/app/stock_app_controller.dart';
import 'src/app/stock_app_scope.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/dashboard/home_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const StockApp());
}

class StockApp extends StatefulWidget {
  const StockApp({super.key, this.controller});

  final StockAppController? controller;

  @override
  State<StockApp> createState() => _StockAppState();
}

class _StockAppState extends State<StockApp> with WidgetsBindingObserver {
  static const Duration _syncInterval = Duration(seconds: 45);

  late final StockAppController _controller;
  late final bool _ownsController;
  Timer? _syncTimer;
  bool _syncInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? StockAppController();
    _controller.addListener(_handleControllerChanged);
    if (_ownsController) {
      unawaited(_controller.bootstrap());
    }
    _configureSyncTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChanged);
    _syncTimer?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _configureSyncTimer();
      unawaited(_performSilentSync());
      return;
    }
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _handleControllerChanged() {
    _configureSyncTimer();
  }

  void _configureSyncTimer() {
    if (!_controller.isAuthenticated) {
      _syncTimer?.cancel();
      _syncTimer = null;
      return;
    }
    if (_syncTimer != null) {
      return;
    }
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      unawaited(_performSilentSync());
    });
  }

  Future<void> _performSilentSync() async {
    if (_syncInFlight || !_controller.isAuthenticated) {
      return;
    }
    _syncInFlight = true;
    try {
      await _controller.refreshData(silent: true);
    } finally {
      _syncInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StockAppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'SepetPro İşyeri',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _StockAppRouter(),
      ),
    );
  }
}

class _StockAppRouter extends StatelessWidget {
  const _StockAppRouter();

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    if (controller.isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!controller.isAuthenticated) {
      return const LoginScreen();
    }
    return const HomeScreen();
  }
}
