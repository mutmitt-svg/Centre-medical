import { useState } from 'react'
import { api } from '../lib/api.js'
import { demo } from '../lib/demo.js'
import { Card, Table, Champ, Note, Tag } from '../components/ui.jsx'
import { useAuth } from '../context/AuthContext.jsx'

const VIDE = {
  nom: '', post_nom: '', prenom: '', sexe: 'F', date_naissance: '', telephone: '',
  village: '', provenance: 'AIRE_SANTE', consentement_donnees: true
}

export default function Patients() {
  const { modeDemo, peut } = useAuth()
  const [recherche, setRecherche] = useState('')
  const [resultats, setResultats] = useState(demo.patients)
  const [form, setForm] = useState(VIDE)
  const [doublons, setDoublons] = useState([])
  const [message, setMessage] = useState(null)

  const chercher = async (e) => {
    e.preventDefault()
    try {
      const r = modeDemo
        ? demo.patients.filter((p) => p.nom_complet.toLowerCase().includes(recherche.toLowerCase()))
        : await api.rechercherPatient(recherche)
      setResultats(r)
    } catch (err) { setMessage({ ton: 'danger', texte: err.message }) }
  }

  const verifierDoublons = async () => {
    if (!form.nom) return
    try {
      const r = modeDemo
        ? demo.patients.filter((p) => p.nom_complet.toUpperCase().includes(form.nom.toUpperCase()))
            .map((p) => ({ ...p, score: 0.6 }))
        : await api.doublons({
            p_nom: form.nom, p_post_nom: form.post_nom, p_prenom: form.prenom,
            p_sexe: form.sexe, p_date_naissance: form.date_naissance || null
          })
      setDoublons(r)
      setMessage(r.length
        ? { ton: 'alerte', texte: `${r.length} dossier(s) proche(s) détecté(s) : vérifiez avant de créer.` }
        : { ton: 'ok', texte: 'Aucun doublon probable, la création peut se poursuivre.' })
    } catch (err) { setMessage({ ton: 'danger', texte: err.message }) }
  }

  return (
    <>
      {message && <Note ton={message.ton}>{message.texte}</Note>}
      <div className="grid gap-3.5 lg:grid-cols-2">
        <Card titre="Rechercher un dossier">
          <form onSubmit={chercher} className="flex gap-2 mb-3">
            <input placeholder="Nom approximatif, numéro de dossier, téléphone"
                   value={recherche} onChange={(e) => setRecherche(e.target.value)} />
            <button className="btn btn-p shrink-0">Chercher</button>
          </form>
          <Table
            colonnes={[
              { cle: 'numero_dossier', titre: 'Dossier' },
              { cle: 'nom_complet', titre: 'Identité' },
              { cle: 'sexe', titre: 'Sexe' },
              { cle: 'age_affiche', titre: 'Âge' },
              { cle: 'village', titre: 'Village' },
              { cle: 'score', titre: 'Pertinence', num: true, rendu: (l) => Number(l.score || 0).toFixed(2) }
            ]}
            lignes={resultats}
            vide="Lancez une recherche"
          />
          <p className="text-[11.5px] text-ink-3 mt-2">
            La recherche tolère les fautes d'orthographe et ignore les accents : « Moukendi » retrouve « MUKENDI ».
          </p>
        </Card>

        <Card titre="Créer un dossier" actions={<Tag ton={peut('PATIENT_ECRIRE') ? 'ok' : 'danger'}>
            {peut('PATIENT_ECRIRE') ? 'Droit accordé' : 'Droit manquant'}</Tag>}>
          <div className="grid sm:grid-cols-2 gap-x-3">
            <Champ libelle="Nom"><input value={form.nom} onChange={(e) => setForm({ ...form, nom: e.target.value })} /></Champ>
            <Champ libelle="Post-nom"><input value={form.post_nom} onChange={(e) => setForm({ ...form, post_nom: e.target.value })} /></Champ>
            <Champ libelle="Prénom"><input value={form.prenom} onChange={(e) => setForm({ ...form, prenom: e.target.value })} /></Champ>
            <Champ libelle="Sexe">
              <select value={form.sexe} onChange={(e) => setForm({ ...form, sexe: e.target.value })}>
                <option value="F">Féminin</option><option value="M">Masculin</option>
              </select>
            </Champ>
            <Champ libelle="Date de naissance" aide="À défaut, saisir l'âge déclaré.">
              <input type="date" value={form.date_naissance} onChange={(e) => setForm({ ...form, date_naissance: e.target.value })} />
            </Champ>
            <Champ libelle="Téléphone"><input value={form.telephone} onChange={(e) => setForm({ ...form, telephone: e.target.value })} /></Champ>
            <Champ libelle="Village ou quartier"><input value={form.village} onChange={(e) => setForm({ ...form, village: e.target.value })} /></Champ>
            <Champ libelle="Provenance">
              <select value={form.provenance} onChange={(e) => setForm({ ...form, provenance: e.target.value })}>
                <option value="AIRE_SANTE">Aire de santé</option>
                <option value="HORS_AIRE_ZS">Hors aire, même zone de santé</option>
                <option value="HORS_ZS">Hors zone de santé</option>
              </select>
            </Champ>
          </div>
          <label className="flex items-center gap-2 mb-3 text-[12.5px] font-normal">
            <input type="checkbox" className="w-auto" checked={form.consentement_donnees}
                   onChange={(e) => setForm({ ...form, consentement_donnees: e.target.checked })} />
            Consentement au traitement des données recueilli
          </label>
          <div className="flex gap-2">
            <button className="btn" onClick={verifierDoublons}>Vérifier les doublons</button>
            <button className="btn btn-p" disabled={!peut('PATIENT_ECRIRE')}>Créer le dossier</button>
          </div>
          {doublons.length > 0 && (
            <div className="mt-3">
              <Table
                colonnes={[
                  { cle: 'numero_dossier', titre: 'Dossier' },
                  { cle: 'nom_complet', titre: 'Identité' },
                  { cle: 'score', titre: 'Similarité', num: true, rendu: (l) => Number(l.score).toFixed(2) }
                ]}
                lignes={doublons}
              />
            </div>
          )}
        </Card>
      </div>
    </>
  )
}
