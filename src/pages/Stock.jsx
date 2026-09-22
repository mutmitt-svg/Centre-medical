import { api } from '../lib/api.js'
import { demo } from '../lib/demo.js'
import { useDonnees } from '../lib/useDonnees.js'
import { Card, Table, Tag, Note } from '../components/ui.jsx'
import { nombre, decimal, periodeMois } from '../lib/format.js'

export default function Stock() {
  const { donnees } = useDonnees(() => api.sigl(periodeMois()), { repli: demo.sigl })
  const lignes = donnees || demo.sigl

  return (
    <>
      <Note ton="accent" titre="Données essentielles du système de gestion logistique">
        Stock disponible utilisable, consommation, pertes et jours de rupture alimentent directement le rapport
        logistique mensuel et le calcul de la quantité à commander.
      </Note>

      <Card titre="Fiche de synthèse par produit">
        <Table
          cle="produit_id"
          colonnes={[
            { cle: 'code', titre: 'Code', nowrap: true },
            { cle: 'dci', titre: 'Dénomination commune' },
            { cle: 'traceur', titre: 'Traceur', rendu: (l) => (l.traceur ? <Tag ton="primaire">Oui</Tag> : '—') },
            { cle: 'sdu', titre: 'Stock utilisable', num: true, rendu: (l) => nombre(l.sdu) },
            { cle: 'consommation', titre: 'Consommation', num: true, rendu: (l) => nombre(l.consommation) },
            { cle: 'pertes', titre: 'Pertes', num: true, rendu: (l) => nombre(l.pertes) },
            { cle: 'jours_rupture', titre: 'Jours de rupture', num: true },
            { cle: 'cmm', titre: 'Moyenne mensuelle', num: true, rendu: (l) => decimal(l.cmm) },
            { cle: 'mois_de_stock', titre: 'Mois de stock', num: true, rendu: (l) => (
                <Tag ton={l.mois_de_stock === null ? 'neutre' : l.mois_de_stock < 1 ? 'danger' : l.mois_de_stock < 2 ? 'alerte' : 'ok'}>
                  {l.mois_de_stock === null ? '—' : decimal(l.mois_de_stock)}
                </Tag>) },
            { cle: 'a_commander', titre: 'À commander', num: true, rendu: (l) => nombre(l.a_commander) }
          ]}
          lignes={lignes}
        />
      </Card>

      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre="Réception"><p className="text-[12.5px] text-ink-2">
          Bordereau du dépôt de district, lot, date de péremption et quantité reçue. Un lot déjà périmé est refusé.
        </p></Card>
        <Card titre="Inventaire"><p className="text-[12.5px] text-ink-2">
          Comptage physique par lot, écart calculé automatiquement, ajustement soumis à justification.
        </p></Card>
        <Card titre="Pertes et ajustements"><p className="text-[12.5px] text-ink-2">
          Péremption, casse, vol, chaîne du froid rompue : chaque motif est codifié pour le rapport logistique.
        </p></Card>
      </div>
    </>
  )
}
