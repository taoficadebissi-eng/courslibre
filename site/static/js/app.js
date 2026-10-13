// Comportement du navigateur : filtres, apparition au scroll, mise à jour en
// direct du catalogue, compteur de visiteurs. Le site fonctionne sans ce
// script (pages pré-générées) ; il ajoute l'interactivité et la fraîcheur.
import {
  CONFIG, chargerCours, estExpire, categoriesDe, coursApparentes, donneesStructurees, esc, rendreCartes,
  rendreCours, rendrePuces, signature, slugDe, statistiques, tronquer, texteRecherche,
} from '/js/shared.mjs';

document.documentElement.classList.add('js');

const $ = (selecteur, racine = document) => racine.querySelector(selecteur);
const $$ = (selecteur, racine = document) => [...racine.querySelectorAll(selecteur)];
const page = document.body.dataset.page;

// ---------- En-tête ----------
const entete = $('#entete');
const majEntete = () => entete?.classList.toggle('is-fixe', window.scrollY > 24 || page !== 'accueil');
majEntete();
window.addEventListener('scroll', majEntete, { passive: true });

const burger = $('#burger');
const nav = $('#nav');
burger?.addEventListener('click', () => {
  const ouvert = burger.getAttribute('aria-expanded') !== 'true';
  burger.setAttribute('aria-expanded', String(ouvert));
  nav.classList.toggle('is-ouvert', ouvert);
});
nav?.addEventListener('click', (e) => {
  if (e.target.closest('a')) {
    burger.setAttribute('aria-expanded', 'false');
    nav.classList.remove('is-ouvert');
  }
});

// ---------- Apparition au scroll + survol « au défilement » ----------
// Écrans tactiles (pas de survol) : la carte la plus proche du centre de
// l'écran reçoit le même relief que le survol à la souris.
const observateur = new IntersectionObserver(
  (entrees) => {
    for (const e of entrees) {
      if (e.isIntersecting) {
        e.target.classList.add('est-visible');
        observateur.unobserve(e.target);
      }
    }
  },
  { rootMargin: '0px 0px -8% 0px', threshold: 0.08 },
);

function observer(racine = document) {
  $$('.reveal:not(.est-visible)', racine).forEach((el) => observateur.observe(el));
}

const tactile = window.matchMedia('(hover: none)').matches;
let enVue = null;
function majCarteEnVue() {
  if (!tactile) return;
  const centre = window.innerHeight / 2;
  let meilleure = null;
  let ecart = Infinity;
  for (const carte of $$('.carte.est-visible')) {
    const r = carte.getBoundingClientRect();
    if (r.bottom < 0 || r.top > window.innerHeight) continue;
    const d = Math.abs(r.top + r.height / 2 - centre);
    if (d < ecart) { ecart = d; meilleure = carte; }
  }
  if (meilleure !== enVue) {
    enVue?.classList.remove('en-vue');
    meilleure?.classList.add('en-vue');
    enVue = meilleure;
  }
}
let attente = false;
window.addEventListener('scroll', () => {
  if (attente) return;
  attente = true;
  requestAnimationFrame(() => { majCarteEnVue(); attente = false; });
}, { passive: true });

// Image de couverture inaccessible : on retombe sur le dégradé.
document.addEventListener('error', (e) => {
  if (e.target.tagName === 'IMG' && (e.target.classList.contains('carte__img') || e.target.classList.contains('fiche__img'))) e.target.remove();
}, true);

observer();

// ---------- Accueil : filtres ----------
const etat = { q: '', cat: '', niveau: '' };
const grille = $('#grille');

function normaliser(texte) {
  return texte.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
}

// Un cours dont la date de fin est passée disparaît, même si la page
// pré-générée l'affiche encore (elle n'est régénérée qu'une fois par heure).
function expire(element) {
  const fin = element.dataset.fin;
  return Boolean(fin) && estExpire({ dateFin: fin });
}

function appliquerFiltres() {
  if (!grille) return;
  const mots = normaliser(etat.q).split(/\s+/).filter(Boolean);
  let visibles = 0;
  for (const carte of $$('.carte', grille)) {
    const ok =
      !expire(carte) &&
      (!etat.cat || carte.dataset.cat === etat.cat) &&
      (!etat.niveau || carte.dataset.niveau === etat.niveau) &&
      mots.every((m) => carte.dataset.q.includes(m));
    carte.hidden = !ok;
    if (ok) visibles++;
  }
  $('#compte').textContent = `${visibles} cours${etat.cat ? ` · ${etat.cat}` : ''}`;
  const chiffre = $('#chiffre-cours');
  if (chiffre && !etat.cat && !etat.q && !etat.niveau) chiffre.textContent = visibles;
  $('#vide').hidden = visibles !== 0;
  $$('.puce').forEach((p) => p.classList.toggle('is-actif', p.dataset.cat === etat.cat));
  const url = new URL(location.href);
  etat.cat ? url.searchParams.set('categorie', etat.cat) : url.searchParams.delete('categorie');
  history.replaceState(null, '', url);
  majCarteEnVue();
}

