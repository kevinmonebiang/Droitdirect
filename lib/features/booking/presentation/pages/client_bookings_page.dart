import 'package:flutter/material.dart';

import '../../../../models.dart';
import '../../../../screens/home_shell.dart';

class ClientBookingsPage extends StatelessWidget {
  const ClientBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShell(
      key: ValueKey('client-bookings-shell'),
      role: UserRole.client,
      initialIndex: 1,
    );
  }
}
