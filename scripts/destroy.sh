#!/usr/bin/env bash
# Nettoyage : supprime les ressources Azure créées par deploy.sh.
#
# Le groupe de ressources n'est PAS supprimé : il nous a été attribué.
#
# Opération sensible : suppression définitive du registre et de toutes ses images.
# Sauvegarder les preuves avant de lancer ce script.
#
# Utilisation : ./scripts/destroy.sh

set -euo pipefail

RG="${RG:-rg-quiz-groupe01}"
ACR_NAME="${ACR_NAME:-acrquizg01}"

if [ -n "${AZ_SUBSCRIPTION:-}" ]; then
  az account set --subscription "$AZ_SUBSCRIPTION"
fi

echo "Abonnement actif : $(az account show --query name -o tsv)"
echo "Ressources à supprimer dans $RG :"
echo "  - registre $ACR_NAME et toutes ses images"
read -r -p "Confirmer la suppression ? (oui/non) " REPONSE
if [ "$REPONSE" != "oui" ]; then
  echo "Annulé."
  exit 0
fi

if az acr show -n "$ACR_NAME" -g "$RG" -o none 2>/dev/null; then
  az acr delete -n "$ACR_NAME" -g "$RG" --yes
  echo "Registre $ACR_NAME supprimé."
else
  echo "Registre $ACR_NAME déjà absent."
fi
