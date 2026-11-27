# Démo de la soutenance — antisèche

**But :** montrer la chaîne complète demandée par la consigne :
modifier une question → branche → Pull Request → contrôle Trivy → approbation → fusion → publication ACR → mise à jour Azure Container Apps → la question est en ligne.

**Qui fait quoi :** Lucas pilote (terminal, VS Code, fusion). Hameem approuve la PR depuis son ordinateur.

**Durées mesurées :** CI environ 3 à 5 min, CD environ 2 min. On lance donc la PR **au tout début** de la soutenance.

---

## 1. Ce soir : à préparer une seule fois

### a) Protéger `main` (pas encore fait)

GitHub → **Settings** → **Rules** → **Rulesets** → **New ruleset** → **New branch ruleset** :

- **Ruleset name :** `protection-main`
- **Enforcement status :** **Active**
- **Target branches :** **Add target** → **Include default branch**
- Cocher **Restrict deletions** et **Block force pushes**
- Cocher **Require a pull request before merging** → **Required approvals : 1**
- Cocher **Require status checks to pass** → **Add checks** → taper `build-scan` → choisir `build-scan (frontend)` et `build-scan (backend)`
- **Create**

Sans cette règle, rien n'empêche de fusionner une PR rouge : la démo du blocage ne marche pas.

### b) Préparer la PR « rouge » du test Trivy (à ne jamais fusionner)

```bash
git checkout -b test/trivy-bloquant origin/main
sed -i '' 's#FROM nginxinc/nginx-unprivileged:mainline-alpine#FROM nginx:1.27-alpine#' Dockerfile
sed -i '' '/RUN apk upgrade --no-cache/d' Dockerfile
git add Dockerfile
git commit -m "Test : image vulnérable pour vérifier le blocage"
git push -u origin test/trivy-bloquant
```

Il faut retirer aussi `apk upgrade` : sinon il met à jour l'ancienne image, les failles CRITICAL disparaissent et le contrôle reste vert.

Ouvrir la PR sur GitHub, attendre que `build-scan (frontend)` soit **rouge**, vérifier que la fusion est **bloquée**, faire une capture (`preuves/J6`). **Laisser la PR ouverte** pour la montrer demain.

### c) Répéter une fois toute la démo — fait (PR #12)

La 1re question est devenue `"Quelle commande Docker construit une image à partir d'un Dockerfile ?"`, et elle est en ligne (image `77ae40f`). Pour la vraie démo, on modifie donc **la 2e question** (partie 3).

⚠️ Une fois la PR fusionnée, pousser d'autres commits sur la même branche ne lance plus rien : il faut une **nouvelle branche** et une **nouvelle PR**.

---

## 2. Juste avant de passer (5 minutes)

- [ ] `az account show -o table` répond (sinon `az login`)
- [ ] Le site en ligne est ouvert et chargé (le frontend se met en veille)
- [ ] Onglets ouverts : GitHub (**Pull requests** et **Actions**), la PR rouge du test Trivy, le portail Azure sur `quiz-frontend` > **Révisions**
- [ ] Terminal dans le projet, à jour :

```bash
git checkout main
git pull
```

- [ ] Hameem est connecté à GitHub et prêt à approuver

---

## 3. Pendant la soutenance

| Quand | Qui | Action |
| --- | --- | --- |
| Début (30 s) | Lucas | Modifier la question, pousser, ouvrir la PR (commandes ci-dessous) |
| Diapos 1 à 4 | Lucas, Hameem | On présente, la CI tourne |
| Diapo 5 | Lucas | Montrer les 2 contrôles **verts** de la PR, puis la PR **rouge** du test Trivy (fusion bloquée) |
| Diapo 5 | Hameem | Approuver la PR de démo |
| Diapo 5 | Lucas | **Merge** → onglet Actions : le **CD** démarre |
| Diapo 6 | Lucas, Hameem | Bilan, le CD tourne |
| Fin | Lucas | CD vert → vérifier la question en ligne et la nouvelle révision |

### Modifier la question (début)

Dans VS Code, ouvrir `questions_docker.js` et changer la 2e question :
`"Quelle est la principale fonction d'un volume Docker ?"`
devient
`"À quoi sert principalement un volume Docker ?"`

Puis :

```bash
git checkout -b demo/question-live
git add questions_docker.js
git commit -m "Démo : modification d'une question Docker"
git push -u origin demo/question-live
```

Ouvrir la PR avec le lien affiché par `git push`.

### Vérifier en ligne (fin)

```bash
./scripts/verifier-question.sh "À quoi sert principalement un volume Docker"
```

Réponse attendue : l'image du frontend porte le nouveau commit, et `OK : le texte est bien en ligne`.
Montrer aussi la nouvelle révision dans le portail (**quiz-frontend** > **Révisions**). On peut aussi ouvrir le site et faire le quiz : les questions sont mélangées, la nouvelle peut arriver n'importe quand.

---

## 4. Plan B

| Problème | On fait quoi |
| --- | --- |
| La CI est trop lente | Montrer une CI verte déjà passée (PR #9 ou #10), et revenir à la PR de démo à la fin |
| Le CD échoue | Ouvrir l'étape rouge, lire le message (c'est aussi une démo de diagnostic), puis montrer la capture du CD réussi (`preuves/J6`) |
| `az` demande de se reconnecter | `az login`, choisir l'abonnement du groupe |
| Le site met du temps à répondre | Normal après une veille : attendre quelques secondes, recharger |
| Plus de crédits Azure ou ressources supprimées | Montrer les preuves de `preuves/J3` à `J6` (la consigne l'accepte) |
