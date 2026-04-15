import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain_api.dart';
import 'models.dart';
import 'remote_api.dart';

abstract class SpetoAuthRepository {
  Future<SpetoSession?> readSession();

  Future<void> writeSession(SpetoSession? session);

  Future<SpetoRegistrationDraft?> readRegistrationDraft();

  Future<void> writeRegistrationDraft(SpetoRegistrationDraft? draft);

  Future<void> rememberPasswordResetEmail(String email);

  Future<String?> readPasswordResetEmail();

  Future<void> clearPasswordResetEmail();
}

abstract class SpetoCommerceRepository {
  Future<SpetoCommerceSnapshot?> readSnapshot({String? scopeKey});

  Future<void> writeSnapshot(
    SpetoCommerceSnapshot snapshot, {
    String? scopeKey,
  });
}

class SpetoBootstrap {
  SpetoBootstrap({
    required this.authRepository,
    required this.commerceRepository,
    this.domainApi,
    this.session,
    this.registrationDraft,
    this.passwordResetEmail,
    this.commerceSnapshot,
  });

  final SpetoAuthRepository authRepository;
  final SpetoCommerceRepository commerceRepository;
  final SpetoRemoteDomainApi? domainApi;
  final SpetoSession? session;
  final SpetoRegistrationDraft? registrationDraft;
  final String? passwordResetEmail;
  final SpetoCommerceSnapshot? commerceSnapshot;

  factory SpetoBootstrap.ephemeral() {
    return SpetoBootstrap(
      authRepository: InMemorySpetoAuthRepository(),
      commerceRepository: InMemorySpetoCommerceRepository(),
    );
  }

  static Future<SpetoBootstrap> persistent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocalSpetoAuthRepository authRepository = LocalSpetoAuthRepository(
      prefs,
    );
    final LocalSpetoCommerceRepository commerceRepository =
        LocalSpetoCommerceRepository(prefs);
    SpetoSession? session = await authRepository.readSession();
    final SpetoRemoteApiClient apiClient =
        await SpetoRemoteApiClient.resolveDefault(session: session);
    apiClient.setSessionChangedCallback((SpetoSession? nextSession) async {
      await authRepository.writeSession(nextSession);
    });
    final SpetoRemoteDomainApi domainApi = SpetoRemoteDomainApi(apiClient);

    if (session != null) {
      try {
        if (session.authToken.trim().isEmpty ||
            session.refreshToken.trim().isEmpty) {
          session = null;
          await authRepository.writeSession(null);
        } else if (domainApi.shouldRefreshSession() ||
            session.authToken.trim().isEmpty) {
          session = await domainApi.refreshSession(
            refreshToken: session.refreshToken,
            notifyListeners: false,
          );
          await authRepository.writeSession(session);
        }
      } catch (error) {
        debugPrint('Speto session refresh failed during bootstrap: $error');
        session = null;
        await authRepository.writeSession(null);
        domainApi.clearSession();
      }
    }

    return SpetoBootstrap(
      authRepository: authRepository,
      commerceRepository: commerceRepository,
      domainApi: domainApi,
      session: session,
      registrationDraft: await authRepository.readRegistrationDraft(),
      passwordResetEmail: await authRepository.readPasswordResetEmail(),
      commerceSnapshot: await commerceRepository.readSnapshot(
        scopeKey: session?.email,
      ),
    );
  }
}

class RemoteSpetoAuthRepository implements SpetoAuthRepository {
  RemoteSpetoAuthRepository(this._apiClient);

  final SpetoRemoteApiClient _apiClient;

  @override
  Future<SpetoRegistrationDraft?> readRegistrationDraft() async {
    return _readJsonObject(
      'client-state/registration-draft',
      SpetoRegistrationDraft.fromJson,
    );
  }

  @override
  Future<String?> readPasswordResetEmail() async {
    return _readString('client-state/password-reset-email');
  }

  @override
  Future<void> clearPasswordResetEmail() async {
    await _apiClient.delete('client-state/password-reset-email');
  }

  @override
  Future<SpetoSession?> readSession() async {
    final SpetoSession? session = await _readJsonObject(
      'client-state/session',
      SpetoSession.fromJson,
    );
    _apiClient.setSession(session);
    return session;
  }

  @override
  Future<void> rememberPasswordResetEmail(String email) async {
    await _apiClient.put(
      'client-state/password-reset-email',
      body: <String, Object?>{'email': email},
    );
  }

  @override
  Future<void> writeRegistrationDraft(SpetoRegistrationDraft? draft) async {
    if (draft == null) {
      await _apiClient.delete('client-state/registration-draft');
      return;
    }
    await _apiClient.put(
      'client-state/registration-draft',
      body: draft.toJson(),
    );
  }

  @override
  Future<void> writeSession(SpetoSession? session) async {
    if (session == null) {
      _apiClient.clearSession();
      await _apiClient.delete('client-state/session');
      return;
    }
    _apiClient.setSession(session);
    await _apiClient.put('client-state/session', body: session.toJson());
  }

  Future<T?> _readJsonObject<T>(
    String path,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    final Object? data = _unwrapData(await _apiClient.get(path));
    if (data == null) {
      return null;
    }
    return fromJson(_asJsonMap(data));
  }

  Future<String?> _readString(String path) async {
    final Object? data = _unwrapData(await _apiClient.get(path));
    if (data == null) {
      return null;
    }
    if (data is! String) {
      throw const FormatException('Expected string payload from backend');
    }
    return data;
  }
}

