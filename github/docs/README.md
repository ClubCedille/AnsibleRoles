# Collection GitHub pour ClubCedille

## Vue d'ensemble

La collection `cedille.github` regroupe les rôles nécessaires pour déployer
des composants liés à GitHub sur des hôtes cibles.

## Rôles disponibles

- `runner` : déploie et enregistre un runner GitHub Actions self-hosted
  (binaire officiel `actions/runner`, exécution host-native — les jobs
  tournent directement sur la VM, pas dans un conteneur intermédiaire comme
  act_runner/Forgejo, sauf si le workflow demande explicitement un
  `container:`).

## Installation

```bash
ansible-galaxy collection install -r requirements.yml
```

```yaml
collections:
  - name: cedille.github
    version: "0.1.0"
```

## Utilisation

```yaml
- name: Déployer un runner GitHub Actions
  hosts: github_runners
  roles:
    - cedille.docker.install
    - cedille.github.runner
```

Avant exécution, définir dans les group_vars/host_vars consommateurs :
`github_runner_org` et `github_runner_registration_token`. Voir
`roles/runner/defaults/main.yaml` pour la liste complète des variables.

### Particularité : le token d'enregistrement n'est pas un secret statique

Contrairement à Forgejo (où `forgejo_runner_registration_token` est un jeton
long-lived généré une fois par runner dans l'UI), l'API GitHub
(`POST /orgs/{org}/actions/runners/registration-token`) ne délivre que des
jetons **valides 1h**, ré-utilisables pour enregistrer plusieurs runners
pendant cette fenêtre mais pas au-delà. `github_runner_registration_token`
doit donc être calculé à chaque exécution du playbook (tâche
`delegate_to: localhost` qui appelle l'API avec un identifiant admin
org — PAT classic `admin:org`, ou jeton d'installation GitHub App via Vault
si l'App a la permission `organization_self_hosted_runners`), jamais commité
en clair ni vaulté statiquement. Voir `playbooks/network/github-runners.yaml`
dans AnsibleInfra pour le pattern complet.

Le rôle est idempotent : si `.runner` existe déjà dans
`github_runner_paths.data_dir`, `config.sh` n'est pas ré-exécuté, donc un
jeton expiré/absent n'empêche pas les runs suivants une fois l'enregistrement
initial fait.

## Convention

Le rôle suit la structure standard des autres collections `cedille.*` :
`defaults/main.yaml`, `tasks/main.yaml`, `handlers/main.yaml`,
`templates/`, `meta/main.yml`.
