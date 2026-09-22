#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Chargement du schéma et du jeu de démonstration sur une base PostgreSQL
# locale (poste de développement ou serveur du centre de santé).
#
# Usage :
#   PGURL="postgresql://postgres:motdepasse@localhost:5432/centre_sante" \
#     ./scripts/charger_base_locale.sh [--sans-seed]
# ---------------------------------------------------------------------------
set -euo pipefail

PGURL="${PGURL:-postgresql://postgres:postgres@localhost:5432/centre_sante}"
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
SANS_SEED="${1:-}"

echo "Base cible : ${PGURL%%\?*}"

for fichier in "$RACINE"/supabase/migrations/*.sql; do
  echo "→ $(basename "$fichier")"
  psql "$PGURL" -v ON_ERROR_STOP=1 -q -f "$fichier"
done

if [ "$SANS_SEED" != "--sans-seed" ]; then
  echo "→ seed.sql (jeu de démonstration Kamalondo)"
  psql "$PGURL" -v ON_ERROR_STOP=1 -q -f "$RACINE/supabase/seed.sql"
fi

psql "$PGURL" -c "SELECT count(*) AS tables FROM pg_tables WHERE schemaname = 'cs';"
psql "$PGURL" -c "SELECT count(*) AS fonctions FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'cs';"
echo "Chargement terminé."
