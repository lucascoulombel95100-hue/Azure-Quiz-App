#!/usr/bin/env bash
# Déploiement de Quiz App sur Azure.
# Partie J3 : crée le registre d'images (ACR) et y envoie les images du frontend et du backend.
#
# Prérequis :
#   - Azure CLI connecté (az login) sur l'abonnement qui contient le groupe de ressources.
#     Sinon : az account set --subscription <id>, ou lancer avec AZ_SUBSCRIPTION=<id>
#   - Docker Desktop lancé
#   - Sous Windows : lancer depuis Git Bash ou WSL
#
# Utilisation (depuis n'importe quel dossier du projet) :
#   ./scripts/deploy.sh
#
# Les valeurs par défaut peuvent être changées sans modifier le script, par exemple :
#   ACR_NAME=monregistre ./scripts/deploy.sh
#
# Opérations sensibles :
#   - crée un registre ACR Basic : payant, environ 0,16 € par jour sur les crédits Azure
#   - envoie les images dans ce registre
# Aucun secret n'est écrit dans ce script.
#
# Le tag des images est le commit Git actuel : committer avant de déployer.

set -euo pipefail

RG="${RG:-rg-quiz-groupe01}"
# Notre abonnement Azure for Students n'autorise que certaines régions (France Central est refusée).
# Germany West Central est autorisée pour ACR, Log Analytics et Container Apps.
LOCATION="${LOCATION:-germanywestcentral}"
ACR_NAME="${ACR_NAME:-acrquizg01}"

cd "$(dirname "$0")/.."
TAG="${TAG:-$(git rev-parse --short HEAD)}"

if [ -n "${AZ_SUBSCRIPTION:-}" ]; then
  az account set --subscription "$AZ_SUBSCRIPTION"
fi

echo "==> Abonnement actif : $(az account show --query name -o tsv)"
if ! az group show -n "$RG" -o none 2>/dev/null; then
  echo "Groupe de ressources $RG introuvable dans cet abonnement." >&2
  echo "Vérifier l'abonnement actif : az account list --refresh -o table" >&2
  exit 1
fi

echo "==> Registre $ACR_NAME"
if az acr show -n "$ACR_NAME" -g "$RG" -o none 2>/dev/null; then
  echo "    existe déjà"
else
  az acr create -g "$RG" -n "$ACR_NAME" -l "$LOCATION" --sku Basic -o none
  echo "    créé"
fi

LOGIN_SERVER="$(az acr show -n "$ACR_NAME" -g "$RG" --query loginServer -o tsv)"
az acr login -n "$ACR_NAME"

# Azure fait tourner les conteneurs en amd64 : on construit pour cette plateforme,
# même sur un Mac Apple Silicon (arm64).
echo "==> Construction des images (tag $TAG)"
docker build --platform linux/amd64 -t "$LOGIN_SERVER/quiz-backend:$TAG" ./backend
docker build --platform linux/amd64 -t "$LOGIN_SERVER/quiz-frontend:$TAG" .

echo "==> Envoi des images dans $LOGIN_SERVER"
docker push "$LOGIN_SERVER/quiz-backend:$TAG"
docker push "$LOGIN_SERVER/quiz-frontend:$TAG"

echo "==> Images présentes dans le registre"
az acr repository show-tags -n "$ACR_NAME" --repository quiz-backend -o table
az acr repository show-tags -n "$ACR_NAME" --repository quiz-frontend -o table

echo "==> Terminé : $LOGIN_SERVER/quiz-backend:$TAG et $LOGIN_SERVER/quiz-frontend:$TAG"

# ---------- Partie J4 : mise à jour des applis Container Apps ----------
# quiz-backend et quiz-frontend ont été créées une première fois à la main (J4).
# Ici, on leur donne seulement la nouvelle image. Les secrets ne sont pas touchés :
# ils restent stockés dans Azure, jamais dans ce script.
if az containerapp show -n quiz-backend -g "$RG" -o none 2>/dev/null; then
  echo "==> Mise à jour des applis Container Apps (tag $TAG)"
  az containerapp update -n quiz-backend -g "$RG" --image "$LOGIN_SERVER/quiz-backend:$TAG" -o none
  az containerapp update -n quiz-frontend -g "$RG" --image "$LOGIN_SERVER/quiz-frontend:$TAG" -o none
  FQDN="$(az containerapp show -n quiz-frontend -g "$RG" --query properties.configuration.ingress.fqdn -o tsv)"
  echo "==> Site en ligne : https://$FQDN"
else
  echo "==> Applis Container Apps absentes : les créer d'abord (voir les étapes du J4)."
fi
