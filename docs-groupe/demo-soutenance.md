# Démo de la soutenance — antisèche

**But :** montrer la chaîne complète, en partant de zéro :

1. on remet **à la main** une vieille image Alpine pleine de failles → la CI la **bloque** ;
2. on remet la bonne image → la CI passe au **vert** ;
3. on modifie une question → fusion → **CD** → la question est **en ligne**.

**Qui fait quoi :** Lucas pilote (terminal, VS Code, fusion). Hameem approuve la PR depuis son ordinateur.

**Durées mesurées :** CI environ **40 s**, CD environ **2 min**. La démo complète prend environ **6 minutes** : on la fait juste après la diapo 5 (CI/CD).

---

## 1. Juste avant de passer (5 minutes)

- [ ] `az account show -o table` répond (sinon `az login`)
- [ ] Le site en ligne est ouvert et chargé (le frontend se met en veille)
- [ ] Onglets ouverts : GitHub (**Pull requests** et **Actions**), le portail Azure sur `quiz-frontend` > **Révisions**
- [ ] VS Code ouvert sur le projet, avec `Dockerfile` et `questions_docker.js`
- [ ] Terminal dans le projet, à jour :

```bash
git checkout main
git pull
```

- [ ] Hameem est connecté à GitHub et prêt à approuver

---

## 2. Pendant la démo

### Étape 1 — Une image vulnérable : la CI bloque

```bash
git checkout -b demo/live
```

Dans VS Code, `Dockerfile`, dernière étape (`FROM nginx…`) :

- remplacer `FROM nginxinc/nginx-unprivileged:mainline-alpine` par `FROM nginx:1.27-alpine` (Alpine 3.21, l'image de J1) ;
- supprimer la ligne `RUN apk upgrade --no-cache` (sinon elle corrige les failles toute seule).

```bash
git add Dockerfile
git commit -m "Démo : image nginx 1.27 (Alpine 3.21, vulnérable)"
git push -u origin demo/live
```

Ouvrir la PR avec le lien affiché par `git push`. Après environ 40 s :

- `build-scan (frontend)` est **rouge** → **Details** → étape « Contrôle bloquant » : le tableau Trivy avec les failles **CRITICAL** ;
- en bas de la PR : **« Merging is blocked »**.

À dire : « Trivy trouve des failles CRITICAL dans l'image : la CI échoue et GitHub refuse la fusion. »

### Étape 2 — On remet la bonne image : vert

```bash
git checkout origin/main -- Dockerfile
git add Dockerfile
git commit -m "Démo : retour à l'image nginx non root à jour"
git push
```

`git checkout origin/main -- Dockerfile` remet le Dockerfile de `main`, celui corrigé en J2. Après environ 40 s : les 2 contrôles sont **verts**. La PR attend encore une approbation.

À dire : « Avec l'image corrigée en J2, il n'y a plus de faille grave : le contrôle passe. »

### Étape 3 — On modifie une question : elle part en ligne

Dans VS Code, `questions_docker.js`, 2e question :
`"Quelle est la principale fonction d'un volume Docker ?"` devient `"À quoi sert principalement un volume Docker ?"`

```bash
git add questions_docker.js
git commit -m "Démo : modification d'une question Docker"
git push
```

Après environ 40 s, les contrôles sont verts. Puis :

1. **Hameem approuve** (onglet **Files changed** > **Review changes** > **Approve**) ;
2. Lucas clique sur **Merge pull request** ;
3. onglet **Actions** : le **CD** démarre (environ 2 min).

Quand le CD est vert :

```bash
./scripts/verifier-question.sh "À quoi sert principalement un volume Docker"
```

Réponse attendue : l'image du frontend porte le commit de la fusion, et `OK : le texte est bien en ligne`. Montrer aussi la nouvelle révision dans le portail (**quiz-frontend** > **Révisions**).

À dire : « Le code sain passe, l'image vulnérable est bloquée, et la modification est en ligne sans qu'on ait touché à Azure. »

### Si on n'a pas le temps de taper

Les mêmes modifications en commandes (à la place de VS Code) :

```bash
sed -i '' 's#FROM nginxinc/nginx-unprivileged:mainline-alpine#FROM nginx:1.27-alpine#' Dockerfile
sed -i '' '/RUN apk upgrade --no-cache/d' Dockerfile
```

```bash
sed -i '' "s/Quelle est la principale fonction d'un volume Docker ?/À quoi sert principalement un volume Docker ?/" questions_docker.js
```

---

## 3. Remettre à zéro après une répétition

Seulement si la PR **n'a pas été fusionnée** :

```bash
git restore Dockerfile questions_docker.js; git checkout main && git pull; git branch -D demo/live; git push origin --delete demo/live
```

Cette ligne annule les modifications de la démo dans `Dockerfile` et `questions_docker.js` (et seulement celles-là), revient sur `main` à jour, puis supprime la branche sur le Mac et sur GitHub. La PR se ferme toute seule, et les exécutions de la CI restent visibles dans **Actions**.

---

## 4. Plan B

| Problème | On fait quoi |
| --- | --- |
| La CI est trop lente | Montrer la PR #11 (test Trivy, déjà rouge et bloquée) et une CI verte déjà passée |
| Le CD échoue | Ouvrir l'étape rouge, lire le message (c'est aussi une démo de diagnostic), puis montrer la capture du CD réussi (`preuves/J6`) |
| `az` demande de se reconnecter | `az login`, choisir l'abonnement du groupe |
| Le site met du temps à répondre | Normal après une veille : attendre quelques secondes, recharger |
| Plus de crédits Azure ou ressources supprimées | Montrer les preuves de `preuves/J3` à `J6` (la consigne l'accepte) |

---

## 5. Ce qui a déjà été fait

- **Répétition (PR #12)** : la 1re question est devenue `"Quelle commande Docker construit une image à partir d'un Dockerfile ?"`, et elle est en ligne.
- **Test Trivy (PR #11)** : ancienne image sans `apk upgrade`, `build-scan (frontend)` rouge à l'étape « Contrôle bloquant ». La laisser ouverte jusqu'à la fin de la soutenance, comme plan B.
- ⚠️ Une fois une PR fusionnée, pousser d'autres commits sur la même branche ne lance plus rien : il faut une **nouvelle branche** et une **nouvelle PR**.
