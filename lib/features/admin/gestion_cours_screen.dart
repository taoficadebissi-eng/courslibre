// lib/features/auth/gestion_cours_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../cours_publics/models/cours_gratuit_model.dart';
import '../cours_publics/providers/cours_publics_provider.dart';
import '../../widgets/blurred_toast.dart';

class GestionCoursScreen extends ConsumerStatefulWidget {
  const GestionCoursScreen({super.key});

  @override
  ConsumerState<GestionCoursScreen> createState() => _GestionCoursScreenState();
}

class _GestionCoursScreenState extends ConsumerState<GestionCoursScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionDetailleeController = TextEditingController();
  final _fournisseurController = TextEditingController();
  final _dureeController = TextEditingController();
  final _langueController = TextEditingController(text: 'Français');
  final _categorieController = TextEditingController();
  final _lienCoursController = TextEditingController();

  NiveauCours _niveau = NiveauCours.debutant;
  bool _certificatDisponible = false;
  bool _certificatPayant = false;
  bool _actif = true;

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _descriptionDetailleeController.dispose();
    _fournisseurController.dispose();
    _dureeController.dispose();
    _langueController.dispose();
    _categorieController.dispose();
    _lienCoursController.dispose();
    super.dispose();
  }

  InputDecoration _boxDecoration(String label, {bool optionnel = false}) {
    return InputDecoration(
      labelText: optionnel ? '$label (optionnel)' : label,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5),
      ),
    );
  }

  Widget _sectionTitle(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Future<void> _sauvegarderCours() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final nouveauCours = CoursGratuit(
        id: '',
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        descriptionDetaillee: _descriptionDetailleeController.text.trim(),
        fournisseur: _fournisseurController.text.trim(),
        niveau: _niveau,
        duree: _dureeController.text.trim().isEmpty
            ? null
            : _dureeController.text.trim(),
        langue: _langueController.text.trim(),
        certificatDisponible: _certificatDisponible,
        certificatPayant: _certificatPayant,
        categorie: _categorieController.text.trim(),
        lienCours: _lienCoursController.text.trim(),
        actif: _actif,
      );

      await FirebaseFirestore.instance
          .collection('cours_gratuits')
          .add(nouveauCours.toFirestore(isNew: true));

      // Invalide le cache local pour que le nouveau cours apparaisse
      // immédiatement sur la page publique, sans attendre les 24h de TTL.
      ref.read(refreshCoursProvider)();

      if (mounted) {
        BlurredToast.show(
          context,
          'Cours ajouté avec succès !',
          icon: Icons.check_circle_outline,
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        BlurredToast.show(context, 'Erreur : $e', icon: Icons.error_outline);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _titreController.clear();
    _descriptionController.clear();
    _descriptionDetailleeController.clear();
    _fournisseurController.clear();
    _dureeController.clear();
    _categorieController.clear();
    _lienCoursController.clear();
    setState(() {
      _niveau = NiveauCours.debutant;
      _certificatDisponible = false;
      _certificatPayant = false;
      _actif = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Ajouter un cours gratuit'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('INFORMATIONS PRINCIPALES'),
              TextFormField(
                controller: _titreController,
                decoration: _boxDecoration('Titre *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _fournisseurController,
                decoration: _boxDecoration('Fournisseur *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<NiveauCours>(
                initialValue: _niveau,
                decoration: _boxDecoration('Niveau *'),
                items: NiveauCours.values
                    .map(
                      (n) => DropdownMenuItem(value: n, child: Text(n.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _niveau = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categorieController,
                decoration: _boxDecoration('Catégorie *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),

              _sectionTitle('DESCRIPTIONS'),
              TextFormField(
                controller: _descriptionController,
                decoration: _boxDecoration('Description courte *'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionDetailleeController,
                decoration: _boxDecoration('Description détaillée *'),
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),

              _sectionTitle('ACCÈS AU COURS'),
              TextFormField(
                controller: _lienCoursController,
                decoration: _boxDecoration('Lien vers le cours *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dureeController,
                      decoration: _boxDecoration('Durée', optionnel: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _langueController,
                      decoration: _boxDecoration('Langue *'),
                    ),
                  ),
                ],
              ),

              _sectionTitle('OPTIONS'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Certificat disponible'),
                      value: _certificatDisponible,
                      onChanged: (v) =>
                          setState(() => _certificatDisponible = v ?? false),
                    ),
                    if (_certificatDisponible)
                      CheckboxListTile(
                        title: const Text('Certificat payant ?'),
                        value: _certificatPayant,
                        onChanged: (v) =>
                            setState(() => _certificatPayant = v ?? false),
                      ),
                    CheckboxListTile(
                      title: const Text('Cours actif (visible)'),
                      value: _actif,
                      onChanged: (v) => setState(() => _actif = v ?? true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _sauvegarderCours,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ENREGISTRER LE COURS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
