# CoursLibre

Vitrine publique de cours gratuits, en **HTML / CSS / JavaScript** (sans
framework), pensée pour le référencement : une vraie page par cours, titres et
descriptions propres à chaque page, données structurées *schema.org*, plan du
site, chargement très léger (~8 Ko pour l'accueil).

L'espace privé (publier / modifier / supprimer les cours, compteur de
visiteurs) n'est **plus ici** : il se trouve dans l'application *Gestion
Formation* (dépôt `Gestion-formation-CL`), derrière une authentification.

## Comment ça marche

```
Espace privé (Gestion Formation)         Visiteurs
        │ ajoute / modifie un cours            │
        ▼                                      ▼
   Firestore  ──── lecture publique ───►  page d'accueil (JS)  → cours à jour immédiatement
        │
        └──── toutes les heures ────► GitHub Actions ──► npm run build ──► Firebase Hosting
                                                         (pages statiques + sitemap pour Google)
```

- **Immédiat :** la page d'accueil relit Firestore à chaque visite (et au retour
  sur l'onglet) : un cours ajouté apparaît sans attendre.
- **Référencement :** le script `scripts/build.mjs` génère une page HTML par
  cours + `sitemap.xml` + `robots.txt`. Un cours très récent, pas encore généré,
  s'affiche quand même (page `cours-live.html`, remplie en direct) et sera
  généré à la prochaine publication.

## Développement

```bash
npm install
npm run build          # génère dist/ depuis les cours publiés (nécessite le réseau)
npm run serve          # aperçu local via l'émulateur Firebase Hosting
```

Structure : `site/shared.mjs` (rendu, partagé Node + navigateur),
`site/static/` (CSS, JS, images ; les polices Fraunces et Manrope sont
copiées depuis `node_modules`), `scripts/build.mjs` (génération).

## Publication

Manuelle :
```bash
npm run build
npx firebase-tools deploy --only hosting --project gestion-de-formation-5b049
```

### Publication automatique (une seule fois)
Le workflow `.github/workflows/publier.yml` publie toutes les heures et à chaque
push. Il lui faut un jeton Firebase :

```bash
firebase login:ci                                   # affiche un jeton (1//0...)
gh secret set FIREBASE_TOKEN --repo taoficadebissi-eng/courslibre
# collez le jeton quand il est demandé
```
Notes : GitHub désactive les tâches planifiées d'un dépôt sans aucune activité
pendant 60 jours (un push les réactive). `firebase login:ci` est déprécié par
Firebase mais fonctionne ; l'alternative durable est un compte de service
(rôle « Firebase Hosting Admin ») stocké en secret.

## Projet Firebase partagé
Même projet que Gestion Formation (`gestion-de-formation-5b049`), site
d'hébergement `courslibre-gf`. Les règles Firestore sont dans le dépôt Gestion :
lecture publique de `cours_gratuits`, écriture réservée au super-admin ;
`compteur/visiteurs` n'accepte que +1.

## Nom de domaine
Pas encore de domaine. Quand il y en aura un : le brancher dans la console
Firebase (Hosting → Ajouter un domaine personnalisé), puis définir la variable
GitHub `SITE_URL` (Settings → Variables) avec la nouvelle adresse pour que les
liens canoniques et le plan du site l'utilisent. L'ancienne adresse
`courslibre-gf.web.app` continue de fonctionner.
