import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

enum _StockDestination {
  dashboard,
  reports,
  orders,
  products,
  campaigns,
  revenue,
  help,
  account,
}

enum _OrderQueueFilter { all, fresh, preparing, ready, delivered, cancelled }

enum _OrderDateFilter { all, today }

LinearGradient get _heroGradient => const LinearGradient(
  colors: <Color>[Color(0xFFF8F8F4), Color(0xFFF4F6EF), Color(0xFFF8F5F0)],
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

String _ordersStageLabel(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => 'Yeni',
    SpetoOpsOrderStage.accepted ||
    SpetoOpsOrderStage.preparing => 'Hazırlanıyor',
    SpetoOpsOrderStage.ready => 'Hazır',
    SpetoOpsOrderStage.completed => 'Tamamlandı',
    SpetoOpsOrderStage.cancelled => 'İptal',
  };
}

Color _ordersStageColor(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.created => _success,
    SpetoOpsOrderStage.accepted || SpetoOpsOrderStage.preparing => _warning,
    SpetoOpsOrderStage.ready => _accent,
    SpetoOpsOrderStage.completed => _info,
    SpetoOpsOrderStage.cancelled => _danger,
  };
}

String _orderActionLabel(SpetoOpsOrderStage stage) {
  return switch (stage) {
    SpetoOpsOrderStage.accepted => 'Siparişi Onayla',
    SpetoOpsOrderStage.preparing => 'Hazırlamaya Başla',
    SpetoOpsOrderStage.ready => 'Hazırlandı',
    SpetoOpsOrderStage.completed => 'Teslim Edildi',
    SpetoOpsOrderStage.cancelled => 'Siparişi İptal Et',
    SpetoOpsOrderStage.created => 'Güncelle',
  };
}

String _formatCurrency(double value) {
  final String fixed = value.toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  return '₺${parts.first},${parts.last}';
}

DateTime? _parseOrderPlacedAt(SpetoOpsOrder order) {
  final Match? match = RegExp(
    r'(\d{2})\.(\d{2})\.(\d{4})\s*•\s*(\d{2}):(\d{2})',
  ).firstMatch(order.placedAtLabel);
  if (match == null) {
    return null;
  }
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}

bool _isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _orderTimeLabel(SpetoOpsOrder order) {
  final List<String> parts = order.placedAtLabel.split('•');
  if (parts.length > 1) {
    return parts[1].trim();
  }
  return order.placedAtLabel;
}

String _orderDateLabel(SpetoOpsOrder order) {
  final DateTime? placedAt = _parseOrderPlacedAt(order);
  if (placedAt == null) {
    return order.placedAtLabel;
  }
  return _isSameCalendarDay(placedAt, DateTime.now())
      ? 'Bugün'
      : '${placedAt.day.toString().padLeft(2, '0')}.${placedAt.month.toString().padLeft(2, '0')}.${placedAt.year}';
}

String _orderReference(SpetoOpsOrder order) {
  if (order.pickupCode.trim().isNotEmpty) {
    return order.pickupCode.trim().toUpperCase();
  }
  final String normalized = order.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (normalized.isEmpty) {
    return '0000';
  }
  return normalized
      .substring(0, normalized.length < 6 ? normalized.length : 6)
      .toUpperCase();
}

String _orderItemsSummary(SpetoOpsOrder order, {int maxItems = 2}) {
  if (order.items.isEmpty) {
    return 'Ürün bilgisi yok';
  }
  return order.items
      .take(maxItems)
      .map((SpetoCartItem item) => item.title)
      .join(' + ');
}

class SpetoStockApp extends StatefulWidget {
  const SpetoStockApp({super.key});

  @override
  State<SpetoStockApp> createState() => _SpetoStockAppState();
}

class _SpetoStockAppState extends State<SpetoStockApp> {
  static const String _sessionStorageKey = 'stock_app.session';

