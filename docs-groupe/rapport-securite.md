# J2 : rapport de sécurité des images

Outil : Trivy 0.70.0 (lancé en conteneur, version fixée), sévérités HIGH et CRITICAL.
Commandes et rapports complets : dossier `preuves/J2/`.

## Résultat avant / après

| Image | CRITICAL avant | HIGH avant | CRITICAL après | HIGH après | Taille avant | Taille après |
|---|---|---|---|---|---|---|
| frontend | 3 | 67 | 0 | 0 | 73,7 Mo | 111 Mo |
| backend | 0 | 10 | 0 | 0 | 268 Mo | 273 Mo |

## Constat préalable : build non reproductible

`backend/Dockerfile` utilisait `npm ci` sans `package-lock.json` versionné :
le build échouait sur un autre poste (`preuves/J2/00-build-backend-sans-lockfile.txt`).

## Corrections et justifications

| Correction | Pourquoi |
|---|---|
| Ajout de `backend/package-lock.json` | Versions exactes de chaque bibliothèque : build identique sur tous les postes |
| Frontend : `nginx:1.27-alpine` remplacé par `nginxinc/nginx-unprivileged:mainline-alpine` | L'ancienne image reposait sur Alpine 3.21 (70 failles). La branche mainline contient un nginx corrigé (la branche stable avait encore nginx 1.30.6 avec 4 CRITICAL). La variante unprivileged tourne sans root |
| Frontend : écoute sur 8080 (template nginx + Compose `8087:8080`) | Un utilisateur non root ne peut pas ouvrir un port inférieur à 1024 |
| `apk upgrade` dans les deux images | Applique les correctifs Alpine parus depuis la publication des images de base |
| Backend : build en deux étapes, npm/npx/corepack/yarn supprimés de l'image finale | Les 10 failles HIGH étaient toutes dans npm (`brace-expansion`, `ip-address`, `pacote`, `picomatch`, `sigstore`). L'appli n'utilise pas npm pour tourner : on le retire, ce qui supprime aussi un outil exploitable par un attaquant |
| Backend : `COPY package.json server.js` au lieu de `COPY . .` | Seuls les fichiers nécessaires entrent dans l'image |
| Utilisateurs | frontend : `nginx`, backend : `node`. Aucun conteneur en root (`preuves/J2/04-utilisateurs-final.txt`) |

## Vulnérabilités résiduelles et limites

- Aucune vulnérabilité HIGH ou CRITICAL restante au 26/11/2026.
- Les sévérités MEDIUM et LOW n'ont pas été traitées. `npm` signale 4 vulnérabilités modérées
  dans les dépendances du backend : à surveiller, sans blocage selon la politique de la CI (CRITICAL).
- La taille des images n'a pas baissé : supprimer npm dans une couche supérieure le masque
  sans l'effacer de la couche de base. Le gain porte sur la sécurité, pas sur la taille.
- Les failles évoluent chaque jour : le scan sera refait automatiquement par la CI (J6).