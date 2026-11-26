# J0 : vérification de l'abonnement Azure

- Abonnement : Azure for Students, état Enabled
- Crédits restants au 26/11/2026 : 100 €
- Région retenue : France Central (francecentral), création du groupe acceptée
- Services activés : Microsoft.App, Microsoft.OperationalInsights, Microsoft.ContainerRegistry (Registered)
- Groupe de ressources du projet : rg-quiz-groupe01
- Accès de Lucas : rôle Contributor sur rg-quiz-groupe01

## Restrictions rencontrées

- Double authentification (MFA) obligatoire pour créer des ressources avec Azure CLI :
  erreur AADSTS50076 à la première tentative, résolue avec
  `az login --tenant <tenant> --scope https://management.core.windows.net//.default --claims-challenge <...>`.