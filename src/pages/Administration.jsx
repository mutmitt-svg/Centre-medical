import { useEffect, useState } from 'react'
import { api } from '../lib/api.js'
import { demo } from '../lib/demo.js'
import { useDonnees } from '../lib/useDonnees.js'
import { Card, Table, Tag, Note, Champ } from '../components/ui.jsx'
import { dateHeure } from '../lib/format.js'
import { useAuth } from '../context/AuthContext.jsx'

const QUALIFICATIONS = [
  'MEDECIN', 'INFIRMIER_L2', 'INFIRMIER_A1', 'INFIRMIER_A2', 'SAGE_FEMME', 'ACCOUCHEUSE',
  'NUTRITIONNISTE', 'TECH_LABO', 'PHARMACIEN', 'ADMINISTRATIF', 'CAISSIER', 'TECHNICIEN', 'AUTRE'
]

const VIDE = { nom: '', postNom: '', prenom: '', qualification: 'ADMINISTRATIF', login: '', email: '', motDePasse: '', roleCode: '' }

export default function Administration() {
  const { profil, peut, modeDemo } = useAuth()

  const { donnees: utilisateurs, chargement: chargementUtilisateurs, recharger } = useDonnees(
    () => modeDemo ? Promise.resolve(demo.utilisateurs) : api.listerUtilisateurs(),
    { repli: demo.utilisateurs, deps: [modeDemo] }
  )
  const { donnees: audit } = useDonnees(
    () => modeDemo ? Promise.resolve(demo.audit) : api.audit(50),
    { repli: demo.audit, deps: [modeDemo] }
  )

  const lignesUtilisateurs = modeDemo ? utilisateurs : (utilisateurs || []).map((u) => ({
    login: u.login,
    nom: u.agent ? [u.agent.nom, u.agent.post_nom, u.agent.prenom].filter(Boolean).join(' ') : u.login,
    qualification: u.agent?.qualification || '—',
    roles: (u.roles || []).map((r) => r.role?.libelle).filter(Boolean).join(', ') || '—',
    actif: u.actif
  }))

  return (
    <>
      {!peut('AUDIT_LIRE') && (
        <Note ton="alerte" titre="Accès partiel">
          Votre profil ne permet pas la lecture du journal d'audit.
        </Note>
      )}

      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre="Comptes et rôles" className="lg:col-span-2">
          <Table
            colonnes={[
              { cle: 'login', titre: 'Identifiant' },
              { cle: 'nom', titre: 'Agent' },
              { cle: 'qualification', titre: 'Qualification' },
              { cle: 'roles', titre: 'Rôles' },
              { cle: 'actif', titre: 'État', rendu: (l) => <Tag ton={l.actif ? 'ok' : 'danger'}>{l.actif ? 'Actif' : 'Suspendu'}</Tag> }
            ]}
            lignes={lignesUtilisateurs}
            vide={chargementUtilisateurs ? 'Chargement…' : 'Aucun compte'}
          />
        </Card>

        <Card titre="Profil connecté">
          <p className="font-semibold text-13.5">{profil?.nom}</p>
          <p className="text-[12px] text-ink-3">{profil?.qualification} — {profil?.structure}</p>
          <div className="sec">Permissions</div>
          <div className="flex flex-wrap gap-1">
            {(profil?.permissions || []).map((p) => <Tag key={p} ton="neutre">{p}</Tag>)}
          </div>
        </Card>
      </div>

      {peut('UTILISATEUR_GERER') && !modeDemo && (
        <FormulaireNouveauCompte onCree={recharger} />
      )}
      {peut('UTILISATEUR_GERER') && modeDemo && (
        <Note ton="accent" titre="Mode découverte">
          La création de comptes est désactivée en mode découverte ; elle sera disponible une fois la base connectée.
        </Note>
      )}

      <Card titre="Journal d'audit">
        <Table
          colonnes={[
            { cle: 'horodatage', titre: 'Horodatage', rendu: (l) => dateHeure(l.horodatage) },
            { cle: 'utilisateur', titre: 'Utilisateur' },
            { cle: 'action', titre: 'Action', rendu: (l) => (
                <Tag ton={l.action === 'BRIS_DE_GLACE' ? 'danger' : 'neutre'}>{l.action}</Tag>) },
            { cle: 'entite', titre: 'Objet' },
            { cle: 'justification', titre: 'Justification' }
          ]}
          lignes={audit}
        />
        <p className="text-[11.5px] text-ink-3 mt-2">
          Le journal est en ajout seul : la modification et la suppression de ses lignes sont refusées par la base.
        </p>
      </Card>
    </>
  )
}

