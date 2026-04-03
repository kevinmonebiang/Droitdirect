import 'package:flutter/material.dart';

import '../../../../models.dart';
import '../../../../screens/home_shell.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShell(
      key: ValueKey('client-home-shell'),
      role: UserRole.client,
    );
  }
}
