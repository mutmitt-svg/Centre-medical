import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY
const schema = import.meta.env.VITE_SUPABASE_SCHEMA || 'public'

/** Vrai lorsque les variables d'environnement sont renseignées. L'interface
 *  reste utilisable sans base (mode découverte) et affiche un avertissement. */
export const supabaseConfigure = Boolean(url && key && !url.includes('xxxxxxxx'))

export const supabase = supabaseConfigure
  ? createClient(url, key, {
      db: { schema },
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: false,
        storageKey: 'cs-sante-auth'
      },
      global: { headers: { 'x-application-name': 'centre-sante-app' } }
    })
  : null

export const structureNom = import.meta.env.VITE_STRUCTURE_NOM || 'Centre de Santé'
export const structureCode = import.meta.env.VITE_STRUCTURE_CODE || '—'
export const deviseDefaut = import.meta.env.VITE_DEVISE || 'CDF'
