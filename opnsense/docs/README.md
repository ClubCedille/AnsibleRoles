# Collection opnsense pour le Lan ETS

## Installation

Pour installer la collection opnsense, utilisez la commande suivante :

```bash
ansible-galaxy collection install -r requirements.yml
```

Assurez-vous que le fichier `requirements.yml` est présent à la racine de votre projet et contient les informations nécessaires pour installer la collection opnsense.

```yaml
collections:
  - name: cedille.opnsense
    version: "1.0.1"
```

## Rôles disponibles

La collection opnsense comprend les rôles suivants :
- `config` : Rôle pour configurer une instance de OPNsense après l'installation

## Utilisation

Pour utiliser les rôles de la collection opnsense dans vos playbooks Ansible, vous pouvez les inclure de la manière suivante :

```yaml
- name: Configurer OPNsense
  hosts: opnsense_hosts
  roles:
    - cedille.opnsense.config
```
