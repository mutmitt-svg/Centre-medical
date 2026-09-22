-- Généré depuis schema_centre_sante.sql v1.0 — ne pas éditer à la main sans mettre à jour la source.
SET search_path TO cs, public;

-- ---------------------------------------------------------------------
-- 25. INDEX COMPLÉMENTAIRES DE PERFORMANCE (ENF-P01 à P04)
-- ---------------------------------------------------------------------
CREATE INDEX idx_consult_periode      ON consultation(date_heure);
CREATE INDEX idx_dispensation_patient ON dispensation(patient_id, date_heure DESC);
CREATE INDEX idx_facture_patient      ON facture(patient_id, date_facture DESC);
CREATE INDEX idx_paiement_session     ON paiement(session_caisse_id);
CREATE INDEX idx_stock_depot          ON stock(depot_id) WHERE quantite > 0;
CREATE INDEX idx_rapport_periode      ON rapport_mensuel(structure_id, periode_mois, type_rapport);
CREATE INDEX idx_inclusion_prog       ON inclusion_programme(structure_id, programme_id, issue);
CREATE INDEX idx_rdv_patient          ON rendez_vous(patient_id, date_prevue);

-- =====================================================================
