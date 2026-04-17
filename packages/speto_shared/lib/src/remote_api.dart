import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

const String _spetoApiBaseUrlOverride = String.fromEnvironment(
  'SPETO_API_BASE_URL',
);
const String _spetoLanApiBaseUrlOverride = String.fromEnvironment(
  'SPETO_LAN_API_BASE_URL',
);
const String _productionApiBaseUrl = 'https://speto-backend.onrender.com/api';
const String _defaultLocalNetworkApiBaseUrl = 'http://192.168.1.2:4000/api';
const Duration _localBackendProbeTimeout = Duration(milliseconds: 1500);
const Duration _localBackendProbeRetryDelay = Duration(milliseconds: 250);
const Duration _sleepingBackendWakeTimeout = Duration(seconds: 60);
const Duration _sleepingBackendWakeRequestTimeout = Duration(seconds: 8);
const Duration _sleepingBackendWakeRetryDelay = Duration(seconds: 2);

typedef SpetoSessionChangedCallback =
    Future<void> Function(SpetoSession? session);

class SpetoRemoteApiClient {
  SpetoRemoteApiClient({
    http.Client? httpClient,
    String? baseUrl,
    SpetoSession? session,
  }) : _httpClient = httpClient ?? http.Client(),
       baseUrl = _normalizeBaseUrl(baseUrl ?? defaultSpetoApiBaseUrl()) {
    setSession(session);
  }

  final http.Client _httpClient;
  final String baseUrl;
  SpetoSession? _session;
  SpetoSessionChangedCallback? _onSessionChanged;
  Future<SpetoSession?>? _refreshInFlight;

  SpetoSession? get session => _session;

  void setSessionChangedCallback(SpetoSessionChangedCallback? callback) {
    _onSessionChanged = callback;
  }

  void setAccessToken(String? accessToken) {
    final SpetoSession? currentSession = _session;
    if (currentSession == null) {
      if ((accessToken?.trim() ?? '').isEmpty) {
        return;
      }
      _session = SpetoSession(
        email: '',
        displayName: '',
        phone: '',
        authToken: accessToken!.trim(),
        lastLoginIso: DateTime.now().toIso8601String(),
      );
      return;
    }
    setSession(currentSession.copyWith(authToken: accessToken?.trim() ?? ''));
  }

  void setSession(SpetoSession? session) {
    _session = session == null ? null : _normalizeSession(session);
  }

  void clearSession() {
    _session = null;
  }

  SpetoSession mergeSession(SpetoSession session) {
    final SpetoSession? currentSession = _session;
    if (currentSession == null) {
      return session;
    }
    return session.copyWith(
      authToken: currentSession.authToken,
      refreshToken: currentSession.refreshToken,
      accessTokenExpiresAt: currentSession.accessTokenExpiresAt,
      refreshTokenExpiresAt: currentSession.refreshTokenExpiresAt,
    );
  }

  bool shouldRefreshSession({
    Duration threshold = const Duration(seconds: 30),
  }) {
    final SpetoSession? currentSession = _session;
    if (currentSession == null) {
      return false;
    }
    final DateTime? accessTokenExpiresAt = _parseIsoDateTime(
      currentSession.accessTokenExpiresAt,
    );
    if (accessTokenExpiresAt == null) {
      return false;
    }
    return accessTokenExpiresAt
        .subtract(threshold)
        .isBefore(DateTime.now().toUtc());
  }

  Future<bool> checkHealth({Duration? timeout}) {
    return waitForBackend(timeout: timeout);
  }

  Future<bool> waitForBackend({Duration? timeout}) {
    return _waitForBackend(
      timeout: timeout ?? _backendProbeTimeout,
      requestTimeout: _backendProbeRequestTimeout,
      retryDelay: _backendProbeRetryDelay,
    );
  }

