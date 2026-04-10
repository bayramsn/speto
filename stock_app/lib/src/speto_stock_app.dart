import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

const Color _sidebar = Color(0xFF16110F);
const Color _panel = Color(0xFFFFFCF8);
const Color _panelStrong = Colors.white;
const Color _ink = Color(0xFF1E1917);
const Color _muted = Color(0xFF766B61);
const Color _line = Color(0xFFE8DDCF);
const Color _accent = Color(0xFFC56B1A);
const Color _accentDeep = Color(0xFF8F4B14);
const Color _accentSoft = Color(0xFFFFF1DD);
const Color _danger = Color(0xFFB9382B);
const Color _dangerSoft = Color(0xFFFCE7E5);
const Color _success = Color(0xFF1F8A55);
const Color _successSoft = Color(0xFFE7F5EC);
const Color _warning = Color(0xFFB77A12);
const Color _warningSoft = Color(0xFFFFF6DB);
const Color _info = Color(0xFF3657B8);
const Color _infoSoft = Color(0xFFEAF0FF);

LinearGradient get _heroGradient => const LinearGradient(
  colors: <Color>[Color(0xFFFBE5C5), Color(0xFFE9F0DE), Color(0xFFF7F1E8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

String _storefrontLabel(SpetoStorefrontType type) {
  return switch (type) {
    SpetoStorefrontType.market => 'Market',
    SpetoStorefrontType.restaurant => 'Restoran',
  };
}

Color _healthColor(SpetoIntegrationHealth health) {
  return switch (health) {
    SpetoIntegrationHealth.healthy => _success,
    SpetoIntegrationHealth.warning => _warning,
    SpetoIntegrationHealth.failed => _danger,
  };
}

String _healthLabel(SpetoIntegrationHealth health) {
  return switch (health) {
    SpetoIntegrationHealth.healthy => 'Sağlıklı',
    SpetoIntegrationHealth.warning => 'Dikkat',
    SpetoIntegrationHealth.failed => 'Sorunlu',
  };
}

Color _stockColor(SpetoStockStatus status) {
  if (!status.isInStock) {
    return _danger;
  }
  if (status.lowStock) {
    return _warning;
  }
  return _success;
}

String _stockLabel(SpetoStockStatus status) {
  if (!status.isInStock) {
    return 'Tükendi';
  }
  if (status.lowStock) {
    return 'Kritik stok';
  }
  return 'Satışta';
}

String _roleLabel(SpetoUserRole role) {
  return switch (role) {
    SpetoUserRole.admin => 'YÖNETİCİ',
    SpetoUserRole.vendor => 'MAĞAZA',
    SpetoUserRole.customer => 'MÜŞTERİ',
  };
}

String _opsStageLabel(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => 'Yeni',
    SpetoOpsOrderStage.accepted => 'Kabul edildi',
    SpetoOpsOrderStage.preparing => 'Hazırlanıyor',
    SpetoOpsOrderStage.ready => 'Hazır',
    SpetoOpsOrderStage.completed => 'Tamamlandı',
    SpetoOpsOrderStage.cancelled => 'İptal',
  };
}

String _inventoryMovementLabel(SpetoInventoryMovementType type) {
  return switch (type) {
    SpetoInventoryMovementType.sale => 'Satış',
    SpetoInventoryMovementType.manualAdjustment => 'Manuel düzeltme',
    SpetoInventoryMovementType.restock => 'Stok girişi',
    SpetoInventoryMovementType.posSync => 'POS senkronu',
    SpetoInventoryMovementType.reservation => 'Rezervasyon',
    SpetoInventoryMovementType.release => 'Rezervasyon bırakma',
  };
}

List<SpetoOpsOrderStage> _nextOpsStages(SpetoOpsOrderStage current) {
  return switch (current) {
    SpetoOpsOrderStage.created => <SpetoOpsOrderStage>[
      SpetoOpsOrderStage.accepted,
      SpetoOpsOrderStage.cancelled,
    ],
    SpetoOpsOrderStage.accepted => <SpetoOpsOrderStage>[
      SpetoOpsOrderStage.preparing,
      SpetoOpsOrderStage.cancelled,
    ],
    SpetoOpsOrderStage.preparing => <SpetoOpsOrderStage>[
      SpetoOpsOrderStage.ready,
      SpetoOpsOrderStage.cancelled,
    ],
    SpetoOpsOrderStage.ready => <SpetoOpsOrderStage>[
      SpetoOpsOrderStage.completed,
    ],
    SpetoOpsOrderStage.completed ||
    SpetoOpsOrderStage.cancelled => const <SpetoOpsOrderStage>[],
  };
}

class SpetoStockApp extends StatefulWidget {
  const SpetoStockApp({super.key});

  @override
  State<SpetoStockApp> createState() => _SpetoStockAppState();
}

class _SpetoStockAppState extends State<SpetoStockApp> {
  final SpetoRemoteDomainApi _api = SpetoRemoteDomainApi(
    SpetoRemoteApiClient(),
  );

  SpetoSession? _session;

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
    final ThemeData theme = baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -1.2,
        ),
        displayMedium: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.8,
        ),
        displaySmall: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.6,
        ),
        headlineLarge: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.4,
        ),
        headlineMedium: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.3,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.2,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        bodyLarge: const TextStyle(fontSize: 15, height: 1.5, color: _ink),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.5, color: _ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _panelStrong,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: _muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _line),
        ),
      ),
      dividerColor: _line,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: _line),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: _panelStrong,
        indicatorColor: _accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
          Set<WidgetState> states,
        ) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w700,
            color: states.contains(WidgetState.selected) ? _ink : _muted,
          );
        }),
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Speto Stock',
      theme: theme,
      home: _session == null
          ? _LoginScreen(
              api: _api,
              onLoggedIn: (SpetoSession session) {
                setState(() {
                  _session = session;
                });
              },
            )
          : _StockShell(
              api: _api,
              session: _session!,
              onSignOut: () {
                _api.clearSession();
                setState(() {
                  _session = null;
                });
              },
            ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({required this.api, required this.onLoggedIn});

  final SpetoRemoteDomainApi api;
  final ValueChanged<SpetoSession> onLoggedIn;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  static const String _backendOfflineMessage =
      'Backend erişilemiyor. Önce backend servisini başlatın ve sayfayı yenileyin.';

  final TextEditingController _emailController = TextEditingController(
    text: 'admin@speto.app',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'admin123',
  );

  bool _isLoading = false;
  bool _isCheckingBackend = true;
  bool _backendReachable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final bool isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (!isTestBinding) {
      _probeBackend();
    } else {
      _isCheckingBackend = false;
      _backendReachable = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _probeBackend() async {
    setState(() {
      _isCheckingBackend = true;
    });
    final bool isReachable = await widget.api.checkHealth();
    if (!mounted) {
      return;
    }
    setState(() {
      _isCheckingBackend = false;
      _backendReachable = isReachable;
      if (isReachable && _error == _backendOfflineMessage) {
        _error = null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_backendReachable) {
      await _probeBackend();
      if (!_backendReachable) {
        setState(() {
          _error = _backendOfflineMessage;
        });
        return;
      }
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final SpetoSession session = await widget.api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (session.role == SpetoUserRole.customer) {
        setState(() {
          _error =
              'Bu uygulamaya yalnızca admin veya vendor hesapları girebilir.';
          _isLoading = false;
        });
        return;
      }
      widget.onLoggedIn(session);
    } on SpetoRemoteApiException catch (error) {
      setState(() {
        _error = _friendlyApiError(error);
        _isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        _error =
            'Backend zamanında yanıt vermedi. API servisini kontrol edip tekrar deneyin.';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = _backendOfflineMessage;
        _isLoading = false;
      });
    }
  }

  String _friendlyApiError(SpetoRemoteApiException error) {
    if (error.message.contains('401')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (error.message.contains('404') ||
        error.toString().contains('XMLHttpRequest error')) {
      return _backendOfflineMessage;
    }
    if (error.message.contains('500')) {
      return 'Backend hata verdi. Servis loglarını kontrol edip tekrar deneyin.';
    }
    return 'Giriş başarısız. Demo hesaplardan biriyle tekrar deneyin.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF7E8D2), Color(0xFFE8F0E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 760;
                  final Widget introPanel = Padding(
                    padding: EdgeInsets.only(
                      right: compact ? 0 : 24,
                      bottom: compact ? 24 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Speto Stock Ops',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Stok, sipariş ve ERP senkronunu tek panelde yönetin.',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bu uygulama aynı backend üzerinden vendor ve admin operasyonunu yönetir. Düşük stok, açık sipariş, manuel düzeltme ve generic POS/ERP sync akışları buradan yürür.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: _muted, height: 1.55),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: const <Widget>[
                            _CredentialChip(
                              label: 'Admin',
                              email: 'admin@speto.app',
                              password: 'admin123',
                            ),
                            _CredentialChip(
                              label: 'Burger Mağaza',
                              email: 'burger@speto.app',
                              password: 'vendor123',
                            ),
                            _CredentialChip(
                              label: 'Market Mağaza',
                              email: 'market@speto.app',
                              password: 'vendor123',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                  final Widget formPanel = Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          blurRadius: 30,
                          color: Color(0x1A0F172A),
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Operasyon girişi',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _emailController,
                          decoration: _inputDecoration('E-posta'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration('Şifre'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Icon(
                              _isCheckingBackend
                                  ? Icons.sync
                                  : _backendReachable
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_off_outlined,
                              size: 18,
                              color: _isCheckingBackend
                                  ? _muted
                                  : _backendReachable
                                  ? _success
                                  : _danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isCheckingBackend
                                    ? 'Backend bağlantısı kontrol ediliyor...'
                                    : _backendReachable
                                    ? 'Backend bağlı. Giriş yapılabilir.'
                                    : _backendOfflineMessage,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: _isCheckingBackend
                                          ? _muted
                                          : _backendReachable
                                          ? _success
                                          : _danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: _isCheckingBackend
                                  ? null
                                  : _probeBackend,
                              child: const Text('Yenile'),
                            ),
                          ],
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _danger,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading || _isCheckingBackend
                                ? null
                                : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: _ink,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _isLoading ? 'Giriş yapılıyor...' : 'Panele gir',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[introPanel, formPanel],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: introPanel),
                      Expanded(child: formPanel),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _CredentialChip extends StatelessWidget {
  const _CredentialChip({
    required this.label,
    required this.email,
    required this.password,
  });

  final String label;
  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: _muted)),
          Text(password, style: const TextStyle(color: _muted)),
        ],
      ),
    );
  }
}

class _StockShell extends StatefulWidget {
  const _StockShell({
    required this.api,
    required this.session,
    required this.onSignOut,
  });

  final SpetoRemoteDomainApi api;
  final SpetoSession session;
  final VoidCallback onSignOut;

  @override
  State<_StockShell> createState() => _StockShellState();
}

class _StockShellState extends State<_StockShell> {
  int _index = 0;
  bool _loading = true;
  String? _error;
  String? _warningMessage;
  String? _selectedVendorId;
  String? _selectedInventoryId;

  SpetoInventorySnapshot? _dashboard;
  List<SpetoInventoryItem> _inventoryItems = <SpetoInventoryItem>[];
  List<SpetoOpsOrder> _orders = <SpetoOpsOrder>[];
  List<SpetoIntegrationConnection> _integrations =
      <SpetoIntegrationConnection>[];
  List<SpetoInventoryMovement> _movements = <SpetoInventoryMovement>[];
  List<SpetoCatalogVendor> _catalogVendors = <SpetoCatalogVendor>[];
  List<SpetoCatalogEvent> _catalogEvents = <SpetoCatalogEvent>[];
  List<SpetoCatalogContentBlock> _contentBlocks = <SpetoCatalogContentBlock>[];

  bool get _isAdmin => widget.session.role == SpetoUserRole.admin;

  List<_VendorScopeChoice> get _vendorChoices {
    return _vendorOptions.map((_vendorChoiceForId)).toList(growable: false);
  }

  List<String> _vendorOptionsFor([List<SpetoCatalogVendor>? catalogVendors]) {
    final LinkedHashSet<String> vendorIds = LinkedHashSet<String>.from(
      <String>[
            ...widget.session.vendorScopes,
            ...(catalogVendors ?? _catalogVendors).map(
              (SpetoCatalogVendor vendor) => vendor.vendorId,
            ),
          ]
          .map((String vendorId) => vendorId.trim())
          .where((String vendorId) => vendorId.isNotEmpty),
    );
    if (vendorIds.isEmpty) {
      vendorIds.add('vendor-burger-yiyelim');
    }
    return vendorIds.toList(growable: false);
  }

  List<String> get _vendorOptions => _vendorOptionsFor();

  String? _normalizedVendorId([
    String? preferredVendorId,
    List<SpetoCatalogVendor>? catalogVendors,
  ]) {
    final List<String> options = _vendorOptionsFor(catalogVendors);
    if (options.isEmpty) {
      return null;
    }
    final String? candidate = preferredVendorId ?? _selectedVendorId;
    if (candidate != null && options.contains(candidate)) {
      return candidate;
    }
    return options.first;
  }

  @override
  void initState() {
    super.initState();
    _selectedVendorId = _normalizedVendorId();
    _reload();
  }

  String? _resolvedVendorId() {
    if (_isAdmin) {
      return _normalizedVendorId();
    }
    final List<String> options = _vendorOptions;
    return options.isEmpty ? null : options.first;
  }

  _VendorScopeChoice _vendorChoiceForId(String vendorId) {
    final SpetoCatalogVendor? vendor = _findVendorById(vendorId);
    if (vendor != null) {
      return _VendorScopeChoice(
        id: vendor.vendorId,
        label: vendor.title,
        caption:
            '${_storefrontLabel(vendor.storefrontType)} • ${vendor.subtitle.isEmpty ? vendor.cuisine : vendor.subtitle}',
      );
    }
    return _VendorScopeChoice(
      id: vendorId,
      label: vendorId.replaceFirst('vendor-', '').replaceAll('-', ' '),
      caption: 'Mağaza kapsamı',
    );
  }

  String _friendlyApiError(SpetoRemoteApiException error) {
    if (error.message.contains('401')) {
      return 'Oturum doğrulanamadı. Yeniden giriş yapın.';
    }
    if (error.message.contains('403')) {
      return 'Bu işlem için yetkiniz yok.';
    }
    if (error.message.contains('404') ||
        error.toString().contains('XMLHttpRequest error')) {
      return 'Backend erişilemiyor. API servisini kontrol edin.';
    }
    if (error.message.contains('500')) {
      return 'Backend hata verdi. Servis loglarını kontrol edin.';
    }
    return 'İstek başarısız oldu.';
  }

  Future<T?> _safeLoad<T>(
    String label,
    Future<T> Function() action,
    List<String> warnings,
  ) async {
    try {
      return await action();
    } on SpetoRemoteApiException catch (error) {
      warnings.add('$label: ${_friendlyApiError(error)}');
    } on TimeoutException {
      warnings.add('$label: İstek zamanında tamamlanmadı.');
    } catch (_) {
      warnings.add('$label: Beklenmeyen bir hata oluştu.');
    }
    return null;
  }

  SpetoInventorySnapshot _fallbackSnapshot(
    List<SpetoInventoryItem> items,
    List<SpetoOpsOrder> orders,
    List<SpetoIntegrationConnection> integrations,
  ) {
    final int lowStockCount = items
        .where((SpetoInventoryItem item) => item.stockStatus.lowStock)
        .length;
    final int outOfStockCount = items
        .where((SpetoInventoryItem item) => !item.stockStatus.isInStock)
        .length;
    final int openOrdersCount = orders
        .where((SpetoOpsOrder order) => order.status == SpetoOrderStatus.active)
        .length;
    final int integrationErrorCount = integrations
        .where(
          (SpetoIntegrationConnection connection) =>
              connection.health == SpetoIntegrationHealth.failed,
        )
        .length;
    final int pendingSyncCount = integrations
        .where(
          (SpetoIntegrationConnection connection) =>
              connection.lastSync.status == SpetoSyncRunStatus.running,
        )
        .length;

    return SpetoInventorySnapshot(
      items: items,
      totalItems: items.length,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      openOrdersCount: openOrdersCount,
      integrationErrorCount: integrationErrorCount,
      pendingSyncCount: pendingSyncCount,
      totalAvailableUnits: items.fold<int>(
        0,
        (int total, SpetoInventoryItem item) =>
            total + item.stockStatus.availableQuantity,
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? _danger : _ink,
          content: Text(message),
        ),
      );
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _warningMessage = null;
    });
    final List<String> warnings = <String>[];
    final String? vendorId = _resolvedVendorId();

    final SpetoInventorySnapshot? snapshot = await _safeLoad(
      'Dashboard',
      () => widget.api.fetchInventorySnapshot(vendorId: vendorId),
      warnings,
    );
    final List<SpetoInventoryItem> inventory =
        await _safeLoad(
          'Stok listesi',
          () => widget.api.fetchInventoryItems(vendorId: vendorId),
          warnings,
        ) ??
        const <SpetoInventoryItem>[];
    final List<SpetoOpsOrder> orders =
        await _safeLoad(
          'Siparişler',
          () => widget.api.fetchOpsOrders(vendorId: vendorId),
          warnings,
        ) ??
        const <SpetoOpsOrder>[];
    final List<SpetoIntegrationConnection> integrations =
        await _safeLoad(
          'Entegrasyonlar',
          () => widget.api.fetchIntegrations(vendorId: vendorId),
          warnings,
        ) ??
        const <SpetoIntegrationConnection>[];
    final List<SpetoCatalogVendor> catalogVendors =
        await _safeLoad(
          'Katalog vendorları',
          () => widget.api.fetchCatalogAdminVendors(vendorId: vendorId),
          warnings,
        ) ??
        const <SpetoCatalogVendor>[];
    final List<SpetoCatalogEvent> catalogEvents = _isAdmin
        ? await _safeLoad(
                'Etkinlik kataloğu',
                () => widget.api.fetchCatalogAdminEvents(),
                warnings,
              ) ??
              const <SpetoCatalogEvent>[]
        : const <SpetoCatalogEvent>[];
    final List<SpetoCatalogContentBlock> contentBlocks = _isAdmin
        ? await _safeLoad(
                'Ana sayfa içerikleri',
                () => widget.api.fetchCatalogContentBlocks(),
                warnings,
              ) ??
              const <SpetoCatalogContentBlock>[]
        : const <SpetoCatalogContentBlock>[];

    final String? selectedInventoryId =
        inventory.any(
          (SpetoInventoryItem item) => item.id == _selectedInventoryId,
        )
        ? _selectedInventoryId
        : inventory.isNotEmpty
        ? inventory.first.id
        : null;
    final List<SpetoInventoryMovement> movements = selectedInventoryId == null
        ? const <SpetoInventoryMovement>[]
        : await _safeLoad(
                'Hareket geçmişi',
                () => widget.api.fetchInventoryMovements(
                  vendorId: vendorId,
                  productId: selectedInventoryId,
                ),
                warnings,
              ) ??
              const <SpetoInventoryMovement>[];

    if (!mounted) {
      return;
    }

    final SpetoInventorySnapshot resolvedSnapshot =
        snapshot ?? _fallbackSnapshot(inventory, orders, integrations);
    final String? normalizedVendorId = _normalizedVendorId(
      _selectedVendorId,
      catalogVendors,
    );
    final bool hasAnyData =
        resolvedSnapshot.items.isNotEmpty ||
        orders.isNotEmpty ||
        integrations.isNotEmpty ||
        catalogVendors.isNotEmpty ||
        catalogEvents.isNotEmpty ||
        contentBlocks.isNotEmpty;

    setState(() {
      _dashboard = resolvedSnapshot;
      _inventoryItems = inventory;
      _orders = orders;
      _integrations = integrations;
      _selectedVendorId = normalizedVendorId;
      _selectedInventoryId = selectedInventoryId;
      _movements = movements;
      _catalogVendors = catalogVendors;
      _catalogEvents = catalogEvents;
      _contentBlocks = contentBlocks;
      _error = hasAnyData
          ? null
          : 'Operasyon verisi yüklenemedi. Backend bağlantısını ve giriş durumunu kontrol edin.';
      _warningMessage = warnings.isEmpty ? null : warnings.join('\n');
      _loading = false;
    });
  }

  Future<void> _changeOrderStatus(
    SpetoOpsOrder order,
    SpetoOpsOrderStage stage,
  ) async {
    try {
      await widget.api.updateOpsOrderStatus(order.id, stage);
      await _reload();
      if (mounted) {
        _showMessage(
          'Sipariş durumu ${stage.name.toUpperCase()} olarak güncellendi.',
        );
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage('Sipariş güncellemesi zaman aşımına uğradı.', isError: true);
    } catch (_) {
      _showMessage('Sipariş durumu güncellenemedi.', isError: true);
    }
  }

  Future<void> _adjustInventory(SpetoInventoryItem item, bool restock) async {
    final TextEditingController amountController = TextEditingController(
      text: restock ? '5' : '-2',
    );
    final TextEditingController noteController = TextEditingController(
      text: restock ? 'Tedarik girişi' : 'Sayım düzeltmesi',
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(restock ? 'Stok girişi yap' : 'Manuel düzeltme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Miktar'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Not'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      if (restock) {
        await widget.api.restockInventoryItem(
          id: item.id,
          quantity: int.tryParse(amountController.text) ?? 0,
          note: noteController.text.trim(),
        );
      } else {
        await widget.api.adjustInventoryItem(
          id: item.id,
          quantityDelta: int.tryParse(amountController.text) ?? 0,
          reason: noteController.text.trim(),
        );
      }
      await _reload();
      if (mounted) {
        _showMessage(
          restock ? 'Stok girişi kaydedildi.' : 'Manuel düzeltme kaydedildi.',
        );
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage('Stok işlemi zaman aşımına uğradı.', isError: true);
    } catch (_) {
      _showMessage('Stok işlemi tamamlanamadı.', isError: true);
    }
  }

  Future<void> _syncIntegration(SpetoIntegrationConnection connection) async {
    try {
      await widget.api.syncIntegration(connection.id);
      await _reload();
      if (mounted) {
        _showMessage('Entegrasyon sync tamamlandı.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage('Senkron isteği zaman aşımına uğradı.', isError: true);
    } catch (_) {
      _showMessage('Senkron işlemi başlatılamadı.', isError: true);
    }
  }

  Future<void> _createIntegration() async {
    final TextEditingController nameController = TextEditingController(
      text: 'Yeni ERP Bağlantısı',
    );
    final TextEditingController providerController = TextEditingController(
      text: 'Generic Adapter',
    );
    final TextEditingController baseUrlController = TextEditingController(
      text: 'https://example-erp.local',
    );
    final TextEditingController locationController = TextEditingController(
      text: 'loc-generic',
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni entegrasyon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Bağlantı adı'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: providerController,
                decoration: const InputDecoration(labelText: 'Sağlayıcı'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(labelText: 'Servis adresi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Lokasyon ID'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      final String? vendorId = _normalizedVendorId();
      if (vendorId == null) {
        _showMessage('Önce bir mağaza seçin.', isError: true);
        return;
      }
      await widget.api.createIntegration(
        vendorId: vendorId,
        name: nameController.text.trim(),
        provider: providerController.text.trim(),
        type: SpetoIntegrationType.erp,
        baseUrl: baseUrlController.text.trim(),
        locationId: locationController.text.trim(),
        skuMappings: <String, String>{'EXT-GEN-001': 'BK-MEGA-001'},
      );
      await _reload();
      if (mounted) {
        _showMessage('Yeni entegrasyon oluşturuldu.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage(
        'Entegrasyon oluşturma zaman aşımına uğradı.',
        isError: true,
      );
    } catch (_) {
      _showMessage('Entegrasyon oluşturulamadı.', isError: true);
    }
  }

  SpetoCatalogVendor? _findVendorById(String vendorId) {
    for (final SpetoCatalogVendor vendor in _catalogVendors) {
      if (vendor.vendorId == vendorId) {
        return vendor;
      }
    }
    return null;
  }

  Future<void> _createCatalogVendor() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController slugController = TextEditingController();
    final TextEditingController categoryController = TextEditingController(
      text: 'Restoran',
    );
    final TextEditingController subtitleController = TextEditingController();
    final TextEditingController imageController = TextEditingController();
    final TextEditingController pickupLabelController = TextEditingController(
      text: 'Ana teslim noktası',
    );
    final TextEditingController pickupAddressController =
        TextEditingController();
    final TextEditingController operatorNameController =
        TextEditingController();
    final TextEditingController operatorEmailController =
        TextEditingController();
    final TextEditingController operatorPasswordController =
        TextEditingController(text: 'vendor123');
    final TextEditingController operatorPhoneController =
        TextEditingController();
    bool isMarket = false;
    int currentStep = 0;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final Size screenSize = MediaQuery.sizeOf(context);
            final bool compactDialog = screenSize.width < 560;
            final double dialogHeight = screenSize.height * 0.88 < 760
                ? screenSize.height * 0.88
                : 760;
            return Dialog(
              insetPadding: EdgeInsets.all(compactDialog ? 12 : 24),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compactDialog ? screenSize.width - 24 : 760,
                  maxHeight: dialogHeight,
                ),
                child: _SurfaceCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Yeni mağaza / restoran',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Admin kurulumu dört adımda tamamlar: tip, vitrin, operatör hesabı ve ilk operasyon ayarları.',
                        style: TextStyle(color: _muted, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: Stepper(
                              margin: compactDialog ? EdgeInsets.zero : null,
                              currentStep: currentStep,
                              onStepTapped: (int step) {
                                setModalState(() {
                                  currentStep = step;
                                });
                              },
                              controlsBuilder:
                                  (
                                    BuildContext context,
                                    ControlsDetails details,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 18),
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: <Widget>[
                                          if (currentStep > 0)
                                            OutlinedButton(
                                              onPressed: () {
                                                setModalState(() {
                                                  currentStep -= 1;
                                                });
                                              },
                                              child: const Text('Geri'),
                                            ),
                                          FilledButton(
                                            onPressed: () {
                                              if (currentStep == 3) {
                                                Navigator.of(context).pop(true);
                                                return;
                                              }
                                              setModalState(() {
                                                currentStep += 1;
                                              });
                                            },
                                            child: Text(
                                              currentStep == 3
                                                  ? 'Mağazayı oluştur'
                                                  : 'Devam et',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                              steps: <Step>[
                                Step(
                                  title: const Text('Mağaza tipi'),
                                  isActive: currentStep >= 0,
                                  content: Column(
                                    children: <Widget>[
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Market olarak oluştur',
                                        ),
                                        subtitle: const Text(
                                          'Kapalıysa restoran storefront akışı açılır.',
                                        ),
                                        value: isMarket,
                                        onChanged: (bool value) {
                                          setModalState(() {
                                            isMarket = value;
                                            categoryController.text = value
                                                ? 'Market'
                                                : 'Restoran';
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Mağaza adı',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: slugController,
                                        decoration: const InputDecoration(
                                          labelText: 'Kısa kod / slug',
                                          helperText:
                                              'Boş bırakırsan otomatik üretilir',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: categoryController,
                                        decoration: const InputDecoration(
                                          labelText: 'Kategori',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Step(
                                  title: const Text('Vitrin bilgileri'),
                                  isActive: currentStep >= 1,
                                  content: Column(
                                    children: <Widget>[
                                      TextField(
                                        controller: subtitleController,
                                        decoration: const InputDecoration(
                                          labelText: 'Alt başlık',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: imageController,
                                        decoration: const InputDecoration(
                                          labelText: 'Kapak görseli URL',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: pickupLabelController,
                                        decoration: const InputDecoration(
                                          labelText: 'Teslim noktası başlığı',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: pickupAddressController,
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                          labelText: 'Teslim noktası adresi',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Step(
                                  title: const Text('Operatör hesabı'),
                                  isActive: currentStep >= 2,
                                  content: Column(
                                    children: <Widget>[
                                      TextField(
                                        controller: operatorNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Mağaza yetkilisi adı',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: operatorEmailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Kullanıcı adı / e-posta',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: operatorPasswordController,
                                        decoration: const InputDecoration(
                                          labelText: 'Şifre',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: operatorPhoneController,
                                        decoration: const InputDecoration(
                                          labelText: 'Telefon',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Step(
                                  title: const Text('İlk kurulum özeti'),
                                  isActive: currentStep >= 3,
                                  content: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _accentSoft.withValues(
                                        alpha: 0.45,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          nameController.text.isEmpty
                                              ? 'Yeni mağaza'
                                              : nameController.text,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${isMarket ? 'Market' : 'Restoran'} • ${subtitleController.text.isEmpty ? 'Alt başlık yok' : subtitleController.text}',
                                          style: const TextStyle(color: _muted),
                                        ),
                                        const SizedBox(height: 12),
                                        _InfoPill(
                                          label:
                                              operatorEmailController
                                                  .text
                                                  .isEmpty
                                              ? 'Operatör hesabı tanımlanmadı'
                                              : operatorEmailController.text,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      final SpetoCatalogVendor created = await widget.api
          .createCatalogVendor(<String, Object?>{
            'name': nameController.text.trim(),
            'slug': slugController.text.trim(),
            'category': categoryController.text.trim(),
            'subtitle': subtitleController.text.trim(),
            'imageUrl': imageController.text.trim(),
            'storefrontType': isMarket ? 'MARKET' : 'RESTAURANT',
            'pickupPointLabel': pickupLabelController.text.trim(),
            'pickupPointAddress': pickupAddressController.text.trim(),
            'operatorDisplayName': operatorNameController.text.trim(),
            'operatorEmail': operatorEmailController.text.trim(),
            'operatorPassword': operatorPasswordController.text.trim(),
            'operatorPhone': operatorPhoneController.text.trim(),
          });
      if (mounted) {
        setState(() {
          _catalogVendors = <SpetoCatalogVendor>[
            created,
            ..._catalogVendors.where(
              (SpetoCatalogVendor vendor) =>
                  vendor.vendorId != created.vendorId,
            ),
          ];
          _selectedVendorId = created.vendorId;
          _index = 4;
        });
      }
      await _reload();
      if (mounted) {
        _showMessage('Yeni mağaza oluşturuldu.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage('Mağaza oluşturma zaman aşımına uğradı.', isError: true);
    } catch (_) {
      _showMessage('Mağaza oluşturulamadı.', isError: true);
    }
  }

  Future<void> _createCatalogSection(SpetoCatalogVendor vendor) async {
    final TextEditingController labelController = TextEditingController();
    final TextEditingController keyController = TextEditingController();
    final TextEditingController orderController = TextEditingController(
      text: '${vendor.sections.length}',
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${vendor.title} için kategori ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Kategori adı'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Kısa kod',
                    helperText: 'Boş kalırsa otomatik üretilir',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sıra'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.api.createCatalogSection(<String, Object?>{
        'vendorId': vendor.vendorId,
        'label': labelController.text.trim(),
        'key': keyController.text.trim(),
        'displayOrder':
            int.tryParse(orderController.text) ?? vendor.sections.length,
        'isActive': true,
      });
      await _reload();
      if (mounted) {
        _showMessage('Kategori eklendi.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage('Kategori ekleme zaman aşımına uğradı.', isError: true);
    } catch (_) {
      _showMessage('Kategori eklenemedi.', isError: true);
    }
  }

  Future<void> _openCatalogProductEditor({
    required SpetoCatalogVendor vendor,
    SpetoCatalogProduct? product,
    SpetoCatalogSection? initialSection,
  }) async {
    final bool isCreate = product == null;
    final SpetoCatalogProduct? existingProduct = product;
    final TextEditingController titleController = TextEditingController(
      text: product?.title ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final TextEditingController imageController = TextEditingController(
      text: product?.imageUrl ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: isCreate
          ? '0'
          : existingProduct?.unitPrice.toStringAsFixed(0) ?? '0',
    );
    final TextEditingController categoryController = TextEditingController(
      text: product?.category ?? vendor.cuisine,
    );
    final TextEditingController skuController = TextEditingController(
      text: product?.sku ?? '',
    );
    final TextEditingController barcodeController = TextEditingController(
      text: product?.barcode ?? '',
    );
    final TextEditingController externalCodeController = TextEditingController(
      text: product?.externalCode ?? '',
    );
    final TextEditingController subtitleController = TextEditingController(
      text: product?.displaySubtitle ?? '',
    );
    final TextEditingController badgeController = TextEditingController(
      text: product?.displayBadge ?? '',
    );
    final TextEditingController orderController = TextEditingController(
      text: '${product?.displayOrder ?? 0}',
    );
    final TextEditingController reorderController = TextEditingController(
      text: '${product?.reorderLevel ?? 3}',
    );
    final TextEditingController keywordController = TextEditingController(
      text: (product?.searchKeywords ?? const <String>[]).join(', '),
    );
    final TextEditingController aliasController = TextEditingController(
      text: (product?.legacyAliases ?? const <String>[]).join(', '),
    );
    final TextEditingController onHandController = TextEditingController(
      text: '0',
    );
    final TextEditingController sectionLabelController = TextEditingController(
      text: initialSection?.label ?? '',
    );
    String? selectedSectionId = product?.sectionId.isNotEmpty == true
        ? existingProduct?.sectionId
        : initialSection?.id;
    bool isVisibleInApp = product?.isVisibleInApp ?? true;
    bool isFeatured = product?.isFeatured ?? false;
    bool trackStock = product?.trackStock ?? true;
    bool isArchived = product?.isArchived ?? false;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Dialog(
              alignment: Alignment.centerRight,
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 720,
                  maxHeight: MediaQuery.of(context).size.height - 32,
                ),
                child: _SurfaceCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  isCreate
                                      ? 'Yeni ürün oluştur'
                                      : 'Ürünü düzenle',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  vendor.title,
                                  style: const TextStyle(color: _muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              _EditorSection(
                                title: 'Temel bilgi',
                                child: Column(
                                  children: <Widget>[
                                    DropdownButtonFormField<String>(
                                      initialValue:
                                          selectedSectionId != null &&
                                              vendor.sections.any(
                                                (SpetoCatalogSection section) =>
                                                    section.id ==
                                                    selectedSectionId,
                                              )
                                          ? selectedSectionId
                                          : null,
                                      items: vendor.sections
                                          .map(
                                            (SpetoCatalogSection section) =>
                                                DropdownMenuItem<String>(
                                                  value: section.id,
                                                  child: Text(section.label),
                                                ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (String? value) {
                                        setModalState(() {
                                          selectedSectionId = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Kategori / section',
                                      ),
                                    ),
                                    if (vendor.sections.isEmpty ||
                                        selectedSectionId == null) ...<Widget>[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: sectionLabelController,
                                        decoration: const InputDecoration(
                                          labelText: 'Yeni kategori adı',
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: titleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Ürün adı',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: descriptionController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: 'Açıklama',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _EditorSection(
                                title: 'Medya ve vitrin',
                                child: Column(
                                  children: <Widget>[
                                    TextField(
                                      controller: imageController,
                                      decoration: const InputDecoration(
                                        labelText: 'Fotoğraf URL',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: TextField(
                                            controller: subtitleController,
                                            decoration: const InputDecoration(
                                              labelText: 'Kısa açıklama',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: badgeController,
                                            decoration: const InputDecoration(
                                              labelText: 'Rozet',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _EditorSection(
                                title: 'Fiyat ve stok',
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: TextField(
                                            controller: priceController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Fiyat',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: categoryController,
                                            decoration: const InputDecoration(
                                              labelText: 'Kategori',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: TextField(
                                            controller: orderController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Sıra',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: reorderController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Kritik stok seviyesi',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isCreate) ...<Widget>[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: onHandController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Başlangıç stok adedi',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _EditorSection(
                                title: 'Entegrasyon kodları',
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: TextField(
                                            controller: skuController,
                                            decoration: const InputDecoration(
                                              labelText: 'SKU',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: barcodeController,
                                            decoration: const InputDecoration(
                                              labelText: 'Barkod',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: externalCodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Dış sistem kodu',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _EditorSection(
                                title: 'Görünürlük',
                                child: Column(
                                  children: <Widget>[
                                    TextField(
                                      controller: keywordController,
                                      decoration: const InputDecoration(
                                        labelText: 'Arama kelimeleri',
                                        helperText: 'Virgülle ayır',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: aliasController,
                                      decoration: const InputDecoration(
                                        labelText: 'Eski kimlik / alias',
                                        helperText: 'Virgülle ayır',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text(
                                        'Müşteri uygulamasında görünsün',
                                      ),
                                      value: isVisibleInApp,
                                      onChanged: (bool value) {
                                        setModalState(() {
                                          isVisibleInApp = value;
                                        });
                                      },
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Öne çıkan ürün'),
                                      value: isFeatured,
                                      onChanged: (bool value) {
                                        setModalState(() {
                                          isFeatured = value;
                                        });
                                      },
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Stok takibi açık'),
                                      value: trackStock,
                                      onChanged: (bool value) {
                                        setModalState(() {
                                          trackStock = value;
                                        });
                                      },
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Arşivlensin'),
                                      value: isArchived,
                                      onChanged: (bool value) {
                                        setModalState(() {
                                          isArchived = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Vazgeç'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(isCreate ? 'Ürünü oluştur' : 'Kaydet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    final Map<String, Object?> payload = <String, Object?>{
      'vendorId': vendor.vendorId,
      'catalogSectionId': selectedSectionId ?? '',
      'sectionLabel': sectionLabelController.text.trim(),
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'imageUrl': imageController.text.trim(),
      'unitPrice': double.tryParse(priceController.text) ?? 0,
      'category': categoryController.text.trim(),
      'sku': skuController.text.trim(),
      'barcode': barcodeController.text.trim(),
      'externalCode': externalCodeController.text.trim(),
      'displaySubtitle': subtitleController.text.trim(),
      'displayBadge': badgeController.text.trim(),
      'displayOrder': int.tryParse(orderController.text) ?? 0,
      'reorderLevel': int.tryParse(reorderController.text) ?? 0,
      'isVisibleInApp': isVisibleInApp,
      'isFeatured': isFeatured,
      'trackStock': trackStock,
      'isArchived': isArchived,
      'searchKeywords': keywordController.text.trim(),
      'legacyAliases': aliasController.text.trim(),
    };
    if (isCreate) {
      payload['onHand'] = int.tryParse(onHandController.text) ?? 0;
    }
    try {
      if (isCreate) {
        await widget.api.createCatalogProduct(payload);
      } else {
        await widget.api.updateCatalogProduct(existingProduct!.id, payload);
      }
      await _reload();
      if (mounted) {
        _showMessage(isCreate ? 'Yeni ürün oluşturuldu.' : 'Ürün güncellendi.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage(
        isCreate
            ? 'Ürün oluşturma zaman aşımına uğradı.'
            : 'Ürün güncellemesi zaman aşımına uğradı.',
        isError: true,
      );
    } catch (_) {
      _showMessage(
        isCreate ? 'Ürün oluşturulamadı.' : 'Ürün güncellenemedi.',
        isError: true,
      );
    }
  }

  Future<void> _editCatalogVendor(SpetoCatalogVendor vendor) async {
    final TextEditingController titleController = TextEditingController(
      text: vendor.title,
    );
    final TextEditingController subtitleController = TextEditingController(
      text: vendor.subtitle,
    );
    final TextEditingController metaController = TextEditingController(
      text: vendor.meta,
    );
    final TextEditingController badgeController = TextEditingController(
      text: vendor.badge,
    );
    final TextEditingController imageController = TextEditingController(
      text: vendor.image,
    );
    final TextEditingController rewardController = TextEditingController(
      text: vendor.rewardLabel,
    );
    final TextEditingController promoController = TextEditingController(
      text: vendor.promoLabel,
    );
    final TextEditingController workingHoursController = TextEditingController(
      text: vendor.workingHoursLabel,
    );
    final TextEditingController pickupLabelController = TextEditingController(
      text: vendor.pickupPoints.isNotEmpty
          ? vendor.pickupPoints.first.label
          : '',
    );
    final TextEditingController pickupAddressController = TextEditingController(
      text: vendor.pickupPoints.isNotEmpty
          ? vendor.pickupPoints.first.address
          : '',
    );
    final TextEditingController operatorNameController = TextEditingController(
      text: vendor.operatorAccounts.isNotEmpty
          ? vendor.operatorAccounts.first.displayName
          : '',
    );
    final TextEditingController operatorEmailController = TextEditingController(
      text: vendor.operatorAccounts.isNotEmpty
          ? vendor.operatorAccounts.first.email
          : '',
    );
    final TextEditingController operatorPasswordController =
        TextEditingController();
    final TextEditingController operatorPhoneController = TextEditingController(
      text: vendor.operatorAccounts.isNotEmpty
          ? vendor.operatorAccounts.first.phone
          : '',
    );
    final TextEditingController heroTitleController = TextEditingController(
      text: vendor.heroTitle,
    );
    final TextEditingController heroSubtitleController = TextEditingController(
      text: vendor.heroSubtitle,
    );
    final TextEditingController announcementController = TextEditingController(
      text: vendor.announcement,
    );
    final TextEditingController etaMinController = TextEditingController(
      text: '${vendor.etaMin}',
    );
    final TextEditingController etaMaxController = TextEditingController(
      text: '${vendor.etaMax}',
    );
    final TextEditingController ratingController = TextEditingController(
      text: vendor.ratingValue.toStringAsFixed(1),
    );
    bool isFeatured = vendor.isFeatured;
    bool isActive = vendor.isActive;
    bool studentFriendly = vendor.studentFriendly;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Mağaza vitrini ve erişim'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Mağaza adı',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Alt başlık',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: metaController,
                        decoration: const InputDecoration(
                          labelText: 'Meta satırı',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Kapak görseli URL',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: badgeController,
                              decoration: const InputDecoration(
                                labelText: 'Rozet',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: rewardController,
                              decoration: const InputDecoration(
                                labelText: 'Ödül etiketi',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: promoController,
                        decoration: const InputDecoration(
                          labelText: 'Kampanya etiketi',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: workingHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Çalışma saatleri',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: etaMinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min. süre',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: etaMaxController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Maks. süre',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: ratingController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Puan',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pickupLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Teslim noktası adı',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pickupAddressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Teslim noktası adresi',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: heroTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Hero başlığı',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: heroSubtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Hero alt başlığı',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: announcementController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Duyuru'),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Öğrenci dostu'),
                        value: studentFriendly,
                        onChanged: (bool value) {
                          setModalState(() {
                            studentFriendly = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Öne çıkan mağaza'),
                        value: isFeatured,
                        onChanged: (bool value) {
                          setModalState(() {
                            isFeatured = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aktif'),
                        value: isActive,
                        onChanged: (bool value) {
                          setModalState(() {
                            isActive = value;
                          });
                        },
                      ),
                      if (_isAdmin) ...<Widget>[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Mağaza giriş hesabı',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: operatorNameController,
                          decoration: const InputDecoration(
                            labelText: 'Yetkili adı',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: operatorEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Kullanıcı adı / e-posta',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: operatorPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Yeni şifre',
                            helperText: 'Boş bırakırsan mevcut şifre korunur',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: operatorPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.api.updateCatalogVendor(vendor.vendorId, <String, Object?>{
        'name': titleController.text.trim(),
        'subtitle': subtitleController.text.trim(),
        'meta': metaController.text.trim(),
        'imageUrl': imageController.text.trim(),
        'badge': badgeController.text.trim(),
        'rewardLabel': rewardController.text.trim(),
        'promoLabel': promoController.text.trim(),
        'workingHoursLabel': workingHoursController.text.trim(),
        'pickupPointLabel': pickupLabelController.text.trim(),
        'pickupPointAddress': pickupAddressController.text.trim(),
        'heroTitle': heroTitleController.text.trim(),
        'heroSubtitle': heroSubtitleController.text.trim(),
        'announcement': announcementController.text.trim(),
        'studentFriendly': studentFriendly,
        'isFeatured': isFeatured,
        'isActive': isActive,
        'etaMin': int.tryParse(etaMinController.text) ?? vendor.etaMin,
        'etaMax': int.tryParse(etaMaxController.text) ?? vendor.etaMax,
        'ratingValue':
            double.tryParse(ratingController.text) ?? vendor.ratingValue,
        if (_isAdmin) 'operatorDisplayName': operatorNameController.text.trim(),
        if (_isAdmin) 'operatorEmail': operatorEmailController.text.trim(),
        if (_isAdmin && operatorPasswordController.text.trim().isNotEmpty)
          'operatorPassword': operatorPasswordController.text.trim(),
        if (_isAdmin) 'operatorPhone': operatorPhoneController.text.trim(),
      });
      await _reload();
      if (mounted) {
        _showMessage('Mağaza bilgileri güncellendi.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage('Mağaza güncellemesi zaman aşımına uğradı.', isError: true);
    } catch (_) {
      _showMessage('Mağaza güncellenemedi.', isError: true);
    }
  }

  Future<void> _editCatalogSection(
    SpetoCatalogVendor vendor,
    SpetoCatalogSection section,
  ) async {
    final TextEditingController labelController = TextEditingController(
      text: section.label,
    );
    final TextEditingController orderController = TextEditingController(
      text: section.displayOrder.toString(),
    );
    bool isActive = section.isActive;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: Text('${vendor.title} • Kategori'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori adı',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sıra'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    value: isActive,
                    onChanged: (bool value) {
                      setModalState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.api.updateCatalogSection(section.id, <String, Object?>{
        'label': labelController.text.trim(),
        'displayOrder':
            int.tryParse(orderController.text) ?? section.displayOrder,
        'isActive': isActive,
      });
      await _reload();
      if (mounted) {
        _showMessage('Kategori güncellendi.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage(
        'Kategori güncellemesi zaman aşımına uğradı.',
        isError: true,
      );
    } catch (_) {
      _showMessage('Kategori güncellenemedi.', isError: true);
    }
  }

  Future<void> _editCatalogProduct(SpetoCatalogProduct product) async {
    final SpetoCatalogVendor? vendor = _findVendorById(product.vendorId);
    if (vendor == null) {
      _showMessage('Ürün için mağaza bilgisi bulunamadı.', isError: true);
      return;
    }
    await _openCatalogProductEditor(vendor: vendor, product: product);
  }

  Future<void> _editCatalogEvent(SpetoCatalogEvent event) async {
    final TextEditingController titleController = TextEditingController(
      text: event.title,
    );
    final TextEditingController venueController = TextEditingController(
      text: event.venue,
    );
    final TextEditingController primaryTagController = TextEditingController(
      text: event.primaryTag,
    );
    final TextEditingController secondaryTagController = TextEditingController(
      text: event.secondaryTag,
    );
    final TextEditingController pointsController = TextEditingController(
      text: event.pointsCost.toString(),
    );
    final TextEditingController remainingController = TextEditingController(
      text: event.remainingCount.toString(),
    );
    bool isFeatured = event.isFeatured;
    bool isActive = event.isActive;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Etkinlik düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Başlık'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(labelText: 'Mekân'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: primaryTagController,
                      decoration: const InputDecoration(
                        labelText: 'Birincil etiket',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: secondaryTagController,
                      decoration: const InputDecoration(
                        labelText: 'İkincil etiket',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Puan maliyeti',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remainingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kalan adet',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Öne çıkan'),
                      value: isFeatured,
                      onChanged: (bool value) {
                        setModalState(() {
                          isFeatured = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktif'),
                      value: isActive,
                      onChanged: (bool value) {
                        setModalState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.api.updateCatalogEvent(event.id, <String, Object?>{
        'title': titleController.text.trim(),
        'venue': venueController.text.trim(),
        'primaryTag': primaryTagController.text.trim(),
        'secondaryTag': secondaryTagController.text.trim(),
        'pointsCost': int.tryParse(pointsController.text) ?? event.pointsCost,
        'remainingCount':
            int.tryParse(remainingController.text) ?? event.remainingCount,
        'isFeatured': isFeatured,
        'isActive': isActive,
      });
      await _reload();
      if (mounted) {
        _showMessage('Etkinlik güncellendi.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage(
        'Etkinlik güncellemesi zaman aşımına uğradı.',
        isError: true,
      );
    } catch (_) {
      _showMessage('Etkinlik güncellenemedi.', isError: true);
    }
  }

  Future<void> _editContentBlock(SpetoCatalogContentBlock block) async {
    final TextEditingController titleController = TextEditingController(
      text: block.title,
    );
    final TextEditingController subtitleController = TextEditingController(
      text: block.subtitle,
    );
    final TextEditingController badgeController = TextEditingController(
      text: block.badge,
    );
    final TextEditingController actionController = TextEditingController(
      text: block.actionLabel,
    );
    final TextEditingController screenController = TextEditingController(
      text: block.screen,
    );
    final TextEditingController iconController = TextEditingController(
      text: block.iconKey,
    );
    final TextEditingController orderController = TextEditingController(
      text: block.displayOrder.toString(),
    );
    bool highlight = block.highlight;
    bool isActive = block.isActive;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('İçerik bloğu düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Başlık'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Alt başlık',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: badgeController,
                      decoration: const InputDecoration(labelText: 'Badge'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: actionController,
                      decoration: const InputDecoration(
                        labelText: 'Buton metni',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: screenController,
                      decoration: const InputDecoration(
                        labelText: 'Hedef ekran',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: iconController,
                      decoration: const InputDecoration(
                        labelText: 'İkon anahtarı',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sıra'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Highlight'),
                      value: highlight,
                      onChanged: (bool value) {
                        setModalState(() {
                          highlight = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktif'),
                      value: isActive,
                      onChanged: (bool value) {
                        setModalState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.api.updateCatalogContentBlock(block.id, <String, Object?>{
        'title': titleController.text.trim(),
        'subtitle': subtitleController.text.trim(),
        'badge': badgeController.text.trim(),
        'actionLabel': actionController.text.trim(),
        'screen': screenController.text.trim(),
        'iconKey': iconController.text.trim(),
        'displayOrder':
            int.tryParse(orderController.text) ?? block.displayOrder,
        'highlight': highlight,
        'isActive': isActive,
      });
      await _reload();
      if (mounted) {
        _showMessage('İçerik bloğu güncellendi.');
      }
    } on SpetoRemoteApiException catch (error) {
      _showMessage(_friendlyApiError(error), isError: true);
    } on TimeoutException {
      _showMessage(
        'İçerik bloğu güncellemesi zaman aşımına uğradı.',
        isError: true,
      );
    } catch (_) {
      _showMessage('İçerik bloğu güncellenemedi.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 980;
    final List<_NavItem> items = const <_NavItem>[
      _NavItem(
        'Gösterge',
        Icons.dashboard_customize_outlined,
        'Özet operasyon görünümü',
      ),
      _NavItem('Envanter', Icons.inventory_2_outlined, 'SKU ve stok masası'),
      _NavItem(
        'Operasyon',
        Icons.receipt_long_outlined,
        'Sipariş akış tahtası',
      ),
      _NavItem('Bağlantılar', Icons.hub_outlined, 'ERP ve POS kontrolü'),
      _NavItem(
        'Katalog',
        Icons.storefront_outlined,
        'Storefront içerik yönetimi',
      ),
    ];
    final _VendorScopeChoice? selectedVendorChoice = _vendorChoices
        .cast<_VendorScopeChoice?>()
        .firstWhere(
          (_VendorScopeChoice? choice) => choice?.id == _normalizedVendorId(),
          orElse: () => _vendorChoices.isEmpty ? null : _vendorChoices.first,
        );
    final String selectedVendorLabel =
        selectedVendorChoice?.label.isNotEmpty == true
        ? selectedVendorChoice!.label
        : 'Operasyon paneli';

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: _heroGradient),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: _AppBackdrop()),
            Row(
              children: <Widget>[
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                    child: _SidebarNav(
                      items: items,
                      selectedIndex: _index,
                      onSelected: (int value) {
                        setState(() {
                          _index = value;
                        });
                      },
                      session: widget.session,
                      selectedVendorLabel: selectedVendorLabel,
                      snapshot: _dashboard,
                    ),
                  ),
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 12 : 16,
                        compact ? 12 : 16,
                        compact ? 12 : 20,
                        compact ? 12 : 20,
                      ),
                      child: Column(
                        children: <Widget>[
                          _TopBar(
                            session: widget.session,
                            selectedVendorId: _normalizedVendorId(),
                            vendorChoices: _vendorChoices,
                            selectedVendorLabel: selectedVendorLabel,
                            onVendorChanged:
                                widget.session.role == SpetoUserRole.admin
                                ? (String? value) async {
                                    setState(() {
                                      _selectedVendorId = value;
                                    });
                                    await _reload();
                                  }
                                : null,
                            onRefresh: _reload,
                            onSignOut: widget.onSignOut,
                          ),
                          if (_warningMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _InlineBanner(
                                message: _warningMessage!,
                                color: _warning,
                                backgroundColor: _warningSoft,
                                icon: Icons.warning_amber_rounded,
                              ),
                            ),
                          Expanded(
                            child: _loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _error != null
                                ? _CenterStateMessage(
                                    title: 'Operasyon verisi alınamadı',
                                    description: _error!,
                                    icon: Icons.cloud_off_outlined,
                                  )
                                : IndexedStack(
                                    index: _index,
                                    children: <Widget>[
                                      _DashboardPage(
                                        vendorLabel: selectedVendorLabel,
                                        snapshot: _dashboard!,
                                        orders: _orders,
                                        integrations: _integrations,
                                        onNavigate: (int tabIndex) {
                                          setState(() {
                                            _index = tabIndex;
                                          });
                                        },
                                      ),
                                      _InventoryPage(
                                        items: _inventoryItems,
                                        selectedId: _selectedInventoryId,
                                        movements: _movements,
                                        onSelected: (String id) async {
                                          setState(() {
                                            _selectedInventoryId = id;
                                          });
                                          try {
                                            final List<SpetoInventoryMovement>
                                            movements = await widget.api
                                                .fetchInventoryMovements(
                                                  vendorId: _resolvedVendorId(),
                                                  productId: id,
                                                );
                                            if (!mounted) {
                                              return;
                                            }
                                            setState(() {
                                              _movements = movements;
                                            });
                                          } on SpetoRemoteApiException catch (
                                            error
                                          ) {
                                            _showMessage(
                                              _friendlyApiError(error),
                                              isError: true,
                                            );
                                          } on TimeoutException {
                                            _showMessage(
                                              'Hareket geçmişi zamanında yüklenemedi.',
                                              isError: true,
                                            );
                                          } catch (_) {
                                            _showMessage(
                                              'Hareket geçmişi yüklenemedi.',
                                              isError: true,
                                            );
                                          }
                                        },
                                        onAdjust: (SpetoInventoryItem item) =>
                                            _adjustInventory(item, false),
                                        onRestock: (SpetoInventoryItem item) =>
                                            _adjustInventory(item, true),
                                      ),
                                      _OrdersPage(
                                        orders: _orders,
                                        onAdvance: _changeOrderStatus,
                                      ),
                                      _IntegrationsPage(
                                        integrations: _integrations,
                                        onSync: _syncIntegration,
                                        onCreate: _createIntegration,
                                      ),
                                      _CatalogPage(
                                        session: widget.session,
                                        vendors: _catalogVendors,
                                        events: _catalogEvents,
                                        contentBlocks: _contentBlocks,
                                        onCreateVendor: _isAdmin
                                            ? _createCatalogVendor
                                            : null,
                                        onEditVendor: _editCatalogVendor,
                                        onCreateSection: _createCatalogSection,
                                        onEditSection: _editCatalogSection,
                                        onCreateProduct:
                                            ({
                                              required SpetoCatalogVendor
                                              vendor,
                                              SpetoCatalogSection? section,
                                            }) => _openCatalogProductEditor(
                                              vendor: vendor,
                                              initialSection: section,
                                            ),
                                        onEditProduct: _editCatalogProduct,
                                        onEditEvent: _editCatalogEvent,
                                        onEditContentBlock: _editContentBlock,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: compact
          ? SafeArea(
              top: false,
              left: false,
              right: false,
              minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: NavigationBar(
                selectedIndex: _index,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: items
                    .map(
                      (_NavItem item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ),
                    )
                    .toList(growable: false),
                onDestinationSelected: (int value) {
                  setState(() {
                    _index = value;
                  });
                },
              ),
            )
          : null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.session,
    required this.selectedVendorId,
    required this.vendorChoices,
    required this.selectedVendorLabel,
    required this.onVendorChanged,
    required this.onRefresh,
    required this.onSignOut,
  });

  final SpetoSession session;
  final String? selectedVendorId;
  final List<_VendorScopeChoice> vendorChoices;
  final String selectedVendorLabel;
  final ValueChanged<String?>? onVendorChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 880;
        final double vendorFieldWidth = compact ? constraints.maxWidth : 320;
        final Widget heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _StatusPill(
              label: compact ? _roleLabel(session.role) : selectedVendorLabel,
              color: _accent,
              backgroundColor: _accentSoft,
            ),
            const SizedBox(height: 12),
            Text(
              'Operasyon Merkezi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${session.displayName} • ${_roleLabel(session.role)} • Canlı operasyon paneli',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

        final List<Widget> controls = <Widget>[
          if (onVendorChanged != null)
            SizedBox(
              width: vendorFieldWidth,
              child: DropdownButtonFormField<String>(
                initialValue: selectedVendorId,
                isExpanded: true,
                selectedItemBuilder: (BuildContext context) {
                  return vendorChoices
                      .map(
                        (_VendorScopeChoice choice) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            choice.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                      .toList(growable: false);
                },
                items: vendorChoices
                    .map(
                      (_VendorScopeChoice choice) => DropdownMenuItem<String>(
                        value: choice.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                choice.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                choice.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onVendorChanged,
                decoration: const InputDecoration(
                  labelText: 'Çalışma kapsamı',
                  contentPadding: EdgeInsets.fromLTRB(16, 20, 16, 14),
                ),
              ),
            ),
          FilledButton.tonalIcon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yenile'),
          ),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Çıkış'),
          ),
        ];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SurfaceCard(
            padding: const EdgeInsets.all(20),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      heading,
                      const SizedBox(height: 16),
                      Wrap(spacing: 10, runSpacing: 10, children: controls),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      Expanded(child: heading),
                      const SizedBox(width: 16),
                      ...controls
                          .expand(
                            (Widget widget) => <Widget>[
                              widget,
                              const SizedBox(width: 10),
                            ],
                          )
                          .toList(growable: false)
                        ..removeLast(),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.vendorLabel,
    required this.snapshot,
    required this.orders,
    required this.integrations,
    required this.onNavigate,
  });

  final String vendorLabel;
  final SpetoInventorySnapshot snapshot;
  final List<SpetoOpsOrder> orders;
  final List<SpetoIntegrationConnection> integrations;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final List<SpetoInventoryItem> criticalItems = snapshot.items
        .where(
          (SpetoInventoryItem item) =>
              !item.stockStatus.isInStock || item.stockStatus.lowStock,
        )
        .take(5)
        .toList(growable: false);
    final List<SpetoIntegrationConnection> visibleIntegrations = integrations
        .take(4)
        .toList(growable: false);
    final int failedIntegrations = integrations
        .where(
          (SpetoIntegrationConnection integration) =>
              integration.health == SpetoIntegrationHealth.failed,
        )
        .length;
    final int warningIntegrations = integrations
        .where(
          (SpetoIntegrationConnection integration) =>
              integration.health == SpetoIntegrationHealth.warning,
        )
        .length;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 900;
        final List<Widget> metricCards = <Widget>[
          _MetricCard(
            compact: compact,
            emphasis: true,
            label: 'Satılabilir stok',
            value: '${snapshot.totalAvailableUnits}',
            caption: 'Bugün canlı satılabilir toplam adet',
            accent: _ink,
            icon: Icons.inventory_rounded,
          ),
          _MetricCard(
            compact: compact,
            label: 'Açık sipariş',
            value: '${snapshot.openOrdersCount}',
            caption: 'Anlık operasyon yükü',
            accent: _success,
            icon: Icons.receipt_long_rounded,
          ),
          _MetricCard(
            compact: compact,
            label: 'Kritik ürün',
            value: '${snapshot.lowStockCount}',
            caption: 'Yakın zamanda müdahale gerektirir',
            accent: _warning,
            icon: Icons.warning_amber_rounded,
          ),
          _MetricCard(
            compact: compact,
            label: 'Senkron alarmı',
            value: '${snapshot.integrationErrorCount}',
            caption: 'ERP / POS tarafında aksiyon bekliyor',
            accent: _danger,
            icon: Icons.hub_rounded,
            highlight: snapshot.integrationErrorCount > 0,
          ),
        ];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DashboardHero(
                compact: compact,
                vendorLabel: vendorLabel,
                snapshot: snapshot,
                failedIntegrations: failedIntegrations,
                warningIntegrations: warningIntegrations,
                onNavigate: onNavigate,
              ),
              const SizedBox(height: 18),
              if (compact)
                Column(
                  children: metricCards
                      .map(
                        (Widget card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                      )
                      .toList(growable: false),
                )
              else
                Wrap(spacing: 16, runSpacing: 16, children: metricCards),
              const SizedBox(height: 18),
              if (compact) ...<Widget>[
                _SectionCard(
                  title: 'Kritik ürünler',
                  subtitle:
                      'Stok seviyesi düşen veya satışa kapanan ürünleri ilk sırada görün.',
                  child: criticalItems.isEmpty
                      ? const _EmptyState(
                          title: 'Kritik ürün görünmüyor',
                          description:
                              'Şu an için stok alarmı üreten ürün yok. Yeni risk oluştuğunda burada öne çıkar.',
                          icon: Icons.inventory_2_outlined,
                        )
                      : Column(
                          children: criticalItems
                              .map(
                                (SpetoInventoryItem item) =>
                                    _CriticalProductRow(item: item),
                              )
                              .toList(growable: false),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Bağlantı sağlığı',
                  subtitle:
                      'Senkron kalitesi, son hata ve mapping kapsamı tek yerde.',
                  child: visibleIntegrations.isEmpty
                      ? const _EmptyState(
                          title: 'Bağlantı tanımı yok',
                          description:
                              'ERP veya POS bağlantısı oluşturulduğunda sağlık kartları burada görünür.',
                          icon: Icons.link_off_rounded,
                        )
                      : Column(
                          children: visibleIntegrations
                              .map(
                                (SpetoIntegrationConnection integration) =>
                                    _IntegrationHealthRow(
                                      integration: integration,
                                    ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 6,
                      child: _SectionCard(
                        title: 'Kritik ürünler',
                        subtitle:
                            'Kasa kapanmadan müdahale edilmesi gereken SKU listesi.',
                        child: criticalItems.isEmpty
                            ? const _EmptyState(
                                title: 'Kritik ürün görünmüyor',
                                description:
                                    'Şu an için stok alarmı üreten ürün yok. Yeni risk oluştuğunda burada öne çıkar.',
                                icon: Icons.inventory_2_outlined,
                              )
                            : Column(
                                children: criticalItems
                                    .map(
                                      (SpetoInventoryItem item) =>
                                          _CriticalProductRow(item: item),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _SectionCard(
                        title: 'Bağlantı sağlığı',
                        subtitle:
                            'Senkron durumu, işlenen kayıt ve mapping kapsamı.',
                        child: visibleIntegrations.isEmpty
                            ? const _EmptyState(
                                title: 'Bağlantı tanımı yok',
                                description:
                                    'ERP veya POS bağlantısı oluşturulduğunda sağlık kartları burada görünür.',
                                icon: Icons.link_off_rounded,
                              )
                            : Column(
                                children: visibleIntegrations
                                    .map(
                                      (
                                        SpetoIntegrationConnection integration,
                                      ) => _IntegrationHealthRow(
                                        integration: integration,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Sipariş akışı',
                subtitle:
                    'Hazırlık hattındaki siparişleri aşama ve hız riskiyle birlikte takip et.',
                trailing: orders.isEmpty
                    ? null
                    : _StatusPill(
                        label: '${orders.length} aktif iş',
                        color: _accent,
                        backgroundColor: _accentSoft,
                      ),
                child: orders.isEmpty
                    ? const _EmptyState(
                        title: 'Aktif sipariş bulunmuyor',
                        description:
                            'Yeni siparişler düştüğünde aşama zaman çizelgesi burada görünür.',
                        icon: Icons.schedule_rounded,
                      )
                    : Column(
                        children: orders
                            .take(6)
                            .map(
                              (SpetoOpsOrder order) =>
                                  _OrderTimelineRow(order: order),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InventoryPage extends StatefulWidget {
  const _InventoryPage({
    required this.items,
    required this.selectedId,
    required this.movements,
    required this.onSelected,
    required this.onAdjust,
    required this.onRestock,
  });

  final List<SpetoInventoryItem> items;
  final String? selectedId;
  final List<SpetoInventoryMovement> movements;
  final ValueChanged<String> onSelected;
  final ValueChanged<SpetoInventoryItem> onAdjust;
  final ValueChanged<SpetoInventoryItem> onRestock;

  @override
  State<_InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<_InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 1180;
    if (widget.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, 24),
        child: _SectionCard(
          title: 'Envanter',
          subtitle: 'Canlı stok kartları, detay akışı ve hareket geçmişi',
          child: _EmptyState(
            title: 'Ürün bulunamadı',
            description:
                'Seçili mağaza için stok kartı bulunmuyor. Stok girişi veya ürün eşlemesi sonrası burada listelenir.',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );
    }
    final List<SpetoInventoryItem> filteredItems = widget.items
        .where((SpetoInventoryItem item) {
          if (_query.trim().isEmpty) {
            return true;
          }
          final String haystack =
              '${item.title} ${item.category} ${item.sku} ${item.barcode} ${item.locationLabel}'
                  .toLowerCase();
          return haystack.contains(_query.trim().toLowerCase());
        })
        .toList(growable: false);
    final bool hasQuery = _query.trim().isNotEmpty;
    final List<SpetoInventoryItem> visibleItems = hasQuery
        ? filteredItems
        : widget.items;
    final SpetoInventoryItem? selected = visibleItems
        .cast<SpetoInventoryItem?>()
        .firstWhere(
          (SpetoInventoryItem? item) => item?.id == widget.selectedId,
          orElse: () => visibleItems.isNotEmpty ? visibleItems.first : null,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      child: compact
          ? ListView(
              children: <Widget>[
                _SectionCard(
                  title: 'Envanter çalışma alanı',
                  subtitle:
                      'Ürünleri ara, seç ve detay kartından stok müdahalesi yap.',
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _searchController,
                        onChanged: (String value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Ürün, SKU veya barkod ara',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (hasQuery && visibleItems.isEmpty)
                        const _EmptyState(
                          title: 'Aramaya uygun ürün yok',
                          description:
                              'Farklı bir ürün adı, SKU veya barkod ile tekrar dene.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        ...visibleItems.map((SpetoInventoryItem item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InventoryCard(
                              item: item,
                              selected: item.id == selected?.id,
                              movements: item.id == selected?.id
                                  ? widget.movements
                                  : const <SpetoInventoryMovement>[],
                              onTap: () => widget.onSelected(item.id),
                              onAdjust: () => widget.onAdjust(item),
                              onRestock: () => widget.onRestock(item),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: _SurfaceCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Ürün masası',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Filtrele, tablo benzeri listede tara ve detay paneline ak.',
                                    style: TextStyle(
                                      color: _muted,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StatusPill(
                              label: '${visibleItems.length} ürün',
                              color: _info,
                              backgroundColor: _infoSoft,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (String value) {
                                  setState(() {
                                    _query = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Ürün, SKU, barkod veya konum ara',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _InfoPill(
                              label:
                                  '${widget.items.where((SpetoInventoryItem item) => item.stockStatus.lowStock).length} kritik',
                            ),
                            const SizedBox(width: 8),
                            _InfoPill(
                              label: '${widget.items.length} toplam SKU',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: hasQuery && visibleItems.isEmpty
                              ? const _EmptyState(
                                  title: 'Aramaya uygun ürün yok',
                                  description:
                                      'Farklı bir ürün adı, SKU veya barkod ile tekrar dene.',
                                  icon: Icons.search_off_rounded,
                                )
                              : Column(
                                  children: <Widget>[
                                    const _InventoryTableHeader(),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: visibleItems.length,
                                        separatorBuilder: (_, int index) =>
                                            const SizedBox(height: 8),
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              final SpetoInventoryItem item =
                                                  visibleItems[index];
                                              return _InventoryTableRow(
                                                item: item,
                                                selected:
                                                    item.id == selected?.id,
                                                onTap: () =>
                                                    widget.onSelected(item.id),
                                              );
                                            },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: selected == null
                      ? const _CenterStateMessage(
                          title: 'Ürün seçilmedi',
                          description:
                              'Soldaki ürün masasından bir SKU seçildiğinde detay, fiyat, hareket ve entegrasyon bilgileri burada açılır.',
                          icon: Icons.touch_app_rounded,
                        )
                      : _InventoryDetailPanel(
                          item: selected,
                          movements: widget.movements,
                          onAdjust: () => widget.onAdjust(selected),
                          onRestock: () => widget.onRestock(selected),
                        ),
                ),
              ],
            ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.selected,
    required this.movements,
    required this.onTap,
    required this.onAdjust,
    required this.onRestock,
  });

  final SpetoInventoryItem item;
  final bool selected;
  final List<SpetoInventoryMovement> movements;
  final VoidCallback onTap;
  final VoidCallback onAdjust;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 430;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: _SurfaceCard(
            padding: const EdgeInsets.all(20),
            tint: selected ? _accentSoft.withValues(alpha: 0.35) : _panelStrong,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _ThumbImage(
                            imageUrl: item.imageUrl,
                            label: item.title,
                            size: 64,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.vendorName} • ${item.locationLabel}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: _muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatusPill(
                        label: _stockLabel(item.stockStatus),
                        color: _stockColor(item.stockStatus),
                        backgroundColor: _stockColor(
                          item.stockStatus,
                        ).withValues(alpha: 0.12),
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      _ThumbImage(
                        imageUrl: item.imageUrl,
                        label: item.title,
                        size: 64,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.vendorName} • ${item.locationLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(
                        label: _stockLabel(item.stockStatus),
                        color: _stockColor(item.stockStatus),
                        backgroundColor: _stockColor(
                          item.stockStatus,
                        ).withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _InfoPill(label: 'Fiziksel ${item.onHand}'),
                    _InfoPill(label: 'Rezerve ${item.reserved}'),
                    _InfoPill(label: 'Satılabilir ${item.availableQuantity}'),
                    _InfoPill(label: 'Kritik seviye ${item.reorderLevel}'),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: onAdjust,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Düzelt'),
                    ),
                    FilledButton.icon(
                      onPressed: onRestock,
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Stok girişi'),
                    ),
                  ],
                ),
                if (movements.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  Text(
                    'Hareket geçmişi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...movements.take(4).map((SpetoInventoryMovement movement) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_inventoryMovementLabel(movement.type)),
                      subtitle: Text(movement.createdAtLabel),
                      trailing: Text(
                        '${movement.quantityDelta >= 0 ? '+' : ''}${movement.quantityDelta}',
                        style: TextStyle(
                          color: movement.quantityDelta >= 0
                              ? _success
                              : _danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.orders, required this.onAdvance});

  final List<SpetoOpsOrder> orders;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, 24),
        child: _SectionCard(
          title: 'Operasyon kuyruğu',
          subtitle: 'Siparişleri aşama bazlı tahtadan yönet',
          child: _EmptyState(
            title: 'Sipariş kuyruğu boş',
            description:
                'Yeni siparişler operasyon akışına düştüğünde bu ekranda ilerletilebilir.',
            icon: Icons.inbox_rounded,
          ),
        ),
      );
    }
    final List<SpetoOpsOrderStage> columns = <SpetoOpsOrderStage>[
      SpetoOpsOrderStage.created,
      SpetoOpsOrderStage.accepted,
      SpetoOpsOrderStage.preparing,
      SpetoOpsOrderStage.ready,
      SpetoOpsOrderStage.completed,
    ];
    final Map<SpetoOpsOrderStage, List<SpetoOpsOrder>> grouped =
        <SpetoOpsOrderStage, List<SpetoOpsOrder>>{
          for (final SpetoOpsOrderStage stage in columns)
            stage: orders
                .where((SpetoOpsOrder order) => order.opsStatus == stage)
                .toList(growable: false),
        };
    final bool compact = MediaQuery.sizeOf(context).width < 780;
    final Widget compactBoard = _SectionCard(
      title: 'Operasyon tahtası',
      subtitle:
          'Siparişleri tek bakışta aşamaya, tempo riskine ve müşteri tipine göre ilerlet.',
      trailing: _StatusPill(
        label: '${orders.length} aktif sipariş',
        color: _accent,
        backgroundColor: _accentSoft,
      ),
      child: Column(
        children: columns
            .map(
              (SpetoOpsOrderStage stage) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MobileOrderStageSection(
                  stage: stage,
                  orders: grouped[stage]!,
                  onAdvance: onAdvance,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      child: compact
          ? SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 88),
              child: compactBoard,
            )
          : _SectionCard(
              title: 'Operasyon tahtası',
              subtitle:
                  'Siparişleri tek bakışta aşamaya, tempo riskine ve müşteri tipine göre ilerlet.',
              trailing: _StatusPill(
                label: '${orders.length} aktif sipariş',
                color: _accent,
                backgroundColor: _accentSoft,
              ),
              child: SizedBox(
                height: 640,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: columns
                        .map(
                          (SpetoOpsOrderStage stage) => Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _OrdersBoardColumn(
                              stage: stage,
                              orders: grouped[stage]!,
                              onAdvance: onAdvance,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
    );
  }
}

class _CatalogPage extends StatelessWidget {
  const _CatalogPage({
    required this.session,
    required this.vendors,
    required this.events,
    required this.contentBlocks,
    required this.onCreateVendor,
    required this.onEditVendor,
    required this.onCreateSection,
    required this.onEditSection,
    required this.onCreateProduct,
    required this.onEditProduct,
    required this.onEditEvent,
    required this.onEditContentBlock,
  });

  final SpetoSession session;
  final List<SpetoCatalogVendor> vendors;
  final List<SpetoCatalogEvent> events;
  final List<SpetoCatalogContentBlock> contentBlocks;
  final Future<void> Function()? onCreateVendor;
  final ValueChanged<SpetoCatalogVendor> onEditVendor;
  final Future<void> Function(SpetoCatalogVendor vendor) onCreateSection;
  final void Function(SpetoCatalogVendor, SpetoCatalogSection) onEditSection;
  final Future<void> Function({
    required SpetoCatalogVendor vendor,
    SpetoCatalogSection? section,
  })
  onCreateProduct;
  final ValueChanged<SpetoCatalogProduct> onEditProduct;
  final ValueChanged<SpetoCatalogEvent> onEditEvent;
  final ValueChanged<SpetoCatalogContentBlock> onEditContentBlock;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionCard(
            title: 'Storefront kontrol merkezi',
            subtitle:
                'Mağaza vitrini, kategori, ürün, operatör ve yayın görünürlüğünü tek ekrandan yönet.',
            trailing: onCreateVendor == null
                ? null
                : FilledButton.icon(
                    onPressed: onCreateVendor,
                    icon: const Icon(Icons.store_mall_directory_outlined),
                    label: const Text('Yeni mağaza / restoran'),
                  ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InfoPill(label: '${vendors.length} mağaza'),
                _InfoPill(
                  label:
                      '${vendors.expand((SpetoCatalogVendor vendor) => vendor.sections).length} kategori',
                ),
                _InfoPill(
                  label:
                      '${vendors.expand((SpetoCatalogVendor vendor) => vendor.sections).expand((SpetoCatalogSection section) => section.products).length} ürün',
                ),
                if (session.role == SpetoUserRole.admin)
                  _InfoPill(label: '${events.length} etkinlik'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Mağaza ve ürün kataloğu',
            subtitle:
                'Her mağaza kendi storefront yapısı, kategori akışı ve ürün yönetim alanıyla listelenir.',
            child: vendors.isEmpty
                ? const _EmptyState(
                    title: 'Mağaza bulunamadı',
                    description:
                        'Mağaza vitrini, kategori ve ürün düzenleme alanı burada listelenir.',
                    icon: Icons.storefront_outlined,
                  )
                : Column(
                    children: vendors
                        .map(
                          (SpetoCatalogVendor vendor) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CatalogVendorCard(
                              vendor: vendor,
                              onEditVendor: () => onEditVendor(vendor),
                              onCreateSection: () => onCreateSection(vendor),
                              onEditSection: (SpetoCatalogSection section) =>
                                  onEditSection(vendor, section),
                              onCreateProduct:
                                  ({
                                    required SpetoCatalogVendor vendor,
                                    SpetoCatalogSection? section,
                                  }) => onCreateProduct(
                                    vendor: vendor,
                                    section: section,
                                  ),
                              onEditProduct: onEditProduct,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          if (session.role == SpetoUserRole.admin) ...<Widget>[
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Etkinlik kataloğu',
              subtitle:
                  'Yalnız admin görünür. Müşteri uygulamasındaki deneyim akışı buradan yönetilir.',
              child: events.isEmpty
                  ? const _EmptyState(
                      title: 'Etkinlik kaydı yok',
                      description:
                          'Müşteri uygulamasında görünen deneyimler burada düzenlenir.',
                      icon: Icons.celebration_outlined,
                    )
                  : Column(
                      children: events
                          .map(
                            (SpetoCatalogEvent event) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${event.venue} • ${event.primaryTag} • ${event.pointsCost} puan',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _StatusPill(
                                    label: event.isActive ? 'AKTİF' : 'PASİF',
                                    color: event.isActive ? _success : _danger,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => onEditEvent(event),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Ana sayfa içerikleri',
              subtitle:
                  'Hero kartları, hızlı filtreler ve keşif blokları için hafif CMS katmanı.',
              child: contentBlocks.isEmpty
                  ? const _EmptyState(
                      title: 'İçerik bloğu yok',
                      description:
                          'Hero kartları, hızlı filtreler ve keşif blokları burada güncellenir.',
                      icon: Icons.dashboard_customize_outlined,
                    )
                  : Column(
                      children: contentBlocks
                          .map(
                            (SpetoCatalogContentBlock block) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                block.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${block.type.name} • ${block.screen.isEmpty ? 'atanmadı' : block.screen}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _StatusPill(
                                    label: block.isActive ? 'AKTİF' : 'PASİF',
                                    color: block.isActive ? _success : _danger,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => onEditContentBlock(block),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogVendorCard extends StatefulWidget {
  const _CatalogVendorCard({
    required this.vendor,
    required this.onEditVendor,
    required this.onCreateSection,
    required this.onEditSection,
    required this.onCreateProduct,
    required this.onEditProduct,
  });

  final SpetoCatalogVendor vendor;
  final VoidCallback onEditVendor;
  final VoidCallback onCreateSection;
  final ValueChanged<SpetoCatalogSection> onEditSection;
  final Future<void> Function({
    required SpetoCatalogVendor vendor,
    SpetoCatalogSection? section,
  })
  onCreateProduct;
  final ValueChanged<SpetoCatalogProduct> onEditProduct;

  @override
  State<_CatalogVendorCard> createState() => _CatalogVendorCardState();
}

class _CatalogVendorCardState extends State<_CatalogVendorCard> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 760;
    final SpetoCatalogVendor vendor = widget.vendor;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F1E1917),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _VendorHeader(
            vendor: vendor,
            compact: compact,
            onEditVendor: widget.onEditVendor,
            onCreateSection: widget.onCreateSection,
            onCreateProduct: () => widget.onCreateProduct(vendor: vendor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _VendorTabChip(
                  label: 'Vitrin',
                  selected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                _VendorTabChip(
                  label: 'Kategoriler',
                  selected: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                _VendorTabChip(
                  label: 'Ürünler',
                  selected: _tabIndex == 2,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
                _VendorTabChip(
                  label: 'Operatörler',
                  selected: _tabIndex == 3,
                  onTap: () => setState(() => _tabIndex = 3),
                ),
                _VendorTabChip(
                  label: 'Ayarlar',
                  selected: _tabIndex == 4,
                  onTap: () => setState(() => _tabIndex = 4),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: _buildTabContent(context, vendor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, SpetoCatalogVendor vendor) {
    switch (_tabIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InfoPill(
                  label: vendor.badge.isEmpty ? 'Rozet yok' : vendor.badge,
                ),
                _InfoPill(
                  label: vendor.promoLabel.isEmpty
                      ? 'Kampanya etiketi yok'
                      : vendor.promoLabel,
                ),
                _InfoPill(
                  label: vendor.announcement.isEmpty
                      ? 'Duyuru yok'
                      : vendor.announcement,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SurfaceCard(
              padding: const EdgeInsets.all(16),
              tint: _accentSoft.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    vendor.heroTitle.isEmpty ? vendor.title : vendor.heroTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendor.heroSubtitle.isEmpty
                        ? vendor.subtitle
                        : vendor.heroSubtitle,
                    style: const TextStyle(color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: vendor.highlights.isEmpty
                        ? <Widget>[
                            const _InfoPill(label: 'Highlight bulunmuyor'),
                          ]
                        : vendor.highlights
                              .map(
                                (SpetoCatalogVendorHighlight highlight) =>
                                    _InfoPill(label: highlight.label),
                              )
                              .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
        if (vendor.sections.isEmpty) {
          return const _EmptyState(
            title: 'Kategori yok',
            description:
                'Mağaza için section tanımı eklediğinde ürün akışı burada düzenlenir.',
            icon: Icons.category_outlined,
          );
        }
        return Column(
          children: vendor.sections
              .map(
                (SpetoCatalogSection section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final bool compact = constraints.maxWidth < 540;
                      return _SurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: compact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    section.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${section.products.length} ürün • sıra ${section.displayOrder}',
                                    style: const TextStyle(color: _muted),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      FilledButton.tonalIcon(
                                        onPressed: () => widget.onCreateProduct(
                                          vendor: vendor,
                                          section: section,
                                        ),
                                        icon: const Icon(
                                          Icons.add_box_outlined,
                                        ),
                                        label: const Text('Ürün ekle'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            widget.onEditSection(section),
                                        icon: const Icon(Icons.tune_rounded),
                                        label: const Text('Düzenle'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          section.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${section.products.length} ürün • sıra ${section.displayOrder}',
                                          style: const TextStyle(color: _muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: () => widget.onCreateProduct(
                                      vendor: vendor,
                                      section: section,
                                    ),
                                    icon: const Icon(Icons.add_box_outlined),
                                    label: const Text('Ürün ekle'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        widget.onEditSection(section),
                                    icon: const Icon(Icons.tune_rounded),
                                    label: const Text('Düzenle'),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              )
              .toList(growable: false),
        );
      case 2:
        final List<SpetoCatalogProduct> products = vendor.sections
            .expand((SpetoCatalogSection section) => section.products)
            .toList(growable: false);
        if (products.isEmpty) {
          return const _EmptyState(
            title: 'Ürün yok',
            description:
                'Yeni ürün oluşturulduğunda stok, görünürlük ve vitrin bilgileri burada listelenir.',
            icon: Icons.add_box_outlined,
          );
        }
        return Column(
          children: products
              .map(
                (SpetoCatalogProduct product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CatalogProductRow(
                    product: product,
                    onEditProduct: widget.onEditProduct,
                  ),
                ),
              )
              .toList(growable: false),
        );
      case 3:
        if (vendor.operatorAccounts.isEmpty) {
          return const _EmptyState(
            title: 'Operatör hesabı yok',
            description:
                'Bu mağazaya özel kullanıcı hesabı tanımlandığında burada görünür.',
            icon: Icons.manage_accounts_outlined,
          );
        }
        return Column(
          children: vendor.operatorAccounts
              .map(
                (SpetoCatalogOperatorAccount operator) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool compact = constraints.maxWidth < 520;
                          return _SurfaceCard(
                            padding: const EdgeInsets.all(16),
                            child: compact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          CircleAvatar(
                                            backgroundColor: _accentSoft,
                                            foregroundColor: _accentDeep,
                                            child: Text(
                                              operator.displayName.isEmpty
                                                  ? '?'
                                                  : operator
                                                        .displayName
                                                        .characters
                                                        .first
                                                        .toUpperCase(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  operator.displayName,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  operator.email,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: _muted,
                                                  ),
                                                ),
                                                if (operator.phone.isNotEmpty)
                                                  Text(
                                                    operator.phone,
                                                    style: const TextStyle(
                                                      color: _muted,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.tonalIcon(
                                        onPressed: widget.onEditVendor,
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Hesabı düzenle'),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        backgroundColor: _accentSoft,
                                        foregroundColor: _accentDeep,
                                        child: Text(
                                          operator.displayName.isEmpty
                                              ? '?'
                                              : operator
                                                    .displayName
                                                    .characters
                                                    .first
                                                    .toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              operator.displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              operator.email,
                                              style: const TextStyle(
                                                color: _muted,
                                              ),
                                            ),
                                            if (operator.phone.isNotEmpty)
                                              Text(
                                                operator.phone,
                                                style: const TextStyle(
                                                  color: _muted,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        onPressed: widget.onEditVendor,
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Hesabı düzenle'),
                                      ),
                                    ],
                                  ),
                          );
                        },
                  ),
                ),
              )
              .toList(growable: false),
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _StatusPill(
                  label: vendor.isActive ? 'Yayında' : 'Pasif',
                  color: vendor.isActive ? _success : _danger,
                  backgroundColor: vendor.isActive ? _successSoft : _dangerSoft,
                ),
                _StatusPill(
                  label: vendor.studentFriendly
                      ? 'Öğrenci dostu'
                      : 'Standart mağaza',
                  color: vendor.studentFriendly ? _info : _muted,
                  backgroundColor: vendor.studentFriendly
                      ? _infoSoft
                      : _accentSoft,
                ),
                _InfoPill(label: vendor.workingHoursLabel),
                _InfoPill(
                  label: vendor.pickupPoints.isEmpty
                      ? 'Pickup noktası yok'
                      : vendor.pickupPoints.first.address,
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: widget.onEditVendor,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Mağaza ayarlarını aç'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _IntegrationsPage extends StatelessWidget {
  const _IntegrationsPage({
    required this.integrations,
    required this.onSync,
    required this.onCreate,
  });

  final List<SpetoIntegrationConnection> integrations;
  final Future<void> Function(SpetoIntegrationConnection connection) onSync;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final int failedCount = integrations
        .where(
          (SpetoIntegrationConnection connection) =>
              connection.health == SpetoIntegrationHealth.failed,
        )
        .length;
    final int warningCount = integrations
        .where(
          (SpetoIntegrationConnection connection) =>
              connection.health == SpetoIntegrationHealth.warning,
        )
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      children: <Widget>[
        _SectionCard(
          title: 'Bağlantı merkezi',
          subtitle:
              'ERP ve POS bağlantılarının sağlık durumu, mapping kapsamı ve senkron yükü bu merkezden yönetilir.',
          trailing: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Entegrasyon ekle'),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _StatusPill(
                label: '${integrations.length} bağlantı',
                color: _info,
                backgroundColor: _infoSoft,
              ),
              _StatusPill(
                label: '$failedCount hata',
                color: _danger,
                backgroundColor: _dangerSoft,
              ),
              _StatusPill(
                label: '$warningCount uyarı',
                color: _warning,
                backgroundColor: _warningSoft,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (failedCount > 0 || warningCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _InlineBanner(
              message:
                  'Bağlantı merkezinde dikkat isteyen kayıtlar var. Hata veren sync, eksik SKU mapping ve stok uyuşmazlığı olan entegrasyonları önce inceleyin.',
              color: failedCount > 0 ? _danger : _warning,
              backgroundColor: failedCount > 0 ? _dangerSoft : _warningSoft,
              icon: failedCount > 0
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
            ),
          ),
        if (integrations.isEmpty)
          const _SectionCard(
            title: 'Entegrasyonlar',
            subtitle: 'Teknik bağlantılar bu alanda tutulur',
            child: _EmptyState(
              title: 'Bağlantı bulunamadı',
              description:
                  'Yeni bir ERP veya POS bağlantısı oluşturup ardından sync çalıştırabilirsiniz.',
              icon: Icons.link_off_rounded,
            ),
          ),
        ...integrations.map((SpetoIntegrationConnection connection) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionCard(
              title: connection.name,
              subtitle: '${connection.provider} • ${connection.baseUrl}',
              trailing: _StatusPill(
                label: _healthLabel(connection.health),
                color: _healthColor(connection.health),
                backgroundColor: switch (connection.health) {
                  SpetoIntegrationHealth.healthy => _successSoft,
                  SpetoIntegrationHealth.warning => _warningSoft,
                  SpetoIntegrationHealth.failed => _dangerSoft,
                },
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _InfoPill(
                        label: 'İşlenen ${connection.lastSync.processedCount}',
                      ),
                      _InfoPill(
                        label:
                            'Sync ${connection.lastSync.status.name.toUpperCase()}',
                      ),
                      _InfoPill(
                        label: '${connection.skuMappings.length} SKU eşleşmesi',
                      ),
                      _InfoPill(
                        label: connection.locationId.isEmpty
                            ? 'Lokasyon yok'
                            : connection.locationId,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Son sync: ${connection.lastSync.completedAtLabel.isEmpty ? '-' : connection.lastSync.completedAtLabel}',
                    style: const TextStyle(color: _muted),
                  ),
                  if (connection.lastSync.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        connection.lastSync.errorMessage,
                        style: const TextStyle(
                          color: _danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => onSync(connection),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync çalıştır'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compactHeader =
              trailing != null && constraints.maxWidth < 560;
          final Widget headerText = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(color: _muted, height: 1.5),
                ),
              ],
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (compactHeader)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    headerText,
                    const SizedBox(height: 12),
                    trailing!,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: headerText),
                    if (trailing != null) ...<Widget>[
                      const SizedBox(width: 12),
                      Flexible(child: trailing!),
                    ],
                  ],
                ),
              const SizedBox(height: 18),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tint,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? _panelStrong,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x121E1917),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AppBackdrop extends StatelessWidget {
  const _AppBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: GridPaper(
                color: _accentDeep,
                divisions: 2,
                interval: 48,
                subdivisions: 1,
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -40,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x33F6C986), Color(0x00F6C986)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -60,
            bottom: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x3354A36D), Color(0x0054A36D)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.message,
    required this.color,
    required this.backgroundColor,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _accentSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: _accentDeep, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CenterStateMessage extends StatelessWidget {
  const _CenterStateMessage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: _SurfaceCard(
          tint: _panel,
          child: _EmptyState(
            title: title,
            description: description,
            icon: icon,
          ),
        ),
      ),
    );
  }
}

class _SidebarNav extends StatelessWidget {
  const _SidebarNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.session,
    required this.selectedVendorLabel,
    required this.snapshot,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final SpetoSession session;
  final String selectedVendorLabel;
  final SpetoInventorySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 276,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _sidebar,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFF3B660), Color(0xFFC56B1A)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Speto Control',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedVendorLabel,
                  style: const TextStyle(
                    color: Color(0xFFE9DACA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.displayName} • ${_roleLabel(session.role)}',
                  style: const TextStyle(color: Color(0xFFB8AAA0)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (snapshot != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _SidebarMetric(
                      label: 'Sipariş',
                      value: '${snapshot!.openOrdersCount}',
                    ),
                  ),
                  Expanded(
                    child: _SidebarMetric(
                      label: 'Kritik',
                      value: '${snapshot!.lowStockCount}',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, int index) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final _NavItem item = items[index];
                final bool selected = index == selectedIndex;
                return InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: selected
                          ? Border.all(color: const Color(0x5CF3C27A))
                          : null,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0x26F6C986)
                                : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.icon,
                            color: selected
                                ? const Color(0xFFF4D7AA)
                                : const Color(0xFFD4C4B8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFFE8DCCF),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFFEADFCC)
                                      : const Color(0xFFAE9F95),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMetric extends StatelessWidget {
  const _SidebarMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB8AAA0),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.compact,
    required this.vendorLabel,
    required this.snapshot,
    required this.failedIntegrations,
    required this.warningIntegrations,
    required this.onNavigate,
  });

  final bool compact;
  final String vendorLabel;
  final SpetoInventorySnapshot snapshot;
  final int failedIntegrations;
  final int warningIntegrations;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF0D7), Color(0xFFE9F3E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFE2B7)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x141E1917),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Wrap(
        spacing: compact ? 14 : 18,
        runSpacing: compact ? 14 : 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compact ? double.infinity : 520,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _StatusPill(
                  label: vendorLabel,
                  color: _accentDeep,
                  backgroundColor: Colors.white.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 14),
                Text(
                  'Bugünün operasyon temposu net: sipariş yükü, stok riski ve bağlantı sağlığı aynı yüzeyde.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: compact ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Öncelikli aksiyonlar: kritik stoklu SKU\'ları kapat, hazır siparişleri tahsilata geçir ve hata veren entegrasyonları sync et.',
                  style: TextStyle(color: _muted, height: 1.6),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => onNavigate(1),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Envantere git'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => onNavigate(2),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Sipariş tahtası'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => onNavigate(3),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Bağlantı merkezi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compact ? double.infinity : 320,
              minWidth: compact ? 0 : 280,
            ),
            child: Column(
              children: <Widget>[
                _HeroStatTile(
                  label: 'Açık sipariş',
                  value: '${snapshot.openOrdersCount}',
                  color: _success,
                ),
                const SizedBox(height: 10),
                _HeroStatTile(
                  label: 'Kritik stok',
                  value: '${snapshot.lowStockCount + snapshot.outOfStockCount}',
                  color: _warning,
                ),
                const SizedBox(height: 10),
                _HeroStatTile(
                  label: 'Sync alarmı',
                  value: '${failedIntegrations + warningIntegrations}',
                  color: failedIntegrations > 0 ? _danger : _info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
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

class _CriticalProductRow extends StatelessWidget {
  const _CriticalProductRow({required this.item});

  final SpetoInventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 430;
          return _SurfaceCard(
            padding: const EdgeInsets.all(14),
            tint: Colors.white,
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _ThumbImage(
                            imageUrl: item.imageUrl,
                            label: item.title,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.category} • ${item.sku}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: _muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _StatusPill(
                            label: _stockLabel(item.stockStatus),
                            color: _stockColor(item.stockStatus),
                            backgroundColor: _stockColor(
                              item.stockStatus,
                            ).withValues(alpha: 0.12),
                          ),
                          Text(
                            '${item.availableQuantity} adet',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      _ThumbImage(imageUrl: item.imageUrl, label: item.title),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.category} • ${item.sku}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          _StatusPill(
                            label: _stockLabel(item.stockStatus),
                            color: _stockColor(item.stockStatus),
                            backgroundColor: _stockColor(
                              item.stockStatus,
                            ).withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.availableQuantity} adet',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _IntegrationHealthRow extends StatelessWidget {
  const _IntegrationHealthRow({required this.integration});

  final SpetoIntegrationConnection integration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 430;
          return _SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: _infoSoft,
                            foregroundColor: _info,
                            child: Text(
                              integration.provider.isEmpty
                                  ? '?'
                                  : integration.provider.characters.first
                                        .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  integration.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  integration.provider,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: _muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatusPill(
                        label: _healthLabel(integration.health),
                        color: _healthColor(integration.health),
                        backgroundColor: _healthColor(
                          integration.health,
                        ).withValues(alpha: 0.12),
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: _infoSoft,
                        foregroundColor: _info,
                        child: Text(
                          integration.provider.isEmpty
                              ? '?'
                              : integration.provider.characters.first
                                    .toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              integration.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              integration.provider,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(
                        label: _healthLabel(integration.health),
                        color: _healthColor(integration.health),
                        backgroundColor: _healthColor(
                          integration.health,
                        ).withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoPill(
                      label: '${integration.skuMappings.length} eşleşme',
                    ),
                    _InfoPill(
                      label:
                          'Son durum ${integration.lastSync.status.name.toUpperCase()}',
                    ),
                    _InfoPill(
                      label: 'İşlenen ${integration.lastSync.processedCount}',
                    ),
                  ],
                ),
                if (integration.lastSync.errorMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    integration.lastSync.errorMessage,
                    style: const TextStyle(
                      color: _danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderTimelineRow extends StatelessWidget {
  const _OrderTimelineRow({required this.order});

  final SpetoOpsOrder order;

  @override
  Widget build(BuildContext context) {
    final Color stageColor = order.opsStatus == SpetoOpsOrderStage.completed
        ? _success
        : order.opsStatus == SpetoOpsOrderStage.cancelled
        ? _danger
        : _accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 12,
              height: 72,
              decoration: BoxDecoration(
                color: stageColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${order.vendor} • ${order.pickupCode}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.items.isEmpty
                        ? order.placedAtLabel
                        : '${order.items.first.title} • ${order.placedAtLabel}',
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _StatusPill(
                        label: _opsStageLabel(order.opsStatus),
                        color: stageColor,
                        backgroundColor: stageColor.withValues(alpha: 0.12),
                      ),
                      _InfoPill(label: order.deliveryMode),
                      _InfoPill(label: order.paymentMethod),
                    ],
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

class _InventoryTableHeader extends StatelessWidget {
  const _InventoryTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _accentSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: <Widget>[
          SizedBox(width: 64, child: Text('Ürün')),
          Expanded(flex: 3, child: Text('Ad / kategori')),
          Expanded(flex: 2, child: Text('Stok')),
          Expanded(flex: 2, child: Text('Eşik / fiyat')),
          Expanded(flex: 2, child: Text('Görünürlük')),
          Expanded(flex: 2, child: Text('Konum')),
        ],
      ),
    );
  }
}

class _InventoryTableRow extends StatelessWidget {
  const _InventoryTableRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SpetoInventoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected ? _accent : _line;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accentSoft.withValues(alpha: 0.45) : _panelStrong,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 64,
              child: _ThumbImage(imageUrl: item.imageUrl, label: item.title),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category} • ${item.sku}',
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${item.availableQuantity} / ${item.onHand}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${item.reorderLevel} kritik • ${item.unitPrice.toStringAsFixed(0)} TL',
                style: const TextStyle(color: _muted),
              ),
            ),
            Expanded(
              flex: 2,
              child: _StatusPill(
                label: item.isArchived
                    ? 'Arşiv'
                    : item.stockStatus.canPurchase
                    ? 'Açık'
                    : 'Kapalı',
                color: item.isArchived
                    ? _muted
                    : item.stockStatus.canPurchase
                    ? _success
                    : _warning,
                backgroundColor: item.isArchived
                    ? _accentSoft
                    : item.stockStatus.canPurchase
                    ? _successSoft
                    : _warningSoft,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.locationLabel.isEmpty ? 'Belirsiz' : item.locationLabel,
                style: const TextStyle(color: _muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryDetailPanel extends StatelessWidget {
  const _InventoryDetailPanel({
    required this.item,
    required this.movements,
    required this.onAdjust,
    required this.onRestock,
  });

  final SpetoInventoryItem item;
  final List<SpetoInventoryMovement> movements;
  final VoidCallback onAdjust;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.category} • ${item.sku} • ${item.locationLabel.isEmpty ? 'Konum yok' : item.locationLabel}',
                      style: const TextStyle(color: _muted, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(
                label: _stockLabel(item.stockStatus),
                color: _stockColor(item.stockStatus),
                backgroundColor: _stockColor(
                  item.stockStatus,
                ).withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _ThumbImage(imageUrl: item.imageUrl, label: item.title, size: 84),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoPill(
                      label: 'Fiyat ${item.unitPrice.toStringAsFixed(0)} TL',
                    ),
                    _InfoPill(
                      label:
                          'Barkod ${item.barcode.isEmpty ? '-' : item.barcode}',
                    ),
                    _InfoPill(
                      label:
                          'Dış kod ${item.externalCode.isEmpty ? '-' : item.externalCode}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onAdjust,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Manuel düzelt'),
              ),
              FilledButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Stok girişi'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DefaultTabController(
            length: 5,
            child: Expanded(
              child: Column(
                children: <Widget>[
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: <Widget>[
                      Tab(text: 'Genel'),
                      Tab(text: 'Stok'),
                      Tab(text: 'Fiyat ve görünürlük'),
                      Tab(text: 'Hareket geçmişi'),
                      Tab(text: 'Entegrasyon'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        ListView(
                          children: <Widget>[
                            _DetailInfoRow(
                              label: 'Ürün adı',
                              value: item.title,
                            ),
                            _DetailInfoRow(
                              label: 'Açıklama',
                              value: item.description,
                            ),
                            _DetailInfoRow(
                              label: 'Kategori',
                              value: item.category,
                            ),
                            _DetailInfoRow(label: 'SKU', value: item.sku),
                            _DetailInfoRow(
                              label: 'Konum',
                              value: item.locationLabel,
                            ),
                          ],
                        ),
                        ListView(
                          children: <Widget>[
                            _DetailInfoRow(
                              label: 'Fiziksel stok',
                              value: '${item.onHand}',
                            ),
                            _DetailInfoRow(
                              label: 'Rezerve',
                              value: '${item.reserved}',
                            ),
                            _DetailInfoRow(
                              label: 'Satılabilir',
                              value: '${item.availableQuantity}',
                            ),
                            _DetailInfoRow(
                              label: 'Kritik seviye',
                              value: '${item.reorderLevel}',
                            ),
                            _DetailInfoRow(
                              label: 'Takip modu',
                              value: item.trackStock ? 'Açık' : 'Kapalı',
                            ),
                          ],
                        ),
                        ListView(
                          children: <Widget>[
                            _DetailInfoRow(
                              label: 'Fiyat',
                              value: '${item.unitPrice.toStringAsFixed(0)} TL',
                            ),
                            _DetailInfoRow(
                              label: 'Müşteri görünürlüğü',
                              value: item.stockStatus.canPurchase
                                  ? 'Satışa açık'
                                  : 'Satışa kapalı',
                            ),
                            _DetailInfoRow(
                              label: 'Arşiv durumu',
                              value: item.isArchived ? 'Arşivde' : 'Aktif',
                            ),
                          ],
                        ),
                        movements.isEmpty
                            ? const _EmptyState(
                                title: 'Hareket kaydı yok',
                                description:
                                    'Bu ürün için henüz envanter hareketi görünmüyor.',
                                icon: Icons.timeline_rounded,
                              )
                            : ListView(
                                children: movements
                                    .map(
                                      (
                                        SpetoInventoryMovement movement,
                                      ) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          _inventoryMovementLabel(
                                            movement.type,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${movement.createdAtLabel}${movement.note.isEmpty ? '' : ' • ${movement.note}'}',
                                        ),
                                        trailing: Text(
                                          '${movement.quantityDelta >= 0 ? '+' : ''}${movement.quantityDelta}',
                                          style: TextStyle(
                                            color: movement.quantityDelta >= 0
                                                ? _success
                                                : _danger,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                        ListView(
                          children: <Widget>[
                            _DetailInfoRow(
                              label: 'Dış sistem kodu',
                              value: item.externalCode.isEmpty
                                  ? 'Tanımsız'
                                  : item.externalCode,
                            ),
                            _DetailInfoRow(
                              label: 'Barkod',
                              value: item.barcode.isEmpty
                                  ? 'Tanımsız'
                                  : item.barcode,
                            ),
                            _DetailInfoRow(
                              label: 'Lokasyon ID',
                              value: item.locationId.isEmpty
                                  ? '-'
                                  : item.locationId,
                            ),
                          ],
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
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersBoardColumn extends StatelessWidget {
  const _OrdersBoardColumn({
    required this.stage,
    required this.orders,
    required this.onAdvance,
  });

  final SpetoOpsOrderStage stage;
  final List<SpetoOpsOrder> orders;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  Widget build(BuildContext context) {
    final Color tone = switch (stage) {
      SpetoOpsOrderStage.completed => _success,
      SpetoOpsOrderStage.cancelled => _danger,
      SpetoOpsOrderStage.ready => _info,
      SpetoOpsOrderStage.preparing => _warning,
      SpetoOpsOrderStage.accepted => _accent,
      SpetoOpsOrderStage.created => _ink,
    };
    return SizedBox(
      width: 320,
      child: _SurfaceCard(
        tint: _panel,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _StatusPill(
                  label: _opsStageLabel(stage),
                  color: tone,
                  backgroundColor: tone.withValues(alpha: 0.12),
                ),
                const Spacer(),
                Text(
                  '${orders.length} sipariş',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: orders.isEmpty
                  ? const _EmptyState(
                      title: 'Kuyruk boş',
                      description: 'Bu aşamada bekleyen sipariş görünmüyor.',
                      icon: Icons.low_priority_rounded,
                    )
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, int index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final SpetoOpsOrder order = orders[index];
                        final List<SpetoOpsOrderStage> actions = _nextOpsStages(
                          order.opsStatus,
                        );
                        return _SurfaceCard(
                          padding: const EdgeInsets.all(16),
                          tint: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      order.pickupCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _InfoPill(label: order.deliveryMode),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.vendor,
                                style: const TextStyle(color: _muted),
                              ),
                              const SizedBox(height: 12),
                              ...order.items.take(2).map((SpetoCartItem item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.title}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item.unitPrice.toStringAsFixed(0)} TL',
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _InfoPill(label: order.paymentMethod),
                                  _InfoPill(label: order.placedAtLabel),
                                ],
                              ),
                              if (actions.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: actions
                                      .map(
                                        (SpetoOpsOrderStage nextStage) =>
                                            FilledButton.tonal(
                                              onPressed: () =>
                                                  onAdvance(order, nextStage),
                                              child: Text(
                                                _opsStageLabel(nextStage),
                                              ),
                                            ),
                                      )
                                      .toList(growable: false),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileOrderStageSection extends StatelessWidget {
  const _MobileOrderStageSection({
    required this.stage,
    required this.orders,
    required this.onAdvance,
  });

  final SpetoOpsOrderStage stage;
  final List<SpetoOpsOrder> orders;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  Widget build(BuildContext context) {
    final Color tone = switch (stage) {
      SpetoOpsOrderStage.completed => _success,
      SpetoOpsOrderStage.cancelled => _danger,
      SpetoOpsOrderStage.ready => _info,
      SpetoOpsOrderStage.preparing => _warning,
      SpetoOpsOrderStage.accepted => _accent,
      SpetoOpsOrderStage.created => _ink,
    };
    return _SurfaceCard(
      tint: _panel,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatusPill(
                  label: _opsStageLabel(stage),
                  color: tone,
                  backgroundColor: tone.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${orders.length} sipariş',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const _EmptyState(
              title: 'Kuyruk boş',
              description: 'Bu aşamada bekleyen sipariş görünmüyor.',
              icon: Icons.low_priority_rounded,
            )
          else
            Column(
              children: orders
                  .map(
                    (SpetoOpsOrder order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MobileOrderCard(
                        order: order,
                        onAdvance: onAdvance,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  const _MobileOrderCard({required this.order, required this.onAdvance});

  final SpetoOpsOrder order;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  Widget build(BuildContext context) {
    final List<SpetoOpsOrderStage> actions = _nextOpsStages(order.opsStatus);
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      tint: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  order.pickupCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              _InfoPill(label: order.deliveryMode),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.vendor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 12),
          ...order.items.take(2).map((SpetoCartItem item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item.unitPrice.toStringAsFixed(0)} TL'),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(label: order.paymentMethod),
              _InfoPill(label: order.placedAtLabel),
            ],
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map(
                    (SpetoOpsOrderStage nextStage) => FilledButton.tonal(
                      onPressed: () => onAdvance(order, nextStage),
                      child: Text(_opsStageLabel(nextStage)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _VendorHeader extends StatelessWidget {
  const _VendorHeader({
    required this.vendor,
    required this.compact,
    required this.onEditVendor,
    required this.onCreateSection,
    required this.onCreateProduct,
  });

  final SpetoCatalogVendor vendor;
  final bool compact;
  final VoidCallback onEditVendor;
  final VoidCallback onCreateSection;
  final VoidCallback onCreateProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: vendor.storefrontType == SpetoStorefrontType.market
            ? const LinearGradient(
                colors: <Color>[Color(0xFFEAF7F0), Color(0xFFFFF4E6)],
              )
            : const LinearGradient(
                colors: <Color>[Color(0xFFFFF0D8), Color(0xFFFFF8F0)],
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 18,
          runSpacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _ThumbImage(imageUrl: vendor.image, label: vendor.title, size: 92),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: compact ? double.infinity : 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _StatusPill(
                        label: _storefrontLabel(vendor.storefrontType),
                        color: _info,
                        backgroundColor: _infoSoft,
                      ),
                      _StatusPill(
                        label: vendor.isActive ? 'Yayında' : 'Pasif',
                        color: vendor.isActive ? _success : _danger,
                        backgroundColor: vendor.isActive
                            ? _successSoft
                            : _dangerSoft,
                      ),
                      _StatusPill(
                        label: _stockLabel(vendor.stockStatus),
                        color: _stockColor(vendor.stockStatus),
                        backgroundColor: _stockColor(
                          vendor.stockStatus,
                        ).withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vendor.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vendor.subtitle.isEmpty ? vendor.meta : vendor.subtitle,
                    style: const TextStyle(color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      if (vendor.badge.isNotEmpty)
                        _InfoPill(label: vendor.badge),
                      if (vendor.promoLabel.isNotEmpty)
                        _InfoPill(label: vendor.promoLabel),
                      if (vendor.rewardLabel.isNotEmpty)
                        _InfoPill(label: vendor.rewardLabel),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: onEditVendor,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Vitrin'),
                ),
                OutlinedButton.icon(
                  onPressed: onCreateSection,
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('Kategori ekle'),
                ),
                FilledButton.icon(
                  onPressed: onCreateProduct,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Yeni ürün'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorTabChip extends StatelessWidget {
  const _VendorTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _accentSoft,
      labelStyle: TextStyle(
        color: selected ? _accentDeep : _ink,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: _line),
    );
  }
}

class _CatalogProductRow extends StatelessWidget {
  const _CatalogProductRow({
    required this.product,
    required this.onEditProduct,
  });

  final SpetoCatalogProduct product;
  final ValueChanged<SpetoCatalogProduct> onEditProduct;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 460;
        return _SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _ThumbImage(
                          imageUrl: product.imageUrl,
                          label: product.title,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${product.sectionLabel} • ${product.sku}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _InfoPill(label: product.priceText),
                        _InfoPill(
                          label: product.isVisibleInApp
                              ? 'Uygulamada açık'
                              : 'Gizli',
                        ),
                        if (product.displayBadge.isNotEmpty)
                          _InfoPill(label: product.displayBadge),
                        _StatusPill(
                          label: _stockLabel(product.stockStatus),
                          color: _stockColor(product.stockStatus),
                          backgroundColor: _stockColor(
                            product.stockStatus,
                          ).withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => onEditProduct(product),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Düzenle'),
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    _ThumbImage(
                      imageUrl: product.imageUrl,
                      label: product.title,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${product.sectionLabel} • ${product.sku}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _InfoPill(label: product.priceText),
                              _InfoPill(
                                label: product.isVisibleInApp
                                    ? 'Uygulamada açık'
                                    : 'Gizli',
                              ),
                              if (product.displayBadge.isNotEmpty)
                                _InfoPill(label: product.displayBadge),
                              _StatusPill(
                                label: _stockLabel(product.stockStatus),
                                color: _stockColor(product.stockStatus),
                                backgroundColor: _stockColor(
                                  product.stockStatus,
                                ).withValues(alpha: 0.12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => onEditProduct(product),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Düzenle'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ThumbImage extends StatelessWidget {
  const _ThumbImage({
    required this.imageUrl,
    required this.label,
    this.size = 56,
  });

  final String imageUrl;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => _thumbFallback(),
        ),
      );
    }
    return _thumbFallback();
  }

  Widget _thumbFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isEmpty ? '?' : label.characters.first.toUpperCase(),
        style: TextStyle(
          color: _accentDeep,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    this.compact = false,
    this.accent = _ink,
    this.icon = Icons.auto_graph_rounded,
    this.emphasis = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String caption;
  final bool compact;
  final Color accent;
  final IconData icon;
  final bool emphasis;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      width: compact ? double.infinity : (emphasis ? 320 : 248),
      tint: highlight ? _dangerSoft : _panelStrong,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 26 : (emphasis ? 34 : 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(caption, style: const TextStyle(color: _muted, height: 1.5)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.sizeOf(context).width < 560
        ? MediaQuery.sizeOf(context).width * 0.72
        : 320;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.sizeOf(context).width < 560
        ? MediaQuery.sizeOf(context).width * 0.72
        : 320;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _VendorScopeChoice {
  const _VendorScopeChoice({
    required this.id,
    required this.label,
    required this.caption,
  });

  final String id;
  final String label;
  final String caption;
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.description);

  final String label;
  final IconData icon;
  final String description;
}
