import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.onOpenNotification,
  });

  final List<AppNotification> notifications;
  final Future<void> Function(AppNotification notification) onOpenNotification;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final TextEditingController _searchController;
  final Set<String> _locallyReadIds = <String>{};
  String _query = '';
  bool _markingAll = false;

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

  bool _isUnread(AppNotification notification) {
    return notification.isUnread && !_locallyReadIds.contains(notification.id);
  }

  List<AppNotification> get _visibleNotifications {
    final query = _query.trim().toLowerCase();
    final list = [...widget.notifications];
    list.sort((a, b) {
      final unreadOrder = (_isUnread(b) ? 1 : 0).compareTo(_isUnread(a) ? 1 : 0);
      if (unreadOrder != 0) {
        return unreadOrder;
      }
      return 0;
    });

    return list.where((notification) {
      final source =
          '${notification.title} ${notification.body} ${notification.type}'
              .toLowerCase();
      if (query.isNotEmpty && !source.contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _unreadCount =>
      widget.notifications.where((notification) => _isUnread(notification)).length;

  Future<void> _openNotification(AppNotification notification) async {
    setState(() => _locallyReadIds.add(notification.id));
    await widget.onOpenNotification(notification);
  }

  Future<void> _markAllAsRead() async {
    if (_markingAll) {
      return;
    }
    final ids = _visibleNotifications
        .where(_isUnread)
        .map((notification) => notification.id)
        .toSet();
    if (ids.isEmpty) {
      return;
    }
    setState(() {
      _markingAll = true;
      _locallyReadIds.addAll(ids);
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) {
      setState(() => _markingAll = false);
    }
  }

  List<_NotificationSection> get _sections {
    final today = <AppNotification>[];
    final week = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final notification in _visibleNotifications) {
      final section = _sectionLabel(notification.timeLabel);
      if (section == 'Aujourd hui') {
        today.add(notification);
      } else if (section == 'Cette semaine') {
        week.add(notification);
      } else {
        earlier.add(notification);
      }
    }

    final sections = <_NotificationSection>[];
    if (today.isNotEmpty) {
      sections.add(_NotificationSection('Aujourd hui', today));
    }
    if (week.isNotEmpty) {
      sections.add(_NotificationSection('Cette semaine', week));
    }
    if (earlier.isNotEmpty) {
      sections.add(_NotificationSection('Plus anciennes', earlier));
    }
    return sections;
  }

  String _sectionLabel(String timeLabel) {
    final source = timeLabel.toLowerCase();
    if (source.contains('min') ||
        source.contains('heure') ||
        source.contains('hour') ||
        source.contains('today') ||
        source.contains('aujourd')) {
      return 'Aujourd hui';
    }
    final dayMatch = RegExp(r'(\d+)').firstMatch(source);
    final days = int.tryParse(dayMatch?.group(1) ?? '');
    if (days != null && days <= 7) {
      return 'Cette semaine';
    }
    return 'Plus anciennes';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final sections = _sections;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFDFEFF),
            Color(0xFFF6FAFE),
            Color(0xFFF3F7FC),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.navy.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: colors.navy,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Notifications',
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
                      _unreadCount > 0
                          ? (_unreadCount > 9 ? '9+ non lues' : '$_unreadCount non lues')
                          : 'A jour',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _searchField(context),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Toutes les alertes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _markingAll ? null : _markAllAsRead,
                    child: Text(_markingAll ? 'Chargement...' : 'Tout marquer lu'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: sections.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        itemCount: sections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: colors.navy,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              ...section.notifications.map((notification) {
                                final config = _config(notification, colors);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AlertCard(
                                    notification: notification,
                                    config: config,
                                    isUnread: _isUnread(notification),
                                    onOpen: () => _openNotification(notification),
                                  ),
                                );
                              }),
                            ],
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
          hintText: 'Rechercher une alerte...',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_none_rounded,
              size: 38,
              color: colors.navy,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune notification',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.navy,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les messages, reservations, paiements et rappels s afficheront ici.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.body,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  _AlertConfig _config(AppNotification notification, CamrlexColors colors) {
    final source =
        '${notification.title} ${notification.body} ${notification.type}'
            .toLowerCase();
    if (source.contains('payment') || source.contains('paiement')) {
      return _AlertConfig(
        icon: Icons.payments_rounded,
        accent: colors.success,
        background: const Color(0xFFEAF7EE),
        avatar: const Color(0xFFCFE9D6),
      );
    }
    if (source.contains('message') || source.contains('chat')) {
      return _AlertConfig(
        icon: Icons.chat_bubble_rounded,
        accent: colors.navySoft,
        background: const Color(0xFFEAF4FF),
        avatar: const Color(0xFFD4E5FB),
      );
    }
    if (source.contains('booking') ||
        source.contains('reservation') ||
        source.contains('rendez')) {
      return _AlertConfig(
        icon: Icons.calendar_month_rounded,
        accent: colors.gold,
        background: const Color(0xFFFFF5D9),
        avatar: const Color(0xFFF4DEA7),
      );
    }
    if (source.contains('verification')) {
      return _AlertConfig(
        icon: Icons.verified_user_rounded,
        accent: colors.gold,
        background: const Color(0xFFFFF7E7),
        avatar: const Color(0xFFF3E0B4),
      );
    }
    return _AlertConfig(
      icon: Icons.notifications_active_rounded,
      accent: colors.navy,
      background: const Color(0xFFF2F7FD),
      avatar: const Color(0xFFDCE8F7),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.notification,
    required this.config,
    required this.isUnread,
    required this.onOpen,
  });

  final AppNotification notification;
  final _AlertConfig config;
  final bool isUnread;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final trimmedTitle = notification.title.trim();
    final initial = trimmedTitle.isEmpty ? 'A' : trimmedTitle[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnread
              ? config.accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.avatar,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: colors.navy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: colors.navy,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                              ),
                          children: [
                            TextSpan(text: notification.title),
                            TextSpan(
                              text: ' ${notification.body}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.body,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isUnread)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      config.icon,
                      size: 16,
                      color: config.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notification.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.body,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: onOpen,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: const Text('Ouvrir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSection {
  const _NotificationSection(this.title, this.notifications);

  final String title;
  final List<AppNotification> notifications;
}

class _AlertConfig {
  const _AlertConfig({
    required this.icon,
    required this.accent,
    required this.background,
    required this.avatar,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final Color avatar;
}
