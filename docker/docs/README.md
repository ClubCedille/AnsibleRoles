# Collection Docker pour le Lan ETS

`## Installation

Pour installer la collection Docker, utilisez la commande suivante :

```bash
ansible-galaxy collection install -r requirements.yml
```

Assurez-vous que le fichier `requirements.yml` est présent à la racine de votre projet et contient les informations nécessaires pour installer la collection Docker:

```yaml
collections:
  - name: cedille.docker
    version: "1.0.0"
```

## Rôles disponibles

La collection Docker comprend les rôles suivants :
- `install` : Rôle pour installer docker.

## Utilisation

Pour utiliser les rôles de la collection Docker dans vos playbooks Ansible, vous pouvez les inclure de la manière suivante :

```yaml
- name: Configurer les hotes docker
  hosts: docker_hosts
  roles:
    - cedille.docker.install
```
`