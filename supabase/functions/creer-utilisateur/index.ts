// Fonction Edge : création d'un compte utilisateur additionnel par un
// administrateur déjà connecté.
//
// Pourquoi une fonction serveur et pas un simple appel depuis le
// navigateur ? Créer une identité Supabase Auth pour quelqu'un d'autre
// nécessite la clé service_role, qui ne doit jamais être envoyée au
// navigateur (elle contourne toute la sécurité au niveau des lignes).
// Et `supabase.auth.signUp()` côté client remplacerait la session de
// l'administrateur en cours par celle du nouveau compte, ce qu'on ne veut
// pas non plus. Cette fonction s'exécute donc côté serveur, vérifie que
// l'appelant a la permission UTILISATEUR_GERER, puis crée le compte avec la
// clé service_role (fournie automatiquement par Supabase à l'exécution,
// aucun secret à configurer manuellement).
//
// Déploiement : npx supabase functions deploy creer-utilisateur

import { createClient } from 'jsr:@supabase/supabase-js@2'

const ENTETES_CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
}

function reponse(corps: unknown, statut = 200) {
  return new Response(JSON.stringify(corps), {
    status: statut,
    headers: { ...ENTETES_CORS, 'Content-Type': 'application/json' }
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: ENTETES_CORS })

  try {
    const url = Deno.env.get('SUPABASE_URL')!
    const cleAnon = Deno.env.get('SUPABASE_ANON_KEY')!
    const cleService = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const enteteAutorisation = req.headers.get('Authorization') ?? ''

    // Client agissant avec les droits de l'appelant (son jeton de session),
    // pour vérifier sa permission sans jamais utiliser service_role ici.
    const clientAppelant = createClient(url, cleAnon, {
      global: { headers: { Authorization: enteteAutorisation } }
    })

    const { data: autorise, error: erreurPermission } = await clientAppelant.rpc('a_permission', { p_code: 'UTILISATEUR_GERER' })
    if (erreurPermission || !autorise) {
      return reponse({ erreur: 'Permission UTILISATEUR_GERER requise pour créer un compte.' }, 403)
    }

    const { data: structureId, error: erreurStructure } = await clientAppelant.rpc('structure_courante')
    if (erreurStructure || !structureId) {
      return reponse({ erreur: "Impossible de déterminer la structure de l'appelant." }, 400)
    }

    const corps = await req.json()
    const { nom, postNom, prenom, qualification, login, email, motDePasse, roleCode } = corps ?? {}
    if (!nom || !login || !email || !motDePasse || !roleCode) {
      return reponse({ erreur: 'Champs obligatoires manquants (nom, login, email, mot de passe, rôle).' }, 400)
    }
    if (String(motDePasse).length < 8) {
      return reponse({ erreur: 'Le mot de passe doit contenir au moins 8 caractères.' }, 400)
    }

    // Client avec les droits élevés, utilisé uniquement à partir d'ici, une
    // fois la permission de l'appelant confirmée ci-dessus.
    const admin = createClient(url, cleService)

    const { data: nouvelleIdentite, error: erreurCreationAuth } = await admin.auth.admin.createUser({
      email, password: motDePasse, email_confirm: true
    })
    if (erreurCreationAuth) return reponse({ erreur: erreurCreationAuth.message }, 400)

    const { data: agent, error: erreurAgent } = await admin
      .from('agent')
      .insert({
        structure_id: structureId, nom, post_nom: postNom || '', prenom: prenom || '',
        qualification: qualification || 'AUTRE', fonction: roleCode, statut: 'Contractuel',
        date_entree: new Date().toISOString().slice(0, 10)
      })
      .select('id').single()
    if (erreurAgent) {
      await admin.auth.admin.deleteUser(nouvelleIdentite.user.id)
      return reponse({ erreur: erreurAgent.message }, 400)
    }

    const { data: utilisateur, error: erreurUtilisateur } = await admin
      .from('utilisateur')
      .insert({
        agent_id: agent.id, structure_id: structureId, login,
        mot_de_passe_hash: 'GERE_PAR_SUPABASE_AUTH', doit_changer_mdp: true,
        auth_user_id: nouvelleIdentite.user.id
      })
      .select('id').single()
    if (erreurUtilisateur) {
      await admin.auth.admin.deleteUser(nouvelleIdentite.user.id)
      return reponse({ erreur: erreurUtilisateur.message }, 400)
    }

    const { data: role } = await admin.from('role').select('id').eq('code', roleCode).maybeSingle()
    if (role) {
      await admin.from('utilisateur_role').insert({ utilisateur_id: utilisateur.id, role_id: role.id })
    }

    return reponse({ ok: true, id: utilisateur.id })
  } catch (e) {
    return reponse({ erreur: e instanceof Error ? e.message : String(e) }, 500)
  }
})
