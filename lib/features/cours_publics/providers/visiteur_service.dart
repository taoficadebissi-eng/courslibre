import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compteur de visiteurs custom Firestore : 1 seule écriture par appareil et
/// par jour (suivi via shared_preferences), pour rester compatible avec le
/// plan Firebase Spark (pas de Firebase Analytics, coûts maîtrisés).
class VisiteurService {
  static const String _docId = 'visiteurs';
  static const String _keyDerniereVisite = 'derniere_visite_comptee';

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('compteur').doc(_docId);

  Stream<int> ecouterTotal() {
    return _doc.snapshots().map((snap) => (snap.data()?['total'] as int?) ?? 0);
  }

  Future<void> enregistrerVisiteSiNecessaire() async {
    final prefs = await SharedPreferences.getInstance();
    final aujourdhui = _cleJour(DateTime.now());
    final derniereVisite = prefs.getString(_keyDerniereVisite);
    if (derniereVisite == aujourdhui) return;

    try {
      await _doc.set({
        'total': FieldValue.increment(1),
      }, SetOptions(merge: true));
      await prefs.setString(_keyDerniereVisite, aujourdhui);
    } catch (_) {
      // Silencieux : le compteur est cosmétique, il ne doit jamais bloquer
      // l'affichage de la page publique en cas d'échec réseau/règles.
    }
  }

  String _cleJour(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
