import { useCallback, useEffect, useState } from 'react'

/**
 * Chargement de données avec repli sur un jeu de démonstration lorsque la
 * base n'est pas configurée ou que l'appel échoue hors ligne.
 */
export function useDonnees(chargeur, { repli = null, deps = [] } = {}) {
  const [donnees, setDonnees] = useState(repli)
  const [chargement, setChargement] = useState(true)
  const [erreur, setErreur] = useState(null)

  const executer = useCallback(async () => {
    setChargement(true)
    setErreur(null)
    try {
      const r = await chargeur()
      setDonnees(r)
    } catch (e) {
      setErreur(e.message || String(e))
      if (repli !== null) setDonnees(repli)
    } finally {
      setChargement(false)
    }
    // Les dépendances sont fournies par l'appelant via l'option deps.
  }, deps)

  useEffect(() => { executer() }, [executer])

  return { donnees, chargement, erreur, recharger: executer }
}
