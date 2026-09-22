/**
 * Vérification hors ligne des scripts SQL : les migrations et le jeu de
 * démonstration sont exécutés sur une instance PostgreSQL embarquée
 * (WebAssembly), sans installer de serveur. Utile en intégration continue.
 *
 *   npm install --no-save @electric-sql/pglite
 *   node scripts/verifier_sql.mjs
 */
import fs from 'node:fs'
import path from 'node:path'
import { PGlite } from '@electric-sql/pglite'
import { pg_trgm } from '@electric-sql/pglite/contrib/pg_trgm'
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto'
import { unaccent } from '@electric-sql/pglite/contrib/unaccent'

const racine = path.resolve(import.meta.dirname, '..')
const db = await PGlite.create({ extensions: { pg_trgm, pgcrypto, unaccent } })

// Doublures des objets fournis par Supabase (authentification, rôles).
await db.exec(`
  CREATE SCHEMA IF NOT EXISTS auth;
  CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql AS $$ SELECT NULL::uuid $$;
  CREATE ROLE authenticated; CREATE ROLE anon; CREATE ROLE service_role;
`)

const migrations = fs.readdirSync(path.join(racine, 'supabase/migrations')).sort()
for (const f of migrations) {
  await db.exec(fs.readFileSync(path.join(racine, 'supabase/migrations', f), 'utf8'))
  console.log('migration appliquée :', f)
}
await db.exec(fs.readFileSync(path.join(racine, 'supabase/seed.sql'), 'utf8'))
console.log('jeu de démonstration chargé')

const compte = async (sql) => (await db.query(sql)).rows[0].n
console.log('tables      :', await compte(`select count(*)::int n from pg_tables where schemaname='cs'`))
console.log('vues        :', await compte(`select count(*)::int n from pg_views where schemaname='cs'`))
console.log('fonctions   :', await compte(`select count(*)::int n from pg_proc p join pg_namespace s on s.oid=p.pronamespace where s.nspname='cs'`))
console.log('politiques  :', await compte(`select count(*)::int n from pg_policies where schemaname='cs'`))
console.log('patients    :', await compte(`select count(*)::int n from cs.patient`))
