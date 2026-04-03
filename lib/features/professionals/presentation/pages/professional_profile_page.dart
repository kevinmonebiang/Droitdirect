import 'package:flutter/material.dart';

import '../../../../models.dart';
import '../../../../screens/home_shell.dart';

class ProfessionalProfilePage extends StatelessWidget {
  const ProfessionalProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShell(
      key: ValueKey('professional-profile-shell'),
      role: UserRole.professional,
      initialIndex: 3,
    );
  }
}
