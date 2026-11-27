#!/usr/bin/env bash
# Démo J6 : vérifie qu'un texte de question est bien dans le site en ligne,
# sans avoir à jouer tout le quiz (les questions sont mélangées).
#
# Utilisation : ./scripts/verifier-question.sh "un morceau du texte de la question"

set -euo pipefail

TEXTE="${1:?Donner le texte à chercher, entre guillemets}"
RG="${RG:-rg-quiz-groupe01}"

FQDN="$(az containerapp show -n quiz-frontend -g "$RG" --query properties.configuration.ingress.fqdn -o tsv 2>/dev/null)"
MAIN="$(curl -fsS "https://$FQDN/" | grep -oE '/assets/main-[A-Za-z0-9_-]+\.js' | head -1)"
QUESTIONS="$(curl -fsS "https://$FQDN$MAIN" | grep -oE 'questions_docker-[A-Za-z0-9_-]+\.js' | head -1)"

echo "Site en ligne  : https://$FQDN"
echo "Image frontend : $(az containerapp show -n quiz-frontend -g "$RG" --query 'properties.template.containers[0].image' -o tsv 2>/dev/null)"

if curl -fsS "https://$FQDN/assets/$QUESTIONS" | grep -qF "$TEXTE"; then
  echo "OK : le texte est bien en ligne"
else
  echo "PAS ENCORE : texte introuvable (le déploiement n'est peut-être pas terminé)"
  exit 1
fi
