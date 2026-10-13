import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  chargerCours, estExpire, lienSur, rendreCarte, rendreCours, slugDe, slugify, normaliser,
} from '../site/shared.mjs';

const champ = (valeurs) =>
  Object.fromEntries(
    Object.entries(valeurs).map(([k, v]) => [
      k,
      typeof v === 'boolean' ? { booleanValue: v } : typeof v === 'number' ? { integerValue: String(v) } : v === null ? { nullValue: null } : v instanceof Date ? { timestampValue: v.toISOString() } : { stringValue: v },
    ]),
  );

const doc = (id, valeurs) => ({ name: `projects/p/databases/(default)/documents/cours_gratuits/${id}`, fields: champ(valeurs) });

const base = { titre: 'Cours', description: 'd', descriptionDetaillee: 'dd', fournisseur: 'F', niveau: 'Débutant', langue: 'Français', categorie: 'Cat', lienCours: 'https://exemple.org/c', actif: true, certificatDisponible: false };

test('slugify retire accents, ponctuation et limite la longueur', () => {
  assert.equal(slugify("L'IA pour les professionnels !"), 'l-ia-pour-les-professionnels');
  assert.equal(slugify('Développeurs & Cie'), 'developpeurs-et-cie');
  assert.ok(slugify('a'.repeat(200)).length <= 70);
});

test('slugDe est stable et contient le début de l\'identifiant', () => {
  assert.equal(slugDe({ id: 'AbCdEfGhIj', titre: 'Mon cours' }), 'mon-cours-abcdef');
});

test('lienSur n\'accepte que https', () => {
  assert.equal(lienSur('https://a.b/c'), 'https://a.b/c');
  assert.equal(lienSur('javascript:alert(1)'), '');
  assert.equal(lienSur('http://a.b'), '');
  assert.equal(lienSur('data:text/html,<b>'), '');
  assert.equal(lienSur(null), '');
});

test('estExpire : sans date jamais, passé oui, futur non', () => {
  const maintenant = new Date('2026-06-15T12:00:00Z').getTime();
  assert.equal(estExpire({ dateFin: '' }, maintenant), false);
  assert.equal(estExpire({ dateFin: '2026-06-14T23:59:59Z' }, maintenant), true);
  assert.equal(estExpire({ dateFin: '2026-06-15T23:59:59Z' }, maintenant), false);
});

test('chargerCours masque expirés, inactifs et liens invalides ; respecte l\'ordre', async () => {
  const futur = new Date(Date.now() + 86400000 * 30);
  const passe = new Date(Date.now() - 86400000);
  const reponse = {
    documents: [
      doc('a1', { ...base, titre: 'Actif sans fin' }),
      doc('b2', { ...base, titre: 'Fin future', dateFin: futur }),
      doc('c3', { ...base, titre: 'Expire hier', dateFin: passe }),
      doc('d4', { ...base, titre: 'Masque', actif: false }),
      doc('e5', { ...base, titre: 'Lien dangereux', lienCours: 'javascript:alert(1)' }),
      doc('f6', { ...base, titre: 'Premier', ordreAffichage: 1 }),
    ],
  };
  const liste = await chargerCours(async () => ({ ok: true, json: async () => reponse }));
  assert.deepEqual(liste.map((c) => c.titre), ['Premier', 'Actif sans fin', 'Fin future']);
});

test('chargerCours suit la pagination', async () => {
  const pages = [
    { documents: [doc('a1', { ...base, titre: 'P1' })], nextPageToken: 'suite' },
    { documents: [doc('b2', { ...base, titre: 'P2' })] },
  ];
  let appel = 0;
  const liste = await chargerCours(async (url) => {
    if (appel === 1) assert.match(url, /pageToken=suite/);
    return { ok: true, json: async () => pages[appel++] };
  });
  assert.equal(liste.length, 2);
});

test('le rendu échappe le HTML des titres et descriptions (pas d\'injection)', () => {
  const c = normaliser(doc('x1', { ...base, titre: '<img src=x onerror=alert(1)>', description: '"><script>alert(1)</script>' }));
  const html = rendreCarte(c) + rendreCours(c);
  assert.ok(!html.includes('<script>alert'));
  assert.ok(!html.includes('<img src=x'));
  assert.ok(html.includes('&lt;img src=x onerror=alert(1)&gt;'));
});

test('la carte et la fiche portent la date de fin', () => {
  const c = normaliser(doc('x2', { ...base, dateFin: new Date('2030-03-05T22:59:59Z') }));
  assert.match(rendreCarte(c), /data-fin="2030-03-05T22:59:59.000Z"/);
  assert.match(rendreCours(c), /Disponible jusqu/);
});
