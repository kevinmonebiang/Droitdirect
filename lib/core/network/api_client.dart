import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_session_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseOptions = BaseOptions(
    baseUrl: 'http://localhost:8000/api',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  );
  final dio = Dio(baseOptions);
  final refreshDio = Dio(baseOptions);
  Future<String?>? refreshFuture;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = ref.read(authSessionProvider);
        final accessToken = session.accessToken;
        if (session.isAuthenticated &&
            accessToken != null &&
            accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode ?? 0;
        final path = error.requestOptions.path;
        final isAuthEndpoint = path.startsWith('/auth/login') ||
            path.startsWith('/auth/register') ||
            path.startsWith('/auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;
        final session = ref.read(authSessionProvider);
        final refreshToken = session.refreshToken;

        if (statusCode == 401 &&
            !isAuthEndpoint &&
            !alreadyRetried &&
            refreshToken != null &&
            refreshToken.isNotEmpty) {
          refreshFuture ??= () async {
            try {
              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refresh': refreshToken},
              );
              final payload = response.data as Map<String, dynamic>;
              final nextAccessToken = (payload['access'] ?? '').toString();
              final nextRefreshToken = (payload['refresh'] ?? '').toString();
              if (nextAccessToken.isEmpty) {
                return null;
              }
              ref.read(authSessionProvider.notifier).updateTokens(
                    accessToken: nextAccessToken,
                    refreshToken:
                        nextRefreshToken.isEmpty ? null : nextRefreshToken,
                  );
              return nextAccessToken;
            } catch (_) {
              return null;
            } finally {
              refreshFuture = null;
            }
          }();

          final nextAccessToken = await refreshFuture;
          if (nextAccessToken != null && nextAccessToken.isNotEmpty) {
            final requestOptions = error.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $nextAccessToken';
            requestOptions.extra = {
              ...requestOptions.extra,
              'retried': true,
            };
            final retryResponse = await dio.fetch(requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        }

        if (statusCode == 401 && !isAuthEndpoint) {
          ref.read(authSessionProvider.notifier).signOut();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
