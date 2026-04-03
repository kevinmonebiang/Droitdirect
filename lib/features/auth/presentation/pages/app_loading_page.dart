import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../models.dart';
import '../../../../theme.dart';
import '../../../../widgets/droit_direct_logo.dart';
import '../providers/auth_session_provider.dart';

class AppLoadingPage extends ConsumerStatefulWidget {
  const AppLoadingPage({super.key});

  @override
  ConsumerState<AppLoadingPage> createState() => _AppLoadingPageState();
}

class _AppLoadingPageState extends ConsumerState<AppLoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    try {
      await ref
          .read(authSessionProvider.notifier)
          .restoreSession()
          .timeout(const Duration(milliseconds: 2500), onTimeout: () {});
      final session = ref.read(authSessionProvider);
      if (session.isAuthenticated) {
        try {
          final freshUser = await ref
              .read(authRepositoryProvider)
              .me()
              .timeout(const Duration(milliseconds: 1800), onTimeout: () {
            throw TimeoutException('user refresh timeout');
          });
          ref.read(authSessionProvider.notifier).updateUser(freshUser);
        } on DioException catch (error) {
          if (error.response?.statusCode == 401) {
            ref.read(authSessionProvider.notifier).signOut();
          }
          // Keep the restored user if the refresh endpoint is temporarily unavailable.
        } catch (_) {
          // Keep the restored user if the refresh endpoint is temporarily unavailable.
        }
      }
    } catch (_) {
      // Keep redirect fallback below.
    }

    if (!mounted) {
      return;
    }

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = const Duration(seconds: 5) - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }

    _redirectNext();
  }

  void _redirectNext() {
    if (!mounted || _didNavigate) {
      return;
    }
    _didNavigate = true;

    final session = ref.read(authSessionProvider);
    final target = switch (session.role) {
      UserRole.client when session.isAuthenticated => AppRoutes.clientHome,
      UserRole.professional when session.isAuthenticated =>
        AppRoutes.professionalHome,
      UserRole.admin when session.isAuthenticated => AppRoutes.adminHome,
      _ => AppRoutes.login,
    };

    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final session = ref.watch(authSessionProvider);
    final roleLabel = (session.role?.label ?? '').toLowerCase();
    final message = session.isAuthenticated
        ? 'Preparation de votre espace $roleLabel...'
        : 'Merci de patienter...';

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: FadeTransition(
                      opacity: _opacity,
                      child: const DroitDirectLogo(
                        size: 180,
                        showWordmark: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'DroitDirect',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colors.navy,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.navySoft.withValues(alpha: 0.86),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'La justice, sans detour.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 240,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8EEF8),
                        valueColor: AlwaysStoppedAnimation<Color>(colors.gold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
