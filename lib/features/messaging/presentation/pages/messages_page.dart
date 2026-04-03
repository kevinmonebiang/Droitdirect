import 'package:flutter/material.dart';

import '../../../../models.dart';
import '../../../../screens/home_shell.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      key: ValueKey('${role.name}-messages-shell'),
      role: role,
      initialIndex: 2,
    );
  }
}
