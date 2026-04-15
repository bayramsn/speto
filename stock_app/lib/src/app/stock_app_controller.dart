import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speto_shared/speto_shared.dart';

typedef StockSharedPreferencesLoader = Future<SharedPreferences> Function();
typedef StockApiBundle = ({
  SpetoRemoteDomainApi api,
  SpetoRemoteApiClient? client,
});
typedef StockApiResolver =
    Future<StockApiBundle> Function(SpetoSession? session);

class StockWorkingDay {
  StockWorkingDay({
    required this.label,
    required this.shortLabel,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  final String label;
  final String shortLabel;
  bool isOpen;
  String openTime;
  String closeTime;

  StockWorkingDay copy() {
    return StockWorkingDay(
      label: label,
      shortLabel: shortLabel,
      isOpen: isOpen,
      openTime: openTime,
      closeTime: closeTime,
    );
  }
}

class StockRegistrationDraft {
  StockRegistrationDraft();

  SpetoStorefrontType storefrontType = SpetoStorefrontType.restaurant;
  String businessName = '';
  String businessCategory = '';
  String businessSubtitle = '';
  String businessImageUrl = '';
  String city = '';
  String district = '';
  String pickupPointLabel = '';
  String pickupPointAddress = '';
  String operatorEmail = '';
  String operatorPassword = '';
  String operatorDisplayName = '';
  String operatorPhone = '';
  String bankHolderName = '';
  String bankName = '';
  String iban = '';
  String taxNumber = '';
  String taxOffice = '';
  bool termsAccepted = false;
  bool privacyAccepted = false;
  bool marketingOptIn = false;
  bool notifyNewOrders = true;
  bool notifyCancellations = true;
  bool notifyLowStock = true;
  bool notifyCampaignTips = false;
  bool notifySms = false;
  bool notifyPush = true;
  List<StockWorkingDay> workingDays = <StockWorkingDay>[
    StockWorkingDay(
      label: 'Pazartesi',
      shortLabel: 'Pzt',
      isOpen: true,
      openTime: '09:00',
      closeTime: '22:00',
    ),
    StockWorkingDay(
      label: 'Salı',
      shortLabel: 'Sal',
      isOpen: true,
      openTime: '09:00',
      closeTime: '22:00',
    ),
    StockWorkingDay(
      label: 'Çarşamba',
      shortLabel: 'Çar',
      isOpen: true,
      openTime: '09:00',
      closeTime: '22:00',
    ),
    StockWorkingDay(
      label: 'Perşembe',
      shortLabel: 'Per',
      isOpen: true,
      openTime: '09:00',
      closeTime: '22:00',
    ),
    StockWorkingDay(
      label: 'Cuma',
      shortLabel: 'Cum',
      isOpen: true,
      openTime: '09:00',
      closeTime: '23:00',
    ),
    StockWorkingDay(
      label: 'Cumartesi',
      shortLabel: 'Cmt',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StockWorkingDay(
      label: 'Pazar',
      shortLabel: 'Paz',
      isOpen: false,
      openTime: '10:00',
      closeTime: '22:00',
    ),
  ];

  String get workingHoursLabel {
    final List<StockWorkingDay> openDays = workingDays
        .where((StockWorkingDay day) => day.isOpen)
        .toList();
    if (openDays.isEmpty) {
      return 'Kapalı';
    }
    final bool sameHours = openDays.every(
      (StockWorkingDay day) =>
          day.openTime == openDays.first.openTime &&
          day.closeTime == openDays.first.closeTime,
    );
    if (sameHours) {
      return '${openDays.first.shortLabel}-${openDays.last.shortLabel} '
          '${openDays.first.openTime}-${openDays.first.closeTime}';
    }
    return openDays
        .map(
          (StockWorkingDay day) =>
              '${day.shortLabel} ${day.openTime}-${day.closeTime}',
        )
        .join(', ');
  }

  void reset() {
    final StockRegistrationDraft fresh = StockRegistrationDraft();
    storefrontType = fresh.storefrontType;
    businessName = fresh.businessName;
    businessCategory = fresh.businessCategory;
    businessSubtitle = fresh.businessSubtitle;
    businessImageUrl = fresh.businessImageUrl;
    city = fresh.city;
    district = fresh.district;
    pickupPointLabel = fresh.pickupPointLabel;
    pickupPointAddress = fresh.pickupPointAddress;
    operatorEmail = fresh.operatorEmail;
    operatorPassword = fresh.operatorPassword;
    operatorDisplayName = fresh.operatorDisplayName;
    operatorPhone = fresh.operatorPhone;
    bankHolderName = fresh.bankHolderName;
    bankName = fresh.bankName;
    iban = fresh.iban;
    taxNumber = fresh.taxNumber;
    taxOffice = fresh.taxOffice;
    termsAccepted = fresh.termsAccepted;
    privacyAccepted = fresh.privacyAccepted;
    marketingOptIn = fresh.marketingOptIn;
    notifyNewOrders = fresh.notifyNewOrders;
    notifyCancellations = fresh.notifyCancellations;
    notifyLowStock = fresh.notifyLowStock;
    notifyCampaignTips = fresh.notifyCampaignTips;
    notifySms = fresh.notifySms;
    notifyPush = fresh.notifyPush;
    workingDays = fresh.workingDays
        .map((StockWorkingDay day) => day.copy())
        .toList();
  }
}

class StockAppController extends ChangeNotifier {
  StockAppController({
    StockSharedPreferencesLoader? sharedPreferencesLoader,
    StockApiResolver? apiResolver,
    SpetoSession? initialSession,
    bool initialBootstrapping = true,
    bool initialBackendReachable = false,
  }) : _sharedPreferencesLoader =
           sharedPreferencesLoader ?? SharedPreferences.getInstance,
       _apiResolver = apiResolver ?? _defaultApiResolver {
    _session = initialSession;
    _bootstrapping = initialBootstrapping;
    _backendReachable = initialBackendReachable;
  }

  static const String _sessionStorageKey = 'stock_app.session';
  static Future<StockApiBundle> _defaultApiResolver(
    SpetoSession? session,
  ) async {
    final SpetoRemoteApiClient client =
        await SpetoRemoteApiClient.resolveDefault(session: session);
    return (api: SpetoRemoteDomainApi(client), client: client);
  }

  final StockSharedPreferencesLoader _sharedPreferencesLoader;
  final StockApiResolver _apiResolver;

  SharedPreferences? _prefs;
  SpetoRemoteDomainApi? _api;
  SpetoSession? _session;
  bool _bootstrapping = true;
  bool _authenticating = false;
  bool _loading = false;
  bool _refreshingData = false;
  bool _checkingBackend = false;
  bool _backendReachable = false;
  String? _authError;
  String? _dashboardError;
  final Map<String, bool> _busyByKey = <String, bool>{};

  final StockRegistrationDraft registrationDraft = StockRegistrationDraft();

  List<SpetoCatalogVendor> vendors = const <SpetoCatalogVendor>[];
  String? selectedVendorId;
  SpetoInventorySnapshot? inventorySnapshot;
  List<SpetoInventoryItem> inventoryItems = const <SpetoInventoryItem>[];
  List<SpetoOpsOrder> orders = const <SpetoOpsOrder>[];
  List<SpetoCatalogProduct> products = const <SpetoCatalogProduct>[];
  List<SpetoIntegrationConnection> integrations =
      const <SpetoIntegrationConnection>[];
  SpetoVendorCampaignSummary? campaignSummary;
  SpetoVendorFinanceSummary? financeSummary;
  List<SpetoSupportTicket> supportTickets = const <SpetoSupportTicket>[];
  SpetoRemoteUserProfile? userProfile;

  bool get isBootstrapping => _bootstrapping;
  bool get isAuthenticating => _authenticating;
  bool get isLoading => _loading;
  bool get isCheckingBackend => _checkingBackend;
  bool get backendReachable => _backendReachable;
  bool get isAuthenticated => _session != null;
  String? get authError => _authError;
  String? get dashboardError => _dashboardError;
  SpetoSession? get session => _session;
  bool get isVendor => _session?.role == SpetoUserRole.vendor;

  SpetoCatalogVendor? get selectedVendor {
    for (final SpetoCatalogVendor vendor in vendors) {
      if (vendor.vendorId == selectedVendorId) {
        return vendor;
      }
    }
    return vendors.isNotEmpty ? vendors.first : null;
  }

  SpetoStorefrontType get storefrontType =>
      selectedVendor?.storefrontType ?? SpetoStorefrontType.market;

  bool get isRestaurantMode => storefrontType == SpetoStorefrontType.restaurant;

  bool isBusy(String key) => _busyByKey[key] == true;

  Future<void> bootstrap() async {
    _bootstrapping = true;
    _authError = null;
    _dashboardError = null;
    notifyListeners();

    SharedPreferences? prefs;
    try {
      prefs = await _sharedPreferencesLoader();
      SpetoSession? restoredSession = _readStoredSession(prefs);
      final StockApiBundle bundle = await _apiResolver(restoredSession);
      final SpetoRemoteDomainApi api = bundle.api;
      final SpetoRemoteApiClient? client = bundle.client;

      client?.setSessionChangedCallback((SpetoSession? nextSession) async {
        _session = nextSession;
        if (nextSession == null) {
          _resetDashboardState();
        }
        await _persistStoredSession(nextSession);
        notifyListeners();
      });

      _prefs = prefs;
      _api = api;
      if (restoredSession != null) {
        try {
          if (restoredSession.authToken.trim().isEmpty ||
              restoredSession.refreshToken.trim().isEmpty) {
            restoredSession = null;
            await _persistStoredSession(null);
          } else if (api.shouldRefreshSession()) {
            restoredSession = await api.refreshSession(
              refreshToken: restoredSession.refreshToken,
              notifyListeners: false,
            );
            await _persistStoredSession(restoredSession);
          }
        } catch (_) {
          restoredSession = null;
          await _persistStoredSession(null);
          api.clearSession();
        }
      }

      _session = restoredSession;
      unawaited(probeBackend());
      if (_session != null) {
        await refreshData();
      }
    } catch (error) {
      _session = null;
      _authError = 'Oturum yüklenemedi. Tekrar giriş yapın.';
      _dashboardError = explainError(error);
      _resetDashboardState();
      await prefs?.remove(_sessionStorageKey);
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> probeBackend() async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    _checkingBackend = true;
    notifyListeners();
    try {
      _backendReachable = await api.checkHealth();
    } catch (_) {
      _backendReachable = false;
    } finally {
      _checkingBackend = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return false;
    }
    _authenticating = true;
    _authError = null;
    notifyListeners();
    try {
      if (!_backendReachable) {
        await probeBackend();
      }
      if (!_backendReachable) {
        throw const _ControllerMessage(
          'Sunucu başlatılıyor olabilir. Biraz bekleyip tekrar deneyin.',
        );
      }
      final SpetoSession nextSession = await api.login(
        email: email.trim(),
        password: password,
      );
      if (nextSession.role != SpetoUserRole.vendor) {
        throw const _ControllerMessage(
          'Yönetici hesapları bu uygulamayı kullanamaz. Lütfen admin_panel üzerinden giriş yapın.',
        );
      }
      _session = nextSession;
      await _persistStoredSession(nextSession);
      await refreshData();
      return true;
    } catch (error) {
      _authError = explainError(error);
      notifyListeners();
      return false;
    } finally {
      _authenticating = false;
      notifyListeners();
    }
  }

  Future<bool> registerOperator() async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return false;
    }
    _authenticating = true;
    _authError = null;
    notifyListeners();
    try {
      _validateRegistrationDraft();
      if (!_backendReachable) {
        await probeBackend();
      }
      if (!_backendReachable) {
        throw const _ControllerMessage(
          'Sunucu başlatılıyor olabilir. Biraz bekleyip tekrar deneyin.',
        );
      }
      final SpetoSession nextSession = await api.registerOperator(
        storefrontType: registrationDraft.storefrontType,
        businessName: registrationDraft.businessName.trim(),
        businessCategory: registrationDraft.businessCategory.trim(),
        businessSubtitle: registrationDraft.businessSubtitle.trim(),
        businessImageUrl: registrationDraft.businessImageUrl.trim(),
        city: registrationDraft.city.trim(),
        district: registrationDraft.district.trim(),
        pickupPointLabel: registrationDraft.pickupPointLabel.trim().isEmpty
            ? 'Ana teslim noktası'
            : registrationDraft.pickupPointLabel.trim(),
        pickupPointAddress: registrationDraft.pickupPointAddress.trim(),
        workingHoursLabel: registrationDraft.workingHoursLabel,
        workingDays: registrationDraft.workingDays
            .map(
              (StockWorkingDay day) => <String, Object?>{
                'label': day.label,
                'shortLabel': day.shortLabel,
                'isOpen': day.isOpen,
                'openTime': day.openTime,
                'closeTime': day.closeTime,
              },
            )
            .toList(growable: false),
        email: registrationDraft.operatorEmail.trim(),
        password: registrationDraft.operatorPassword,
        displayName: registrationDraft.operatorDisplayName.trim(),
        phone: registrationDraft.operatorPhone.trim(),
        holderName: registrationDraft.bankHolderName.trim(),
        bankName: registrationDraft.bankName.trim().isEmpty
            ? 'Banka bilgisi'
            : registrationDraft.bankName.trim(),
        iban: registrationDraft.iban.trim(),
        taxNumber: registrationDraft.taxNumber.trim(),
        taxOffice: registrationDraft.taxOffice.trim(),
        termsAccepted: registrationDraft.termsAccepted,
        privacyAccepted: registrationDraft.privacyAccepted,
        marketingOptIn: registrationDraft.marketingOptIn,
        notifyNewOrders: registrationDraft.notifyNewOrders,
        notifyCancellations: registrationDraft.notifyCancellations,
        notifyLowStock: registrationDraft.notifyLowStock,
        notifyCampaignTips: registrationDraft.notifyCampaignTips,
        notifySms: registrationDraft.notifySms,
        notifyPush: registrationDraft.notifyPush,
      );
      _session = nextSession;
      registrationDraft.reset();
      await _persistStoredSession(nextSession);
      await refreshData();
      return true;
    } catch (error) {
      _authError = explainError(error);
      notifyListeners();
      return false;
    } finally {
      _authenticating = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final SpetoRemoteDomainApi? api = _api;
    final String refreshToken = _session?.refreshToken ?? '';
    try {
      if (api != null) {
        await api.logout(
          refreshToken: refreshToken.isEmpty ? null : refreshToken,
        );
      }
    } catch (_) {
      api?.clearSession();
    }
    _session = null;
    _resetDashboardState();
    await _persistStoredSession(null);
    notifyListeners();
  }

  Future<void> refreshData({bool silent = false}) async {
    final SpetoRemoteDomainApi? api = _api;
    final SpetoSession? currentSession = _session;
    if (api == null || currentSession == null || _refreshingData) {
      return;
    }
    _refreshingData = true;
    if (!silent) {
      _loading = true;
      _dashboardError = null;
      notifyListeners();
    }
    try {
      await _ensureFreshSession();
      final List<SpetoCatalogVendor> nextVendors = await api
          .fetchCatalogAdminVendors(vendorId: _sessionVendorId);
      vendors = nextVendors;
      selectedVendorId = _resolveSelectedVendorId(nextVendors);
      final String? vendorId = selectedVendorId;
      if (vendorId == null) {
        inventorySnapshot = null;
        inventoryItems = const <SpetoInventoryItem>[];
        orders = const <SpetoOpsOrder>[];
        products = const <SpetoCatalogProduct>[];
        integrations = const <SpetoIntegrationConnection>[];
        campaignSummary = null;
        financeSummary = null;
        supportTickets = const <SpetoSupportTicket>[];
        userProfile = null;
        return;
      }

      final List<Object?> results =
          await Future.wait<Object?>(<Future<Object?>>[
            api.fetchInventorySnapshot(vendorId: vendorId),
            api.fetchInventoryItems(vendorId: vendorId),
            api.fetchOpsOrders(vendorId: vendorId),
            api.fetchCatalogAdminProducts(vendorId: vendorId),
            api.fetchIntegrations(vendorId: vendorId),
            api.fetchCampaignSummary(vendorId: vendorId),
            api.fetchFinanceSummary(vendorId: vendorId),
            api.fetchSupportTickets(),
            api.fetchSnapshot(),
          ]);

      inventorySnapshot = results[0]! as SpetoInventorySnapshot;
      inventoryItems = results[1]! as List<SpetoInventoryItem>;
      orders = results[2]! as List<SpetoOpsOrder>;
      products = results[3]! as List<SpetoCatalogProduct>;
      integrations = results[4]! as List<SpetoIntegrationConnection>;
      campaignSummary = results[5]! as SpetoVendorCampaignSummary;
      financeSummary = results[6]! as SpetoVendorFinanceSummary;
      supportTickets = results[7]! as List<SpetoSupportTicket>;
      userProfile = (results[8]! as SpetoRemoteSnapshot).profile;
    } catch (error) {
      _dashboardError = explainError(error);
    } finally {
      _refreshingData = false;
      if (!silent) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  Future<void> selectVendor(String vendorId) async {
    final String? scopedVendorId = _sessionVendorId;
    if (scopedVendorId != null && scopedVendorId != vendorId) {
      return;
    }
    if (selectedVendorId == vendorId) {
      return;
    }
    selectedVendorId = vendorId;
    notifyListeners();
    await refreshData();
  }

  Future<void> updateOrderStatus(
    String orderId,
    SpetoOpsOrderStage stage,
  ) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    await _runBusy('order:$orderId', () async {
      await _ensureFreshSession();
      await api.updateOpsOrderStatus(orderId, stage);
      await refreshData();
    });
  }

  Future<void> adjustInventory({
    required String productId,
    required int quantityDelta,
    required String reason,
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    await _runBusy('inventory:$productId', () async {
      await _ensureFreshSession();
      await api.adjustInventoryItem(
        id: productId,
        quantityDelta: quantityDelta,
        reason: reason,
      );
      await refreshData();
    });
  }

  Future<void> restockInventory({
    required String productId,
    required int quantity,
    required String note,
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    await _runBusy('inventory:$productId', () async {
      await _ensureFreshSession();
      await api.restockInventoryItem(
        id: productId,
        quantity: quantity,
        note: note,
      );
      await refreshData();
    });
  }

  Future<void> saveProduct({
    String? productId,
    required String title,
    required String description,
    required String sectionLabel,
    required String category,
    required double unitPrice,
    String imageUrl = '',
    String displaySubtitle = '',
    String displayBadge = '',
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    final String? vendorId = selectedVendorId;
    if (api == null || vendorId == null) {
      return;
    }
    final Map<String, Object?> payload = <String, Object?>{
      'vendorId': vendorId,
      'title': title.trim(),
      'description': description.trim(),
      'sectionLabel': sectionLabel.trim(),
      'category': category.trim(),
      'unitPrice': unitPrice,
      'imageUrl': imageUrl.trim(),
      'displaySubtitle': displaySubtitle.trim(),
      'displayBadge': displayBadge.trim(),
    };
    await _runBusy('products:save', () async {
      await _ensureFreshSession();
      if (productId == null || productId.trim().isEmpty) {
        await api.createCatalogProduct(payload);
      } else {
        await api.updateCatalogProduct(productId, payload);
      }
      await refreshData();
    });
  }

  Future<void> toggleCampaign(String campaignId) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    await _runBusy('campaign:$campaignId', () async {
      await _ensureFreshSession();
      await api.toggleCampaign(campaignId);
      await refreshData();
    });
  }

  Future<void> createCampaign({
    required SpetoCampaignKind kind,
    required String title,
    required String description,
    String? scheduleLabel,
    String? badgeLabel,
    int? discountPercent,
    double? discountedPrice,
    List<String>? productIds,
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    final String? vendorId = selectedVendorId;
    if (api == null || vendorId == null) {
      return;
    }
    await _runBusy('campaigns:create', () async {
      await _ensureFreshSession();
      await api.createCampaign(
        vendorId: vendorId,
        kind: kind,
        title: title.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        status: SpetoCampaignStatus.active,
        scheduleLabel: scheduleLabel,
        badgeLabel: badgeLabel,
        discountPercent: discountPercent,
        discountedPrice: discountedPrice,
        productIds: productIds,
      );
      await refreshData();
    });
  }

  Future<void> createIntegration({
    required String name,
    required String provider,
    required SpetoIntegrationType type,
    required String baseUrl,
    required String locationId,
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    final String? vendorId = selectedVendorId;
    if (api == null || vendorId == null) {
      return;
    }
    await _runBusy('integrations:create', () async {
      await _ensureFreshSession();
      await api.createIntegration(
        vendorId: vendorId,
        name: name.trim(),
        provider: provider.trim(),
        type: type,
        baseUrl: baseUrl.trim(),
        locationId: locationId.trim(),
        skuMappings: const <String, String>{},
      );
      await refreshData();
    });
  }

  Future<void> syncIntegration(String integrationId) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    await _runBusy('integration:$integrationId', () async {
      await _ensureFreshSession();
      await api.syncIntegration(integrationId);
      await refreshData();
    });
  }

  Future<void> addBankAccount({
    required String holderName,
    required String bankName,
    required String iban,
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    final String? vendorId = selectedVendorId;
    if (api == null || vendorId == null) {
      return;
    }
    await _runBusy('finance:account', () async {
      await _ensureFreshSession();
      await api.createFinanceAccount(
        vendorId: vendorId,
        holderName: holderName.trim(),
        bankName: bankName.trim(),
        iban: iban.trim(),
      );
      await refreshData();
    });
  }

  Future<void> createPayout({
    required String bankAccountId,
    required double amount,
    String note = '',
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    final String? vendorId = selectedVendorId;
    if (api == null || vendorId == null) {
      return;
    }
    await _runBusy('finance:payout', () async {
      await _ensureFreshSession();
      await api.createPayout(
        vendorId: vendorId,
        bankAccountId: bankAccountId,
        amount: amount,
        note: note.trim().isEmpty ? null : note.trim(),
      );
      await refreshData();
    });
  }

  Future<void> createSupportTicket({
    required String subject,
    required String message,
    String channel = 'operator-app',
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    await _runBusy('support:create', () async {
      await _ensureFreshSession();
      await api.createSupportTicket(
        subject: subject.trim(),
        message: message.trim(),
        channel: channel,
      );
      await refreshData();
    });
  }

  Future<void> updateBusinessProfile({
    required String businessName,
    required String subtitle,
    required String category,
    required String pickupPointLabel,
    required String pickupPointAddress,
    required String workingHoursLabel,
    required String imageUrl,
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    final SpetoCatalogVendor? vendor = selectedVendor;
    final SpetoRemoteUserProfile? profile = userProfile;
    if (api == null || vendor == null || profile == null) {
      return;
    }
    await _runBusy('profile:update', () async {
      await _ensureFreshSession();
      await api.updateCatalogVendor(vendor.vendorId, <String, Object?>{
        'name': businessName.trim(),
        'subtitle': subtitle.trim(),
        'category': category.trim(),
        'pickupPointLabel': pickupPointLabel.trim(),
        'pickupPointAddress': pickupPointAddress.trim(),
        'workingHoursLabel': workingHoursLabel.trim(),
        'imageUrl': imageUrl.trim(),
      });
      await api.updateProfile(
        displayName: profile.displayName,
        email: profile.email,
        phone: profile.phone,
        avatarUrl: imageUrl.trim().isEmpty
            ? profile.avatarUrl
            : imageUrl.trim(),
        notificationsEnabled: profile.notificationsEnabled,
      );
      await refreshData();
    });
  }

  Future<void> updateOperatorProfile({
    required String displayName,
    required String email,
    required String phone,
    required bool notificationsEnabled,
    required String avatarUrl,
  }) async {
    final SpetoRemoteDomainApi? api = _api;
    if (api == null) {
      return;
    }
    await _runBusy('profile:user', () async {
      await _ensureFreshSession();
      await api.updateProfile(
        displayName: displayName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        avatarUrl: avatarUrl.trim(),
        notificationsEnabled: notificationsEnabled,
      );
      await refreshData();
    });
  }

  String explainError(Object error) {
    if (error is _ControllerMessage) {
      return error.message;
    }
    if (error is SpetoRemoteApiException) {
      final String message = _extractApiErrorMessage(error);
      final String normalized = message.toLowerCase();
      if (normalized.contains('pending approval')) {
        return 'İşletme hesabınız henüz onaylanmadı.';
      }
      if (normalized.contains('has been rejected')) {
        return 'İşletme hesabınız reddedildi.';
      }
      if (normalized.contains('has been suspended')) {
        return 'İşletme hesabınız askıya alındı.';
      }
      if (normalized.contains('is inactive')) {
        return 'İşletme hesabı aktif değil.';
      }
      if (normalized.contains('invalid email or password')) {
        return 'E-posta veya şifre hatalı.';
      }
      if (normalized.contains('403')) {
        return 'Bu işlem için yetkiniz bulunmuyor.';
      }
      if (normalized.contains('409')) {
        return 'Bu kayıt zaten mevcut.';
      }
      return message.isEmpty ? 'Sunucu hatası oluştu.' : message;
    }
    if (error is TimeoutException) {
      return 'Sunucu zamanında yanıt vermedi.';
    }
    return 'Beklenmeyen bir hata oluştu.';
  }

  void _resetDashboardState() {
    vendors = const <SpetoCatalogVendor>[];
    selectedVendorId = null;
    inventorySnapshot = null;
    inventoryItems = const <SpetoInventoryItem>[];
    orders = const <SpetoOpsOrder>[];
    products = const <SpetoCatalogProduct>[];
    integrations = const <SpetoIntegrationConnection>[];
    campaignSummary = null;
    financeSummary = null;
    supportTickets = const <SpetoSupportTicket>[];
    userProfile = null;
  }

  String _extractApiErrorMessage(SpetoRemoteApiException error) {
    final String body = error.body?.trim() ?? '';
    if (body.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(body);
        if (decoded is Map<String, Object?>) {
          final Object? message = decoded['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
          if (message is List<Object?>) {
            for (final Object? item in message) {
              if (item is String && item.trim().isNotEmpty) {
                return item.trim();
              }
            }
          }
        }
      } catch (_) {}
    }
    return error.message.trim();
  }

  String? _resolveSelectedVendorId(List<SpetoCatalogVendor> nextVendors) {
    if (nextVendors.isEmpty) {
      return null;
    }
    final String? scopedVendorId = _sessionVendorId;
    if (scopedVendorId != null) {
      return scopedVendorId;
    }
    if (selectedVendorId != null) {
      for (final SpetoCatalogVendor vendor in nextVendors) {
        if (vendor.vendorId == selectedVendorId) {
          return vendor.vendorId;
        }
      }
    }
    return nextVendors.first.vendorId;
  }

  String? get _sessionVendorId {
    if (_session == null || _session!.vendorScopes.isEmpty) {
      return null;
    }
    return _session!.vendorScopes.first;
  }

  Future<void> _ensureFreshSession() async {
    final SpetoRemoteDomainApi? api = _api;
    final SpetoSession? currentSession = _session;
    if (api == null || currentSession == null) {
      return;
    }
    if (!api.shouldRefreshSession()) {
      return;
    }
    final SpetoSession? refreshed = await api.refreshSession(
      refreshToken: currentSession.refreshToken,
      notifyListeners: false,
    );
    if (refreshed != null) {
      _session = refreshed;
      await _persistStoredSession(refreshed);
    }
  }

  Future<void> _runBusy(String key, Future<void> Function() action) async {
    _busyByKey[key] = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busyByKey.remove(key);
      notifyListeners();
    }
  }

  void _validateRegistrationDraft() {
    if (registrationDraft.businessName.trim().isEmpty) {
      throw const _ControllerMessage('İşletme adı zorunlu.');
    }
    if (registrationDraft.businessCategory.trim().isEmpty) {
      throw const _ControllerMessage('Kategori zorunlu.');
    }
    if (registrationDraft.pickupPointAddress.trim().isEmpty) {
      throw const _ControllerMessage('Açık adres zorunlu.');
    }
    if (registrationDraft.operatorDisplayName.trim().isEmpty) {
      throw const _ControllerMessage('Yetkili adı zorunlu.');
    }
    if (registrationDraft.operatorEmail.trim().isEmpty) {
      throw const _ControllerMessage('E-posta zorunlu.');
    }
    if (registrationDraft.operatorPassword.trim().length < 8) {
      throw const _ControllerMessage('Şifre en az 8 karakter olmalı.');
    }
    if (registrationDraft.bankHolderName.trim().isEmpty ||
        registrationDraft.iban.trim().isEmpty) {
      throw const _ControllerMessage('Banka bilgileri eksik.');
    }
    if (!registrationDraft.termsAccepted ||
        !registrationDraft.privacyAccepted) {
      throw const _ControllerMessage(
        'Zorunlu sözleşme ve KVKK onaylarını tamamlayın.',
      );
    }
  }

  SpetoSession? _readStoredSession(SharedPreferences prefs) {
    final String? raw = prefs.getString(_sessionStorageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return SpetoSession.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistStoredSession(SpetoSession? session) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }
    if (session == null) {
      await prefs.remove(_sessionStorageKey);
      return;
    }
    await prefs.setString(_sessionStorageKey, jsonEncode(session.toJson()));
  }
}

class _ControllerMessage implements Exception {
  const _ControllerMessage(this.message);

  final String message;
}
