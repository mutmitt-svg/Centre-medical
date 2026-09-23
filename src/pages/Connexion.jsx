import { useState } from 'react'
import { useAuth } from '../context/AuthContext.jsx'
import { structureNom, structureCode } from '../lib/supabase.js'
import { Note } from '../components/ui.jsx'

export default function Connexion() {
  const { connexion, erreur, modeDemo, compteExiste, creerComptePrincipal } = useAuth()
  const [login, setLogin] = useState(modeDemo ? 'm.kabeya' : '')
  const [motDePasse, setMotDePasse] = useState('')
  const [envoi, setEnvoi] = useState(false)

  const soumettre = async (e) => {
    e.preventDefault()
    setEnvoi(true)
    try { await connexion(login, motDePasse) } catch { /* message géré par le contexte */ }
    finally { setEnvoi(false) }
  }

  // Aucun compte applicatif n'existe encore sur cette base : on propose de
  // créer le compte administrateur principal plutôt que le formulaire de
  // connexion habituel.
  if (!modeDemo && compteExiste === false) {
    return <CreationComptePrincipal creerComptePrincipal={creerComptePrincipal} erreur={erreur} />
  }

  return (
    <div className="min-h-full grid place-items-center p-4">
      <form onSubmit={soumettre} className="card w-full max-w-sm">
        <div className="px-4 py-4 border-b border-line">
          <h1 className="text-base font-bold">{structureNom}</h1>
          <p className="text-[12px] text-ink-3">Code SNIS {structureCode} — Zone de santé de Lubumbashi</p>
        </div>
        <div className="p-4">
          {erreur && <div className="mb-3"><Note ton="danger">{erreur}</Note></div>}
          {modeDemo && (
            <div className="mb-3">
              <Note ton="alerte" titre="Mode découverte">
                La base n'est pas configurée. Validez pour explorer l'application avec le jeu de démonstration.
              </Note>
            </div>
          )}
          <div className="mb-3">
            <label htmlFor="login">Identifiant</label>
            <input id="login" value={login} onChange={(e) => setLogin(e.target.value)} autoComplete="username" required />
          </div>
          <div className="mb-4">
            <label htmlFor="mdp">Mot de passe</label>
            <input id="mdp" type="password" value={motDePasse} onChange={(e) => setMotDePasse(e.target.value)}
                   autoComplete="current-password" required={!modeDemo} />
          </div>
          <button className="btn btn-p w-full" disabled={envoi}>
            {envoi ? 'Vérification…' : 'Ouvrir la session'}
          </button>
          <p className="text-[11.5px] text-ink-3 mt-3">
            Trois échecs consécutifs verrouillent temporairement le compte. Toute connexion est journalisée.
          </p>
        </div>
      </form>
    </div>
  )
}

/**
 * Formulaire affiché uniquement tant qu'aucun compte applicatif n'existe.
 * Il crée à la fois l'identité Supabase Auth (auto-inscription) et le
 * dossier « utilisateur » qui lui est rattaché, avec le rôle Administrateur
 * système — toutes les permissions, y compris la création des autres
 * comptes depuis le menu Administration.
 */
function CreationComptePrincipal({ creerComptePrincipal, erreur }) {
  const [nomComplet, setNomComplet] = useState('')
  const [email, setEmail] = useState('')
  const [motDePasse, setMotDePasse] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [envoi, setEnvoi] = useState(false)
  const [messageConfirmation, setMessageConfirmation] = useState(null)
  const [erreurLocale, setErreurLocale] = useState(null)

  const soumettre = async (e) => {
    e.preventDefault()
    setErreurLocale(null)
    if (motDePasse !== confirmation) { setErreurLocale('Les deux mots de passe ne correspondent pas.'); return }
    if (motDePasse.length < 8) { setErreurLocale('Le mot de passe doit contenir au moins 8 caractères.'); return }
    setEnvoi(true)
    try {
      const r = await creerComptePrincipal(email, motDePasse, nomComplet)
      if (r?.confirmationRequise) {
        setMessageConfirmation("Un e-mail de confirmation a été envoyé à cette adresse. Cliquez sur le lien reçu, puis revenez vous connecter avec cet identifiant et ce mot de passe : le compte administrateur sera terminé automatiquement.")
      }
    } catch { /* message géré par le contexte ou erreurLocale */ }
    finally { setEnvoi(false) }
  }

  return (
    <div className="min-h-full grid place-items-center p-4">
      <form onSubmit={soumettre} className="card w-full max-w-sm">
        <div className="px-4 py-4 border-b border-line">
          <h1 className="text-base font-bold">{structureNom}</h1>
          <p className="text-[12px] text-ink-3">Code SNIS {structureCode} — Zone de santé de Lubumbashi</p>
        </div>
        <div className="p-4">
          <div className="mb-3">
            <Note ton="accent" titre="Premier accès">
              Aucun compte n'existe encore sur cette base. Créez le compte administrateur principal ;
              vous pourrez ensuite créer les autres comptes depuis le menu Administration de l'application.
            </Note>
          </div>
          {(erreurLocale || erreur) && <div className="mb-3"><Note ton="danger">{erreurLocale || erreur}</Note></div>}
          {messageConfirmation
            ? <Note ton="ok">{messageConfirmation}</Note>
            : (
              <>
                <div className="mb-3">
                  <label htmlFor="nom">Nom complet</label>
                  <input id="nom" value={nomComplet} onChange={(e) => setNomComplet(e.target.value)} required />
                </div>
                <div className="mb-3">
                  <label htmlFor="email">Adresse e-mail</label>
                  <input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" required />
                </div>
                <div className="mb-3">
                  <label htmlFor="mdp1">Mot de passe</label>
                  <input id="mdp1" type="password" value={motDePasse} onChange={(e) => setMotDePasse(e.target.value)}
                         autoComplete="new-password" minLength={8} required />
                </div>
                <div className="mb-4">
                  <label htmlFor="mdp2">Confirmer le mot de passe</label>
                  <input id="mdp2" type="password" value={confirmation} onChange={(e) => setConfirmation(e.target.value)}
                         autoComplete="new-password" minLength={8} required />
                </div>
                <button className="btn btn-p w-full" disabled={envoi}>
                  {envoi ? 'Création…' : 'Créer le compte administrateur'}
                </button>
              </>
            )}
        </div>
      </form>
    </div>
  )
}
