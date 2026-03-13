# Collection Proxmox pour le Lan ETS

## Installation

Pour installer la collection Proxmox, utilisez la commande suivante :

```bash
ansible-galaxy collection install -r requirements.yml
```

Assurez-vous que le fichier `requirements.yml` est présent à la racine de votre projet et contient les informations nécessaires pour installer la collection Proxmox:

```yaml
collections:
  - name: cedille.proxmox
    version: "1.0.1"
```

## Rôles disponibles

La collection Proxmox comprend les rôles suivants :
- `apt_sources` : Rôle pour configurer les sources APT sur des hôtes
- `network` : Rôle pour configurer les interfaces réseau, les bridges, bonds et VLANs sur des hôtes Proxmox
- `pull_disk` : Rôle pour télécharger une image disque à utiliser pour les VM Proxmox

## Utilisation

Pour utiliser les rôles de la collection Proxmox dans vos playbooks Ansible, vous pouvez les inclure de la manière suivante :

```yaml
- name: Configurer les sources APT sur Proxmox
  hosts: proxmox_hosts
  roles:
    - cedille.proxmox.apt_sources
- name: Configurer le réseau sur Proxmox
  hosts: proxmox_hosts
  roles:
    - cedille.proxmox.network
- name: Télécharger une image disque pour une VM sur Proxmox
  hosts: proxmox_hosts
  roles:
    - cedille.proxmox.pull_disk
```
