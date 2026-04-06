# Collection Debian Common

## Installation

Pour installer la collection Debian Common, utilisez la commande suivante :

```bash
ansible-galaxy collection install -r requirements.yml
```

Assurez-vous que le fichier `requirements.yml` contient la collection suivante :

```yaml
collections:
  - name: cedille.debian_common
    version: "1.0.1"
```

## Rôles disponibles

La collection Debian Common fournit les rôles suivants :
- `base_system` : socle système Debian avec mise à jour APT, sources backports et paquets de base
- `network` : configuration d'une adresse IP statique via NetworkManager et nmcli
- `ssh` : installation et activation du service SSH

## Utilisation

Exemple d'utilisation dans un playbook :

```yaml
- name: Préparer un hôte Debian
  hosts: debian_hosts
  become: true
  roles:
    - cedille.debian_common.base_system
    - cedille.debian_common.network
    - cedille.debian_common.ssh
```
