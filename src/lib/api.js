import { supabase, supabaseConfigure } from './supabase.js'
import { empiler } from './offline.js'

class ApiIndisponible extends Error {
  constructor() {
    super("Base de données non configurée : renseignez VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans .env.local")
    this.name = 'ApiIndisponible'
  }
}

function client() {
  if (!supabaseConfigure) throw new ApiIndisponible()
  return supabase
}

/** Appel d'une fonction RPC PostgreSQL (toute la logique métier y réside). */
export async function rpc(nom, params = {}) {
  const { data, error } = await client().rpc(nom, params)
  if (error) throw new Error(error.message)
  return data
}

/** Lecture simple d'une table avec sélection de colonnes. */
export async function lire(table, { select = '*', filtres = {}, ordre, limite } = {}) {
  let q = client().from(table).select(select)
  Object.entries(filtres).forEach(([col, val]) => {
    if (val === null) q = q.is(col, null)
    else if (Array.isArray(val)) q = q.in(col, val)
    else q = q.eq(col, val)
  })
  if (ordre) q = q.order(ordre.colonne, { ascending: ordre.ascendant !== false })
  if (limite) q = q.limit(limite)
  const { data, error } = await q
  if (error) throw new Error(error.message)
  return data
}

/** Appel d'une fonction Edge (code serveur avec droits élevés, ex. création de comptes). */
export async function invoquer(nom, corps = {}) {
  const { data, error } = await client().functions.invoke(nom, { body: corps })
  if (error) throw new Error(error.message)
  if (data?.erreur) throw new Error(data.erreur)
  return data
}


export async function ecrire(table, valeurs, { rpcNom } = {}) {
  try {
    if (rpcNom) return await rpc(rpcNom, valeurs)
    const { data, error } = await client().from(table).insert(valeurs).select()
    if (error) throw new Error(error.message)
    return data
  } catch (e) {
    if (!navigator.onLine || e.name === 'ApiIndisponible' || /fetch|network/i.test(e.message)) {
      await empiler({ type: rpcNom ? 'rpc' : 'insert', cible: rpcNom || table, charge: valeurs })
      return { differe: true }
    }
    throw e
  }
}

/** Rejeu d'une entrée de la file locale. */
export async function rejouerEntree(entree) {
  if (entree.type === 'rpc') return rpc(entree.cible, entree.charge)
  const { error } = await client().from(entree.cible).insert(entree.charge)
  if (error) throw new Error(error.message)
  return true
}

// ---------------------------------------------------------------------------
// Fonctions métier utilisées par les écrans
// ---------------------------------------------------------------------------
export const api = {
  tableauDeBord: () => rpc('tableau_de_bord'),
  fileAttente: (service) => rpc('file_attente', { p_service: service ?? null }),
  rechercherPatient: (q) => rpc('rechercher_patient', { p_q: q }),
  doublons: (p) => rpc('doublons_probables', p),
  calculerCas: (patient) => rpc('calculer_cas', { p_patient: patient }),
  enregistrerVenue: (p) => ecrire(null, p, { rpcNom: 'enregistrer_venue' }),
  calendrierVaccinal: (patient) => rpc('calendrier_vaccinal', { p_patient: patient }),
  sigl: (periode) => rpc('donnees_essentielles_sigl', { p_periode: periode }),
  lotsFefo: (produit, depot, quantite) =>
    rpc('proposer_lots_fefo', { p_produit: produit, p_depot: depot, p_quantite: quantite }),
  dispenser: (venue, depot, lignes) =>
    ecrire(null, { p_venue: venue, p_depot: depot, p_lignes: lignes }, { rpcNom: 'dispenser' }),
  genererFacture: (venue) => rpc('generer_facture', { p_venue: venue }),
  encaisser: (p) => ecrire(null, p, { rpcNom: 'encaisser' }),
  cloturerCaisse: (p) => rpc('cloturer_session_caisse', p),
  genererRapport: (periode, type = 'SNIS_CS') =>
    rpc('generer_rapport_snis', { p_periode: periode, p_type: type }),
  controles: (rapport) => rpc('controles_coherence', { p_rapport: rapport }),
  transmettre: (rapport, canal) => rpc('transmettre_rapport', { p_rapport: rapport, p_canal: canal }),
  journaliser: (p) => rpc('journaliser', p),
  audit: (limite = 50) =>
    lire('journal_audit', { select: '*', ordre: { colonne: 'horodatage', ascendant: false }, limite }),

  // Comptes et habilitations (menu Administration) ------------------------
  comptePrincipalExiste: () => rpc('compte_principal_existe'),
  creerComptePrincipal: (nomComplet, nomStructure, codeStructure) =>
    rpc('creer_compte_principal', { p_nom_complet: nomComplet, p_nom_structure: nomStructure ?? null, p_code_structure: codeStructure ?? null }),
  listerUtilisateurs: () =>
    lire('utilisateur', {
      select: 'id, login, actif, agent:agent_id (nom, post_nom, prenom, qualification), roles:utilisateur_role (role:role_id (code, libelle))'
    }),
  listerRoles: () => lire('role', { select: 'id, code, libelle', ordre: { colonne: 'libelle' } }),
  creerUtilisateur: (p) => invoquer('creer-utilisateur', p)
}

export { ApiIndisponible }
