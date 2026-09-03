# Collection Forgejo pour le Lan ETS

## Vue d'ensemble

La collection `cedille.forgejo` regroupe les rôles nécessaires pour déployer des
composants Forgejo sur des hôtes cibles.

## Rôles disponibles

- `runner` : déploie et enregistre un runner Forgejo Actions (binaire
  `forgejo-runner` + exécuteur Docker, avec support optionnel de l'exécution
  host-native pour les labels `*:host`).

## Installation

```bash
ansible-galaxy collection install -r requirements.yml
```

```yaml
collections:
  - name: cedille.forgejo
    version: "0.1.0"
```

## Utilisation

```yaml
- name: Déployer un runner Forgejo Actions
  hosts: forgejo_runners
  roles:
    - cedille.docker.install
    - cedille.forgejo.runner
```

Avant exécution, définir dans les group_vars/host_vars consommateurs :
`forgejo_runner_instance_url`, `forgejo_runner_uuid` et
`forgejo_runner_registration_token` (ce dernier chiffré via ansible-vault).
Voir `roles/runner/defaults/main.yaml` pour la liste complète des variables.

## Convention

Le rôle suit la structure standard des autres collections `cedille.*` :
`defaults/main.yaml`, `tasks/main.yaml`, `handlers/main.yaml`,
`templates/`, `meta/main.yml`.
