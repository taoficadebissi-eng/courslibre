// Code partagé : utilisé à la fois par le script de génération (Node) et par
// le navigateur (/js/shared.mjs). Une seule source pour le rendu des cartes,
// afin que la page pré-générée (SEO) et la page mise à jour en direct soient
// strictement identiques.

export const CONFIG = {
  siteName: 'CoursLibre',
  projectId: 'gestion-de-formation-5b049',
  // Clé web Firebase : publique par conception (la sécurité repose sur les
  // règles Firestore, qui n'ouvrent que la lecture des cours et le compteur).
  apiKey: 'AIzaSyD-FZgp9wsD5r5oSXH8f1C6Bu-DKbeQu5g',
};

const DOCS = `https://firestore.googleapis.com/v1/projects/${CONFIG.projectId}/databases/(default)/documents`;

// ---------- Utilitaires ----------

export function esc(valeur) {
  return String(valeur ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function slugify(texte) {
  return String(texte ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/&/g, ' et ')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 70)
    .replace(/-+$/g, '');
}

/** Adresse d'un cours : titre lisible + début de l'identifiant (unicité). */
export function slugDe(cours) {
  return `${slugify(cours.titre) || 'cours'}-${cours.id.slice(0, 6).toLowerCase()}`;
}

export function urlCours(cours) {
  return `/cours/${slugDe(cours)}`;
}

/** N'accepte que les liens https (jamais javascript:, data:, http:). */
export function lienSur(url) {
  try {
    const u = new URL(String(url ?? ''));
    return u.protocol === 'https:' ? u.href : '';
  } catch {
    return '';
  }
}

export function tronquer(texte, max) {
  const t = String(texte ?? '').replace(/\s+/g, ' ').trim();
  if (t.length <= max) return t;
  return t.slice(0, max - 1).replace(/\s+\S*$/, '') + '…';
}

export function signature(liste) {
  const brut = JSON.stringify(liste);
  let h = 5381;
  for (let i = 0; i < brut.length; i++) h = ((h << 5) + h + brut.charCodeAt(i)) | 0;
  return (h >>> 0).toString(36);
}

// ---------- Données (API REST Firestore, lecture publique) ----------

function valeur(v) {
  if (!v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('timestampValue' in v) return v.timestampValue;
  return null;
}

const NIVEAUX = {
  debutant: 'Débutant',
  intermediaire: 'Intermédiaire',
  avance: 'Avancé',
};

function cleNiveau(texte) {
  const t = String(texte ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim();
  if (t.startsWith('inter')) return 'intermediaire';
  if (t.startsWith('avan')) return 'avance';
  return 'debutant';
}

export function normaliser(doc) {
  const f = {};
  for (const [cle, v] of Object.entries(doc.fields ?? {})) f[cle] = valeur(v);
  const niveauCle = cleNiveau(f.niveau);
  return {
    id: doc.name.split('/').pop(),
    titre: f.titre ?? '',
    description: f.description ?? '',
    descriptionDetaillee: f.descriptionDetaillee ?? '',
    fournisseur: f.fournisseur ?? '',
    niveauCle,
    niveau: NIVEAUX[niveauCle],
    duree: f.duree || '',
    langue: f.langue ?? '',
    certificatDisponible: f.certificatDisponible === true,
    certificatPayant: f.certificatPayant === true,
    categorie: f.categorie ?? '',
    lienImage: lienSur(f.lienImage),
    lienCours: lienSur(f.lienCours),
    dateAjout: f.dateAjout ?? '',
    actif: f.actif !== false,
    ordre: typeof f.ordreAffichage === 'number' ? f.ordreAffichage : null,
  };
}

function comparer(a, b) {
  if (a.ordre !== null && b.ordre !== null && a.ordre !== b.ordre) return a.ordre - b.ordre;
  if (a.ordre !== null && b.ordre === null) return -1;
  if (a.ordre === null && b.ordre !== null) return 1;
  return String(b.dateAjout).localeCompare(String(a.dateAjout));
}

/** Cours visibles (actif, avec lien valide), triés comme dans l'espace admin. */
export async function chargerCours(fetchFn = fetch) {
  const tous = [];
  let page = '';
  do {
    const url = `${DOCS}/cours_gratuits?pageSize=300${page ? `&pageToken=${encodeURIComponent(page)}` : ''}`;
    const reponse = await fetchFn(url);
    if (!reponse.ok) throw new Error(`Firestore ${reponse.status}`);
    const json = await reponse.json();
    for (const doc of json.documents ?? []) tous.push(normaliser(doc));
    page = json.nextPageToken ?? '';
  } while (page);
  return tous.filter((c) => c.actif && c.titre && c.lienCours).sort(comparer);
}

// ---------- Rendu HTML ----------

const FLECHE =
  '<svg class="icone" viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';

/** Teinte (0..5) stable pour une catégorie : fond de carte sans image. */
export function teinte(categorie) {
  let h = 0;
  for (const ch of String(categorie)) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  return h % 6;
}

function certificat(c) {
  if (!c.certificatDisponible) return '';
  return c.certificatPayant ? 'Certificat payant' : 'Certificat gratuit';
}

function pastilles(c) {
  const items = [c.duree, c.langue, certificat(c)].filter(Boolean);
  return items.map((t) => `<li>${esc(t)}</li>`).join('');
}

export function texteRecherche(c) {
  return `${c.titre} ${c.description} ${c.fournisseur} ${c.categorie}`
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();
}

export function rendreCarte(c, i = 0) {
  const initiale = esc((c.categorie || c.titre).trim().charAt(0).toUpperCase());
  const image = c.lienImage
    ? `<img class="carte__img" src="${esc(c.lienImage)}" alt="" loading="lazy" decoding="async" referrerpolicy="no-referrer">`
    : '';
  return `<article class="carte reveal" style="--i:${i % 6}" data-id="${esc(c.id)}" data-cat="${esc(c.categorie)}" data-niveau="${c.niveauCle}" data-q="${esc(texteRecherche(c))}">
  <a class="carte__lien" href="${esc(urlCours(c))}">
    <div class="carte__media t${teinte(c.categorie)}">
      <span class="carte__initiale" aria-hidden="true">${initiale}</span>
      ${image}
      <span class="badge badge--${c.niveauCle}">${esc(c.niveau)}</span>
      <span class="carte__fournisseur">${esc(c.fournisseur)}</span>
    </div>
    <div class="carte__corps">
      <p class="carte__rubrique">${esc(c.categorie)}</p>
      <h3 class="carte__titre">${esc(c.titre)}</h3>
      <p class="carte__texte">${esc(c.description)}</p>
      <ul class="carte__infos">${pastilles(c)}</ul>
      <span class="carte__cta">Voir le cours ${FLECHE}</span>
    </div>
  </a>
</article>`;
}

export function rendreCartes(liste) {
  return liste.map((c, i) => rendreCarte(c, i)).join('\n');
}

export function categoriesDe(liste) {
  const compte = new Map();
  for (const c of liste) {
    if (c.categorie) compte.set(c.categorie, (compte.get(c.categorie) ?? 0) + 1);
  }
  return [...compte.entries()]
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], 'fr'))
    .map(([nom, n]) => ({ nom, n }));
}

