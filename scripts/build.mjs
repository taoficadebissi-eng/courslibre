// Génère le site statique dans dist/ à partir des cours publiés dans
// Firestore (lecture publique, sans identifiants).
//
//   npm run build
//
// Variables d'environnement :
//   SITE_URL  adresse publique (défaut : https://courslibre-gf.web.app)
//             à changer le jour où un nom de domaine est branché.
import dns from 'node:dns';
import net from 'node:net';
import { cp, mkdir, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  CONFIG, chargerCours, coursApparentes, donneesStructurees, esc, rendreCartes, rendreCours,
  rendreEntete, rendrePied, rendrePuces, signature, slugDe, statistiques, tronquer, urlCours,
} from '../site/shared.mjs';

// Certains réseaux n'ont pas d'IPv6 fonctionnel : Node attendrait alors la
// fin d'un délai avant de basculer en IPv4. On privilégie IPv4 d'emblée.
dns.setDefaultResultOrder('ipv4first');
net.setDefaultAutoSelectFamilyAttemptTimeout?.(2000);

const racine = join(dirname(fileURLToPath(import.meta.url)), '..');
const dist = join(racine, 'dist');
const SITE_URL = (process.env.SITE_URL || 'https://courslibre-gf.web.app').replace(/\/$/, '');
const maintenant = new Date().toISOString();

const TITRE_ACCUEIL = 'CoursLibre — Cours gratuits en ligne, choisis pour vous';
const DESCRIPTION_ACCUEIL =
  'Des cours gratuits des meilleures plateformes, sélectionnés à la main, classés par thème et par niveau, expliqués en français. Choisissez, cliquez, apprenez.';

function jsonLd(objet) {
  // `<` échappé : impossible de fermer la balise <script> depuis les données.
  return `<script type="application/ld+json">${JSON.stringify(objet).replace(/</g, '\\u003c')}</script>`;
}

function tete({ titre, description, chemin, image, extra = '' }) {
  const url = `${SITE_URL}${chemin}`;
  const img = image || `${SITE_URL}/img/logo-512.png`;
  return `<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(titre)}</title>
<meta name="description" content="${esc(description)}">
<link rel="canonical" href="${esc(url)}">
<meta name="theme-color" content="#14213D">
<meta property="og:type" content="website">
<meta property="og:site_name" content="CoursLibre">
<meta property="og:locale" content="fr_FR">
<meta property="og:title" content="${esc(titre)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:url" content="${esc(url)}">
<meta property="og:image" content="${esc(img)}">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" type="image/png" href="/img/favicon.png">
<link rel="apple-touch-icon" href="/img/logo-192.png">
<link rel="preload" href="/fonts/fraunces.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/fonts/manrope.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="/css/style.css">
${extra}
</head>`;
}

function page({ tete: t, corps, liste, pageId }) {
  return `${t}
<body data-page="${pageId}">
<a class="lien-evitement" href="#contenu">Aller au contenu</a>
${rendreEntete()}
<main id="contenu">
${corps}
</main>
${rendrePied(liste, maintenant)}
<script type="module" src="/js/app.js"></script>
</body>
</html>
`;
}

