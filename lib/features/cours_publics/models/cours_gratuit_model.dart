import 'package:cloud_firestore/cloud_firestore.dart';

enum NiveauCours {
  debutant('Débutant'),
  intermediaire('Intermédiaire'),
  avance('Avancé');

  final String label;
  const NiveauCours(this.label);

  static NiveauCours fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'intermédiaire':
      case 'intermediaire':
        return NiveauCours.intermediaire;
      case 'avancé':
      case 'avance':
        return NiveauCours.avance;
      default:
        return NiveauCours.debutant;
    }
  }
}

class CoursGratuit {
  final String id;
  final String titre;
  final String description;
  final String descriptionDetaillee;
  final String fournisseur;
  final NiveauCours niveau;
  final String? duree;
  final String langue;
  final bool certificatDisponible;
  final bool certificatPayant;
  final String categorie;
  final String? lienImage;
  final String lienCours;
  final DateTime? dateAjout;
  final bool actif;
  final int? ordreAffichage;

  const CoursGratuit({
    required this.id,
    required this.titre,
    required this.description,
    required this.descriptionDetaillee,
    required this.fournisseur,
    required this.niveau,
    this.duree,
    required this.langue,
    required this.certificatDisponible,
    this.certificatPayant = false,
    required this.categorie,
    this.lienImage,
    required this.lienCours,
    this.dateAjout,
    required this.actif,
    this.ordreAffichage,
  });

  factory CoursGratuit.empty() => CoursGratuit(
    id: '',
    titre: '',
    description: '',
    descriptionDetaillee: '',
    fournisseur: '',
    niveau: NiveauCours.debutant,
    langue: 'Français',
    certificatDisponible: false,
    certificatPayant: false,
    categorie: '',
    lienCours: '',
    actif: true,
  );

  factory CoursGratuit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoursGratuit(
      id: doc.id,
      titre: (data['titre'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      descriptionDetaillee: (data['descriptionDetaillee'] as String?) ?? '',
      fournisseur: (data['fournisseur'] as String?) ?? '',
      niveau: NiveauCours.fromString(data['niveau'] as String?),
      duree: data['duree'] as String?,
      langue: (data['langue'] as String?) ?? '',
      certificatDisponible: (data['certificatDisponible'] as bool?) ?? false,
      certificatPayant: (data['certificatPayant'] as bool?) ?? false,
      categorie: (data['categorie'] as String?) ?? '',
      lienImage: data['lienImage'] as String?,
      lienCours: (data['lienCours'] as String?) ?? '',
      dateAjout: (data['dateAjout'] as Timestamp?)?.toDate(),
      actif: (data['actif'] as bool?) ?? true,
      ordreAffichage: (data['ordreAffichage'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    return {
      'titre': titre,
      'description': description,
      'descriptionDetaillee': descriptionDetaillee,
      'fournisseur': fournisseur,
      'niveau': niveau.label,
      'duree': duree,
      'langue': langue,
      'certificatDisponible': certificatDisponible,
      'certificatPayant': certificatPayant,
      'categorie': categorie,
      'lienImage': lienImage,
      'lienCours': lienCours,
      'actif': actif,
      'ordreAffichage': ordreAffichage,
      if (isNew) 'dateAjout': FieldValue.serverTimestamp(),
    };
  }

  CoursGratuit copyWith({
    String? id,
    String? titre,
    String? description,
    String? descriptionDetaillee,
    String? fournisseur,
    NiveauCours? niveau,
    String? duree,
    String? langue,
    bool? certificatDisponible,
    bool? certificatPayant,
    String? categorie,
    String? lienImage,
    String? lienCours,
    DateTime? dateAjout,
    bool? actif,
    int? ordreAffichage,
  }) {
    return CoursGratuit(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      descriptionDetaillee: descriptionDetaillee ?? this.descriptionDetaillee,
      fournisseur: fournisseur ?? this.fournisseur,
      niveau: niveau ?? this.niveau,
      duree: duree ?? this.duree,
      langue: langue ?? this.langue,
      certificatDisponible: certificatDisponible ?? this.certificatDisponible,
      certificatPayant: certificatPayant ?? this.certificatPayant,
      categorie: categorie ?? this.categorie,
      lienImage: lienImage ?? this.lienImage,
      lienCours: lienCours ?? this.lienCours,
      dateAjout: dateAjout ?? this.dateAjout,
      actif: actif ?? this.actif,
      ordreAffichage: ordreAffichage ?? this.ordreAffichage,
    );
  }
}
