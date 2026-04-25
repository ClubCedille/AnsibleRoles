# Collection netservices pour le Lan ETS

## Installation

Pour installer la collection netservices, utilisez la commande suivante :

```bash
ansible-galaxy collection install -r requirements.yml
```

Assurez-vous que le fichier `requirements.yml` est présent à la racine de votre projet et contient les informations nécessaires pour installer la collection netservices.

```yaml
collections:
  - name: cedille.netservices
    version: "1.0.1"
```

## Rôles disponibles

La collection netservices comprend les rôles suivants :

- `dhcp` : Installe et configure Kea DHCPv4.
- `dns` : Installe et configure BIND9 avec une configuration orientée cache, zones et mode master/slave.
- `stork` : Installe et configure Stork pour superviser Kea et BIND9.

## Vue d'ensemble

Chaque rôle suit la même logique de base :

1. installation des paquets nécessaires;
2. génération de la configuration à partir des variables des `defaults`;
3. démarrage et activation des services système.

Les rôles sont pensés pour des hôtes Ubuntu 24.04.

## Utilisation

Pour utiliser les rôles de la collection netservices dans vos playbooks Ansible, vous pouvez les inclure de la manière suivante :

```yaml
- name: Configurer les services réseau
  hosts: netservices_hosts
  roles:
    - cedille.netservices.dhcp
    - cedille.netservices.dns
    - cedille.netservices.stork
```

## Variables

Les variables principales sont regroupées dans les `defaults/main.yaml` de chaque rôle. Elles sont organisées par sections pour faciliter les surcharges par `group_vars` ou `host_vars`.
