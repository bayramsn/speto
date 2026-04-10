import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _spetoApiBaseUrlOverride = String.fromEnvironment(
  'SPETO_API_BASE_URL',
);
const String _spetoLanApiBaseUrlOverride = String.fromEnvironment(
  'SPETO_LAN_API_BASE_URL',
);
const String _defaultLocalNetworkApiBaseUrl = 'http://192.168.1.2:4000/api';

class SpetoRemoteApiClient {
  SpetoRemoteApiClient({
    http.Client? httpClient,
    String? baseUrl,
    String? accessToken,
  }) : _httpClient = httpClient ?? http.Client(),
       _accessToken = accessToken,
       baseUrl = _normalizeBaseUrl(baseUrl ?? defaultSpetoApiBaseUrl());

  final http.Client _httpClient;
  final String baseUrl;
  String? _accessToken;

  void setAccessToken(String? accessToken) {
    final String normalized = accessToken?.trim() ?? '';
    _accessToken = normalized.isEmpty ? null : normalized;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  static Future<SpetoRemoteApiClient> resolveDefault({
    http.Client? httpClient,
    String? accessToken,
  }) async {
    final http.Client resolvedHttpClient = httpClient ?? http.Client();
    final List<String> candidates = defaultSpetoApiBaseUrlCandidates();
    for (final String candidate in candidates) {
      final SpetoRemoteApiClient client = SpetoRemoteApiClient(
        httpClient: resolvedHttpClient,
        baseUrl: candidate,
        accessToken: accessToken,
      );
      if (await client._canReachBackend()) {
        return client;
      }
    }
    return SpetoRemoteApiClient(
      httpClient: resolvedHttpClient,
      baseUrl: candidates.first,
      accessToken: accessToken,
    );
  }

  static String defaultSpetoApiBaseUrl() {
    return defaultSpetoApiBaseUrlCandidates().first;
  }

  static List<String> defaultSpetoApiBaseUrlCandidates() {
    if (_spetoApiBaseUrlOverride.isNotEmpty) {
      return <String>[_spetoApiBaseUrlOverride];
    }
    final String localNetworkBaseUrl = _spetoLanApiBaseUrlOverride.isNotEmpty
        ? _spetoLanApiBaseUrlOverride
        : _defaultLocalNetworkApiBaseUrl;
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
        return _uniqueBaseUrls(<String>[
          'http://127.0.0.1:4000/api',
          localNetworkBaseUrl,
        ]);
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

  Future<Object?> _request({
    required String method,
    required String path,
    required Map<String, String?> queryParameters,
    Object? body,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    final bool hasBody = body != null;
    final Map<String, String> headers = <String, String>{
      ..._headersForRequest(hasBody: hasBody),
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
    final Future<http.Response> pendingResponse = switch (method) {
      'GET' => _httpClient.get(uri, headers: headers),
      'PUT' => _httpClient.put(
        uri,
        headers: headers,
        body: hasBody ? jsonEncode(body) : null,
      ),
      'POST' => _httpClient.post(
        uri,
        headers: headers,
        body: hasBody ? jsonEncode(body) : null,
      ),
      'PATCH' => _httpClient.patch(
        uri,
        headers: headers,
        body: hasBody ? jsonEncode(body) : null,
      ),
      'DELETE' => _httpClient.delete(uri, headers: headers),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };
    final http.Response response = await pendingResponse.timeout(
      const Duration(seconds: 8),
    );
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

  Future<bool> _canReachBackend() async {
    try {
      final Uri healthUri = _buildUri('health', const <String, String?>{});
      final http.Response response = await _httpClient
          .get(
            healthUri,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(milliseconds: 1500));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
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
