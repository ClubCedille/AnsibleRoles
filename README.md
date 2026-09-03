# AnsibleRoles

Roles Ansible pour l'infrastructure physique à administrer pour les clubs étudiants.
Fortement inspiré des collections internes de l'infrastructure du Lan ETS

## Notes de noms de fichiers

Il est à noter que les fichiers .yml et .yaml sont utilisés dans des cas spécifiques pour différencier les types de contenu.

- Les fichiers `.yml` sont utilisés pour les fichiers galaxy et les autres fichiers qui ne nécessitent pas de linting propre à Ansible.
- Les fichiers `.yaml` sont utilisés pour les playbooks et les rôles Ansible, où le linting spécifique à Ansible est appliqué.

## Collections et rôles

- [proxmox](proxmox/docs/README.md) : Collection de rôles Ansible pour gérer Proxmox.
- [opnsense](opnsense/docs/README.md) : Collection générique pour gérer OPNsense.
- [netservices](netservices/docs/README.md) : Collection de rôles réseau pour Kea DHCP, BIND9 et Stork.
- [monitoring](monitoring/docs/README.md) : Collection de rôles pour Prometheus, Grafana, Loki et les exporters (node, smartctl, blackbox, snmp, ipmi, pve).
- [docker](docker/docs/README.md) : Collection de rôles pour installer et configurer Docker.
- [forgejo](forgejo/docs/README.md) : Collection de rôles pour déployer les runners Forgejo Actions.
- [omni](omni/docs/README.md) : Collection de rôles pour déployer Sidero Omni (gestionnaire de clusters Talos Kubernetes).
- [cisco-3850](cisco-3850/docs/README.md) : Collection de rôles pour la configuration des switches Cisco 3850.
- [cs2](cs2/docs/README.md) : Collection de rôles pour le déploiement de serveurs CS2 (LanETS).
- [pkgcache](pkgcache/docs/README.md) : Collection de rôles pour les mirrors de cache de paquets (apt, dnf, nix, pacman, pkg, OPNsense).

Tous les rôles réutilisables de l'infrastructure Cedille vivent ici — le
repository d'exécution [AnsibleInfra](https://github.com/ClubCedille/AnsibleInfra)
ne contient plus aucun rôle local, uniquement des playbooks et inventaires qui
consomment ces collections via `collections/requirements.yml`.

## Extensions suggérées

Le dossier ./.vscode contient des configurations pour les extensions suivantes, qui sont recommandées pour une expérience de développement optimale :

- Prettier - Code formatter : pour le formatage automatique du code YAML.
- Ansible : pour le linting et la validation des fichiers Ansible.
- YAML : pour le support avancé du langage YAML, y compris la validation et le linting.
- Better Jinja : pour une meilleure prise en charge de la syntaxe Jinja utilisée dans les playbooks Ansible.
