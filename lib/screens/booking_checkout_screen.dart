import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../features/booking/domain/entities/availability_slot_entity.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/camrlex_ui.dart';

class BookingCheckoutScreen extends ConsumerStatefulWidget {
  const BookingCheckoutScreen({
    super.key,
    required this.offer,
    required this.onConfirm,
  });

  final ServiceOffer offer;
  final Future<String?> Function(
    ServiceOffer offer,
    ServiceMode mode,
    BookingUrgency urgency,
    String issueTitle,
    String issueSummary,
    String appointmentDate,
    String startTime,
    String endTime,
  ) onConfirm;

  @override
  ConsumerState<BookingCheckoutScreen> createState() =>
      _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  late ServiceMode _selectedMode;
  BookingUrgency _selectedUrgency = BookingUrgency.medium;
  late final TextEditingController _issueTitleController;
  late final TextEditingController _issueSummaryController;
  final List<_BookableSlot> _slots = <_BookableSlot>[];
  int _selectedSlot = -1;
  int _selectedPayment = 0;
  bool _loadingSlots = true;
  bool _submitting = false;
  String? _slotError;

  static const _paymentOptions = [
    'Acompte 30%',
    'Paiement total',
  ];

  @override
  void initState() {
    super.initState();
    _issueTitleController = TextEditingController();
    _issueSummaryController = TextEditingController();
    _selectedMode = widget.offer.mode == ServiceMode.both
        ? ServiceMode.online
        : widget.offer.mode;
    _loadAvailability();
  }

