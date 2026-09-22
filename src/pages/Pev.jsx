import { demo } from '../lib/demo.js'
import { Card, Table, Tag, Jauge, Note } from '../components/ui.jsx'
import { dateCourte, nombre } from '../lib/format.js'

const TON = { RECU: 'ok', DU: 'alerte', EN_RETARD: 'danger', PROGRAMME: 'neutre', INCONNU: 'neutre' }

export default function Pev() {
  return (
    <>
      <Note ton="alerte" titre="Enfants à récupérer">
        Les doses en retard alimentent la liste de récupération, exportable pour les stratégies avancées et mobiles.
      </Note>

      <div className="grid gap-3.5 lg:grid-cols-2">
        <Card titre="Calendrier vaccinal — MBAYO Kalume Daniel, 4 mois">
          <Table
            cle="antigene"
            colonnes={[
              { cle: 'antigene', titre: 'Antigène' },
              { cle: 'libelle', titre: 'Libellé' },
              { cle: 'date_theorique', titre: 'Date théorique', rendu: (l) => dateCourte(l.date_theorique) },
              { cle: 'date_recue', titre: 'Date reçue', rendu: (l) => dateCourte(l.date_recue) },
              { cle: 'statut', titre: 'Statut', rendu: (l) => <Tag ton={TON[l.statut]}>{l.statut}</Tag> }
            ]}
            lignes={demo.pev}
          />
        </Card>

        <Card titre="Couverture vaccinale cumulée de l'année">
          <div className="flex flex-col gap-3">
            {demo.couverture.map((c) => (
              <div key={c.antigene}>
                <div className="flex justify-between text-[12.5px] mb-1">
                  <span className="font-semibold">{c.antigene}</span>
                  <span>{nombre(c.realise)} / {nombre(c.cible)} — {c.couverture} %</span>
                </div>
                <Jauge valeur={c.couverture} ton={c.couverture >= 90 ? 'ok' : c.couverture >= 70 ? 'alerte' : 'danger'} />
              </div>
            ))}
          </div>
          <p className="text-[11.5px] text-ink-3 mt-3">
            Les cibles annuelles sont calculées à partir de la population de l'aire de santé et des coefficients
            démographiques utilisés par la zone de santé.
          </p>
        </Card>
      </div>
    </>
  )
}
