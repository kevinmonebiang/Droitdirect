import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

enum _ConversationFilter { all, unread, urgent, read }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    required this.role,
    required this.conversations,
    required this.archivedConversationIds,
    required this.deletedConversationIds,
    this.selectedConversationId,
    required this.onSendMessage,
    required this.onOpenConversation,
    required this.onArchiveConversation,
    required this.onDeleteConversation,
  });

  final UserRole role;
  final List<ConversationPreview> conversations;
  final Set<String> archivedConversationIds;
  final Set<String> deletedConversationIds;
  final String? selectedConversationId;
  final Future<String?> Function({
    required String conversationId,
    required String content,
  }) onSendMessage;
  final Future<void> Function(String conversationId) onOpenConversation;
  final Future<String?> Function(String conversationId) onArchiveConversation;
  final Future<String?> Function(String conversationId) onDeleteConversation;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _composerController;

  String _search = '';
  String? _selectedId;
  String? _lastOpenedId;
  _ConversationFilter _filter = _ConversationFilter.all;
  bool _sending = false;
  bool _mobileDetail = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _composerController = TextEditingController();
    _selectedId = widget.selectedConversationId?.isNotEmpty == true
        ? widget.selectedConversationId
        : (widget.conversations.isNotEmpty ? widget.conversations.first.id : null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markOpened());
  }

  @override
  void didUpdateWidget(covariant MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requestedId = widget.selectedConversationId;
    if (requestedId != null &&
        requestedId.isNotEmpty &&
        requestedId != _selectedId &&
        widget.conversations.any(
          (c) =>
              c.id == requestedId &&
              !widget.archivedConversationIds.contains(c.id) &&
              !widget.deletedConversationIds.contains(c.id),
        )) {
      _selectedId = requestedId;
    }

    final exists = widget.conversations.any(
      (c) =>
          c.id == _selectedId &&
          !widget.archivedConversationIds.contains(c.id) &&
          !widget.deletedConversationIds.contains(c.id),
    );
    if (!exists) {
      final next = widget.conversations.where(
        (c) =>
            !widget.archivedConversationIds.contains(c.id) &&
            !widget.deletedConversationIds.contains(c.id),
      );
      _selectedId = next.isEmpty ? null : next.first.id;
      _mobileDetail = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _markOpened());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  List<ConversationPreview> get _sortedConversations {
    final list = [...widget.conversations];
    list.sort((a, b) {
      final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
      if (unreadCompare != 0) {
        return unreadCompare;
      }
      return _safeDate(b.lastActivityAt).compareTo(_safeDate(a.lastActivityAt));
    });
    return list;
  }

  List<ConversationPreview> get _visibleConversations {
    final q = _search.trim().toLowerCase();
    return _sortedConversations.where((conversation) {
      if (widget.archivedConversationIds.contains(conversation.id) ||
          widget.deletedConversationIds.contains(conversation.id)) {
        return false;
      }
      final source = [
        conversation.contactName,
        conversation.subtitle,
        ...conversation.messages.map((m) => m.message),
      ].join(' ').toLowerCase();
      if (q.isNotEmpty && !source.contains(q)) {
        return false;
      }
      switch (_filter) {
        case _ConversationFilter.all:
          return true;
        case _ConversationFilter.unread:
          return conversation.unreadCount > 0;
        case _ConversationFilter.urgent:
          return _isUrgent(conversation);
        case _ConversationFilter.read:
          return conversation.unreadCount == 0;
      }
    }).toList();
  }

  ConversationPreview? get _activeConversation {
    final available = widget.conversations.where(
      (c) =>
          !widget.archivedConversationIds.contains(c.id) &&
          !widget.deletedConversationIds.contains(c.id),
    );
    if (_selectedId == null) {
      return available.isEmpty ? null : available.first;
    }
    for (final conversation in available) {
      if (conversation.id == _selectedId) {
        return conversation;
      }
    }
    return available.isEmpty ? null : available.first;
  }

  List<ChatMessage> get _visibleMessages =>
      _activeConversation?.messages ?? const <ChatMessage>[];

  @override
  Widget build(BuildContext context) {
    final active = _activeConversation;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1080;
        final tablet = constraints.maxWidth >= 760;
        final mobile = !tablet;
        final showMobileChat = mobile && _mobileDetail && active != null;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFDFEFF),
                Color(0xFFF6FAFE),
                Color(0xFFF3F7FC),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _MessagesBackdrop()),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 26 : 16,
                    16,
                    desktop ? 26 : 16,
                    18,
                  ),
                  child: showMobileChat
                      ? _buildChatPane(context, active, allowBack: true, compact: true)
                      : mobile
                          ? _buildInboxPane(context, compact: true)
                          : Row(
                              children: [
                                Expanded(
                                  flex: desktop ? 44 : 46,
                                  child: _buildInboxPane(context, compact: false),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: desktop ? 56 : 54,
                                  child: _buildChatPane(
                                    context,
                                    active,
                                    allowBack: false,
                                    compact: false,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInboxPane(BuildContext context, {required bool compact}) {
    final colors = context.camrlex;
    final unread =
        widget.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Messages',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colors.navy,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                ),
              ),
              if (unread > 0)
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
                    unread > 9 ? '9+ non lus' : '$unread non lus',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'A jour',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _searchField(context),
          const SizedBox(height: 18),
          _buildStoryStrip(context),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Discussions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              _tinyFilter(context, 'Tous', _ConversationFilter.all),
              const SizedBox(width: 8),
              _tinyFilter(context, 'Non lus', _ConversationFilter.unread),
              const SizedBox(width: 8),
              _tinyFilter(context, 'Urgent', _ConversationFilter.urgent),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _visibleConversations.isEmpty
                ? _empty(
                    context,
                    'Aucune conversation',
                    'Les echanges entre clients et professionnels apparaitront ici.',
                  )
                : ListView.separated(
                    itemCount: _visibleConversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _visibleConversations[index];
                      return _ConversationTile(
                        conversation: item,
                        selected: item.id == _activeConversation?.id,
                        urgent: _isUrgent(item),
                        initials: _initials(item.contactName),
                        timeLabel: _conversationTime(item.lastActivityAt),
                        onTap: () => _selectConversation(
                          item.id,
                          openMobileDetail: compact,
                        ),
                        onArchive: () => _archiveConversation(item.id),
                        onDelete: () => _deleteConversation(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPane(
    BuildContext context,
    ConversationPreview? active, {
    required bool allowBack,
    required bool compact,
  }) {
    final colors = context.camrlex;
    if (active == null) {
      return _panel(
        context,
        child: _empty(
          context,
          'Selectionne une conversation',
          'Choisis une discussion pour lire et envoyer des messages.',
        ),
      );
    }

    return _panel(
      context,
      child: Column(
        children: [
          Row(
            children: [
              if (allowBack) ...[
                _iconButton(
                  context,
                  icon: Icons.arrow_back_rounded,
                  onTap: () => setState(() => _mobileDetail = false),
                ),
                const SizedBox(width: 12),
              ],
              _presenceAvatar(
                context,
                initials: _initials(active.contactName),
                size: compact ? 54 : 58,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.contactName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isUrgent(active)
                          ? 'Priorite elevee'
                          : 'Disponible pour echanger',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.body,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onSelected: (value) {
                  if (value == 'archive') {
                    _archiveConversation(active.id);
                  } else if (value == 'delete') {
                    _deleteConversation(active.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'archive',
                    child: Text('Archiver'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
                child: _iconButton(
                  context,
                  icon: Icons.more_horiz_rounded,
                  onTap: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Divider(color: colors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Aujourd hui',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.body,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Expanded(child: Divider(color: colors.line)),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _visibleMessages.isEmpty
                ? _empty(
                    context,
                    'Aucun message',
                    'Commence la discussion depuis le champ en bas.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _visibleMessages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final message = _visibleMessages[index];
                      return _MessageBubble(
                        message: message,
                        compact: compact,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _composerController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ecris une reponse...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.body.withValues(alpha: 0.8),
                          ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Icon(Icons.sentiment_satisfied_alt_rounded, color: colors.body),
                const SizedBox(width: 10),
                Icon(Icons.photo_outlined, color: colors.body),
                const SizedBox(width: 10),
                Icon(Icons.camera_alt_outlined, color: colors.body),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _sending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colors.navy,
                          colors.navySoft,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryStrip(BuildContext context) {
    final colors = context.camrlex;
    final contacts = _sortedConversations.take(5).toList();
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: contacts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return SizedBox(
              width: 68,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.gold.withValues(alpha: 0.72),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.add_rounded, color: colors.navy, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nouveau',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            );
          }
          final item = contacts[index - 1];
          return InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _selectConversation(item.id, openMobileDetail: false),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colors.navySoft,
                          colors.gold,
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: _avatar(
                        context,
                        initials: _initials(item.contactName),
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.contactName.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _search = value),
        decoration: InputDecoration(
          hintText: 'Rechercher une conversation...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.body.withValues(alpha: 0.72),
              ),
          prefixIcon: Icon(Icons.search_rounded, color: colors.navySoft),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) {
    final colors = context.camrlex;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.08),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _tinyFilter(
    BuildContext context,
    String label,
    _ConversationFilter value,
  ) {
    final colors = context.camrlex;
    final selected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.navy : const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : colors.navy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
    String? badge,
  }) {
    final colors = context.camrlex;
    final child = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: colors.navy, size: 22),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (onTap == null)
          child
        else
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: child,
          ),
        if (badge != null)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: colors.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Color(0xFF11284A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatar(
    BuildContext context, {
    required String initials,
    required double size,
  }) {
    final colors = context.camrlex;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.navy.withValues(alpha: 0.95),
            colors.gold.withValues(alpha: 0.92),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  Widget _presenceAvatar(
    BuildContext context, {
    required String initials,
    required double size,
  }) {
    final colors = context.camrlex;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _avatar(context, initials: initials, size: size),
        Positioned(
          top: 3,
          right: 3,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, String title, String subtitle) {
    final colors = context.camrlex;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 180;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 62 : 82,
                      height: compact ? 62 : 82,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF4FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.forum_outlined,
                        size: compact ? 28 : 34,
                        color: colors.navy,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 18 : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.body,
                            height: 1.45,
                            fontSize: compact ? 12.5 : null,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final active = _activeConversation;
    final content = _composerController.text.trim();
    if (active == null || content.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    final error = await widget.onSendMessage(
      conversationId: active.id,
      content: content,
    );
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    if (error == null) {
      _composerController.clear();
      await _markOpened();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _archiveConversation(String id) async {
    final message = await widget.onArchiveConversation(id);
    if (!mounted) {
      return;
    }
    setState(() {
      if (_selectedId == id) {
        final remaining = _visibleConversations.where((c) => c.id != id).toList();
        _selectedId = remaining.isEmpty ? null : remaining.first.id;
        _mobileDetail = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Conversation archivee.')),
    );
  }

  Future<void> _deleteConversation(String id) async {
    final message = await widget.onDeleteConversation(id);
    if (!mounted) {
      return;
    }
    setState(() {
      if (_selectedId == id) {
        final remaining = _visibleConversations.where((c) => c.id != id).toList();
        _selectedId = remaining.isEmpty ? null : remaining.first.id;
        _mobileDetail = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Conversation supprimee.')),
    );
  }

  void _selectConversation(String id, {required bool openMobileDetail}) {
    setState(() {
      _selectedId = id;
      if (openMobileDetail) {
        _mobileDetail = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _markOpened());
  }

  Future<void> _markOpened() async {
    final active = _activeConversation;
    if (!mounted || active == null) {
      return;
    }
    final shouldMark = _lastOpenedId != active.id || active.unreadCount > 0;
    if (!shouldMark) {
      return;
    }
    _lastOpenedId = active.id;
    await widget.onOpenConversation(active.id);
  }

  bool _isUrgent(ConversationPreview conversation) {
    final source = [
      conversation.subtitle,
      ...conversation.messages.map((m) => m.message),
    ].join(' ').toLowerCase();
    return source.contains('urgent') ||
        source.contains('priorite') ||
        source.contains('urgence');
  }

  DateTime _safeDate(String raw) {
    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _conversationTime(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) {
      return raw;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final other = DateTime(date.year, date.month, date.day);
    final diff = today.difference(other).inDays;
    if (diff == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (diff == 1) {
      return 'Hier';
    }
    return '$diff j';
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'DD';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

class _MessagesBackdrop extends StatelessWidget {
  const _MessagesBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 110,
          left: 42,
          child: Transform.rotate(
            angle: -0.82,
            child: Row(
              children: const [
                _DecorStroke(),
                SizedBox(width: 10),
                _DecorStroke(),
              ],
            ),
          ),
        ),
        Positioned(
          top: 240,
          right: 66,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFD8E7F8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 258,
          right: 38,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFC6DAF4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 116,
          right: 34,
          child: Transform.rotate(
            angle: -0.72,
            child: Row(
              children: const [
                _DecorStroke(),
                SizedBox(width: 10),
                _DecorStroke(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DecorStroke extends StatelessWidget {
  const _DecorStroke();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFD1DDF0),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.urgent,
    required this.initials,
    required this.timeLabel,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  final ConversationPreview conversation;
  final bool selected;
  final bool urgent;
  final String initials;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? colors.navy.withValues(alpha: 0.12)
                : const Color(0xFFF1F2F8),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colors.navy.withValues(alpha: 0.95),
                        colors.gold.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: urgent ? colors.gold : colors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.contactName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colors.navy,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.body,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.body,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'archive') {
                      onArchive();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'archive',
                      child: Text('Archiver'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                  child: Icon(Icons.more_horiz_rounded, color: colors.body),
                ),
                if (conversation.unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8A96B),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount > 9
                          ? '9+'
                          : '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Color(0xFF11284A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.compact,
  });

  final ChatMessage message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 280 : 360),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: mine
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF11284A),
                          Color(0xFF1D3A67),
                        ],
                      )
                    : null,
                color: mine ? null : const Color(0xFFF7F7FC),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(mine ? 22 : 8),
                  bottomRight: Radius.circular(mine ? 8 : 22),
                ),
              ),
              child: Text(
                message.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mine ? Colors.white : colors.ink,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                message.sentAt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.body,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
