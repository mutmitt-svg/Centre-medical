import { api } from '../lib/api.js'
import { demo } from '../lib/demo.js'
import { useDonnees } from '../lib/useDonnees.js'
import { Card, Kpi, Table, Tag, Note, Jauge } from '../components/ui.jsx'
import { montant, nombre, moisLibelle, attente } from '../lib/format.js'

export default function TableauDeBord() {
  const { donnees: kpi } = useDonnees(() => api.tableauDeBord(), { repli: demo.tableauDeBord })
  const { donnees: file } = useDonnees(() => api.fileAttente(), { repli: demo.file })
  const d = kpi || demo.tableauDeBord

  const dispo = d.traceurs_total ? Math.round((d.traceurs_disponibles / d.traceurs_total) * 100) : 0

  return (
    <>
      <div className="grid gap-3.5 grid-cols-2 lg:grid-cols-4">
        <Kpi libelle="Cas reçus aujourd'hui" valeur={nombre(d.consultations_jour)}
             detail={`dont ${nombre(d.nouveaux_cas_jour)} nouveaux cas`} />
        <Kpi libelle="Patients en attente" valeur={nombre(d.en_attente)} detail="file du jour"
             ton={d.en_attente > 10 ? 'alerte' : 'neutre'} />
        <Kpi libelle="Recettes du jour" valeur={montant(d.recettes_jour_cdf)} detail="toutes modalités" />
        <Kpi libelle="Disponibilité traceurs" valeur={`${dispo} %`}
             detail={`${d.traceurs_disponibles}/${d.traceurs_total} produits`}
             ton={dispo < 90 ? 'alerte' : 'ok'} />
      </div>

      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre="File d'attente en cours" className="lg:col-span-2">
          <Table
            cle="venue_id"
            colonnes={[
              { cle: 'numero_jeton', titre: 'Jeton', num: true },
              { cle: 'nom_complet', titre: 'Patient' },
              { cle: 'age_affiche', titre: 'Âge' },
              { cle: 'motif', titre: 'Motif' },
              { cle: 'priorite', titre: 'Priorité', rendu: (l) => (
                  <Tag ton={l.priorite === 'URGENCE' ? 'danger' : l.priorite === 'REFERE' ? 'alerte' : 'neutre'}>{l.priorite}</Tag>
                ) },
              { cle: 'statut', titre: 'Étape', rendu: (l) => <Tag ton="accent">{l.statut}</Tag> },
              { cle: 'attente_minutes', titre: 'Attente', num: true, rendu: (l) => attente(l.attente_minutes) }
            ]}
            lignes={file || []}
            vide="Aucun patient en attente"
          />
        </Card>

        <div className="flex flex-col gap-3.5">
          <Card titre="Alertes du jour">
            <div className="flex flex-col gap-2">
              {d.resultats_critiques > 0 && (
                <Note ton="danger" titre={`${d.resultats_critiques} résultat(s) critique(s)`}>
                  À communiquer au prescripteur sans délai.
                </Note>
              )}
              {d.peremptions_90j > 0 && (
                <Note ton="alerte" titre={`${d.peremptions_90j} lot(s) expirant sous 90 jours`}>
                  Prioriser ces lots à la dispensation selon la règle FEFO.
                </Note>
              )}
              {d.traceurs_disponibles < d.traceurs_total && (
                <Note ton="alerte" titre="Ruptures de traceurs">
                  {d.traceurs_total - d.traceurs_disponibles} produit(s) traceur(s) indisponible(s) en stock utilisable.
                </Note>
              )}
              <Note ton="accent" titre="Rapport mensuel">
                Dernière période : {moisLibelle(d.dernier_rapport?.periode)} — statut {d.dernier_rapport?.statut || '—'}.
              </Note>
            </div>
          </Card>

          <Card titre="Population desservie">
            <p className="text-2xl font-bold">{nombre(d.population)}</p>
            <p className="text-[12px] text-ink-3 mb-3">habitants de l'aire de santé, année en cours</p>
            <div className="text-[12px] mb-1 flex justify-between">
              <span>Accouchements du mois</span><strong>{nombre(d.accouchements_mois)}</strong>
            </div>
            <Jauge valeur={d.accouchements_mois} max={Math.max(d.accouchements_mois, 30)} />
          </Card>
        </div>
      </div>
    </>
  )
}
