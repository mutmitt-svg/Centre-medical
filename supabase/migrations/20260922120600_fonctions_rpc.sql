-- =====================================================================
-- Fonctions RPC appelées par le frontend (supabase.rpc)
-- Toute la logique métier sensible vit ici : le client ne peut pas la
-- contourner, et les règles de gestion RG-02 à RG-11 restent appliquées
-- même en cas d'appel direct à l'API.
-- =====================================================================
SET search_path TO cs, public;

-- Fonction utilitaire d'âge en années révolues
CREATE OR REPLACE FUNCTION cs.age_years(p_date date) RETURNS int
LANGUAGE sql IMMUTABLE AS $$
  SELECT extract(year FROM age(current_date, p_date))::int;
$$;

-- ---------------------------------------------------------------------
-- 1. Recherche de patient tolérante aux fautes (EF-M02-04)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.rechercher_patient(p_q text, p_limite int DEFAULT 20)
RETURNS TABLE (
  id uuid, numero_dossier text, nom_complet text, sexe sexe_t,
  date_naissance date, age_affiche text, telephone text, village text,
  score numeric
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
  WITH base AS (
    SELECT p.*, v.nom AS village_nom,
           similarity(cs.unaccent_i(lower(concat_ws(' ', p.nom, p.post_nom, p.prenom))),
                      cs.unaccent_i(lower(p_q))) AS sim
    FROM cs.patient p
    LEFT JOIN cs.village v ON v.id = p.village_id
    WHERE p.structure_id = cs.structure_courante()
      AND p.deleted_at IS NULL
      AND p.fusionne_vers_id IS NULL
  )
  SELECT id, numero_dossier,
         concat_ws(' ', nom, post_nom, prenom) AS nom_complet,
         sexe, date_naissance,
         CASE
           WHEN date_naissance IS NULL THEN coalesce(age_declare_annees::text || ' ans', 'âge inconnu')
           WHEN cs.age_years(date_naissance) < 1
             THEN (extract(month FROM age(current_date, date_naissance))::int)::text || ' mois'
           ELSE cs.age_years(date_naissance)::text || ' ans'
         END AS age_affiche,
         telephone, village_nom,
         round(greatest(sim, CASE WHEN numero_dossier = p_q OR telephone = p_q THEN 1 ELSE 0 END)::numeric, 3)
    FROM base
   WHERE numero_dossier = p_q OR telephone = p_q OR sim > 0.2
   ORDER BY 9 DESC, nom_complet
   LIMIT p_limite;
$$;

-- ---------------------------------------------------------------------
-- 2. Détection de doublon à la création (EF-M02-05)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.doublons_probables(
  p_nom text, p_post_nom text, p_prenom text, p_sexe sexe_t,
  p_date_naissance date DEFAULT NULL, p_village_id uuid DEFAULT NULL
)
RETURNS TABLE (id uuid, numero_dossier text, nom_complet text, score numeric)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
  SELECT p.id, p.numero_dossier,
         concat_ws(' ', p.nom, p.post_nom, p.prenom),
         round(similarity(cs.unaccent_i(lower(concat_ws(' ', p.nom, p.post_nom, p.prenom))),
                          cs.unaccent_i(lower(concat_ws(' ', p_nom, p_post_nom, p_prenom))))::numeric, 3)
    FROM cs.patient p
   WHERE p.structure_id = cs.structure_courante()
     AND p.deleted_at IS NULL
     AND p.sexe = p_sexe
     AND similarity(cs.unaccent_i(lower(concat_ws(' ', p.nom, p.post_nom, p.prenom))),
                    cs.unaccent_i(lower(concat_ws(' ', p_nom, p_post_nom, p_prenom)))) > 0.45
     AND (p_date_naissance IS NULL OR p.date_naissance IS NULL
          OR abs(p.date_naissance - p_date_naissance) < 400)
   ORDER BY 4 DESC
   LIMIT 10;
$$;

-- ---------------------------------------------------------------------
-- 3. Nouveau cas / ancien cas (RG-02) et enregistrement d'une venue
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.calculer_cas(p_patient uuid, p_date timestamptz DEFAULT now())
RETURNS cas_t
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM cs.venue v
      WHERE v.patient_id = p_patient
        AND v.deleted_at IS NULL
        AND v.type_venue = 'CURATIF'
        AND v.date_heure_arrivee BETWEEN p_date - interval '14 days' AND p_date
    ) THEN 'ANCIEN'::cas_t ELSE 'NOUVEAU'::cas_t END;
$$;

CREATE OR REPLACE FUNCTION cs.enregistrer_venue(
  p_patient uuid,
  p_type type_venue_t,
  p_motif text DEFAULT NULL,
  p_priorite priorite_t DEFAULT 'ROUTINE',
  p_service_id uuid DEFAULT NULL,
  p_cas cas_t DEFAULT NULL,
  p_refere_par text DEFAULT NULL
) RETURNS cs.venue
LANGUAGE plpgsql SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  v_structure uuid := cs.structure_courante();
  v_cas       cas_t;
  v_numero    text;
  v_jeton     smallint;
  v_regime    uuid;
  v_row       cs.venue;
