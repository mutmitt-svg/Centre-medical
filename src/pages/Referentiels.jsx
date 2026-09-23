import { Card, Table, Tag } from '../components/ui.jsx'

const REFERENTIELS = [
  { cle: 'r1', nom: 'Produits pharmaceutiques', volume: '412 lignes', cle_metier: 'Code produit, dénomination commune, forme, dosage, traceur', maj: 'Liste nationale des médicaments essentiels' },
  { cle: 'r2', nom: 'Actes et tarifs', volume: '96 actes', cle_metier: 'Code acte, catégorie, tarif par régime', maj: 'Comité de gestion du centre' },
  { cle: 'r3', nom: 'Diagnostics', volume: '1 238 entrées', cle_metier: 'Code CIM-10, libellé, groupe de rapportage', maj: 'Classification internationale des maladies' },
  { cle: 'r4', nom: 'Examens de laboratoire', volume: '74 examens', cle_metier: 'Code, unité, valeurs de référence par âge et sexe', maj: 'Protocoles du laboratoire' },
  { cle: 'r5', nom: 'Antigènes du programme élargi de vaccination', volume: '14 antigènes', cle_metier: 'Âge cible, dose, intervalle minimal, doses par flacon', maj: 'Calendrier vaccinal national' },
  { cle: 'r6', nom: 'Éléments de données du rapport mensuel', volume: '30 éléments', cle_metier: 'Code, rubrique, ventilation, correspondance DHIS2', maj: 'Canevas du système national d\'information sanitaire' },
  { cle: 'r7', nom: 'Villages et ménages', volume: '5 villages', cle_metier: 'Aire de santé, population, distance', maj: 'Recensement de l\'aire de santé' },
  { cle: 'r8', nom: 'Tiers payants', volume: '6 conventions', cle_metier: 'Taux de prise en charge, ticket modérateur, plafond', maj: 'Conventions signées' }
]

export default function Referentiels() {
  return (
    <>
      <Card titre="Référentiels administrés">
        <Table
          cle="cle"
          colonnes={[
            { cle: 'nom', titre: 'Référentiel' },
            { cle: 'volume', titre: 'Volume' },
            { cle: 'cle_metier', titre: 'Champs structurants' },
            { cle: 'maj', titre: 'Source de mise à jour' },
            { cle: 'action', titre: 'Action', rendu: () => <button className="btn btn-sm">Ouvrir</button> }
          ]}
          lignes={REFERENTIELS}
        />
      </Card>
      <Card titre="Règles de modification">
        <ul className="text-[12.5px] list-disc ml-4 text-ink-2 flex flex-col gap-1">
          <li>Une ligne de référentiel utilisée par un enregistrement n'est jamais supprimée : elle est désactivée.</li>
          <li>Les tarifs sont versionnés par date de début et de fin, sans écrasement de l'historique. <Tag ton="primaire">Historique conservé</Tag></li>
          <li>Les codes de correspondance avec le système national doivent rester alignés pour que l'export reste valide.</li>
        </ul>
      </Card>
    </>
  )
}
