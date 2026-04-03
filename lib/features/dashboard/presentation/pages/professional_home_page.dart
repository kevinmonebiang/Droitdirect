import 'package:flutter/material.dart';

import '../../../../models.dart';
import '../../../../screens/home_shell.dart';

class ProfessionalHomePage extends StatelessWidget {
  const ProfessionalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShell(
      key: ValueKey('professional-home-shell'),
      role: UserRole.professional,
    );
  }
}
