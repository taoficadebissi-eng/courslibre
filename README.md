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

## Projet Firebase partagé
CoursLibre utilise le **même projet Firebase** que Gestion Formation
(`gestion-de-formation-5b049`, affiché « CoursLibre » dans la console), avec :
- son propre site Hébergement (`courslibre-gf`) ;
- les règles Firestore **définies dans le dépôt Gestion** (`firestore.rules`,
  sections `cours_gratuits` et `compteur`). Ce dépôt ne déploie donc **que**
  l'hébergement : ne jamais y ajouter de règles Firestore, elles écraseraient
  celles de Gestion.

## Mise en route
```bash
flutter pub get
flutter run -d chrome
flutter build web --release
firebase deploy --only hosting
```

Premier déploiement : créer le site une fois avec
`firebase hosting:sites:create courslibre-gf` (si le nom est pris, en choisir
un autre et le reporter dans `firebase.json`).
