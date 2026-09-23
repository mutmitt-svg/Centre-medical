import { useEffect, useState } from 'react'
import { lister, purgerSynchronisees } from '../lib/offline.js'
import { useOffline } from '../context/OfflineContext.jsx'
import { Card, Table, Tag, Note, Kpi } from '../components/ui.jsx'
import { dateHeure } from '../lib/format.js'

export default function Synchronisation() {
  const { enLigne, enAttente, synchronisation, dernierEchange, synchroniser } = useOffline()
  const [entrees, setEntrees] = useState([])

  const charger = async () => { try { setEntrees(await lister()) } catch { setEntrees([]) } }
  useEffect(() => {
    charger()
    window.addEventListener('cs-file-modifiee', charger)
    return () => window.removeEventListener('cs-file-modifiee', charger)
  }, [])

  const echecs = entrees.filter((e) => e.statut === 'ECHEC')

  return (
    <>
      <div className="grid gap-3.5 grid-cols-2 lg:grid-cols-4">
        <Kpi libelle="État de la liaison" valeur={enLigne ? 'En ligne' : 'Hors ligne'} ton={enLigne ? 'ok' : 'alerte'} />
        <Kpi libelle="Opérations en attente" valeur={enAttente} ton={enAttente > 0 ? 'alerte' : 'ok'} />
        <Kpi libelle="Échecs à traiter" valeur={echecs.length} ton={echecs.length > 0 ? 'danger' : 'ok'} />
        <Kpi libelle="Dernier échange" valeur={dernierEchange ? dateHeure(dernierEchange) : '—'} />
      </div>

      <Note ton="accent" titre="Fonctionnement hors ligne">
        Les saisies effectuées sans réseau sont conservées sur le poste avec un identifiant unique, puis rejouées
        automatiquement au retour de la connexion. Le rejeu est sans effet de bord : une opération déjà transmise
        n'est pas dupliquée.
      </Note>

      <Card
        titre="File de synchronisation locale"
        actions={
          <div className="flex gap-2">
            <button className="btn btn-sm" onClick={purgerSynchronisees}>Purger les envoyées</button>
            <button className="btn btn-sm btn-p" onClick={synchroniser} disabled={!enLigne || synchronisation}>
              {synchronisation ? 'Synchronisation…' : 'Synchroniser maintenant'}
            </button>
          </div>
        }
      >
        <Table
          colonnes={[
            { cle: 'cree_le', titre: 'Créée le', rendu: (l) => dateHeure(l.cree_le) },
            { cle: 'type', titre: 'Type' },
            { cle: 'cible', titre: 'Cible' },
            { cle: 'tentatives', titre: 'Tentatives', num: true },
            { cle: 'statut', titre: 'Statut', rendu: (l) => (
                <Tag ton={l.statut === 'ENVOYE' ? 'ok' : l.statut === 'ECHEC' ? 'danger' : 'alerte'}>{l.statut}</Tag>) },
            { cle: 'erreur', titre: 'Dernière erreur' }
          ]}
          lignes={entrees}
          vide="Aucune opération en file : toutes les saisies sont transmises"
        />
      </Card>
    </>
  )
}
