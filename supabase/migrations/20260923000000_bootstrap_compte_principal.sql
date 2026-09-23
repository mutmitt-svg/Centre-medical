-- ===========================================================================
-- Bootstrap du compte administrateur principal.
--
-- Objectif : permettre de créer le tout premier compte applicatif depuis
-- l'écran de connexion (auto-inscription), sans passer par SQL Editor, tout
-- en empêchant que n'importe qui puisse s'auto-promouvoir administrateur une
-- fois ce premier compte créé. Les comptes suivants sont créés depuis le
-- menu Administration de l'application, par un compte qui a déjà la
-- permission UTILISATEUR_GERER (voir la fonction Edge « creer-utilisateur »).
-- ===========================================================================

SET search_path TO public;

-- Vrai si un compte applicatif est déjà relié à une identité Supabase Auth.
-- Appelable sans être connecté : sert à décider, sur l'écran de connexion,
-- s'il faut proposer la création du compte principal ou le formulaire de
-- connexion classique. Ne renvoie aucune donnée sensible.
CREATE OR REPLACE FUNCTION compte_principal_existe()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM utilisateur WHERE auth_user_id IS NOT NULL);
$$;

GRANT EXECUTE ON FUNCTION compte_principal_existe() TO anon, authenticated;

-- Crée le compte applicatif du tout premier administrateur, relié à
-- l'identité Supabase Auth actuellement connectée (auth.uid()). Refuse si un
-- compte principal existe déjà, afin qu'un seul bootstrap soit possible ;
-- passé ce stade, les comptes se créent via le menu Administration.
CREATE OR REPLACE FUNCTION creer_compte_principal(
  p_nom_complet    text,
  p_nom_structure  text DEFAULT NULL,
  p_code_structure text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_structure_id  uuid;
  v_role_id       uuid;
  v_agent_id      uuid;
  v_utilisateur_id uuid;
  v_login         text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Connexion requise avant de créer le compte principal.';
  END IF;

  IF EXISTS (SELECT 1 FROM utilisateur WHERE auth_user_id IS NOT NULL) THEN
    RAISE EXCEPTION 'Un compte principal existe déjà. Demandez à un administrateur de vous créer un compte.';
  END IF;

  -- Réutilise la structure existante (jeu de démonstration ou déploiement
  -- déjà initialisé) ; en crée une minimale sinon, pour un tout premier
  -- déploiement sans donnée de départ.
  SELECT id INTO v_structure_id FROM structure ORDER BY created_at LIMIT 1;
  IF v_structure_id IS NULL THEN
    INSERT INTO structure (code_snis, nom)
    VALUES (coalesce(p_code_structure, 'CS-001'), coalesce(p_nom_structure, 'Centre de Santé'))
    RETURNING id INTO v_structure_id;
  END IF;

  SELECT id INTO v_role_id FROM role WHERE code = 'ADMIN';

  v_login := lower(regexp_replace(split_part(coalesce(auth.jwt() ->> 'email', 'admin'), '@', 1), '[^a-z0-9._-]', '', 'g'));
  IF v_login = '' OR v_login IS NULL THEN v_login := 'admin'; END IF;

  INSERT INTO agent (structure_id, matricule, nom, post_nom, prenom, qualification, fonction, statut, date_entree)
  VALUES (v_structure_id, 'ADM-' || substr(auth.uid()::text, 1, 8), p_nom_complet, '', '',
          'ADMINISTRATIF', 'Administrateur système', 'Fonctionnaire', current_date)
  RETURNING id INTO v_agent_id;

  INSERT INTO utilisateur (agent_id, structure_id, login, mot_de_passe_hash, doit_changer_mdp, auth_user_id)
  VALUES (v_agent_id, v_structure_id, v_login, 'GERE_PAR_SUPABASE_AUTH', false, auth.uid())
  RETURNING id INTO v_utilisateur_id;

  IF v_role_id IS NOT NULL THEN
    INSERT INTO utilisateur_role (utilisateur_id, role_id) VALUES (v_utilisateur_id, v_role_id);
  END IF;

  RETURN v_utilisateur_id;
END;
$$;

GRANT EXECUTE ON FUNCTION creer_compte_principal(text, text, text) TO authenticated;
