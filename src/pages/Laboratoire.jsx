import { demo } from '../lib/demo.js'
import { Card, Table, Tag, Note } from '../components/ui.jsx'

export default function Laboratoire() {
  const critiques = demo.examens.filter((e) => e.critique)
  return (
    <>
      {critiques.length > 0 && (
        <Note ton="danger" titre={`${critiques.length} résultat(s) critique(s) à communiquer`}>
          La communication au prescripteur doit être tracée avec l'heure et le nom du destinataire.
        </Note>
      )}
      <Card titre="Paillasse du jour">
        <Table
          colonnes={[
            { cle: 'numero', titre: 'Demande' },
            { cle: 'patient', titre: 'Patient' },
            { cle: 'examen', titre: 'Examen' },
            { cle: 'resultat', titre: 'Résultat' },
            { cle: 'reference', titre: 'Valeurs de référence' },
            { cle: 'critique', titre: 'Criticité', rendu: (l) => (
                <Tag ton={l.critique ? 'danger' : 'neutre'}>{l.critique ? 'Critique' : 'Normal'}</Tag>) },
            { cle: 'statut', titre: 'Statut', rendu: (l) => (
                <Tag ton={l.statut === 'VALIDE' ? 'ok' : 'alerte'}>{l.statut}</Tag>) }
          ]}
          lignes={demo.examens}
        />
      </Card>
      <div className="grid gap-3.5 lg:grid-cols-2">
        <Card titre="Contrôle de qualité interne">
          <p className="text-[12.5px] text-ink-2">
            Chaque série exige la saisie du contrôle interne : lot de contrôle, valeur attendue, valeur obtenue.
            Une série sans contrôle valide ne peut pas être publiée.
          </p>
        </Card>
        <Card titre="Registre de laboratoire">
          <p className="text-[12.5px] text-ink-2">
            Le registre imprimable reprend le canevas du système national d'information sanitaire : demandes,
            examens réalisés, positifs, examens rendus dans les délais.
          </p>
        </Card>
      </div>
    </>
  )
}
