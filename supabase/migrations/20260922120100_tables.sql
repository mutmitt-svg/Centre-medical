-- Généré depuis schema_centre_sante.sql v1.0 — ne pas éditer à la main sans mettre à jour la source.
SET search_path TO public;

-- ---------------------------------------------------------------------
-- 1. M01 — ORGANISATION, RÉFÉRENTIELS, PARAMÉTRAGE
-- ---------------------------------------------------------------------
CREATE TABLE province (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code          text UNIQUE NOT NULL,
    nom           text NOT NULL
);

CREATE TABLE zone_sante (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    province_id   uuid NOT NULL REFERENCES province(id),
    code          text UNIQUE NOT NULL,
    nom           text NOT NULL,
    code_dhis2    text                                     -- organisation unit uid
);

CREATE TABLE aire_sante (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_sante_id uuid NOT NULL REFERENCES zone_sante(id),
    code          text UNIQUE NOT NULL,
    nom           text NOT NULL,
    code_dhis2    text
);

CREATE TABLE structure (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aire_sante_id   uuid REFERENCES aire_sante(id),
    code_snis       text UNIQUE NOT NULL,
    code_dhis2      text,
    nom             text NOT NULL,
    type            type_structure_t NOT NULL DEFAULT 'CENTRE_SANTE',
    statut_juridique text,                                 -- public, privé, confessionnel, intégré
    telephone       text,
    adresse         text,
    latitude        numeric(9,6),
    longitude       numeric(9,6),
    rayon_action_km numeric(5,2),
    devise_principale devise_t NOT NULL DEFAULT 'CDF',
    actif           boolean NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- Population de responsabilité : dénominateur des taux de couverture (EF-M01-01)
CREATE TABLE population_annuelle (
    structure_id  uuid NOT NULL REFERENCES structure(id),
    annee         smallint NOT NULL,
    population_totale     integer NOT NULL,
    enfants_0_11_mois     integer,
    enfants_0_59_mois     integer,
    femmes_enceintes_attendues integer,
    femmes_age_procreer   integer,
    PRIMARY KEY (structure_id, annee)
);

CREATE TABLE village (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aire_sante_id uuid NOT NULL REFERENCES aire_sante(id),
    nom           text NOT NULL,
    population    integer,
    distance_km   numeric(5,2)
);

CREATE TABLE service (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    code          text NOT NULL,                           -- RECEPTION, CONSULT, SOINS, MATERNITE, OBSERVATION, LABO, PHARMACIE, LOGISTIQUE
    nom           text NOT NULL,
    nb_lits       smallint DEFAULT 0,
    actif         boolean NOT NULL DEFAULT true,
    UNIQUE (structure_id, code)
);

CREATE TABLE lit (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id    uuid NOT NULL REFERENCES service(id),
    code          text NOT NULL,
    type          text,                                    -- travail, observation, post-partum
    hors_service  boolean NOT NULL DEFAULT false,
    UNIQUE (service_id, code)
);

-- Terminologies (M01, R8)
CREATE TABLE diagnostic_ref (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code_cim10    text UNIQUE NOT NULL,
    libelle       text NOT NULL,
    libelle_local text,
    chapitre      text,
    notifiable    boolean NOT NULL DEFAULT false,          -- maladie à notification obligatoire
    rubrique_snis text,                                    -- rattachement au canevas
    actif         boolean NOT NULL DEFAULT true
);

CREATE TABLE examen_ref (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code           text UNIQUE NOT NULL,
    code_loinc     text,
    libelle        text NOT NULL,
    type_resultat  text NOT NULL,                          -- NUMERIQUE, QUALITATIF, TEXTE
    unite          text,
    valeur_min     numeric(12,4),
    valeur_max     numeric(12,4),
    seuil_critique_bas  numeric(12,4),
    seuil_critique_haut numeric(12,4),
    options_qualitatives text[],                           -- {POSITIF, NEGATIF, TRACES}
    rubrique_snis  text,
    actif          boolean NOT NULL DEFAULT true
);

CREATE TABLE produit (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code            text UNIQUE NOT NULL,
    dci             text NOT NULL,                         -- désignation en DCI obligatoire (R4)
    nom_commercial  text,
    forme           text,                                  -- comprimé, sirop, injectable
    dosage          text,
    conditionnement text,
    classe_therapeutique text,
    liste_nationale_me boolean NOT NULL DEFAULT false,
    traceur         boolean NOT NULL DEFAULT false,        -- produit traceur (suivi ruptures)
    chaine_froid    boolean NOT NULL DEFAULT false,
    intrant_pev     boolean NOT NULL DEFAULT false,
    reactif_labo    boolean NOT NULL DEFAULT false,
    contraceptif    boolean NOT NULL DEFAULT false,
    unite_sortie    text NOT NULL DEFAULT 'unite',
    mois_stock_max  numeric(4,2) DEFAULT 3.0,              -- paramètres de réapprovisionnement
    mois_stock_securite numeric(4,2) DEFAULT 1.0,
    actif           boolean NOT NULL DEFAULT true
);

CREATE TABLE acte (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code          text UNIQUE NOT NULL,
    libelle       text NOT NULL,
    service_code  text,
    unite         text DEFAULT 'acte',
    forfaitaire   boolean NOT NULL DEFAULT false,          -- tarif forfaitaire par épisode
    indicateur_fbp boolean NOT NULL DEFAULT false,
    rubrique_snis text,
    actif         boolean NOT NULL DEFAULT true
);

-- Grille tarifaire versionnée (EF-M01-07, EF-M01-11)
CREATE TABLE tarif (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    acte_id       uuid REFERENCES acte(id),
    produit_id    uuid REFERENCES produit(id),
    examen_id     uuid REFERENCES examen_ref(id),
    type_regime   type_regime_t NOT NULL DEFAULT 'PAYANT',
    montant       numeric(14,2) NOT NULL,
    devise        devise_t NOT NULL DEFAULT 'CDF',
    date_debut    date NOT NULL,
    date_fin      date,
    CHECK (num_nonnulls(acte_id, produit_id, examen_id) = 1),
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);
CREATE INDEX idx_tarif_lookup ON tarif(structure_id, type_regime, date_debut);

CREATE TABLE taux_change (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    date_jour    date NOT NULL,
    devise_source devise_t NOT NULL,
    devise_cible  devise_t NOT NULL,
    taux          numeric(16,6) NOT NULL,
    UNIQUE (date_jour, devise_source, devise_cible)
);

-- Ordinogrammes / protocoles paramétrables (EF-M01-12)
CREATE TABLE protocole (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code          text UNIQUE NOT NULL,
    libelle       text NOT NULL,
    domaine       text,                                    -- PALUDISME, IRA, DIARRHEE, PCIME, IST
    version       text NOT NULL,
    contenu       jsonb NOT NULL,                          -- arbre de décision
    date_debut    date NOT NULL,
    date_fin      date,
    actif         boolean NOT NULL DEFAULT true
);

-- ---------------------------------------------------------------------
-- 2. M25 — UTILISATEURS, RÔLES, AUDIT
-- ---------------------------------------------------------------------
CREATE TABLE agent (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    matricule       text,
    nom             text NOT NULL,
    post_nom        text,
    prenom          text,
    sexe            sexe_t,
    date_naissance  date,
    qualification   qualification_t NOT NULL,
    fonction        text,                                  -- infirmier titulaire, caissier...
    statut          text,                                  -- fonctionnaire, contractuel, bénévole
    date_entree     date,
    date_sortie     date,
    telephone       text,
    numero_ordre    text,
    actif           boolean NOT NULL DEFAULT true,
    UNIQUE (structure_id, matricule)
);

CREATE TABLE utilisateur (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id        uuid REFERENCES agent(id),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    login           text UNIQUE NOT NULL,
    mot_de_passe_hash text NOT NULL,
    pin_hash        text,
    doit_changer_mdp boolean NOT NULL DEFAULT true,
    echecs_consecutifs smallint NOT NULL DEFAULT 0,
    verrouille_jusqu_a timestamptz,
    derniere_connexion timestamptz,
    actif           boolean NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE role (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code        text UNIQUE NOT NULL,                      -- IT, INFIRMIER, SAGE_FEMME, LABO, PHARMACIE, CAISSE, COMPTA, RH, ADMIN, SUPERVISEUR_ECZS
    libelle     text NOT NULL
);

CREATE TABLE permission (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code        text UNIQUE NOT NULL,                      -- ex: CONSULTATION_CREER, CAISSE_CLOTURER, DOSSIER_SENSIBLE_LIRE
    module      text NOT NULL,
    libelle     text NOT NULL
);

CREATE TABLE role_permission (
    role_id       uuid NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES permission(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE utilisateur_role (
    utilisateur_id uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
    role_id        uuid NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY (utilisateur_id, role_id)
);

-- Journal d'audit inaltérable (EF-M25-03) : aucun UPDATE/DELETE autorisé
CREATE TABLE journal_audit (
    id             bigserial PRIMARY KEY,
    structure_id   uuid,
    utilisateur_id uuid,
    action         action_audit_t NOT NULL,
    entite         text NOT NULL,
    entite_id      uuid,
    patient_id     uuid,
    justification  text,                                   -- obligatoire pour dossier sensible
    valeur_avant   jsonb,
    valeur_apres   jsonb,
    adresse_ip     text,
    poste          text,
    horodatage     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_patient ON journal_audit(patient_id, horodatage DESC);
CREATE INDEX idx_audit_user ON journal_audit(utilisateur_id, horodatage DESC);

-- ---------------------------------------------------------------------
-- 3. M02 — PATIENT, MÉNAGE, RÉGIMES
-- ---------------------------------------------------------------------
CREATE TABLE menage (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    code          text,
    chef_nom      text,
    village_id    uuid REFERENCES village(id),
    adresse       text,
    nb_membres    smallint,
    indigent      boolean NOT NULL DEFAULT false
);

CREATE TABLE patient (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id      uuid NOT NULL REFERENCES structure(id),
    numero_dossier    text NOT NULL,                       -- imprimé sur la carte + QR
    nom               text NOT NULL,
    post_nom          text,
    prenom            text,
    sexe              sexe_t NOT NULL,
    date_naissance    date,
    age_declare_annees smallint,                           -- si date inconnue (EF-M02-03)
    age_estime        boolean NOT NULL DEFAULT false,
    etat_civil        text,
    profession        text,
    telephone         text,
    telephone_secondaire text,
    village_id        uuid REFERENCES village(id),
    adresse           text,
    menage_id         uuid REFERENCES menage(id),
    mere_id           uuid REFERENCES patient(id),         -- lien mère-enfant (CPS, PEV, PTME)
    pere_id           uuid REFERENCES patient(id),
    personne_contact  text,
    telephone_contact text,
    provenance        provenance_t DEFAULT 'AIRE_SANTE',
    groupe_sanguin    text,
    consentement_donnees boolean NOT NULL DEFAULT false,   -- Code du numérique (R6)
    consentement_sms  boolean NOT NULL DEFAULT false,
    date_consentement date,
    decede            boolean NOT NULL DEFAULT false,
    date_deces        date,
    fusionne_vers_id  uuid REFERENCES patient(id),         -- traçabilité de fusion (EF-M02-05)
    created_by        uuid REFERENCES utilisateur(id),
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz,
    deleted_at        timestamptz,
    UNIQUE (structure_id, numero_dossier)
);
CREATE INDEX idx_patient_nom_trgm ON patient USING gin ((public.unaccent_i(nom || ' ' || coalesce(post_nom,'') || ' ' || coalesce(prenom,''))) gin_trgm_ops);
CREATE INDEX idx_patient_tel ON patient(telephone);
CREATE INDEX idx_patient_mere ON patient(mere_id);

CREATE TABLE alerte_clinique (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  uuid NOT NULL REFERENCES patient(id),
    type        text NOT NULL,                             -- ALLERGIE, CHRONIQUE, TRAITEMENT_LONG_COURS, GROSSESSE
    libelle     text NOT NULL,
    gravite     text,
    active      boolean NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tiers_payant (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id       uuid NOT NULL REFERENCES structure(id),
    code               text NOT NULL,
    nom                text NOT NULL,
    type               type_regime_t NOT NULL,
    taux_prise_charge  numeric(5,2) NOT NULL DEFAULT 100,  -- %
    ticket_moderateur  numeric(5,2) DEFAULT 0,
    plafond_par_episode numeric(14,2),
    plafond_annuel     numeric(14,2),
    exclusions         text,
    delai_facturation_jours smallint,
    contact            text,
    convention_debut   date,
    convention_fin     date,
    actif              boolean NOT NULL DEFAULT true,
    UNIQUE (structure_id, code)
);

CREATE TABLE patient_regime (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id       uuid NOT NULL REFERENCES patient(id),
    type_regime      type_regime_t NOT NULL,
    tiers_payant_id  uuid REFERENCES tiers_payant(id),
    numero_affiliation text,
    qualite          text,                                 -- titulaire, ayant droit
    piece_justificative text,
    date_debut       date NOT NULL,
    date_fin         date,
    valide_par       uuid REFERENCES utilisateur(id),
    actif            boolean NOT NULL DEFAULT true
);
CREATE INDEX idx_patient_regime ON patient_regime(patient_id, actif);

-- ---------------------------------------------------------------------
-- 4. M03 — VENUE, FILE D'ATTENTE, TRIAGE
-- ---------------------------------------------------------------------
CREATE TABLE venue (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id      uuid NOT NULL REFERENCES structure(id),
    patient_id        uuid NOT NULL REFERENCES patient(id),
    numero_venue      text NOT NULL,                       -- numéro d'ordre du registre des malades
    numero_jeton      smallint,
    date_heure_arrivee timestamptz NOT NULL DEFAULT now(),
    type_venue        type_venue_t NOT NULL,
    cas               cas_t,                               -- nouveau / ancien cas (RG-02)
    priorite          priorite_t NOT NULL DEFAULT 'ROUTINE',
    refere_par        text,                                -- RECO, autre FOSA, communauté
    motif             text,
    service_orientation_id uuid REFERENCES service(id),
    statut            statut_venue_t NOT NULL DEFAULT 'ATTENTE',
    regime_applique_id uuid REFERENCES patient_regime(id),
    date_heure_cloture timestamptz,
    issue             issue_sortie_t,
    accueil_par       uuid REFERENCES utilisateur(id),
    created_at        timestamptz NOT NULL DEFAULT now(),
    deleted_at        timestamptz,
    UNIQUE (structure_id, numero_venue)
);
CREATE INDEX idx_venue_patient ON venue(patient_id, date_heure_arrivee DESC);
CREATE INDEX idx_venue_file ON venue(structure_id, statut, date_heure_arrivee);

CREATE TABLE triage (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id        uuid NOT NULL REFERENCES venue(id),
    poids_kg        numeric(6,2),
    taille_cm       numeric(6,2),
    perimetre_brachial_mm numeric(6,1),
    temperature_c   numeric(4,1),
    tension_systolique  smallint,
    tension_diastolique smallint,
    pouls           smallint,
    freq_respiratoire smallint,
    spo2            smallint,
    imc             numeric(6,2),                          -- calculé
    z_score_pt      numeric(6,2),                          -- poids/taille
    z_score_pa      numeric(6,2),                          -- poids/âge
    z_score_ta      numeric(6,2),                          -- taille/âge
    oedemes         boolean,
    signes_danger   text[],                                -- signes PCIME
    observation     text,
    mesure_par      uuid REFERENCES utilisateur(id),
    horodatage      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE etape_file (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id      uuid NOT NULL REFERENCES venue(id),
    service_id    uuid NOT NULL REFERENCES service(id),
    entree        timestamptz NOT NULL DEFAULT now(),
    prise_en_charge timestamptz,
    sortie        timestamptz
);

-- ---------------------------------------------------------------------
-- 5. M04/M05 — CONSULTATION, DIAGNOSTICS, ACTES, PRESCRIPTIONS
-- ---------------------------------------------------------------------
CREATE TABLE consultation (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id          uuid NOT NULL REFERENCES venue(id),
    patient_id        uuid NOT NULL REFERENCES patient(id),
    date_heure        timestamptz NOT NULL DEFAULT now(),
    plainte_principale text,
    anamnese          text,
    antecedents       text,
    examen_physique   jsonb,                               -- par appareil
    hypotheses        text,
    conduite          text,
    protocole_id      uuid REFERENCES protocole(id),
    protocole_suivi   boolean,
    praticien_id      uuid NOT NULL REFERENCES utilisateur(id),
    validee           boolean NOT NULL DEFAULT false,      -- RG-07 : verrouillage
    date_validation   timestamptz,
    sensible          boolean NOT NULL DEFAULT false,      -- VIH, VBG, santé mentale
    deleted_at        timestamptz
);
CREATE INDEX idx_consult_patient ON consultation(patient_id, date_heure DESC);

CREATE TABLE consultation_addendum (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id uuid NOT NULL REFERENCES consultation(id),
    contenu         text NOT NULL,
    auteur_id       uuid NOT NULL REFERENCES utilisateur(id),
    horodatage      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE consultation_diagnostic (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id uuid NOT NULL REFERENCES consultation(id),
    diagnostic_id   uuid NOT NULL REFERENCES diagnostic_ref(id),
    principal       boolean NOT NULL DEFAULT false,
    confirme        boolean NOT NULL DEFAULT false,        -- confirmé biologiquement
    UNIQUE (consultation_id, diagnostic_id)
);

CREATE TABLE notification_maladie (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    patient_id      uuid NOT NULL REFERENCES patient(id),
    diagnostic_id   uuid NOT NULL REFERENCES diagnostic_ref(id),
    date_notification date NOT NULL DEFAULT current_date,
    village_id      uuid REFERENCES village(id),
    statut_envoi    text DEFAULT 'EN_ATTENTE',
    envoye_le       timestamptz
);

CREATE TABLE acte_realise (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id      uuid NOT NULL REFERENCES venue(id),
    acte_id       uuid NOT NULL REFERENCES acte(id),
    quantite      numeric(8,2) NOT NULL DEFAULT 1,
    service_id    uuid REFERENCES service(id),
    executant_id  uuid REFERENCES utilisateur(id),
    date_heure    timestamptz NOT NULL DEFAULT now(),
    observation   text,
    facture_ligne_id uuid,                                 -- FK ajoutée après facture_ligne
    deleted_at    timestamptz
);

CREATE TABLE prescription (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id uuid REFERENCES consultation(id),
    venue_id        uuid NOT NULL REFERENCES venue(id),
    patient_id      uuid NOT NULL REFERENCES patient(id),
    produit_id      uuid NOT NULL REFERENCES produit(id),
    dose            text,
    voie            text,
    frequence_par_jour numeric(4,1),
    duree_jours     smallint,
    quantite_prescrite numeric(10,2) NOT NULL,             -- calculée (EF-M05-01)
    posologie_texte text,
    long_cours      boolean NOT NULL DEFAULT false,
    prescripteur_id uuid NOT NULL REFERENCES utilisateur(id),
    date_heure      timestamptz NOT NULL DEFAULT now(),
    statut          text NOT NULL DEFAULT 'A_DISPENSER',   -- A_DISPENSER, DISPENSEE, PARTIELLE, REFUSEE_RUPTURE, ANNULEE
    deleted_at      timestamptz
);
CREATE INDEX idx_prescription_venue ON prescription(venue_id, statut);

CREATE TABLE rendez_vous (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id    uuid NOT NULL REFERENCES patient(id),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    type          text NOT NULL,                           -- CPN, CPS, PEV, PF, ARV, TB, CHRONIQUE, CONTROLE
    date_prevue   date NOT NULL,
    service_id    uuid REFERENCES service(id),
    honore        boolean,
    date_honore   date,
    venue_id      uuid REFERENCES venue(id),
    rappel_envoye boolean NOT NULL DEFAULT false,
    commentaire   text
);
CREATE INDEX idx_rdv_echeance ON rendez_vous(structure_id, date_prevue, honore);

-- ---------------------------------------------------------------------
-- 6. M06 — LABORATOIRE
-- ---------------------------------------------------------------------
CREATE TABLE demande_examen (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id        uuid NOT NULL REFERENCES venue(id),
    patient_id      uuid NOT NULL REFERENCES patient(id),
    consultation_id uuid REFERENCES consultation(id),
    numero_labo     text,                                  -- numéro d'ordre du registre de laboratoire
    urgent          boolean NOT NULL DEFAULT false,
    prescripteur_id uuid NOT NULL REFERENCES utilisateur(id),
    date_heure      timestamptz NOT NULL DEFAULT now(),
    statut          text NOT NULL DEFAULT 'DEMANDEE',      -- DEMANDEE, PRELEVEE, EN_COURS, RENDUE, ANNULEE
    deleted_at      timestamptz
);

CREATE TABLE demande_examen_ligne (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    demande_id    uuid NOT NULL REFERENCES demande_examen(id),
    examen_id     uuid NOT NULL REFERENCES examen_ref(id),
    facture_ligne_id uuid,
    UNIQUE (demande_id, examen_id)
);

CREATE TABLE resultat_examen (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    demande_ligne_id  uuid NOT NULL REFERENCES demande_examen_ligne(id),
    valeur_numerique  numeric(14,4),
    valeur_qualitative text,
    valeur_texte      text,
    unite             text,
    interpretation    text,                                -- NORMAL, ANORMAL, CRITIQUE
    critique          boolean NOT NULL DEFAULT false,
    lot_reactif_id    uuid,                                -- FK -> lot
    technicien_id     uuid REFERENCES utilisateur(id),
    date_heure_resultat timestamptz NOT NULL DEFAULT now(),
    valide            boolean NOT NULL DEFAULT false,
    rendu_le          timestamptz,
    commentaire       text
);

CREATE TABLE transfusion (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id       uuid NOT NULL REFERENCES venue(id),
    patient_id     uuid NOT NULL REFERENCES patient(id),
    groupe_receveur text,
    groupe_poche   text,
    numero_poche   text,
    volume_ml      integer,
    test_compatibilite text,
    donneur        text,
    date_heure_debut timestamptz,
    date_heure_fin timestamptz,
    incident       text,
    responsable_id uuid REFERENCES utilisateur(id)
);

CREATE TABLE releve_temperature (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    equipement_id uuid,                                    -- FK -> equipement
    date_jour     date NOT NULL,
    moment        text NOT NULL,                           -- MATIN, SOIR
    temperature_c numeric(4,1) NOT NULL,
    hors_plage    boolean NOT NULL DEFAULT false,
    action_corrective text,
    releve_par    uuid REFERENCES utilisateur(id),
    UNIQUE (equipement_id, date_jour, moment)
);

-- ---------------------------------------------------------------------
-- 7. M07 — PHARMACIE, STOCK, SIGL
-- ---------------------------------------------------------------------
CREATE TABLE depot (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    code          text NOT NULL,
    nom           text NOT NULL,
    type          text NOT NULL,                           -- PHARMACIE_PRINCIPALE, OFFICINE, LABO, PEV, MATERNITE
    UNIQUE (structure_id, code)
);

CREATE TABLE lot (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produit_id      uuid NOT NULL REFERENCES produit(id),
    numero_lot      text,
    date_peremption date,
    fabricant       text,
    prix_achat_unitaire numeric(14,4),
    devise_achat    devise_t DEFAULT 'CDF',
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (produit_id, numero_lot, date_peremption)
);
CREATE INDEX idx_lot_peremption ON lot(date_peremption);

-- Solde matérialisé par dépôt et lot (mis à jour par trigger sur mouvement_stock)
CREATE TABLE stock (
    depot_id      uuid NOT NULL REFERENCES depot(id),
    lot_id        uuid NOT NULL REFERENCES lot(id),
    quantite      numeric(14,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (depot_id, lot_id),
    CHECK (quantite >= 0)                                  -- RG-04
);

-- Fiche de stock électronique : la ligne de mouvement EST la ligne de fiche (EF-M07-01)
CREATE TABLE mouvement_stock (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    depot_id        uuid NOT NULL REFERENCES depot(id),
    lot_id          uuid NOT NULL REFERENCES lot(id),
    type            mouvement_t NOT NULL,
    quantite        numeric(14,2) NOT NULL CHECK (quantite > 0),
    solde_apres     numeric(14,2) NOT NULL,
    motif_perte     motif_perte_t,
    piece_reference text,                                  -- n° PV réception, bon, ordonnance
    reception_id    uuid,
    dispensation_id uuid,
    inventaire_id   uuid,
    derogation_fefo boolean NOT NULL DEFAULT false,        -- RG-05 : dérogation tracée
    motif_derogation text,
    date_mouvement  timestamptz NOT NULL DEFAULT now(),
    saisi_par       uuid REFERENCES utilisateur(id)
);
CREATE INDEX idx_mvt_fiche ON mouvement_stock(depot_id, lot_id, date_mouvement);
CREATE INDEX idx_mvt_periode ON mouvement_stock(structure_id, date_mouvement);

CREATE TABLE rupture_stock (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    depot_id      uuid NOT NULL REFERENCES depot(id),
    produit_id    uuid NOT NULL REFERENCES produit(id),
    date_debut    date NOT NULL,
    date_fin      date,
    nb_jours      integer GENERATED ALWAYS AS
                  (CASE WHEN date_fin IS NULL THEN NULL ELSE (date_fin - date_debut) END) STORED
);

CREATE TABLE commande (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    numero          text NOT NULL,
    destinataire    text NOT NULL,                         -- BCZS, CDR, fournisseur
    periode_mois    date NOT NULL,                         -- mois de commande
    date_commande   date NOT NULL DEFAULT current_date,
    statut          text NOT NULL DEFAULT 'BROUILLON',     -- BROUILLON, TRANSMISE, PARTIELLE, SERVIE, ANNULEE
    montant_estime  numeric(14,2),
    etabli_par      uuid REFERENCES utilisateur(id),
    UNIQUE (structure_id, numero)
);

CREATE TABLE commande_ligne (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    commande_id   uuid NOT NULL REFERENCES commande(id),
    produit_id    uuid NOT NULL REFERENCES produit(id),
    cmm           numeric(14,2),                           -- consommation moyenne mensuelle
    sdu           numeric(14,2),                           -- stock disponible utilisable
    stock_securite numeric(14,2),
    stock_max     numeric(14,2),
    quantite_demandee numeric(14,2) NOT NULL,
    quantite_servie   numeric(14,2),
    UNIQUE (commande_id, produit_id)
);

CREATE TABLE reception (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    depot_id        uuid NOT NULL REFERENCES depot(id),
    commande_id     uuid REFERENCES commande(id),
    numero_pv       text NOT NULL,                         -- procès-verbal de réception (R2 #116)
    bon_livraison   text,
    fournisseur     text,
    date_reception  date NOT NULL DEFAULT current_date,
    observations_ecarts text,
    receptionne_par uuid REFERENCES utilisateur(id),
    contresigne_par uuid REFERENCES utilisateur(id),
    UNIQUE (structure_id, numero_pv)
);

CREATE TABLE reception_ligne (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reception_id  uuid NOT NULL REFERENCES reception(id),
    lot_id        uuid NOT NULL REFERENCES lot(id),
    quantite_attendue numeric(14,2),
    quantite_recue    numeric(14,2) NOT NULL,
    quantite_refusee  numeric(14,2) DEFAULT 0,
    motif_refus   text
);

CREATE TABLE inventaire (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    depot_id      uuid NOT NULL REFERENCES depot(id),
    date_inventaire date NOT NULL,
    type          text NOT NULL DEFAULT 'PERIODIQUE',      -- INITIAL, PERIODIQUE, TOURNANT
    statut        text NOT NULL DEFAULT 'EN_COURS',
    realise_par   uuid REFERENCES utilisateur(id),
    valide_par    uuid REFERENCES utilisateur(id),
    commentaire   text
);

CREATE TABLE inventaire_ligne (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    inventaire_id  uuid NOT NULL REFERENCES inventaire(id),
    lot_id         uuid NOT NULL REFERENCES lot(id),
    quantite_theorique numeric(14,2) NOT NULL,
    quantite_physique  numeric(14,2) NOT NULL,
    ecart          numeric(14,2) GENERATED ALWAYS AS (quantite_physique - quantite_theorique) STORED,
    quantite_perimee numeric(14,2) DEFAULT 0,
    quantite_avariee numeric(14,2) DEFAULT 0,
    justification  text,
    UNIQUE (inventaire_id, lot_id)
);

CREATE TABLE produit_hors_usage (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    lot_id        uuid NOT NULL REFERENCES lot(id),
    quantite      numeric(14,2) NOT NULL,
    motif         motif_perte_t NOT NULL,
    date_constat  date NOT NULL DEFAULT current_date,
    valeur        numeric(14,2),
    pv_destruction text,
    date_destruction date,
    constate_par  uuid REFERENCES utilisateur(id)
);

CREATE TABLE dispensation (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    venue_id        uuid REFERENCES venue(id),
    patient_id      uuid REFERENCES patient(id),
    prescription_id uuid REFERENCES prescription(id),       -- RG-03
    vente_officine  boolean NOT NULL DEFAULT false,
    depot_id        uuid NOT NULL REFERENCES depot(id),
    lot_id          uuid NOT NULL REFERENCES lot(id),
    quantite        numeric(14,2) NOT NULL,
    substitution    boolean NOT NULL DEFAULT false,
    produit_initial_id uuid REFERENCES produit(id),
    motif_substitution text,
    montant         numeric(14,2),
    date_heure      timestamptz NOT NULL DEFAULT now(),
    dispense_par    uuid REFERENCES utilisateur(id),
    facture_ligne_id uuid,
    CHECK (prescription_id IS NOT NULL OR vente_officine = true)
);
CREATE INDEX idx_dispensation_jour ON dispensation(structure_id, date_heure);

-- RUMER : registre d'utilisation des médicaments et des recettes (R4)
CREATE TABLE rumer_jour (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id      uuid NOT NULL REFERENCES structure(id),
    date_jour         date NOT NULL,
    valeur_stock_consomme numeric(14,2) NOT NULL DEFAULT 0,
    recettes_jour     numeric(14,2) NOT NULL DEFAULT 0,
    versement_tresorier numeric(14,2) NOT NULL DEFAULT 0,
    date_versement    date,
    visa_it           uuid REFERENCES utilisateur(id),
    date_visa         timestamptz,
    UNIQUE (structure_id, date_jour)
);

-- ---------------------------------------------------------------------
-- 8. M08 — OBSERVATION / HOSPITALISATION
-- ---------------------------------------------------------------------
CREATE TABLE sejour (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id      uuid NOT NULL REFERENCES structure(id),
    venue_id          uuid NOT NULL REFERENCES venue(id),
    patient_id        uuid NOT NULL REFERENCES patient(id),
    numero_sejour     text NOT NULL,
    service_id        uuid NOT NULL REFERENCES service(id),
    lit_id            uuid REFERENCES lit(id),
    date_heure_entree timestamptz NOT NULL DEFAULT now(),
    date_heure_sortie timestamptz,
    diagnostic_entree_id uuid REFERENCES diagnostic_ref(id),
    diagnostic_sortie_id uuid REFERENCES diagnostic_ref(id),
    issue             issue_sortie_t,
    journees          integer,                             -- calculé à la sortie
    UNIQUE (structure_id, numero_sejour)
);

CREATE TABLE signe_vital (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sejour_id     uuid REFERENCES sejour(id),
    venue_id      uuid REFERENCES venue(id),
    horodatage    timestamptz NOT NULL DEFAULT now(),
    temperature_c numeric(4,1),
    pouls         smallint,
    tension_systolique smallint,
    tension_diastolique smallint,
    freq_respiratoire smallint,
    spo2          smallint,
    diurese_ml    integer,
    observation   text,
    releve_par    uuid REFERENCES utilisateur(id)
);

CREATE TABLE administration_traitement (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sejour_id       uuid REFERENCES sejour(id),
    prescription_id uuid REFERENCES prescription(id),
    produit_id      uuid NOT NULL REFERENCES produit(id),
    dose_administree text,
    voie            text,
    horodatage_prevu timestamptz,
    horodatage_reel timestamptz NOT NULL DEFAULT now(),
    administre      boolean NOT NULL DEFAULT true,
    motif_non_administration text,
    administre_par  uuid REFERENCES utilisateur(id)
);

CREATE TABLE note_evolution (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sejour_id     uuid NOT NULL REFERENCES sejour(id),
    type          text NOT NULL DEFAULT 'EVOLUTION',       -- EVOLUTION, TOUR_DE_SALLE, PLAN_DE_SOINS, CONSIGNE_GARDE
    contenu       text NOT NULL,
    auteur_id     uuid NOT NULL REFERENCES utilisateur(id),
    horodatage    timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 9. M09 — SANTÉ MATERNELLE
-- ---------------------------------------------------------------------
CREATE TABLE dossier_grossesse (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id        uuid NOT NULL REFERENCES structure(id),
    patient_id          uuid NOT NULL REFERENCES patient(id),
    numero_cpn          text,
    date_ouverture      date NOT NULL DEFAULT current_date,
    ddr                 date,                              -- dernières règles
    dpa                 date,                              -- date prévue d'accouchement
    gestite             smallint,
    parite              smallint,
    antecedents_obstetricaux text,
    groupe_sanguin      text,
    statut_vih          text,                              -- POSITIF, NEGATIF, INCONNU, REFUS
    sous_arv            boolean DEFAULT false,
    test_syphilis       text,
    grossesse_a_risque  boolean NOT NULL DEFAULT false,
    issue               text,                              -- ACCOUCHEMENT, AVORTEMENT, PERDUE_DE_VUE, TRANSFERT
    date_cloture        date
);
CREATE INDEX idx_grossesse_patient ON dossier_grossesse(patient_id);

CREATE TABLE visite_cpn (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_grossesse_id uuid NOT NULL REFERENCES dossier_grossesse(id),
    venue_id           uuid REFERENCES venue(id),
    numero_visite      smallint NOT NULL,                  -- CPN 1..n
    date_visite        date NOT NULL,
    age_gestationnel_semaines smallint,
    poids_kg           numeric(6,2),
    tension_systolique smallint,
    tension_diastolique smallint,
    hauteur_uterine_cm numeric(5,1),
    bcf                smallint,
    presentation       text,
    oedemes            boolean,
    hemoglobine        numeric(5,2),
    albuminurie        text,
    vat_dose           smallint,
    tpi_dose           smallint,                           -- traitement préventif intermittent
    fer_acide_folique  boolean,
    milda_recue        boolean,
    deparasitage       boolean,
    conseils           text,
    prochain_rdv       date,
    prestataire_id     uuid REFERENCES utilisateur(id),
    UNIQUE (dossier_grossesse_id, numero_visite)
);

CREATE TABLE travail_accouchement (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id       uuid NOT NULL REFERENCES structure(id),
    dossier_grossesse_id uuid REFERENCES dossier_grossesse(id),
    venue_id           uuid REFERENCES venue(id),
    patient_id         uuid NOT NULL REFERENCES patient(id),
    numero_accouchement text,
    date_heure_admission timestamptz,
    date_heure_accouchement timestamptz,
    type_accouchement  type_accouchement_t NOT NULL,
    lieu               text,                               -- FOSA, DOMICILE, EN_ROUTE
    assistance_qualifiee boolean NOT NULL DEFAULT true,
    gatpa              boolean,                            -- gestion active du 3e stade
    delivrance         text,
    pertes_sanguines_ml integer,
    episiotomie        boolean,
    dechirure          text,
    complications      text[],
    refere             boolean NOT NULL DEFAULT false,
    motif_reference    text,
    accoucheur_id      uuid REFERENCES utilisateur(id),
    gratuite_appliquee boolean NOT NULL DEFAULT false,      -- RG-06
    UNIQUE (structure_id, numero_accouchement)
);

CREATE TABLE partogramme_releve (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    accouchement_id uuid NOT NULL REFERENCES travail_accouchement(id),
    horodatage     timestamptz NOT NULL,
    dilatation_cm  numeric(4,1),
    descente_tete  text,
    contractions_par_10min smallint,
    duree_contraction_sec smallint,
    bcf            smallint,
    liquide_amniotique text,
    moulage        text,
    temperature_c  numeric(4,1),
    pouls          smallint,
    tension_systolique smallint,
    tension_diastolique smallint,
    urines         text,
    medicaments    text,
    releve_par     uuid REFERENCES utilisateur(id)
);

CREATE TABLE nouveau_ne (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    accouchement_id uuid NOT NULL REFERENCES travail_accouchement(id),
    patient_id      uuid REFERENCES patient(id),           -- dossier créé pour le nouveau-né
    rang            smallint NOT NULL DEFAULT 1,           -- gémellaire
    sexe            sexe_t,
    poids_g         integer,
    taille_cm       numeric(5,1),
    perimetre_cranien_cm numeric(5,1),
    apgar_1min      smallint,
    apgar_5min      smallint,
    vivant          boolean NOT NULL DEFAULT true,
    mort_ne_type    text,                                  -- FRAIS, MACERE
    reanimation     boolean,
    soins_essentiels boolean,
    allaitement_precoce boolean,
    bcg_polio0      boolean,
    prophylaxie_arv boolean,
    certificat_naissance_numero text
);

CREATE TABLE visite_postnatale (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id     uuid NOT NULL REFERENCES patient(id),
    accouchement_id uuid REFERENCES travail_accouchement(id),
    venue_id       uuid REFERENCES venue(id),
    numero_visite  smallint,
    date_visite    date NOT NULL,
    jour_post_partum smallint,                             -- J0-J2, J3-J7, J8-J42
    involution_uterine text,
    lochies        text,
    allaitement    text,
    complications  text,
    pf_proposee    boolean,
    prestataire_id uuid REFERENCES utilisateur(id)
);

CREATE TABLE deces_maternel_neonatal (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id   uuid NOT NULL REFERENCES structure(id),
    patient_id     uuid REFERENCES patient(id),
    type           text NOT NULL,                          -- MATERNEL, NEONATAL, PERINATAL
    date_deces     date NOT NULL,
    lieu           text,
    cause_probable text,
    facteurs_evitables text,
    revue_realisee boolean NOT NULL DEFAULT false,
    date_revue     date,
    recommandations text
);

CREATE TABLE ptme_suivi (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_grossesse_id uuid REFERENCES dossier_grossesse(id),
    patient_id     uuid NOT NULL REFERENCES patient(id),
    enfant_id      uuid REFERENCES patient(id),
    date_depistage date,
    resultat       text,
    mise_sous_arv  date,
    protocole_arv  text,
    prophylaxie_enfant text,
    pcr_enfant_date date,
    pcr_enfant_resultat text,
    statut_final   text
);

-- ---------------------------------------------------------------------
-- 10. M10 — SANTÉ DE L'ENFANT, CPS, PEV
-- ---------------------------------------------------------------------
CREATE TABLE dossier_cps (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id   uuid NOT NULL REFERENCES structure(id),
    patient_id     uuid NOT NULL REFERENCES patient(id),
    numero_cps     text,
    date_ouverture date NOT NULL DEFAULT current_date,
    mere_id        uuid REFERENCES patient(id),
    village_id     uuid REFERENCES village(id)
);

CREATE TABLE visite_cps (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_cps_id  uuid NOT NULL REFERENCES dossier_cps(id),
    venue_id        uuid REFERENCES venue(id),
    date_visite     date NOT NULL,
    age_mois        smallint,
    poids_kg        numeric(6,2),
    taille_cm       numeric(6,2),
    perimetre_brachial_mm numeric(6,1),
    z_score_pa      numeric(6,2),
    z_score_pt      numeric(6,2),
    z_score_ta      numeric(6,2),
    courbe          text,                                  -- ASCENDANTE, STAGNANTE, DESCENDANTE
    vitamine_a      boolean,
    mebendazole     boolean,
    zinc            boolean,
    milda           boolean,
    conseils        text,
    prochain_rdv    date,
    prestataire_id  uuid REFERENCES utilisateur(id)
);

CREATE TABLE antigene (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code           text UNIQUE NOT NULL,                   -- BCG, VPO0, VPO1..3, VPI1, VPI2, PENTA1..3, PCV1..3, ROTA, VAR1, VAR2, VAA, VAT
    libelle        text NOT NULL,
    produit_id     uuid REFERENCES produit(id),
    cible          text NOT NULL,                          -- ENFANT, FEMME_ENCEINTE
    age_cible_jours integer,
    numero_dose    smallint,
    intervalle_min_jours integer,
    doses_par_flacon smallint,
    duree_flacon_ouvert_heures smallint,
    actif          boolean NOT NULL DEFAULT true
);

CREATE TABLE vaccination (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id   uuid NOT NULL REFERENCES structure(id),
    patient_id     uuid NOT NULL REFERENCES patient(id),
    antigene_id    uuid NOT NULL REFERENCES antigene(id),
    date_vaccination date NOT NULL,
    lot_id         uuid REFERENCES lot(id),
    strategie      strategie_pev_t NOT NULL DEFAULT 'FIXE',
    site           text,
    hors_aire      boolean NOT NULL DEFAULT false,
    vaccinateur_id uuid REFERENCES utilisateur(id),
    venue_id       uuid REFERENCES venue(id),
    UNIQUE (patient_id, antigene_id)
);
CREATE INDEX idx_vaccination_periode ON vaccination(structure_id, date_vaccination);

CREATE TABLE mapi (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    vaccination_id uuid NOT NULL REFERENCES vaccination(id),
    date_apparition date NOT NULL,
    manifestation  text NOT NULL,
    gravite        text,
    conduite       text,
    notifie        boolean NOT NULL DEFAULT false
);

CREATE TABLE seance_pev (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id   uuid NOT NULL REFERENCES structure(id),
    date_seance    date NOT NULL,
    strategie      strategie_pev_t NOT NULL,
    site           text,
    village_id     uuid REFERENCES village(id),
    nb_enfants_attendus integer,
    nb_enfants_vus integer,
    responsable_id uuid REFERENCES utilisateur(id)
);

-- ---------------------------------------------------------------------
-- 11. M11 — PLANIFICATION FAMILIALE
-- ---------------------------------------------------------------------
CREATE TABLE methode_pf (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code            text UNIQUE NOT NULL,
    libelle         text NOT NULL,
    categorie       text,                                  -- ORALE, INJECTABLE, IMPLANT, DIU, BARRIERE, NATURELLE, DEFINITIVE
    produit_id      uuid REFERENCES produit(id),
    duree_protection_jours integer,
    facteur_cap     numeric(8,4),                          -- couples-années de protection
    actif           boolean NOT NULL DEFAULT true
);

CREATE TABLE suivi_pf (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    patient_id      uuid NOT NULL REFERENCES patient(id),
    venue_id        uuid REFERENCES venue(id),
    methode_id      uuid NOT NULL REFERENCES methode_pf(id),
    date_prestation date NOT NULL,
    nouvelle_utilisatrice boolean NOT NULL DEFAULT false,
    counseling_realise boolean,
    quantite_remise numeric(8,2),
    date_renouvellement date,
    effets_secondaires text,
    abandon         boolean NOT NULL DEFAULT false,
    motif_abandon   text,
    retrait         boolean NOT NULL DEFAULT false,
    prestataire_id  uuid REFERENCES utilisateur(id)
);

-- ---------------------------------------------------------------------
-- 12. M12 — NUTRITION
-- ---------------------------------------------------------------------
CREATE TABLE admission_nutrition (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    patient_id      uuid NOT NULL REFERENCES patient(id),
    unite           text NOT NULL,                         -- UNTA, UNS
    categorie       text,                                  -- MAS, MAM, FEMME_ENCEINTE, ALLAITANTE, PVVIH, TB
    date_admission  date NOT NULL,
    critere_admission text,                                -- PB, Z_SCORE_PT, OEDEMES
    pb_admission_mm numeric(6,1),
    z_score_admission numeric(6,2),
    oedemes         boolean,
    test_appetit    text,
    poids_admission_kg numeric(6,2),
    date_sortie     date,
    issue           issue_nutrition_t,
    poids_sortie_kg numeric(6,2),
    gain_poids_g_kg_j numeric(6,2)
);

CREATE TABLE visite_nutrition (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    admission_id    uuid NOT NULL REFERENCES admission_nutrition(id),
    date_visite     date NOT NULL,
    semaine         smallint,
    poids_kg        numeric(6,2),
    pb_mm           numeric(6,1),
    oedemes         boolean,
    ration_produit_id uuid REFERENCES produit(id),
    ration_quantite numeric(8,2),
    complications   text
);

-- ---------------------------------------------------------------------
-- 13. M13 — PROGRAMMES VERTICAUX (cohortes)
-- ---------------------------------------------------------------------
CREATE TABLE programme (
    id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code    text UNIQUE NOT NULL,                          -- PALU, TB, VIH, IST, HTA, DIABETE, LEPRE, THA
    libelle text NOT NULL
);

CREATE TABLE inclusion_programme (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    programme_id    uuid NOT NULL REFERENCES programme(id),
    patient_id      uuid NOT NULL REFERENCES patient(id),
    numero_registre text,
    date_inclusion  date NOT NULL,
    categorie       text,                                  -- ex TB : nouveau cas, rechute, échec
    schema_traitement text,
    date_debut_traitement date,
    date_fin_prevue date,
    issue           text,                                  -- GUERI, TERMINE, ECHEC, DECES, PERDU_DE_VUE, TRANSFERT
    date_issue      date,
    sensible        boolean NOT NULL DEFAULT false,
    UNIQUE (structure_id, programme_id, numero_registre)
);

CREATE TABLE suivi_programme (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    inclusion_id    uuid NOT NULL REFERENCES inclusion_programme(id),
    venue_id        uuid REFERENCES venue(id),
    date_visite     date NOT NULL,
    mois_traitement smallint,
    observance      text,
    poids_kg        numeric(6,2),
    tension_systolique smallint,
    tension_diastolique smallint,
    glycemie        numeric(6,2),
    charge_virale   numeric(14,2),
    resultat_crachat text,
    cotrimoxazole   boolean,
    prochain_rdv    date,
    prestataire_id  uuid REFERENCES utilisateur(id)
);

CREATE TABLE contact_depistage (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    inclusion_id  uuid NOT NULL REFERENCES inclusion_programme(id),
    nom           text,
    lien          text,
    age           smallint,
    depiste       boolean,
    date_depistage date,
    resultat      text
);

-- ---------------------------------------------------------------------
-- 14. M14 — RÉFÉRENCE / CONTRE-RÉFÉRENCE
-- ---------------------------------------------------------------------
CREATE TABLE reference (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id      uuid NOT NULL REFERENCES structure(id),
    venue_id          uuid NOT NULL REFERENCES venue(id),
    patient_id        uuid NOT NULL REFERENCES patient(id),
    numero            text NOT NULL,
    destination_nom   text NOT NULL,                       -- HGR, autre FOSA
    destination_structure_id uuid REFERENCES structure(id),
    date_heure_decision timestamptz NOT NULL DEFAULT now(),
    date_heure_depart timestamptz,
    urgence           priorite_t NOT NULL DEFAULT 'URGENCE',
    motif             text NOT NULL,
    diagnostic_id     uuid REFERENCES diagnostic_ref(id),
    actes_poses       text,
    traitement_administre text,
    moyen_transport   text,
    accompagnant      text,
    refere_par        uuid REFERENCES utilisateur(id),
    -- contre-référence
    contre_reference_recue boolean NOT NULL DEFAULT false,
    date_contre_reference date,
    diagnostic_retour text,
    traitement_retour text,
    recommandations   text,
    document_scanne   text,
    UNIQUE (structure_id, numero)
);
CREATE INDEX idx_reference_periode ON reference(structure_id, date_heure_decision);

-- ---------------------------------------------------------------------
-- 15. M15/M16 — TARIFICATION, FACTURATION, CAISSE, TIERS PAYANTS
-- ---------------------------------------------------------------------
CREATE TABLE facture (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id      uuid NOT NULL REFERENCES structure(id),
    venue_id          uuid NOT NULL REFERENCES venue(id),
    patient_id        uuid NOT NULL REFERENCES patient(id),
    numero            text NOT NULL,
    date_facture      timestamptz NOT NULL DEFAULT now(),
    devise            devise_t NOT NULL DEFAULT 'CDF',
    taux_change       numeric(16,6),
    montant_brut      numeric(14,2) NOT NULL DEFAULT 0,
    montant_remise    numeric(14,2) NOT NULL DEFAULT 0,
    montant_exonere   numeric(14,2) NOT NULL DEFAULT 0,
    part_patient      numeric(14,2) NOT NULL DEFAULT 0,
    part_tiers        numeric(14,2) NOT NULL DEFAULT 0,
    tiers_payant_id   uuid REFERENCES tiers_payant(id),
    type_regime       type_regime_t NOT NULL DEFAULT 'PAYANT',
    motif_exoneration text,
    exoneration_validee_par uuid REFERENCES utilisateur(id),
    statut            statut_facture_t NOT NULL DEFAULT 'BROUILLON',
    facture_annulee_id uuid REFERENCES facture(id),        -- contre-passation (RG-07)
    etablie_par       uuid REFERENCES utilisateur(id),
    UNIQUE (structure_id, numero)
);
CREATE INDEX idx_facture_periode ON facture(structure_id, date_facture);

CREATE TABLE facture_ligne (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    facture_id     uuid NOT NULL REFERENCES facture(id),
    type_ligne     text NOT NULL,                          -- ACTE, EXAMEN, MEDICAMENT, JOURNEE, FORFAIT
    acte_id        uuid REFERENCES acte(id),
    examen_id      uuid REFERENCES examen_ref(id),
    produit_id     uuid REFERENCES produit(id),
    libelle        text NOT NULL,
    quantite       numeric(10,2) NOT NULL DEFAULT 1,
    prix_unitaire  numeric(14,2) NOT NULL,
    taux_prise_charge numeric(5,2) NOT NULL DEFAULT 0,
    montant_total  numeric(14,2) NOT NULL,
    part_patient   numeric(14,2) NOT NULL,
    part_tiers     numeric(14,2) NOT NULL DEFAULT 0
);

ALTER TABLE acte_realise           ADD CONSTRAINT fk_ar_fl  FOREIGN KEY (facture_ligne_id) REFERENCES facture_ligne(id);
ALTER TABLE demande_examen_ligne   ADD CONSTRAINT fk_del_fl FOREIGN KEY (facture_ligne_id) REFERENCES facture_ligne(id);
ALTER TABLE dispensation           ADD CONSTRAINT fk_disp_fl FOREIGN KEY (facture_ligne_id) REFERENCES facture_ligne(id);

CREATE TABLE session_caisse (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id      uuid NOT NULL REFERENCES structure(id),
    caissier_id       uuid NOT NULL REFERENCES utilisateur(id),
    poste             text,
    ouverture         timestamptz NOT NULL DEFAULT now(),
    fonds_initial     numeric(14,2) NOT NULL DEFAULT 0,
    cloture           timestamptz,
    total_theorique_cdf numeric(14,2),
    total_theorique_usd numeric(14,2),
    total_compte_cdf  numeric(14,2),
    total_compte_usd  numeric(14,2),
    ecart_cdf         numeric(14,2),
    ecart_usd         numeric(14,2),
    justification_ecart text,
    valide_par        uuid REFERENCES utilisateur(id)
);

CREATE TABLE paiement (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id   uuid NOT NULL REFERENCES structure(id),
    facture_id     uuid NOT NULL REFERENCES facture(id),
    session_caisse_id uuid REFERENCES session_caisse(id),
    numero_recu    text NOT NULL,                          -- série inaltérable (EF-M15-03)
    mode           mode_paiement_t NOT NULL,
    devise         devise_t NOT NULL,
    montant        numeric(14,2) NOT NULL,
    taux_change    numeric(16,6),
    montant_equiv_cdf numeric(14,2),
    reference_externe text,                                -- transaction mobile money
    date_heure     timestamptz NOT NULL DEFAULT now(),
    encaisse_par   uuid REFERENCES utilisateur(id),
    annule         boolean NOT NULL DEFAULT false,
    paiement_annule_id uuid REFERENCES paiement(id),       -- RG-07 contre-passation
    UNIQUE (structure_id, numero_recu)
);

CREATE TABLE versement (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    session_caisse_id uuid REFERENCES session_caisse(id),
    numero_bordereau text NOT NULL,
    montant_cdf     numeric(14,2) NOT NULL DEFAULT 0,
    montant_usd     numeric(14,2) NOT NULL DEFAULT 0,
    date_versement  date NOT NULL DEFAULT current_date,
    destination     text,                                  -- trésorier, banque
    remis_par       uuid REFERENCES utilisateur(id),
    recu_par        uuid REFERENCES utilisateur(id),
    UNIQUE (structure_id, numero_bordereau)
);

CREATE TABLE creance_patient (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    facture_id    uuid NOT NULL REFERENCES facture(id),
    patient_id    uuid NOT NULL REFERENCES patient(id),
    montant_du    numeric(14,2) NOT NULL,
    echeance      date,
    statut        text NOT NULL DEFAULT 'OUVERTE',
    date_reglement date
);

CREATE TABLE bordereau_tiers_payant (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    tiers_payant_id uuid NOT NULL REFERENCES tiers_payant(id),
    numero          text NOT NULL,
    periode_debut   date NOT NULL,
    periode_fin     date NOT NULL,
    montant_reclame numeric(14,2) NOT NULL,
    montant_accepte numeric(14,2),
    montant_rejete  numeric(14,2),
    motif_rejet     text,
    statut          text NOT NULL DEFAULT 'PREPARE',       -- PREPARE, ENVOYE, RECU, CONTESTE, PAYE
    date_envoi      date,
    date_paiement   date,
    UNIQUE (structure_id, numero)
);

CREATE TABLE bordereau_ligne (
    bordereau_id  uuid NOT NULL REFERENCES bordereau_tiers_payant(id),
    facture_id    uuid NOT NULL REFERENCES facture(id),
    montant       numeric(14,2) NOT NULL,
    accepte       boolean,
    motif_rejet   text,
    PRIMARY KEY (bordereau_id, facture_id)
);

-- ---------------------------------------------------------------------
-- 16. M17 — COMPTABILITÉ, BUDGET, TRÉSORERIE
-- ---------------------------------------------------------------------
CREATE TABLE compte_comptable (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    numero        text UNIQUE NOT NULL,
    libelle       text NOT NULL,
    classe        smallint,
    type          text,                                    -- ACTIF, PASSIF, CHARGE, PRODUIT
    actif         boolean NOT NULL DEFAULT true
);

CREATE TABLE journal_comptable (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code          text UNIQUE NOT NULL,                    -- CA (caisse), BQ, AC, VE, OD
    libelle       text NOT NULL
);

CREATE TABLE ecriture (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    journal_id    uuid NOT NULL REFERENCES journal_comptable(id),
    numero_piece  text NOT NULL,
    date_ecriture date NOT NULL,
    libelle       text NOT NULL,
    origine       text,                                    -- CAISSE, PHARMACIE, PAIE, MANUEL
    origine_id    uuid,
    exercice      smallint NOT NULL,
    cloturee      boolean NOT NULL DEFAULT false,
    saisie_par    uuid REFERENCES utilisateur(id)
);

CREATE TABLE ecriture_ligne (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ecriture_id   uuid NOT NULL REFERENCES ecriture(id),
    compte_id     uuid NOT NULL REFERENCES compte_comptable(id),
    debit         numeric(16,2) NOT NULL DEFAULT 0,
    credit        numeric(16,2) NOT NULL DEFAULT 0,
    axe_analytique text,                                   -- service, projet, bailleur
    bailleur      text,
    CHECK (debit >= 0 AND credit >= 0 AND (debit = 0 OR credit = 0))
);

CREATE TABLE budget (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    exercice      smallint NOT NULL,
    statut        text NOT NULL DEFAULT 'PROJET',
    UNIQUE (structure_id, exercice)
);

CREATE TABLE budget_ligne (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id     uuid NOT NULL REFERENCES budget(id),
    compte_id     uuid REFERENCES compte_comptable(id),
    rubrique      text NOT NULL,
    source_financement text,
    montant_prevu numeric(16,2) NOT NULL,
    montant_engage numeric(16,2) NOT NULL DEFAULT 0,
    montant_realise numeric(16,2) NOT NULL DEFAULT 0
);

CREATE TABLE depense (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    numero_piece    text NOT NULL,
    type_piece      text NOT NULL,                         -- BON_DEMANDE_FONDS, BON_ENGAGEMENT, BON_COMMANDE, FACTURE_FOURNISSEUR
    beneficiaire    text,
    objet           text NOT NULL,
    montant         numeric(16,2) NOT NULL,
    devise          devise_t NOT NULL DEFAULT 'CDF',
    budget_ligne_id uuid REFERENCES budget_ligne(id),
    date_depense    date NOT NULL DEFAULT current_date,
    mode_paiement   mode_paiement_t,
    justifiee       boolean NOT NULL DEFAULT false,
    demande_par     uuid REFERENCES utilisateur(id),
    approuve_par    uuid REFERENCES utilisateur(id),
    ecriture_id     uuid REFERENCES ecriture(id),
    UNIQUE (structure_id, numero_piece)
);

CREATE TABLE compte_bancaire (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    banque        text NOT NULL,
    numero        text NOT NULL,
    devise        devise_t NOT NULL,
    solde_initial numeric(16,2) NOT NULL DEFAULT 0
);

CREATE TABLE mouvement_bancaire (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    compte_bancaire_id uuid NOT NULL REFERENCES compte_bancaire(id),
    date_operation date NOT NULL,
    libelle       text NOT NULL,
    debit         numeric(16,2) DEFAULT 0,
    credit        numeric(16,2) DEFAULT 0,
    reference     text,
    rapproche     boolean NOT NULL DEFAULT false
);

-- ---------------------------------------------------------------------
-- 17. M18 — RESSOURCES HUMAINES ET PAIE
-- ---------------------------------------------------------------------
CREATE TABLE presence (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id      uuid NOT NULL REFERENCES agent(id),
    date_jour     date NOT NULL,
    present       boolean NOT NULL DEFAULT true,
    type_absence  text,                                    -- CONGE, MALADIE, MISSION, FORMATION, INJUSTIFIEE
    justifiee     boolean,
    heure_arrivee time,
    heure_depart  time,
    UNIQUE (agent_id, date_jour)
);

CREATE TABLE conge (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id      uuid NOT NULL REFERENCES agent(id),
    type          text NOT NULL,
    date_debut    date NOT NULL,
    date_fin      date NOT NULL,
    nb_jours      smallint,
    statut        text NOT NULL DEFAULT 'DEMANDE',
    numero_decision text,
    approuve_par  uuid REFERENCES utilisateur(id)
);

CREATE TABLE roulement (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id      uuid NOT NULL REFERENCES agent(id),
    service_id    uuid NOT NULL REFERENCES service(id),
    date_jour     date NOT NULL,
    poste         text NOT NULL,                           -- MATIN, APRES_MIDI, NUIT, GARDE
    UNIQUE (agent_id, date_jour, poste)
);

CREATE TABLE periode_paie (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    mois          date NOT NULL,
    statut        text NOT NULL DEFAULT 'OUVERTE',
    total_brut    numeric(16,2),
    total_net     numeric(16,2),
    valide_par    uuid REFERENCES utilisateur(id),
    UNIQUE (structure_id, mois)
);

CREATE TABLE bulletin_paie (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    periode_paie_id uuid NOT NULL REFERENCES periode_paie(id),
    agent_id        uuid NOT NULL REFERENCES agent(id),
    salaire_base    numeric(14,2) NOT NULL DEFAULT 0,
    prime_risque    numeric(14,2) DEFAULT 0,
    prime_fbp       numeric(14,2) DEFAULT 0,
    autres_primes   numeric(14,2) DEFAULT 0,
    retenues        numeric(14,2) DEFAULT 0,
    net_a_payer     numeric(14,2) NOT NULL,
    devise          devise_t NOT NULL DEFAULT 'CDF',
    jours_prestes   smallint,
    paye            boolean NOT NULL DEFAULT false,
    date_paiement   date,
    UNIQUE (periode_paie_id, agent_id)
);

CREATE TABLE evaluation_agent (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id      uuid NOT NULL REFERENCES agent(id),
    periode       text NOT NULL,
    score         numeric(5,2),
    points_forts  text,
    axes_amelioration text,
    evaluateur_id uuid REFERENCES utilisateur(id),
    date_evaluation date NOT NULL DEFAULT current_date
);

CREATE TABLE formation (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    theme         text NOT NULL,
    date_debut    date,
    date_fin      date,
    formateur     text,
    lieu          text
);

CREATE TABLE formation_participant (
    formation_id  uuid NOT NULL REFERENCES formation(id),
    agent_id      uuid NOT NULL REFERENCES agent(id),
    present       boolean NOT NULL DEFAULT true,
    note          numeric(5,2),
    PRIMARY KEY (formation_id, agent_id)
);

-- ---------------------------------------------------------------------
-- 18. M19/M20 — ÉQUIPEMENTS, MAINTENANCE, HYGIÈNE ET DÉCHETS
-- ---------------------------------------------------------------------
CREATE TABLE equipement (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    code            text NOT NULL,
    libelle         text NOT NULL,
    categorie       text,                                  -- FRIGO, MICROSCOPE, GLUCOMETRE, SPECTROPHOTOMETRE, CENTRIFUGEUSE, SOLAIRE
    service_id      uuid REFERENCES service(id),
    numero_serie    text,
    date_acquisition date,
    valeur_acquisition numeric(16,2),
    source_financement text,
    duree_amortissement_annees smallint,
    etat            etat_equipement_t NOT NULL DEFAULT 'FONCTIONNEL',
    chaine_froid    boolean NOT NULL DEFAULT false,
    date_reforme    date,
    UNIQUE (structure_id, code)
);

ALTER TABLE releve_temperature ADD CONSTRAINT fk_temp_equip FOREIGN KEY (equipement_id) REFERENCES equipement(id);

CREATE TABLE maintenance (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    equipement_id  uuid NOT NULL REFERENCES equipement(id),
    type           text NOT NULL,                          -- PREVENTIVE, CURATIVE
    date_prevue    date,
    date_realisee  date,
    panne_decrite  text,
    intervention   text,
    cout           numeric(14,2),
    prestataire    text,
    statut         text NOT NULL DEFAULT 'PLANIFIEE'
);

CREATE TABLE dechet_biomedical (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    date_jour     date NOT NULL,
    categorie     text NOT NULL,                           -- PIQUANTS, ANATOMIQUES, INFECTIEUX, PHARMACEUTIQUES
    quantite_kg   numeric(8,2),
    mode_traitement text,                                  -- INCINERATION, ENFOUISSEMENT, AUTOCLAVE
    responsable_id uuid REFERENCES utilisateur(id)
);

CREATE TABLE cycle_sterilisation (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    date_heure    timestamptz NOT NULL DEFAULT now(),
    equipement_id uuid REFERENCES equipement(id),
    charge        text,
    temperature_c numeric(5,1),
    duree_minutes smallint,
    controle_reussi boolean,
    operateur_id  uuid REFERENCES utilisateur(id)
);

CREATE TABLE accident_exposition_sang (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    agent_id      uuid REFERENCES agent(id),
    date_heure    timestamptz NOT NULL,
    circonstances text,
    conduite_tenue text,
    prophylaxie   boolean,
    suivi         text
);

-- ---------------------------------------------------------------------
-- 19. M21 — ACTIVITÉS COMMUNAUTAIRES
-- ---------------------------------------------------------------------
CREATE TABLE reco (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    nom           text NOT NULL,
    sexe          sexe_t,
    village_id    uuid REFERENCES village(id),
    telephone     text,
    date_formation date,
    type          text,                                    -- RECO, CAC, MEMBRE_COSA
    actif         boolean NOT NULL DEFAULT true
);

CREATE TABLE site_soins_communautaire (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    nom           text NOT NULL,
    village_id    uuid REFERENCES village(id),
    reco_id       uuid REFERENCES reco(id),
    fonctionnel   boolean NOT NULL DEFAULT true,
    depot_id      uuid REFERENCES depot(id)
);

CREATE TABLE activite_communautaire (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    reco_id       uuid REFERENCES reco(id),
    site_id       uuid REFERENCES site_soins_communautaire(id),
    date_activite date NOT NULL,
    type          text NOT NULL,                           -- VISITE_DOMICILE, SENSIBILISATION, RECUPERATION, REFERENCE, PCIME_C, SUIVI_PALLIATIF
    village_id    uuid REFERENCES village(id),
    nb_menages    integer,
    nb_personnes  integer,
    nb_enfants_recuperes integer,
    nb_femmes_enceintes_recuperees integer,
    theme         text,
    observations  text,
    saisi_par     uuid REFERENCES utilisateur(id)
);

CREATE TABLE prise_charge_site (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id       uuid NOT NULL REFERENCES site_soins_communautaire(id),
    patient_id    uuid REFERENCES patient(id),
    date_prise_charge date NOT NULL,
    age_mois      smallint,
    pathologie    text,                                    -- PALU, DIARRHEE, IRA
    tdr_realise   boolean,
    tdr_resultat  text,
    traitement    text,
    refere        boolean NOT NULL DEFAULT false
);

CREATE TABLE perdu_de_vue (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    patient_id    uuid NOT NULL REFERENCES patient(id),
    domaine       text NOT NULL,                           -- PEV, CPN, ARV, TB, NUTRITION, PF
    date_detection date NOT NULL,
    reco_id       uuid REFERENCES reco(id),
    recupere      boolean NOT NULL DEFAULT false,
    date_recuperation date,
    motif_abandon text
);

CREATE TABLE supervision (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    date_supervision date NOT NULL,
    type          text NOT NULL,                           -- ECZS, INTERNE, PARTENAIRE, SUPERVISION_RECO
    superviseur   text,
    domaines      text[],
    constats      text,
    recommandations text,
    score         numeric(5,2)
);

-- ---------------------------------------------------------------------
-- 20. M22 — SNIS / DHIS2
-- ---------------------------------------------------------------------
CREATE TABLE element_donnee_snis (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code          text UNIQUE NOT NULL,
    rubrique      text NOT NULL,                           -- CONSULTATIONS, SANTE_MERE, PF, SANTE_ENFANT, LABO, NUTRITION, PHARMACIE, PERSONNEL, FINANCES...
    libelle       text NOT NULL,
    unite         text,
    ventilation   text[],                                  -- {SEXE, AGE_MOINS_5, AGE_5_PLUS}
    code_dhis2_de text,                                    -- dataElement uid
    code_dhis2_coc text,                                   -- categoryOptionCombo uid
    formule       text,                                    -- expression de calcul documentée
    obligatoire   boolean NOT NULL DEFAULT true,
    actif         boolean NOT NULL DEFAULT true
);

CREATE TABLE rapport_mensuel (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    periode_mois    date NOT NULL,                         -- 1er du mois
    type_rapport    text NOT NULL DEFAULT 'SNIS_CS',        -- SNIS_CS, SIGL_FOSA, PEV, TB, VIH, NUTRITION, FBP
    statut          statut_rapport_t NOT NULL DEFAULT 'BROUILLON',
    version         smallint NOT NULL DEFAULT 1,
    genere_le       timestamptz,
    genere_par      uuid REFERENCES utilisateur(id),
    valide_par      uuid REFERENCES utilisateur(id),
    date_validation timestamptz,
    transmis_le     timestamptz,
    canal_transmission text,                               -- PAPIER, DHIS2_API, FICHIER
    accuse_reception text,
    complet         boolean,
    commentaire     text,
    UNIQUE (structure_id, periode_mois, type_rapport, version)
);

CREATE TABLE rapport_valeur (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    rapport_id        uuid NOT NULL REFERENCES rapport_mensuel(id) ON DELETE CASCADE,
    element_id        uuid NOT NULL REFERENCES element_donnee_snis(id),
    ventilation_cle   text NOT NULL DEFAULT 'TOTAL',       -- ex: F_MOINS5
    valeur_calculee   numeric(16,2),
    valeur_saisie     numeric(16,2),                       -- uniquement si non dérivable
    valeur_retenue    numeric(16,2) NOT NULL,
    commentaire       text,
    UNIQUE (rapport_id, element_id, ventilation_cle)
);

CREATE TABLE controle_coherence (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    rapport_id    uuid NOT NULL REFERENCES rapport_mensuel(id) ON DELETE CASCADE,
    code_regle    text NOT NULL,
    severite      text NOT NULL,                           -- BLOQUANT, AVERTISSEMENT
    message       text NOT NULL,
    resolu        boolean NOT NULL DEFAULT false,
    justification text
);

CREATE TABLE export_dhis2 (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    rapport_id    uuid NOT NULL REFERENCES rapport_mensuel(id),
    payload       jsonb NOT NULL,
    tentative     smallint NOT NULL DEFAULT 1,
    statut        text NOT NULL DEFAULT 'EN_ATTENTE',       -- EN_ATTENTE, SUCCES, ECHEC
    reponse       jsonb,
    date_tentative timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 21. M23 — FBP ET QUALITÉ
-- ---------------------------------------------------------------------
CREATE TABLE indicateur_fbp (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code          text UNIQUE NOT NULL,
    libelle       text NOT NULL,
    unite         text,
    tarif_unitaire numeric(14,2) NOT NULL,
    devise        devise_t NOT NULL DEFAULT 'USD',
    source_verification text NOT NULL,                     -- registre concerné
    date_debut    date NOT NULL,
    date_fin      date
);

CREATE TABLE declaration_fbp (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    periode_mois    date NOT NULL,
    numero_bordereau text NOT NULL,
    statut          text NOT NULL DEFAULT 'BROUILLON',     -- BROUILLON, DECLARE, VERIFIE, VALIDE, PAYE
    montant_declare numeric(16,2),
    montant_valide  numeric(16,2),
    date_verification date,
    verificateur    text,
    UNIQUE (structure_id, periode_mois, numero_bordereau)
);

CREATE TABLE declaration_fbp_ligne (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    declaration_id  uuid NOT NULL REFERENCES declaration_fbp(id),
    indicateur_id   uuid NOT NULL REFERENCES indicateur_fbp(id),
    quantite_declaree numeric(14,2) NOT NULL,
    quantite_verifiee numeric(14,2),
    ecart_pourcent  numeric(6,2),
    montant         numeric(16,2),
    UNIQUE (declaration_id, indicateur_id)
);

-- Traçabilité prestation déclarée -> source primaire (EF-M23-03)
CREATE TABLE preuve_fbp (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    declaration_ligne_id uuid NOT NULL REFERENCES declaration_fbp_ligne(id),
    entite_source     text NOT NULL,                       -- venue, accouchement, vaccination...
    entite_source_id  uuid NOT NULL,
    patient_id        uuid REFERENCES patient(id),
    date_prestation   date NOT NULL,
    verifie           boolean,
    commentaire_verif text
);

CREATE TABLE evaluation_qualite (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    periode         date NOT NULL,
    type            text NOT NULL DEFAULT 'TRIMESTRIELLE',
    score_global    numeric(5,2),
    evaluateur      text,
    date_evaluation date
);

CREATE TABLE evaluation_qualite_critere (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_id   uuid NOT NULL REFERENCES evaluation_qualite(id),
    domaine         text NOT NULL,                         -- ACCUEIL, HYGIENE, CONSULTATION, PHARMACIE, MATERNITE, GESTION
    critere         text NOT NULL,
    points_max      numeric(6,2) NOT NULL,
    points_obtenus  numeric(6,2) NOT NULL,
    observation     text
);

CREATE TABLE contre_verification (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id    uuid NOT NULL REFERENCES structure(id),
    periode_mois    date NOT NULL,
    taille_echantillon integer,
    nb_retrouves    integer,
    nb_satisfaits   integer,
    taux_ecart      numeric(6,2),
    organisation    text,
    observations    text
);

CREATE TABLE plan_action (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    periode       text NOT NULL,
    objectif      text NOT NULL,
    activite      text NOT NULL,
    responsable   text,
    echeance      date,
    budget        numeric(14,2),
    statut        text NOT NULL DEFAULT 'PLANIFIE',
    taux_realisation numeric(5,2)
);

-- ---------------------------------------------------------------------
-- 22. M26/M27 — SYNCHRONISATION ET NOTIFICATIONS
-- ---------------------------------------------------------------------
CREATE TABLE sync_journal (
    id            bigserial PRIMARY KEY,
    entite        text NOT NULL,
    entite_id     uuid NOT NULL,
    operation     text NOT NULL,                           -- INSERT, UPDATE
    version       bigint NOT NULL,
    structure_id  uuid,
    payload       jsonb NOT NULL,
    horodatage    timestamptz NOT NULL DEFAULT now(),
    synchronise   boolean NOT NULL DEFAULT false,
    date_sync     timestamptz
);
CREATE INDEX idx_sync_pending ON sync_journal(synchronise, horodatage);

CREATE TABLE sync_conflit (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entite        text NOT NULL,
    entite_id     uuid NOT NULL,
    version_locale jsonb NOT NULL,
    version_distante jsonb NOT NULL,
    detecte_le    timestamptz NOT NULL DEFAULT now(),
    resolu        boolean NOT NULL DEFAULT false,
    resolution    text,                                    -- LOCALE, DISTANTE, FUSION_MANUELLE
    resolu_par    uuid REFERENCES utilisateur(id),
    resolu_le     timestamptz
);

CREATE TABLE sauvegarde (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    type          text NOT NULL,                           -- LOCALE, EXTERNE, DISTANTE
    chemin        text,
    taille_octets bigint,
    chiffree      boolean NOT NULL DEFAULT true,
    succes        boolean NOT NULL,
    message       text,
    horodatage    timestamptz NOT NULL DEFAULT now(),
    restauration_testee_le date
);

CREATE TABLE notification (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id  uuid NOT NULL REFERENCES structure(id),
    canal         text NOT NULL,                           -- SMS, INTERNE
    destinataire  text,
    patient_id    uuid REFERENCES patient(id),
    utilisateur_id uuid REFERENCES utilisateur(id),
    type          text NOT NULL,                           -- RAPPEL_RDV, RUPTURE_STOCK, PEREMPTION, RESULTAT_CRITIQUE, RAPPORT_RETARD, ECART_CAISSE, NOTIF_EPIDEMIO
    message       text NOT NULL,
    statut        text NOT NULL DEFAULT 'EN_ATTENTE',
    tentatives    smallint NOT NULL DEFAULT 0,
    envoye_le     timestamptz,
    lu_le         timestamptz,
    cout          numeric(10,2)
);
CREATE INDEX idx_notif_pending ON notification(structure_id, statut);
