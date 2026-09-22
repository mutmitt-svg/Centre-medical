import { useState } from 'react'
import { api } from '../lib/api.js'
import { demo } from '../lib/demo.js'
import { useDonnees } from '../lib/useDonnees.js'
import { Card, Table, Tag, Champ, Note } from '../components/ui.jsx'
import { attente } from '../lib/format.js'
import { useAuth } from '../context/AuthContext.jsx'

const TYPES = ['CURATIF', 'PREVENTIF', 'URGENCE', 'SUIVI', 'MATERNITE', 'LABO_SEUL', 'PHARMACIE_SEULE']
const PRIORITES = ['ROUTINE', 'REFERE', 'URGENCE']

export default function Accueil() {
  const { modeDemo } = useAuth()
  const { donnees: file, recharger } = useDonnees(() => api.fileAttente(), { repli: demo.file })
  const [recherche, setRecherche] = useState('')
  const [resultats, setResultats] = useState([])
  const [choisi, setChoisi] = useState(null)
  const [form, setForm] = useState({ type: 'CURATIF', priorite: 'ROUTINE', motif: '' })
  const [message, setMessage] = useState(null)

  const chercher = async (e) => {
    e.preventDefault()
    setMessage(null)
    try {
      const r = modeDemo
        ? demo.patients.filter((p) => p.nom_complet.toLowerCase().includes(recherche.toLowerCase()) || p.numero_dossier.includes(recherche))
        : await api.rechercherPatient(recherche)
      setResultats(r)
      if (r.length === 0) setMessage({ ton: 'alerte', texte: 'Aucun dossier trouvé. Créez un nouveau dossier depuis l\'écran Dossiers patients.' })
    } catch (err) { setMessage({ ton: 'danger', texte: err.message }) }
  }

  const enregistrer = async () => {
    if (!choisi) return
    try {
      const r = await api.enregistrerVenue({
        p_patient: choisi.id, p_type: form.type, p_motif: form.motif, p_priorite: form.priorite
      })
      setMessage({
        ton: 'ok',
        texte: r?.differe
          ? "Venue enregistrée hors ligne : elle sera transmise à la reconnexion."
          : `Venue ${r?.numero_venue || ''} enregistrée, jeton ${r?.numero_jeton ?? ''}.`
      })
      setChoisi(null); setForm({ type: 'CURATIF', priorite: 'ROUTINE', motif: '' }); recharger()
    } catch (err) { setMessage({ ton: 'danger', texte: err.message }) }
  }

  return (
    <>
      {message && <Note ton={message.ton}>{message.texte}</Note>}

      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre="Identifier le patient">
          <form onSubmit={chercher} className="flex gap-2 mb-3">
            <input placeholder="Nom, numéro de dossier ou téléphone"
                   value={recherche} onChange={(e) => setRecherche(e.target.value)} />
            <button className="btn btn-p shrink-0">Chercher</button>
          </form>
          <ul className="flex flex-col gap-1.5">
            {resultats.map((p) => (
              <li key={p.id}>
                <button onClick={() => setChoisi(p)}
                        className={`w-full text-left px-2.5 py-2 rounded-sm2 border ${choisi?.id === p.id ? 'border-primary bg-primary-soft' : 'border-line hover:bg-surface-2'}`}>
                  <div className="font-semibold text-13.5">{p.nom_complet}</div>
                  <div className="text-[11.5px] text-ink-3">
                    Dossier {p.numero_dossier} — {p.sexe} — {p.age_affiche} — {p.village || '—'}
                  </div>
                </button>
              </li>
            ))}
          </ul>
        </Card>

        <Card titre="Enregistrer la venue">
          {!choisi && <p className="text-ink-3 text-13">Sélectionnez d'abord un dossier patient.</p>}
          {choisi && (
            <>
              <Note ton="accent" titre={choisi.nom_complet}>Dossier {choisi.numero_dossier}</Note>
              <div className="mt-3">
                <Champ libelle="Type de venue">
                  <select value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
                    {TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
                  </select>
                </Champ>
                <Champ libelle="Priorité" aide="Une urgence passe devant la file, un référé est prioritaire ensuite.">
                  <select value={form.priorite} onChange={(e) => setForm({ ...form, priorite: e.target.value })}>
                    {PRIORITES.map((t) => <option key={t} value={t}>{t}</option>)}
                  </select>
                </Champ>
                <Champ libelle="Motif de recours">
                  <textarea rows={3} value={form.motif} onChange={(e) => setForm({ ...form, motif: e.target.value })} />
                </Champ>
                <button className="btn btn-p w-full" onClick={enregistrer}>Enregistrer et délivrer le jeton</button>
                <p className="text-[11.5px] text-ink-3 mt-2">
                  Le caractère nouveau ou ancien cas est calculé automatiquement sur une fenêtre de 14 jours (règle RG-02).
                </p>
              </div>
            </>
          )}
        </Card>

        <Card titre="File du jour">
          <Table
            cle="venue_id"
            colonnes={[
              { cle: 'numero_jeton', titre: 'Jeton', num: true },
              { cle: 'nom_complet', titre: 'Patient' },
              { cle: 'cas', titre: 'Cas', rendu: (l) => <Tag ton={l.cas === 'NOUVEAU' ? 'primaire' : 'neutre'}>{l.cas}</Tag> },
              { cle: 'statut', titre: 'Étape' },
              { cle: 'attente_minutes', titre: 'Attente', num: true, rendu: (l) => attente(l.attente_minutes) }
            ]}
            lignes={file || []}
          />
        </Card>
      </div>
    </>
  )
}
