import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { supabase, supabaseConfigure, structureNom, structureCode } from '../lib/supabase.js'

const Ctx = createContext(null)
const CLE_NOM_EN_ATTENTE = 'csBootstrapNomComplet'

/** Profil de démonstration utilisé lorsque la base n'est pas encore reliée. */
const PROFIL_DEMO = {
  login: 'm.kabeya',
  nom: 'M. KABEYA Ilunga',
  qualification: 'Infirmier titulaire',
  structure: 'Centre de Santé Kamalondo',
  permissions: [
    'PATIENT_LIRE', 'PATIENT_ECRIRE', 'CONSULTATION_ECRIRE', 'LABO_LIRE', 'LABO_VALIDER',
    'PHARMACIE_DISPENSER', 'STOCK_ECRIRE', 'CAISSE_ENCAISSER', 'CAISSE_CLOTURER',
    'RAPPORT_GENERER', 'RAPPORT_VALIDER', 'REFERENTIEL_ECRIRE', 'AUDIT_LIRE',
    'DOSSIER_SENSIBLE_LIRE', 'UTILISATEUR_GERER'
  ]
}

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [profil, setProfil] = useState(supabaseConfigure ? null : PROFIL_DEMO)
  const [chargement, setChargement] = useState(supabaseConfigure)
  const [erreur, setErreur] = useState(null)
  // null = pas encore su ; true/false une fois vérifié auprès de la base.
  const [compteExiste, setCompteExiste] = useState(supabaseConfigure ? null : true)

  useEffect(() => {
    if (!supabaseConfigure) return
    let actif = true
    supabase.auth.getSession().then(({ data }) => {
      if (!actif) return
      setSession(data.session)
      setChargement(false)
    })
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => setSession(s))
    return () => { actif = false; sub.subscription.unsubscribe() }
  }, [])

  // Tant qu'aucune session n'est ouverte, on sait quand même si un compte
  // principal existe déjà, pour savoir quel écran proposer à la connexion.
  useEffect(() => {
    if (!supabaseConfigure || session) return
    let actif = true
    supabase.rpc('compte_principal_existe').then(({ data, error }) => {
      if (actif && !error) setCompteExiste(Boolean(data))
    })
    return () => { actif = false }
  }, [session])

  const chargerProfil = useCallback(async (s) => {
    const { data, error } = await supabase
      .from('utilisateur')
      .select('id, login, actif, structure:structure_id (nom, code_snis), agent:agent_id (nom, post_nom, prenom, qualification)')
      .eq('auth_user_id', s.user.id)
      .maybeSingle()
    if (error) { setErreur(error.message); return }

    if (!data) {
      // Aucun profil applicatif relié : si c'est la toute première identité
      // (bootstrap en attente de confirmation d'e-mail), on termine sa
      // création automatiquement avec le nom saisi lors de l'inscription.
      const { data: existeDeja } = await supabase.rpc('compte_principal_existe')
      const nomEnAttente = typeof window !== 'undefined' ? window.localStorage.getItem(CLE_NOM_EN_ATTENTE) : null
      if (!existeDeja && nomEnAttente) {
        const { error: erreurBootstrap } = await supabase.rpc('creer_compte_principal', {
          p_nom_complet: nomEnAttente, p_nom_structure: structureNom, p_code_structure: structureCode
        })
        window.localStorage.removeItem(CLE_NOM_EN_ATTENTE)
        if (!erreurBootstrap) { await chargerProfil(s); return }
        setErreur(erreurBootstrap.message)
        return
      }
      setErreur("Aucun compte applicatif rattaché à cette identité. Contactez l'administrateur.")
      return
    }

    setCompteExiste(true)
    const { data: perms } = await supabase.rpc('permissions_courantes')
    setProfil({
      id: data.id,
      login: data.login,
      nom: data.agent ? [data.agent.nom, data.agent.post_nom, data.agent.prenom].filter(Boolean).join(' ') : data.login,
      qualification: data.agent?.qualification || '—',
      structure: data.structure?.nom || '—',
      codeStructure: data.structure?.code_snis || '—',
      permissions: perms || []
    })
  }, [])

  useEffect(() => {
    if (!supabaseConfigure || !session) { if (supabaseConfigure) setProfil(null); return }
    let actif = true
    ;(async () => { if (actif) await chargerProfil(session) })()
    return () => { actif = false }
  }, [session, chargerProfil])

  const connexion = async (login, motDePasse) => {
    setErreur(null)
    if (!supabaseConfigure) { setProfil(PROFIL_DEMO); return { demo: true } }
    const courriel = login.includes('@') ? login : `${login}@${import.meta.env.VITE_DOMAINE_COMPTES || 'cs-kamalondo.cd'}`
    const { error } = await supabase.auth.signInWithPassword({ email: courriel, password: motDePasse })
    if (error) { setErreur('Identifiants invalides ou compte verrouillé.'); throw error }
    return { ok: true }
  }

  /**
   * Crée le tout premier compte administrateur, depuis l'écran de
   * connexion. Refusé côté base si un compte principal existe déjà.
   */
  const creerComptePrincipal = async (email, motDePasse, nomComplet) => {
    setErreur(null)
    if (!supabaseConfigure) throw new Error('Base non configurée.')
    window.localStorage.setItem(CLE_NOM_EN_ATTENTE, nomComplet)
    const { data, error } = await supabase.auth.signUp({ email, password: motDePasse })
    if (error) { window.localStorage.removeItem(CLE_NOM_EN_ATTENTE); setErreur(error.message); throw error }

    if (!data.session) {
      // Confirmation par e-mail exigée par le projet Supabase : le compte
      // applicatif sera terminé automatiquement à la première connexion,
      // une fois l'e-mail confirmé (voir chargerProfil).
      return { confirmationRequise: true }
    }

    const { error: erreurRpc } = await supabase.rpc('creer_compte_principal', {
      p_nom_complet: nomComplet, p_nom_structure: structureNom, p_code_structure: structureCode
    })
    window.localStorage.removeItem(CLE_NOM_EN_ATTENTE)
    if (erreurRpc) { setErreur(erreurRpc.message); throw erreurRpc }
    setSession(data.session)
    return { ok: true }
  }

  const deconnexion = async () => {
    if (supabaseConfigure) await supabase.auth.signOut()
    setProfil(supabaseConfigure ? null : PROFIL_DEMO)
    setSession(null)
  }

  const peut = (code) => Boolean(profil?.permissions?.includes(code))

  const valeur = useMemo(
    () => ({
      session, profil, chargement, erreur, connexion, deconnexion, peut,
      modeDemo: !supabaseConfigure, compteExiste, creerComptePrincipal
    }),
    [session, profil, chargement, erreur, compteExiste]
  )
  return <Ctx.Provider value={valeur}>{children}</Ctx.Provider>
}

export const useAuth = () => useContext(Ctx)