export function rendrePuces(liste) {
  const cats = categoriesDe(liste);
  return [
    `<button class="puce is-actif" type="button" data-cat="">Tous <span>${liste.length}</span></button>`,
    ...cats.map(
      (c) => `<button class="puce" type="button" data-cat="${esc(c.nom)}">${esc(c.nom)} <span>${c.n}</span></button>`,
    ),
  ].join('');
}

export function statistiques(liste) {
  const plateformes = new Set(liste.map((c) => c.fournisseur).filter(Boolean));
  return { cours: liste.length, plateformes: plateformes.size };
}

export function rendreEntete() {
  return `<header class="entete" id="entete">
  <div class="entete__interieur">
    <a class="marque" href="/" aria-label="CoursLibre, accueil">
      <img src="/img/logo-128.webp" width="40" height="40" alt="" class="marque__logo">
      <span class="marque__nom">CoursLibre</span>
    </a>
    <button class="burger" id="burger" type="button" aria-label="Menu" aria-expanded="false" aria-controls="nav">
      <span></span><span></span><span></span>
    </button>
    <nav class="nav" id="nav" aria-label="Navigation principale">
      <a href="/#catalogue">Les cours</a>
      <a href="/#methode">Comment ça marche</a>
      <a href="/#a-propos">À propos</a>
    </nav>
  </div>
</header>`;
}

export function rendrePied(liste, miseAJour) {
  const cats = categoriesDe(liste).slice(0, 6);
  const date = miseAJour
    ? new Date(miseAJour).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })
    : '';
  return `<footer class="pied">
  <div class="pied__interieur">
    <div class="pied__marque">
      <a class="marque marque--clair" href="/">
        <img src="/img/logo-128.webp" width="44" height="44" alt="" class="marque__logo">
        <span class="marque__nom">CoursLibre</span>
      </a>
      <p class="pied__mission">Né d'une idée simple : trier le meilleur du gratuit pour que personne n'ait à chercher des heures avant de commencer à apprendre.</p>
    </div>
    <div class="pied__colonne">
      <h2>Explorer</h2>
      <ul>
        <li><a href="/#catalogue">Tous les cours</a></li>
        ${cats.map((c) => `<li><a href="/?categorie=${encodeURIComponent(c.nom)}#catalogue">${esc(c.nom)}</a></li>`).join('\n        ')}
      </ul>
    </div>
    <div class="pied__colonne" id="a-propos">
      <h2>À propos</h2>
      <p>Chaque cours est choisi et vérifié à la main avant publication. CoursLibre ne produit ni ne vend aucun cours : vous êtes redirigé vers la plateforme d'origine.</p>
      <p>Certains cours proposent un certificat payant. C'est toujours indiqué sur la fiche : apprendre reste gratuit.</p>
    </div>
  </div>
  <div class="pied__bas">
    <p>© ${new Date().getFullYear()} CoursLibre — Créé par Taofic Adébissi.</p>
    ${date ? `<p>Catalogue mis à jour le ${esc(date)}.</p>` : ''}
  </div>
</footer>`;
}

