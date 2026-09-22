const nf = new Intl.NumberFormat('fr-CD', { maximumFractionDigits: 0 })
const nf2 = new Intl.NumberFormat('fr-CD', { minimumFractionDigits: 1, maximumFractionDigits: 1 })

export const montant = (v, devise = 'CDF') =>
  v === null || v === undefined ? '—' : `${nf.format(Number(v))} ${devise}`

export const nombre = (v) => (v === null || v === undefined ? '—' : nf.format(Number(v)))
export const decimal = (v) => (v === null || v === undefined ? '—' : nf2.format(Number(v)))

export const dateCourte = (d) =>
  d ? new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '—'

export const dateHeure = (d) =>
  d
    ? new Date(d).toLocaleString('fr-FR', {
        day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'
      })
    : '—'

export const heure = (d) =>
  d ? new Date(d).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) : '—'

export const attente = (minutes) => {
  if (minutes === null || minutes === undefined) return '—'
  if (minutes < 60) return `${minutes} min`
  return `${Math.floor(minutes / 60)} h ${String(minutes % 60).padStart(2, '0')}`
}

export const moisLibelle = (d) =>
  d ? new Date(d).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' }) : '—'

export const periodeMois = (d = new Date()) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`
