import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';

enum _BookingFilter { all, pending, accepted, completed }

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({
    super.key,
    required this.role,
    required this.bookings,
    required this.onOpenConversation,
    required this.onRespondToBooking,
    required this.onMarkInProgress,
    required this.onMarkResolved,
    required this.onReportIssue,
    required this.onSubmitReview,
    required this.onDownloadReceipt,
    required this.isInProgress,
    required this.onInitiatePayment,
    required this.onConfirmPayment,
  });

  final UserRole role;
  final List<BookingRequest> bookings;
  final Future<void> Function(BookingRequest booking) onOpenConversation;
  final Future<String?> Function(BookingRequest booking, bool accept)
      onRespondToBooking;
  final Future<String?> Function(BookingRequest booking) onMarkInProgress;
  final Future<String?> Function(BookingRequest booking) onMarkResolved;
  final Future<String?> Function(
    BookingRequest booking, {
    required String reason,
    required String details,
    required bool wantsRefund,
  }) onReportIssue;
  final Future<String?> Function(
    BookingRequest booking, {
    required int rating,
    required String comment,
  }) onSubmitReview;
  final Future<String?> Function(BookingRequest booking) onDownloadReceipt;
  final bool Function(String bookingId) isInProgress;
  final Future<PaymentInstruction?> Function(
    BookingRequest booking,
    PaymentProvider provider,
  ) onInitiatePayment;
  final Future<String?> Function(String paymentId) onConfirmPayment;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late final TextEditingController _searchController;
  _BookingFilter _filter = _BookingFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookingRequest> get _visibleBookings {
    final query = _query.trim().toLowerCase();
    return widget.bookings.where((booking) {
      if (_filter == _BookingFilter.pending &&
          booking.status != BookingStatus.pending) {
        return false;
      }
      if (_filter == _BookingFilter.accepted &&
          booking.status != BookingStatus.accepted) {
        return false;
      }
      if (_filter == _BookingFilter.completed &&
          booking.status != BookingStatus.completed) {
        return false;
      }

      final source = [
        booking.serviceTitle,
        booking.professionalName,
        booking.clientName,
        booking.issueTitle,
        booking.issueSummary,
        booking.dateLabel,
      ].join(' ').toLowerCase();
      return query.isEmpty || source.contains(query);
    }).toList();
  }

  int get _pendingCount => widget.bookings
      .where((booking) => booking.status == BookingStatus.pending)
      .length;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final visible = _visibleBookings;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFDFEFF),
            const Color(0xFFF6FAFE),
            const Color(0xFFF3F7FC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reservations',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _pendingCount > 0
                          ? (_pendingCount > 9
                              ? '9+ en attente'
                              : '$_pendingCount en attente')
                          : 'A jour',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _searchField(context),
              const SizedBox(height: 16),
              Text(
                widget.role == UserRole.client
                    ? 'Mes rendez-vous'
                    : 'Demandes recues',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: visible.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _BookingCard(
                            role: widget.role,
                            booking: visible[index],
                            onOpenConversation: widget.onOpenConversation,
                            onRespondToBooking: widget.onRespondToBooking,
                            onMarkInProgress: widget.onMarkInProgress,
                            onMarkResolved: widget.onMarkResolved,
                            onReportIssue: widget.onReportIssue,
                            onSubmitReview: widget.onSubmitReview,
                            onDownloadReceipt: widget.onDownloadReceipt,
                            isInProgress:
                                widget.isInProgress(visible[index].id),
                            onInitiatePayment: widget.onInitiatePayment,
                            onConfirmPayment: widget.onConfirmPayment,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Rechercher une reservation...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.body.withValues(alpha: 0.74),
              ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.navySoft,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colors.navy.withValues(alpha: 0.18),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final colors = context.camrlex;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.calendar_month_rounded,
                size: 36,
                color: colors.navy,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aucune reservation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.navy,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.role == UserRole.client
                  ? 'Vos prochaines demandes apparaitront ici.'
                  : 'Les nouvelles demandes clients apparaitront ici.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.body,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.role,
    required this.booking,
    required this.onOpenConversation,
    required this.onRespondToBooking,
    required this.onMarkInProgress,
    required this.onMarkResolved,
    required this.onReportIssue,
    required this.onSubmitReview,
    required this.onDownloadReceipt,
    required this.isInProgress,
    required this.onInitiatePayment,
    required this.onConfirmPayment,
  });

  final UserRole role;
  final BookingRequest booking;
  final Future<void> Function(BookingRequest booking) onOpenConversation;
  final Future<String?> Function(BookingRequest booking, bool accept)
      onRespondToBooking;
  final Future<String?> Function(BookingRequest booking) onMarkInProgress;
  final Future<String?> Function(BookingRequest booking) onMarkResolved;
  final Future<String?> Function(
    BookingRequest booking, {
    required String reason,
    required String details,
    required bool wantsRefund,
  }) onReportIssue;
  final Future<String?> Function(
    BookingRequest booking, {
    required int rating,
    required String comment,
  }) onSubmitReview;
  final Future<String?> Function(BookingRequest booking) onDownloadReceipt;
  final bool isInProgress;
  final Future<PaymentInstruction?> Function(
    BookingRequest booking,
    PaymentProvider provider,
  ) onInitiatePayment;
  final Future<String?> Function(String paymentId) onConfirmPayment;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final statusColor = _statusColor(booking.status, colors);
    final counterpartName =
        role == UserRole.client ? booking.professionalName : booking.clientName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: booking.status == BookingStatus.pending
            ? const Color(0xFFF7FBFF)
            : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: booking.status == BookingStatus.pending
              ? colors.gold.withValues(alpha: 0.35)
              : colors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.status == BookingStatus.accepted && isInProgress
                      ? 'En cours'
                      : booking.status.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            role == UserRole.client
                ? 'Professionnel: $counterpartName'
                : 'Client: $counterpartName',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.body,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoPill(
                context,
                icon: Icons.schedule_rounded,
                label: booking.dateLabel,
              ),
              _infoPill(
                context,
                icon: booking.mode == ServiceMode.online
                    ? Icons.videocam_rounded
                    : Icons.place_rounded,
                label: booking.mode.label,
              ),
              _infoPill(
                context,
                icon: Icons.payments_rounded,
                label: '${booking.priceCfa} FCFA',
              ),
              _infoPill(
                context,
                icon: booking.urgency == BookingUrgency.urgent
                    ? Icons.priority_high_rounded
                    : Icons.timelapse_rounded,
                label: booking.urgency.label,
              ),
              _infoPill(
                context,
                icon: booking.paymentStatus == PaymentStatus.paid
                    ? Icons.verified_rounded
                    : Icons.hourglass_top_rounded,
                label: booking.paymentStatus.label,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.mist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              booking.locationLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.ink,
                    height: 1.35,
                  ),
            ),
          ),
          if (booking.issueTitle.isNotEmpty ||
              booking.issueSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.issueTitle.isEmpty
                        ? 'Details de la demande'
                        : booking.issueTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (booking.issueSummary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      booking.issueSummary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.body,
                            height: 1.35,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildActions(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final colors = context.camrlex;
    final actions = <Widget>[];

    if (role == UserRole.professional &&
        booking.status == BookingStatus.pending) {
      actions.add(
        FilledButton.icon(
          onPressed: () async {
            final message = await onRespondToBooking(booking, true);
            if (!context.mounted || message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Accepter'),
        ),
      );
      actions.add(
        OutlinedButton.icon(
          onPressed: () async {
            final message = await onRespondToBooking(booking, false);
            if (!context.mounted || message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Refuser'),
        ),
      );
    }

    if (role == UserRole.client &&
        booking.status == BookingStatus.pending &&
        booking.paymentStatus != PaymentStatus.paid) {
      actions.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'En attente de confirmation du professionnel avant paiement.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
    }

    if (role == UserRole.client &&
        booking.status == BookingStatus.accepted &&
        booking.paymentStatus != PaymentStatus.paid) {
      actions.add(
        FilledButton.icon(
          onPressed: () => _showPaymentSheet(context),
          icon: const Icon(Icons.payments_rounded),
          label: const Text('Payer maintenant'),
        ),
      );
    }

    final canChat = booking.paymentStatus == PaymentStatus.paid &&
        (booking.status == BookingStatus.accepted ||
            booking.status == BookingStatus.completed);
    if (canChat) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => onOpenConversation(booking),
          icon: const Icon(Icons.forum_rounded),
          label: const Text('Ouvrir la messagerie'),
        ),
      );
    }

    if (role == UserRole.professional &&
        booking.status == BookingStatus.accepted &&
        booking.paymentStatus != PaymentStatus.paid) {
      actions.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.mist,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'En attente du paiement client.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.body,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
    }

    if (role == UserRole.professional &&
        booking.status == BookingStatus.accepted &&
        booking.paymentStatus == PaymentStatus.paid &&
        !isInProgress) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () async {
            final message = await onMarkInProgress(booking);
            if (!context.mounted || message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: const Text('Marquer en cours'),
        ),
      );
    }

    if (role == UserRole.professional &&
        booking.status == BookingStatus.accepted &&
        booking.paymentStatus == PaymentStatus.paid) {
      actions.add(
        FilledButton.icon(
          onPressed: () async {
            final message = await onMarkResolved(booking);
            if (!context.mounted || message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          icon: const Icon(Icons.task_alt_rounded),
          label: const Text('Marquer resolu'),
        ),
      );
    }

    if (role == UserRole.client && booking.paymentId.isNotEmpty) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () async {
            final message = await onDownloadReceipt(booking);
            if (!context.mounted || message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Recu PDF'),
        ),
      );
    }

    final canReportIssue = role == UserRole.client &&
        booking.paymentStatus == PaymentStatus.paid &&
        (booking.status == BookingStatus.accepted ||
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.disputed);
    if (canReportIssue) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _showIssueDialog(context),
          icon: const Icon(Icons.report_gmailerrorred_rounded),
          label: Text(
            booking.issueReportStatus.isNotEmpty
                ? 'Litige en cours'
                : 'Signaler un probleme',
          ),
        ),
      );
    }

    if (role == UserRole.client &&
        booking.status == BookingStatus.completed &&
        !booking.hasReview) {
      actions.add(
        FilledButton.icon(
          onPressed: () => _showReviewDialog(context),
          icon: const Icon(Icons.star_rate_rounded),
          label: const Text('Laisser un avis'),
        ),
      );
    }

    return actions;
  }

  Future<void> _showPaymentSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(
        booking: booking,
        onInitiatePayment: onInitiatePayment,
        onConfirmPayment: onConfirmPayment,
      ),
    );
  }

  Future<void> _showIssueDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();
    bool wantsRefund = false;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Signaler un probleme'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motif du signalement',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Details du probleme',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: wantsRefund,
                      onChanged: (value) {
                        setLocalState(() => wantsRefund = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Je demande un remboursement'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSend != true) {
      reasonController.dispose();
      detailsController.dispose();
      return;
    }

    final message = await onReportIssue(
      booking,
      reason: reasonController.text.trim(),
      details: detailsController.text.trim(),
      wantsRefund: wantsRefund,
    );
    reasonController.dispose();
    detailsController.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Avis enregistre avec succes.'),
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    final commentController = TextEditingController();
    int rating = 5;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Laisser un avis verifie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: rating,
                      items: List.generate(
                        5,
                        (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text('${index + 1} etoile${index == 0 ? '' : 's'}'),
                        ),
                      ),
                      onChanged: (value) {
                        setLocalState(() => rating = value ?? 5);
                      },
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Publier'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSend != true) {
      commentController.dispose();
      return;
    }

    final message = await onSubmitReview(
      booking,
      rating: rating,
      comment: commentController.text.trim(),
    );
    commentController.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Avis enregistre avec succes.'),
      ),
    );
  }

  Widget _infoPill(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.navySoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BookingStatus status, CamrlexColors colors) {
    switch (status) {
      case BookingStatus.pending:
        return colors.gold;
      case BookingStatus.accepted:
        return colors.success;
      case BookingStatus.completed:
        return colors.navySoft;
      case BookingStatus.refused:
      case BookingStatus.cancelled:
      case BookingStatus.expired:
      case BookingStatus.disputed:
        return const Color(0xFFB3261E);
    }
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.booking,
    required this.onInitiatePayment,
    required this.onConfirmPayment,
  });

  final BookingRequest booking;
  final Future<PaymentInstruction?> Function(
    BookingRequest booking,
    PaymentProvider provider,
  ) onInitiatePayment;
  final Future<String?> Function(String paymentId) onConfirmPayment;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  PaymentProvider _provider = PaymentProvider.orangeMoney;
  PaymentInstruction? _instruction;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paiement de la consultation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez Orange Money ou MTN puis composez le code USSD.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.body,
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<PaymentProvider>(
              segments: const [
                ButtonSegment(
                  value: PaymentProvider.orangeMoney,
                  label: Text('Orange'),
                ),
                ButtonSegment(
                  value: PaymentProvider.mtnMoney,
                  label: Text('MTN'),
                ),
              ],
              selected: {_provider},
              onSelectionChanged: (values) {
                setState(() {
                  _provider = values.first;
                  _instruction = null;
                });
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.mist,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _instruction?.ussdCode ??
                    'Montant: ${widget.booking.priceCfa} FCFA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _generateCode,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.dialpad_rounded),
                  label: const Text('Generer le code'),
                ),
                if (_instruction != null)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _instruction!.ussdCode),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code USSD copie.')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copier'),
                  ),
              ],
            ),
            if (_instruction != null) ...[
              const SizedBox(height: 14),
              Text(
                'Apres paiement, cliquez sur confirmation pour demarrer la discussion.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.body,
                    ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busy ? null : _confirmPayment,
                icon: const Icon(Icons.verified_user_rounded),
                label: const Text('Confirmer le paiement'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateCode() async {
    setState(() => _busy = true);
    final instruction =
        await widget.onInitiatePayment(widget.booking, _provider);
    if (!mounted) return;
    setState(() {
      _instruction = instruction;
      _busy = false;
    });
    if (instruction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer le paiement.')),
      );
    }
  }

  Future<void> _confirmPayment() async {
    final instruction = _instruction;
    if (instruction == null) return;
    setState(() => _busy = true);
    final error = await widget.onConfirmPayment(instruction.paymentId);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Paiement confirme. Ouverture de la messagerie...'),
      ),
    );
  }
}
