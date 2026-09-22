-- Généré depuis schema_centre_sante.sql v1.0 — ne pas éditer à la main sans mettre à jour la source.
SET search_path TO public;

-- ---------------------------------------------------------------------
-- 23. VUES DE CALCUL (agrégats dérivés, jamais saisis)
-- ---------------------------------------------------------------------

-- Consommation moyenne mensuelle sur 3 mois glissants (EF-M07-04)
CREATE OR REPLACE VIEW v_cmm_3mois AS
SELECT m.structure_id,
       l.produit_id,
       round(sum(m.quantite) / 3.0, 2) AS cmm
FROM mouvement_stock m
JOIN lot l ON l.id = m.lot_id
WHERE m.type = 'SORTIE'
  AND m.date_mouvement >= (date_trunc('month', current_date) - interval '3 months')
  AND m.date_mouvement <  date_trunc('month', current_date)
GROUP BY m.structure_id, l.produit_id;

-- Stock disponible utilisable : hors lots périmés (EF-M07-02)
CREATE OR REPLACE VIEW v_sdu AS
SELECT d.structure_id,
       l.produit_id,
       sum(s.quantite) AS sdu
FROM stock s
JOIN depot d ON d.id = s.depot_id
JOIN lot l   ON l.id = s.lot_id
WHERE l.date_peremption IS NULL OR l.date_peremption > current_date
GROUP BY d.structure_id, l.produit_id;

-- Base du registre de consultation curative (EF-M04-05)
CREATE OR REPLACE VIEW v_registre_consultation AS
SELECT v.structure_id,
       v.numero_venue,
       v.date_heure_arrivee::date AS date_consultation,
       p.numero_dossier,
       trim(concat_ws(' ', p.nom, p.post_nom, p.prenom)) AS identite,
       p.sexe,
       CASE WHEN p.date_naissance IS NOT NULL
            THEN date_part('year', age(v.date_heure_arrivee, p.date_naissance))
            ELSE p.age_declare_annees END AS age_ans,
       vil.nom AS village,
       v.cas,
       p.provenance,
       dr.code_cim10,
       dr.libelle AS diagnostic,
       v.issue,
       u.login AS prestataire
FROM venue v
JOIN patient p ON p.id = v.patient_id
LEFT JOIN village vil ON vil.id = p.village_id
LEFT JOIN consultation c ON c.venue_id = v.id AND c.deleted_at IS NULL
LEFT JOIN consultation_diagnostic cd ON cd.consultation_id = c.id AND cd.principal
LEFT JOIN diagnostic_ref dr ON dr.id = cd.diagnostic_id
LEFT JOIN utilisateur u ON u.id = c.praticien_id
WHERE v.deleted_at IS NULL;

-- Agrégat mensuel des consultations avec ventilations exigées par le canevas SNIS
CREATE OR REPLACE VIEW v_snis_consultations AS
SELECT v.structure_id,
       date_trunc('month', v.date_heure_arrivee)::date AS periode_mois,
       count(*)                                                                AS cas_recus,
       count(*) FILTER (WHERE v.cas = 'NOUVEAU')                                AS nouveaux_cas,
       count(*) FILTER (WHERE v.cas = 'ANCIEN')                                 AS anciens_cas,
       count(*) FILTER (WHERE p.sexe = 'F')                                     AS feminin,
       count(*) FILTER (WHERE p.sexe = 'M')                                     AS masculin,
       count(*) FILTER (WHERE p.date_naissance IS NOT NULL
                          AND v.date_heure_arrivee < p.date_naissance + interval '5 years') AS moins_5_ans,
       count(*) FILTER (WHERE pr.type_regime = 'MUTUELLE')                      AS nouveaux_cas_mutualistes,
       count(*) FILTER (WHERE pr.type_regime = 'INDIGENT')                      AS nouveaux_cas_indigents
FROM venue v
JOIN patient p ON p.id = v.patient_id
LEFT JOIN patient_regime pr ON pr.id = v.regime_applique_id
WHERE v.deleted_at IS NULL AND v.type_venue = 'CURATIF'
GROUP BY v.structure_id, date_trunc('month', v.date_heure_arrivee);

-- Recettes du jour par service et mode de paiement (EF-M15-09)
CREATE OR REPLACE VIEW v_recettes_jour AS
SELECT pa.structure_id,
       pa.date_heure::date AS date_jour,
       pa.mode,
       pa.devise,
       sum(pa.montant) FILTER (WHERE NOT pa.annule) AS total
FROM paiement pa
GROUP BY pa.structure_id, pa.date_heure::date, pa.mode, pa.devise;

-- Couverture vaccinale par antigène (dénominateur population, EF-M24-02)
CREATE OR REPLACE VIEW v_couverture_pev AS
SELECT vac.structure_id,
       date_trunc('month', vac.date_vaccination)::date AS periode_mois,
       a.code AS antigene,
       count(*) AS doses_administrees,
       pop.enfants_0_11_mois,
       CASE WHEN pop.enfants_0_11_mois > 0
            THEN round(100.0 * count(*) / (pop.enfants_0_11_mois / 12.0), 2) END AS couverture_pourcent
FROM vaccination vac
JOIN antigene a ON a.id = vac.antigene_id
LEFT JOIN population_annuelle pop
       ON pop.structure_id = vac.structure_id
      AND pop.annee = date_part('year', vac.date_vaccination)
GROUP BY vac.structure_id, date_trunc('month', vac.date_vaccination), a.code, pop.enfants_0_11_mois;
