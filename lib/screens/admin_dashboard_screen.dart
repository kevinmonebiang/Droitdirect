import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/providers/repository_providers.dart';
import '../features/auth/presentation/providers/auth_session_provider.dart';
import '../theme.dart';
import '../widgets/droit_direct_logo.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic>? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(adminRemoteDataSourceProvider).getOverview();
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = data;
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.response?.data is Map<String, dynamic>
            ? (error.response?.data['detail'] ?? error.message ?? 'Erreur admin.')
                .toString()
            : (error.message ?? 'Erreur admin.');
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les donnees administrateur.';
      });
    }
  }

  Future<void> _reviewProfessional({
    required String professionalId,
    required String status,
    String rejectionReason = '',
  }) async {
    try {
      await ref.read(adminRemoteDataSourceProvider).reviewProfessional(
            professionalId: professionalId,
            status: status,
            rejectionReason: rejectionReason,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier professionnel mis a jour.')),
      );
      await _loadOverview();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['detail'] ?? 'Action admin impossible.')
              .toString()
          : (error.message ?? 'Action admin impossible.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _reviewIssueReport({
    required String bookingId,
    required String status,
    String adminNote = '',
  }) async {
    try {
      await ref.read(adminRemoteDataSourceProvider).reviewIssueReport(
            bookingId: bookingId,
            status: status,
            adminNote: adminNote,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Litige mis a jour.')),
      );
      await _loadOverview();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final payload = error.response?.data;
      final message = payload is Map<String, dynamic>
          ? (payload['detail'] ?? 'Action sur le litige impossible.')
              .toString()
          : (error.message ?? 'Action sur le litige impossible.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _logout() async {
    final authRepository = ref.read(authRepositoryProvider);
    final session = ref.read(authSessionProvider);
    final refreshToken = session.refreshToken;

    ref.read(authSessionProvider.notifier).signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      Future<void>.microtask(() async {
        try {
          await authRepository
              .logout(refreshToken)
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          // Ignore remote logout failure once local session is cleared.
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.camrlex;
    final metrics =
        (_overview?['metrics'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final professionals =
        (_overview?['professionals'] as List<dynamic>?) ?? const <dynamic>[];
    final users = (_overview?['users'] as List<dynamic>?) ?? const <dynamic>[];
    final bookings =
        (_overview?['bookings'] as List<dynamic>?) ?? const <dynamic>[];
    final issueReports =
        (_overview?['issue_reports'] as List<dynamic>?) ?? const <dynamic>[];

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: colors.line),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Console administrateur'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton.filledTonal(
                tooltip: 'Rafraichir',
                onPressed: _loading ? null : _loadOverview,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Se deconnecter'),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadOverview,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [colors.navy, colors.navySoft, const Color(0xFF10233D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.navy.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'ADMINISTRATION',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Supervision DroitDirect',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Validez les professionnels, surveillez les litiges et gardez une vue claire sur les reservations et les comptes.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const DroitDirectLogo(
                          size: 88,
                          showWordmark: false,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD3C7)),
                  ),
                  child: Text(_error!),
                ),
              if (_error != null) const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    label: 'Utilisateurs',
                    value: '${metrics['total_users'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'Professionnels',
                    value: '${metrics['total_professionals'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'Verifies',
                    value: '${metrics['verified_professionals'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'A traiter',
                    value: '${metrics['pending_professionals'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'Reservations',
                    value: '${metrics['total_bookings'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'En attente',
                    value: '${metrics['pending_bookings'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'Litiges ouverts',
                    value: '${metrics['open_disputes'] ?? 0}',
                  ),
                  _MetricCard(
                    label: 'Demandes remb.',
                    value: '${metrics['refund_requests'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Professionnels',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (professionals.isEmpty)
                const _EmptyCard(
                  message: 'Aucun professionnel enregistre pour le moment.',
                )
              else
                ...professionals.map((item) {
                  final data = item as Map<String, dynamic>;
                  final status = (data['verification_status'] ?? '').toString();
                  final badgeText = _verificationLabel(status);
                  final phone = (data['phone'] ?? '').toString();
                  final city = (data['city'] ?? '').toString();
                  final number = (data['professional_number'] ?? '').toString();
                  final zone = (data['intervention_zone'] ?? '').toString();
                  final isOnline = (data['is_online'] ?? false) == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (data['full_name'] ?? 'Professionnel')
                                        .toString(),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _verificationColor(status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      color: _verificationColor(status),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${(data['profession_type'] ?? '').toString()} - $city',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Numero: ${number.isEmpty ? 'Non renseigne' : number}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Telephone: ${phone.isEmpty ? 'Non renseigne' : phone}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Zone: ${zone.isEmpty ? 'Non renseignee' : zone}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isOnline ? 'Statut: en ligne' : 'Statut: hors ligne',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isOnline ? colors.success : colors.body,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _showVerificationDocuments(data),
                                  child: const Text('Voir le dossier'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () => _reviewProfessional(
                                    professionalId: data['id'].toString(),
                                    status: 'verified',
                                  ),
                                  child: const Text('Valider'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _reviewProfessional(
                                    professionalId: data['id'].toString(),
                                    status: 'needs_completion',
                                    rejectionReason: 'Documents incomplets.',
                                  ),
                                  child: const Text('A completer'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _reviewProfessional(
                                    professionalId: data['id'].toString(),
                                    status: 'rejected',
                                    rejectionReason:
                                        'Dossier rejete par l administration.',
                                  ),
                                  child: const Text('Rejeter'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 22),
              Text(
                'Reservations recentes',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (bookings.isEmpty)
                const _EmptyCard(
                  message: 'Aucune reservation enregistree pour le moment.',
                )
              else
                ...bookings.take(20).map((item) {
                  final data = item as Map<String, dynamic>;
                  final bookingStatus =
                      (data['status'] ?? 'pending').toString();
                  final urgency = (data['urgency'] ?? 'medium').toString();
                  final issueTitle = (data['issue_title'] ?? '').toString();
                  final issueSummary = (data['issue_summary'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (data['service_title'] ?? 'Reservation')
                                        .toString(),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _bookingStatusColor(bookingStatus)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _bookingStatusLabel(bookingStatus),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: _bookingStatusColor(bookingStatus),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(data['client_name'] ?? '').toString()} - ${(data['professional_name'] ?? '').toString()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.body,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _AdminChip(
                                  label: (data['booking_type'] ?? '').toString(),
                                  color: colors.navySoft,
                                ),
                                _AdminChip(
                                  label: urgency == 'urgent' ? 'Urgent' : 'Moyen',
                                  color: urgency == 'urgent'
                                      ? const Color(0xFFB3261E)
                                      : colors.gold,
                                ),
                                _AdminChip(
                                  label: _paymentStatusLabel(
                                    (data['payment_status'] ?? '').toString(),
                                  ),
                                  color: colors.success,
                                ),
                              ],
                            ),
                            if (issueTitle.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                issueTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            if (issueSummary.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                issueSummary,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.body,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 22),
              Text(
                'Litiges et remboursements',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (issueReports.isEmpty)
                const _EmptyCard(
                  message: 'Aucun signalement ou remboursement en cours.',
                )
              else
                ...issueReports.take(20).map((item) {
                  final data = item as Map<String, dynamic>;
                  final status = (data['status'] ?? 'open').toString();
                  final bookingStatus =
                      (data['booking_status'] ?? 'pending').toString();
                  final paymentStatus =
                      (data['payment_status'] ?? 'pending').toString();
                  final wantsRefund =
                      (data['wants_refund'] ?? false) == true;
                  final adminNote = (data['admin_note'] ?? '').toString();
                  final transactionRef =
                      (data['transaction_ref'] ?? '').toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (data['service_title'] ?? 'Litige')
                                        .toString(),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _issueStatusColor(status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _issueStatusLabel(status),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: _issueStatusColor(status),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${(data['client_name'] ?? '').toString()} - ${(data['professional_name'] ?? '').toString()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.body,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _AdminChip(
                                  label: _bookingStatusLabel(bookingStatus),
                                  color: _bookingStatusColor(bookingStatus),
                                ),
                                _AdminChip(
                                  label: _paymentStatusLabel(paymentStatus),
                                  color: paymentStatus == 'refunded'
                                      ? const Color(0xFF1D3A67)
                                      : colors.success,
                                ),
                                if (wantsRefund)
                                  _AdminChip(
                                    label: 'Remboursement demande',
                                    color: colors.gold,
                                  ),
                                _AdminChip(
                                  label: '${data['amount'] ?? '0'} XAF',
                                  color: colors.navySoft,
                                ),
                              ],
                            ),
                            if (transactionRef.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Transaction: $transactionRef',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.body,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              (data['reason'] ?? '').toString(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if ((data['details'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                (data['details'] ?? '').toString(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.body,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (adminNote.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.mist,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Note admin: $adminNote',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: status == 'under_review'
                                      ? null
                                      : () => _reviewIssueReport(
                                            bookingId:
                                                data['booking_id'].toString(),
                                            status: 'under_review',
                                            adminNote:
                                                'Dossier en cours d examen par l administration.',
                                          ),
                                  child: const Text('Prendre en charge'),
                                ),
                                FilledButton.tonal(
                                  onPressed: status == 'resolved'
                                      ? null
                                      : () => _reviewIssueReport(
                                            bookingId:
                                                data['booking_id'].toString(),
                                            status: 'resolved',
                                            adminNote:
                                                'Le probleme a ete traite et clos.',
                                          ),
                                  child: const Text('Marquer resolu'),
                                ),
                                if (wantsRefund)
                                  FilledButton(
                                    onPressed: status == 'refund_approved'
                                        ? null
                                        : () => _reviewIssueReport(
                                              bookingId: data['booking_id']
                                                  .toString(),
                                              status: 'refund_approved',
                                              adminNote:
                                                  'Remboursement valide par l administration.',
                                            ),
                                    child: const Text('Approuver remboursement'),
                                  ),
                                if (wantsRefund)
                                  OutlinedButton(
                                    onPressed: status == 'refund_rejected'
                                        ? null
                                        : () => _reviewIssueReport(
                                              bookingId: data['booking_id']
                                                  .toString(),
                                              status: 'refund_rejected',
                                              adminNote:
                                                  'Demande de remboursement refusee.',
                                            ),
                                    child:
                                        const Text('Refuser remboursement'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 22),
              Text(
                'Utilisateurs',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (users.isEmpty)
                const _EmptyCard(
                  message: 'Aucun utilisateur enregistre pour le moment.',
                )
              else
                ...users.take(25).map((item) {
                  final data = item as Map<String, dynamic>;
                  final role = (data['role'] ?? '').toString();
                  final hasPro =
                      (data['has_professional_profile'] ?? false) == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          (data['full_name'] ?? 'Utilisateur').toString(),
                        ),
                        subtitle: Text(
                          '${(data['email'] ?? '').toString()}\n$role - ${(data['city'] ?? '').toString()}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text((data['status'] ?? '').toString()),
                            const SizedBox(height: 4),
                            Text(
                              hasPro ? 'Compte pro' : 'Compte simple',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
            ),
          ),
        ),
      ),
    );
  }

  String _verificationLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verifie';
      case 'submitted':
        return 'Soumis';
      case 'under_review':
        return 'En examen';
      case 'rejected':
        return 'Rejete';
      case 'needs_completion':
        return 'A completer';
      case 'suspended':
        return 'Suspendu';
      default:
        return 'Brouillon';
    }
  }

  Color _verificationColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF1F7A4D);
      case 'submitted':
      case 'under_review':
        return const Color(0xFFB7822D);
      case 'rejected':
        return const Color(0xFFB3261E);
      case 'needs_completion':
        return const Color(0xFF8A5A00);
      case 'suspended':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF1D3A67);
    }
  }

  String _bookingStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Acceptee';
      case 'rejected':
        return 'Refusee';
      case 'completed':
        return 'Terminee';
      case 'cancelled':
        return 'Annulee';
      case 'disputed':
        return 'Litige';
      case 'pending':
      default:
        return 'En attente';
    }
  }

  Color _bookingStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF1F7A4D);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFB3261E);
      case 'completed':
        return const Color(0xFF1D3A67);
      case 'disputed':
        return const Color(0xFF8A5A00);
      case 'pending':
      default:
        return const Color(0xFFB7822D);
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paye';
      case 'failed':
        return 'Echec';
      case 'refunded':
        return 'Rembourse';
      case 'pending':
      default:
        return 'En attente';
    }
  }

  String _issueStatusLabel(String status) {
    switch (status) {
      case 'under_review':
        return 'En cours';
      case 'resolved':
        return 'Resolu';
      case 'refund_approved':
        return 'Rembourse';
      case 'refund_rejected':
        return 'Remb. refuse';
      case 'open':
      default:
        return 'Ouvert';
    }
  }

  Color _issueStatusColor(String status) {
    switch (status) {
      case 'under_review':
        return const Color(0xFFB7822D);
      case 'resolved':
        return const Color(0xFF1F7A4D);
      case 'refund_approved':
        return const Color(0xFF1D3A67);
      case 'refund_rejected':
        return const Color(0xFFB3261E);
      case 'open':
      default:
        return const Color(0xFF8A5A00);
    }
  }

  Future<void> _showVerificationDocuments(Map<String, dynamic> data) async {
    final docs = (data['verification_documents'] as List<dynamic>?) ??
        const <dynamic>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.camrlex;
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Dossier de verification',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (data['full_name'] ?? 'Professionnel').toString(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.body,
                  ),
                ),
                const SizedBox(height: 18),
                if (docs.isEmpty)
                  const _EmptyCard(
                    message: 'Aucun document soumis pour ce professionnel.',
                  )
                else
                  ...docs.map((item) {
                    final doc = item as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.panel,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statut: ${(doc['status'] ?? '').toString()}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _DocLine(
                              label: 'Numero professionnel',
                              value: (doc['bar_number'] ?? '').toString(),
                            ),
                            _DocLine(
                              label: 'CNI ou carte professionnelle',
                              value: (doc['cni_front_url'] ?? '').toString(),
                            ),
                            _DocLine(
                              label: 'Diplome ou attestation',
                              value: (doc['diploma_url'] ?? '').toString(),
                            ),
                            _DocLine(
                              label: 'Selfie',
                              value:
                                  (doc['portrait_photo_url'] ?? '').toString(),
                            ),
                            if ((doc['rejection_reason'] ?? '')
                                .toString()
                                .isNotEmpty)
                              _DocLine(
                                label: 'Motif',
                                value:
                                    (doc['rejection_reason'] ?? '').toString(),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.line),
          boxShadow: [
            BoxShadow(
              color: colors.navy.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconForMetric(label),
              color: colors.gold,
              size: 22,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.navy,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.body,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForMetric(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('utilisateur')) return Icons.groups_rounded;
    if (lower.contains('professionnel')) return Icons.badge_rounded;
    if (lower.contains('verif')) return Icons.verified_rounded;
    if (lower.contains('traiter')) return Icons.rule_folder_rounded;
    if (lower.contains('reservation')) return Icons.event_note_rounded;
    if (lower.contains('attente')) return Icons.hourglass_top_rounded;
    if (lower.contains('litige')) return Icons.gavel_rounded;
    if (lower.contains('remb')) return Icons.currency_exchange_rounded;
    return Icons.analytics_rounded;
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.body,
              height: 1.45,
            ),
      ),
    );
  }
}

class _DocLine extends StatelessWidget {
  const _DocLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