  Future<Object?> get(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Object?> put(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
    Object? body,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<Object?> post(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
    Object? body,
  }) {
    return _request(
      method: 'POST',
      path: path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<Object?> patch(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
    Object? body,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<Object?> delete(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      queryParameters: queryParameters,
    );
  }

  SpetoSession consumeAuthResponse(Map<String, Object?> json) {
    final Map<String, Object?> user = _asJsonMap(json['user']);
    final Map<String, Object?> tokens = _asJsonMap(json['tokens']);
    final SpetoSession nextSession = SpetoSession(
      email: user['email'] as String? ?? _session?.email ?? '',
      displayName:
          user['displayName'] as String? ?? _session?.displayName ?? '',
      phone: user['phone'] as String? ?? _session?.phone ?? '',
      authToken: tokens['accessToken'] as String? ?? '',
      refreshToken: tokens['refreshToken'] as String? ?? '',
      accessTokenExpiresAt: tokens['accessTokenExpiresAt'] as String? ?? '',
      refreshTokenExpiresAt: tokens['refreshTokenExpiresAt'] as String? ?? '',
      lastLoginIso: DateTime.now().toIso8601String(),
      avatarUrl: user['avatarUrl'] as String? ?? _session?.avatarUrl ?? '',
      notificationsEnabled:
          user['notificationsEnabled'] as bool? ??
          _session?.notificationsEnabled ??
          true,
      role: _enumByApiName(
        SpetoUserRole.values,
        user['role'] as String?,
        fallback: _session?.role ?? SpetoUserRole.customer,
      ),
      vendorScopes:
          ((user['vendorScopes'] as List<Object?>?) ?? const <Object?>[])
              .map((Object? item) => item! as String)
              .toList(growable: false),
    );
    setSession(nextSession);
    return nextSession;
  }

  Future<SpetoSession?> refreshSession({
    String? refreshToken,
    bool notifyListeners = true,
  }) async {
    final String normalizedRefreshToken =
        (refreshToken ?? _session?.refreshToken ?? '').trim();
    if (normalizedRefreshToken.isEmpty) {
      await _expireSession(notifyListeners: notifyListeners);
      return null;
    }
    final DateTime? refreshTokenExpiresAt = _parseIsoDateTime(
      _session?.refreshTokenExpiresAt ?? '',
    );
    if (refreshTokenExpiresAt != null &&
        refreshTokenExpiresAt.isBefore(DateTime.now().toUtc())) {
      await _expireSession(notifyListeners: notifyListeners);
      return null;
    }
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }
    final Future<SpetoSession?> future = _performRefresh(
      normalizedRefreshToken,
      notifyListeners: notifyListeners,
    );
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  static Future<SpetoRemoteApiClient> resolveDefault({
    http.Client? httpClient,
    SpetoSession? session,
  }) async {
    final http.Client resolvedHttpClient = httpClient ?? http.Client();
    final List<String> candidates = defaultSpetoApiBaseUrlCandidates();
    for (final String candidate in candidates) {
      final SpetoRemoteApiClient client = SpetoRemoteApiClient(
        httpClient: resolvedHttpClient,
        baseUrl: candidate,
        session: session,
      );
      if (await client._canReachBackend()) {
        return client;
      }
    }
    return SpetoRemoteApiClient(
      httpClient: resolvedHttpClient,
      baseUrl: candidates.first,
      session: session,
    );
  }

  static String defaultSpetoApiBaseUrl() {
    return defaultSpetoApiBaseUrlCandidates().first;
  }

  static List<String> defaultSpetoApiBaseUrlCandidates() {
    final String explicitBaseUrl = _spetoApiBaseUrlOverride.trim();
    if (explicitBaseUrl.isNotEmpty) {
      _assertConfiguredBaseUrl(explicitBaseUrl, isRelease: kReleaseMode);
      return <String>[explicitBaseUrl];
    }
    final String localNetworkBaseUrl = _spetoLanApiBaseUrlOverride.isNotEmpty
        ? _spetoLanApiBaseUrlOverride
        : _defaultLocalNetworkApiBaseUrl;
    if (kReleaseMode) {
      _assertConfiguredBaseUrl(_productionApiBaseUrl, isRelease: true);
      return <String>[_productionApiBaseUrl];
    }
    if (kIsWeb) {
      return _uniqueBaseUrls(<String>[
        'http://127.0.0.1:4000/api',
        localNetworkBaseUrl,
      ]);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _uniqueBaseUrls(<String>[
          'http://10.0.2.2:4000/api',
          localNetworkBaseUrl,
        ]);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return _uniqueBaseUrls(<String>[
          'http://127.0.0.1:4000/api',
          localNetworkBaseUrl,
        ]);
    }
  }

  Future<Object?> _request({
    required String method,
    required String path,
    required Map<String, String?> queryParameters,
    Object? body,
    bool allowRefresh = true,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    final bool hasBody = body != null;
    final Map<String, String> headers = <String, String>{
      ..._headersForRequest(hasBody: hasBody),
      if ((_session?.authToken ?? '').trim().isNotEmpty)
        'Authorization': 'Bearer ${_session!.authToken}',
    };
    final http.Response response = await _sendRequest(
      uri,
      method: method,
      headers: headers,
      body: hasBody ? jsonEncode(body) : null,
    );
    if (response.statusCode == 401 &&
        allowRefresh &&
        !_isAuthRefreshRequest(path) &&
        !_isAuthLoginRequest(path)) {
      final SpetoSession? refreshedSession = await refreshSession();
      if (refreshedSession != null) {
        return _request(
          method: method,
          path: path,
          queryParameters: queryParameters,
          body: body,
          allowRefresh: false,
        );
      }
    }
    if (response.statusCode >= 400) {
      throw SpetoRemoteApiException(
        'HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}'.trim(),
        uri: uri,
        body: response.body,
      );
    }
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body) as Object?;
  }

  Future<http.Response> _sendRequest(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String? body,
  }) {
    final Future<http.Response> pendingResponse = switch (method) {
      'GET' => _httpClient.get(uri, headers: headers),
      'PUT' => _httpClient.put(uri, headers: headers, body: body),
      'POST' => _httpClient.post(uri, headers: headers, body: body),
      'PATCH' => _httpClient.patch(uri, headers: headers, body: body),
      'DELETE' => _httpClient.delete(uri, headers: headers),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };
    return pendingResponse.timeout(const Duration(seconds: 8));
  }

  Future<SpetoSession?> _performRefresh(
    String refreshToken, {
    required bool notifyListeners,
  }) async {
    final Uri uri = _buildUri('auth/refresh', const <String, String?>{});
    final http.Response response = await _sendRequest(
      uri,
      method: 'POST',
      headers: _headersForRequest(hasBody: true),
      body: jsonEncode(<String, Object?>{'refreshToken': refreshToken}),
    );
    if (response.statusCode >= 400) {
      await _expireSession(notifyListeners: notifyListeners);
      return null;
    }
    if (response.body.isEmpty) {
      await _expireSession(notifyListeners: notifyListeners);
      return null;
    }
    final Object? decoded = jsonDecode(response.body);
    final SpetoSession session = consumeAuthResponse(_asJsonMap(decoded));
    if (notifyListeners) {
      await _notifySessionChanged(session);
    }
    return session;
  }

  Future<void> _expireSession({required bool notifyListeners}) async {
    clearSession();
    if (notifyListeners) {
      await _notifySessionChanged(null);
    }
  }

  Future<void> _notifySessionChanged(SpetoSession? session) async {
    final SpetoSessionChangedCallback? callback = _onSessionChanged;
    if (callback == null) {
      return;
    }
    await callback(session == null ? null : _normalizeSession(session));
  }

  Uri _buildUri(String path, Map<String, String?> queryParameters) {
    final String normalizedPath = path.startsWith('/')
        ? path.substring(1)
        : path;
    final Uri resolved = Uri.parse(baseUrl).resolve(normalizedPath);
    final Map<String, String> cleanedQueryParameters = <String, String>{
      for (final MapEntry<String, String?> entry in queryParameters.entries)
        if (entry.value != null && entry.value!.trim().isNotEmpty)
          entry.key: entry.value!,
    };
    return resolved.replace(
      queryParameters: cleanedQueryParameters.isEmpty
          ? null
          : cleanedQueryParameters,
    );
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value : '$value/';
  }

  static void _assertConfiguredBaseUrl(
    String value, {
    required bool isRelease,
  }) {
    final Uri uri = Uri.parse(value);
    if (!uri.hasScheme || uri.host.trim().isEmpty) {
      throw StateError('SPETO_API_BASE_URL must be a fully-qualified URL.');
    }
    if (isRelease && uri.scheme != 'https' && !_isLocalNetworkUri(uri)) {
      throw StateError(
        'SPETO_API_BASE_URL must use https:// in release builds unless it points to a local network backend.',
      );
    }
  }

  static bool _isLocalNetworkUri(Uri uri) {
    final String host = uri.host.trim().toLowerCase();
    if (host.isEmpty) {
      return false;
    }
    if (host == 'localhost' || host == '127.0.0.1') {
      return true;
    }
    final List<String> octets = host.split('.');
    if (octets.length != 4) {
      return false;
    }
    final List<int> parts = <int>[];
    for (final String octet in octets) {
      final int? value = int.tryParse(octet);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      parts.add(value);
    }
    if (parts[0] == 10) {
      return true;
    }
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) {
      return true;
    }
    return parts[0] == 192 && parts[1] == 168;
  }

  static List<String> _uniqueBaseUrls(List<String> values) {
    final List<String> uniqueValues = <String>[];
    final Set<String> seen = <String>{};
    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final String normalized = _normalizeBaseUrl(trimmed);
      if (!seen.add(normalized)) {
        continue;
      }
      uniqueValues.add(trimmed);
    }
    return uniqueValues;
  }

