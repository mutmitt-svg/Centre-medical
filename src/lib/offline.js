/**
 * File d'attente locale pour le fonctionnement hors ligne (EF-M26-01/02).
 *
 * Principe : toute écriture est d'abord journalisée dans IndexedDB avec un
 * identifiant UUID généré côté client, puis rejouée dès que la connexion
 * revient. Les identifiants étant globalement uniques (EF-M26-04), le rejeu
 * est idempotent et ne crée pas de doublon.
 */

const BASE = 'cs-sante'
const STORE = 'file_sync'
const VERSION = 1

function ouvrir() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(BASE, VERSION)
    req.onupgradeneeded = () => {
      const db = req.result
      if (!db.objectStoreNames.contains(STORE)) {
        const s = db.createObjectStore(STORE, { keyPath: 'id' })
        s.createIndex('statut', 'statut')
        s.createIndex('cree_le', 'cree_le')
      }
    }
    req.onsuccess = () => resolve(req.result)
    req.onerror = () => reject(req.error)
  })
}

async function tx(mode, fn) {
  const db = await ouvrir()
  return new Promise((resolve, reject) => {
    const t = db.transaction(STORE, mode)
    const store = t.objectStore(STORE)
    const out = fn(store)
    t.oncomplete = () => resolve(out?.result ?? out)
    t.onerror = () => reject(t.error)
  })
}

export const nouvelId = () =>
  crypto.randomUUID ? crypto.randomUUID() : URL.createObjectURL(new Blob()).slice(-36)

/** Ajoute une opération à la file locale. */
export async function empiler(operation) {
  const entree = {
    id: nouvelId(),
    statut: 'EN_ATTENTE',
    tentatives: 0,
    cree_le: new Date().toISOString(),
    ...operation
  }
  await tx('readwrite', (s) => s.put(entree))
  window.dispatchEvent(new Event('cs-file-modifiee'))
  return entree
}

export async function lister(statut) {
  const db = await ouvrir()
  return new Promise((resolve, reject) => {
    const t = db.transaction(STORE, 'readonly')
    const req = t.objectStore(STORE).getAll()
    req.onsuccess = () =>
      resolve(statut ? req.result.filter((e) => e.statut === statut) : req.result)
    req.onerror = () => reject(req.error)
  })
}

export async function compter(statut = 'EN_ATTENTE') {
  return (await lister(statut)).length
}

export async function marquer(id, statut, erreur) {
  const db = await ouvrir()
  return new Promise((resolve, reject) => {
    const t = db.transaction(STORE, 'readwrite')
    const store = t.objectStore(STORE)
    const req = store.get(id)
    req.onsuccess = () => {
      const e = req.result
      if (!e) return
      e.statut = statut
      e.erreur = erreur ?? null
      e.tentatives = (e.tentatives || 0) + (statut === 'ECHEC' ? 1 : 0)
      e.traite_le = new Date().toISOString()
      store.put(e)
    }
    t.oncomplete = () => resolve(true)
    t.onerror = () => reject(t.error)
  })
}

export async function purgerSynchronisees() {
  const envoyees = await lister('ENVOYE')
  await tx('readwrite', (s) => envoyees.forEach((e) => s.delete(e.id)))
  window.dispatchEvent(new Event('cs-file-modifiee'))
  return envoyees.length
}

/**
 * Rejoue la file. `executeur(entree)` doit effectuer l'appel réseau et lever
 * une exception en cas d'échec pour que l'entrée reste dans la file.
 */
export async function rejouer(executeur) {
  const attente = await lister('EN_ATTENTE')
  let envoyees = 0
  let echecs = 0
  for (const entree of attente) {
    try {
      await executeur(entree)
      await marquer(entree.id, 'ENVOYE')
      envoyees += 1
    } catch (e) {
      await marquer(entree.id, 'ECHEC', e?.message || String(e))
      echecs += 1
    }
  }
  window.dispatchEvent(new Event('cs-file-modifiee'))
  return { envoyees, echecs, total: attente.length }
}
