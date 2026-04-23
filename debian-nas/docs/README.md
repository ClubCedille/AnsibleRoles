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
- `zfs` : installation de ZFS avec préférence APT dédiée, paquets noyau requis et création optionnelle de pool/datasets
- `cockpit` : installation de Cockpit et des plugins sélectionnés, avec dépôt 45Drives
- `file_sharing` : installation de Samba et/ou NFS selon les variables d'activation
- `garage_s3` : déploiement du binaire Garage et de sa configuration S3; le rôle attend une URL de binaire via `garage.binary_url`

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

Exemple avec création d'un pool ZFS à partir d'une liste de disques :

```yaml
- name: Préparer un hôte NAS Debian
  hosts: nas_hosts
  become: true
  roles:
    - role: cedille.debian_nas.zfs
      vars:
        zfs_manage_pool: true
        zfs_pool:
          name: tank
          mode: raidz1
          disks:
            - /dev/disk/by-id/ata-disk1
            - /dev/disk/by-id/ata-disk2
            - /dev/disk/by-id/ata-disk3
        zfs_datasets:
          - tank/data
          - tank/backups
```

Variables principales du rôle `zfs` :

```yaml
zfs_manage_pool: false
zfs_pool:
  name: tank
  mode: stripe # stripe | mirror | raidz | raidz1 | raidz2 | raidz3
  disks: []
  force: false
  ashift: 12
  compression: lz4
  atime: false
  mountpoint: "/{{ zfs_pool.name }}"
zfs_datasets: []
```
