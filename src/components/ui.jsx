import { NavLink } from 'react-router-dom'

export function Card({ titre, actions, children, className = '', pied }) {
  return (
    <section className={`card ${className}`}>
      {(titre || actions) && (
        <header className="card-header">
          <h2 className="text-13.5 font-bold flex-1">{titre}</h2>
          {actions}
        </header>
      )}
      <div className="card-body">{children}</div>
      {pied && <footer className="px-3.5 py-2.5 border-t border-line bg-surface-2 text-[12.5px]">{pied}</footer>}
    </section>
  )
}

const TONS = {
  neutre: 'bg-[#eef2f4] text-ink-2',
  primaire: 'bg-primary-soft text-primary-dark',
  accent: 'bg-accent-soft text-accent',
  ok: 'bg-ok-soft text-ok',
  alerte: 'bg-warn-soft text-warn',
  danger: 'bg-danger-soft text-danger'
}

export function Tag({ ton = 'neutre', children }) {
  return <span className={`tag ${TONS[ton] || TONS.neutre}`}>{children}</span>
}

export function Kpi({ libelle, valeur, detail, ton = 'neutre' }) {
  return (
    <div className="card p-3">
      <div className="text-[11px] uppercase tracking-wide text-ink-3 font-bold">{libelle}</div>
      <div className={`text-2xl font-bold mt-1 ${ton === 'danger' ? 'text-danger' : ton === 'alerte' ? 'text-warn' : ton === 'ok' ? 'text-ok' : 'text-ink'}`}>
        {valeur}
      </div>
      {detail && <div className="text-[12px] text-ink-3 mt-0.5">{detail}</div>}
    </div>
  )
}

export function Note({ ton = 'accent', titre, children }) {
  const styles = {
    accent: 'border-accent bg-accent-soft text-accent',
    alerte: 'border-warn bg-warn-soft text-warn',
    danger: 'border-danger bg-danger-soft text-danger',
    ok: 'border-ok bg-ok-soft text-ok'
  }
  return (
    <div className={`note ${styles[ton]}`}>
      {titre && <strong className="block mb-0.5">{titre}</strong>}
      {children}
    </div>
  )
}

export function Table({ colonnes, lignes, vide = 'Aucune donnée', cle = 'id' }) {
  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>{colonnes.map((c) => <th key={c.cle} className={c.num ? 'text-right' : undefined}>{c.titre}</th>)}</tr>
        </thead>
        <tbody>
          {(!lignes || lignes.length === 0) && (
            <tr><td colSpan={colonnes.length} className="text-center text-ink-3 py-6">{vide}</td></tr>
          )}
          {lignes?.map((l, i) => (
            <tr key={l[cle] ?? i}>
              {colonnes.map((c) => (
                <td key={c.cle} className={[c.num ? 'num' : '', c.nowrap ? 'whitespace-nowrap' : ''].join(' ').trim() || undefined}>
                  {c.rendu ? c.rendu(l) : l[c.cle] ?? '—'}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export function Champ({ libelle, aide, children }) {
  return (
    <div className="mb-3">
      <label>{libelle}</label>
      {children}
      {aide && <p className="text-[11.5px] text-ink-3 mt-1">{aide}</p>}
    </div>
  )
}

export function Lien({ to, children }) {
  return <NavLink to={to} className="text-accent font-semibold hover:underline">{children}</NavLink>
}

export function Chargement({ texte = 'Chargement' }) {
  return <p className="text-ink-3 text-13 py-4">{texte}…</p>
}

export function Jauge({ valeur, max = 100, ton = 'primaire' }) {
  const pct = Math.max(0, Math.min(100, max ? (valeur / max) * 100 : 0))
  const couleurs = { primaire: 'bg-primary', alerte: 'bg-warn', danger: 'bg-danger', ok: 'bg-ok' }
  return (
    <div className="h-2 bg-[#eef2f4] rounded-full overflow-hidden">
      <div className={`h-full ${couleurs[ton]}`} style={{ width: `${pct}%` }} />
    </div>
  )
}
