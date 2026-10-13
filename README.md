# CoursLibre

Vitrine publique de cours gratuits (Coursera, edX, Google…), en Flutter web +
Firebase. Projet **indépendant** de Gestion Formation : seul le lien
« Connexion / Gestion Formation » pointe vers l'autre application
(`lib/core/config/app_config.dart`).

## Fonctionnement
- Lecture publique de `cours_gratuits` ; cache local (`shared_preferences`).
- Compteur de visiteurs (`compteur/visiteurs`) : +1 par appareil et par jour,
  strictement borné par les règles Firestore.
- Administration sur `/admin` : connexion Firebase Auth réservée au compte
  super-admin (`taoficadebissi@gmail.com`, e-mail vérifié) — mêmes conditions
  dans le routeur et dans `firestore.rules`.
- Plan Spark : pas de Storage ni de Cloud Functions ; les images sont des liens.

## Mise en route
```bash
flutter pub get
flutter run -d chrome
flutter build web --release
firebase deploy --only firestore:rules,hosting
```

## Configuration Firebase (à faire une fois)
`lib/firebase_options.dart` est **provisoire** (copie de celle de Gestion).
Créez un projet Firebase dédié (Authentication e-mail/mot de passe + Firestore),
puis `flutterfire configure` dans ce dossier, et mettez à jour `.firebaserc`.
Créez et vérifiez le compte super-admin dans ce projet.
