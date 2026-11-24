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
- `pwdssh` : Rôle pour réactiver l'authentification SSH par mot de passe sur Ubuntu en retirant le drop-in cloud-init et en activant KbdInteractiveAuthentication
- `permissions` : Rôle pour gérer le RBAC Proxmox (rôles custom et ACL sur les chemins `/pool`, `/vms`, `/nodes`, `/storage`) via l'API. Les identités sont fournies par le realm Authentik (OIDC) : le rôle ne crée ni utilisateurs ni groupes Proxmox.
- `vm` : Rôle pour créer/configurer des VMs Proxmox (pools et tags inclus)

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
- name: Préparer une machine Ubuntu pour l'accès SSH par mot de passe
  hosts: ubuntu_hosts
  roles:
    - cedille.proxmox.pwdssh
- name: Gérer les ACL Proxmox des groupes Authentik
  hosts: pve01.mgmt.etsmtl.club
  connection: local
  gather_facts: false
  roles:
    - cedille.proxmox.permissions
```

### Rôle `permissions`

Le rôle consomme `permissions_proxmox_api` (même forme que `vm_proxmox_api`) et une
liste d'ACL désirées :

```yaml
permissions_proxmox_api:
  user: "root@pam"
  password: "{{ pve_api_password }}"
  host: "10.0.21.51"
  validate_certs: false

permissions_acls:
  - path: "/pool/Management"
    roleid: "PVEVMAdmin"
    type: "group"
    ugid: "k8s-pmx-shared-admin"
    propagate: true
    state: "present"
```

Seules les entrées listées sont gérées : il n'y a **aucune purge implicite**, une
révocation s'exprime avec `state: absent`. Les rôles Proxmox intégrés ne sont pas
réécrits ; `permissions_manage_roles: true` + `permissions_roles` permettent de
déclarer des rôles custom.

`community.proxmox.proxmox_access_acl` ne supporte pas `--check` : en mode
dry-run, le rôle lit l'API en lecture seule et échoue si l'état désiré n'est pas
déjà appliqué.
