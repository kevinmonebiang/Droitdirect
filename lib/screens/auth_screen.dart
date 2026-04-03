import 'package:flutter/material.dart';

import '../models.dart';
import 'home_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  UserRole _selectedRole = UserRole.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _openApp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeShell(role: _selectedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D7F3F),
                      Color(0xFFF2B705),
                      Color(0xFFB71C1C)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DroitDirect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reserve un avocat, un huissier ou un notaire en quelques minutes.',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Application juridique pour les ciyoyen, entreprises et les professionnels du droit au Cameroun.',
                      style: TextStyle(color: Colors.white, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Connexion', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Les clients recherchent et reservent. Les professionnels creent leur profil, soumettent leurs justificatifs et recoivent des reservations apres validation.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: UserRole.values.map((role) {
                  final selected = role == _selectedRole;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      role.label,
                    ),
                    onSelected: (_) => setState(() => _selectedRole = role),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telephone',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email ou numero de telephone',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _openApp,
                child: Text(
                  switch (_selectedRole) {
                    UserRole.client => 'Se connecter comme Client',
                    UserRole.professional =>
                      'Entrer dans l espace professionnel',
                    UserRole.admin => 'Ouvrir la console administrateur',
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regles de verification',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Documents demandes: CNI, numero du barreau ou identifiant professionnel, diplome, photo entiere et portrait. Le professionnel ne peut recevoir des reservations qu apres validation admin.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
