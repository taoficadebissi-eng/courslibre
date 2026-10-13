import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'visiteur_service.dart';

final visiteurServiceProvider = Provider<VisiteurService>((ref) {
  return VisiteurService();
});

/// Nombre total de visites, mis à jour en temps réel.
final visiteurCountProvider = StreamProvider<int>((ref) {
  return ref.watch(visiteurServiceProvider).ecouterTotal();
});
