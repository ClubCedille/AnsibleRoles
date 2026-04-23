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
- [debian-common](debian-common/docs/README.md) : Collection de base pour les hôtes Debian standards.
- [debian-nas](debian-nas/docs/README.md) : Collection dédiée aux hôtes Debian orientés NAS.

## Extensions suggérées

Le dossier ./.vscode contient des configurations pour les extensions suivantes, qui sont recommandées pour une expérience de développement optimale :
- Prettier - Code formatter : pour le formatage automatique du code YAML.
- Ansible : pour le linting et la validation des fichiers Ansible.
- YAML : pour le support avancé du langage YAML, y compris la validation et le linting.
- Better Jinja : pour une meilleure prise en charge de la syntaxe Jinja utilisée dans les playbooks Ansible.
