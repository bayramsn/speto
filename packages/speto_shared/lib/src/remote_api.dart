import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _spetoApiBaseUrlOverride = String.fromEnvironment(
  'SPETO_API_BASE_URL',
);

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

  static String defaultSpetoApiBaseUrl() {
    if (_spetoApiBaseUrlOverride.isNotEmpty) {
      return _spetoApiBaseUrlOverride;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:4000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:4000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:4000/api';
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
    final Map<String, String> headers = <String, String>{
      ..._jsonHeaders,
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
    final Future<http.Response> pendingResponse = switch (method) {
      'GET' => _httpClient.get(uri, headers: headers),
      'PUT' => _httpClient.put(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'POST' => _httpClient.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'PATCH' => _httpClient.patch(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
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

const Map<String, String> _jsonHeaders = <String, String>{
  'Accept': 'application/json',
  'Content-Type': 'application/json',
};