class RemoteSpetoCommerceRepository implements SpetoCommerceRepository {
  RemoteSpetoCommerceRepository(this._apiClient);

  final SpetoRemoteApiClient _apiClient;

  @override
  Future<SpetoCommerceSnapshot?> readSnapshot({String? scopeKey}) async {
    final Object? data = _unwrapData(
      await _apiClient.get(
        'client-state/commerce-snapshot',
        queryParameters: <String, String?>{'scopeKey': scopeKey},
      ),
    );
    if (data == null) {
      return null;
    }
    return SpetoCommerceSnapshot.fromJson(_asJsonMap(data));
  }

  @override
  Future<void> writeSnapshot(
    SpetoCommerceSnapshot snapshot, {
    String? scopeKey,
  }) async {
    await _apiClient.put(
      'client-state/commerce-snapshot',
      queryParameters: <String, String?>{'scopeKey': scopeKey},
      body: snapshot.toJson(),
    );
  }
}

class InMemorySpetoAuthRepository implements SpetoAuthRepository {
  SpetoSession? _session;
  SpetoRegistrationDraft? _draft;
  String? _passwordResetEmail;

  @override
  Future<SpetoRegistrationDraft?> readRegistrationDraft() async => _draft;

  @override
  Future<String?> readPasswordResetEmail() async => _passwordResetEmail;

  @override
  Future<void> clearPasswordResetEmail() async {
    _passwordResetEmail = null;
  }

  @override
  Future<SpetoSession?> readSession() async => _session;

  @override
  Future<void> rememberPasswordResetEmail(String email) async {
    _passwordResetEmail = email;
  }

  @override
  Future<void> writeRegistrationDraft(SpetoRegistrationDraft? draft) async {
    _draft = draft;
  }

  @override
  Future<void> writeSession(SpetoSession? session) async {
    _session = session;
  }
}

class InMemorySpetoCommerceRepository implements SpetoCommerceRepository {
  final Map<String, SpetoCommerceSnapshot> _snapshots =
      <String, SpetoCommerceSnapshot>{};

  @override
  Future<SpetoCommerceSnapshot?> readSnapshot({String? scopeKey}) async {
    return _snapshots[_snapshotKeyFor(scopeKey)];
  }

  @override
  Future<void> writeSnapshot(
    SpetoCommerceSnapshot snapshot, {
    String? scopeKey,
  }) async {
    _snapshots[_snapshotKeyFor(scopeKey)] = snapshot;
  }
}

class LocalSpetoAuthRepository implements SpetoAuthRepository {
  LocalSpetoAuthRepository(this._prefs);

  static const String _sessionKey = 'speto.session';
  static const String _draftKey = 'speto.registration_draft';
  static const String _resetEmailKey = 'speto.reset_email';

  final SharedPreferences _prefs;

  @override
  Future<SpetoRegistrationDraft?> readRegistrationDraft() async {
    return _decodeObject(
      _prefs.getString(_draftKey),
      SpetoRegistrationDraft.fromJson,
    );
  }

  @override
  Future<String?> readPasswordResetEmail() async {
    return _prefs.getString(_resetEmailKey);
  }

  @override
  Future<void> clearPasswordResetEmail() async {
    await _prefs.remove(_resetEmailKey);
  }

  @override
  Future<SpetoSession?> readSession() async {
    return _decodeObject(_prefs.getString(_sessionKey), SpetoSession.fromJson);
  }

  @override
  Future<void> rememberPasswordResetEmail(String email) async {
    await _prefs.setString(_resetEmailKey, email);
  }

  @override
  Future<void> writeRegistrationDraft(SpetoRegistrationDraft? draft) async {
    if (draft == null) {
      await _prefs.remove(_draftKey);
      return;
    }
    await _prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  @override
  Future<void> writeSession(SpetoSession? session) async {
    if (session == null) {
      await _prefs.remove(_sessionKey);
      return;
    }
    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }
}

class LocalSpetoCommerceRepository implements SpetoCommerceRepository {
  LocalSpetoCommerceRepository(this._prefs);

  static const String _snapshotKey = 'speto.commerce_snapshot';

  final SharedPreferences _prefs;

  @override
  Future<SpetoCommerceSnapshot?> readSnapshot({String? scopeKey}) async {
    return _decodeObject(
      _prefs.getString(_snapshotStorageKey(scopeKey)),
      SpetoCommerceSnapshot.fromJson,
    );
  }

  @override
  Future<void> writeSnapshot(
    SpetoCommerceSnapshot snapshot, {
    String? scopeKey,
  }) async {
    await _prefs.setString(
      _snapshotStorageKey(scopeKey),
      jsonEncode(snapshot.toJson()),
    );
  }

  String _snapshotStorageKey(String? scopeKey) {
    return '$_snapshotKey.${_snapshotKeyFor(scopeKey)}';
  }
}

String _snapshotKeyFor(String? scopeKey) {
  if (scopeKey == null || scopeKey.trim().isEmpty) {
    return 'guest';
  }
  return base64Url.encode(utf8.encode(scopeKey.trim().toLowerCase()));
}

T? _decodeObject<T>(
  String? raw,
  T Function(Map<String, Object?> json) fromJson,
) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final Object? decoded = jsonDecode(raw);
  if (decoded is! Map<String, Object?>) {
    return null;
  }
  return fromJson(decoded);
}

Object? _unwrapData(Object? response) {
  if (response == null) {
    return null;
  }
  if (response is Map<String, Object?>) {
    return response['data'];
  }
  if (response is Map) {
    return response['data'];
  }
  return response;
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