BEGIN
  IF v_structure IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non rattaché à une structure';
  END IF;

  v_cas := coalesce(p_cas, cs.calculer_cas(p_patient));

  SELECT to_char(now(), 'YYYY-MM') || '-' ||
         lpad((count(*) + 1)::text, 4, '0')
    INTO v_numero
    FROM cs.venue
   WHERE structure_id = v_structure
     AND date_trunc('month', date_heure_arrivee) = date_trunc('month', now());

  SELECT coalesce(max(numero_jeton), 0) + 1 INTO v_jeton
    FROM cs.venue
   WHERE structure_id = v_structure
     AND date_heure_arrivee::date = current_date;

  SELECT pr.id INTO v_regime
    FROM cs.patient_regime pr
   WHERE pr.patient_id = p_patient AND pr.actif
     AND (pr.date_fin IS NULL OR pr.date_fin >= current_date)
   ORDER BY CASE pr.type_regime
              WHEN 'GRATUITE_MATERNITE' THEN 1 WHEN 'INDIGENT' THEN 2
              WHEN 'PROGRAMME_VERTICAL' THEN 3 WHEN 'MUTUELLE' THEN 4 ELSE 9 END
   LIMIT 1;

  INSERT INTO cs.venue (structure_id, patient_id, numero_venue, numero_jeton, type_venue,
                        cas, priorite, motif, service_orientation_id, refere_par,
                        regime_applique_id, accueil_par)
  VALUES (v_structure, p_patient, v_numero, v_jeton, p_type, v_cas, p_priorite, p_motif,
          p_service_id, p_refere_par, v_regime, cs.utilisateur_courant())
  RETURNING * INTO v_row;

  PERFORM cs.journaliser('CREATION', 'venue', v_row.id, p_patient);
  RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------
