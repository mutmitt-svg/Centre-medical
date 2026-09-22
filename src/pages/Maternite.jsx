import { demo } from '../lib/demo.js'
import { Card, Table, Note, Jauge } from '../components/ui.jsx'

export default function Maternite() {
  const { cpn, partogramme } = demo.maternite
  return (
    <>
      <Note ton="ok" titre="Gratuité des soins de la mère et du nouveau-né">
        Les prestations de consultation prénatale, d'accouchement et de suivi du nouveau-né sont facturées au
        programme, jamais à la patiente.
      </Note>

      <Card titre="Consultations prénatales suivies">
        <Table
          colonnes={[
            { cle: 'patient', titre: 'Patiente' },
            { cle: 'gestite', titre: 'Gestité' },
            { cle: 'ddr', titre: 'Dernières règles' },
            { cle: 'dpa', titre: 'Date prévue' },
            { cle: 'visite', titre: 'Visite', nowrap: true },
            { cle: 'ta', titre: 'Tension' },
            { cle: 'hu', titre: 'Hauteur utérine' },
            { cle: 'bcf', titre: 'Bruits du cœur' },
            { cle: 'vat', titre: 'Vaccin antitétanique' },
            { cle: 'tpi', titre: 'Traitement préventif' }
          ]}
          lignes={cpn}
        />
      </Card>

      <Card titre={`Partogramme — ${partogramme.patiente}`}>
        <Table
          cle="heure"
          colonnes={[
            { cle: 'heure', titre: 'Heure' },
            { cle: 'dilatation', titre: 'Dilatation (cm)', num: true },
            { cle: 'progression', titre: 'Progression', rendu: (l) => (
                <div className="w-40"><Jauge valeur={l.dilatation} max={10} ton={l.dilatation >= 10 ? 'ok' : 'primaire'} /></div>) },
            { cle: 'contractions', titre: 'Contractions' },
            { cle: 'bcf', titre: 'Bruits du cœur', num: true },
            { cle: 'ta', titre: 'Tension' }
          ]}
          lignes={partogramme.releves}
        />
        <p className="text-[11.5px] text-ink-3 mt-2">
          Une dilatation stagnante sur deux relevés consécutifs déclenche une alerte de dystocie et propose la
          référence vers la structure de référence.
        </p>
      </Card>
    </>
  )
}
