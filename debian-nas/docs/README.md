# Collection Debian NAS

## Installation

Pour installer la collection Debian NAS, utilisez la commande suivante :

```bash
ansible-galaxy collection install -r requirements.yml
```

Le fichier `requirements.yml` doit contenir la collection suivante :

```yaml
collections:
  - name: cedille.debian_nas
    version: "1.0.1"
```

Cette collection suppose que la base Debian est déjà préparée avec la collection `cedille.debian_common`.

## Rôles disponibles

La collection Debian NAS fournit les rôles suivants :
- `zfs` : installation de ZFS avec préférence APT dédiée et paquets noyau requis
- `cockpit` : installation de Cockpit et des plugins sélectionnés, avec dépôt 45Drives
- `file_sharing` : installation de Samba et/ou NFS selon les variables d'activation
- `garage_s3` : déploiement du binaire Garage et de sa configuration S3; le rôle attend une URL de binaire via `garage_binary_url`

## Utilisation

Exemple d'utilisation dans un playbook :

```yaml
- name: Préparer un hôte NAS Debian
  hosts: nas_hosts
  become: true
  roles:
    - cedille.debian_common.base_system
    - cedille.debian_nas.zfs
    - cedille.debian_nas.cockpit
```
