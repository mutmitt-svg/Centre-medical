/**
 * Génération du fichier d'import DHIS2 à partir d'un rapport mensuel validé.
 *
 *   SUPABASE_URL=... SUPABASE_SERVICE_KEY=... RAPPORT_ID=... \
 *     node scripts/exporter_dhis2.mjs > dhis2-2026-09.json
 *
 * La correspondance entre éléments du système national et identifiants DHIS2
 * est portée par la table cs.element_donnee_snis (colonnes code_dhis2_de et
 * code_dhis2_coc) ; voir docs/04-integration-dhis2.md.
 */
import { createClient } from '@supabase/supabase-js'

const url = process.env.SUPABASE_URL
const cle = process.env.SUPABASE_SERVICE_KEY
const rapport = process.env.RAPPORT_ID
if (!url || !cle || !rapport) {
  console.error('Variables requises : SUPABASE_URL, SUPABASE_SERVICE_KEY, RAPPORT_ID')
  process.exit(1)
}

const client = createClient(url, cle, { db: { schema: 'cs' } })

const { data: entete, error: e1 } = await client
  .from('rapport_mensuel')
  .select('periode_mois, statut, structure:structure_id (code_snis, code_dhis2)')
  .eq('id', rapport)
  .single()
if (e1) throw new Error(e1.message)

const { data: valeurs, error: e2 } = await client
  .from('rapport_valeur')
  .select('valeur_retenue, element:element_id (code, code_dhis2_de, code_dhis2_coc)')
  .eq('rapport_id', rapport)
if (e2) throw new Error(e2.message)

const periode = String(entete.periode_mois).slice(0, 7).replace('-', '')
const charge = {
  dataSet: process.env.DHIS2_DATASET || 'SNIS_CS_MENSUEL',
  completeDate: new Date().toISOString().slice(0, 10),
  period: periode,
  orgUnit: entete.structure?.code_dhis2 || entete.structure?.code_snis,
  dataValues: valeurs
    .filter((v) => v.element?.code_dhis2_de && v.valeur_retenue !== null)
    .map((v) => ({
      dataElement: v.element.code_dhis2_de,
      categoryOptionCombo: v.element.code_dhis2_coc || undefined,
      value: String(v.valeur_retenue)
    }))
}
process.stdout.write(JSON.stringify(charge, null, 2))