  @override
  void dispose() {
    _issueTitleController.dispose();
    _issueSummaryController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loadingSlots = true;
      _slotError = null;
    });

    try {
      final items = await ref.read(bookingRepositoryProvider).listAvailabilitySlots(
            professionalId: widget.offer.professionalId,
          );
      final mapped = items
          .where((item) => item.isAvailable)
          .map(_buildBookableSlot)
          .whereType<_BookableSlot>()
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (!mounted) {
        return;
      }

      setState(() {
        _slots
          ..clear()
          ..addAll(mapped);
        _selectedSlot = mapped.isEmpty ? -1 : 0;
        _loadingSlots = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSlots = false;
        _slotError = 'Impossible de charger les disponibilites du professionnel.';
      });
    }
  }

  _BookableSlot? _buildBookableSlot(AvailabilitySlotEntity slot) {
    final startParts = slot.startTime.split(':');
    final endParts = slot.endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) {
      return null;
    }

    final now = DateTime.now();
    final targetWeekday = slot.dayOfWeek == 0 ? DateTime.sunday : slot.dayOfWeek;
    var date = DateTime(now.year, now.month, now.day);
    while (date.weekday != targetWeekday) {
      date = date.add(const Duration(days: 1));
    }

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMinute = int.tryParse(startParts[1]) ?? 0;
    final candidate = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMinute,
    );
    if (candidate.isBefore(now.add(const Duration(minutes: 30)))) {
      date = date.add(const Duration(days: 7));
    }

    final appointmentDate = _dateOnly(date);
    return _BookableSlot(
      id: slot.id,
      label: '${_weekdayLabel(date.weekday)} ${date.day} ${_monthLabel(date.month)} ${date.year} - ${_formatTime(slot.startTime)}',
      subtitle: '${_formatTime(slot.startTime)} a ${_formatTime(slot.endTime)} • ${slot.slotDuration} min',
      appointmentDate: appointmentDate.toIso8601String().split('T').first,
      startTime: _normalizeTime(slot.startTime),
      endTime: _normalizeTime(slot.endTime),
      dateTime: DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        startHour,
        startMinute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final hasFixedPaidPrice =
        !widget.offer.isFree && !widget.offer.isPricedAfterReview;
    final deposit = hasFixedPaidPrice ? (widget.offer.feeCfa * 0.3).round() : 0;
    final verification = verificationColor(
      widget.offer.profile.verificationStatus,
      colors,
    );
    final selectedSlot =
        _selectedSlot >= 0 && _selectedSlot < _slots.length ? _slots[_selectedSlot] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          CamrlexHeroCard(
            dark: true,
            eyebrow: 'CONFIRMATION',
            title: 'Envoyez la demande puis attendez la confirmation du pro.',
            description:
                'Validez le mode, choisissez un creneau reel et decrivez votre besoin. '
                'Le paiement se fait apres acceptation du professionnel.',
            children: [
              const CamrlexInfoChip(
                icon: Icons.lock_rounded,
                label: 'Paiement securise',
              ),
              CamrlexInfoChip(
                icon: Icons.verified_user_rounded,
                label: widget.offer.profile.verificationStatus.label,
              ),
              CamrlexInfoChip(
                icon: Icons.schedule_rounded,
                label: widget.offer.durationLabel,
              ),
            ],
          ),
          const SizedBox(height: 18),
          CamrlexSectionCard(
            title: widget.offer.title,
            subtitle:
                '${widget.offer.profile.fullName} - ${widget.offer.profile.profession.label} - ${widget.offer.city}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          CamrlexInfoChip(
                            icon: Icons.payments_outlined,
                            label: widget.offer.pricingLabel,
                          ),
                          CamrlexInfoChip(
                            icon: Icons.place_outlined,
                            label: widget.offer.city,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CamrlexStatusBadge(
                      label: widget.offer.profile.verificationStatus.label,
                      color: verification,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.mist,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedMode == ServiceMode.online
                        ? 'Le rendez-vous se fera a distance par appel ou visioconference.'
                        : 'Le rendez-vous se fera au cabinet: ${widget.offer.profile.address}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.ink,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CamrlexSectionCard(
            title: '1. Choix du mode',
            subtitle:
                'Active uniquement les formats autorises par l offre du professionnel.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (widget.offer.mode == ServiceMode.both ||
                    widget.offer.mode == ServiceMode.online)
                  ChoiceChip(
                    selected: _selectedMode == ServiceMode.online,
                    label: const Text('En ligne'),
                    onSelected: (_) {
                      setState(() => _selectedMode = ServiceMode.online);
                    },
                  ),
                if (widget.offer.mode == ServiceMode.both ||
                    widget.offer.mode == ServiceMode.inPerson)
                  ChoiceChip(
                    selected: _selectedMode == ServiceMode.inPerson,
                    label: const Text('Presentiel'),
                    onSelected: (_) {
                      setState(() => _selectedMode = ServiceMode.inPerson);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CamrlexSectionCard(
            title: '2. Choix du creneau',
            subtitle:
                'Les disponibilites ci-dessous viennent du planning reel du professionnel.',
            child: _buildSlotsSection(context),
          ),
          const SizedBox(height: 16),
          CamrlexSectionCard(
            title: '3. Votre probleme',
            subtitle:
                'Expliquez clairement l objet du dossier afin que le professionnel decide avec le bon contexte.',
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Niveau d urgence',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<BookingUrgency>(
                  segments: const [
                    ButtonSegment(
                      value: BookingUrgency.urgent,
                      label: Text('Urgent'),
                      icon: Icon(Icons.priority_high_rounded),
                    ),
                    ButtonSegment(
                      value: BookingUrgency.medium,
                      label: Text('Moyen'),
                      icon: Icon(Icons.schedule_rounded),
                    ),
                  ],
                  selected: {_selectedUrgency},
                  onSelectionChanged: (values) {
                    setState(() => _selectedUrgency = values.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _issueTitleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Titre du probleme',
                    hintText: 'Ex: Litige foncier familial',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _issueSummaryController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Bref resume',
                    hintText:
                        'Expliquez en quelques lignes le contexte, l urgence et ce que vous attendez.',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CamrlexSectionCard(
            title: '4. Paiement',
            subtitle:
                'Le paiement sera disponible uniquement apres acceptation de la reservation.',
            child: hasFixedPaidPrice
                ? Column(
                    children: List.generate(_paymentOptions.length, (index) {
                      final selected = _selectedPayment == index;
                      final amount = index == 0 ? deposit : widget.offer.feeCfa;

                      return _SelectableCard(
                        icon: index == 0
                            ? Icons.account_balance_wallet_rounded
                            : Icons.payments_rounded,
                        title: _paymentOptions[index],
                        subtitle: '$amount FCFA',
                        selected: selected,
                        onTap: () {
                          setState(() => _selectedPayment = index);
                        },
                      );
                    }),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.mist,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.offer.isFree
                          ? 'Cette consultation est gratuite. Aucun paiement ne sera demande apres acceptation.'
                          : 'Les honoraires seront fixes apres consultation du dossier. Le professionnel vous precisera le montant avant paiement.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.ink,
                            height: 1.45,
                          ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: colors.line),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.offer.isFree
                  ? 'Consultation gratuite'
                  : widget.offer.isPricedAfterReview
                      ? 'Honoraires definis apres etude du dossier'
                      : (_selectedPayment == 0
                          ? 'Acompte a regler: $deposit FCFA'
                          : 'Total a regler: ${widget.offer.feeCfa} FCFA'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedSlot != null
                  ? 'Creneau: ${selectedSlot.label}'
                  : 'Choisissez un creneau disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.body,
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: !_loadingSlots && selectedSlot != null && !_submitting
                        ? () async {
                            final issueTitle = _issueTitleController.text.trim();
                            final issueSummary =
                                _issueSummaryController.text.trim();
                            if (issueTitle.isEmpty || issueSummary.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ajoutez le titre et le resume du probleme avant de continuer.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() => _submitting = true);
                            final errorMessage = await widget.onConfirm(
                              widget.offer,
                              _selectedMode,
                              _selectedUrgency,
                              issueTitle,
                              issueSummary,
                              selectedSlot.appointmentDate,
                              selectedSlot.startTime,
                              selectedSlot.endTime,
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() => _submitting = false);
                            if (errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMessage)),
                              );
                              return;
                            }
                            Navigator.of(context).pop(true);
                          }
                        : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_rounded),
                    label: Text(_submitting ? 'Envoi...' : 'Envoyer la demande'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsSection(BuildContext context) {
    final colors = context.camrlex;
    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_slotError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _slotError!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB3261E),
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadAvailability,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reessayer'),
          ),
        ],
      );
    }
    if (_slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.mist,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'Aucun creneau n est encore configure pour ce professionnel.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.body,
              ),
        ),
      );
    }

    return Column(
      children: List.generate(_slots.length, (index) {
        final selected = _selectedSlot == index;
        final slot = _slots[index];
        return _SelectableCard(
          icon: Icons.calendar_month_rounded,
          title: slot.label,
          subtitle: slot.subtitle,
          selected: selected,
          onTap: () {
            setState(() => _selectedSlot = index);
          },
        );
      }),
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _normalizeTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '00';
    final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    return '$hour:$minute:00';
  }

  String _formatTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '00';
    final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    return '$hour:$minute';
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mer';
      case DateTime.thursday:
        return 'Jeu';
      case DateTime.friday:
        return 'Ven';
      case DateTime.saturday:
        return 'Sam';
      default:
        return 'Dim';
    }
  }

  String _monthLabel(int month) {
    switch (month) {
      case 1:
        return 'janv.';
      case 2:
        return 'fevr.';
      case 3:
        return 'mars';
      case 4:
        return 'avr.';
      case 5:
        return 'mai';
      case 6:
        return 'juin';
      case 7:
        return 'juil.';
      case 8:
        return 'aout';
      case 9:
        return 'sept.';
      case 10:
        return 'oct.';
      case 11:
        return 'nov.';
      default:
        return 'dec.';
    }
  }
}

class _BookableSlot {
  const _BookableSlot({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.dateTime,
  });

  final String id;
  final String label;
  final String subtitle;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final DateTime dateTime;
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? colors.navy.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colors.navy : colors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? colors.navy : colors.body,
            ),
          ],
        ),
      ),
    );
  }
}
