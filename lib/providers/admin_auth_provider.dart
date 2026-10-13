import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// Vrai si l'utilisateur connecté est le super-admin (e-mail vérifié). Les
/// règles Firestore refont la même vérification côté serveur : ce provider
/// ne sert qu'à orienter la navigation.
final estSuperAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user != null &&
      user.emailVerified &&
      user.email?.toLowerCase() == superAdminEmail;
});
