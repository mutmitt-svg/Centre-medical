import { createContext, useContext, useEffect, useMemo, useState, useCallback } from 'react'
import { compter, rejouer, purgerSynchronisees } from '../lib/offline.js'
import { rejouerEntree } from '../lib/api.js'

const Ctx = createContext(null)

export function OfflineProvider({ children }) {
  const [enLigne, setEnLigne] = useState(navigator.onLine)
  const [enAttente, setEnAttente] = useState(0)
  const [synchronisation, setSynchronisation] = useState(false)
  const [dernierEchange, setDernierEchange] = useState(null)

  const rafraichir = useCallback(async () => {
    try { setEnAttente(await compter('EN_ATTENTE')) } catch { /* IndexedDB indisponible */ }
  }, [])

  const synchroniser = useCallback(async () => {
    if (!navigator.onLine) return { envoyees: 0, echecs: 0, total: 0 }
    setSynchronisation(true)
    try {
      const bilan = await rejouer(rejouerEntree)
      await purgerSynchronisees()
      setDernierEchange(new Date().toISOString())
      return bilan
    } finally {
      setSynchronisation(false)
      rafraichir()
    }
  }, [rafraichir])

  useEffect(() => {
    rafraichir()
    const majEtat = () => {
      setEnLigne(navigator.onLine)
      if (navigator.onLine) synchroniser()
    }
    window.addEventListener('online', majEtat)
    window.addEventListener('offline', majEtat)
    window.addEventListener('cs-file-modifiee', rafraichir)
    const minuterie = setInterval(() => { if (navigator.onLine) synchroniser() }, 120000)
    return () => {
      window.removeEventListener('online', majEtat)
      window.removeEventListener('offline', majEtat)
      window.removeEventListener('cs-file-modifiee', rafraichir)
      clearInterval(minuterie)
    }
  }, [rafraichir, synchroniser])

  const valeur = useMemo(
    () => ({ enLigne, enAttente, synchronisation, dernierEchange, synchroniser, rafraichir }),
    [enLigne, enAttente, synchronisation, dernierEchange, synchroniser, rafraichir]
  )
  return <Ctx.Provider value={valeur}>{children}</Ctx.Provider>
}

export const useOffline = () => useContext(Ctx)
