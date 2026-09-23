-- =====================================================================
-- Schéma de base de données — Application de gestion d'un centre de santé
-- Cible : PostgreSQL 14+ (compatible SQLite avec adaptations signalées)
-- Version 1.0 — 22 septembre 2026
-- Référence : cahier des charges "Application de gestion complète d'un
-- centre de santé" (modules M01 à M28)
--
-- Principes appliqués
--  1. Clés primaires UUID  -> synchronisation multi-sites sans collision
--  2. Colonne structure_id -> cloisonnement par formation sanitaire
--  3. Journal d'audit      -> aucune suppression physique (deleted_at)
--  4. Événements immuables -> les agrégats SNIS sont TOUJOURS dérivés
--  5. Référentiels versionnés (date_debut / date_fin) sans casser l'historique
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";      -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";       -- recherche tolérante aux fautes
CREATE EXTENSION IF NOT EXISTS "unaccent";

SET search_path TO public;

-- ---------------------------------------------------------------------
-- Enveloppe IMMUTABLE d'unaccent : indispensable pour indexer une
-- expression de recherche (unaccent est STABLE et non indexable).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.unaccent_i(text) RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS
$$ SELECT public.unaccent('public.unaccent'::regdictionary, $1) $$;

-- ---------------------------------------------------------------------
-- 0. TYPES ÉNUMÉRÉS
-- ---------------------------------------------------------------------
CREATE TYPE sexe_t              AS ENUM ('M','F');
CREATE TYPE type_structure_t    AS ENUM ('POSTE_SANTE','CENTRE_SANTE','CS_REFERENCE','HGR','BCZS');
CREATE TYPE type_venue_t        AS ENUM ('CURATIF','PREVENTIF','URGENCE','SUIVI','MATERNITE','LABO_SEUL','PHARMACIE_SEULE');
CREATE TYPE cas_t               AS ENUM ('NOUVEAU','ANCIEN');
CREATE TYPE provenance_t        AS ENUM ('AIRE_SANTE','HORS_AIRE_DANS_ZS','HORS_ZS');
CREATE TYPE priorite_t          AS ENUM ('ROUTINE','REFERE','URGENCE');
CREATE TYPE statut_venue_t      AS ENUM ('ATTENTE','TRIAGE','EN_CONSULTATION','LABO','PHARMACIE','CAISSE','OBSERVATION','CLOTUREE','ABANDON');
CREATE TYPE mouvement_t         AS ENUM ('ENTREE','SORTIE','PERTE','AJUSTEMENT','TRANSFERT_ENTRANT','TRANSFERT_SORTANT','RETOUR');
CREATE TYPE motif_perte_t       AS ENUM ('PEREMPTION','AVARIE','VOL','CASSE','RUPTURE_CHAINE_FROID','AUTRE');
CREATE TYPE mode_paiement_t     AS ENUM ('ESPECES','MOBILE_MONEY','CHEQUE','VIREMENT','TIERS_PAYANT','EXONERATION');
CREATE TYPE devise_t            AS ENUM ('CDF','USD');
CREATE TYPE statut_facture_t    AS ENUM ('BROUILLON','VALIDEE','PARTIELLEMENT_PAYEE','PAYEE','ANNULEE','IMPAYEE');
CREATE TYPE type_regime_t       AS ENUM ('PAYANT','MUTUELLE','ASSURANCE','EMPLOYEUR','INDIGENT','GRATUITE_MATERNITE','PROGRAMME_VERTICAL','PERSONNEL');
CREATE TYPE issue_sortie_t      AS ENUM ('GUERI','AMELIORE','REFERE','TRANSFERE','SORTIE_CONTRE_AVIS','ABANDON','DECES');
CREATE TYPE type_accouchement_t AS ENUM ('EUTOCIQUE','DYSTOCIQUE','CESARIENNE_REFEREE','HORS_FOSA');
CREATE TYPE strategie_pev_t     AS ENUM ('FIXE','AVANCEE','MOBILE','RIPOSTE');
CREATE TYPE statut_rapport_t    AS ENUM ('BROUILLON','CONTROLE','VALIDE','TRANSMIS','RECTIFIE');
CREATE TYPE qualification_t     AS ENUM ('MEDECIN','INFIRMIER_L2','INFIRMIER_A1','INFIRMIER_A2','SAGE_FEMME','ACCOUCHEUSE',
                                         'NUTRITIONNISTE','TECH_LABO','PHARMACIEN','ADMINISTRATIF','CAISSIER','TECHNICIEN','AUTRE');
CREATE TYPE etat_equipement_t   AS ENUM ('FONCTIONNEL','EN_PANNE','HORS_USAGE','REFORME');
CREATE TYPE issue_nutrition_t   AS ENUM ('GUERI','DECES','ABANDON','NON_REPONDANT','TRANSFERT');
CREATE TYPE action_audit_t      AS ENUM ('CREATION','MODIFICATION','LECTURE','SUPPRESSION_LOGIQUE','CONNEXION','ECHEC_CONNEXION','EXPORT','IMPRESSION','BRIS_DE_GLACE');