function accueil(liste) {
  const { cours, plateformes } = statistiques(liste);
  // Trois cours de catégories différentes pour varier l'aperçu du hero.
  const vedettes = [];
  for (const c of liste) {
    if (vedettes.length < 3 && !vedettes.some((v) => v.categorie === c.categorie)) vedettes.push(c);
  }
  for (const c of liste) {
    if (vedettes.length < 3 && !vedettes.includes(c)) vedettes.push(c);
  }
  const vide = liste.length === 0;
  const corps = `<section class="hero${vedettes.length ? '' : ' hero--sans-visuel'}">
  <div class="hero__fond" aria-hidden="true"><span class="soleil"></span><span class="grain"></span></div>
  <div class="hero__interieur">
    <div class="hero__texte">
      <p class="hero__etiquette"><span class="point"></span> 100 % gratuit · Choisi à la main</p>
      <h1 class="hero__titre">Le savoir ne devrait jamais avoir de <em>prix d'entrée</em>.</h1>
      <p class="hero__sous-titre">Les meilleurs cours gratuits des grandes plateformes, réunis, classés et expliqués en français. Choisissez, cliquez, apprenez.</p>
      <form class="recherche" id="recherche" role="search" autocomplete="off">
        <svg class="recherche__icone" viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7" fill="none" stroke="currentColor" stroke-width="2"/><path d="m20 20-3.5-3.5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
        <input id="recherche-champ" type="search" placeholder="Rechercher un cours…" aria-label="Rechercher un cours" enterkeyhint="search">
        <button type="submit">Chercher</button>
      </form>
      <ul class="hero__chiffres" id="chiffres">
        <li${vide ? ' hidden' : ''}><strong id="chiffre-cours">${cours}</strong> cours gratuits</li>
        <li${vide ? ' hidden' : ''}><strong id="chiffre-plateformes">${plateformes}</strong> plateformes</li>
        <li><strong>0 €</strong> pour apprendre</li>
      </ul>
    </div>
    ${vedettes.length ? `<div class="hero__visuel" aria-hidden="true">
      ${vedettes
        .map(
          (c, i) => `<div class="vedette vedette--${i + 1}"><span class="vedette__rubrique">${esc(c.categorie)}</span><strong>${esc(tronquer(c.titre, 48))}</strong><span class="vedette__source">${esc(c.fournisseur)}</span></div>`,
        )
        .join('\n      ')}
    </div>` : ''}
  </div>
  <svg class="hero__vague" viewBox="0 0 1440 90" preserveAspectRatio="none" aria-hidden="true"><path d="M0 60C240 100 480 10 720 40s480 50 720 0V90H0Z"/></svg>
</section>

<section class="section" id="catalogue">
  <div class="section__interieur">
    <p class="section__etiquette">Le catalogue</p>
    <h2 class="section__titre">Trouvez le cours qui vous ressemble</h2>
    <div class="outils"${vide ? ' hidden' : ''}>
      <div class="puces" id="puces" role="group" aria-label="Filtrer par catégorie">${rendrePuces(liste)}</div>
      <label class="niveau"><span>Niveau</span>
        <select id="niveau">
          <option value="">Tous les niveaux</option>
          <option value="debutant">Débutant</option>
          <option value="intermediaire">Intermédiaire</option>
          <option value="avance">Avancé</option>
        </select>
      </label>
    </div>
    <p class="compte" id="compte" aria-live="polite"${vide ? ' hidden' : ''}>${cours} cours</p>
    <div class="grille" id="grille" data-sig="${signature(liste)}">
${rendreCartes(liste)}
    </div>
    <div class="vide" id="vide"${vide ? '' : ' hidden'}>
      <p class="vide__titre" id="vide-titre">${vide ? 'Le catalogue se prépare.' : 'Aucun cours ne correspond.'}</p>
      <p id="vide-texte">${vide ? 'De nouveaux cours gratuits arrivent très bientôt. Revenez nous voir !' : 'Essayez un autre mot, ou <button type="button" class="lien" id="reinitialiser">affichez tous les cours</button>.'}</p>
    </div>
  </div>
</section>

<section class="section section--encre" id="methode">
  <div class="section__interieur">
    <p class="section__etiquette section__etiquette--clair">Comment ça marche</p>
    <h2 class="section__titre section__titre--clair">Trois gestes, zéro dépense</h2>
    <ol class="etapes">
      <li class="reveal"><span class="etapes__numero">1</span><h3>Explorez</h3><p>Filtrez par thème ou par niveau, ou cherchez directement un sujet.</p></li>
      <li class="reveal" style="--i:1"><span class="etapes__numero">2</span><h3>Choisissez</h3><p>Lisez le résumé, repérez la durée, la langue et la présence d'un certificat.</p></li>
      <li class="reveal" style="--i:2"><span class="etapes__numero">3</span><h3>Apprenez</h3><p>Un clic vous mène chez la plateforme d'origine. Pas de compte à créer chez nous.</p></li>
    </ol>
  </div>
</section>`;
  const t = tete({
    titre: TITRE_ACCUEIL,
    description: DESCRIPTION_ACCUEIL,
    chemin: '/',
    extra: jsonLd({
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      name: 'CoursLibre',
      url: SITE_URL,
      inLanguage: 'fr',
      description: DESCRIPTION_ACCUEIL,
    }),
  });
  return page({ tete: t, corps, liste, pageId: 'accueil' });
}

function pageCours(c, liste) {
  const chemin = urlCours(c);
  const titre = `${c.titre} — cours gratuit ${c.fournisseur} | CoursLibre`;
  const t = tete({
    titre,
    description: tronquer(c.description || c.descriptionDetaillee, 155),
    chemin,
    image: c.lienImage || undefined,
    extra: [
      jsonLd(donneesStructurees(c, SITE_URL)),
      jsonLd({
        '@context': 'https://schema.org',
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Accueil', item: `${SITE_URL}/` },
          { '@type': 'ListItem', position: 2, name: c.categorie, item: `${SITE_URL}/?categorie=${encodeURIComponent(c.categorie)}` },
          { '@type': 'ListItem', position: 3, name: c.titre, item: `${SITE_URL}${chemin}` },
        ],
      }),
    ].join('\n'),
  });
  return page({ tete: t, corps: rendreCours(c, coursApparentes(c, liste)), liste, pageId: 'cours' });
}

