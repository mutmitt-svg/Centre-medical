import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { supabase, supabaseConfigure } from '../lib/supabase.js'

const Ctx = createContext(null)

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

  useEffect(() => {
    if (!supabaseConfigure || !session) { if (supabaseConfigure) setProfil(null); return }
    let actif = true
    ;(async () => {
      const { data, error } = await supabase
        .from('utilisateur')
        .select('id, login, actif, structure:structure_id (nom, code_snis), agent:agent_id (nom, post_nom, prenom, qualification)')
        .eq('auth_user_id', session.user.id)
        .maybeSingle()
      if (!actif) return
      if (error) { setErreur(error.message); return }
      if (!data) { setErreur("Aucun compte applicatif rattaché à cette identité. Contactez l'administrateur."); return }
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
    })()
    return () => { actif = false }
  }, [session])

  const connexion = async (login, motDePasse) => {
    setErreur(null)
    if (!supabaseConfigure) { setProfil(PROFIL_DEMO); return { demo: true } }
    const courriel = login.includes('@') ? login : `${login}@${import.meta.env.VITE_DOMAINE_COMPTES || 'cs-kamalondo.cd'}`
    const { error } = await supabase.auth.signInWithPassword({ email: courriel, password: motDePasse })
    if (error) { setErreur('Identifiants invalides ou compte verrouillé.'); throw error }
    return { ok: true }
  }

  const deconnexion = async () => {
    if (supabaseConfigure) await supabase.auth.signOut()
    setProfil(supabaseConfigure ? null : PROFIL_DEMO)
    setSession(null)
  }

  const peut = (code) => Boolean(profil?.permissions?.includes(code))

  const valeur = useMemo(
    () => ({ session, profil, chargement, erreur, connexion, deconnexion, peut, modeDemo: !supabaseConfigure }),
    [session, profil, chargement, erreur]
  )
  return <Ctx.Provider value={valeur}>{children}</Ctx.Provider>
}

export const useAuth = () => useContext(Ctx)
