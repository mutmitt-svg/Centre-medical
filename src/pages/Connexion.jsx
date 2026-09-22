import { useState } from 'react'
import { useAuth } from '../context/AuthContext.jsx'
import { structureNom, structureCode } from '../lib/supabase.js'
import { Note } from '../components/ui.jsx'

export default function Connexion() {
  const { connexion, erreur, modeDemo } = useAuth()
  const [login, setLogin] = useState(modeDemo ? 'm.kabeya' : '')
  const [motDePasse, setMotDePasse] = useState('')
  const [envoi, setEnvoi] = useState(false)

  const soumettre = async (e) => {
    e.preventDefault()
    setEnvoi(true)
    try { await connexion(login, motDePasse) } catch { /* message géré par le contexte */ }
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
