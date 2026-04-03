import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../models.dart';
import '../../../../theme.dart';
import '../../../../widgets/droit_direct_logo.dart';
import '../../domain/entities/auth_session.dart';
import '../providers/auth_session_provider.dart';

class AuthGatewayPage extends ConsumerStatefulWidget {
  const AuthGatewayPage({
    super.key,
    this.availableRoles = const [UserRole.client, UserRole.professional],
    this.allowRegister = true,
    this.initialRole = UserRole.client,
  });

  final List<UserRole> availableRoles;
  final bool allowRegister;
  final UserRole initialRole;

  @override
  ConsumerState<AuthGatewayPage> createState() => _AuthGatewayPageState();
}

class _AuthGatewayPageState extends ConsumerState<AuthGatewayPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late UserRole _selectedRole;
  late bool _isRegisterMode;
  bool _restoringSession = true;
  bool _didAttemptRestore = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.availableRoles.contains(widget.initialRole)
        ? widget.initialRole
        : widget.availableRoles.first;
    _isRegisterMode = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreIfNeeded());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreIfNeeded() async {
    if (_didAttemptRestore) {
      return;
    }
    _didAttemptRestore = true;

    try {
      await ref
          .read(authSessionProvider.notifier)
          .restoreSession()
          .timeout(const Duration(milliseconds: 900));
      final session = ref.read(authSessionProvider);
      if (!mounted) {
        return;
      }
      if (session.isAuthenticated &&
          session.role != null &&
          widget.availableRoles.contains(session.role!)) {
        try {
          final freshUser = await ref
              .read(authRepositoryProvider)
              .me()
              .timeout(const Duration(milliseconds: 1400));
          ref.read(authSessionProvider.notifier).updateUser(freshUser);
        } on DioException catch (error) {
          if (error.response?.statusCode == 401) {
            ref.read(authSessionProvider.notifier).signOut();
            return;
          }
          return;
        } catch (_) {
          return;
        }
        context.go(_homeRouteForRole(session.role!));
        return;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _restoringSession = false);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final auth = ref.read(authRepositoryProvider);
    ref.read(authSessionProvider.notifier).setLoading(true);

    try {
      late final AuthSession session;
      if (_isRegisterMode) {
        session = await auth.register(
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole.name,
        );
      } else {
        session = await auth.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      ref.read(authSessionProvider.notifier).setSession(session);

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isRegisterMode
                ? 'Compte cree avec succes.'
                : 'Connexion reussie.',
          ),
        ),
      );
      context.go(AppRoutes.loading);
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_readableError(error))),
      );
    } finally {
      ref.read(authSessionProvider.notifier).setLoading(false);
    }
  }

  void _handleSocialSignIn(String providerLabel) {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Connexion $providerLabel prete dans l interface. Il reste a brancher les credentials OAuth pour l activer completement.',
        ),
      ),
    );
  }

  String _readableError(Object error) {
    final message = error.toString();
    if (message.contains('409')) {
      return 'Un compte existe deja avec cet email.';
    }
    if (message.contains('401')) {
      return 'Identifiants invalides.';
    }
    if (message.contains('SocketException') || message.contains('timeout')) {
      return 'Connexion reseau instable. Reessaie dans un instant.';
    }
    return 'Une erreur est survenue. Verifie les informations et reessaie.';
  }

  String _homeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.client:
        return AppRoutes.clientHome;
      case UserRole.professional:
        return AppRoutes.professionalHome;
      case UserRole.admin:
        return AppRoutes.adminHome;
    }
  }

  void _openAdminAccess() {
    if (widget.availableRoles.length == 1 &&
        widget.availableRoles.first == UserRole.admin) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Espace admin prive.'),
        duration: Duration(milliseconds: 900),
      ),
    );
    context.go(AppRoutes.adminLogin);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final isBusy = authState.isLoading || _restoringSession;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthBackgroundDecor()),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoSize =
                      constraints.maxWidth >= 720 ? 132.0 : 112.0;
                  final maxWidth =
                      constraints.maxWidth >= 720 ? 460.0 : 420.0;
                  final isAdminOnly = widget.availableRoles.length == 1 &&
                      widget.availableRoles.first == UserRole.admin;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          children: [
                            GestureDetector(
                              onLongPress: _openAdminAccess,
                              child: DroitDirectLogo(
                                size: logoSize,
                                showWordmark: false,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _AuthFormPanel(
                              formKey: _formKey,
                              isBusy: isBusy,
                              isRegisterMode: _isRegisterMode,
                              canRegister: widget.allowRegister &&
                                  _selectedRole != UserRole.admin,
                              availableRoles: widget.availableRoles,
                              selectedRole: _selectedRole,
                              fullNameController: _fullNameController,
                              emailController: _emailController,
                              phoneController: _phoneController,
                              passwordController: _passwordController,
                              onBackToLogin: isAdminOnly
                                  ? () => context.go(AppRoutes.login)
                                  : null,
                              onModeChanged: (value) {
                                setState(() => _isRegisterMode = value);
                              },
                              onRoleChanged: (role) {
                                setState(() {
                                  _selectedRole = role;
                                  if (role == UserRole.admin) {
                                    _isRegisterMode = false;
                                  }
                                });
                              },
                              onSubmit: _submit,
                              onGoogleSignIn: () =>
                                  _handleSocialSignIn('Google'),
                              onAppleSignIn: () =>
                                  _handleSocialSignIn('Apple'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackgroundDecor extends StatelessWidget {
  const _AuthBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFDFEFF)),
      child: Stack(
        children: [
          Positioned(
            top: -180,
            left: -44,
            right: -44,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(220),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFCCE0FF).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 72,
            left: -28,
            child: _BubbleOrb(
              size: 68,
              colors: [
                Color(0xFFE2C98B),
                Color(0xFFC8A96B),
              ],
            ),
          ),
          const Positioned(
            top: 170,
            right: 106,
            child: _BubbleOrb(
              size: 54,
              colors: [
                Color(0xFF9CC2F5),
                Color(0xFF4B79B8),
              ],
            ),
          ),
          const Positioned(
            top: 252,
            right: 36,
            child: _BubbleOrb(
              size: 92,
              colors: [
                Color(0xFFE2C98B),
                Color(0xFFC8A96B),
              ],
            ),
          ),
          const Positioned(
            top: 246,
            left: 60,
            child: _BubbleOrb(
              size: 36,
              colors: [
                Color(0xFF9CC2F5),
                Color(0xFF4B79B8),
              ],
            ),
          ),
          const Positioned(
            bottom: 192,
            left: -24,
            child: _BubbleOrb(
              size: 74,
              colors: [
                Color(0xFFE2C98B),
                Color(0xFFC8A96B),
              ],
            ),
          ),
          const Positioned(
            bottom: 114,
            right: -18,
            child: _BubbleOrb(
              size: 82,
              colors: [
                Color(0xFFE2C98B),
                Color(0xFFC8A96B),
              ],
            ),
          ),
          const Positioned(
            bottom: 210,
            right: 54,
            child: _BubbleOrb(
              size: 58,
              colors: [
                Color(0xFF9CC2F5),
                Color(0xFF4B79B8),
              ],
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.12),
                  radius: 1.18,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE8F2FF).withValues(alpha: 0.22),
                    const Color(0xFFDDEBFF).withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleOrb extends StatelessWidget {
  const _BubbleOrb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            colors.first.withValues(alpha: 0.95),
            colors.last,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.24),
            blurRadius: size * 0.24,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({
    required this.formKey,
    required this.isBusy,
    required this.isRegisterMode,
    required this.canRegister,
    required this.availableRoles,
    required this.selectedRole,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.onModeChanged,
    required this.onRoleChanged,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.onBackToLogin,
  });

  final GlobalKey<FormState> formKey;
  final bool isBusy;
  final bool isRegisterMode;
  final bool canRegister;
  final List<UserRole> availableRoles;
  final UserRole selectedRole;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final VoidCallback? onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final isAdminOnly =
        availableRoles.length == 1 && availableRoles.first == UserRole.admin;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colors.line,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                isAdminOnly
                    ? 'Connexion administrateur'
                    : isRegisterMode
                        ? 'Creer un compte'
                        : 'Connexion',
                key: ValueKey('${isAdminOnly}_$isRegisterMode'),
                style: TextStyle(
                  color: colors.navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRegisterMode
                  ? 'Renseigne tes informations pour ouvrir ton espace DroitDirect.'
                  : 'Entre dans ton espace et retrouve tes services juridiques.',
              style: TextStyle(
                color: colors.body,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onBackToLogin != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onBackToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.navy,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour a la connexion standard'),
                ),
              ),
            ],
            if (canRegister) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.line,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Connexion',
                        active: !isRegisterMode,
                        onTap: () => onModeChanged(false),
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        label: 'Inscription',
                        active: isRegisterMode,
                        onTap: () => onModeChanged(true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableRoles
                  .map(
                    (role) => _RolePill(
                      role: role,
                      selected: role == selectedRole,
                      onTap: () => onRoleChanged(role),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: Column(
                key: ValueKey('fields-$isRegisterMode-$selectedRole'),
                children: [
                  if (isRegisterMode) ...[
                    _FormField(
                      controller: fullNameController,
                      label: 'Nom complet',
                      hint: 'Jean Mbarga',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if ((value ?? '').trim().length < 3) {
                          return 'Entre un nom complet valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: phoneController,
                      label: 'Telephone',
                      hint: '+237 6 77 00 00 00',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_outlined,
                      validator: (value) {
                        if ((value ?? '').trim().length < 6) {
                          return 'Entre un numero valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  _FormField(
                    controller: emailController,
                    label: 'Email',
                    hint: 'nom@email.com',
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.alternate_email_rounded,
                    validator: (value) {
                      final input = (value ?? '').trim();
                      if (input.isEmpty || !input.contains('@')) {
                        return 'Entre un email valide.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    controller: passwordController,
                    label: 'Mot de passe',
                    hint: '********',
                    obscureText: true,
                    icon: Icons.lock_outline_rounded,
                    validator: (value) {
                      if ((value ?? '').trim().length < 6) {
                        return 'Le mot de passe doit contenir 6 caracteres minimum.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isBusy ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isRegisterMode ? 'Creer mon compte' : 'Se connecter',
                    ),
            ),
            if (!isAdminOnly) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colors.line,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Ou continuer avec',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.body,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colors.line,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: colors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      onTap: onGoogleSignIn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialButton(
                      label: 'Apple',
                      leading: Icon(
                        Icons.apple_rounded,
                        color: colors.navy,
                        size: 22,
                      ),
                      onTap: onAppleSignIn,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: const Color(0xFFF7FAFD),
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: colors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: active ? colors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? colors.gold.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : colors.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final icon = switch (role) {
      UserRole.client => Icons.person_outline_rounded,
      UserRole.professional => Icons.business_center_outlined,
      UserRole.admin => Icons.admin_panel_settings_outlined,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? colors.gold.withValues(alpha: 0.14)
                : const Color(0xFFF7FAFD),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colors.gold.withValues(alpha: 0.4)
                  : colors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colors.gold : colors.navySoft,
              ),
              const SizedBox(width: 8),
              Text(
                role.label,
                style: TextStyle(
                  color: colors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: colors.line,
      ),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        color: colors.ink,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: colors.gold,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: colors.navySoft,
        ),
        labelStyle: TextStyle(
          color: colors.body,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: colors.body.withValues(alpha: 0.55),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFD),
        enabledBorder: inputBorder,
        border: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colors.navy,
            width: 1.2,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: Color(0xFFB3261E),
          ),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: Color(0xFFB3261E),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
