import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models.dart';
import '../../data/datasources/auth_session_local_datasource.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

class AuthSessionState {
  const AuthSessionState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
  });

  final AuthUser? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;

  bool get isAuthenticated =>
      user != null && accessToken != null && refreshToken != null;

  UserRole? get role => user?.role;

  AuthSessionState copyWith({
    AuthUser? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    bool clearUser = false,
    bool clearTokens = false,
  }) {
    return AuthSessionState(
      user: clearUser ? null : (user ?? this.user),
      accessToken: clearTokens ? null : (accessToken ?? this.accessToken),
      refreshToken: clearTokens ? null : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthSessionController extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    return const AuthSessionState();
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setSession(AuthSession session) {
    state = AuthSessionState(
      user: session.user,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      isLoading: false,
    );
    ref.read(authSessionLocalDataSourceProvider).saveSession(session);
  }

  Future<void> restoreSession() async {
    final restoredSession =
        await ref.read(authSessionLocalDataSourceProvider).readSession();
    if (restoredSession == null) {
      state = state.copyWith(isLoading: false, clearUser: true, clearTokens: true);
      return;
    }

    state = AuthSessionState(
      user: restoredSession.user,
      accessToken: restoredSession.accessToken,
      refreshToken: restoredSession.refreshToken,
      isLoading: false,
    );
  }

  void updateUser(AuthUser user) {
    state = state.copyWith(user: user, isLoading: false);
    final accessToken = state.accessToken;
    final refreshToken = state.refreshToken;
    if (accessToken != null && refreshToken != null) {
      ref.read(authSessionLocalDataSourceProvider).saveSession(
            AuthSession(
              user: user,
              accessToken: accessToken,
              refreshToken: refreshToken,
            ),
          );
    }
  }

  void updateTokens({
    required String accessToken,
    String? refreshToken,
  }) {
    final user = state.user;
    final nextRefreshToken = refreshToken ?? state.refreshToken;
    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
      isLoading: false,
    );
    if (user != null && nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
      ref.read(authSessionLocalDataSourceProvider).saveSession(
            AuthSession(
              user: user,
              accessToken: accessToken,
              refreshToken: nextRefreshToken,
            ),
          );
    }
  }

  void signOut() {
    state = const AuthSessionState();
    ref.read(authSessionLocalDataSourceProvider).clearSession();
  }
}

final authSessionLocalDataSourceProvider =
    Provider<AuthSessionLocalDataSource>((ref) {
  return AuthSessionLocalDataSource();
});

final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSessionState>(
  AuthSessionController.new,
);
