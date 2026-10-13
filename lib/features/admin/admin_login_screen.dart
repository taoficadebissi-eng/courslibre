import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Connexion du super-admin (compte Firebase Auth). La navigation vers
/// `/admin` est faite par le routeur dès que le compte est reconnu.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _motDePasse.text,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        // Premiere connexion : on envoie le lien de verification, puis on
        // deconnecte. Apres avoir clique sur le lien, se reconnecter.
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(
            () => _erreur =
                'E-mail non verifie : un lien vient de vous etre envoye. '
                'Cliquez dessus (spams compris), puis reconnectez-vous.',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(
        () => _erreur = e.code == 'too-many-requests'
            ? 'Trop de tentatives, reessayez dans quelques minutes'
            : 'Email ou mot de passe incorrect',
      );
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _reinitialiser() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _erreur = 'Saisissez votre e-mail d\'abord');
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('E-mail de réinitialisation envoyé')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration CoursLibre'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _motDePasse,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  onSubmitted: (_) => _connecter(),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _enCours ? null : _connecter,
                    child: Text(_enCours ? 'Connexion...' : 'Se connecter'),
                  ),
                ),
                TextButton(
                  onPressed: _reinitialiser,
                  child: const Text('Mot de passe oublié ?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
