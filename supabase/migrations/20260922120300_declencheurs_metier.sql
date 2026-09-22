-- Généré depuis schema_centre_sante.sql v1.0 — ne pas éditer à la main sans mettre à jour la source.
SET search_path TO public;

-- ---------------------------------------------------------------------
-- 24. TRIGGERS ET RÈGLES DE GESTION
-- ---------------------------------------------------------------------

-- RG-04 : mise à jour du solde et interdiction du solde négatif
CREATE OR REPLACE FUNCTION trg_maj_stock() RETURNS trigger AS $$
DECLARE
    v_delta numeric(14,2);
    v_solde numeric(14,2);
BEGIN
    v_delta := CASE NEW.type
                 WHEN 'ENTREE' THEN NEW.quantite
                 WHEN 'TRANSFERT_ENTRANT' THEN NEW.quantite
                 WHEN 'RETOUR' THEN NEW.quantite
                 WHEN 'AJUSTEMENT' THEN NEW.quantite      -- signe porté par le processus d'inventaire
                 ELSE -NEW.quantite
               END;

    INSERT INTO stock(depot_id, lot_id, quantite)
    VALUES (NEW.depot_id, NEW.lot_id, v_delta)
    ON CONFLICT (depot_id, lot_id)
    DO UPDATE SET quantite = stock.quantite + v_delta
    RETURNING quantite INTO v_solde;

    NEW.solde_apres := v_solde;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER t_mouvement_stock
BEFORE INSERT ON mouvement_stock
FOR EACH ROW EXECUTE FUNCTION trg_maj_stock();

-- RG-06 : une prestation sous gratuité maternité ne peut être encaissée au patient
CREATE OR REPLACE FUNCTION trg_gratuite_maternite() RETURNS trigger AS $$
BEGIN
    IF (SELECT f.type_regime FROM facture f WHERE f.id = NEW.facture_id) = 'GRATUITE_MATERNITE'
       AND NEW.mode NOT IN ('TIERS_PAYANT','EXONERATION') THEN
        RAISE EXCEPTION 'RG-06 : encaissement patient interdit sous gratuité maternité (facture %)', NEW.facture_id;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER t_gratuite_maternite
BEFORE INSERT ON paiement
FOR EACH ROW EXECUTE FUNCTION trg_gratuite_maternite();

-- RG-07 : une facture validée n'est plus modifiable (hors annulation)
CREATE OR REPLACE FUNCTION trg_facture_immuable() RETURNS trigger AS $$
BEGIN
    IF OLD.statut IN ('VALIDEE','PAYEE','PARTIELLEMENT_PAYEE')
       AND NEW.statut <> 'ANNULEE'
       AND (NEW.montant_brut <> OLD.montant_brut OR NEW.part_patient <> OLD.part_patient) THEN
        RAISE EXCEPTION 'RG-07 : facture validée non modifiable, utiliser une contre-passation';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER t_facture_immuable
BEFORE UPDATE ON facture
FOR EACH ROW EXECUTE FUNCTION trg_facture_immuable();

-- RG-11 : données d'un mois clos figées
CREATE OR REPLACE FUNCTION trg_periode_close() RETURNS trigger AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM rapport_mensuel r
               WHERE r.structure_id = NEW.structure_id
                 AND r.type_rapport = 'SNIS_CS'
                 AND r.statut = 'TRANSMIS'
                 AND r.periode_mois = date_trunc('month', NEW.date_heure_arrivee)::date) THEN
        RAISE EXCEPTION 'RG-11 : période déjà transmise, créer un rapport rectificatif';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER t_venue_periode_close
BEFORE INSERT ON venue
FOR EACH ROW EXECUTE FUNCTION trg_periode_close();

-- Journal d'audit inaltérable : interdiction d'UPDATE et DELETE
CREATE RULE r_audit_no_update AS ON UPDATE TO journal_audit DO INSTEAD NOTHING;
CREATE RULE r_audit_no_delete AS ON DELETE TO journal_audit DO INSTEAD NOTHING;
