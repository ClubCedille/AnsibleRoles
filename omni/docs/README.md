# Collection Omni pour le Lan ETS

## Vue d'ensemble

La collection `cedille.omni` regroupe les rôles nécessaires pour déployer
[Sidero Omni](https://omni.siderolabs.com/) (gestionnaire de clusters Talos
Kubernetes) via Docker Compose.

## Rôles disponibles

- `deploy` : crée le répertoire de déploiement, génère un certificat TLS
  interne auto-signé (Omni exige `--cert`/`--key` même derrière un reverse
  proxy), template le `Caddyfile` (TLS externe Let's Encrypt) et applique de
  façon idempotente les `SAMLLabelRules` via `omnictl`. Ne déploie pas
  Docker Compose lui-même — à combiner avec `cedille.docker.install`
  (voir exemple ci-dessous).

## Dépendances

Le rôle `deploy` utilise les modules `community.crypto.openssl_privatekey`,
`community.crypto.openssl_csr_pipe` et `community.crypto.x509_certificate`.
Assurez-vous que la collection `community.crypto` est installée côté
consommateur.

## Installation

```bash
ansible-galaxy collection install -r requirements.yml
```

```yaml
collections:
  - name: cedille.omni
    version: "0.1.0"
```

## Utilisation

```yaml
- name: Installer Docker et déployer Omni
  hosts: omni
  vars:
    install_docker_compose_source_type: template
    install_docker_compose_template_src: "{{ playbook_dir }}/../../.cache/roles/cedille.omni.deploy/templates/docker-compose.yml.j2"
    install_docker_compose_target_dir: "{{ omni_deploy_dir }}"
    install_docker_compose_filename: docker-compose.yml
  roles:
    - cedille.omni.deploy      # crée /opt/omni, omni.asc, certs/, Caddyfile
    - cedille.docker.install   # installe Docker, écrit le compose, `docker compose up`
```

Voir `roles/deploy/defaults/main.yaml` pour la liste complète des variables
(FQDN, ports, SAML, EULA, clé WireGuard pour le chiffrement etcd, etc.).

Ce que ce rôle NE fait PAS : le manifest de cluster Talos applicatif
(`Cluster`/`MachineSet`/`MachineSetNode` via `omnictl apply`) est spécifique à
chaque cluster déployé (topologie, comptes CP/workers) et reste donc dans le
repository d'exécution qui le consomme (playbooks), pas dans ce rôle.

## Convention

Le rôle suit la structure standard des autres collections `cedille.*` :
`defaults/main.yaml`, `tasks/main.yaml`, `handlers/main.yaml`,
`templates/`, `meta/main.yml`.