function fiche(libelle, valeur_) {
  return valeur_ ? `<div><dt>${esc(libelle)}</dt><dd>${esc(valeur_)}</dd></div>` : '';
}

/** Contenu principal d'une page de cours (sans en-tête ni pied de page). */
export function rendreCours(c, apparentes = []) {
  const image = c.lienImage
    ? `<img class="fiche__img" src="${esc(c.lienImage)}" alt="" decoding="async" referrerpolicy="no-referrer">`
    : '';
  const paragraphes = (c.descriptionDetaillee || c.description)
    .split(/\n{1,}/)
    .map((p) => p.trim())
    .filter(Boolean)
    .map((p) => `<p>${esc(p)}</p>`)
    .join('\n');
  return `<section class="fiche-hero t${teinte(c.categorie)}">
  <div class="fiche-hero__interieur">
    <nav class="fil" aria-label="Fil d'Ariane"><a href="/">Accueil</a><span>/</span><a href="/?categorie=${encodeURIComponent(c.categorie)}#catalogue">${esc(c.categorie)}</a></nav>
    <p class="fiche__fournisseur">${esc(c.fournisseur)}</p>
    <h1 class="fiche__titre">${esc(c.titre)}</h1>
    <p class="fiche__resume">${esc(c.description)}</p>
    <div class="fiche__badges">
      <span class="badge badge--${c.niveauCle}">${esc(c.niveau)}</span>
      <span class="badge badge--gratuit">Gratuit</span>
      ${certificat(c) ? `<span class="badge badge--neutre">${esc(certificat(c))}</span>` : ''}
    </div>
  </div>
</section>
<div class="fiche">
  <article class="fiche__texte">
    ${image}
    <h2>À propos de ce cours</h2>
    ${paragraphes}
    <h2>Bon à savoir</h2>
    <p>Ce cours est hébergé par <strong>${esc(c.fournisseur)}</strong>. En cliquant sur le bouton, vous quittez CoursLibre pour accéder directement à la plateforme.${c.certificatPayant ? ' Le certificat de fin de cours est payant ; l\'accès au contenu reste gratuit.' : ''}</p>
  </article>
  <aside class="fiche__cote">
    <div class="fiche__carte">
      <p class="fiche__prix">Gratuit</p>
      <a class="bouton bouton--grand" href="${esc(c.lienCours)}" target="_blank" rel="noopener noreferrer">Accéder au cours ${FLECHE}</a>
      <dl class="fiche__infos">
        ${fiche('Plateforme', c.fournisseur)}
        ${fiche('Niveau', c.niveau)}
        ${fiche('Durée', c.duree)}
        ${fiche('Langue', c.langue)}
        ${fiche('Certificat', certificat(c) || 'Non proposé')}
        ${fiche('Catégorie', c.categorie)}
      </dl>
    </div>
  </aside>
</div>
${apparentes.length ? `<section class="section section--etroite"><div class="section__interieur"><h2 class="section__titre">Dans la même catégorie</h2><div class="grille">${rendreCartes(apparentes)}</div></div></section>` : ''}`;
}

export function coursApparentes(c, liste, max = 3) {
  const memes = liste.filter((x) => x.id !== c.id && x.categorie === c.categorie);
  const autres = liste.filter((x) => x.id !== c.id && x.categorie !== c.categorie);
  return [...memes, ...autres].slice(0, max);
}

export function donneesStructurees(c, baseUrl) {
  const url = `${baseUrl}${urlCours(c)}`;
  return {
    '@context': 'https://schema.org',
    '@type': 'Course',
    name: c.titre,
    description: tronquer(c.descriptionDetaillee || c.description, 500),
    url,
    inLanguage: c.langue,
    educationalLevel: c.niveau,
    isAccessibleForFree: true,
    provider: { '@type': 'Organization', name: c.fournisseur },
    offers: { '@type': 'Offer', category: 'Free', price: 0, priceCurrency: 'EUR', url: c.lienCours },
  };
}
