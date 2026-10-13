import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Accueil de l'administration : accès à l'ajout et à la liste des cours.
class AdminAccueilScreen extends StatelessWidget {
  const AdminAccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration CoursLibre'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Retour à la vitrine',
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/admin/gestion-cours'),
              icon: const Icon(Icons.edit_note),
              label: const Text('Ajouter un cours'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/liste-cours'),
              icon: const Icon(Icons.list_alt),
              label: const Text('Liste des cours'),
            ),
          ],
        ),
      ),
    );
  }
}
