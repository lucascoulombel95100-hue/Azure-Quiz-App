#!/usr/bin/env bash
# J6 : donne à GitHub Actions le droit de déployer sur Azure, sans mot de passe (OIDC).
#
# Ce que fait le script :
#   1. crée une identité managée « id-github-quiz » dans le groupe de ressources (gratuit) ;
#   2. autorise GitHub Actions à l'utiliser, mais seulement depuis la branche main de notre dépôt ;
#   3. lui donne le rôle Contributor sur le groupe de ressources seulement (pas sur tout l'abonnement) ;
#   4. affiche les 3 valeurs à mettre dans les secrets du dépôt GitHub.
#
# L'étape 3 demande le droit de donner des rôles (Owner de l'abonnement).
# Avec un compte qui n'a que Contributor, le script le signale : la personne Owner le relance.
# On peut relancer le script sans risque : ce qui existe déjà est gardé.
# Aucun mot de passe n'est créé ni stocké.
#
# Utilisation : ./scripts/setup-github-oidc.sh

set -euo pipefail

RG="${RG:-rg-quiz-groupe01}"
LOCATION="${LOCATION:-germanywestcentral}"
IDENTITY="${IDENTITY:-id-github-quiz}"
REPO="${REPO:-lucascoulombel95100-hue/Azure-Quiz-App}"

if [ -n "${AZ_SUBSCRIPTION:-}" ]; then
  az account set --subscription "$AZ_SUBSCRIPTION"
fi

echo "==> 1. Identité $IDENTITY"
if az identity show -g "$RG" -n "$IDENTITY" -o none 2>/dev/null; then
  echo "    existe déjà"
else
  az identity create -g "$RG" -n "$IDENTITY" -l "$LOCATION" -o none
  echo "    créée"
fi
CLIENT_ID="$(az identity show -g "$RG" -n "$IDENTITY" --query clientId -o tsv)"
PRINCIPAL_ID="$(az identity show -g "$RG" -n "$IDENTITY" --query principalId -o tsv)"

echo "==> 2. Connexion autorisée depuis GitHub Actions (branche main de $REPO)"
if az identity federated-credential show -g "$RG" --identity-name "$IDENTITY" -n github-main -o none 2>/dev/null; then
  echo "    existe déjà"
else
  az identity federated-credential create -g "$RG" --identity-name "$IDENTITY" -n github-main \
    --issuer https://token.actions.githubusercontent.com \
    --subject "repo:$REPO:ref:refs/heads/main" \
    --audiences api://AzureADTokenExchange -o none
  echo "    créée"
fi

echo "==> 3. Rôle Contributor sur $RG uniquement"
RG_ID="$(az group show -n "$RG" --query id -o tsv)"
if [ -n "$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$RG_ID" --role Contributor --query "[].id" -o tsv 2>/dev/null)" ]; then
  echo "    déjà donné"
elif az role assignment create --assignee-object-id "$PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
       --role Contributor --scope "$RG_ID" -o none 2>/dev/null; then
  echo "    donné (il faut parfois quelques minutes avant qu'il soit actif)"
else
  echo "    IMPOSSIBLE avec ce compte : il faut être Owner pour donner un rôle." >&2
  echo "    La personne Owner de l'abonnement doit relancer ce script." >&2
fi

echo "==> 4. Secrets à créer dans GitHub (Settings > Secrets and variables > Actions)"
echo "    AZURE_CLIENT_ID       = $CLIENT_ID"
echo "    AZURE_TENANT_ID       = $(az account show --query tenantId -o tsv)"
echo "    AZURE_SUBSCRIPTION_ID = $(az account show --query id -o tsv)"
