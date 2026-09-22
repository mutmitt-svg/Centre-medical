import { demo } from '../lib/demo.js'
import { Card, Table, Tag, Note } from '../components/ui.jsx'
import { dateHeure } from '../lib/format.js'
import { useAuth } from '../context/AuthContext.jsx'

export default function Administration() {
  const { profil, peut } = useAuth()
  return (
    <>
      {!peut('AUDIT_LIRE') && (
        <Note ton="alerte" titre="Accès partiel">
          Votre profil ne permet pas la lecture du journal d'audit.
        </Note>
      )}

      <div className="grid gap-3.5 lg:grid-cols-3">
        <Card titre="Comptes et rôles" className="lg:col-span-2">
          <Table
            colonnes={[
              { cle: 'login', titre: 'Identifiant' },
              { cle: 'nom', titre: 'Agent' },
              { cle: 'qualification', titre: 'Qualification' },
              { cle: 'roles', titre: 'Rôles' },
              { cle: 'actif', titre: 'État', rendu: (l) => <Tag ton={l.actif ? 'ok' : 'danger'}>{l.actif ? 'Actif' : 'Suspendu'}</Tag> }
            ]}
            lignes={demo.utilisateurs}
          />
        </Card>

        <Card titre="Profil connecté">
          <p className="font-semibold text-13.5">{profil?.nom}</p>
          <p className="text-[12px] text-ink-3">{profil?.qualification} — {profil?.structure}</p>
          <div className="sec">Permissions</div>
          <div className="flex flex-wrap gap-1">
            {(profil?.permissions || []).map((p) => <Tag key={p} ton="neutre">{p}</Tag>)}
          </div>
        </Card>
      </div>

      <Card titre="Journal d'audit">
        <Table
          colonnes={[
            { cle: 'horodatage', titre: 'Horodatage', rendu: (l) => dateHeure(l.horodatage) },
            { cle: 'utilisateur', titre: 'Utilisateur' },
            { cle: 'action', titre: 'Action', rendu: (l) => (
                <Tag ton={l.action === 'BRIS_DE_GLACE' ? 'danger' : 'neutre'}>{l.action}</Tag>) },
            { cle: 'entite', titre: 'Objet' },
            { cle: 'justification', titre: 'Justification' }
          ]}
          lignes={demo.audit}
        />
        <p className="text-[11.5px] text-ink-3 mt-2">
          Le journal est en ajout seul : la modification et la suppression de ses lignes sont refusées par la base.
        </p>
      </Card>
    </>
  )
}
