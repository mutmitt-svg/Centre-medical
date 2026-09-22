import { useState } from 'react'
import { api } from '../lib/api.js'
import { demo } from '../lib/demo.js'
import { Card, Table, Tag, Note } from '../components/ui.jsx'
import { nombre, moisLibelle, periodeMois } from '../lib/format.js'
import { useAuth } from '../context/AuthContext.jsx'

export default function Snis() {
  const { modeDemo, peut } = useAuth()
  const [periode, setPeriode] = useState(periodeMois())
  const [rapport, setRapport] = useState(demo.rapport)
  const [message, setMessage] = useState(null)

  const generer = async () => {
    setMessage(null)
    if (modeDemo) { setRapport({ ...demo.rapport, periode }); return }
    try {
      const id = await api.genererRapport(periode)
      const controles = await api.controles(id)
      setRapport({ id, periode, statut: 'BROUILLON', valeurs: demo.rapport.valeurs, controles })
      setMessage({ ton: 'ok', texte: 'Rapport généré à partir des données saisies dans les registres.' })
    } catch (e) { setMessage({ ton: 'danger', texte: e.message }) }
  }

  const bloquants = (rapport.controles || []).filter((c) => c.severite === 'BLOQUANT' && !c.respecte)

  return (
    <>
      {message && <Note ton={message.ton}>{message.texte}</Note>}

      <Card
        titre={`Rapport mensuel — ${moisLibelle(rapport.periode)}`}
        actions={
          <div className="flex items-center gap-2">
            <input type="month" className="w-40"
                   value={String(rapport.periode).slice(0, 7)}
                   onChange={(e) => setPeriode(`${e.target.value}-01`)} />
            <button className="btn btn-sm" onClick={generer}>Générer</button>
            <Tag ton={rapport.statut === 'TRANSMIS' ? 'ok' : 'alerte'}>{rapport.statut}</Tag>
          </div>
        }
      >
        <Table
          cle="code"
          colonnes={[
            { cle: 'code', titre: 'Élément' },
            { cle: 'libelle', titre: 'Libellé' },
            { cle: 'valeur', titre: 'Valeur calculée', num: true, rendu: (l) => nombre(l.valeur) },
            { cle: 'correction', titre: 'Valeur retenue', num: true, rendu: (l) => (
                <input className="w-28 text-right" defaultValue={l.valeur} />) }
          ]}
          lignes={rapport.valeurs}
        />
        <p className="text-[11.5px] text-ink-3 mt-2">
          Toute valeur retenue différente de la valeur calculée exige un commentaire, conservé avec le rapport.
        </p>
      </Card>

      <Card titre="Contrôles de cohérence">
        <Table
          cle="code_regle"
          colonnes={[
            { cle: 'code_regle', titre: 'Règle' },
            { cle: 'message', titre: 'Contrôle' },
            { cle: 'severite', titre: 'Sévérité', rendu: (l) => (
                <Tag ton={l.severite === 'BLOQUANT' ? 'danger' : 'alerte'}>{l.severite}</Tag>) },
            { cle: 'respecte', titre: 'Résultat', rendu: (l) => (
                <Tag ton={l.respecte ? 'ok' : 'danger'}>{l.respecte ? 'Conforme' : 'À corriger'}</Tag>) }
          ]}
          lignes={rapport.controles}
        />
        <div className="flex items-center gap-2 mt-3">
          <button className="btn">Exporter en PDF</button>
          <button className="btn">Exporter le fichier d'import DHIS2</button>
          <button className="btn btn-p" disabled={bloquants.length > 0 || !peut('RAPPORT_VALIDER')}>
            Valider et transmettre
          </button>
          {bloquants.length > 0 && <Tag ton="danger">{bloquants.length} contrôle(s) bloquant(s)</Tag>}
        </div>
      </Card>
    </>
  )
}
