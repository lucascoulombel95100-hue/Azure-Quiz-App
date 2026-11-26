# J1 — Conteneurisation locale (26/11/2026)

## Lancement
cp .env.example .env   # puis remplacer les valeurs
docker compose up --build -d
Quiz : http://localhost:8087 — Admin : http://localhost:8087/gestion-quiz

## Architecture
navigateur → frontend (nginx:80, publié sur 8087) → /api → backend (node:3007) → db (postgres:5432)
Seul le frontend est exposé sur l'hôte ; backend et db restent sur le réseau interne Compose.

## Persistance
Volume nommé `pgdata` monté sur /var/lib/postgresql/data.
`docker compose down` supprime les conteneurs mais pas le volume → données conservées (voir 06 et 07).
`init.sql` n'est exécuté qu'au premier démarrage (volume vide).

## Fichiers
01 build · 02 images · 03 services · 04 /health · 05 logs · 06/07 données avant/après recréation · 08 volume · 09-11 captures