  bool get _shouldWaitForSleepingBackend {
    if (_spetoApiBaseUrlOverride.trim().isEmpty) {
      return false;
    }
    final Uri? uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      return false;
    }
    return !_isLocalNetworkUri(uri);
  }

  Duration get _backendProbeTimeout => _shouldWaitForSleepingBackend
      ? _sleepingBackendWakeTimeout
      : _localBackendProbeTimeout;

  Duration get _backendProbeRequestTimeout => _shouldWaitForSleepingBackend
      ? _sleepingBackendWakeRequestTimeout
      : _localBackendProbeTimeout;

  Duration get _backendProbeRetryDelay => _shouldWaitForSleepingBackend
      ? _sleepingBackendWakeRetryDelay
      : _localBackendProbeRetryDelay;

  Future<bool> _canReachBackend() async {
    return _waitForBackend(
      timeout: _backendProbeTimeout,
      requestTimeout: _backendProbeRequestTimeout,
      retryDelay: _backendProbeRetryDelay,
    );
  }

  Future<bool> _waitForBackend({
    required Duration timeout,
    required Duration requestTimeout,
    required Duration retryDelay,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final Uri healthUri = _buildUri('health', const <String, String?>{});

    try {
      while (stopwatch.elapsedMilliseconds < timeout.inMilliseconds) {
        try {
          final int remainingBeforeRequestMs =
              timeout.inMilliseconds - stopwatch.elapsedMilliseconds;
          final int requestTimeoutMs =
              requestTimeout.inMilliseconds < remainingBeforeRequestMs
              ? requestTimeout.inMilliseconds
              : remainingBeforeRequestMs;
          final http.Response response = await _httpClient
              .get(
                healthUri,
                headers: const <String, String>{'Accept': 'application/json'},
              )
              .timeout(Duration(milliseconds: requestTimeoutMs));
          if (_isHealthyBackendResponse(response)) {
            return true;
          }
        } catch (_) {}

        final int remainingMs =
            timeout.inMilliseconds - stopwatch.elapsedMilliseconds;
        if (remainingMs <= 0) {
          return false;
        }
        final int retryDelayMs = retryDelay.inMilliseconds < remainingMs
            ? retryDelay.inMilliseconds
            : remainingMs;
        await Future<void>.delayed(Duration(milliseconds: retryDelayMs));
      }
      return false;
    } finally {
      stopwatch.stop();
    }
  }
}

