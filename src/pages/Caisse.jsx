import { useState } from 'react'
import { demo } from '../lib/demo.js'
import { Card, Table, Note, Champ, Tag } from '../components/ui.jsx'
import { montant } from '../lib/format.js'

export default function Caisse() {
  const f = demo.facture
  const [compte, setCompte] = useState('')
  const [justification, setJustification] = useState('')
  const theorique = 184500
  const ecart = compte === '' ? 0 : Number(compte) - theorique

  return (
    <>
      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre={`Facture ${f.numero}`} className="lg:col-span-2">
          <p className="text-13 text-ink-2 mb-2">{f.patient} — {f.regime}</p>
          <Table
            cle="libelle"
            colonnes={[
              { cle: 'libelle', titre: 'Prestation' },
              { cle: 'quantite', titre: 'Qté', num: true },
              { cle: 'prix_unitaire', titre: 'Prix unitaire', num: true, rendu: (l) => montant(l.prix_unitaire) },
              { cle: 'montant_total', titre: 'Total', num: true, rendu: (l) => montant(l.montant_total) }
            ]}
            lignes={f.lignes}
          />
          <div className="mt-3 border-t border-line pt-2.5 flex flex-col gap-1 text-13">
            <div className="flex justify-between"><span>Montant brut</span><strong>{montant(f.montant_brut)}</strong></div>
            <div className="flex justify-between"><span>Part tiers payant</span><strong>{montant(f.part_tiers)}</strong></div>
            <div className="flex justify-between text-base"><span className="font-semibold">Part patient à encaisser</span>
              <strong className="text-primary">{montant(f.part_patient)}</strong></div>
          </div>
        </Card>

        <Card titre="Encaissement">
          <Champ libelle="Mode de paiement">
            <select>
              <option>Espèces</option><option>Mobile money</option><option>Tiers payant</option>
              <option>Exonération</option>
            </select>
          </Champ>
          <Champ libelle="Devise"><select><option>CDF</option><option>USD</option></select></Champ>
          <Champ libelle="Montant reçu" aide="Taux de référence du jour : 1 USD = 2 850 CDF.">
            <input type="number" defaultValue={f.part_patient} />
          </Champ>
          <button className="btn btn-p w-full">Encaisser et imprimer le reçu</button>
          <Note ton="alerte" titre="Gratuité maternité">
            Aucun encaissement n'est accepté pour une prise en charge sous gratuité de la maternité et du nouveau-né.
          </Note>
        </Card>
      </div>

      <Card titre="Clôture de la session de caisse">
        <div className="grid sm:grid-cols-3 gap-x-3">
          <Champ libelle="Total théorique"><input readOnly value={montant(theorique)} /></Champ>
          <Champ libelle="Espèces comptées (CDF)">
            <input type="number" value={compte} onChange={(e) => setCompte(e.target.value)} />
          </Champ>
          <Champ libelle="Écart constaté">
            <input readOnly value={montant(ecart)} className={ecart !== 0 ? 'text-danger font-semibold' : undefined} />
          </Champ>
        </div>
        {ecart !== 0 && (
          <Champ libelle="Justification de l'écart (obligatoire)">
            <textarea rows={2} value={justification} onChange={(e) => setJustification(e.target.value)} />
          </Champ>
        )}
        <div className="flex items-center gap-2">
          <button className="btn btn-p" disabled={ecart !== 0 && justification.trim() === ''}>Clôturer la session</button>
          {ecart !== 0 && justification.trim() === '' && <Tag ton="danger">Justification requise</Tag>}
        </div>
      </Card>
    </>
  )
}
