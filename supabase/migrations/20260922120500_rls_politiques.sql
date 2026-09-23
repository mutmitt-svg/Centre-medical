-- =====================================================================
-- Sécurité au niveau des lignes (RLS) — cloisonnement par structure,
-- habilitations fines et protection des données sensibles.
-- Exigences : EF-M25-01, EF-M25-02, EF-M25-03, EF-M25-09, EF-M26-05.
-- =====================================================================
SET search_path TO public;

-- ---------------------------------------------------------------------
-- 1. Liaison entre un compte Supabase Auth et un utilisateur métier
-- ---------------------------------------------------------------------
ALTER TABLE utilisateur ADD COLUMN IF NOT EXISTS auth_user_id uuid UNIQUE;

COMMENT ON COLUMN utilisateur.auth_user_id IS
  'Identifiant du compte Supabase Auth associé. Renseigné à la création du compte.';

-- ---------------------------------------------------------------------
-- 2. Fonctions d''aide (SECURITY DEFINER, non modifiables par l''appelant)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.utilisateur_courant() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id FROM public.utilisateur u
  WHERE u.auth_user_id = auth.uid() AND u.actif
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.structure_courante() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.structure_id FROM public.utilisateur u
  WHERE u.auth_user_id = auth.uid() AND u.actif
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.a_permission(p_code text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.utilisateur u
    JOIN public.utilisateur_role ur ON ur.utilisateur_id = u.id
    JOIN public.role_permission rp  ON rp.role_id = ur.role_id
    JOIN public.permission p        ON p.id = rp.permission_id
    WHERE u.auth_user_id = auth.uid() AND u.actif AND p.code = p_code
  );
$$;

CREATE OR REPLACE FUNCTION public.permissions_courantes() RETURNS text[]
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(array_agg(DISTINCT p.code), '{}')
  FROM public.utilisateur u
  JOIN public.utilisateur_role ur ON ur.utilisateur_id = u.id
  JOIN public.role_permission rp  ON rp.role_id = ur.role_id
  JOIN public.permission p        ON p.id = rp.permission_id
  WHERE u.auth_user_id = auth.uid() AND u.actif;
$$;

-- Journalisation applicative appelable depuis le client (EF-M02-11, EF-M25-03)
CREATE OR REPLACE FUNCTION public.journaliser(
  p_action text, p_entite text, p_entite_id uuid DEFAULT NULL,
  p_patient_id uuid DEFAULT NULL, p_justification text DEFAULT NULL,
  p_poste text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.journal_audit(structure_id, utilisateur_id, action, entite, entite_id,
                               patient_id, justification, poste)
  VALUES (public.structure_courante(), public.utilisateur_courant(),
          p_action::public.action_audit_t, p_entite,
          p_entite_id, p_patient_id, p_justification, p_poste);
END;
$$;

-- ---------------------------------------------------------------------
-- 3. Activation de RLS sur toutes les tables du schéma
--    RLS est activé sans FORCE : le rôle propriétaire (migrations, seed,
--    service_role) conserve l'accès administratif nécessaire.
-- ---------------------------------------------------------------------
DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.tablename);
  END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 4. Référentiels partagés : lecture pour tout utilisateur authentifié,
--    écriture réservée à la permission REFERENTIEL_ECRIRE (EF-M01-11)
-- ---------------------------------------------------------------------
DO $$
DECLARE t text;
  refs text[] := ARRAY['province','zone_sante','aire_sante','village','diagnostic_ref',
    'examen_ref','produit','acte','antigene','methode_pf','programme','compte_comptable',
    'element_donnee_snis','indicateur_fbp','permission','role','role_permission','protocole',
    'taux_change'];
BEGIN
  FOREACH t IN ARRAY refs LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename=t) THEN
      EXECUTE format($f$
        CREATE POLICY %1$I_lecture ON public.%1$I FOR SELECT TO authenticated
          USING (public.utilisateur_courant() IS NOT NULL);
        CREATE POLICY %1$I_ecriture ON public.%1$I FOR ALL TO authenticated
          USING (public.a_permission('REFERENTIEL_ECRIRE'))
          WITH CHECK (public.a_permission('REFERENTIEL_ECRIRE'));
      $f$, t);
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 5. Tables métier portant structure_id : cloisonnement par structure
-- ---------------------------------------------------------------------
DO $$
DECLARE t record;
BEGIN
  FOR t IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN pg_tables pt ON pt.schemaname = 'public' AND pt.tablename=c.table_name
    WHERE c.table_schema='public' AND c.column_name='structure_id'
      AND c.table_name NOT IN ('journal_audit','utilisateur')
  LOOP
    EXECUTE format($f$
      CREATE POLICY %1$I_structure_select ON public.%1$I FOR SELECT TO authenticated
        USING (structure_id = public.structure_courante());
      CREATE POLICY %1$I_structure_insert ON public.%1$I FOR INSERT TO authenticated
        WITH CHECK (structure_id = public.structure_courante());
      CREATE POLICY %1$I_structure_update ON public.%1$I FOR UPDATE TO authenticated
        USING (structure_id = public.structure_courante())
        WITH CHECK (structure_id = public.structure_courante());
    $f$, t.table_name);
  END LOOP;
END $$;