class SpetoRemoteApiException implements Exception {
  const SpetoRemoteApiException(this.message, {required this.uri, this.body});

  final String message;
  final Uri uri;
  final String? body;

  @override
  String toString() {
    final String normalizedBody = body?.trim() ?? '';
    if (normalizedBody.isEmpty) {
      return 'SpetoRemoteApiException($message, uri: $uri)';
    }
    return 'SpetoRemoteApiException($message, uri: $uri, body: $normalizedBody)';
  }
}

const Map<String, String> _baseHeaders = <String, String>{
  'Accept': 'application/json',
};

Map<String, String> _headersForRequest({required bool hasBody}) {
  return <String, String>{
    ..._baseHeaders,
    if (hasBody) 'Content-Type': 'application/json',
  };
}

bool _isHealthyBackendResponse(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 400) {
    return false;
  }
  final String body = response.body.trim();
  if (body.isEmpty) {
    return true;
  }
  try {
    final Object? decoded = jsonDecode(body);
    final Map<String, Object?> json = _asJsonMap(decoded);
    return json['status'] == 'ok' || json['ok'] == true;
  } catch (_) {
    return false;
  }
}

bool _isAuthRefreshRequest(String path) {
  final String normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  return normalizedPath == 'auth/refresh';
}

bool _isAuthLoginRequest(String path) {
  final String normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  return normalizedPath == 'auth/login' || normalizedPath == 'auth/register';
}

DateTime? _parseIsoDateTime(String rawValue) {
  final String normalized = rawValue.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return DateTime.tryParse(normalized)?.toUtc();
}

SpetoSession _normalizeSession(SpetoSession session) {
  return session.copyWith(
    authToken: session.authToken.trim(),
    refreshToken: session.refreshToken.trim(),
    accessTokenExpiresAt: session.accessTokenExpiresAt.trim(),
    refreshTokenExpiresAt: session.refreshTokenExpiresAt.trim(),
  );
}

String _normalizeEnumToken(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }
  return value.trim().replaceAll(RegExp(r'[\s_-]+'), '').toLowerCase();
}

T _enumByApiName<T extends Enum>(
  List<T> values,
  String? rawValue, {
  required T fallback,
}) {
  final String normalizedRawValue = _normalizeEnumToken(rawValue);
  for (final T value in values) {
    if (_normalizeEnumToken(value.name) == normalizedRawValue) {
      return value;
    }
  }
  return fallback;
}

Map<String, Object?> _asJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw const FormatException('Expected JSON object payload from backend');
}
