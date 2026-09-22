#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Démarrage guidé : installe les dépendances si besoin, signale l'absence de
# configuration, puis lance le serveur de développement.
#
#   ./scripts/demarrer.sh
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f package.json ]; then
  echo "Erreur : lancez ce script depuis le dossier du projet." >&2
  exit 1
fi

if [ ! -d node_modules ]; then
  echo "Installation des dépendances, patientez quelques instants…"
  npm install
fi

if [ ! -f .env.local ] && [ ! -f .env ]; then
  echo "Aucun fichier .env.local : l'application démarrera en mode découverte."
  echo "Pour relier la base : cp .env.example .env.local puis renseignez les valeurs Supabase."
fi

echo
echo "Ouvrez dans le navigateur l'adresse affichée ci-dessous par Vite."
echo "N'ouvrez jamais index.html par un double-clic : le navigateur ne sait pas compiler main.jsx."
echo
exec npm run dev
