# Application de gestion d'un centre de santé — RDC

Application complète de gestion d'un centre de santé, conçue pour le contexte de la République
démocratique du Congo : registres du système national d'information sanitaire, gestion logistique des
médicaments, gratuité de la maternité, tiers payants, fonctionnement en connexion intermittente.

Le dépôt contient trois ensembles cohérents entre eux :

- une base de données PostgreSQL complète (schéma `cs`, 136 tables, vues de rapportage, déclencheurs
  métier, sécurité au niveau des lignes, fonctions métier appelables par l'API) ;
- une interface web React installable comme application (fonctionnement hors ligne, file de
  synchronisation locale) ;
- la documentation de référence : cahier des charges, plan de tests, matrice de traçabilité,
  correspondance avec DHIS2, spécification de l'interface de programmation.

## Sommaire

- [Contenu du dépôt](#contenu-du-depot)
- [Prérequis](#prerequis)
- [Étape 1 — Initialiser le dépôt et publier sur GitHub](#etape-1--initialiser-le-depot-et-publier-sur-github)
- [Étape 2 — Créer la base sur Supabase](#etape-2--creer-la-base-sur-supabase)
- [Étape 3 — Injecter le jeu de données de démonstration](#etape-3--injecter-le-jeu-de-donnees-de-demonstration)
- [Étape 4 — Exposer le schéma et créer les comptes](#etape-4--exposer-le-schema-et-creer-les-comptes)
- [Étape 5 — Configurer les variables d'environnement](#etape-5--configurer-les-variables-denvironnement)
- [Étape 6 — Lancer, construire et installer l'application](#etape-6--lancer-construire-et-installer-lapplication)
- [Servir l'application sans Node.js](#servir-lapplication-sans-nodejs)
- [Publier sur GitHub Pages](#publier-sur-github-pages)
- [Étape 7 — Mettre en production](#etape-7--mettre-en-production)
- [Vérifier la base sans serveur PostgreSQL](#verifier-la-base-sans-serveur-postgresql)
- [Fonctions métier disponibles](#fonctions-metier-disponibles)
- [Règles de gestion appliquées par la base](#regles-de-gestion-appliquees-par-la-base)
- [Modèle de sécurité](#modele-de-securite)
- [Fonctionnement hors ligne](#fonctionnement-hors-ligne)
- [Comptes de démonstration](#comptes-de-demonstration)
- [Dépannage](#depannage)
- [Sources normatives](#sources-normatives)

## Contenu du dépôt

```
centre-sante-app/
├── README.md                          ce guide
├── .github/workflows/publier-pages.yml  publication automatique sur GitHub Pages
├── package.json                       dépendances et commandes npm
├── vite.config.js                     compilation et configuration application installable
├── tailwind.config.js                 jetons de design (couleurs, typographie, ombres)
├── postcss.config.js
├── index.html
├── .env.example                       modèle de variables d'environnement
├── .gitignore
├── distribution/                      version déjà compilée, servable sans Node.js
├── public/
│   ├── favicon.svg
│   ├── icone-192.png                  icônes de l'application installable
│   └── icone-512.png
├── src/
│   ├── main.jsx                       point d'entrée, fournisseurs de contexte
│   ├── App.jsx                        routes de l'application
│   ├── index.css                      styles de base et composants utilitaires
│   ├── components/
│   │   ├── Layout.jsx                 navigation latérale, barre supérieure, état de liaison
│   │   └── ui.jsx                     cartes, tableaux, étiquettes, indicateurs, jauges
│   ├── context/
│   │   ├── AuthContext.jsx            session, profil applicatif, permissions
│   │   └── OfflineContext.jsx         état de liaison et synchronisation automatique
│   ├── lib/
│   │   ├── supabase.js                client de base de données (schéma cs)
│   │   ├── api.js                     appels aux fonctions métier et écritures différées
│   │   ├── offline.js                 file locale IndexedDB et rejeu idempotent
│   │   ├── format.js                  formats francophones (montants, dates, durées)
│   │   ├── useDonnees.js              chargement avec repli sur le jeu de démonstration
│   │   └── demo.js                    jeu de démonstration de l'interface
│   └── pages/                         15 écrans métier
│       ├── Connexion.jsx  TableauDeBord.jsx  Accueil.jsx  Patients.jsx
│       ├── Consultation.jsx  Laboratoire.jsx  Pharmacie.jsx  Caisse.jsx
│       ├── Maternite.jsx  Pev.jsx  Snis.jsx  Stock.jsx
│       └── Referentiels.jsx  Administration.jsx  Synchronisation.jsx
├── supabase/
│   ├── migrations/
│   │   ├── 20260922120000_extensions_et_types.sql       extensions, 21 types énumérés
│   │   ├── 20260922120100_tables.sql                    136 tables, contraintes, index
│   │   ├── 20260922120200_vues_snis.sql                 6 vues de rapportage
│   │   ├── 20260922120300_declencheurs_metier.sql       4 déclencheurs, journal en ajout seul
│   │   ├── 20260922120400_index_performance.sql         index complémentaires
│   │   ├── 20260922120500_rls_politiques.sql            sécurité au niveau des lignes
│   │   └── 20260922120600_fonctions_rpc.sql             fonctions métier appelables
│   └── seed.sql                       jeu de données de Kamalondo, cas de Sarah Mukendi
├── api/
│   └── openapi.yaml                   spécification de l'interface de programmation
├── docs/
│   ├── 01-cahier-des-charges.md       28 modules, 213 exigences, 12 règles de gestion
│   ├── 02-plan-de-tests.md            cas de test et listes de contrôle
│   ├── 03-matrice-tracabilite.csv     exigence par exigence, cas de test et livrable
│   ├── 04-integration-dhis2.md        interopérabilité et transmission mensuelle
│   ├── 05-correspondance-snis-dhis2.csv
│   └── 06-schema-complet-reference.sql  schéma en un seul fichier, pour lecture
└── scripts/
    ├── demarrer.sh                    démarrage guidé du serveur de développement
    ├── charger_base_locale.sh         chargement sur un PostgreSQL local
    ├── verifier_sql.mjs               exécution des scripts sans serveur installé
    └── exporter_dhis2.mjs             génération du fichier d'import DHIS2
```

## Prérequis

| Outil | Version | Rôle |
| --- | --- | --- |
| Node.js | 18 ou plus récent (testé avec 20) | compilation et exécution du frontend |
| npm | 9 ou plus récent | gestion des dépendances |
| Git | 2.30 ou plus récent | publication du dépôt |
| Compte Supabase | offre gratuite suffisante pour démarrer | base PostgreSQL managée, authentification, interface de programmation |
| Interface en ligne de commande Supabase | 1.180 ou plus récent, facultative | application des migrations depuis le poste |
| `psql` | 14 ou plus récent, facultatif | chargement direct sur une base locale |

Vérification rapide :

```bash
node --version && npm --version && git --version
```

## Étape 1 — Initialiser le dépôt et publier sur GitHub

1. Placez-vous dans le dossier du projet et créez le dépôt local :

```bash
cd centre-sante-app
git init
git add .
git commit -m "Version initiale : base PostgreSQL, interface React, documentation"
```

2. Créez un dépôt vide sur GitHub. Deux possibilités.

Avec l'interface en ligne de commande GitHub, si elle est installée :

```bash
gh repo create centre-sante-app --private --source=. --remote=origin --push
```

Manuellement, depuis la page « New repository » de GitHub, sans cocher l'ajout d'un fichier
`README` ni d'un `.gitignore`, puis :

```bash
git branch -M main
git remote add origin https://github.com/VOTRE-COMPTE/centre-sante-app.git
git push -u origin main
```

3. Si l'authentification par mot de passe est refusée, créez un jeton d'accès personnel sur GitHub
   (Settings, Developer settings, Personal access tokens, portée `repo`) et utilisez-le comme mot de
   passe, ou configurez une clé SSH puis :

```bash
git remote set-url origin git@github.com:VOTRE-COMPTE/centre-sante-app.git
```

4. Points de vigilance avant toute publication :
   - le fichier `.gitignore` exclut déjà `.env`, `.env.local`, `node_modules/` et `dist/` ;
   - ne versionnez jamais la clé `service_role` de Supabase ni un fichier `.env` renseigné ;
   - le jeu de démonstration ne contient aucune donnée réelle de patient, il peut rester dans le dépôt,
     ce qui ne serait pas le cas d'un export de production.

Commandes utiles pour la suite du travail :

```bash
git status
git add -A && git commit -m "Description du changement"
git push
```

## Étape 2 — Créer la base sur Supabase

### Créer le projet

1. Ouvrez [le tableau de bord Supabase](https://supabase.com/dashboard) et créez un projet, par
   exemple `centre-sante-kamalondo`, dans la région la plus proche.
2. Conservez le mot de passe de la base : il sert aux connexions directes par `psql`.
3. Attendez la fin de l'initialisation, environ deux minutes.

### Appliquer les migrations — méthode recommandée, en ligne de commande

```bash
# installation de l'interface en ligne de commande
npm install -g supabase        # ou : brew install supabase/tap/supabase

supabase login
supabase link --project-ref VOTRE_REFERENCE_PROJET   # visible dans l'URL du tableau de bord
supabase db push                                     # applique les 7 migrations dans l'ordre
```

### Déploiement automatique des migrations via l'intégration GitHub

Le dépôt contient un fichier `supabase/config.toml`, nécessaire pour que l'intégration GitHub de
Supabase reconnaisse le dossier `supabase/` et applique les migrations automatiquement à chaque
push. Pour l'activer :

1. Dans le tableau de bord Supabase : **Project Settings > Integrations > GitHub**, connectez le
   dépôt.
2. Si le dossier `supabase/` n'est pas à la racine du dépôt Git (par exemple si le dépôt contient
   un dossier `centre-sante-app/` à sa racine), renseignez ce chemin dans le champ
   **Supabase directory**.
3. Cochez explicitement l'option **Deploy to production** : le simple fait de connecter le dépôt
   ne suffit pas, cette case doit être activée pour que les migrations se déploient sur push.
4. Vérifiez la **branche de production** configurée (généralement `main`) : le déploiement
   automatique ne se déclenche que sur les push vers cette branche précise.
5. Poussez un commit sur cette branche puis consultez l'historique de déploiement de
   l'intégration dans le tableau de bord Supabase : il détaille toute erreur de migration.

Sans `config.toml`, sans l'option « Deploy to production » cochée, ou avec un chemin de dossier
incorrect, le dépôt peut apparaître « lié » sans que les migrations ne soient jamais appliquées.

`supabase db push` applique les fichiers de `supabase/migrations/` par ordre de nom, ce qui
correspond à l'ordre de dépendance :

| Ordre | Fichier | Contenu |
| --- | --- | --- |
| 1 | `20260922120000_extensions_et_types.sql` | extensions `pgcrypto`, `pg_trgm`, `unaccent`, enveloppe indexable d'`unaccent`, 21 types énumérés |
| 2 | `20260922120100_tables.sql` | 136 tables, clés étrangères, contraintes de validation, index principaux |
| 3 | `20260922120200_vues_snis.sql` | consommation moyenne mensuelle, stock disponible utilisable, registre de consultation, agrégats du rapport mensuel, recettes journalières, couverture vaccinale |
| 4 | `20260922120300_declencheurs_metier.sql` | mise à jour du stock, gratuité de la maternité, immuabilité des factures, verrouillage des périodes transmises, journal d'audit en ajout seul |
| 5 | `20260922120400_index_performance.sql` | index de recherche et de rapportage |
| 6 | `20260922120500_rls_politiques.sql` | rattachement des comptes, fonctions de contexte, activation de la sécurité au niveau des lignes, politiques par structure et par permission |
| 7 | `20260922120600_fonctions_rpc.sql` | fonctions métier appelées par l'interface |

### Appliquer les migrations — méthode alternative, éditeur SQL

Dans le tableau de bord, ouvrez « SQL Editor » puis exécutez les sept fichiers **dans l'ordre du
tableau ci-dessus**, un fichier par exécution. Copiez le contenu intégral de chaque fichier ; ne
mélangez pas deux fichiers dans la même exécution, afin que les messages d'erreur restent lisibles.

### Vérifier l'installation

```sql
select count(*) as tables     from pg_tables  where schemaname = 'public';        -- 136
select count(*) as vues       from pg_views   where schemaname = 'public';        -- 6
select count(*) as fonctions  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public';                                                     -- 27
select count(*) as politiques from pg_policies where schemaname = 'public';       -- 236
```

## Étape 3 — Injecter le jeu de données de démonstration

Le fichier `supabase/seed.sql` installe un centre complet et prêt à la formation : Centre de Santé
Kamalondo (code `CS-KAM-001`, zone de santé de Lubumbashi, aire de santé de Kamalondo, population
9 450 habitants), cinq villages, cinq agents, les référentiels de produits, actes, examens, antigènes
et éléments du rapport mensuel, les tarifs par régime, les stocks avec lots et dates de péremption,
ainsi que quatre parcours cliniques complets :

- **MUKENDI Ilunga Sarah**, 3 ans, dossier `2026-0418` : paludisme grave à `Plasmodium falciparum`
  (CIM-10 `B50.0`), hémoglobine à 5,2 g/dl, allergie documentée au cotrimoxazole, mutuelle MUSOSA
  couvrant 80 %, facture `FAC-2026-1142` de 25 200 CDF répartie en 5 040 CDF à la charge de la
  patiente et 20 160 CDF au tiers payant ;
- **KASONGO Mwamba Marie**, G3P2 : consultations prénatales, partogramme, accouchement sous gratuité
  de la maternité ;
- **MBAYO Kalume Daniel**, dossier `2026-0507` : consultation préscolaire et calendrier vaccinal avec
  une dose Penta 2 attendue ;
- **TSHIBANGU Lupembe Paul** : suivi d'hypertension artérielle.

Trois manières de le charger.

Avec l'interface en ligne de commande, sur la base distante :

```bash
psql "$(supabase db url)" -v ON_ERROR_STOP=1 -f supabase/seed.sql
```

Avec l'éditeur SQL du tableau de bord : copiez le contenu de `supabase/seed.sql` puis exécutez.

Sur une base locale de développement :

```bash
PGURL="postgresql://postgres:postgres@localhost:5432/centre_sante" ./scripts/charger_base_locale.sh
```

Contrôle du chargement :

```sql
select numero_dossier, nom, post_nom, prenom from cs.patient order by numero_dossier;
select numero, montant_brut, part_patient, part_tiers from cs.facture;
select code, sdu from cs.v_sdu limit 5;
```

Pour repartir d'une base vierge en développement local : `supabase db reset`, qui rejoue les
migrations puis `seed.sql`.

## Étape 4 — Exposer le schéma et créer les comptes

### Exposer le schéma métier

L'interface de programmation de Supabase n'expose que les schémas déclarés. Dans le tableau de bord,
ouvrez « Project Settings », puis « Data API », et ajoutez `cs` à la liste « Exposed schemas », en
conservant `public`. Sans cette étape, tous les appels renvoient une erreur de schéma introuvable.

### Créer les comptes d'authentification et les rattacher

Chaque ligne de `cs.utilisateur` porte une colonne `auth_user_id` qui la relie à un compte
d'authentification. La procédure, pour chaque agent :

1. dans « Authentication », « Users », créez l'utilisateur avec une adresse de connexion, par exemple
   `m.kabeya@cs-kamalondo.cd`, et un mot de passe provisoire ;
2. copiez l'identifiant technique du compte créé ;
3. rattachez-le au compte applicatif :

```sql
update cs.utilisateur
   set auth_user_id = 'IDENTIFIANT_DU_COMPTE_AUTH'
 where login = 'm.kabeya';
```

Vérification du contexte applicatif, exécutée sous l'identité de l'agent depuis l'application :

```sql
select cs.utilisateur_courant(), cs.structure_courante(), cs.permissions_courantes();
```

Si l'application affiche « Aucun compte applicatif rattaché à cette identité », c'est que l'étape 3
ci-dessus n'a pas été faite pour ce compte.

## Étape 5 — Configurer les variables d'environnement

1. Copiez le modèle :

```bash
cp .env.example .env.local
```

2. Renseignez les valeurs lues dans « Project Settings », « Data API » :

```dotenv
VITE_SUPABASE_URL=https://abcdefghijklmnop.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9....
VITE_SUPABASE_SCHEMA=public
VITE_STRUCTURE_NOM=Centre de Santé Kamalondo
VITE_STRUCTURE_CODE=CS-KAM-001
VITE_DEVISE=CDF
```

| Variable | Obligatoire | Rôle |
| --- | --- | --- |
| `VITE_SUPABASE_URL` | oui | adresse du projet Supabase |
| `VITE_SUPABASE_ANON_KEY` | oui | clé publique, soumise à la sécurité au niveau des lignes |
| `VITE_SUPABASE_SCHEMA` | non, `cs` par défaut | schéma métier exposé |
| `VITE_STRUCTURE_NOM` | non | nom affiché dans l'interface |
| `VITE_STRUCTURE_CODE` | non | code du système national affiché |
| `VITE_DEVISE` | non, `CDF` par défaut | devise d'affichage |
| `VITE_DOMAINE_COMPTES` | non, `cs-kamalondo.cd` par défaut | domaine ajouté à l'identifiant lorsque l'agent saisit `m.kabeya` sans adresse complète |

Trois règles à respecter :

- seules les variables préfixées `VITE_` sont visibles par le navigateur, c'est voulu ;
- la clé `service_role` n'a rien à faire dans un fichier `VITE_`, car elle contourne toute la
  sécurité ; réservez-la aux scripts exécutés sur un serveur, comme `scripts/exporter_dhis2.mjs` ;
- après modification de `.env.local`, arrêtez et relancez le serveur de développement, Vite ne
  recharge pas les variables à chaud.

Sans variables renseignées, l'application démarre en mode découverte et affiche le jeu de
démonstration intégré, ce qui permet la formation des agents avant l'ouverture de la base.

## Étape 6 — Lancer, construire et installer l'application

Le plus simple, sous Linux et macOS :

```bash
./scripts/demarrer.sh
```

Ou, commande par commande :

```bash
npm install          # installation des dépendances
npm run dev          # développement sur http://localhost:5173
npm run build        # construction dans dist/
npm run preview      # vérification du résultat construit sur http://localhost:4173
```

Deux points souvent source d'erreur :

- l'application doit toujours être servie par un serveur web. Ouvrir `index.html` par un double-clic,
  donc en `file://`, provoque une erreur 404 sur `main.jsx` : ce fichier est du code source que Vite
  compile à la volée, il n'est pas lisible tel quel par le navigateur ;
- en production, publiez le contenu du dossier `dist/` et non la racine du projet, pour la même
  raison : `dist/` contient le code déjà compilé.

La navigation utilise des ancres (`/#/accueil`), ce qui permet de servir l'application depuis la
racine d'un domaine, un sous-répertoire d'intranet ou un simple dossier partagé, sans configurer de
réécriture d'URL sur le serveur web.

Installation sur les postes et téléphones : ouvrez l'application dans Chrome ou Edge, puis
« Installer l'application » depuis la barre d'adresse ou le menu. Sur Android, « Ajouter à l'écran
d'accueil ». L'application s'ouvre ensuite en plein écran et démarre sans réseau.

## Servir l'application sans Node.js

Le dossier `distribution/` contient la version déjà compilée : HTML, CSS et JavaScript prêts à
l'emploi. Aucune installation n'est nécessaire, seulement un serveur web.

```bash
cd distribution
python3 -m http.server 8080      # puis ouvrir http://localhost:8080
# ou
npx serve .                      # puis ouvrir l'adresse affichée
```

Pour une publication, copiez le contenu de `distribution/` à la racine du site : Nginx, Apache,
Vercel, Netlify, Cloudflare Pages, GitHub Pages ou un simple partage réseau du centre conviennent.

Deux erreurs fréquentes, et leur explication :

- `Failed to load module script: … MIME type of "text/jsx"` signifie que le serveur web sert les
  fichiers du dossier `src/`, qui sont du code source non compilé. Servez `distribution/`, ou lancez
  le serveur de développement avec `npm run dev` ;
- un double-clic sur `index.html` ouvre la page en `file://`, protocole sous lequel les modules
  JavaScript sont refusés par le navigateur. Passez toujours par une adresse `http://`.

Cette version compilée est construite sans variables d'environnement : elle démarre donc en mode
découverte avec le jeu de démonstration. Pour la relier à votre base, renseignez `.env.local` puis
relancez `npm run build` et remplacez le contenu de `distribution/` par celui de `dist/`.

## Publier sur GitHub Pages

GitHub Pages est un hébergeur de fichiers statiques : il ne compile pas le JSX. Publier la racine du
dépôt aboutit donc à l'erreur `Failed to load module script: … MIME type of "text/jsx"`, puisque le
navigateur reçoit `src/main.jsx` tel quel. Il faut publier le résultat de la compilation.

### Méthode automatique, recommandée

Le dépôt contient déjà le flux `.github/workflows/publier-pages.yml`, qui compile puis publie à
chaque poussée sur `main`.

1. Poussez le projet sur GitHub, flux inclus :

```bash
git add .github/workflows/publier-pages.yml
git commit -m "Publication automatique sur GitHub Pages"
git push
```

2. Dans le dépôt, ouvrez « Settings », « Pages », et choisissez comme source « GitHub Actions ».
3. Facultatif, pour relier la base : dans « Settings », « Secrets and variables », « Actions », onglet
   « Variables », créez `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, et si vous le souhaitez
   `VITE_STRUCTURE_NOM` et `VITE_STRUCTURE_CODE`. Sans ces variables, le site se publie en mode
   découverte avec le jeu de démonstration, ce qui convient pour une présentation.
4. Suivez l'exécution dans l'onglet « Actions ». À la fin, l'adresse publiée est indiquée, sous la
   forme `https://VOTRE-COMPTE.github.io/centre-sante-app/`.

Le flux ajoute automatiquement un fichier `.nojekyll`, sans lequel GitHub Pages ignore certains
fichiers générés.

### Méthode manuelle, sans flux d'intégration

Le dossier `distribution/` contient déjà la version compilée, avec son `.nojekyll`.

```bash
npm run build                          # régénère dist/ si vous avez modifié le code
rm -rf distribution && cp -r dist distribution

git subtree push --prefix distribution origin gh-pages
```

Si `git subtree` échoue parce que la branche existe déjà avec un autre historique :

```bash
git push origin `git subtree split --prefix distribution main`:gh-pages --force
```

Puis, dans « Settings », « Pages », choisissez la source « Deploy from a branch », branche
`gh-pages`, dossier `/ (root)`.

### Pourquoi cela fonctionne dans un sous-répertoire

Deux choix de configuration rendent le site compatible avec l'adresse
`https://compte.github.io/nom-du-depot/` sans réglage supplémentaire :

- la compilation utilise des chemins relatifs, donc aucune ressource n'est cherchée à la racine du
  domaine ;
- la navigation passe par des ancres, par exemple `…/centre-sante-app/#/caisse`, ce qui évite les
  erreurs 404 sur rafraîchissement, GitHub Pages ne sachant pas réécrire les URL.

### Points de vigilance

- La clé publiée est la clé publique `anon`, jamais la clé `service_role` : un site GitHub Pages est
  public, et la protection des données repose sur la sécurité au niveau des lignes de la base.
- Un dépôt public expose aussi le jeu de démonstration, qui ne contient aucune donnée réelle. Pour un
  usage avec de vraies données de patients, utilisez un dépôt privé et un hébergement maîtrisé.
- Après une nouvelle publication, l'application installée peut conserver l'ancienne version en cache
  quelques minutes, le temps que le service worker se mette à jour.

## Étape 7 — Mettre en production

### Hébergement statique

Le dossier `dist/` est entièrement statique. Il se publie sur Vercel, Netlify, Cloudflare Pages,
GitHub Pages ou un simple serveur Nginx du centre.

Avec Vercel :

```bash
npm install -g vercel
vercel                       # première publication
vercel --prod                # mise en production
```

Déclarez les variables `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY` dans les réglages du projet
d'hébergement, puis reconstruisez : elles sont lues au moment de la compilation.

Avec Nginx, sur un serveur du centre :

```nginx
server {
    listen 80;
    server_name centre-sante.local;
    root /var/www/centre-sante/dist;
    index index.html;
    location / { try_files $uri $uri/ /index.html; }
}
```

### Sauvegardes et continuité

- activez les sauvegardes quotidiennes du projet Supabase et vérifiez régulièrement une restauration ;
- exportez chaque mois le rapport transmis, en fichier d'import DHIS2 et en version imprimée ;
- conservez un poste capable de fonctionner hors ligne, la file locale garantissant l'absence de perte
  de saisie pendant une coupure.

## Vérifier la base sans serveur PostgreSQL

Les scripts SQL de ce dépôt ont été exécutés intégralement sur un moteur PostgreSQL avant livraison :
136 tables, 6 vues, 27 fonctions, 236 politiques de sécurité, 4 déclencheurs et le jeu de
démonstration se chargent sans erreur. Vous pouvez reproduire ce contrôle sans installer de serveur :

```bash
npm install --no-save @electric-sql/pglite
node scripts/verifier_sql.mjs
```

Le script instancie un PostgreSQL embarqué, crée les doublures des objets fournis par Supabase
(`auth.uid()`, rôles `authenticated`, `anon`, `service_role`), applique les migrations puis le jeu de
données, et affiche les décomptes. C'est le contrôle à intégrer dans une chaîne d'intégration
continue avant chaque publication.

## Fonctions métier disponibles

Toute la logique sensible est implantée dans la base et appelée par `supabase.rpc(...)`, de sorte
qu'aucun client ne peut la contourner.

| Fonction | Objet |
| --- | --- |
| `cs.rechercher_patient(q, limite)` | recherche tolérante aux fautes et insensible aux accents, sur le nom, le numéro de dossier et le téléphone |
| `cs.doublons_probables(nom, post_nom, prenom, sexe, naissance, village)` | détection de doublons avant création d'un dossier |
| `cs.calculer_cas(patient, date)` | nouveau cas ou ancien cas sur une fenêtre de 14 jours |
| `cs.enregistrer_venue(patient, type, motif, priorité, service, cas, référé_par)` | ouverture d'une venue avec numéro et jeton, régime applicable détecté |
| `cs.file_attente(service)` | file du jour triée par priorité puis par jeton, avec durée d'attente |
| `cs.proposer_lots_fefo(produit, dépôt, quantité)` | lots à servir, du plus proche de la péremption au plus éloigné |
| `cs.dispenser(venue, dépôt, lignes)` | dispensation complète : contrôle de prescription, respect de la règle du premier périmé premier sorti, mouvements de stock |
| `cs.donnees_essentielles_sigl(période)` | stock disponible utilisable, consommation, pertes, jours de rupture, consommation moyenne mensuelle, stock de sécurité, stock maximum, quantité à commander, mois de stock |
| `cs.generer_facture(venue)` | facture consolidée : actes, examens, médicaments, éclatement entre patient et tiers payant |
| `cs.encaisser(facture, session, mode, devise, montant, référence)` | encaissement, numéro de reçu, conversion au taux du jour, mise à jour du statut de la facture |
| `cs.cloturer_session_caisse(session, comptant CDF, comptant USD, justification)` | clôture avec calcul de l'écart et justification obligatoire |
| `cs.calendrier_vaccinal(patient)` | doses reçues, dues, en retard et programmées |
| `cs.generer_rapport_snis(période, type)` | calcul du rapport mensuel depuis les registres, versionnement d'un rectificatif si la période est transmise |
| `cs.controles_coherence(rapport)` | contrôles bloquants et avertissements avant transmission |
| `cs.transmettre_rapport(rapport, canal)` | transmission refusée tant qu'un contrôle bloquant subsiste |
| `cs.tableau_de_bord()` | indicateurs du jour et du mois, en un seul appel |
| `cs.journaliser(action, entité, identifiant, patient, justification, poste)` | écriture dans le journal d'audit |

Exemple d'appel depuis l'interface :

```js
import { api } from './lib/api.js'

const file = await api.fileAttente()
const venue = await api.enregistrerVenue({
  p_patient: patientId,
  p_type: 'CURATIF',
  p_motif: 'Fièvre depuis trois jours',
  p_priorite: 'URGENCE'
})
```

## Règles de gestion appliquées par la base

Ces règles sont vérifiées par des contraintes, des déclencheurs ou des fonctions, donc valables quel
que soit le client utilisé.

| Règle | Énoncé | Mécanisme |
| --- | --- | --- |
| RG-02 | un retour dans les 14 jours pour le même épisode est un ancien cas | `cs.calculer_cas` |
| RG-03 | aucune dispensation sans prescription valide | `cs.dispenser` |
| RG-04 | un solde de stock ne devient jamais négatif | déclencheur de mise à jour du stock et contrainte de validation |
| RG-05 | le lot le plus proche de la péremption est servi en premier, sauf dérogation motivée | `cs.proposer_lots_fefo` et `cs.dispenser` |
| RG-06 | aucune somme n'est réclamée à une patiente sous gratuité de la maternité | déclencheur de gratuité |
| RG-07 | une facture validée n'est jamais modifiée, elle est annulée puis refaite | déclencheur d'immuabilité |
| RG-08 | une session de caisse ne se clôture pas sur un écart non justifié | `cs.cloturer_session_caisse` |
| RG-11 | une période transmise est figée, la correction passe par un rapport rectificatif versionné | déclencheur de période close et `cs.generer_rapport_snis` |
| RG-12 | le journal d'audit est en ajout seul | règles bloquant la modification et la suppression |

## Modèle de sécurité

- Sécurité au niveau des lignes activée sur toutes les tables du schéma `cs`, avec pour principe le
  cloisonnement par structure : un agent ne voit que les données de son centre.
- Politiques d'écriture adossées à des permissions nommées, lues par `cs.a_permission(code)` :
  `PATIENT_ECRIRE`, `CONSULTATION_ECRIRE`, `PHARMACIE_DISPENSER`, `CAISSE_ENCAISSER`,
  `RAPPORT_VALIDER`, `REFERENTIEL_ECRIRE`, `AUDIT_LIRE`, entre autres.
- Aucune politique de suppression : les données de soins ne sont pas effaçables, elles sont marquées
  supprimées logiquement, conformément aux exigences de conservation.
- Données sensibles protégées par des politiques restrictives supplémentaires, exigeant la permission
  `DOSSIER_SENSIBLE_LIRE` : consultations marquées sensibles, suivi de la prévention de la
  transmission mère-enfant, inclusion et suivi dans les programmes verticaux, dépistage des contacts.
- Accès du rôle anonyme révoqué ; les fonctions métier sont exécutables par les comptes authentifiés,
  avec le contexte de l'agent pour déterminer la structure et les permissions.
- Journal d'audit en ajout seul, avec traçabilité de l'accès en bris de glace.

## Fonctionnement hors ligne

1. L'application est installable et sa coque est mise en cache, elle démarre donc sans réseau.
2. Les référentiels consultés sont servis depuis le cache lorsque la liaison est absente.
3. Chaque écriture tentée sans réseau part dans une file locale IndexedDB, avec un identifiant unique
   généré sur le poste.
4. Au retour de la connexion, ainsi que toutes les deux minutes, la file est rejouée. L'identifiant
   unique rend le rejeu sans effet de bord : une opération déjà transmise n'est pas dupliquée.
5. L'écran « Synchronisation » affiche l'état de la liaison, les opérations en attente, les échecs et
   la date du dernier échange, et permet un rejeu manuel.

## Comptes de démonstration

Ces identifiants existent dans `cs.utilisateur` après chargement du jeu de données. Leurs mots de
passe doivent être créés dans « Authentication », puis rattachés comme décrit à l'étape 4.

| Identifiant | Agent | Fonction | Périmètre |
| --- | --- | --- | --- |
| `m.kabeya` | KABEYA Ilunga Michel | infirmier titulaire | ensemble du centre, validation du rapport mensuel |
| `b.nsenga` | NSENGA Bwalya Béatrice | sage-femme | maternité, consultations prénatales, accouchements |
| `p.kazadi` | KAZADI Pierre | laborantin | laboratoire, validation des résultats |
| `t.mbuyi` | MBUYI Tshibola Thérèse | pharmacien | pharmacie, stocks, rapport logistique |
| `a.caissier` | AMISI Kalonda André | caissier | caisse, encaissements, clôture de session |

Note sur le jeu de démonstration : le mois de septembre 2026 comporte volontairement une incohérence
entre consultations prénatales de rang 1 et de rang 4, afin que le contrôle de cohérence `CTL-006`
apparaisse en avertissement pendant la formation.

## Dépannage

| Symptôme | Cause probable | Correction |
| --- | --- | --- |
| `Failed to load module script: … MIME type of "text/jsx"` | un serveur statique, GitHub Pages compris, sert le dossier des sources au lieu de la version compilée | sur GitHub Pages, réglez la source sur « GitHub Actions » pour utiliser le flux fourni, ou publiez la branche `gh-pages` depuis `distribution/` ; en local, lancez `npm run dev` |
| Page blanche sur GitHub Pages, ressources en 404 | publication de la racine du dépôt, ou absence de `.nojekyll` | publiez `dist/` ou `distribution/`, qui contiennent déjà `.nojekyll` |
| `main.jsx` : 404 dans la console du navigateur | le fichier `index.html` a été ouvert sans serveur de développement, ou les sources ont été publiées telles quelles sur un hébergeur statique | en développement : `npm install` puis `npm run dev`, et ouvrez l'adresse affichée par Vite, jamais le fichier `index.html` directement ; en production : publiez le contenu de `dist/` produit par `npm run build`, jamais la racine du projet |
| `vite: command not found` ou `Cannot find module` | dépendances non installées | `npm install` à la racine du projet, là où se trouve `package.json` |
| `Failed to resolve import` au lancement | commande exécutée depuis le mauvais dossier | placez-vous dans `centre-sante-app/`, vérifiez par `ls package.json src/main.jsx` |
| `The schema must be one of the following: public` | schéma `cs` non exposé | ajoutez `cs` dans « Data API », « Exposed schemas » |
| `permission denied for schema public` | droits non appliqués | rejouez `20260922120500_rls_politiques.sql`, qui contient les autorisations |
| Toutes les listes sont vides alors que la base contient des données | compte non rattaché, donc structure inconnue | renseignez `auth_user_id` dans `cs.utilisateur`, puis vérifiez avec `select cs.structure_courante()` |
| « Aucun compte applicatif rattaché à cette identité » | rattachement manquant pour ce compte | même correction que ci-dessus |
| `functions in index expression must be marked IMMUTABLE` | migration 1 non appliquée avant la migration 2 | appliquez les fichiers dans l'ordre : l'enveloppe indexable `cs.unaccent_i` est créée en premier |
| `RG-05 : lot non conforme au FEFO` | lot choisi manuellement alors qu'un lot périme plus tôt | servez le lot proposé, ou transmettez `derogation_fefo` et `motif_derogation` |
| `RG-08 : écart de caisse` | clôture avec un écart sans justification | saisissez la justification de l'écart |
| `RG-11 : période déjà transmise` | saisie rétroactive dans un mois transmis | passez par un rapport rectificatif, généré automatiquement en nouvelle version |
| L'interface reste en mode découverte | variables absentes ou serveur non relancé | vérifiez `.env.local` puis relancez `npm run dev` |
| Page blanche après publication | chemins absolus attendus par l'hébergeur | la configuration utilise déjà des chemins relatifs et une navigation par ancre ; videz le cache du navigateur et le cache de l'application installée |

## Sources normatives

Les règles métier, les registres et les indicateurs reprennent les documents officiels suivants.

- [Recueil des normes de création, d'organisation et de fonctionnement des structures de la zone de santé, ministère de la Santé publique, 2019](https://bv-assk.org/wp-content/uploads/2024/03/Recueil-des-normes-de-creation-dorganisation-de-fonctionnement-des-structures-de-la-ZS-en-RDC-MSP-2019.pdf)
- [Arrêté ministériel du 15 septembre 2017 portant standardisation des outils minimum de gestion](https://www.droitcongolais.info/files/810.09.17.2-Arrete-du-15-septembre-2017_outils-de-standardisartion.pdf)
- [Canevas du rapport mensuel des centres de santé, système national d'information sanitaire](https://bv-assk.org/wp-content/uploads/2024/03/Canevas-SNIS-CS-AVEC-VPI2-ET-VAR-2-OK.pdf)
- [Canevas mensuel du bureau central de la zone de santé](https://bv-assk.org/wp-content/uploads/2024/02/2021-05-30-Canevas-mensuel-BCZ-Vfini-2.pdf)
- [Manuel descriptif du système d'information en gestion logistique, ASRAMES, mai 2020](https://asrames.org/wp-content/uploads/2020/06/Manuel-Descriptif-du-SIGL-version-Mai-2020.pdf)
- [Manuel de procédures de remplissage des outils de gestion du système national d'information sanitaire de routine](https://malariaportal.org/sites/default/files/2023-11/DRC-511.1_%20Manuel%20de%20Procedures%20de%20Remplissage%20des%20outils%20de%20Gestion%20du%20SNIS%20de%20Routine_%20Registres%20et%20Canevas%20de%20Rapport%20Mensuel%20D%E2%80%99Activites_%202016%20(Part%201_3).pdf)
- [Manuel opérationnel du financement basé sur la performance, projet de développement du système de santé](https://santenews.info/wp-content/uploads/2020/04/Manuel_PBF_PDSS_FINANCEMENT.pdf)
- [Manuel des outils de gestion logistique, Organisation mondiale de la santé, bureau régional Afrique](https://files.aho.afro.who.int/afahobckpcontainer/production/files/Manuel_des_Outils_de_Gestion_Logistique.pdf)
- [Programme de la gratuité de la maternité et des soins du nouveau-né, ministère de la Santé publique](https://sante.gouv.cd/actualites/revue-annuelle-du-programme-de-la-gratuite-de-la-maternite-et-des-soins-du-nouveau-ne)
- [Code du numérique de la République démocratique du Congo, livre III, protection des données à caractère personnel](https://www.anove.ai/fr/regulations/drc-digital-code-book-iii)
- [Système d'information en gestion logistique, plateforme nationale](https://sigl.infomedrdc.org/)
- [Documentation de Supabase, sécurité au niveau des lignes](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Documentation de Vite, variables d'environnement](https://vite.dev/guide/env-and-mode)

## Licence et usage

Ce dépôt est un socle de mise en œuvre. Avant tout usage sur des données réelles de patients,
prévoyez une revue de conformité au Code du numérique, la signature d'engagements de confidentialité
par les agents, et une politique de sauvegarde vérifiée par restauration.
