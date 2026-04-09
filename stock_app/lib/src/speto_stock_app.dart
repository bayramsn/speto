import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speto_shared/speto_shared.dart';

const Color _bg = Color(0xFFF4EFE7);
const Color _panel = Colors.white;
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF6B7280);
const Color _accent = Color(0xFFD97706);
const Color _accentSoft = Color(0xFFFFF1D6);
const Color _danger = Color(0xFFB91C1C);
const Color _success = Color(0xFF15803D);

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
    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: _bg,
      textTheme: GoogleFonts.spaceGroteskTextTheme(),
      useMaterial3: true,
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
    _probeBackend();
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
                              label: 'Burger Vendor',
                              email: 'burger@speto.app',
                              password: 'vendor123',
                            ),
                            _CredentialChip(
                              label: 'Market Vendor',
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
  String? _warning;
  String? _selectedVendorId;
  String? _selectedInventoryId;

  SpetoInventorySnapshot? _dashboard;
  List<SpetoInventoryItem> _inventoryItems = <SpetoInventoryItem>[];
  List<SpetoOpsOrder> _orders = <SpetoOpsOrder>[];
  List<SpetoIntegrationConnection> _integrations =
      <SpetoIntegrationConnection>[];
  List<SpetoInventoryMovement> _movements = <SpetoInventoryMovement>[];

  List<String> get _vendorOptions {
    if (widget.session.role == SpetoUserRole.admin) {
      return widget.session.vendorScopes;
    }
    if (widget.session.vendorScopes.isNotEmpty) {
      return widget.session.vendorScopes;
    }
    return const <String>['vendor-burger-yiyelim'];
  }

  @override
  void initState() {
    super.initState();
    _selectedVendorId = _vendorOptions.first;
    _reload();
  }

  String? _resolvedVendorId() {
    if (widget.session.role == SpetoUserRole.admin) {
      return _selectedVendorId;
    }
    if (widget.session.vendorScopes.isNotEmpty) {
      return widget.session.vendorScopes.first;
    }
    return null;
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
      _warning = null;
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
    final bool hasAnyData =
        resolvedSnapshot.items.isNotEmpty ||
        orders.isNotEmpty ||
        integrations.isNotEmpty;

    setState(() {
      _dashboard = resolvedSnapshot;
      _inventoryItems = inventory;
      _orders = orders;
      _integrations = integrations;
      _selectedInventoryId = selectedInventoryId;
      _movements = movements;
      _error = hasAnyData
          ? null
          : 'Operasyon verisi yüklenemedi. Backend bağlantısını ve giriş durumunu kontrol edin.';
      _warning = warnings.isEmpty ? null : warnings.join('\n');
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
          title: Text(restock ? 'Restock gir' : 'Manuel düzeltme'),
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
          restock ? 'Restock kaydedildi.' : 'Manuel düzeltme kaydedildi.',
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
      _showMessage('Sync isteği zaman aşımına uğradı.', isError: true);
    } catch (_) {
      _showMessage('Sync işlemi başlatılamadı.', isError: true);
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
                decoration: const InputDecoration(labelText: 'Provider'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(labelText: 'Base URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location ID'),
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
      await widget.api.createIntegration(
        vendorId: _selectedVendorId ?? _vendorOptions.first,
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

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 980;
    final List<_NavItem> items = const <_NavItem>[
      _NavItem('Dashboard', Icons.dashboard_customize_outlined),
      _NavItem('Inventory', Icons.inventory_2_outlined),
      _NavItem('Orders', Icons.receipt_long_outlined),
      _NavItem('Integrations', Icons.hub_outlined),
    ];

    return Scaffold(
      body: Row(
        children: <Widget>[
          if (!compact)
            NavigationRail(
              backgroundColor: const Color(0xFFF8F6F0),
              selectedIndex: _index,
              destinations: items
                  .map(
                    (_NavItem item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(growable: false),
              onDestinationSelected: (int value) {
                setState(() {
                  _index = value;
                });
              },
              leading: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  _TopBar(
                    session: widget.session,
                    selectedVendorId: _selectedVendorId,
                    vendorOptions: _vendorOptions,
                    onVendorChanged: widget.session.role == SpetoUserRole.admin
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
                  if (_warning != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _InlineBanner(
                        message: _warning!,
                        color: _accent,
                        backgroundColor: _accentSoft,
                      ),
                    ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: _danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          )
                        : IndexedStack(
                            index: _index,
                            children: <Widget>[
                              _DashboardPage(
                                snapshot: _dashboard!,
                                orders: _orders,
                                integrations: _integrations,
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
                                  } on SpetoRemoteApiException catch (error) {
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
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: _index,
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
            )
          : null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.session,
    required this.selectedVendorId,
    required this.vendorOptions,
    required this.onVendorChanged,
    required this.onRefresh,
    required this.onSignOut,
  });

  final SpetoSession session;
  final String? selectedVendorId;
  final List<String> vendorOptions;
  final ValueChanged<String?>? onVendorChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Operational Control',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${session.displayName} • ${session.role.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onVendorChanged != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<String>(
                value: selectedVendorId,
                underline: const SizedBox.shrink(),
                items: vendorOptions
                    .map(
                      (String vendor) => DropdownMenuItem<String>(
                        value: vendor,
                        child: Text(vendor),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onVendorChanged,
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.snapshot,
    required this.orders,
    required this.integrations,
  });

  final SpetoInventorySnapshot snapshot;
  final List<SpetoOpsOrder> orders;
  final List<SpetoIntegrationConnection> integrations;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _MetricCard(
                label: 'Toplam SKU',
                value: '${snapshot.totalItems}',
                caption: 'Aktif takip edilen ürün',
              ),
              _MetricCard(
                label: 'Düşük stok',
                value: '${snapshot.lowStockCount}',
                caption: 'Kritik seviyeye yaklaşan',
                accent: _accent,
              ),
              _MetricCard(
                label: 'Stok tükendi',
                value: '${snapshot.outOfStockCount}',
                caption: 'Satışa kapalı ürün',
                accent: _danger,
              ),
              _MetricCard(
                label: 'Açık sipariş',
                value: '${snapshot.openOrdersCount}',
                caption: 'Operasyon akışında bekliyor',
                accent: _success,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: _SectionCard(
                  title: 'Kritik ürünler',
                  child: snapshot.items.isEmpty
                      ? const _EmptyState(
                          title: 'Stok verisi yok',
                          description:
                              'Seçili vendor için henüz takip edilen ürün görünmüyor.',
                        )
                      : Column(
                          children: snapshot.items
                              .take(5)
                              .map((SpetoInventoryItem item) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item.vendorName} • ${item.sku}',
                                  ),
                                  trailing: _StatusPill(
                                    label: item.stockStatus.isInStock
                                        ? '${item.stockStatus.availableQuantity} adet'
                                        : 'Tükendi',
                                    color: item.stockStatus.isInStock
                                        ? _accent
                                        : _danger,
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _SectionCard(
                  title: 'Senkron sağlık',
                  child: integrations.isEmpty
                      ? const _EmptyState(
                          title: 'Entegrasyon yok',
                          description:
                              'Bu vendor için henüz ERP veya POS bağlantısı tanımlanmadı.',
                        )
                      : Column(
                          children: integrations
                              .map((SpetoIntegrationConnection integration) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    integration.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${integration.provider} • ${integration.lastSync.status.name}',
                                  ),
                                  trailing: _StatusPill(
                                    label: integration.health.name
                                        .toUpperCase(),
                                    color: switch (integration.health) {
                                      SpetoIntegrationHealth.healthy =>
                                        _success,
                                      SpetoIntegrationHealth.warning => _accent,
                                      SpetoIntegrationHealth.failed => _danger,
                                    },
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Açık sipariş akışı',
            child: orders.isEmpty
                ? const _EmptyState(
                    title: 'Açık sipariş yok',
                    description:
                        'Operasyon akışına düşen aktif sipariş bulunduğunda burada görünür.',
                  )
                : Column(
                    children: orders
                        .take(6)
                        .map((SpetoOpsOrder order) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              order.vendor,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${order.items.first.title} • ${order.pickupCode}',
                            ),
                            trailing: _StatusPill(
                              label: order.opsStatus.name.toUpperCase(),
                              color:
                                  order.opsStatus ==
                                      SpetoOpsOrderStage.completed
                                  ? _success
                                  : order.opsStatus ==
                                        SpetoOpsOrderStage.cancelled
                                  ? _danger
                                  : _accent,
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

class _InventoryPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 980;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: _SectionCard(
          title: 'Inventory',
          child: _EmptyState(
            title: 'Ürün bulunamadı',
            description:
                'Seçili vendor için stok kartı bulunmuyor. Restock veya ürün eşlemesi sonrası burada listelenir.',
          ),
        ),
      );
    }
    final SpetoInventoryItem? selected = items
        .cast<SpetoInventoryItem?>()
        .firstWhere(
          (SpetoInventoryItem? item) => item?.id == selectedId,
          orElse: () => items.isNotEmpty ? items.first : null,
        );
    if (compact) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: items
            .map((SpetoInventoryItem item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InventoryCard(
                  item: item,
                  selected: item.id == selected?.id,
                  movements: item.id == selected?.id
                      ? movements
                      : const <SpetoInventoryMovement>[],
                  onTap: () => onSelected(item.id),
                  onAdjust: () => onAdjust(item),
                  onRestock: () => onRestock(item),
                ),
              );
            })
            .toList(growable: false),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SectionCard(
              title: 'Ürün listesi',
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, int index) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final SpetoInventoryItem item = items[index];
                  return ListTile(
                    onTap: () => onSelected(item.id),
                    selected: item.id == selected?.id,
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${item.vendorName} • ${item.sku}'),
                    trailing: _StatusPill(
                      label: item.stockStatus.isInStock
                          ? '${item.stockStatus.availableQuantity} adet'
                          : 'Tükendi',
                      color: item.stockStatus.isInStock ? _accent : _danger,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: selected == null
                ? const Center(child: Text('Ürün seçilmedi'))
                : _InventoryCard(
                    item: selected,
                    selected: true,
                    movements: movements,
                    onTap: () {},
                    onAdjust: () => onAdjust(selected),
                    onRestock: () => onRestock(selected),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? _accent : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
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
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.vendorName} • ${item.locationLabel}',
                        style: const TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: item.stockStatus.isInStock ? 'Satışta' : 'Kapalı',
                  color: item.stockStatus.isInStock ? _success : _danger,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InfoPill(label: 'On hand ${item.onHand}'),
                _InfoPill(label: 'Reserved ${item.reserved}'),
                _InfoPill(label: 'Available ${item.availableQuantity}'),
                _InfoPill(label: 'Reorder ${item.reorderLevel}'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Düzelt'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onRestock,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('Restock'),
                ),
              ],
            ),
            if (movements.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Text(
                'Hareket geçmişi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...movements.take(4).map((SpetoInventoryMovement movement) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(movement.type.name),
                  subtitle: Text(movement.createdAtLabel),
                  trailing: Text(
                    '${movement.quantityDelta >= 0 ? '+' : ''}${movement.quantityDelta}',
                    style: TextStyle(
                      color: movement.quantityDelta >= 0 ? _success : _danger,
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
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: _SectionCard(
          title: 'Orders',
          child: _EmptyState(
            title: 'Sipariş kuyruğu boş',
            description:
                'Yeni siparişler operasyon akışına düştüğünde bu ekranda ilerletilebilir.',
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: orders.length,
      itemBuilder: (BuildContext context, int index) {
        final SpetoOpsOrder order = orders[index];
        final List<SpetoOpsOrderStage> actions = _nextStages(order.opsStatus);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SectionCard(
            title: order.vendor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${order.items.first.title} • ${order.pickupCode}',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _StatusPill(
                      label: order.opsStatus.name.toUpperCase(),
                      color: order.opsStatus == SpetoOpsOrderStage.completed
                          ? _success
                          : order.opsStatus == SpetoOpsOrderStage.cancelled
                          ? _danger
                          : _accent,
                    ),
                    ...actions.map((SpetoOpsOrderStage stage) {
                      return FilledButton.tonal(
                        onPressed: () => onAdvance(order, stage),
                        child: Text(stage.name.toUpperCase()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SpetoOpsOrderStage> _nextStages(SpetoOpsOrderStage current) {
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_link_rounded),
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
            ),
            label: const Text('Entegrasyon ekle'),
          ),
        ),
        const SizedBox(height: 14),
        if (integrations.isEmpty)
          const _SectionCard(
            title: 'Entegrasyonlar',
            child: _EmptyState(
              title: 'Bağlantı bulunamadı',
              description:
                  'Yeni bir ERP veya POS bağlantısı oluşturup ardından sync çalıştırabilirsiniz.',
            ),
          ),
        ...integrations.map((SpetoIntegrationConnection connection) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionCard(
              title: connection.name,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${connection.provider} • ${connection.baseUrl}',
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _StatusPill(
                        label: connection.health.name.toUpperCase(),
                        color: switch (connection.health) {
                          SpetoIntegrationHealth.healthy => _success,
                          SpetoIntegrationHealth.warning => _accent,
                          SpetoIntegrationHealth.failed => _danger,
                        },
                      ),
                      _InfoPill(
                        label:
                            'Processed ${connection.lastSync.processedCount}',
                      ),
                      _InfoPill(
                        label: connection.lastSync.status.name.toUpperCase(),
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
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
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
  });

  final String message;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    this.accent = _ink,
  });

  final String label;
  final String value;
  final String caption;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(caption, style: const TextStyle(color: _muted)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
