import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/admin_accueil_screen.dart';
import '../features/admin/admin_login_screen.dart';
import '../features/admin/gestion_cours_screen.dart';
import '../features/admin/liste_cours_screen.dart';
import '../features/cours_publics/models/cours_gratuit_model.dart';
import '../features/cours_publics/screens/accueil_public_screen.dart';
import '../features/cours_publics/screens/detail_cours_screen.dart';
import '../providers/admin_auth_provider.dart';

class _RefreshNotifier extends ChangeNotifier {
  _RefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final estAdminRoute = loc.startsWith('/admin');
      if (!estAdminRoute) return null;

      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;
      final estSuperAdmin = ref.read(estSuperAdminProvider);

      if (loc == '/admin/login') return estSuperAdmin ? '/admin' : null;
      return estSuperAdmin ? null : '/admin/login';
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AccueilPublicScreen(),
      ),
      GoRoute(
        path: '/cours/:id',
        builder: (context, state) {
          final cours = state.extra as CoursGratuit?;
          // Accès direct à l'URL sans passer par une carte : retour à l'accueil.
          if (cours == null) return const AccueilPublicScreen();
          return DetailCoursScreen(cours: cours);
        },
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminAccueilScreen(),
      ),
      GoRoute(
        path: '/admin/gestion-cours',
        builder: (context, state) => const GestionCoursScreen(),
      ),
      GoRoute(
        path: '/admin/liste-cours',
        builder: (context, state) => const ListeCoursScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page introuvable'))),
  );
});
