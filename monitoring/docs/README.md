# Collection monitoring pour le Lan ETS

## Vue d'ensemble

La collection `cedille.monitoring` regroupe les rôles nécessaires pour construire une pile d'observabilité autour de Prometheus, Grafana et d'outils de collecte de métriques ou de logs.

## Rôles prévus

- `prometheus` : agrégation des métriques des switches, de Kea DHCP, de BIND9 et des exporters.
- `grafana` : observabilité et dashboards à partir des sources de données récupérées.
- `loki` : centralisation des logs dans une pile plus légère qu'Elastic.
- `alloy` : collecte et envoi des logs vers Loki.
- `node_exporter` : métriques système des hôtes Linux.
- `blackbox_exporter` : checks réseau, HTTP et ICMP.
- `snmp_exporter` : métriques SNMP des switches et équipements réseau.
- `alertmanager` : routage des alertes Prometheus.

## Usage

Les rôles sont pensés pour être consommés depuis un autre repository de déploiement.

```yaml
- name: Déployer la pile de monitoring
  hosts: monitoring_hosts
  roles:
    - cedille.monitoring.prometheus
    - cedille.monitoring.grafana
    - cedille.monitoring.loki
    - cedille.monitoring.alloy
```

## Convention

Chaque rôle suit la même structure:

1. `defaults/main.yaml` pour les variables agrégées;
2. `tasks/install.yaml` pour l'installation;
3. `tasks/config.yaml` pour la configuration;
4. `handlers/main.yaml` pour les redémarrages;
5. `meta/main.yml` pour la compatibilité Ubuntu 24.04.