/**
 * Création d'un compte additionnel par un administrateur déjà connecté.
 * Passe par une fonction Edge (droits élevés côté serveur) pour ne jamais
 * exposer la clé service_role au navigateur, et pour ne pas remplacer la
 * session de l'administrateur en cours par celle du nouveau compte.
 */
function FormulaireNouveauCompte({ onCree }) {
  const [roles, setRoles] = useState([])
  const [form, setForm] = useState(VIDE)
  const [envoi, setEnvoi] = useState(false)
  const [message, setMessage] = useState(null)

  useEffect(() => {
    api.listerRoles().then(setRoles).catch(() => setRoles([]))
  }, [])

  const champ = (cle) => (e) => setForm((f) => ({ ...f, [cle]: e.target.value }))

  const soumettre = async (e) => {
    e.preventDefault()
    setMessage(null)
    setEnvoi(true)
    try {
      await api.creerUtilisateur({
        nom: form.nom, postNom: form.postNom, prenom: form.prenom, qualification: form.qualification,
        login: form.login, email: form.email, motDePasse: form.motDePasse, roleCode: form.roleCode
      })
      setMessage({ ton: 'ok', texte: `Compte ${form.login} créé. Communiquez-lui son mot de passe temporaire de façon sécurisée.` })
      setForm(VIDE)
      onCree?.()
    } catch (err) {
      setMessage({ ton: 'danger', texte: err.message })
    } finally {
      setEnvoi(false)
    }
  }

  return (
    <Card titre="Créer un compte">
      {message && <div className="mb-3"><Note ton={message.ton}>{message.texte}</Note></div>}
      <form onSubmit={soumettre} className="grid gap-3 md:grid-cols-3">
        <Champ libelle="Nom"><input value={form.nom} onChange={champ('nom')} required /></Champ>
        <Champ libelle="Post-nom"><input value={form.postNom} onChange={champ('postNom')} /></Champ>
        <Champ libelle="Prénom"><input value={form.prenom} onChange={champ('prenom')} /></Champ>

        <Champ libelle="Qualification">
          <select value={form.qualification} onChange={champ('qualification')}>
            {QUALIFICATIONS.map((q) => <option key={q} value={q}>{q}</option>)}
          </select>
        </Champ>
        <Champ libelle="Rôle applicatif">
          <select value={form.roleCode} onChange={champ('roleCode')} required>
            <option value="" disabled>Choisir…</option>
            {roles.map((r) => <option key={r.code} value={r.code}>{r.libelle}</option>)}
          </select>
        </Champ>
        <Champ libelle="Identifiant de connexion" aide="Sans espace, ex. j.mukendi">
          <input value={form.login} onChange={champ('login')} required />
        </Champ>

        <Champ libelle="Adresse e-mail">
          <input type="email" value={form.email} onChange={champ('email')} required />
        </Champ>
        <Champ libelle="Mot de passe temporaire" aide="Communiqué à l'agent, à changer à sa première connexion">
          <input type="password" value={form.motDePasse} onChange={champ('motDePasse')} minLength={8} required />
        </Champ>
        <div className="flex items-end">
          <button className="btn btn-p w-full" disabled={envoi}>{envoi ? 'Création…' : 'Créer le compte'}</button>
        </div>
      </form>
    </Card>
  )
}
