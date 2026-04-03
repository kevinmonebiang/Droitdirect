import 'package:flutter/material.dart';

import '../../../../models.dart';
import '../../../../screens/home_shell.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      key: ValueKey('${role.name}-notifications-shell'),
      role: role,
      initialIndex: 4,
    );
  }
}