-- Aucune politique DELETE n'est créée : la suppression physique est interdite
-- (EF-M25-04). Les tables exposent une colonne deleted_at pour la suppression
-- logique motivée, tracée par le journal d'audit.

-- ---------------------------------------------------------------------
-- 6. Tables filles sans structure_id : héritage par la table parente
-- ---------------------------------------------------------------------
CREATE POLICY consultation_parent ON public.consultation FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.venue v WHERE v.id = consultation.venue_id
                 AND v.structure_id = public.structure_courante()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.venue v WHERE v.id = consultation.venue_id
                 AND v.structure_id = public.structure_courante()));

CREATE POLICY consultation_diagnostic_parent ON public.consultation_diagnostic FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.consultation c JOIN public.venue v ON v.id = c.venue_id
                 WHERE c.id = consultation_diagnostic.consultation_id
                   AND v.structure_id = public.structure_courante()))
  WITH CHECK (true);

CREATE POLICY facture_ligne_parent ON public.facture_ligne FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.facture f WHERE f.id = facture_ligne.facture_id
                 AND f.structure_id = public.structure_courante()))
  WITH CHECK (true);

CREATE POLICY triage_parent ON public.triage FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.venue v WHERE v.id = triage.venue_id
                 AND v.structure_id = public.structure_courante()))
  WITH CHECK (true);

CREATE POLICY stock_depot ON public.stock FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.depot d WHERE d.id = stock.depot_id
                 AND d.structure_id = public.structure_courante()))
  WITH CHECK (true);

CREATE POLICY lot_lecture ON public.lot FOR SELECT TO authenticated
  USING (public.utilisateur_courant() IS NOT NULL);
CREATE POLICY lot_ecriture ON public.lot FOR INSERT TO authenticated
  WITH CHECK (public.a_permission('STOCK_ECRIRE'));

CREATE POLICY tarif_lecture ON public.tarif FOR SELECT TO authenticated
  USING (structure_id IS NULL OR structure_id = public.structure_courante());
CREATE POLICY tarif_ecriture ON public.tarif FOR INSERT TO authenticated
  WITH CHECK (public.a_permission('TARIF_ECRIRE'));

CREATE POLICY rapport_valeur_parent ON public.rapport_valeur FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.rapport_mensuel r WHERE r.id = rapport_valeur.rapport_id
                 AND r.structure_id = public.structure_courante()))
  WITH CHECK (true);

-- ---------------------------------------------------------------------
-- 7. Utilisateurs, rôles et journal d'audit
-- ---------------------------------------------------------------------
CREATE POLICY utilisateur_soi ON public.utilisateur FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid() OR public.a_permission('UTILISATEUR_LIRE'));
CREATE POLICY utilisateur_admin ON public.utilisateur FOR ALL TO authenticated
  USING (public.a_permission('UTILISATEUR_ECRIRE'))
  WITH CHECK (public.a_permission('UTILISATEUR_ECRIRE'));

CREATE POLICY utilisateur_role_lecture ON public.utilisateur_role FOR SELECT TO authenticated
  USING (utilisateur_id = public.utilisateur_courant() OR public.a_permission('UTILISATEUR_LIRE'));
CREATE POLICY utilisateur_role_admin ON public.utilisateur_role FOR ALL TO authenticated
  USING (public.a_permission('UTILISATEUR_ECRIRE'))
  WITH CHECK (public.a_permission('UTILISATEUR_ECRIRE'));

-- Le journal est lisible par les profils habilités, jamais modifiable :
-- les règles r_audit_no_update / r_audit_no_delete bloquent déjà toute écriture.
CREATE POLICY audit_lecture ON public.journal_audit FOR SELECT TO authenticated
  USING (structure_id = public.structure_courante() AND public.a_permission('AUDIT_LIRE'));
CREATE POLICY audit_insertion ON public.journal_audit FOR INSERT TO authenticated
  WITH CHECK (structure_id = public.structure_courante());

-- ---------------------------------------------------------------------
-- 8. Données sensibles : masquage renforcé (EF-M25-09)
-- ---------------------------------------------------------------------
-- Une consultation marquée sensible n'est lisible qu'avec la permission dédiée
-- ou par son auteur. La politique restrictive s'ajoute aux politiques ci-dessus.
CREATE POLICY consultation_sensible ON public.consultation AS RESTRICTIVE
  FOR SELECT TO authenticated
  USING (NOT sensible
         OR public.a_permission('DOSSIER_SENSIBLE_LIRE')
         OR praticien_id = public.utilisateur_courant());

DO $$
DECLARE t text;
  sensibles text[] := ARRAY['ptme_suivi','inclusion_programme','suivi_programme','contact_depistage'];
BEGIN
  FOREACH t IN ARRAY sensibles LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename=t) THEN
      EXECUTE format($f$
        CREATE POLICY %1$I_sensible ON public.%1$I AS RESTRICTIVE FOR SELECT TO authenticated
          USING (public.a_permission('DOSSIER_SENSIBLE_LIRE'));
      $f$, t);
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 9. Droits d'accès au schéma
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE ON TABLES TO authenticated;

-- Le rôle anon n'a aucun droit : aucune donnée de santé n'est accessible
-- sans authentification.
REVOKE ALL ON SCHEMA public FROM anon;