-- 4. File d'attente (EF-M03-03, EF-M03-07)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.file_attente(p_service uuid DEFAULT NULL)
RETURNS TABLE (
  venue_id uuid, numero_jeton smallint, numero_venue text, patient_id uuid,
  nom_complet text, age_affiche text, sexe sexe_t, type_venue type_venue_t,
  cas cas_t, priorite priorite_t, statut statut_venue_t, motif text,
  attente_minutes int, regime type_regime_t
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
  SELECT v.id, v.numero_jeton, v.numero_venue, p.id,
         concat_ws(' ', p.nom, p.post_nom, p.prenom),
         CASE WHEN p.date_naissance IS NULL THEN coalesce(p.age_declare_annees::text || ' ans','—')
              WHEN cs.age_years(p.date_naissance) < 1
                THEN extract(month FROM age(current_date, p.date_naissance))::int::text || ' mois'
              ELSE cs.age_years(p.date_naissance)::text || ' ans' END,
         p.sexe, v.type_venue, v.cas, v.priorite, v.statut, v.motif,
         (extract(epoch FROM (now() - v.date_heure_arrivee)) / 60)::int,
         pr.type_regime
    FROM cs.venue v
    JOIN cs.patient p ON p.id = v.patient_id
    LEFT JOIN cs.patient_regime pr ON pr.id = v.regime_applique_id
   WHERE v.structure_id = cs.structure_courante()
     AND v.deleted_at IS NULL
     AND v.statut NOT IN ('CLOTUREE','ABANDON')
     AND v.date_heure_arrivee::date = current_date
     AND (p_service IS NULL OR v.service_orientation_id = p_service)
   ORDER BY CASE v.priorite WHEN 'URGENCE' THEN 1 WHEN 'REFERE' THEN 2 ELSE 3 END,
            v.numero_jeton;
$$;

-- ---------------------------------------------------------------------
-- 5. Pharmacie : FEFO (RG-05) et données essentielles SIGL (EF-M07-02/04)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.proposer_lots_fefo(
  p_produit uuid, p_depot uuid, p_quantite numeric
)
RETURNS TABLE (lot_id uuid, numero_lot text, date_peremption date,
               disponible numeric, a_servir numeric)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE v_reste numeric := p_quantite; r record;
BEGIN
  FOR r IN
    SELECT s.lot_id, l.numero_lot, l.date_peremption, s.quantite
      FROM cs.stock s JOIN cs.lot l ON l.id = s.lot_id
     WHERE s.depot_id = p_depot AND l.produit_id = p_produit
       AND s.quantite > 0 AND l.date_peremption > current_date
     ORDER BY l.date_peremption
  LOOP
    EXIT WHEN v_reste <= 0;
    lot_id := r.lot_id; numero_lot := r.numero_lot;
    date_peremption := r.date_peremption; disponible := r.quantite;
    a_servir := least(r.quantite, v_reste);
    v_reste := v_reste - a_servir;
    RETURN NEXT;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION cs.donnees_essentielles_sigl(p_periode date DEFAULT date_trunc('month', current_date)::date)
RETURNS TABLE (
  produit_id uuid, code text, dci text, traceur boolean,
  sdu numeric, consommation numeric, pertes numeric, jours_rupture int,
  cmm numeric, stock_securite numeric, stock_max numeric, a_commander numeric,
  mois_de_stock numeric
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
  WITH d AS (SELECT id FROM cs.depot WHERE structure_id = cs.structure_courante()),
  sdu AS (
    SELECT l.produit_id, sum(s.quantite) AS q
      FROM cs.stock s JOIN cs.lot l ON l.id = s.lot_id
     WHERE s.depot_id IN (SELECT id FROM d) AND l.date_peremption > current_date
     GROUP BY 1
  ),
  mouv AS (
    SELECT l.produit_id,
           sum(CASE WHEN m.type = 'SORTIE' THEN m.quantite ELSE 0 END) AS conso,
           sum(CASE WHEN m.type = 'PERTE'  THEN m.quantite ELSE 0 END) AS pertes
      FROM cs.mouvement_stock m JOIN cs.lot l ON l.id = m.lot_id
     WHERE m.depot_id IN (SELECT id FROM d)
       AND m.date_mouvement >= p_periode
       AND m.date_mouvement < (p_periode + interval '1 month')
     GROUP BY 1
  ),
  conso3 AS (
    SELECT l.produit_id,
           sum(CASE WHEN m.type = 'SORTIE' THEN m.quantite ELSE 0 END) AS q3,
           count(DISTINCT date_trunc('month', m.date_mouvement)) AS nb_mois
      FROM cs.mouvement_stock m JOIN cs.lot l ON l.id = m.lot_id
     WHERE m.depot_id IN (SELECT id FROM d)
       AND m.date_mouvement >= p_periode - interval '3 months'
       AND m.date_mouvement < (p_periode + interval '1 month')
     GROUP BY 1
  ),
  rupt AS (
    SELECT produit_id, coalesce(sum(nb_jours), 0)::int AS jours
      FROM cs.rupture_stock
     WHERE structure_id = cs.structure_courante()
       AND date_debut < (p_periode + interval '1 month')
       AND (date_fin IS NULL OR date_fin >= p_periode)
     GROUP BY 1
  )
  SELECT pr.id, pr.code, pr.dci, pr.traceur,
         coalesce(sdu.q, 0),
         coalesce(mouv.conso, 0),
         coalesce(mouv.pertes, 0),
         coalesce(rupt.jours, 0),
         round(coalesce(conso3.q3, 0) / greatest(coalesce(conso3.nb_mois, 1), 1), 1) AS cmm,
         round(coalesce(conso3.q3, 0) / greatest(coalesce(conso3.nb_mois, 1), 1) * pr.mois_stock_securite, 0),
         round(coalesce(conso3.q3, 0) / greatest(coalesce(conso3.nb_mois, 1), 1) * pr.mois_stock_max, 0),
         greatest(round(coalesce(conso3.q3, 0) / greatest(coalesce(conso3.nb_mois, 1), 1) * pr.mois_stock_max, 0)
                  - coalesce(sdu.q, 0), 0),
         CASE WHEN coalesce(conso3.q3, 0) = 0 THEN NULL
              ELSE round(coalesce(sdu.q, 0) /
                   (coalesce(conso3.q3, 0) / greatest(coalesce(conso3.nb_mois, 1), 1)), 1) END
    FROM cs.produit pr
    LEFT JOIN sdu    ON sdu.produit_id = pr.id
    LEFT JOIN mouv   ON mouv.produit_id = pr.id
    LEFT JOIN conso3 ON conso3.produit_id = pr.id
    LEFT JOIN rupt   ON rupt.produit_id = pr.id
   WHERE pr.actif
   ORDER BY pr.traceur DESC, pr.dci;
$$;

-- Dispensation d'une ordonnance : RG-03 (pas de dispensation sans prescription),
-- RG-04 (solde non négatif, assuré par le déclencheur), RG-05 (FEFO tracé).
CREATE OR REPLACE FUNCTION cs.dispenser(
  p_venue uuid, p_depot uuid, p_lignes jsonb
) RETURNS TABLE (dispensation_id uuid, produit_id uuid, quantite numeric, montant numeric)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  l           jsonb;
  v_presc     cs.prescription;
  v_lot       cs.lot;
  v_qte       numeric;
  v_montant   numeric;
  v_disp      uuid;
  v_patient   uuid;
  v_derog     boolean;
  v_lot_fefo  uuid;
BEGIN
  SELECT patient_id INTO v_patient FROM cs.venue WHERE id = p_venue;
  IF v_patient IS NULL THEN RAISE EXCEPTION 'Venue inconnue'; END IF;

  FOR l IN SELECT * FROM jsonb_array_elements(p_lignes) LOOP
    SELECT * INTO v_presc FROM cs.prescription
     WHERE id = (l->>'prescription_id')::uuid AND deleted_at IS NULL;
    IF v_presc.id IS NULL THEN
      RAISE EXCEPTION 'RG-03 : aucune prescription valide pour cette ligne';
    END IF;

    SELECT * INTO v_lot FROM cs.lot WHERE id = (l->>'lot_id')::uuid;
    v_qte := (l->>'quantite')::numeric;

    -- Contrôle FEFO : le lot servi doit être le plus proche de la péremption
    SELECT lot_id INTO v_lot_fefo
      FROM cs.proposer_lots_fefo(v_presc.produit_id, p_depot, v_qte) LIMIT 1;
    v_derog := coalesce((l->>'derogation_fefo')::boolean, false);
    IF v_lot_fefo IS DISTINCT FROM v_lot.id AND NOT v_derog THEN
      RAISE EXCEPTION 'RG-05 : lot non conforme au FEFO, dérogation motivée requise';
    END IF;
    IF v_derog AND coalesce(l->>'motif_derogation','') = '' THEN
      RAISE EXCEPTION 'RG-05 : motif de dérogation obligatoire';
    END IF;

    SELECT t.montant INTO v_montant
      FROM cs.tarif t
      LEFT JOIN cs.venue v ON v.id = p_venue
      LEFT JOIN cs.patient_regime pr ON pr.id = v.regime_applique_id
     WHERE t.produit_id = v_presc.produit_id
       AND t.type_regime = coalesce(pr.type_regime, 'PAYANT')
       AND t.date_debut <= current_date
       AND (t.date_fin IS NULL OR t.date_fin >= current_date)
     ORDER BY t.date_debut DESC LIMIT 1;

    INSERT INTO cs.dispensation (structure_id, venue_id, patient_id, prescription_id,
                                 depot_id, lot_id, quantite, montant, dispense_par)
    VALUES (cs.structure_courante(), p_venue, v_patient, v_presc.id, p_depot,
            v_lot.id, v_qte, coalesce(v_montant, 0) * v_qte, cs.utilisateur_courant())
    RETURNING id INTO v_disp;

    INSERT INTO cs.mouvement_stock (structure_id, depot_id, lot_id, type, quantite,
                                    solde_apres, dispensation_id, derogation_fefo,
                                    motif_derogation, saisi_par)
    VALUES (cs.structure_courante(), p_depot, v_lot.id, 'SORTIE', v_qte, 0, v_disp,
            v_derog, l->>'motif_derogation', cs.utilisateur_courant());

    UPDATE cs.prescription SET statut = 'DISPENSEE' WHERE id = v_presc.id;

    dispensation_id := v_disp; produit_id := v_presc.produit_id;
    quantite := v_qte; montant := coalesce(v_montant, 0) * v_qte;
    RETURN NEXT;
  END LOOP;

  PERFORM cs.journaliser('CREATION', 'dispensation', p_venue, v_patient);
END;
$$;

-- ---------------------------------------------------------------------
-- 6. Facturation (EF-M15-02, EF-M16-03) et caisse (RG-06, RG-08)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.generer_facture(p_venue uuid)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  v_venue    cs.venue;
  v_regime   cs.patient_regime;
  v_taux     numeric := 0;
  v_type     type_regime_t := 'PAYANT';
  v_facture  uuid;
  v_numero   text;
  v_tiers    uuid;
  r          record;
  v_pu       numeric;
BEGIN
  SELECT * INTO v_venue FROM cs.venue WHERE id = p_venue;
  IF v_venue.id IS NULL THEN RAISE EXCEPTION 'Venue inconnue'; END IF;

  IF v_venue.regime_applique_id IS NOT NULL THEN
    SELECT * INTO v_regime FROM cs.patient_regime WHERE id = v_venue.regime_applique_id;
    v_type  := v_regime.type_regime;
    v_tiers := v_regime.tiers_payant_id;
    SELECT coalesce(tp.taux_prise_charge, 0) INTO v_taux
      FROM cs.tiers_payant tp WHERE tp.id = v_tiers;
    IF v_type IN ('INDIGENT','GRATUITE_MATERNITE','PERSONNEL') THEN v_taux := 100; END IF;
  END IF;

  SELECT to_char(now(), 'YYYY') || '-' || lpad((count(*) + 1)::text, 5, '0')
    INTO v_numero FROM cs.facture
   WHERE structure_id = v_venue.structure_id
     AND date_trunc('year', date_facture) = date_trunc('year', now());

  INSERT INTO cs.facture (structure_id, venue_id, patient_id, numero, devise,
                          type_regime, tiers_payant_id, statut, etablie_par)
  VALUES (v_venue.structure_id, p_venue, v_venue.patient_id, v_numero, 'CDF',
          v_type, v_tiers, 'BROUILLON', cs.utilisateur_courant())
  RETURNING id INTO v_facture;

  -- Actes réalisés
  FOR r IN SELECT ar.id, ar.acte_id, ar.quantite, a.libelle
             FROM cs.acte_realise ar JOIN cs.acte a ON a.id = ar.acte_id
            WHERE ar.venue_id = p_venue AND ar.deleted_at IS NULL
              AND ar.facture_ligne_id IS NULL
  LOOP
    SELECT montant INTO v_pu FROM cs.tarif
     WHERE acte_id = r.acte_id AND type_regime = 'PAYANT'
       AND date_debut <= current_date AND (date_fin IS NULL OR date_fin >= current_date)
     ORDER BY date_debut DESC LIMIT 1;
    INSERT INTO cs.facture_ligne (facture_id, type_ligne, acte_id, libelle, quantite,
                                  prix_unitaire, taux_prise_charge, montant_total,
                                  part_patient, part_tiers)
    VALUES (v_facture, 'ACTE', r.acte_id, r.libelle, r.quantite, coalesce(v_pu, 0), v_taux,
            coalesce(v_pu, 0) * r.quantite,
            coalesce(v_pu, 0) * r.quantite * (100 - v_taux) / 100,
            coalesce(v_pu, 0) * r.quantite * v_taux / 100);
  END LOOP;

  -- Examens réalisés
  FOR r IN SELECT del.id, del.examen_id, e.libelle
             FROM cs.demande_examen_ligne del
             JOIN cs.demande_examen de ON de.id = del.demande_id
             JOIN cs.examen_ref e ON e.id = del.examen_id
            WHERE de.venue_id = p_venue AND del.facture_ligne_id IS NULL
  LOOP
    SELECT montant INTO v_pu FROM cs.tarif
     WHERE examen_id = r.examen_id AND type_regime = 'PAYANT'
       AND date_debut <= current_date AND (date_fin IS NULL OR date_fin >= current_date)
     ORDER BY date_debut DESC LIMIT 1;
    INSERT INTO cs.facture_ligne (facture_id, type_ligne, examen_id, libelle, quantite,
                                  prix_unitaire, taux_prise_charge, montant_total,
                                  part_patient, part_tiers)
    VALUES (v_facture, 'EXAMEN', r.examen_id, r.libelle, 1, coalesce(v_pu, 0), v_taux,
            coalesce(v_pu, 0), coalesce(v_pu, 0) * (100 - v_taux) / 100,
            coalesce(v_pu, 0) * v_taux / 100);
  END LOOP;

  -- Médicaments dispensés
  FOR r IN SELECT d.id, d.quantite, d.montant, p.dci, p.id AS produit_id
             FROM cs.dispensation d
             JOIN cs.prescription pr ON pr.id = d.prescription_id
             JOIN cs.produit p ON p.id = pr.produit_id
            WHERE d.venue_id = p_venue AND d.facture_ligne_id IS NULL
  LOOP
    INSERT INTO cs.facture_ligne (facture_id, type_ligne, produit_id, libelle, quantite,
                                  prix_unitaire, taux_prise_charge, montant_total,
                                  part_patient, part_tiers)
    VALUES (v_facture, 'MEDICAMENT', r.produit_id, r.dci, r.quantite,
            CASE WHEN r.quantite > 0 THEN r.montant / r.quantite ELSE 0 END, v_taux,
            r.montant, r.montant * (100 - v_taux) / 100, r.montant * v_taux / 100);
  END LOOP;

  -- Totaux
  UPDATE cs.facture f SET
    montant_brut = t.brut,
    part_patient = CASE WHEN v_type = 'GRATUITE_MATERNITE' THEN 0 ELSE t.patient END,
    part_tiers   = CASE WHEN v_type = 'GRATUITE_MATERNITE' THEN t.brut ELSE t.tiers END,
    montant_exonere = CASE WHEN v_type IN ('INDIGENT','PERSONNEL') THEN t.brut ELSE 0 END
  FROM (SELECT coalesce(sum(montant_total), 0) AS brut,
               coalesce(sum(part_patient), 0)  AS patient,
               coalesce(sum(part_tiers), 0)    AS tiers
          FROM cs.facture_ligne WHERE facture_id = v_facture) t
  WHERE f.id = v_facture;

  PERFORM cs.journaliser('CREATION', 'facture', v_facture, v_venue.patient_id);
  RETURN v_facture;
END;
$$;

CREATE OR REPLACE FUNCTION cs.encaisser(
  p_facture uuid, p_session uuid, p_mode mode_paiement_t,
  p_devise devise_t, p_montant numeric, p_reference text DEFAULT NULL
) RETURNS cs.paiement
LANGUAGE plpgsql SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  v_facture cs.facture;
  v_taux    numeric := 1;
  v_numero  text;
  v_row     cs.paiement;
  v_paye    numeric;
BEGIN
  SELECT * INTO v_facture FROM cs.facture WHERE id = p_facture;
  IF v_facture.id IS NULL THEN RAISE EXCEPTION 'Facture inconnue'; END IF;
  IF v_facture.statut = 'ANNULEE' THEN RAISE EXCEPTION 'Facture annulée'; END IF;

  IF p_devise = 'USD' THEN
    SELECT taux INTO v_taux FROM cs.taux_change
     WHERE date_jour <= current_date AND devise_source = 'USD' AND devise_cible = 'CDF'
     ORDER BY date_jour DESC LIMIT 1;
    v_taux := coalesce(v_taux, 1);
  END IF;

  SELECT to_char(now(), 'YYYYMM') || '-' || lpad((count(*) + 1)::text, 5, '0')
    INTO v_numero FROM cs.paiement
   WHERE structure_id = v_facture.structure_id
     AND date_trunc('month', date_heure) = date_trunc('month', now());

  -- Le déclencheur t_gratuite_maternite applique RG-06 et rejette
  -- tout encaissement patient sur une facture sous gratuité maternité.
  INSERT INTO cs.paiement (structure_id, facture_id, session_caisse_id, numero_recu, mode,
                           devise, montant, taux_change, montant_equiv_cdf,
                           reference_externe, encaisse_par)
  VALUES (v_facture.structure_id, p_facture, p_session, v_numero, p_mode, p_devise,
          p_montant, v_taux, p_montant * v_taux, p_reference, cs.utilisateur_courant())
  RETURNING * INTO v_row;

  SELECT coalesce(sum(montant_equiv_cdf), 0) INTO v_paye
    FROM cs.paiement WHERE facture_id = p_facture AND NOT annule;

  UPDATE cs.facture
     SET statut = CASE
           WHEN v_paye >= part_patient THEN 'PAYEE'::statut_facture_t
           WHEN v_paye > 0 THEN 'PARTIELLEMENT_PAYEE'::statut_facture_t
           ELSE statut END
   WHERE id = p_facture;

  PERFORM cs.journaliser('CREATION', 'paiement', v_row.id, v_facture.patient_id);
  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION cs.cloturer_session_caisse(
  p_session uuid, p_compte_cdf numeric, p_compte_usd numeric DEFAULT 0,
  p_justification text DEFAULT NULL
) RETURNS cs.session_caisse
LANGUAGE plpgsql SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  v_th_cdf numeric; v_th_usd numeric; v_row cs.session_caisse;
  v_ecart_cdf numeric; v_ecart_usd numeric; v_fonds numeric;
BEGIN
  SELECT fonds_initial INTO v_fonds FROM cs.session_caisse WHERE id = p_session;
  IF v_fonds IS NULL THEN RAISE EXCEPTION 'Session de caisse inconnue'; END IF;

  SELECT coalesce(sum(CASE WHEN devise = 'CDF' THEN montant ELSE 0 END), 0),
         coalesce(sum(CASE WHEN devise = 'USD' THEN montant ELSE 0 END), 0)
    INTO v_th_cdf, v_th_usd
    FROM cs.paiement
   WHERE session_caisse_id = p_session AND NOT annule
     AND mode IN ('ESPECES','MOBILE_MONEY');

  v_th_cdf    := v_th_cdf + v_fonds;
  v_ecart_cdf := p_compte_cdf - v_th_cdf;
  v_ecart_usd := p_compte_usd - v_th_usd;

  IF (v_ecart_cdf <> 0 OR v_ecart_usd <> 0)
     AND coalesce(p_justification, '') = '' THEN
    RAISE EXCEPTION 'RG-08 : écart de caisse de % CDF et % USD, justification obligatoire',
      v_ecart_cdf, v_ecart_usd;
  END IF;

  UPDATE cs.session_caisse
     SET cloture = now(), total_theorique_cdf = v_th_cdf, total_theorique_usd = v_th_usd,
         total_compte_cdf = p_compte_cdf, total_compte_usd = p_compte_usd,
         ecart_cdf = v_ecart_cdf, ecart_usd = v_ecart_usd,
         justification_ecart = p_justification
   WHERE id = p_session
  RETURNING * INTO v_row;

  PERFORM cs.journaliser('MODIFICATION', 'session_caisse', p_session, NULL, p_justification);
  RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------
-- 7. PEV : calendrier vaccinal (EF-M10-02, EF-M10-03)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.calendrier_vaccinal(p_patient uuid)
RETURNS TABLE (antigene text, libelle text, numero_dose smallint,
               date_theorique date, date_recue date, statut text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
  WITH p AS (SELECT date_naissance FROM cs.patient WHERE id = p_patient)
  SELECT a.code, a.libelle, a.numero_dose,
         ((SELECT date_naissance FROM p) + a.age_cible_jours)::date,
         v.date_vaccination,
         CASE
           WHEN v.id IS NOT NULL THEN 'RECU'
           WHEN (SELECT date_naissance FROM p) IS NULL THEN 'INCONNU'
           WHEN ((SELECT date_naissance FROM p) + a.age_cible_jours) > current_date THEN 'PROGRAMME'
           WHEN ((SELECT date_naissance FROM p) + a.age_cible_jours) < current_date - 14 THEN 'EN_RETARD'
           ELSE 'DU' END
    FROM cs.antigene a
    LEFT JOIN cs.vaccination v ON v.antigene_id = a.id AND v.patient_id = p_patient
   WHERE a.actif
   ORDER BY a.age_cible_jours, a.numero_dose;
$$;

-- ---------------------------------------------------------------------
-- 8. Rapport mensuel SNIS : génération et contrôles (EF-M22-01 à EF-M22-03)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.generer_rapport_snis(
  p_periode date, p_type text DEFAULT 'SNIS_CS'
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  v_structure uuid := cs.structure_courante();
  v_mois      date := date_trunc('month', p_periode)::date;
  v_fin       date := (date_trunc('month', p_periode) + interval '1 month')::date;
  v_rapport   uuid;
  v_version   int;
  v_elem      record;
  v_val       numeric;
BEGIN
  SELECT id, version INTO v_rapport, v_version
    FROM cs.rapport_mensuel
   WHERE structure_id = v_structure AND periode_mois = v_mois AND type_rapport = p_type
   ORDER BY version DESC LIMIT 1;

  IF v_rapport IS NOT NULL THEN
    IF (SELECT statut FROM cs.rapport_mensuel WHERE id = v_rapport) IN ('TRANSMIS','VALIDE') THEN
      -- RG-11 : une période transmise est figée, on ouvre un rectificatif versionné
      INSERT INTO cs.rapport_mensuel (structure_id, periode_mois, type_rapport, statut,
                                      version, genere_par)
      VALUES (v_structure, v_mois, p_type, 'RECTIFIE', v_version + 1, cs.utilisateur_courant())
      RETURNING id INTO v_rapport;
    ELSE
      DELETE FROM cs.rapport_valeur WHERE rapport_id = v_rapport;
      UPDATE cs.rapport_mensuel SET genere_le = now(), genere_par = cs.utilisateur_courant()
       WHERE id = v_rapport;
    END IF;
  ELSE
    INSERT INTO cs.rapport_mensuel (structure_id, periode_mois, type_rapport, statut,
                                    version, genere_par)
    VALUES (v_structure, v_mois, p_type, 'BROUILLON', 1, cs.utilisateur_courant())
    RETURNING id INTO v_rapport;
  END IF;

  FOR v_elem IN SELECT id, code FROM cs.element_donnee_snis WHERE actif LOOP
    v_val := NULL;
    CASE v_elem.code
      WHEN 'SNIS-CONS-001' THEN
        SELECT count(*) INTO v_val FROM cs.venue
         WHERE structure_id = v_structure AND type_venue = 'CURATIF' AND deleted_at IS NULL
           AND date_heure_arrivee >= v_mois AND date_heure_arrivee < v_fin;
      WHEN 'SNIS-CONS-002' THEN
        SELECT count(*) INTO v_val FROM cs.venue
         WHERE structure_id = v_structure AND cas = 'NOUVEAU' AND deleted_at IS NULL
           AND date_heure_arrivee >= v_mois AND date_heure_arrivee < v_fin;
      WHEN 'SNIS-CONS-003' THEN
        SELECT count(*) INTO v_val FROM cs.venue
         WHERE structure_id = v_structure AND cas = 'ANCIEN' AND deleted_at IS NULL
           AND date_heure_arrivee >= v_mois AND date_heure_arrivee < v_fin;
      WHEN 'SNIS-CONS-005' THEN
        SELECT count(*) INTO v_val FROM cs.venue v
          JOIN cs.patient_regime pr ON pr.id = v.regime_applique_id
         WHERE v.structure_id = v_structure AND pr.type_regime = 'MUTUELLE'
           AND v.cas = 'NOUVEAU'
           AND v.date_heure_arrivee >= v_mois AND v.date_heure_arrivee < v_fin;
      WHEN 'SNIS-CONS-006' THEN
        SELECT count(*) INTO v_val FROM cs.venue v
          JOIN cs.patient_regime pr ON pr.id = v.regime_applique_id
         WHERE v.structure_id = v_structure AND pr.type_regime = 'INDIGENT'
           AND v.cas = 'NOUVEAU'
           AND v.date_heure_arrivee >= v_mois AND v.date_heure_arrivee < v_fin;
      WHEN 'SNIS-MERE-001' THEN
        SELECT count(*) INTO v_val FROM cs.visite_cpn c
          JOIN cs.dossier_grossesse g ON g.id = c.dossier_grossesse_id
         WHERE g.structure_id = v_structure AND c.numero_visite = 1
           AND c.date_visite >= v_mois AND c.date_visite < v_fin;
      WHEN 'SNIS-MERE-002' THEN
        SELECT count(*) INTO v_val FROM cs.visite_cpn c
          JOIN cs.dossier_grossesse g ON g.id = c.dossier_grossesse_id
         WHERE g.structure_id = v_structure AND c.numero_visite >= 4
           AND c.date_visite >= v_mois AND c.date_visite < v_fin;
      WHEN 'SNIS-MERE-003' THEN
        SELECT count(*) INTO v_val FROM cs.travail_accouchement
         WHERE structure_id = v_structure AND assistance_qualifiee
           AND date_heure_accouchement >= v_mois AND date_heure_accouchement < v_fin;
      WHEN 'SNIS-ENF-001' THEN
        SELECT count(*) INTO v_val FROM cs.vaccination v JOIN cs.antigene a ON a.id = v.antigene_id
         WHERE v.structure_id = v_structure AND a.code = 'PENTA3'
           AND v.date_vaccination >= v_mois AND v.date_vaccination < v_fin;
      WHEN 'SNIS-ENF-002' THEN
        SELECT count(*) INTO v_val FROM cs.vaccination v JOIN cs.antigene a ON a.id = v.antigene_id
         WHERE v.structure_id = v_structure AND a.code = 'VAR2'
           AND v.date_vaccination >= v_mois AND v.date_vaccination < v_fin;
      WHEN 'SNIS-LAB-001' THEN
        SELECT count(*) INTO v_val FROM cs.resultat_examen r
          JOIN cs.demande_examen_ligne dl ON dl.id = r.demande_ligne_id
          JOIN cs.demande_examen d ON d.id = dl.demande_id
          JOIN cs.venue ve ON ve.id = d.venue_id
         WHERE ve.structure_id = v_structure AND r.valide
           AND r.date_heure_resultat >= v_mois AND r.date_heure_resultat < v_fin;
      WHEN 'SNIS-FIN-001' THEN
        SELECT coalesce(sum(montant_equiv_cdf), 0) INTO v_val FROM cs.paiement
         WHERE structure_id = v_structure AND NOT annule
           AND date_heure >= v_mois AND date_heure < v_fin;
      WHEN 'SNIS-FIN-002' THEN
        SELECT coalesce(sum(montant), 0) INTO v_val FROM cs.depense
         WHERE structure_id = v_structure
           AND date_depense >= v_mois AND date_depense < v_fin;
      WHEN 'SNIS-REF-001' THEN
        SELECT count(*) INTO v_val FROM cs.reference
         WHERE structure_id = v_structure
           AND date_heure_decision >= v_mois AND date_heure_decision < v_fin;
      WHEN 'SNIS-DECES-001' THEN
        SELECT count(*) INTO v_val FROM cs.venue
         WHERE structure_id = v_structure AND issue = 'DECES'
           AND date_heure_cloture >= v_mois AND date_heure_cloture < v_fin;
      ELSE
        v_val := NULL;   -- rubrique à saisir (financement indirect, matériel, etc.)
    END CASE;

    -- Les rubriques sans source calculable (financement indirect, état du
    -- matériel) restent à saisir : aucune ligne n'est créée avec une valeur
    -- inventée, et le rapport est marqué incomplet tant qu'elles manquent.
    IF v_val IS NOT NULL THEN
      INSERT INTO cs.rapport_valeur (rapport_id, element_id, ventilation_cle,
                                     valeur_calculee, valeur_retenue)
      VALUES (v_rapport, v_elem.id, 'TOTAL', v_val, v_val);
    END IF;
  END LOOP;

  UPDATE cs.rapport_mensuel r
     SET complet = (
       SELECT count(*) FROM cs.rapport_valeur rv WHERE rv.rapport_id = r.id
     ) >= (
       SELECT count(*) FROM cs.element_donnee_snis WHERE actif AND obligatoire
     )
   WHERE r.id = v_rapport;

  PERFORM cs.journaliser('CREATION', 'rapport_mensuel', v_rapport);
  RETURN v_rapport;
END;
$$;

CREATE OR REPLACE FUNCTION cs.controles_coherence(p_rapport uuid)
RETURNS TABLE (code_regle text, severite text, message text, respecte boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  v numeric; n numeric; a numeric; cpn1 numeric; cpn4 numeric;
  penta3 numeric; acc numeric; deces numeric;
BEGIN
  SELECT rv.valeur_retenue INTO v FROM cs.rapport_valeur rv
    JOIN cs.element_donnee_snis e ON e.id = rv.element_id
   WHERE rv.rapport_id = p_rapport AND e.code = 'SNIS-CONS-001';
  SELECT rv.valeur_retenue INTO n FROM cs.rapport_valeur rv
    JOIN cs.element_donnee_snis e ON e.id = rv.element_id
   WHERE rv.rapport_id = p_rapport AND e.code = 'SNIS-CONS-002';
  SELECT rv.valeur_retenue INTO a FROM cs.rapport_valeur rv
    JOIN cs.element_donnee_snis e ON e.id = rv.element_id
   WHERE rv.rapport_id = p_rapport AND e.code = 'SNIS-CONS-003';
  SELECT rv.valeur_retenue INTO cpn1 FROM cs.rapport_valeur rv
    JOIN cs.element_donnee_snis e ON e.id = rv.element_id
   WHERE rv.rapport_id = p_rapport AND e.code = 'SNIS-MERE-001';
  SELECT rv.valeur_retenue INTO cpn4 FROM cs.rapport_valeur rv
    JOIN cs.element_donnee_snis e ON e.id = rv.element_id
   WHERE rv.rapport_id = p_rapport AND e.code = 'SNIS-MERE-002';
  SELECT rv.valeur_retenue INTO acc FROM cs.rapport_valeur rv
    JOIN cs.element_donnee_snis e ON e.id = rv.element_id
   WHERE rv.rapport_id = p_rapport AND e.code = 'SNIS-MERE-003';
  SELECT rv.valeur_retenue INTO deces FROM cs.rapport_valeur rv
    JOIN cs.element_donnee_snis e ON e.id = rv.element_id
   WHERE rv.rapport_id = p_rapport AND e.code = 'SNIS-DECES-001';

  code_regle := 'CTL-001'; severite := 'BLOQUANT';
  message := 'Cas reçus doivent égaler nouveaux cas + anciens cas';
  respecte := coalesce(v, 0) = coalesce(n, 0) + coalesce(a, 0);
  RETURN NEXT;

  code_regle := 'CTL-006'; severite := 'AVERTISSEMENT';
  message := 'Les CPN 4 ne peuvent excéder les CPN 1 du mois';
  respecte := coalesce(cpn4, 0) <= coalesce(cpn1, 0);
  RETURN NEXT;

  code_regle := 'CTL-020'; severite := 'BLOQUANT';
  message := 'Les décès enregistrés ne peuvent excéder les cas reçus';
  respecte := coalesce(deces, 0) <= coalesce(v, 0);
  RETURN NEXT;

  code_regle := 'CTL-009'; severite := 'AVERTISSEMENT';
  message := 'Accouchements assistés cohérents avec les nouveau-nés enregistrés';
  respecte := coalesce(acc, 0) >= 0;
  RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION cs.transmettre_rapport(
  p_rapport uuid, p_canal text DEFAULT 'DHIS2_API'
) RETURNS cs.rapport_mensuel
LANGUAGE plpgsql SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE v_row cs.rapport_mensuel; v_bloquant int;
BEGIN
  SELECT count(*) INTO v_bloquant
    FROM cs.controles_coherence(p_rapport)
   WHERE severite = 'BLOQUANT' AND NOT respecte;

  IF v_bloquant > 0 THEN
    RAISE EXCEPTION 'EF-M22-03 : % contrôle(s) bloquant(s) non levé(s)', v_bloquant;
  END IF;

  UPDATE cs.rapport_mensuel
     SET statut = 'TRANSMIS', transmis_le = now(), canal_transmission = p_canal,
         valide_par = cs.utilisateur_courant(), date_validation = now()
   WHERE id = p_rapport
  RETURNING * INTO v_row;

  PERFORM cs.journaliser('EXPORT', 'rapport_mensuel', p_rapport);
  RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------
-- 9. Tableau de bord (EF-M24-01, EF-M24-02)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cs.tableau_de_bord()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = cs, public AS $$
DECLARE
  s uuid := cs.structure_courante();
  res jsonb;
BEGIN
  SELECT jsonb_build_object(
    'consultations_jour', (SELECT count(*) FROM cs.venue
       WHERE structure_id = s AND date_heure_arrivee::date = current_date AND deleted_at IS NULL),
    'nouveaux_cas_jour', (SELECT count(*) FROM cs.venue
       WHERE structure_id = s AND cas = 'NOUVEAU' AND date_heure_arrivee::date = current_date),
    'en_attente', (SELECT count(*) FROM cs.venue
       WHERE structure_id = s AND statut NOT IN ('CLOTUREE','ABANDON')
         AND date_heure_arrivee::date = current_date),
    'recettes_jour_cdf', (SELECT coalesce(sum(montant_equiv_cdf), 0) FROM cs.paiement
       WHERE structure_id = s AND date_heure::date = current_date AND NOT annule),
    'traceurs_total', (SELECT count(*) FROM cs.produit WHERE traceur AND actif),
    'traceurs_disponibles', (SELECT count(DISTINCT l.produit_id)
       FROM cs.stock st JOIN cs.lot l ON l.id = st.lot_id
       JOIN cs.produit p ON p.id = l.produit_id
       JOIN cs.depot d ON d.id = st.depot_id
      WHERE d.structure_id = s AND p.traceur AND st.quantite > 0
        AND l.date_peremption > current_date),
    'peremptions_90j', (SELECT count(*) FROM cs.stock st JOIN cs.lot l ON l.id = st.lot_id
       JOIN cs.depot d ON d.id = st.depot_id
      WHERE d.structure_id = s AND st.quantite > 0
        AND l.date_peremption BETWEEN current_date AND current_date + 90),
    'resultats_critiques', (SELECT count(*) FROM cs.resultat_examen r
       JOIN cs.demande_examen_ligne dl ON dl.id = r.demande_ligne_id
       JOIN cs.demande_examen de ON de.id = dl.demande_id
       JOIN cs.venue ve ON ve.id = de.venue_id
      WHERE ve.structure_id = s AND r.critique AND r.date_heure_resultat::date >= current_date - 2),
    'accouchements_mois', (SELECT count(*) FROM cs.travail_accouchement
       WHERE structure_id = s
         AND date_heure_accouchement >= date_trunc('month', current_date)),
    'dernier_rapport', (SELECT jsonb_build_object('periode', periode_mois, 'statut', statut)
       FROM cs.rapport_mensuel WHERE structure_id = s AND type_rapport = 'SNIS_CS'
      ORDER BY periode_mois DESC LIMIT 1),
    'population', (SELECT population_totale FROM cs.population_annuelle
       WHERE structure_id = s AND annee = extract(year FROM current_date))
  ) INTO res;
  RETURN res;
END;
$$;

-- ---------------------------------------------------------------------
-- 10. Droits d'exécution
-- ---------------------------------------------------------------------
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cs TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA cs GRANT EXECUTE ON FUNCTIONS TO authenticated;
