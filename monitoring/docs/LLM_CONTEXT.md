# Monitoring LLM Context

This document summarizes the `cedille.monitoring` collection for another LLM that will consume these roles from a deployment repository.

## Purpose

The collection provides a monitoring/observability stack for the Lan ETS infrastructure.

Primary targets:

- switches
- Kea DHCP
- BIND9 DNS
- Linux hosts

## Collection identity

- Namespace: `cedille`
- Collection name: `monitoring`
- Galaxy file: `monitoring/galaxy.yml`
- Docs: `monitoring/docs/README.md`

## Roles in scope

- `prometheus`
- `grafana`
- `loki`
- `promtail`
- `node_exporter`
- `blackbox_exporter`
- `snmp_exporter`
- `alertmanager`

## Architectural intent

- The collection is consumed from another repository.
- Variables should stay grouped in `defaults/main.yaml`.
- Each role should keep the same shape: `install.yaml`, `config.yaml`, `handlers/main.yaml`, `meta/main.yml`.
- Prometheus is the aggregation point for metrics.
- Grafana is the visualization layer.
- Loki/Promtail are preferred for logs over Elasticsearch/Kibana in this first iteration.
- SNMP Exporter and Blackbox Exporter are the most relevant add-ons for this infrastructure.
- Alertmanager should be included early so Prometheus alerts have a destination.

## Suggested integration points

- Prometheus scrapes Kea, BIND9, Stork, Node Exporter, SNMP Exporter and Blackbox Exporter.
- Grafana reads from Prometheus and Loki.
- Promtail forwards logs to Loki.
- Node Exporter runs on Linux hosts.
- SNMP Exporter targets switches and network devices.
- Blackbox Exporter probes network reachability and service availability.

## Suggested variable pattern

Use a role-specific prefix, for example:

- `monitoring_prometheus`
- `monitoring_grafana`
- `monitoring_loki`
- `monitoring_promtail`
- `monitoring_node_exporter`
- `monitoring_blackbox_exporter`
- `monitoring_snmp_exporter`
- `monitoring_alertmanager`

Keep variables grouped by sections such as:

- `install`
- `service`
- `paths`
- `server`
- `datasources`
- `scrape_configs`
- `modules`
- `targets`
- `alerts`
- `probes`
- `retention`

## Implementation note

The first implementation pass should favor a clean skeleton that another repository can consume, rather than an all-in-one monorepo deployment layout.
