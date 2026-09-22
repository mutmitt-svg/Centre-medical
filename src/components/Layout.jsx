import { useState } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'
import { useOffline } from '../context/OfflineContext.jsx'
import { structureNom, structureCode } from '../lib/supabase.js'
import { Note } from './ui.jsx'

const MENU = [
  { groupe: 'Pilotage', liens: [{ to: '/', libelle: 'Tableau de bord' }] },
  {
    groupe: 'Circuit du patient',
    liens: [
      { to: '/accueil', libelle: 'Accueil et file' },
      { to: '/patients', libelle: 'Dossiers patients' },
      { to: '/consultation', libelle: 'Consultation' },
      { to: '/laboratoire', libelle: 'Laboratoire' },
      { to: '/pharmacie', libelle: 'Pharmacie' },
      { to: '/caisse', libelle: 'Caisse' }
    ]
  },
  {
    groupe: 'Programmes',
    liens: [
      { to: '/maternite', libelle: 'Maternité et CPN' },
      { to: '/pev', libelle: 'PEV et CPS' }
    ]
  },
  { groupe: 'Rapportage', liens: [{ to: '/snis', libelle: 'Rapport SNIS' }] },
  {
    groupe: 'Gestion',
    liens: [
      { to: '/stock', libelle: 'Stocks et SIGL' },
      { to: '/referentiels', libelle: 'Référentiels' }
    ]
  },
  {
    groupe: 'Système',
    liens: [
      { to: '/synchronisation', libelle: 'Synchronisation' },
      { to: '/administration', libelle: 'Administration' }
    ]
  }
]

export default function Layout() {
  const { profil, deconnexion, modeDemo } = useAuth()
  const { enLigne, enAttente, synchronisation, synchroniser } = useOffline()
  const [ouvert, setOuvert] = useState(false)
  const { pathname } = useLocation()

  return (
    <div className="min-h-full flex">
      <aside className={`${ouvert ? 'block' : 'hidden'} md:block w-60 shrink-0 bg-night text-white/90 fixed md:static inset-y-0 z-20 overflow-y-auto`}>
        <div className="px-4 py-3.5 border-b border-white/10">
          <div className="font-bold text-white text-13.5">{structureNom}</div>
          <div className="text-[11.5px] text-white/60">Code SNIS {structureCode}</div>
        </div>
        <nav className="py-2">
          {MENU.map((g) => (
            <div key={g.groupe} className="mb-1">
              <div className="px-4 pt-3 pb-1 text-[10.5px] uppercase tracking-wider text-white/40 font-bold">{g.groupe}</div>
              {g.liens.map((l) => (
                <NavLink
                  key={l.to}
                  to={l.to}
                  onClick={() => setOuvert(false)}
                  className={({ isActive }) =>
                    `block px-4 py-1.5 text-13.5 border-l-[3px] ${
                      isActive
                        ? 'border-primary bg-white/10 text-white font-semibold'
                        : 'border-transparent hover:bg-white/5'
                    }`
                  }
                >
                  {l.libelle}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>
      </aside>

      <div className="flex-1 min-w-0 flex flex-col">
        <header className="bg-surface border-b border-line px-3.5 py-2 flex items-center gap-3 sticky top-0 z-10">
          <button className="btn btn-sm md:hidden" onClick={() => setOuvert((o) => !o)}>Menu</button>
          <div className="flex-1 min-w-0">
            <div className="text-13.5 font-bold truncate">{titreEcran(pathname)}</div>
            <div className="text-[11.5px] text-ink-3">
              {new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
            </div>
          </div>
          <button
            onClick={synchroniser}
            className={`tag ${enLigne ? 'bg-ok-soft text-ok' : 'bg-warn-soft text-warn'}`}
            title="Forcer la synchronisation"
          >
            {synchronisation ? 'Synchronisation' : enLigne ? 'En ligne' : 'Hors ligne'}
            {enAttente > 0 && ` · ${enAttente} en attente`}
          </button>
          <div className="text-right hidden sm:block">
            <div className="text-[12.5px] font-semibold">{profil?.nom}</div>
            <div className="text-[11px] text-ink-3">{profil?.qualification}</div>
          </div>
          <button className="btn btn-sm" onClick={deconnexion}>Quitter</button>
        </header>

        <main className="p-3.5 flex flex-col gap-3.5 max-w-[1400px] w-full">
          {modeDemo && (
            <Note ton="alerte" titre="Mode découverte">
              Aucune base Supabase n'est reliée : les écrans affichent le jeu de démonstration de Kamalondo.
              Renseignez <code>VITE_SUPABASE_URL</code> et <code>VITE_SUPABASE_ANON_KEY</code> dans <code>.env.local</code> pour passer en données réelles.
            </Note>
          )}
          <Outlet />
        </main>
      </div>
    </div>
  )
}

function titreEcran(chemin) {
  const t = MENU.flatMap((g) => g.liens).find((l) => l.to === chemin)
  return t ? t.libelle : 'Gestion du centre de santé'
}
