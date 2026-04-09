import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/core/bootstrap.dart';
import '../../src/core/models.dart';
import '../state/app_state.dart';

/// Auth repository — resolved from bootstrap.
final authRepositoryProvider = Provider<SpetoAuthRepository>((ref) {
  return ref.watch(bootstrapProvider).authRepository;
});

/// Commerce repository — resolved from bootstrap.
final commerceRepositoryProvider = Provider<SpetoCommerceRepository>((ref) {
  return ref.watch(bootstrapProvider).commerceRepository;
});

/// Bootstrap provider — initialized before app starts.
final bootstrapProvider = Provider<SpetoBootstrap>((ref) {
  throw UnimplementedError('Override in main with ProviderScope');
});

/// Main app state — the central ChangeNotifier.
final appStateProvider = ChangeNotifierProvider<SpetoAppState>((ref) {
  final bootstrap = ref.watch(bootstrapProvider);
  return SpetoAppState(
    authRepository: bootstrap.authRepository,
    commerceRepository: bootstrap.commerceRepository,
    domainApi: bootstrap.domainApi,
    session: bootstrap.session,
    registrationDraft: bootstrap.registrationDraft,
    passwordResetEmail: bootstrap.passwordResetEmail,
    commerceSnapshot: bootstrap.commerceSnapshot,
  );
});

/// Theme mode — derived from app state.
final themeModeProvider = Provider((ref) {
  return ref.watch(appStateProvider).themeMode;
});

/// Auth status — derived from app state.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isAuthenticated;
});

/// Current session — derived from app state.
final sessionProvider = Provider<SpetoSession?>((ref) {
  return ref.watch(appStateProvider).session;
});

/// Cart items count.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(appStateProvider).cartCount;
});

/// Pro points balance.
final proPointsProvider = Provider<double>((ref) {
  return ref.watch(appStateProvider).proPointsBalance;
});