  SpetoRemoteDomainApi? _api;
  SpetoSession? _session;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _bootstrapApi();
  }

  Future<void> _bootstrapApi() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      SpetoSession? session = _readStoredSession(prefs);
      final SpetoRemoteApiClient client =
          await SpetoRemoteApiClient.resolveDefault(session: session);
      final SpetoRemoteDomainApi api = SpetoRemoteDomainApi(client);
      client.setSessionChangedCallback((SpetoSession? nextSession) async {
        await _persistStoredSession(prefs!, nextSession);
        if (!mounted) {
          return;
        }
        setState(() {
          _session = nextSession;
        });
      });
      if (session != null) {
        try {
          if (session.authToken.trim().isEmpty ||
              session.refreshToken.trim().isEmpty) {
            session = null;
            await _persistStoredSession(prefs, null);
          } else if (api.shouldRefreshSession() ||
              session.authToken.trim().isEmpty) {
            session = await api.refreshSession(
              refreshToken: session.refreshToken,
              notifyListeners: false,
            );
            await _persistStoredSession(prefs, session);
          }
        } catch (_) {
          session = null;
          await _persistStoredSession(prefs, null);
          api.clearSession();
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _prefs = prefs;
        _api = api;
        _session = session;
      });
    } catch (_) {
      await prefs?.remove(_sessionStorageKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _session = null;
      });
    }
  }

  SpetoSession? _readStoredSession(SharedPreferences prefs) {
    final String? raw = prefs.getString(_sessionStorageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return SpetoSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistStoredSession(
    SharedPreferences prefs,
    SpetoSession? session,
  ) async {
    if (session == null) {
      await prefs.remove(_sessionStorageKey);
      return;
    }
    await prefs.setString(_sessionStorageKey, jsonEncode(session.toJson()));
  }

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
    final SpetoRemoteDomainApi? api = _api;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SepetPro İşyeri',
      theme: theme,
      home: api == null
          ? const _BootScreen()
          : _session == null
          ? _LoginScreen(
              api: api,
              onLoggedIn: (SpetoSession session) {
                final SharedPreferences? prefs = _prefs;
                if (prefs != null) {
                  unawaited(_persistStoredSession(prefs, session));
                }
                setState(() {
                  _session = session;
                });
              },
            )
          : _StockShell(
              api: api,
              session: _session!,
              onSignOut: () {
                final SpetoSession? currentSession = _session;
                final SharedPreferences? prefs = _prefs;
                unawaited(() async {
                  try {
                    await api.logout(
                      refreshToken: currentSession?.refreshToken,
                    );
                  } catch (_) {
                    api.clearSession();
                  }
                  if (prefs != null) {
                    await _persistStoredSession(prefs, null);
                  }
                }());
                setState(() {
                  _session = null;
                });
              },
            ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    return 'Giriş başarısız. Lütfen gerçek operatör bilgilerinizi kontrol edin.';
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
                            'SepetPro İşyeri',
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _StockDestination _destination = _StockDestination.dashboard;
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
  List<SpetoHappyHourOffer> _offers = <SpetoHappyHourOffer>[];
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

  void _selectDestination(_StockDestination destination) {
    setState(() {
      _destination = destination;
    });
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
      'Anasayfa',
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
    final List<SpetoHappyHourOffer> offers =
        await _safeLoad(
          'Kampanyalar',
          () => widget.api.fetchHappyHourOffers(),
          warnings,
        ) ??
        const <SpetoHappyHourOffer>[];
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
        offers.isNotEmpty ||
        catalogVendors.isNotEmpty ||
        catalogEvents.isNotEmpty ||
        contentBlocks.isNotEmpty;

    setState(() {
      _dashboard = resolvedSnapshot;
      _inventoryItems = inventory;
      _orders = orders;
      _integrations = integrations;
      _offers = offers;
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
        TextEditingController();
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
          _destination = _StockDestination.products;
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
    final List<_NavItem> drawerItems = const <_NavItem>[
      _NavItem(
        'Satış Raporları',
        Icons.insert_chart_outlined_rounded,
        'Ciro, adet ve tempo özeti',
        _StockDestination.reports,
      ),
      _NavItem(
        'Tüm Siparişler',
        Icons.receipt_long_outlined,
        'Yeni, hazır ve teslim edilen siparişler',
        _StockDestination.orders,
      ),
      _NavItem(
        'Ürün Yönetimi',
        Icons.inventory_2_outlined,
        'Stok ve vitrin akışını yönet',
        _StockDestination.products,
      ),
      _NavItem(
        'Kampanyalar',
        Icons.local_offer_outlined,
        'Aktif fırsatlar ve vitrin teklifleri',
        _StockDestination.campaigns,
      ),
      _NavItem(
        'Gelir ve Ödemeler',
        Icons.account_balance_wallet_outlined,
        'Tahsilat ve ödeme kırılımları',
        _StockDestination.revenue,
      ),
      _NavItem(
        'Yardım Merkezi',
        Icons.support_agent_outlined,
        'Operasyon rehberi ve destek notları',
        _StockDestination.help,
      ),
    ];
    final List<_NavItem> bottomItems = const <_NavItem>[
      _NavItem(
        'Anasayfa',
        Icons.home_rounded,
        'Genel operasyon özeti',
        _StockDestination.dashboard,
      ),
      _NavItem(
        'Siparişler',
        Icons.receipt_long_outlined,
        'Canlı sipariş akışı',
        _StockDestination.orders,
      ),
      _NavItem(
        'Ürünler',
        Icons.inventory_2_outlined,
        'Stok ve ürün yönetimi',
        _StockDestination.products,
      ),
      _NavItem(
        'Kampanya',
        Icons.local_offer_outlined,
        'Aktif teklif ve fırsatlar',
        _StockDestination.campaigns,
      ),
      _NavItem(
        'Hesap',
        Icons.person_outline_rounded,
        'Profil ve erişim bilgileri',
        _StockDestination.account,
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
    final String? selectedVendorId = _normalizedVendorId();
    final SpetoCatalogVendor? selectedVendor = selectedVendorId == null
        ? null
        : _findVendorById(selectedVendorId);
    final SpetoInventorySnapshot? dashboardSnapshot = _dashboard;
    final List<SpetoHappyHourOffer> visibleOffers = _offers
        .where(
          (SpetoHappyHourOffer offer) =>
              selectedVendorId == null || offer.vendorId == selectedVendorId,
        )
        .toList(growable: false);
    final Widget currentPage = switch (_destination) {
      _StockDestination.dashboard when dashboardSnapshot != null =>
        _DashboardPage(
          vendorLabel: selectedVendorLabel,
          snapshot: dashboardSnapshot,
          orders: _orders,
          integrations: _integrations,
          onNavigate: _selectDestination,
        ),
      _StockDestination.reports when dashboardSnapshot != null =>
        _SalesReportsPage(
          vendorLabel: selectedVendorLabel,
          snapshot: dashboardSnapshot,
          orders: _orders,
        ),
      _StockDestination.dashboard ||
      _StockDestination.reports => const _CenterStateMessage(
        title: 'Anasayfa hazırlanıyor',
        description:
            'Özet metrikler yeniden yüklenirken birkaç saniye bekleyin.',
        icon: Icons.home_rounded,
      ),
      _StockDestination.orders => _OrdersPage(
        orders: _orders,
        onAdvance: _changeOrderStatus,
      ),
      _StockDestination.products => _ProductsManagementPage(
        session: widget.session,
        items: _inventoryItems,
        selectedId: _selectedInventoryId,
        movements: _movements,
        vendors: _catalogVendors,
        events: _catalogEvents,
        contentBlocks: _contentBlocks,
        onSelected: (String id) async {
          setState(() {
            _selectedInventoryId = id;
          });
          try {
            final List<SpetoInventoryMovement> movements = await widget.api
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
          } on SpetoRemoteApiException catch (error) {
            _showMessage(_friendlyApiError(error), isError: true);
          } on TimeoutException {
            _showMessage(
              'Hareket geçmişi zamanında yüklenemedi.',
              isError: true,
            );
          } catch (_) {
            _showMessage('Hareket geçmişi yüklenemedi.', isError: true);
          }
        },
        onAdjust: (SpetoInventoryItem item) => _adjustInventory(item, false),
        onRestock: (SpetoInventoryItem item) => _adjustInventory(item, true),
        onCreateVendor: _isAdmin ? _createCatalogVendor : null,
        onEditVendor: _editCatalogVendor,
        onCreateSection: _createCatalogSection,
        onEditSection: _editCatalogSection,
        onCreateProduct:
            ({
              required SpetoCatalogVendor vendor,
              SpetoCatalogSection? section,
            }) => _openCatalogProductEditor(
              vendor: vendor,
              initialSection: section,
            ),
        onEditProduct: _editCatalogProduct,
        onEditEvent: _editCatalogEvent,
        onEditContentBlock: _editContentBlock,
      ),
      _StockDestination.campaigns => _CampaignsPage(
        vendorLabel: selectedVendorLabel,
        offers: visibleOffers,
        onNavigate: _selectDestination,
      ),
      _StockDestination.revenue => _RevenuePaymentsPage(
        orders: _orders,
        integrations: _integrations,
        onSync: _syncIntegration,
        onCreate: _createIntegration,
      ),
      _StockDestination.help => _HelpCenterPage(
        vendorLabel: selectedVendorLabel,
        session: widget.session,
      ),
      _StockDestination.account => _AccountPage(
        session: widget.session,
        vendorLabel: selectedVendorLabel,
        selectedVendor: selectedVendor,
        vendors: _catalogVendors,
        integrations: _integrations,
        orders: _orders,
        snapshot: _dashboard,
        offers: visibleOffers,
        onSignOut: widget.onSignOut,
      ),
    };

    return Scaffold(
      key: _scaffoldKey,
      drawer: compact
          ? Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  child: _SidebarNav(
                    items: drawerItems,
                    selectedDestination: _destination,
                    onSelected: _selectDestination,
                    session: widget.session,
                    selectedVendorLabel: selectedVendorLabel,
                    snapshot: _dashboard,
                    drawerMode: true,
                  ),
                ),
              ),
            )
          : null,
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
                      items: drawerItems,
                      selectedDestination: _destination,
                      onSelected: _selectDestination,
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
                          if (compact &&
                              _destination != _StockDestination.account)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                    maximumSize: const Size(44, 44),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () =>
                                      _scaffoldKey.currentState?.openDrawer(),
                                  icon: const Icon(Icons.menu_rounded),
                                ),
                              ),
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
                                : currentPage,
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
              minimum: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                _destination == _StockDestination.account ? 4 : 8,
              ),
              child: _GlassBottomNavBar(
                items: bottomItems,
                selectedDestination: _destination,
                onSelected: _selectDestination,
              ),
            )
          : null,
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
  final ValueChanged<_StockDestination> onNavigate;

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
        final List<SpetoOpsOrder> recentOrders = orders
            .take(compact ? 4 : 5)
            .toList(growable: false);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(4, 4, 4, compact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _OpsPageIntroCard(
                compact: compact,
                icon: Icons.home_rounded,
                title: 'Ana sayfa',
                subtitle:
                    '$vendorLabel operasyonu için sipariş, stok ve bağlantı sağlığını tek yerden izle.',
                tone: _success,
                trailing: _StatusPill(
                  label: '${snapshot.openOrdersCount} açık sipariş',
                  color: _success,
                  backgroundColor: _successSoft,
                ),
                badges: <Widget>[
                  _OpsInlineStat(
                    label: 'Hazır stok',
                    value: '${snapshot.totalAvailableUnits}',
                    tone: _success,
                  ),
                  _OpsInlineStat(
                    label: 'Kritik SKU',
                    value:
                        '${snapshot.lowStockCount + snapshot.outOfStockCount}',
                    tone: _warning,
                  ),
                  _OpsInlineStat(
                    label: 'Sync alarmı',
                    value: '${failedIntegrations + warningIntegrations}',
                    tone: failedIntegrations > 0 ? _danger : _info,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ResponsiveCardGrid(
                minItemWidth: compact ? 156 : 210,
                children: <Widget>[
                  _SummaryStatCard(
                    label: 'Satılabilir stok',
                    value: '${snapshot.totalAvailableUnits}',
                    tone: _success,
                    note: 'Canlı satışa açık toplam birim',
                  ),
                  _SummaryStatCard(
                    label: 'Açık sipariş',
                    value: '${snapshot.openOrdersCount}',
                    tone: _info,
                    note: 'Hazırlık ve teslim akışındaki iş yükü',
                  ),
                  _SummaryStatCard(
                    label: 'Kritik ürün',
                    value: '${snapshot.lowStockCount}',
                    tone: _warning,
                    note: 'Yakında müdahale gerektiren stok kartı',
                  ),
                  _SummaryStatCard(
                    label: 'Senkron alarmı',
                    value: '${snapshot.integrationErrorCount}',
                    tone: snapshot.integrationErrorCount > 0
                        ? _danger
                        : _success,
                    note: 'Bağlantı veya eşleşme kaynaklı bekleyen konu',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Hızlı erişim',
                subtitle:
                    'Operasyon sırasında en sık açılan ekranlara tek dokunuşla geç.',
                child: Column(
                  children: <Widget>[
                    _DetailListTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sipariş kuyruğu',
                      subtitle: 'Yeni ve hazırlanan siparişleri yönet',
                      iconTone: _success,
                      onTap: () => onNavigate(_StockDestination.orders),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: _line.withValues(alpha: 0.7),
                      indent: 68,
                      endIndent: 18,
                    ),
                    _DetailListTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Ürün ve stok',
                      subtitle: 'Kritik SKU, stok düzeltme ve giriş akışını aç',
                      iconTone: _success,
                      onTap: () => onNavigate(_StockDestination.products),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: _line.withValues(alpha: 0.7),
                      indent: 68,
                      endIndent: 18,
                    ),
                    _DetailListTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Gelir ve ödemeler',
                      subtitle: 'Tahsilat ve ödeme yöntemi dağılımını izle',
                      iconTone: _success,
                      onTap: () => onNavigate(_StockDestination.revenue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (compact) ...<Widget>[
                _SectionCard(
                  title: 'Kritik ürünler',
                  subtitle: 'Öncelikli müdahale bekleyen stok listesi.',
                  trailing: criticalItems.isEmpty
                      ? null
                      : _InfoPill(
                          label: '${criticalItems.length} SKU',
                          compact: true,
                        ),
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
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Bağlantı sağlığı',
                  subtitle: 'POS ve ERP akışının canlı durum görünümü.',
                  trailing: visibleIntegrations.isEmpty
                      ? null
                      : _InfoPill(
                          label: '${visibleIntegrations.length} bağlantı',
                          compact: true,
                        ),
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
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Canlı sipariş görünümü',
                subtitle: compact
                    ? 'Hazırlık ve teslim akışındaki son operasyonlar.'
                    : 'Yeni açılan siparişleri teslim süreciyle birlikte takip et.',
                trailing: orders.isEmpty
                    ? null
                    : _StatusPill(
                        label: '${orders.length} aktif iş',
                        color: _success,
                        backgroundColor: _successSoft,
                      ),
                child: orders.isEmpty
                    ? const _EmptyState(
                        title: 'Aktif sipariş bulunmuyor',
                        description:
                            'Yeni siparişler düştüğünde aşama zaman çizelgesi burada görünür.',
                        icon: Icons.schedule_rounded,
                      )
                    : Column(
                        children: recentOrders
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
    final int lowStockCount = widget.items
        .where((SpetoInventoryItem item) => item.stockStatus.lowStock)
        .length;
    final int purchasableCount = widget.items
        .where(
          (SpetoInventoryItem item) =>
              item.stockStatus.canPurchase && !item.isArchived,
        )
        .length;
    final int archivedCount = widget.items
        .where((SpetoInventoryItem item) => item.isArchived)
        .length;
    if (widget.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
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
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: compact
          ? LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 0
                          ? constraints.maxHeight
                          : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SurfaceCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const <Widget>[
                                        Text(
                                          'Stok ve ürünler',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Ürünleri ara, stok durumunu kontrol et ve hızlı müdahale uygula.',
                                          style: TextStyle(
                                            color: _muted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _StatusPill(
                                    label: '${visibleItems.length} SKU',
                                    color: _success,
                                    backgroundColor: _successSoft,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
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
                              const SizedBox(height: 14),
                              _ResponsiveCardGrid(
                                minItemWidth: 136,
                                children: <Widget>[
                                  _CompactMetricTile(
                                    label: 'Kritik stok',
                                    value: '$lowStockCount',
                                    tone: _warning,
                                  ),
                                  _CompactMetricTile(
                                    label: 'Satışa açık',
                                    value: '$purchasableCount',
                                    tone: _success,
                                  ),
                                  _CompactMetricTile(
                                    label: 'Arşivde',
                                    value: '$archivedCount',
                                    tone: _muted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (hasQuery && visibleItems.isEmpty)
                          const _EmptyState(
                            title: 'Aramaya uygun ürün yok',
                            description:
                                'Farklı bir ürün adı, SKU veya barkod ile tekrar dene.',
                            icon: Icons.search_off_rounded,
                          )
                        else
                          Column(
                            children: visibleItems
                                .map((SpetoInventoryItem item) {
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
                                })
                                .toList(growable: false),
                          ),
                      ],
                    ),
                  ),
                );
              },
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
        final Color stockTone = _stockColor(item.stockStatus);
        final List<SpetoInventoryMovement> recentMovements = movements
            .take(3)
            .toList(growable: false);
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: _SurfaceCard(
            padding: EdgeInsets.all(compact ? 18 : 20),
            tint: selected
                ? _successSoft.withValues(alpha: 0.48)
                : _panelStrong,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ThumbImage(
                      imageUrl: item.imageUrl,
                      label: item.title,
                      size: compact ? 66 : 72,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: compact ? 20 : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.vendorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _StatusPill(
                                label: _stockLabel(item.stockStatus),
                                color: stockTone,
                                backgroundColor: stockTone.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              _InfoPill(
                                label:
                                    '${item.unitPrice.toStringAsFixed(0)} TL',
                                compact: true,
                              ),
                              _InfoPill(
                                label: item.locationLabel.isEmpty
                                    ? 'Konum yok'
                                    : item.locationLabel,
                                compact: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (item.isArchived) ...<Widget>[
                      const SizedBox(width: 12),
                      const _StatusPill(
                        label: 'Arşiv',
                        color: _muted,
                        backgroundColor: _accentSoft,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _ResponsiveCardGrid(
                  minItemWidth: compact ? 128 : 150,
                  children: <Widget>[
                    _CompactMetricTile(
                      label: 'Fiziksel',
                      value: '${item.onHand}',
                      tone: _info,
                    ),
                    _CompactMetricTile(
                      label: 'Satılabilir',
                      value: '${item.availableQuantity}',
                      tone: _success,
                    ),
                    _CompactMetricTile(
                      label: 'Rezerve',
                      value: '${item.reserved}',
                      tone: _warning,
                    ),
                    _CompactMetricTile(
                      label: 'Kritik seviye',
                      value: '${item.reorderLevel}',
                      tone: _accent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAdjust,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Düzelt'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onRestock,
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Stok girişi'),
                      ),
                    ),
                  ],
                ),
                if (recentMovements.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _line.withValues(alpha: 0.8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Expanded(
                              child: Text(
                                'Son hareketler',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            _InfoPill(
                              label: '${recentMovements.length} kayıt',
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List<Widget>.generate(recentMovements.length, (
                          int index,
                        ) {
                          final SpetoInventoryMovement movement =
                              recentMovements[index];
                          final bool positive = movement.quantityDelta >= 0;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == recentMovements.length - 1
                                  ? 0
                                  : 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _inventoryMovementLabel(movement.type),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        movement.createdAtLabel,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${positive ? '+' : ''}${movement.quantityDelta}',
                                  style: TextStyle(
                                    color: positive ? _success : _danger,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdersPage extends StatefulWidget {
  const _OrdersPage({required this.orders, required this.onAdvance});

  final List<SpetoOpsOrder> orders;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage>
    with SingleTickerProviderStateMixin {
  static const List<(_OrderQueueFilter, String)> _filters =
      <(_OrderQueueFilter, String)>[
        (_OrderQueueFilter.all, 'Tümü'),
        (_OrderQueueFilter.fresh, 'Yeni'),
        (_OrderQueueFilter.preparing, 'Hazırlanıyor'),
        (_OrderQueueFilter.ready, 'Hazır'),
        (_OrderQueueFilter.delivered, 'Tamamlandı'),
        (_OrderQueueFilter.cancelled, 'İptal'),
      ];

  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  String _query = '';
  _OrderDateFilter _dateFilter = _OrderDateFilter.all;
  String? _paymentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted || _tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  List<String> get _paymentOptions {
    final LinkedHashSet<String> methods = LinkedHashSet<String>.from(
      widget.orders
          .map((SpetoOpsOrder order) => order.paymentMethod.trim())
          .where((String value) => value.isNotEmpty),
    );
    return methods.toList(growable: false);
  }

  int get _currentTabIndex {
    final int index = _tabController.index;
    if (index < 0) {
      return 0;
    }
    if (index >= _filters.length) {
      return _filters.length - 1;
    }
    return index;
  }

  _OrderQueueFilter get _currentFilter => _filters[_currentTabIndex].$1;

  int get _activeFilterCount {
    int count = 0;
    if (_dateFilter != _OrderDateFilter.all) {
      count += 1;
    }
    if (_paymentFilter != null) {
      count += 1;
    }
    return count;
  }

  bool _matchesSearch(SpetoOpsOrder order, String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }
    final String haystack = <String>[
      order.vendor,
      order.id,
      order.pickupCode,
      order.deliveryAddress,
      order.paymentMethod,
      order.promoCode,
      ...order.items.map((SpetoCartItem item) => item.title),
    ].join(' ').toLowerCase();
    return haystack.contains(normalizedQuery);
  }

  bool _matchesBaseFilters(
    SpetoOpsOrder order,
    String normalizedQuery,
    DateTime today,
  ) {
    if (!_matchesSearch(order, normalizedQuery)) {
      return false;
    }
    if (_paymentFilter != null && order.paymentMethod != _paymentFilter) {
      return false;
    }
    if (_dateFilter == _OrderDateFilter.today) {
      final DateTime? placedAt = _parseOrderPlacedAt(order);
      if (placedAt == null || !_isSameCalendarDay(placedAt, today)) {
        return false;
      }
    }
    return true;
  }

  bool _matchesStatusFilter(SpetoOpsOrder order, _OrderQueueFilter filter) {
    return switch (filter) {
      _OrderQueueFilter.all => true,
      _OrderQueueFilter.fresh => order.opsStatus == SpetoOpsOrderStage.created,
      _OrderQueueFilter.preparing =>
        order.opsStatus == SpetoOpsOrderStage.accepted ||
            order.opsStatus == SpetoOpsOrderStage.preparing,
      _OrderQueueFilter.ready => order.opsStatus == SpetoOpsOrderStage.ready,
      _OrderQueueFilter.delivered =>
        order.opsStatus == SpetoOpsOrderStage.completed ||
            order.status == SpetoOrderStatus.completed,
      _OrderQueueFilter.cancelled =>
        order.opsStatus == SpetoOpsOrderStage.cancelled ||
            order.status == SpetoOrderStatus.cancelled,
    };
  }

  List<SpetoOpsOrder> _filteredOrders(_OrderQueueFilter filter) {
    final String normalizedQuery = _query.trim().toLowerCase();
    final DateTime today = DateTime.now();
    final List<SpetoOpsOrder> filtered = widget.orders.where((
      SpetoOpsOrder order,
    ) {
      return _matchesBaseFilters(order, normalizedQuery, today) &&
          _matchesStatusFilter(order, filter);
    }).toList();
    filtered.sort((SpetoOpsOrder a, SpetoOpsOrder b) {
      final DateTime? left = _parseOrderPlacedAt(a);
      final DateTime? right = _parseOrderPlacedAt(b);
      if (left == null || right == null) {
        return 0;
      }
      return right.compareTo(left);
    });
    return filtered;
  }

  void _openOrderHistory() {
    final int deliveredIndex = _filters.indexWhere(
      (((_OrderQueueFilter, String) entry) =>
          entry.$1 == _OrderQueueFilter.delivered),
    );
    if (deliveredIndex >= 0) {
      _tabController.animateTo(deliveredIndex);
    }
  }

  void _openAllOrders() {
    final int allIndex = _filters.indexWhere(
      (((_OrderQueueFilter, String) entry) =>
          entry.$1 == _OrderQueueFilter.all),
    );
    if (allIndex >= 0) {
      _tabController.animateTo(allIndex);
    }
  }

  int _todayOrdersCount() {
    final DateTime today = DateTime.now();
    return _filteredOrders(_OrderQueueFilter.all).where((SpetoOpsOrder order) {
      final DateTime? placedAt = _parseOrderPlacedAt(order);
      return placedAt != null && _isSameCalendarDay(placedAt, today);
    }).length;
  }

  int _activeOrdersCount() {
    return _filteredOrders(_OrderQueueFilter.all)
        .where((SpetoOpsOrder order) => order.status == SpetoOrderStatus.active)
        .length;
  }

  String _sectionTitle(_OrderQueueFilter filter) {
    return switch (filter) {
      _OrderQueueFilter.all => 'Tüm Siparişler',
      _OrderQueueFilter.fresh => 'Yeni Siparişler',
      _OrderQueueFilter.preparing => 'Hazırlanan Siparişler',
      _OrderQueueFilter.ready => 'Hazır Siparişler',
      _OrderQueueFilter.delivered => 'Tamamlanan Siparişler',
      _OrderQueueFilter.cancelled => 'İptal Siparişleri',
    };
  }

  String _emptyDescription(_OrderQueueFilter filter) {
    return switch (filter) {
      _OrderQueueFilter.all =>
        'Henüz görüntülenecek sipariş yok. Yeni siparişler geldiğinde burada listelenecek.',
      _OrderQueueFilter.fresh => 'Onay bekleyen yeni sipariş görünmüyor.',
      _OrderQueueFilter.preparing =>
        'Hazırlık hattında bekleyen sipariş görünmüyor.',
      _OrderQueueFilter.ready => 'Teslime hazır sipariş görünmüyor.',
      _OrderQueueFilter.delivered => 'Tamamlanan sipariş henüz oluşmadı.',
      _OrderQueueFilter.cancelled => 'İptal edilen sipariş görünmüyor.',
    };
  }

  Future<void> _openFilters() async {
    _OrderDateFilter selectedDateFilter = _dateFilter;
    String? selectedPayment = _paymentFilter;
    _OrderQueueFilter selectedStatus = _currentFilter;

    final _OrdersFilterSheetResult?
    result = await showModalBottomSheet<_OrdersFilterSheetResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setSheetState,
              ) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      decoration: const BoxDecoration(
                        color: _panelStrong,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Text(
                                    'Filtrele',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _success,
                                    ),
                                  ),
                                ),
                                if (selectedDateFilter !=
                                        _OrderDateFilter.all ||
                                    selectedPayment != null ||
                                    selectedStatus != _OrderQueueFilter.all)
                                  TextButton(
                                    onPressed: () {
                                      setSheetState(() {
                                        selectedDateFilter =
                                            _OrderDateFilter.all;
                                        selectedPayment = null;
                                        selectedStatus = _OrderQueueFilter.all;
                                      });
                                    },
                                    child: const Text('Temizle'),
                                  ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const _OrdersFilterSectionLabel(label: 'Tarih'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _OrdersFilterChoiceChip(
                                  label: 'Tümü',
                                  selected:
                                      selectedDateFilter ==
                                      _OrderDateFilter.all,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDateFilter = _OrderDateFilter.all;
                                    });
                                  },
                                ),
                                _OrdersFilterChoiceChip(
                                  label: 'Bugün',
                                  selected:
                                      selectedDateFilter ==
                                      _OrderDateFilter.today,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDateFilter =
                                          _OrderDateFilter.today;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _OrdersFilterSectionLabel(
                              label: 'Ödeme Tipi',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _OrdersFilterChoiceChip(
                                  label: 'Tümü',
                                  selected: selectedPayment == null,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedPayment = null;
                                    });
                                  },
                                ),
                                ..._paymentOptions.map((String method) {
                                  return _OrdersFilterChoiceChip(
                                    label: method,
                                    selected: selectedPayment == method,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedPayment = method;
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _OrdersFilterSectionLabel(label: 'Durum'),
                            const SizedBox(height: 10),
                            ..._filters.map((
                              (_OrderQueueFilter, String) entry,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _OrdersStatusSheetTile(
                                  label: entry.$2,
                                  selected: selectedStatus == entry.$1,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedStatus = entry.$1;
                                    });
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop(
                                    _OrdersFilterSheetResult(
                                      dateFilter: selectedDateFilter,
                                      paymentMethod: selectedPayment,
                                      statusFilter: selectedStatus,
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE7F3E8),
                                  foregroundColor: _success,
                                ),
                                child: const Text('Sonuçları Göster'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _dateFilter = result.dateFilter;
      _paymentFilter = result.paymentMethod;
    });
    final int nextIndex = _filters.indexWhere(
      (((_OrderQueueFilter, String) entry) => entry.$1 == result.statusFilter),
    );
    if (nextIndex >= 0 && nextIndex != _currentTabIndex) {
      _tabController.animateTo(nextIndex);
    }
  }

  Widget _buildCompactView(BuildContext context) {
    final int todayOrders = _todayOrdersCount();
    final int activeOrders = _activeOrdersCount();
    final int freshCount = _filteredOrders(_OrderQueueFilter.fresh).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _success,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Siparişler',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: _openOrderHistory,
              style: IconButton.styleFrom(
                minimumSize: const Size(46, 46),
                maximumSize: const Size(46, 46),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white.withValues(alpha: 0.92),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: (String value) {
            setState(() {
              _query = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Siparişler',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 96),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_query.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.search_rounded, color: _muted),
                    ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      IconButton(
                        onPressed: _openFilters,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      if (_activeFilterCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line.withValues(alpha: 0.92)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _success,
            unselectedLabelColor: _muted,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            indicator: BoxDecoration(
              color: _successSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6EBDD)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: _filters
                .map(
                  (((_OrderQueueFilter, String) entry) => Tab(
                    height: 38,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(entry.$2),
                    ),
                  )),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _CompactOrderStatCard(
                icon: Icons.calendar_today_outlined,
                label: 'Bugünkü Sipariş',
                value: '$todayOrders',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactOrderStatCard(
                icon: Icons.notifications_none_rounded,
                label: 'Aktif Sipariş',
                value: '$activeOrders',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
        if (freshCount > 0) ...<Widget>[
          const SizedBox(height: 12),
          _OrdersAlertCard(
            count: freshCount,
            onTap: () {
              final int freshIndex = _filters.indexWhere(
                (((_OrderQueueFilter, String) entry) =>
                    entry.$1 == _OrderQueueFilter.fresh),
              );
              if (freshIndex >= 0) {
                _tabController.animateTo(freshIndex);
              }
            },
          ),
        ],
        const SizedBox(height: 14),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _filters
                .map(
                  (((_OrderQueueFilter, String) entry) => _CompactOrdersList(
                    title: _sectionTitle(entry.$1),
                    subtitle: '${_filteredOrders(entry.$1).length} sipariş',
                    orders: _filteredOrders(entry.$1),
                    emptyDescription: _emptyDescription(entry.$1),
                    onAdvance: widget.onAdvance,
                    onShowAll: entry.$1 == _OrderQueueFilter.all
                        ? null
                        : _openAllOrders,
                  )),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    final int freshCount = _filteredOrders(_OrderQueueFilter.fresh).length;
    final int preparingCount = _filteredOrders(
      _OrderQueueFilter.preparing,
    ).length;
    final int readyCount = _filteredOrders(_OrderQueueFilter.ready).length;
    final int deliveredCount = _filteredOrders(
      _OrderQueueFilter.delivered,
    ).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OpsPageIntroCard(
            compact: false,
            icon: Icons.receipt_long_rounded,
            title: 'Siparişler',
            subtitle:
                'Yeni, hazırlanan, hazır ve tamamlanan siparişleri tek akıştan yönet.',
            tone: _success,
            trailing: _HeaderActionPill(
              label: 'Sipariş geçmişi',
              icon: Icons.history_rounded,
              onTap: _openOrderHistory,
            ),
            badges: <Widget>[
              _OpsInlineStat(
                label: 'Toplam',
                value: '${_filteredOrders(_OrderQueueFilter.all).length}',
                tone: _success,
              ),
              _OpsInlineStat(label: 'Yeni', value: '$freshCount', tone: _info),
              _OpsInlineStat(
                label: 'Hazırlık',
                value: '$preparingCount',
                tone: _warning,
              ),
              _OpsInlineStat(
                label: 'Hazır',
                value: '$readyCount',
                tone: _accent,
              ),
              _OpsInlineStat(
                label: 'Teslim',
                value: '$deliveredCount',
                tone: _success,
              ),
            ],
            footer: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: (String value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Sipariş, mağaza veya ödeme yöntemi ara',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: _openFilters,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          const Icon(Icons.tune_rounded),
                          if (_activeFilterCount > 0)
                            Positioned(
                              top: 1,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FAF7),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFDDECE4)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: _success,
                    unselectedLabelColor: _muted,
                    dividerColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    indicator: BoxDecoration(
                      color: _successSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFD6EBDD)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: _filters
                        .map(
                          (((_OrderQueueFilter, String) entry) => Tab(
                            height: 44,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(entry.$2),
                            ),
                          )),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _SurfaceCard(
              padding: const EdgeInsets.all(14),
              child: TabBarView(
                controller: _tabController,
                children: _filters
                    .map(
                      (((_OrderQueueFilter, String) entry) => _OrdersTabBody(
                        filter: entry.$1,
                        title: entry.$2,
                        orders: _filteredOrders(entry.$1),
                        compact: false,
                        onAdvance: widget.onAdvance,
                      )),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 860;
    return compact ? _buildCompactView(context) : _buildDesktopView(context);
  }
}

class _OrdersTabBody extends StatelessWidget {
  const _OrdersTabBody({
    required this.filter,
    required this.title,
    required this.orders,
    required this.compact,
    required this.onAdvance,
  });

  final _OrderQueueFilter filter;
  final String title;
  final List<SpetoOpsOrder> orders;
  final bool compact;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyState(
        title: '$title kuyruğu boş',
        description:
            'Bu filtrede bekleyen sipariş görünmüyor. Yeni operasyon oluştuğunda burada listelenecek.',
        icon: Icons.inbox_outlined,
      );
    }
    if (filter == _OrderQueueFilter.all) {
      return _AllOrdersList(
        orders: orders,
        compact: false,
        onAdvance: onAdvance,
      );
    }
    if (filter == _OrderQueueFilter.preparing) {
      return _AllOrdersList(
        orders: orders,
        compact: false,
        onAdvance: onAdvance,
        headerLabel: 'Hazırlık hattı',
      );
    }
    final SpetoOpsOrderStage stage = switch (filter) {
      _OrderQueueFilter.fresh => SpetoOpsOrderStage.created,
      _OrderQueueFilter.ready => SpetoOpsOrderStage.ready,
      _OrderQueueFilter.delivered => SpetoOpsOrderStage.completed,
      _OrderQueueFilter.cancelled => SpetoOpsOrderStage.cancelled,
      _OrderQueueFilter.all ||
      _OrderQueueFilter.preparing => SpetoOpsOrderStage.created,
    };
    return Center(
      child: SizedBox(
        height: 560,
        child: _OrdersBoardColumn(
          stage: stage,
          orders: orders,
          onAdvance: onAdvance,
        ),
      ),
    );
  }
}

class _CompactOrdersList extends StatelessWidget {
  const _CompactOrdersList({
    required this.title,
    required this.subtitle,
    required this.orders,
    required this.emptyDescription,
    required this.onAdvance,
    this.onShowAll,
  });

  final String title;
  final String subtitle;
  final List<SpetoOpsOrder> orders;
  final String emptyDescription;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final bool empty = orders.isEmpty;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: empty ? 2 : orders.length + 1,
      separatorBuilder: (_, int index) =>
          SizedBox(height: index == 0 ? 12 : 10),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _OrdersSectionHeader(
            title: title,
            subtitle: subtitle,
            onShowAll: onShowAll,
          );
        }
        if (empty) {
          return _EmptyState(
            title: '$title boş',
            description: emptyDescription,
            icon: Icons.inbox_outlined,
          );
        }
        final SpetoOpsOrder order = orders[index - 1];
        return _MobileOrderCard(order: order, onAdvance: onAdvance);
      },
    );
  }
}

class _OrdersFilterSheetResult {
  const _OrdersFilterSheetResult({
    required this.dateFilter,
    required this.paymentMethod,
    required this.statusFilter,
  });

  final _OrderDateFilter dateFilter;
  final String? paymentMethod;
  final _OrderQueueFilter statusFilter;
}

class _CompactOrderStatCard extends StatelessWidget {
  const _CompactOrderStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line.withValues(alpha: 0.94)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _successSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _success, size: 18),
              ),
              const Spacer(),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersAlertCard extends StatelessWidget {
  const _OrdersAlertCard({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _warningSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2E3B5)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF1D88E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: _accentDeep,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count yeni sipariş bekliyor',
              style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
    if (onTap == null) {
      return child;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}

class _OrdersSectionHeader extends StatelessWidget {
  const _OrdersSectionHeader({
    required this.title,
    required this.subtitle,
    this.onShowAll,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onShowAll != null)
          TextButton.icon(
            onPressed: onShowAll,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text('Tümünü Gör'),
          ),
      ],
    );
  }
}

class _OrdersFilterSectionLabel extends StatelessWidget {
  const _OrdersFilterSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _OrdersFilterChoiceChip extends StatelessWidget {
  const _OrdersFilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _successSoft : const Color(0xFFF4F1EA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFD7EDE2) : _line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _success : _muted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersStatusSheetTile extends StatelessWidget {
  const _OrdersStatusSheetTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFD7EDE2) : _line,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _success : _muted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllOrdersList extends StatelessWidget {
  const _AllOrdersList({
    required this.orders,
    required this.compact,
    required this.onAdvance,
    this.headerLabel,
  });

  final List<SpetoOpsOrder> orders;
  final bool compact;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;
  final String? headerLabel;

  @override
  Widget build(BuildContext context) {
    final Widget content = ListView.separated(
      padding: EdgeInsets.only(bottom: compact ? 4 : 8),
      itemCount: orders.length,
      separatorBuilder: (_, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final SpetoOpsOrder order = orders[index];
        return compact
            ? _MobileOrderCard(order: order, onAdvance: onAdvance)
            : _AllOrdersDesktopCard(order: order, onAdvance: onAdvance);
      },
    );
    if (headerLabel == null) {
      return content;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _StatusPill(
          label: headerLabel!,
          color: _warning,
          backgroundColor: _warningSoft,
        ),
        const SizedBox(height: 16),
        Expanded(child: content),
      ],
    );
  }
}

class _AllOrdersDesktopCard extends StatelessWidget {
  const _AllOrdersDesktopCard({required this.order, required this.onAdvance});

  final SpetoOpsOrder order;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  Widget build(BuildContext context) {
    final List<SpetoOpsOrderStage> actions = _nextOpsStages(order.opsStatus);
    final Color statusColor = switch (order.opsStatus) {
      SpetoOpsOrderStage.completed => _success,
      SpetoOpsOrderStage.cancelled => _danger,
      SpetoOpsOrderStage.ready => _info,
      SpetoOpsOrderStage.preparing => _warning,
      SpetoOpsOrderStage.accepted => _accent,
      SpetoOpsOrderStage.created => _ink,
    };
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
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
                      '${order.vendor} • ${order.pickupCode}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${order.itemCount} ürün • ${order.paymentMethod} • ${order.deliveryMode}',
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
                    label: _opsStageLabel(order.opsStatus),
                    color: statusColor,
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${order.payableTotal.toStringAsFixed(0)} TL',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(label: 'Alındı ${order.placedAtLabel}'),
              _InfoPill(label: 'Hazır süresi ${order.etaLabel}'),
              if (order.promoCode.isNotEmpty)
                _InfoPill(label: 'Kampanya ${order.promoCode}'),
            ],
          ),
          const SizedBox(height: 14),
          ...order.items
              .take(3)
              .map(
                (SpetoCartItem item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${item.totalPrice.toStringAsFixed(0)} TL'),
                    ],
                  ),
                ),
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

class _SalesReportsPage extends StatelessWidget {
  const _SalesReportsPage({
    required this.vendorLabel,
    required this.snapshot,
    required this.orders,
  });

  final String vendorLabel;
  final SpetoInventorySnapshot snapshot;
  final List<SpetoOpsOrder> orders;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    final List<SpetoOpsOrder> completedOrders = orders
        .where(
          (SpetoOpsOrder order) =>
              order.opsStatus == SpetoOpsOrderStage.completed ||
              order.status == SpetoOrderStatus.completed,
        )
        .toList(growable: false);
    final List<SpetoOpsOrder> cancelledOrders = orders
        .where(
          (SpetoOpsOrder order) =>
              order.opsStatus == SpetoOpsOrderStage.cancelled ||
              order.status == SpetoOrderStatus.cancelled,
        )
        .toList(growable: false);
    final double totalRevenue = completedOrders.fold<double>(
      0,
      (double sum, SpetoOpsOrder order) => sum + order.payableTotal,
    );
    final int totalItemsSold = completedOrders.fold<int>(
      0,
      (int sum, SpetoOpsOrder order) => sum + order.itemCount,
    );
    final double averageBasket = completedOrders.isEmpty
        ? 0
        : totalRevenue / completedOrders.length;
    final Map<String, int> productSales = <String, int>{};
    for (final SpetoOpsOrder order in completedOrders) {
      for (final SpetoCartItem item in order.items) {
        productSales.update(
          item.title,
          (int current) => current + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    final List<MapEntry<String, int>> topProducts =
        productSales.entries.toList()..sort(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              b.value.compareTo(a.value),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionCard(
            title: 'Satış raporları',
            subtitle:
                '$vendorLabel için ciro, ürün hızı ve operasyon verimini tek akışta izle.',
            trailing: _InfoPill(
              label: '${completedOrders.length} teslim',
              compact: true,
            ),
            child: _ResponsiveCardGrid(
              minItemWidth: compact ? 150 : 210,
              children: <Widget>[
                _SummaryStatCard(
                  label: 'Toplam ciro',
                  value: '${totalRevenue.toStringAsFixed(0)} TL',
                  tone: _success,
                  note: '${completedOrders.length} teslim edilen sipariş',
                ),
                _SummaryStatCard(
                  label: 'Ortalama sepet',
                  value: '${averageBasket.toStringAsFixed(0)} TL',
                  tone: _info,
                  note: '${snapshot.openOrdersCount} aktif sipariş akışı',
                ),
                _SummaryStatCard(
                  label: 'Satılan ürün',
                  value: '$totalItemsSold adet',
                  tone: _accent,
                  note: '${snapshot.totalItems} SKU havuzu',
                ),
                _SummaryStatCard(
                  label: 'İptal oranı',
                  value: orders.isEmpty
                      ? '%0'
                      : '%${((cancelledOrders.length / orders.length) * 100).toStringAsFixed(0)}',
                  tone: _danger,
                  note: '${cancelledOrders.length} iptal sipariş',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Akış özeti',
            subtitle:
                'Operasyon hattındaki yükün şu an hangi aşamada biriktiğini gör.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InfoPill(
                  label:
                      'Yeni ${orders.where((SpetoOpsOrder order) => order.opsStatus == SpetoOpsOrderStage.created).length}',
                ),
                _InfoPill(
                  label:
                      'Hazırlanan ${orders.where((SpetoOpsOrder order) => order.opsStatus == SpetoOpsOrderStage.accepted || order.opsStatus == SpetoOpsOrderStage.preparing).length}',
                ),
                _InfoPill(
                  label:
                      'Hazır ${orders.where((SpetoOpsOrder order) => order.opsStatus == SpetoOpsOrderStage.ready).length}',
                ),
                _InfoPill(
                  label:
                      'Teslim ${orders.where((SpetoOpsOrder order) => order.opsStatus == SpetoOpsOrderStage.completed).length}',
                ),
                _InfoPill(
                  label:
                      'İptal ${orders.where((SpetoOpsOrder order) => order.opsStatus == SpetoOpsOrderStage.cancelled).length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'En çok satan ürünler',
            subtitle: 'Teslim edilen siparişlerden türetilen ürün temposu.',
            child: topProducts.isEmpty
                ? const _EmptyState(
                    title: 'Rapor üretilecek veri yok',
                    description:
                        'Teslim edilen siparişler geldikçe ürün performansı burada listelenecek.',
                    icon: Icons.bar_chart_rounded,
                  )
                : Column(
                    children: topProducts
                        .take(6)
                        .map((MapEntry<String, int> entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SurfaceCard(
                              padding: const EdgeInsets.all(16),
                              tint: _panel,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _accentSoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${topProducts.indexOf(entry) + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value} adet',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductsManagementPage extends StatefulWidget {
  const _ProductsManagementPage({
    required this.session,
    required this.items,
    required this.selectedId,
    required this.movements,
    required this.vendors,
    required this.events,
    required this.contentBlocks,
    required this.onSelected,
    required this.onAdjust,
    required this.onRestock,
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
  final List<SpetoInventoryItem> items;
  final String? selectedId;
  final List<SpetoInventoryMovement> movements;
  final List<SpetoCatalogVendor> vendors;
  final List<SpetoCatalogEvent> events;
  final List<SpetoCatalogContentBlock> contentBlocks;
  final ValueChanged<String> onSelected;
  final ValueChanged<SpetoInventoryItem> onAdjust;
  final ValueChanged<SpetoInventoryItem> onRestock;
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
  State<_ProductsManagementPage> createState() =>
      _ProductsManagementPageState();
}

class _ProductsManagementPageState extends State<_ProductsManagementPage> {
  bool _showSummary = true;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final bool nextValue = notification.metrics.pixels <= 0.5;
    if (nextValue != _showSummary) {
      setState(() {
        _showSummary = nextValue;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final int totalSections = widget.vendors.fold<int>(
      0,
      (int sum, SpetoCatalogVendor vendor) => sum + vendor.sections.length,
    );
    final int totalProducts = widget.vendors.fold<int>(
      0,
      (int sum, SpetoCatalogVendor vendor) =>
          sum +
          vendor.sections.fold<int>(
            0,
            (int sectionSum, SpetoCatalogSection section) =>
                sectionSum + section.products.length,
          ),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 760;
        return DefaultTabController(
          length: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
            child: Column(
              children: <Widget>[
                _SurfaceCard(
                  padding: EdgeInsets.all(compact ? 14 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                        child: !compact || _showSummary
                            ? Padding(
                                key: const ValueKey<String>(
                                  'products-summary-visible',
                                ),
                                padding: EdgeInsets.only(
                                  bottom: compact ? 12 : 16,
                                ),
                                child: _OpsPageIntroHeader(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'Ürünler',
                                  subtitle:
                                      'Stok operasyonu ile vitrin ve katalog düzenini aynı çalışma alanında yönet.',
                                  tone: _success,
                                  compact: compact,
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey<String>(
                                  'products-summary-hidden',
                                ),
                              ),
                      ),
                      if (!compact || _showSummary) ...<Widget>[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _OpsInlineStat(
                              label: 'Stok kartı',
                              value: '${widget.items.length}',
                              tone: _success,
                            ),
                            _OpsInlineStat(
                              label: 'Kategori',
                              value: '$totalSections',
                              tone: _info,
                            ),
                            _OpsInlineStat(
                              label: 'Vitrin ürünü',
                              value: '$totalProducts',
                              tone: _accent,
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 16),
                      ],
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 6 : 8,
                          vertical: compact ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FAF7),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFDDECE4)),
                        ),
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: _success,
                          unselectedLabelColor: _muted,
                          dividerColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          labelStyle: TextStyle(
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w800,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: _successSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFD6EBDD)),
                          ),
                          onTap: (_) {
                            if (!_showSummary) {
                              setState(() {
                                _showSummary = true;
                              });
                            }
                          },
                          tabs: <Widget>[
                            Tab(
                              height: compact ? 40 : 44,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: const Text('Stok ve ürünler'),
                              ),
                            ),
                            Tab(
                              height: compact ? 40 : 44,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: const Text('Vitrin ve katalog'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: compact
                        ? _handleScrollNotification
                        : (_) => false,
                    child: _SurfaceCard(
                      padding: EdgeInsets.all(compact ? 10 : 14),
                      child: TabBarView(
                        children: <Widget>[
                          _InventoryPage(
                            items: widget.items,
                            selectedId: widget.selectedId,
                            movements: widget.movements,
                            onSelected: widget.onSelected,
                            onAdjust: widget.onAdjust,
                            onRestock: widget.onRestock,
                          ),
                          _CatalogPage(
                            session: widget.session,
                            vendors: widget.vendors,
                            events: widget.events,
                            contentBlocks: widget.contentBlocks,
                            onCreateVendor: widget.onCreateVendor,
                            onEditVendor: widget.onEditVendor,
                            onCreateSection: widget.onCreateSection,
                            onEditSection: widget.onEditSection,
                            onCreateProduct: widget.onCreateProduct,
                            onEditProduct: widget.onEditProduct,
                            onEditEvent: widget.onEditEvent,
                            onEditContentBlock: widget.onEditContentBlock,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CampaignsPage extends StatelessWidget {
  const _CampaignsPage({
    required this.vendorLabel,
    required this.offers,
    required this.onNavigate,
  });

  final String vendorLabel;
  final List<SpetoHappyHourOffer> offers;
  final ValueChanged<_StockDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    final double averageDiscount = offers.isEmpty
        ? 0
        : offers.fold<int>(
                0,
                (int sum, SpetoHappyHourOffer offer) =>
                    sum + offer.discountPercent,
              ) /
              offers.length;
    final int expiringSoon = offers
        .where((SpetoHappyHourOffer offer) => offer.expiresInMinutes <= 60)
        .length;
    final int stockRiskCount = offers
        .where((SpetoHappyHourOffer offer) => !offer.stockStatus.canPurchase)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OpsPageIntroCard(
            compact: compact,
            icon: Icons.local_offer_outlined,
            title: 'Kampanyalar',
            subtitle:
                '$vendorLabel için vitrine çıkan teklifleri, indirim temposunu ve stok riskini tek görünümde takip et.',
            tone: _success,
            trailing: FilledButton.tonalIcon(
              onPressed: () => onNavigate(_StockDestination.products),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Ürünlere git'),
            ),
            badges: <Widget>[
              _OpsInlineStat(
                label: 'Aktif',
                value: '${offers.length}',
                tone: _success,
              ),
              _OpsInlineStat(
                label: 'Ort. indirim',
                value: '%${averageDiscount.toStringAsFixed(0)}',
                tone: _accent,
              ),
              _OpsInlineStat(
                label: 'Bitiyor',
                value: '$expiringSoon',
                tone: _warning,
              ),
              _OpsInlineStat(
                label: 'Riskli stok',
                value: '$stockRiskCount',
                tone: _danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ResponsiveCardGrid(
            minItemWidth: compact ? 156 : 210,
            children: <Widget>[
              _SummaryStatCard(
                label: 'Aktif kampanya',
                value: '${offers.length}',
                tone: _success,
                note: 'Vitrinde yayınlanan teklif',
              ),
              _SummaryStatCard(
                label: 'Ortalama indirim',
                value: '%${averageDiscount.toStringAsFixed(0)}',
                tone: _accent,
                note: '$expiringSoon kampanya 1 saat içinde bitiyor',
              ),
              _SummaryStatCard(
                label: 'Stok riski',
                value: '$stockRiskCount',
                tone: _danger,
                note: 'Stok problemi olan kampanya',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Yayındaki teklifler',
            subtitle:
                'İndirim yüzdesi, kalan süre ve talep sayısı ile kampanyaları sırala.',
            child: offers.isEmpty
                ? const _EmptyState(
                    title: 'Aktif kampanya görünmüyor',
                    description:
                        'Happy hour veya vitrin teklifleri açıldığında burada listelenecek.',
                    icon: Icons.local_offer_outlined,
                  )
                : Column(
                    children: offers
                        .map((SpetoHappyHourOffer offer) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CampaignOfferCard(offer: offer),
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RevenuePaymentsPage extends StatelessWidget {
  const _RevenuePaymentsPage({
    required this.orders,
    required this.integrations,
    required this.onSync,
    required this.onCreate,
  });

  final List<SpetoOpsOrder> orders;
  final List<SpetoIntegrationConnection> integrations;
  final Future<void> Function(SpetoIntegrationConnection connection) onSync;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    final List<SpetoOpsOrder> settledOrders = orders
        .where(
          (SpetoOpsOrder order) =>
              order.opsStatus == SpetoOpsOrderStage.completed ||
              order.status == SpetoOrderStatus.completed,
        )
        .toList(growable: false);
    final Map<String, double> paymentTotals = <String, double>{};
    for (final SpetoOpsOrder order in settledOrders) {
      paymentTotals.update(
        order.paymentMethod,
        (double current) => current + order.payableTotal,
        ifAbsent: () => order.payableTotal,
      );
    }
    final List<MapEntry<String, double>> paymentEntries =
        paymentTotals.entries.toList()..sort(
          (MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value),
        );
    final double settledRevenue = settledOrders.fold<double>(
      0,
      (double sum, SpetoOpsOrder order) => sum + order.payableTotal,
    );
    final double discounts = settledOrders.fold<double>(
      0,
      (double sum, SpetoOpsOrder order) => sum + order.discountAmount,
    );

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        child: Column(
          children: <Widget>[
            _SurfaceCard(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Gelir ve ödemeler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tahsil edilen siparişleri, ödeme yöntemi dağılımını ve entegrasyon bağlantılarını aynı görünümde takip et.',
                    style: TextStyle(color: _muted, height: 1.5),
                  ),
                  SizedBox(height: compact ? 14 : 18),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 8,
                      vertical: compact ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0x1FD27A1F)),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: _ink,
                      unselectedLabelColor: _muted,
                      dividerColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: TextStyle(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                      indicator: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFFD6A3)),
                      ),
                      tabs: <Widget>[
                        Tab(
                          height: compact ? 40 : 44,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: const Text('Gelir özeti'),
                          ),
                        ),
                        Tab(
                          height: compact ? 40 : 44,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: const Text('Ödeme yöntemleri'),
                          ),
                        ),
                        Tab(
                          height: compact ? 40 : 44,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: const Text('Bağlantılar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SectionCard(
                          title: 'Tahsilat özeti',
                          child: _ResponsiveCardGrid(
                            minItemWidth: compact ? 156 : 210,
                            children: <Widget>[
                              _SummaryStatCard(
                                label: 'Tahsil edilen gelir',
                                value:
                                    '${settledRevenue.toStringAsFixed(0)} TL',
                                tone: _success,
                                note:
                                    '${settledOrders.length} teslim edilen sipariş',
                              ),
                              _SummaryStatCard(
                                label: 'İndirim toplamı',
                                value: '${discounts.toStringAsFixed(0)} TL',
                                tone: _warning,
                                note: 'Kampanya ve kupon etkisi',
                              ),
                              _SummaryStatCard(
                                label: 'Aktif ödeme tipi',
                                value: '${paymentEntries.length}',
                                tone: _info,
                                note: 'Kasada kullanılan yöntem',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Son tahsil edilen siparişler',
                          child: settledOrders.isEmpty
                              ? const _EmptyState(
                                  title: 'Tahsil edilmiş sipariş yok',
                                  description:
                                      'Tamamlanan siparişler geldikçe ödeme listesi burada görünür.',
                                  icon: Icons.payments_outlined,
                                )
                              : Column(
                                  children: settledOrders
                                      .take(6)
                                      .map((SpetoOpsOrder order) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _RevenueOrderTile(
                                            order: order,
                                          ),
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _SectionCard(
                      title: 'Ödeme yöntemi kırılımı',
                      subtitle:
                          'Hangi tahsilat kanalının daha fazla gelir getirdiğini izle.',
                      child: paymentEntries.isEmpty
                          ? const _EmptyState(
                              title: 'Ödeme verisi oluşmadı',
                              description:
                                  'Teslim edilen siparişlerden sonra ödeme kırılımı burada listelenir.',
                              icon: Icons.account_balance_wallet_outlined,
                            )
                          : Column(
                              children: paymentEntries
                                  .map((MapEntry<String, double> entry) {
                                    final double percent = settledRevenue == 0
                                        ? 0
                                        : (entry.value / settledRevenue) * 100;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _SurfaceCard(
                                        padding: const EdgeInsets.all(16),
                                        tint: _panel,
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    entry.key,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '%${percent.toStringAsFixed(0)} pay',
                                                    style: const TextStyle(
                                                      color: _muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${entry.value.toStringAsFixed(0)} TL',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                    ),
                  ),
                  _IntegrationsPage(
                    integrations: integrations,
                    onSync: onSync,
                    onCreate: onCreate,
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

class _HelpCenterPage extends StatelessWidget {
  const _HelpCenterPage({required this.vendorLabel, required this.session});

  final String vendorLabel;
  final SpetoSession session;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionCard(
            title: 'Yardım merkezi',
            subtitle:
                '$vendorLabel operasyonu için hızlı çözüm adımlarını ve destek temaslarını burada tut.',
            child: _ResponsiveCardGrid(
              minItemWidth: compact ? 156 : 210,
              children: const <Widget>[
                _SummaryStatCard(
                  label: 'Öncelik 1',
                  value: 'Sipariş akışı',
                  tone: _danger,
                  note: 'Hazır ve yeni siparişleri 5 dk içinde kontrol et',
                ),
                _SummaryStatCard(
                  label: 'Öncelik 2',
                  value: 'Stok doğruluğu',
                  tone: _warning,
                  note: 'Kritik SKU ve manuel düzeltmeleri gözden geçir',
                ),
                _SummaryStatCard(
                  label: 'Öncelik 3',
                  value: 'Kampanya uyumu',
                  tone: _info,
                  note: 'Kampanya stoklarını ve indirimleri senkron tut',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Operasyon rehberi',
            child: Column(
              children: <Widget>[
                _HelpTopicTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sipariş biriktiğinde',
                  body:
                      'Önce Yeni ve Hazırlanıyor sekmelerini aç, geciken siparişleri Hazır aşamasına taşımadan önce ödeme ve ürün adedini doğrula.',
                ),
                _HelpTopicTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stok uyuşmazlığı olduğunda',
                  body:
                      'Ürünler sekmesinden SKU kartını aç, son hareketleri incele ve gerekiyorsa manuel düzeltme ya da stok girişi uygula.',
                ),
                _HelpTopicTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Kampanya stok sorunu olduğunda',
                  body:
                      'Kampanyalar ekranında stok riski taşıyan teklifleri tespit et, sonra Ürün Yönetimi üzerinden ilgili SKU görünürlüğünü güncelle.',
                ),
                _HelpTopicTile(
                  icon: Icons.support_agent_outlined,
                  title: 'Kimden destek alınır?',
                  body:
                      '${session.displayName} oturumu için ilk temas noktası mağaza operasyon yöneticisidir. Teknik blokajlarda backend log ve cihaz ağı birlikte kontrol edilmeli.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({
    required this.session,
    required this.vendorLabel,
    required this.selectedVendor,
    required this.vendors,
    required this.integrations,
    required this.orders,
    required this.snapshot,
    required this.offers,
    required this.onSignOut,
  });

  final SpetoSession session;
  final String vendorLabel;
  final SpetoCatalogVendor? selectedVendor;
  final List<SpetoCatalogVendor> vendors;
  final List<SpetoIntegrationConnection> integrations;
  final List<SpetoOpsOrder> orders;
  final SpetoInventorySnapshot? snapshot;
  final List<SpetoHappyHourOffer> offers;
  final VoidCallback onSignOut;

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (BuildContext context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    final int openOrders = snapshot?.openOrdersCount ?? 0;
    final int lowStock = snapshot?.lowStockCount ?? 0;
    final List<SpetoCatalogVendor> resolvedVendors = vendors.isNotEmpty
        ? vendors
        : selectedVendor == null
        ? const <SpetoCatalogVendor>[]
        : <SpetoCatalogVendor>[selectedVendor!];
    final SpetoCatalogVendor? vendor =
        selectedVendor ??
        (resolvedVendors.isNotEmpty ? resolvedVendors.first : null);
    final List<SpetoCatalogOperatorAccount> operatorAccounts =
        vendor != null && vendor.operatorAccounts.isNotEmpty
        ? vendor.operatorAccounts
        : resolvedVendors
              .expand((SpetoCatalogVendor vendor) => vendor.operatorAccounts)
              .toList(growable: false);
    final Iterable<String> categorySource = vendor?.cuisine.isNotEmpty == true
        ? vendor!.cuisine
              .split(',')
              .map((String item) => item.trim())
              .where((String value) => value.isNotEmpty)
        : (snapshot?.items ?? const <SpetoInventoryItem>[])
              .map((SpetoInventoryItem item) => item.category.trim())
              .where((String value) => value.isNotEmpty)
              .toSet();
    final String categoryLine = categorySource
        .take(3)
        .toList(growable: false)
        .join(' • ');
    final String accessLabel = session.vendorScopes.length <= 1
        ? 'Merkez şube'
        : '${session.vendorScopes.length} şube erişimi';
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 6 : 16,
        compact ? 4 : 8,
        compact ? 6 : 16,
        compact ? 112 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Hesabım',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _AccountIconButton(
                    icon: Icons.notifications_none_rounded,
                    badgeColor: _accent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AccountStoreCard(
                vendorLabel: vendorLabel,
                roleLabel: _roleLabel(session.role),
                email: session.email,
                accessLabel: accessLabel,
                categoryLine: categoryLine,
                onTap: () {
                  _pushPage(
                    context,
                    _AccountBranchManagementPage(
                      vendors: resolvedVendors,
                      selectedVendorId: vendor?.vendorId,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _AccountMenuGroup(
                items: <_AccountMenuEntry>[
                  _AccountMenuEntry(
                    icon: Icons.person_outline_rounded,
                    tone: _success,
                    title: 'Profil Bilgileri',
                    subtitle: 'İşletme ve iletişim bilgilerinizi düzenleyin',
                    onTap: () {
                      _pushPage(
                        context,
                        _AccountProfileInfoPage(
                          session: session,
                          vendorLabel: vendorLabel,
                          vendor: vendor,
                          vendors: resolvedVendors,
                          operatorAccounts: operatorAccounts,
                        ),
                      );
                    },
                  ),
                  _AccountMenuEntry(
                    icon: Icons.access_time_rounded,
                    tone: _success,
                    title: 'Çalışma Saatleri',
                    subtitle: 'Açılış, kapanış ve tatil günlerini yönetin',
                    onTap: () {
                      _pushPage(
                        context,
                        _AccountWorkingHoursPage(vendor: vendor),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AccountMenuGroup(
                items: <_AccountMenuEntry>[
                  _AccountMenuEntry(
                    icon: Icons.account_balance_wallet_outlined,
                    tone: _success,
                    title: 'Ödeme ve Finans',
                    subtitle:
                        '$openOrders açık sipariş ve ${offers.length} aktif kampanya ile kazanç akışını izleyin',
                    onTap: () {
                      _pushPage(
                        context,
                        _AccountPaymentFinancePage(
                          vendorLabel: vendorLabel,
                          orders: orders,
                          offers: offers,
                        ),
                      );
                    },
                  ),
                  _AccountMenuEntry(
                    icon: Icons.notifications_active_outlined,
                    tone: _success,
                    title: 'Bildirim Ayarları',
                    subtitle:
                        '$lowStock kritik stok ve operasyon uyarılarını yönetin',
                    onTap: () {
                      _pushPage(
                        context,
                        _AccountNotificationsPage(
                          notificationsEnabled: session.notificationsEnabled,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AccountMenuGroup(
                items: <_AccountMenuEntry>[
                  _AccountMenuEntry(
                    icon: Icons.extension_outlined,
                    tone: _success,
                    title: 'Entegrasyonlar',
                    subtitle:
                        'POS, yazarkasa ve ${session.vendorScopes.length} kapsam için bağlantıları yönetin',
                    onTap: () {
                      _pushPage(
                        context,
                        _AccountIntegrationsSettingsPage(
                          integrations: integrations,
                        ),
                      );
                    },
                  ),
                  _AccountMenuEntry(
                    icon: Icons.headset_mic_outlined,
                    tone: _success,
                    title: 'Destek Merkezi',
                    subtitle: 'Yardım alın ve destek talebi oluşturun',
                    onTap: () {
                      _pushPage(context, const _AccountSupportCenterPage());
                    },
                  ),
                  _AccountMenuEntry(
                    icon: Icons.shield_outlined,
                    tone: _success,
                    title: 'Güvenlik',
                    subtitle: session.phone.isEmpty
                        ? 'Şifre ve oturum ayarları'
                        : 'Şifre, 2FA ve oturum ayarlarını yönetin',
                    onTap: () {
                      _pushPage(
                        context,
                        _AccountSecurityPage(session: session),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AccountLogoutCard(onTap: onSignOut),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountStoreCard extends StatelessWidget {
  const _AccountStoreCard({
    required this.vendorLabel,
    required this.roleLabel,
    required this.email,
    required this.accessLabel,
    required this.categoryLine,
    this.onTap,
  });

  final String vendorLabel;
  final String roleLabel;
  final String email;
  final String accessLabel;
  final String categoryLine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF232229),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Icon(
                      Icons.lunch_dining_rounded,
                      color: Color(0xFFF6B24A),
                      size: 28,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'SPETO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _success,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        vendorLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _successSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Açık',
                        style: TextStyle(
                          color: _success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  categoryLine.isEmpty ? roleLabel : categoryLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        accessLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted),
                      ),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
    if (onTap == null) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: card,
      ),
    );
  }
}

class _AccountMenuGroup extends StatelessWidget {
  const _AccountMenuGroup({required this.items});

  final List<_AccountMenuEntry> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A1E1917),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: List<Widget>.generate(items.length, (int index) {
          final _AccountMenuEntry entry = items[index];
          return Column(
            children: <Widget>[
              _AccountMenuTile(entry: entry),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 68,
                  endIndent: 18,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({required this.entry});

  final _AccountMenuEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: entry.tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(entry.icon, size: 22, color: entry.tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountLogoutCard extends StatelessWidget {
  const _AccountLogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF5D8D8)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.logout_rounded, color: _danger, size: 20),
              SizedBox(width: 8),
              Text(
                'Çıkış Yap',
                style: TextStyle(
                  color: _danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountIconButton extends StatelessWidget {
  const _AccountIconButton({required this.icon, this.badgeColor});

  final IconData icon;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: _ink),
        ),
        if (badgeColor != null)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountMenuEntry {
  const _AccountMenuEntry({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class _AccountDetailScaffold extends StatelessWidget {
  const _AccountDetailScaffold({
    required this.title,
    required this.child,
    this.trailing,
    this.bottomAction,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: 44, child: trailing ?? const SizedBox()),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: child,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: bottomAction,
              ),
            ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _DetailListTile extends StatelessWidget {
  const _DetailListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconTone = _success,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconTone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: iconTone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconTone, size: compact ? 19 : 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _SettingsFooterButton extends StatelessWidget {
  const _SettingsFooterButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: _success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

class _AccountProfileInfoPage extends StatelessWidget {
  const _AccountProfileInfoPage({
    required this.session,
    required this.vendorLabel,
    required this.vendor,
    required this.vendors,
    required this.operatorAccounts,
  });

  final SpetoSession session;
  final String vendorLabel;
  final SpetoCatalogVendor? vendor;
  final List<SpetoCatalogVendor> vendors;
  final List<SpetoCatalogOperatorAccount> operatorAccounts;

  @override
  Widget build(BuildContext context) {
    final String address = vendor?.pickupPoints.isNotEmpty == true
        ? vendor!.pickupPoints.first.address
        : 'Merkez şube';
    return _AccountDetailScaffold(
      title: 'Profil Bilgileri',
      trailing: operatorAccounts.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        _AccountUserManagementPage(
                          operatorAccounts: operatorAccounts,
                          vendorLabel: vendorLabel,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.group_outlined),
            ),
      bottomAction: const _SettingsFooterButton(label: 'Kaydet'),
      child: Column(
        children: <Widget>[
          _DetailSectionCard(
            child: Column(
              children: <Widget>[
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFF232229),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(
                              Icons.lunch_dining_rounded,
                              color: Color(0xFFF6B24A),
                              size: 32,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'SPETO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _success,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  vendorLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  vendor?.cuisine.isNotEmpty == true
                      ? vendor!.cuisine
                      : _roleLabel(session.role),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _DetailListTile(
                  icon: Icons.storefront_outlined,
                  title: 'İşletme Adı',
                  subtitle: vendorLabel,
                  trailing: const SizedBox.shrink(),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.badge_outlined,
                  title: 'Yetkili',
                  subtitle: session.displayName,
                  trailing: const SizedBox.shrink(),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.phone_outlined,
                  title: 'Telefon',
                  subtitle: session.phone.isEmpty
                      ? 'Tanımlı değil'
                      : session.phone,
                  trailing: const SizedBox.shrink(),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'E-posta',
                  subtitle: session.email,
                  trailing: const SizedBox.shrink(),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.location_on_outlined,
                  title: 'Adres',
                  subtitle: address,
                  trailing: const SizedBox.shrink(),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.apartment_rounded,
                  title: 'Şube Yönetimi',
                  subtitle: '${vendors.length} şube ve teslim noktası görünümü',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            _AccountBranchManagementPage(
                              vendors: vendors,
                              selectedVendorId: vendor?.vendorId,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountWorkingHoursPage extends StatefulWidget {
  const _AccountWorkingHoursPage({required this.vendor});

  final SpetoCatalogVendor? vendor;

  @override
  State<_AccountWorkingHoursPage> createState() =>
      _AccountWorkingHoursPageState();
}

class _AccountWorkingHoursPageState extends State<_AccountWorkingHoursPage> {
  late final List<_WorkingHourSlot> _slots = <_WorkingHourSlot>[
    _WorkingHourSlot(day: 'Pazartesi', hours: '09:00 - 23:00'),
    _WorkingHourSlot(day: 'Salı', hours: '09:00 - 23:00'),
    _WorkingHourSlot(day: 'Çarşamba', hours: '09:00 - 23:00'),
    _WorkingHourSlot(day: 'Perşembe', hours: '09:00 - 23:00'),
    _WorkingHourSlot(day: 'Cuma', hours: '09:00 - 23:00'),
    _WorkingHourSlot(day: 'Cumartesi', hours: '10:00 - 23:00'),
    _WorkingHourSlot(day: 'Pazar', hours: '10:00 - 22:30', enabled: false),
  ];

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Çalışma Saatleri',
      bottomAction: const _SettingsFooterButton(label: 'Kaydet'),
      child: Column(
        children: <Widget>[
          _DetailSectionCard(
            child: Column(
              children: <Widget>[
                Text(
                  widget.vendor?.workingHoursLabel.isNotEmpty == true
                      ? widget.vendor!.workingHoursLabel
                      : 'Servis saatlerini güncelleyin',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 14),
                ...List<Widget>.generate(_slots.length, (int index) {
                  final _WorkingHourSlot slot = _slots[index];
                  return Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              slot.day,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            slot.hours,
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Switch.adaptive(
                            value: slot.enabled,
                            activeTrackColor: _success.withValues(alpha: 0.4),
                            activeThumbColor: _success,
                            onChanged: (bool value) {
                              setState(() {
                                _slots[index] = slot.copyWith(enabled: value);
                              });
                            },
                          ),
                        ],
                      ),
                      if (index != _slots.length - 1)
                        Divider(
                          height: 18,
                          thickness: 1,
                          color: _line.withValues(alpha: 0.7),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Özel Günler',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                _DetailListTile(
                  icon: Icons.event_note_outlined,
                  title: 'Yeni Yıl',
                  subtitle: '31 Ocak 2026',
                  trailing: const Text(
                    'Kapalı',
                    style: TextStyle(
                      color: _danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  compact: true,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 60,
                  endIndent: 12,
                ),
                _DetailListTile(
                  icon: Icons.celebration_outlined,
                  title: 'Ramazan Bayramı',
                  subtitle: '30 Mar - 01 Nis 10:00 - 18:00',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: _muted,
                  ),
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBranchManagementPage extends StatelessWidget {
  const _AccountBranchManagementPage({
    required this.vendors,
    required this.selectedVendorId,
  });

  final List<SpetoCatalogVendor> vendors;
  final String? selectedVendorId;

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Şube Yönetimi',
      child: Column(
        children: <Widget>[
          _DetailSectionCard(
            child: Column(
              children: vendors.isEmpty
                  ? const <Widget>[
                      _EmptyState(
                        title: 'Şube bulunamadı',
                        description: 'Tanımlı şubeler burada listelenir.',
                        icon: Icons.storefront_outlined,
                      ),
                    ]
                  : List<Widget>.generate(vendors.length, (int index) {
                      final SpetoCatalogVendor vendor = vendors[index];
                      return Column(
                        children: <Widget>[
                          _DetailListTile(
                            icon: Icons.store_mall_directory_outlined,
                            title: vendor.title,
                            subtitle: vendor.pickupPoints.isNotEmpty
                                ? vendor.pickupPoints.first.address
                                : vendor.subtitle,
                            iconTone: vendor.vendorId == selectedVendorId
                                ? _success
                                : _info,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: vendor.isActive
                                    ? _successSoft
                                    : _dangerSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                vendor.isActive ? 'Aktif' : 'Pasif',
                                style: TextStyle(
                                  color: vendor.isActive ? _success : _danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            compact: true,
                          ),
                          if (index != vendors.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: _line.withValues(alpha: 0.7),
                              indent: 60,
                              endIndent: 12,
                            ),
                        ],
                      );
                    }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountPaymentFinancePage extends StatelessWidget {
  const _AccountPaymentFinancePage({
    required this.vendorLabel,
    required this.orders,
    required this.offers,
  });

  final String vendorLabel;
  final List<SpetoOpsOrder> orders;
  final List<SpetoHappyHourOffer> offers;

  @override
  Widget build(BuildContext context) {
    final List<SpetoOpsOrder> completedOrders = orders
        .where(
          (SpetoOpsOrder order) =>
              order.status == SpetoOrderStatus.completed ||
              order.opsStatus == SpetoOpsOrderStage.completed,
        )
        .toList(growable: false);
    final List<SpetoOpsOrder> openOrders = orders
        .where((SpetoOpsOrder order) => order.status == SpetoOrderStatus.active)
        .toList(growable: false);
    final double settledTotal = completedOrders.fold<double>(
      0,
      (double sum, SpetoOpsOrder order) => sum + order.payableTotal,
    );
    final double pendingTotal = openOrders.fold<double>(
      0,
      (double sum, SpetoOpsOrder order) => sum + order.payableTotal,
    );
    return _AccountDetailScaffold(
      title: 'Ödeme ve Finans',
      bottomAction: const _SettingsFooterButton(label: 'Raporu İndir'),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _FinanceSummaryCard(
                  title: 'Toplam Tahsilat',
                  value: '${settledTotal.toStringAsFixed(0)} TL',
                  accent: _success,
                  subtitle: vendorLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinanceSummaryCard(
                  title: 'Bekleyen Tutar',
                  value: '${pendingTotal.toStringAsFixed(0)} TL',
                  accent: _warning,
                  subtitle: '${openOrders.length} açık sipariş',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                const _DetailListTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Banka Hesap Bilgileri',
                  subtitle: 'TR12 0001 2000 0000 0000 1234 56',
                  trailing: Text(
                    'Düzenle',
                    style: TextStyle(
                      color: _success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Komisyon Oranları',
                  subtitle: '%${offers.isEmpty ? '0' : '12'} servis ücreti',
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Ödeme Geçmişi',
                  subtitle: '${completedOrders.length} teslim edilen sipariş',
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _line.withValues(alpha: 0.7),
                  indent: 64,
                  endIndent: 14,
                ),
                _DetailListTile(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Kazanç Raporları',
                  subtitle: 'Günlük, haftalık ve aylık kırılım',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountNotificationsPage extends StatefulWidget {
  const _AccountNotificationsPage({required this.notificationsEnabled});

  final bool notificationsEnabled;

  @override
  State<_AccountNotificationsPage> createState() =>
      _AccountNotificationsPageState();
}

class _AccountNotificationsPageState extends State<_AccountNotificationsPage> {
  late final List<_NotificationPreference> _items = <_NotificationPreference>[
    _NotificationPreference(
      title: 'Yeni Sipariş',
      subtitle: 'Yeni sipariş geldiğinde',
      enabled: widget.notificationsEnabled,
    ),
    _NotificationPreference(
      title: 'İptal Siparişi',
      subtitle: 'İptal olan siparişlerde',
      enabled: true,
    ),
    _NotificationPreference(
      title: 'Hazır Sipariş',
      subtitle: 'Hazır olan siparişlerde',
      enabled: true,
    ),
    _NotificationPreference(
      title: 'Kampanyalar',
      subtitle: 'Kampanya değişikliklerinde',
      enabled: false,
    ),
    _NotificationPreference(
      title: 'Kritik Uyarılar',
      subtitle: 'Stok uyarılarında',
      enabled: true,
    ),
    _NotificationPreference(
      title: 'Happy Hour',
      subtitle: 'Happy hour başlangıcında',
      enabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Bildirim Ayarları',
      bottomAction: const _SettingsFooterButton(label: 'Kaydet'),
      child: _DetailSectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: List<Widget>.generate(_items.length, (int index) {
            final _NotificationPreference item = _items[index];
            return Column(
              children: <Widget>[
                _DetailListTile(
                  icon: Icons.notifications_active_outlined,
                  title: item.title,
                  subtitle: item.subtitle,
                  trailing: Switch.adaptive(
                    value: item.enabled,
                    activeTrackColor: _success.withValues(alpha: 0.4),
                    activeThumbColor: _success,
                    onChanged: (bool value) {
                      setState(() {
                        _items[index] = item.copyWith(enabled: value);
                      });
                    },
                  ),
                  compact: true,
                ),
                if (index != _items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _line.withValues(alpha: 0.7),
                    indent: 60,
                    endIndent: 12,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _AccountUserManagementPage extends StatelessWidget {
  const _AccountUserManagementPage({
    required this.operatorAccounts,
    required this.vendorLabel,
  });

  final List<SpetoCatalogOperatorAccount> operatorAccounts;
  final String vendorLabel;

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Kullanıcı Yönetimi',
      child: Column(
        children: <Widget>[
          _DetailSectionCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.groups_rounded, color: _success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${operatorAccounts.length} kullanıcı aktif',
                    style: const TextStyle(
                      color: _success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSectionCard(
            padding: EdgeInsets.zero,
            child: operatorAccounts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: _EmptyState(
                      title: 'Kullanıcı bulunamadı',
                      description: 'Şube kullanıcıları burada listelenir.',
                      icon: Icons.group_off_rounded,
                    ),
                  )
                : Column(
                    children: List<Widget>.generate(operatorAccounts.length, (
                      int index,
                    ) {
                      final SpetoCatalogOperatorAccount operator =
                          operatorAccounts[index];
                      final Color tone = <Color>[
                        _success,
                        _info,
                        _accent,
                        _danger,
                      ][index % 4];
                      final String roleLabel = <String>[
                        'Yönetici',
                        'Vardiya Müdürü',
                        'Kasiyer',
                        'Mutfak',
                      ][index % 4];
                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: tone.withValues(alpha: 0.12),
                                  foregroundColor: tone,
                                  child: Text(
                                    operator.displayName.isEmpty
                                        ? '?'
                                        : operator.displayName.characters.first
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
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        operator.email.isNotEmpty
                                            ? operator.email
                                            : vendorLabel,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tone.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    roleLabel,
                                    style: TextStyle(
                                      color: tone,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (index != operatorAccounts.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: _line.withValues(alpha: 0.7),
                              indent: 68,
                              endIndent: 14,
                            ),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountIntegrationsSettingsPage extends StatelessWidget {
  const _AccountIntegrationsSettingsPage({required this.integrations});

  final List<SpetoIntegrationConnection> integrations;

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Entegrasyonlar',
      child: _DetailSectionCard(
        padding: EdgeInsets.zero,
        child: integrations.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: _EmptyState(
                  title: 'Entegrasyon bulunamadı',
                  description: 'Bağlı servisler burada listelenir.',
                  icon: Icons.link_off_rounded,
                ),
              )
            : Column(
                children: List<Widget>.generate(integrations.length, (
                  int index,
                ) {
                  final SpetoIntegrationConnection integration =
                      integrations[index];
                  final Color tone = _healthColor(integration.health);
                  return Column(
                    children: <Widget>[
                      _DetailListTile(
                        icon: Icons.settings_ethernet_rounded,
                        title: integration.name,
                        subtitle:
                            '${integration.provider} • ${integration.type.name}',
                        iconTone: tone,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _healthLabel(integration.health),
                            style: TextStyle(
                              color: tone,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      if (index != integrations.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: _line.withValues(alpha: 0.7),
                          indent: 60,
                          endIndent: 12,
                        ),
                    ],
                  );
                }),
              ),
      ),
    );
  }
}

class _AccountSupportCenterPage extends StatelessWidget {
  const _AccountSupportCenterPage();

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Destek Merkezi',
      child: Column(
        children: <Widget>[
          _DetailSectionCard(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _successSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: const <Widget>[
                  Icon(Icons.support_agent_rounded, color: _success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Canlı Destek',
                      style: TextStyle(
                        color: _success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _success),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DetailSectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: const <Widget>[
                _DetailListTile(
                  icon: Icons.assignment_outlined,
                  title: 'Destek Talebi Oluştur',
                  subtitle: 'Sorunları kayıt altına alın',
                ),
                Divider(indent: 60, endIndent: 12, height: 1, thickness: 1),
                _DetailListTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Yardım Merkezi',
                  subtitle: 'Sık sorulan sorular ve çözümler',
                ),
                Divider(indent: 60, endIndent: 12, height: 1, thickness: 1),
                _DetailListTile(
                  icon: Icons.menu_book_outlined,
                  title: 'SSS',
                  subtitle: 'Sistem kullanım soruları',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSecurityPage extends StatelessWidget {
  const _AccountSecurityPage({required this.session});

  final SpetoSession session;

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Güvenlik',
      child: _DetailSectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            const _DetailListTile(
              icon: Icons.lock_outline_rounded,
              title: 'Şifre Değiştir',
              subtitle: 'Hesap şifrenizi güncelleyin',
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: _line.withValues(alpha: 0.7),
              indent: 60,
              endIndent: 12,
            ),
            _DetailListTile(
              icon: Icons.verified_user_outlined,
              title: 'İki Faktörlü Doğrulama (2FA)',
              subtitle: 'Hesabınızı ek güvenlikle koruyun',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (session.phone.isEmpty ? _warningSoft : _successSoft),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  session.phone.isEmpty ? 'Pasif' : 'Açık',
                  style: TextStyle(
                    color: session.phone.isEmpty ? _warning : _success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: _line.withValues(alpha: 0.7),
              indent: 60,
              endIndent: 12,
            ),
            const _DetailListTile(
              icon: Icons.history_rounded,
              title: 'Oturum Geçmişi',
              subtitle: 'Son cihaz girişlerini görüntüleyin',
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: _line.withValues(alpha: 0.7),
              indent: 60,
              endIndent: 12,
            ),
            const _DetailListTile(
              icon: Icons.smartphone_outlined,
              title: 'Cihaz Yönetimi',
              subtitle: 'Bağlı cihazları gözden geçirin',
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceSummaryCard extends StatelessWidget {
  const _FinanceSummaryCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.subtitle,
  });

  final String title;
  final String value;
  final Color accent;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NotificationPreference {
  const _NotificationPreference({
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final bool enabled;

  _NotificationPreference copyWith({bool? enabled}) {
    return _NotificationPreference(
      title: title,
      subtitle: subtitle,
      enabled: enabled ?? this.enabled,
    );
  }
}

class _WorkingHourSlot {
  const _WorkingHourSlot({
    required this.day,
    required this.hours,
    this.enabled = true,
  });

  final String day;
  final String hours;
  final bool enabled;

  _WorkingHourSlot copyWith({String? day, String? hours, bool? enabled}) {
    return _WorkingHourSlot(
      day: day ?? this.day,
      hours: hours ?? this.hours,
      enabled: enabled ?? this.enabled,
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.tone,
    required this.note,
  });

  final String label;
  final String value;
  final Color tone;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _StatusPill(
            label: label,
            color: tone,
            backgroundColor: tone.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(color: _muted, height: 1.45)),
        ],
      ),
    );
  }
}

class _OpsPageIntroCard extends StatelessWidget {
  const _OpsPageIntroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.compact,
    this.trailing,
    this.badges = const <Widget>[],
    this.footer,
    this.tone = _success,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;
  final Widget? trailing;
  final List<Widget> badges;
  final Widget? footer;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _OpsPageIntroHeader(
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  tone: tone,
                  compact: compact,
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(height: 14),
                  trailing!,
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _OpsPageIntroHeader(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    tone: tone,
                    compact: compact,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 16),
                  Flexible(child: trailing!),
                ],
              ],
            ),
          if (badges.isNotEmpty) ...<Widget>[
            SizedBox(height: compact ? 14 : 16),
            Wrap(spacing: 10, runSpacing: 10, children: badges),
          ],
          if (footer != null) ...<Widget>[
            SizedBox(height: compact ? 14 : 16),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _OpsPageIntroHeader extends StatelessWidget {
  const _OpsPageIntroHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: compact ? 48 : 54,
          height: compact ? 48 : 54,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: tone, size: compact ? 24 : 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 24 : 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpsInlineStat extends StatelessWidget {
  const _OpsInlineStat({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({required this.children, this.minItemWidth = 180});

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (children.isEmpty) {
          return const SizedBox.shrink();
        }
        final double width = constraints.maxWidth;
        const double spacing = 12;
        final int columns = width < (minItemWidth * 2 + spacing) ? 1 : 2;
        final double itemWidth = (width - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((Widget child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _CampaignOfferCard extends StatelessWidget {
  const _CampaignOfferCard({required this.offer});

  final SpetoHappyHourOffer offer;

  @override
  Widget build(BuildContext context) {
    final Color stockTone = _stockColor(offer.stockStatus);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 520;
        return _SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _CampaignOfferCardBody(
                      offer: offer,
                      stockTone: stockTone,
                      compact: compact,
                    ),
                  ],
                )
              : _CampaignOfferCardBody(
                  offer: offer,
                  stockTone: stockTone,
                  compact: compact,
                ),
        );
      },
    );
  }
}

class _CampaignOfferCardBody extends StatelessWidget {
  const _CampaignOfferCardBody({
    required this.offer,
    required this.stockTone,
    required this.compact,
  });

  final SpetoHappyHourOffer offer;
  final Color stockTone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ThumbImage(imageUrl: offer.imageUrl, label: offer.title, size: 68),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _StatusPill(
                        label: '%${offer.discountPercent} indirim',
                        color: _success,
                        backgroundColor: _successSoft,
                      ),
                      _StatusPill(
                        label: _stockLabel(offer.stockStatus),
                        color: stockTone,
                        backgroundColor: stockTone.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    offer.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${offer.vendorName} • ${offer.sectionLabel}',
                    style: const TextStyle(color: _muted, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDECE4)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      offer.discountedPriceText,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.originalPriceText} yerine',
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _InfoPill(
                    label: '${offer.claimCount} talep',
                    compact: compact,
                  ),
                  const SizedBox(height: 8),
                  _InfoPill(
                    label: '${offer.expiresInMinutes} dk kaldı',
                    compact: compact,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (offer.badge.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _InfoPill(label: offer.badge, compact: compact),
        ],
      ],
    );
  }
}

class _RevenueOrderTile extends StatelessWidget {
  const _RevenueOrderTile({required this.order});

  final SpetoOpsOrder order;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      tint: _panel,
      child: Row(
        children: <Widget>[
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
                  '${order.paymentMethod} • ${order.placedAtLabel}',
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          Text(
            '${order.payableTotal.toStringAsFixed(0)} TL',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HelpTopicTile extends StatelessWidget {
  const _HelpTopicTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SurfaceCard(
        padding: const EdgeInsets.all(16),
        tint: _panel,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _accentDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(color: _muted, height: 1.5),
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
    final int productCount = vendor.sections.fold<int>(
      0,
      (int sum, SpetoCatalogSection section) => sum + section.products.length,
    );
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: _ResponsiveCardGrid(
              minItemWidth: compact ? 120 : 150,
              children: <Widget>[
                _CompactMetricTile(
                  label: 'Kategori',
                  value: '${vendor.sections.length}',
                  tone: _info,
                ),
                _CompactMetricTile(
                  label: 'Ürün',
                  value: '$productCount',
                  tone: _success,
                ),
                _CompactMetricTile(
                  label: 'Operatör',
                  value: '${vendor.operatorAccounts.length}',
                  tone: _accent,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _line),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _VendorTabChip(
                      label: 'Vitrin',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _VendorTabChip(
                      label: 'Kategoriler',
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                    const SizedBox(width: 8),
                    _VendorTabChip(
                      label: 'Ürünler',
                      selected: _tabIndex == 2,
                      onTap: () => setState(() => _tabIndex = 2),
                    ),
                    const SizedBox(width: 8),
                    _VendorTabChip(
                      label: 'Operatörler',
                      selected: _tabIndex == 3,
                      onTap: () => setState(() => _tabIndex = 3),
                    ),
                    const SizedBox(width: 8),
                    _VendorTabChip(
                      label: 'Ayarlar',
                      selected: _tabIndex == 4,
                      onTap: () => setState(() => _tabIndex = 4),
                    ),
                  ],
                ),
              ),
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.05),
                    const Color(0x14FFF6E9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _BackdropFlowPainter()),
          ),
          Positioned(
            top: -132,
            left: -64,
            child: _BackdropGlow(
              width: 340,
              height: 340,
              colors: <Color>[Color(0x42F6C986), Color(0x00F6C986)],
            ),
          ),
          Positioned(
            top: 92,
            right: -112,
            child: _BackdropGlow(
              width: 300,
              height: 260,
              colors: <Color>[Color(0x2A5CA86F), Color(0x005CA86F)],
            ),
          ),
          Positioned(
            left: 24,
            bottom: 88,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 220,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0x1AC56B1A), Color(0x06C56B1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0x12C56B1A)),
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -74,
            child: _BackdropGlow(
              width: 260,
              height: 260,
              colors: <Color>[Color(0x3654A36D), Color(0x0054A36D)],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width),
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _BackdropFlowPainter extends CustomPainter {
  const _BackdropFlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint warmStroke = Paint()
      ..color = const Color(0x14C56B1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final Paint coolStroke = Paint()
      ..color = const Color(0x124C7C5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Path topArc = Path()
      ..moveTo(-size.width * 0.08, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.05,
        size.width * 0.56,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.26,
        size.width * 1.06,
        size.height * 0.08,
      );

    final Path lowerArc = Path()
      ..moveTo(-size.width * 0.04, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.58,
        size.width * 0.48,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.86,
        size.width * 1.04,
        size.height * 0.66,
      );

    final Path sideArc = Path()
      ..moveTo(size.width * 0.82, -size.height * 0.04)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.24,
        size.width * 0.88,
        size.height * 0.46,
      )
      ..quadraticBezierTo(
        size.width * 1.02,
        size.height * 0.68,
        size.width * 0.92,
        size.height * 1.04,
      );

    canvas.drawPath(topArc, warmStroke);
    canvas.drawPath(lowerArc, warmStroke);
    canvas.drawPath(sideArc, coolStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _SidebarNav extends StatefulWidget {
  const _SidebarNav({
    required this.items,
    required this.selectedDestination,
    required this.onSelected,
    required this.session,
    required this.selectedVendorLabel,
    required this.snapshot,
    this.drawerMode = false,
  });

  final List<_NavItem> items;
  final _StockDestination selectedDestination;
  final ValueChanged<_StockDestination> onSelected;
  final SpetoSession session;
  final String selectedVendorLabel;
  final SpetoInventorySnapshot? snapshot;
  final bool drawerMode;

  @override
  State<_SidebarNav> createState() => _SidebarNavState();
}

class _SidebarNavState extends State<_SidebarNav> {
  bool _showOverview = true;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final bool nextValue = notification.metrics.pixels <= 0.5;
    if (nextValue != _showOverview) {
      setState(() {
        _showOverview = nextValue;
      });
    }
    return false;
  }

  void _closeDrawerIfNeeded() {
    if (widget.drawerMode) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.drawerMode ? null : 276,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _sidebar,
        borderRadius: BorderRadius.circular(widget.drawerMode ? 28 : 34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _showOverview
                ? Padding(
                    key: const ValueKey<String>('sidebar-overview-visible'),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SidebarOverview(
                      session: widget.session,
                      selectedVendorLabel: widget.selectedVendorLabel,
                      snapshot: widget.snapshot,
                    ),
                  )
                : const SizedBox(
                    key: ValueKey<String>('sidebar-overview-hidden'),
                  ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: widget.items.length,
                separatorBuilder: (_, int index) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final _NavItem item = widget.items[index];
                  final bool selected =
                      item.destination == widget.selectedDestination;
                  return InkWell(
                    onTap: () {
                      _closeDrawerIfNeeded();
                      widget.onSelected(item.destination);
                    },
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
          ),
        ],
      ),
    );
  }
}

class _SidebarOverview extends StatelessWidget {
  const _SidebarOverview({
    required this.session,
    required this.selectedVendorLabel,
    required this.snapshot,
  });

  final SpetoSession session;
  final String selectedVendorLabel;
  final SpetoInventorySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('sidebar-overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFF3B660), Color(0xFFC56B1A)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'SepetPro İşyeri',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedVendorLabel,
                style: const TextStyle(
                  color: Color(0xFFE9DACA),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${session.displayName} • ${_roleLabel(session.role)}',
                style: const TextStyle(
                  color: Color(0xFFB8AAA0),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (snapshot != null) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
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
        ],
      ],
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
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ],
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

class _MobileOrderCard extends StatelessWidget {
  const _MobileOrderCard({required this.order, required this.onAdvance});

  final SpetoOpsOrder order;
  final Future<void> Function(SpetoOpsOrder order, SpetoOpsOrderStage stage)
  onAdvance;

  @override
  Widget build(BuildContext context) {
    final List<SpetoOpsOrderStage> actions = _nextOpsStages(order.opsStatus);
    final Color stageTone = _ordersStageColor(order.opsStatus);
    final String stageLabel = _ordersStageLabel(order.opsStatus);
    final String itemSummary = _orderItemsSummary(order);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line.withValues(alpha: 0.96)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x101E1917),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: stageTone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  order.items.length > 1
                      ? Icons.shopping_bag_outlined
                      : Icons.receipt_long_outlined,
                  color: stageTone,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sipariş #${_orderReference(order)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      itemSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.vendor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _orderTimeLabel(order),
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(order.payableTotal),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusPill(
                    label: stageLabel,
                    color: stageTone,
                    backgroundColor: stageTone.withValues(alpha: 0.12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3EEE6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...order.items.take(2).map((SpetoCartItem item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.totalPrice.toStringAsFixed(0)} TL',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (order.items.length > 2)
                  Text(
                    '+${order.items.length - 2} ürün daha',
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(label: order.deliveryMode, compact: true),
              _InfoPill(label: order.paymentMethod, compact: true),
              _InfoPill(label: _orderDateLabel(order), compact: true),
            ],
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: List<Widget>.generate(actions.length * 2 - 1, (
                int index,
              ) {
                if (index.isOdd) {
                  return const SizedBox(width: 8);
                }
                final SpetoOpsOrderStage nextStage = actions[index ~/ 2];
                final bool destructive =
                    nextStage == SpetoOpsOrderStage.cancelled;
                final Widget button = destructive
                    ? FilledButton(
                        onPressed: () => onAdvance(order, nextStage),
                        style: FilledButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(_orderActionLabel(nextStage)),
                      )
                    : FilledButton(
                        onPressed: () => onAdvance(order, nextStage),
                        style: FilledButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(_orderActionLabel(nextStage)),
                      );
                return Expanded(child: button);
              }),
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
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _ThumbImage(imageUrl: vendor.image, label: vendor.title, size: 88),
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
                      label: vendor.isActive ? 'Açık' : 'Pasif',
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
                    if (vendor.badge.isNotEmpty) _InfoPill(label: vendor.badge),
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
                style: FilledButton.styleFrom(
                  backgroundColor: _success,
                  foregroundColor: Colors.white,
                ),
                label: const Text('Yeni ürün'),
              ),
            ],
          ),
        ],
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
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _HeaderActionPill extends StatelessWidget {
  const _HeaderActionPill({required this.label, this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _successSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7EDE2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: _success),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _success,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: content,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.sizeOf(context).width < 560
        ? MediaQuery.sizeOf(context).width * 0.72
        : 320;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 13 : 14,
          ),
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

class _GlassBottomNavBar extends StatelessWidget {
  const _GlassBottomNavBar({
    required this.items,
    required this.selectedDestination,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final _StockDestination selectedDestination;
  final ValueChanged<_StockDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _line.withValues(alpha: 0.9)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x141E1917),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: items
                .map((_NavItem item) {
                  final bool selected = item.destination == selectedDestination;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelected(item.destination),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFF3FAF6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            border: selected
                                ? Border.all(color: const Color(0xFFD7EDE2))
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: selected ? 38 : 34,
                                height: selected ? 38 : 34,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _successSoft
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  item.icon,
                                  color: selected ? _success : _ink,
                                  size: selected ? 21 : 20,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: selected ? _ink : _muted,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.description, this.destination);

  final String label;
  final IconData icon;
  final String description;
  final _StockDestination destination;
}
