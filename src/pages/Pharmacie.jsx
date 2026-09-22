import { demo } from '../lib/demo.js'
import { Card, Table, Note, Tag } from '../components/ui.jsx'
import { nombre } from '../lib/format.js'

export default function Pharmacie() {
  const c = demo.consultation
  return (
    <>
      <Note ton="accent" titre="Règles appliquées à la dispensation">
        Aucune sortie sans prescription valide, lot le plus proche de la péremption servi en premier, solde de stock
        jamais négatif. Toute dérogation exige un motif enregistré.
      </Note>

      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre="Ordonnance à servir" className="lg:col-span-2">
          <Table
            cle="produit"
            colonnes={[
              { cle: 'produit', titre: 'Produit prescrit' },
              { cle: 'posologie', titre: 'Posologie' },
              { cle: 'quantite', titre: 'Prescrit', num: true },
              { cle: 'lot', titre: 'Lot proposé', rendu: () => <span className="font-mono text-[12px]">AS-2604-B</span> },
              { cle: 'servi', titre: 'À servir', num: true, rendu: (l) => (
                  <input className="w-20 text-right" defaultValue={l.quantite} />) }
            ]}
            lignes={c.prescriptions}
          />
          <div className="flex gap-2 mt-3">
            <button className="btn">Substituer un produit</button>
            <button className="btn btn-p">Valider la dispensation</button>
          </div>
        </Card>

        <Card titre="Produits traceurs sous surveillance">
          <ul className="flex flex-col gap-2">
            {demo.sigl.filter((s) => s.mois_de_stock !== null && s.mois_de_stock < 1.5).map((s) => (
              <li key={s.produit_id} className="border border-line rounded-sm2 p-2">
                <div className="flex items-center gap-2">
                  <span className="text-13 font-semibold flex-1">{s.dci}</span>
                  <Tag ton={s.sdu === 0 ? 'danger' : 'alerte'}>{s.sdu === 0 ? 'Rupture' : 'Sous seuil'}</Tag>
                </div>
                <div className="text-[11.5px] text-ink-3">
                  Stock utilisable {nombre(s.sdu)} — consommation moyenne mensuelle {nombre(s.cmm)} —
                  à commander {nombre(s.a_commander)}
                </div>
              </li>
            ))}
          </ul>
        </Card>
      </div>
    </>
  )
}
