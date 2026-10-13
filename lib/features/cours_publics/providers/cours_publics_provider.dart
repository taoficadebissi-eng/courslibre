import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cours_gratuit_model.dart';
import 'cours_cache_service.dart';

final coursCacheServiceProvider = Provider<CoursCacheService>((ref) {
  return CoursCacheService();
});

final coursPublicsProvider = FutureProvider<List<CoursGratuit>>((ref) async {
  final cacheService = ref.read(coursCacheServiceProvider);
  final hasValidCache = await cacheService.hasValidCache();

  if (hasValidCache) {
    final cachedData = await cacheService.getCachedCours();
    if (cachedData != null) {
      return cachedData
          .map(
            (json) => CoursGratuit(
              id: json['id'] as String,
              titre: json['titre'] as String,
              description: json['description'] as String,
              descriptionDetaillee: json['descriptionDetaillee'] as String,
              fournisseur: json['fournisseur'] as String,
              niveau: NiveauCours.fromString(json['niveau'] as String?),
              duree: json['duree'] as String?,
              langue: json['langue'] as String,
              certificatDisponible: json['certificatDisponible'] as bool,
              certificatPayant: json['certificatPayant'] as bool? ?? false,
              categorie: json['categorie'] as String,
              lienImage: json['lienImage'] as String?,
              lienCours: json['lienCours'] as String,
              dateAjout: json['dateAjout'] != null
                  ? DateTime.parse(json['dateAjout'] as String)
                  : null,
              actif: json['actif'] as bool? ?? true,
              ordreAffichage: json['ordreAffichage'] as int?,
            ),
          )
          .where((c) => c.actif)
          .toList()
        ..sort((a, b) {
          if (a.ordreAffichage != null && b.ordreAffichage != null) {
            return a.ordreAffichage!.compareTo(b.ordreAffichage!);
          } else if (a.ordreAffichage != null) {
            return -1;
          } else if (b.ordreAffichage != null) {
            return 1;
          } else {
            return (b.dateAjout ?? DateTime(2000)).compareTo(
              a.dateAjout ?? DateTime(2000),
            );
          }
        });
    }
  }

  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore
      .collection('cours_gratuits')
      .where('actif', isEqualTo: true)
      .get();

  final coursList =
      snapshot.docs.map((doc) {
        final cours = CoursGratuit.fromFirestore(doc);
        return cours.copyWith(id: doc.id);
      }).toList()..sort((a, b) {
        if (a.ordreAffichage != null && b.ordreAffichage != null) {
          return a.ordreAffichage!.compareTo(b.ordreAffichage!);
        } else if (a.ordreAffichage != null) {
          return -1;
        } else if (b.ordreAffichage != null) {
          return 1;
        } else {
          return (b.dateAjout ?? DateTime(2000)).compareTo(
            a.dateAjout ?? DateTime(2000),
          );
        }
      });

  final jsonData = coursList.map((c) {
    final map = c.toFirestore();
    map['id'] = c.id;
    if (c.dateAjout != null) {
      map['dateAjout'] = c.dateAjout!.toIso8601String();
    }
    return map;
  }).toList();

  await cacheService.saveCours(jsonData);
  return coursList;
});

// Correction : Le provider doit retourner une fonction void, pas un Future<void>
final refreshCoursProvider = Provider<void Function()>((ref) {
  return () async {
    final cacheService = ref.read(coursCacheServiceProvider);
    await cacheService.clearCache();
    ref.invalidate(coursPublicsProvider);
  };
});