// Page d'un cours : date de fin passée -> message, lien d'accès retiré, et
// la page n'est plus à indexer.
const fiche = $('.fiche[data-fin]');
if (fiche && expire(fiche)) {
  const avis = document.createElement('div');
  avis.className = 'avis-termine';
  avis.innerHTML = '<strong>Ce cours est terminé.</strong> Il n\'est plus proposé. <a href="/#catalogue">Voir les cours disponibles</a>';
  fiche.before(avis);
  $$('.bouton--grand', fiche).forEach((b) => b.remove());
  const meta = document.createElement('meta');
  meta.name = 'robots';
  meta.content = 'noindex';
  document.head.append(meta);
}

if (grille) {
  const params = new URLSearchParams(location.search);
  etat.cat = params.get('categorie') ?? '';

  $('#recherche').addEventListener('submit', (e) => {
    e.preventDefault();
    etat.q = $('#recherche-champ').value;
    appliquerFiltres();
    $('#catalogue').scrollIntoView({ behavior: 'smooth' });
  });
  $('#recherche-champ').addEventListener('input', (e) => {
    etat.q = e.target.value;
    appliquerFiltres();
  });
  $('#niveau').addEventListener('change', (e) => {
    etat.niveau = e.target.value;
    appliquerFiltres();
  });
  $('#puces').addEventListener('click', (e) => {
    const puce = e.target.closest('.puce');
    if (!puce) return;
    etat.cat = puce.dataset.cat;
    appliquerFiltres();
  });
  $('#reinitialiser').addEventListener('click', () => {
    Object.assign(etat, { q: '', cat: '', niveau: '' });
    $('#recherche-champ').value = '';
    $('#niveau').value = '';
    appliquerFiltres();
  });
  if (etat.cat) appliquerFiltres();
}

// ---------- Mise à jour en direct du catalogue ----------
// Un cours ajouté, modifié ou supprimé dans l'espace privé apparaît ici à la
// prochaine visite (ou au retour sur l'onglet), sans attendre la régénération
// des pages statiques.
function appliquerCatalogue(liste) {
  if (!grille || signature(liste) === grille.dataset.sig) return;
  grille.dataset.sig = signature(liste);
  grille.innerHTML = rendreCartes(liste);
  $('#puces').innerHTML = rendrePuces(liste);
  const { cours, plateformes } = statistiques(liste);
  $('#chiffre-cours').textContent = cours;
  $('#chiffre-plateformes').textContent = plateformes;
  if (etat.cat && !categoriesDe(liste).some((c) => c.nom === etat.cat)) etat.cat = '';
  observer(grille);
  appliquerFiltres();
}

let dernierChargement = Date.now();
async function actualiser() {
  try {
    const liste = await chargerCours();
    dernierChargement = Date.now();
    appliquerCatalogue(liste);
    return liste;
  } catch {
    return null; // hors ligne : on garde la page pré-générée
  }
}

if (page === 'accueil') {
  actualiser();
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && Date.now() - dernierChargement > 5 * 60 * 1000) actualiser();
  });
}

// ---------- Page d'un cours publié après la dernière génération ----------
async function afficherCoursEnDirect() {
  const cible = $('#cours-direct');
  const slug = decodeURIComponent(location.pathname.replace(/^\/cours\//, '').replace(/\/$/, ''));
  const liste = await actualiser();
  const cours = liste?.find((c) => slugDe(c) === slug);  // les cours expirés sont déjà exclus de la liste
  if (!cours) {
    cible.innerHTML = `<div class="centre"><h1 class="section__titre">Cours introuvable</h1><p>Ce cours n'existe plus ou n'est plus visible.</p><p><a class="bouton" href="/#catalogue">Voir tous les cours</a></p></div>`;
    return;
  }
  document.title = `${cours.titre} — cours gratuit ${cours.fournisseur} | CoursLibre`;
  cible.className = '';
  cible.innerHTML = rendreCours(cours, coursApparentes(cours, liste));
  const script = document.createElement('script');
  script.type = 'application/ld+json';
  script.textContent = JSON.stringify(donneesStructurees(cours, location.origin)).replace(/</g, '\\u003c');
  document.head.append(script);
  observer(cible);
  $$('.reveal', cible).forEach((el) => el.classList.add('est-visible'));
}
if (page === 'cours-direct') afficherCoursEnDirect();

// ---------- Compteur de visiteurs ----------
// +1 par appareil et par jour. Les règles Firestore n'autorisent que cette
// opération sur `compteur/visiteurs` (incrément strict de 1).
async function compterVisite() {
  const jour = new Date().toISOString().slice(0, 10);
  try {
    if (localStorage.getItem('cl_visite') === jour) return;
    const racine = `projects/${CONFIG.projectId}/databases/(default)/documents`;
    const reponse = await fetch(
      `https://firestore.googleapis.com/v1/${racine}:commit?key=${CONFIG.apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          writes: [{ transform: { document: `${racine}/compteur/visiteurs`, fieldTransforms: [{ fieldPath: 'total', increment: { integerValue: '1' } }] } }],
        }),
      },
    );
    if (reponse.ok) localStorage.setItem('cl_visite', jour);
  } catch {
    /* compteur cosmétique : ne jamais gêner la lecture */
  }
}
if (page === 'accueil') compterVisite();