/** Page « coquille » pour les cours publiés après la dernière génération :
 *  le navigateur la remplit en direct (voir app.js). Hébergement : rewrite
 *  /cours/** -> /cours-live.html, utilisé seulement si la page statique
 *  du cours n'existe pas encore. */
function pageCoursEnDirect(liste) {
  const t = tete({
    titre: 'Cours gratuit | CoursLibre',
    description: DESCRIPTION_ACCUEIL,
    chemin: '/',
    extra: '<meta name="robots" content="noindex">',
  });
  return page({
    tete: t,
    corps: '<div id="cours-direct" class="chargement"><p>Chargement du cours…</p></div>',
    liste,
    pageId: 'cours-direct',
  });
}

function page404(liste) {
  const t = tete({
    titre: 'Page introuvable | CoursLibre',
    description: DESCRIPTION_ACCUEIL,
    chemin: '/',
    extra: '<meta name="robots" content="noindex">',
  });
  const corps = `<section class="section section--etroite"><div class="section__interieur centre">
  <p class="section__etiquette">Erreur 404</p>
  <h1 class="section__titre">Cette page a pris le large.</h1>
  <p>Le cours que vous cherchez n'existe plus ou a changé d'adresse.</p>
  <p><a class="bouton" href="/#catalogue">Voir tous les cours</a></p>
</div></section>`;
  return page({ tete: t, corps, liste, pageId: '404' });
}

function sitemap(liste) {
  const urls = [
    `<url><loc>${SITE_URL}/</loc><lastmod>${maintenant.slice(0, 10)}</lastmod><priority>1.0</priority></url>`,
    ...liste.map(
      (c) =>
        `<url><loc>${esc(SITE_URL + urlCours(c))}</loc><lastmod>${(c.dateAjout || maintenant).slice(0, 10)}</lastmod><priority>0.8</priority></url>`,
    ),
  ];
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.join('\n')}\n</urlset>\n`;
}

async function ecrire(chemin, contenu) {
  const complet = join(dist, chemin);
  await mkdir(dirname(complet), { recursive: true });
  await writeFile(complet, contenu);
}

async function main() {
  let liste;
  for (let essai = 1; ; essai++) {
    try {
      liste = await chargerCours();
      break;
    } catch (erreur) {
      if (essai >= 3) {
        console.error(`Lecture des cours impossible : ${erreur.message}`);
        process.exit(1); // ne jamais publier un site vide par accident
      }
      console.warn(`Lecture des cours échouée (essai ${essai}/3), nouvelle tentative…`);
      await new Promise((r) => setTimeout(r, 1500 * essai));
    }
  }
  // Un catalogue vide est un état valide (cours retirés à dessein) : une erreur
  // de lecture, elle, interrompt déjà la génération (voir plus haut).
  console.log(`${liste.length} cours lus.`);

  await rm(dist, { recursive: true, force: true });
  await mkdir(dist, { recursive: true });
  await cp(join(racine, 'site/static'), dist, { recursive: true });
  await cp(join(racine, 'site/shared.mjs'), join(dist, 'js/shared.mjs'));
  const polices = join(racine, 'node_modules/@fontsource-variable');
  await cp(join(polices, 'fraunces/files/fraunces-latin-wght-normal.woff2'), join(dist, 'fonts/fraunces.woff2'));
  await cp(join(polices, 'fraunces/files/fraunces-latin-wght-italic.woff2'), join(dist, 'fonts/fraunces-italic.woff2'));
  await cp(join(polices, 'manrope/files/manrope-latin-wght-normal.woff2'), join(dist, 'fonts/manrope.woff2'));

  await ecrire('index.html', accueil(liste));
  for (const c of liste) await ecrire(`cours/${slugDe(c)}.html`, pageCours(c, liste));
  await ecrire('cours-live.html', pageCoursEnDirect(liste));
  await ecrire('404.html', page404(liste));
  await ecrire('sitemap.xml', sitemap(liste));
  await ecrire('robots.txt', `User-agent: *\nAllow: /\n\nSitemap: ${SITE_URL}/sitemap.xml\n`);
  await ecrire('build.json', JSON.stringify({ genere: maintenant, cours: liste.length, projet: CONFIG.projectId }) + '\n');
  console.log(`Site généré dans dist/ (${liste.length + 4} pages).`);
}

main();
