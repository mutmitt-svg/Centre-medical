import { demo } from '../lib/demo.js'
import { Card, Note, Tag, Champ, Table } from '../components/ui.jsx'

export default function Consultation() {
  const c = demo.consultation
  return (
    <>
      <Note ton="danger" titre="Alertes cliniques bloquantes">
        <ul className="list-disc ml-4">{c.alertes.map((a) => <li key={a}>{a}</li>)}</ul>
      </Note>

      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre="Observation clinique" className="lg:col-span-2">
          <Champ libelle="Plainte principale"><input defaultValue={c.plainte} /></Champ>
          <Champ libelle="Anamnèse"><textarea rows={4} defaultValue={c.anamnese} /></Champ>
          <Champ libelle="Examen physique et signes vitaux"
                 aide="Les constantes hors bornes déclenchent une alerte et une orientation urgence.">
            <textarea rows={3} defaultValue={c.examen} />
          </Champ>
          <div className="sec">Diagnostics</div>
          <Table
            cle="code"
            colonnes={[
              { cle: 'code', titre: 'CIM-10' },
              { cle: 'libelle', titre: 'Libellé' },
              { cle: 'principal', titre: 'Rang', rendu: (l) => <Tag ton={l.principal ? 'primaire' : 'neutre'}>{l.principal ? 'Principal' : 'Associé'}</Tag> }
            ]}
            lignes={c.diagnostics}
          />
          <div className="sec">Prescriptions</div>
          <Table
            cle="produit"
            colonnes={[
              { cle: 'produit', titre: 'Produit' },
              { cle: 'posologie', titre: 'Posologie' },
              { cle: 'quantite', titre: 'Quantité', num: true }
            ]}
            lignes={c.prescriptions}
          />
          <div className="flex gap-2 mt-3">
            <button className="btn">Enregistrer le brouillon</button>
            <button className="btn btn-p">Valider et orienter</button>
          </div>
        </Card>

        <div className="flex flex-col gap-3.5">
          <Card titre="Patient">
            <p className="font-semibold text-13.5">{c.patient}</p>
            <p className="text-[12px] text-ink-3 mt-1">Mutuelle MUSOSA — prise en charge 80 %</p>
            <div className="sec">Conduite proposée</div>
            <ul className="text-[12.5px] list-disc ml-4 text-ink-2">
              <li>Protocole paludisme grave de l'enfant appliqué</li>
              <li>Référence vers l'hôpital général de référence si absence d'amélioration à H24</li>
              <li>Moustiquaire imprégnée remise et éducation sanitaire tracée</li>
            </ul>
          </Card>
          <Card titre="Traçabilité">
            <p className="text-[12.5px] text-ink-2">
              La validation verrouille la consultation. Toute correction ultérieure crée une version et une entrée
              d'audit avec justification obligatoire.
            </p>
          </Card>
        </div>
      </div>
    </>
  )
}
