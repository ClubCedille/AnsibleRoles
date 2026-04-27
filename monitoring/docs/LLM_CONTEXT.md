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
- `alloy`
- `node_exporter`
- `blackbox_exporter`
- `snmp_exporter`
- `alertmanager`

Removed from scope:

- `promtail` (replaced by `alloy`)

## Architectural intent

- The collection is consumed from another repository.
- Variables should stay grouped in `defaults/main.yaml`.
- Each role should keep the same shape: `install.yaml`, `config.yaml`, `handlers/main.yaml`, `meta/main.yml`.
- Prometheus is the aggregation point for metrics.
- Grafana is the visualization layer.
- Loki/Alloy are preferred for logs over Elasticsearch/Kibana in this first iteration.
- SNMP Exporter and Blackbox Exporter are the most relevant add-ons for this infrastructure.
- Alertmanager should be included early so Prometheus alerts have a destination.
- Install strategy is split in two families:
  - Grafana stack packages from `https://apt.grafana.com`: `grafana`, `loki`, `alloy`
  - Prometheus ecosystem pinned tarballs: `prometheus`, `alertmanager`, `node_exporter`, `blackbox_exporter`, `snmp_exporter`

## Suggested integration points

- Prometheus scrapes Kea, BIND9, Stork, Node Exporter, SNMP Exporter and Blackbox Exporter.
- Grafana reads from Prometheus and Loki.
- Alloy forwards logs to Loki.
- Node Exporter runs on Linux hosts.
- SNMP Exporter targets switches and network devices.
- Blackbox Exporter probes network reachability and service availability.

## Suggested variable pattern

Use the real role-specific prefixes used in `defaults/main.yaml`:

- `prometheus_*`
- `grafana_*`
- `loki_*`
- `alloy_*`
- `node_exporter_*`
- `blackbox_exporter_*`
- `snmp_exporter_*`
- `alertmanager_*`

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

Common high-level keys by role are:

- `<role>_enabled`
- `<role>_supported_distribution`
- `<role>_supported_distribution_version`
- `<role>_install`
- `<role>_service`
- `<role>_paths`

Additional commonly used keys:

- Prometheus: `prometheus_server`, `prometheus_rule_files`, `prometheus_scrape_configs`, `prometheus_alerting`
- Grafana: `grafana_server`, `grafana_datasources`, `grafana_dashboards`
- Loki: `loki_server`, `loki_storage`
- Alloy: `alloy_server`, `alloy_loki_endpoints`, `alloy_file_sources`
- Blackbox Exporter: `blackbox_exporter_modules`
- SNMP Exporter: `snmp_exporter_modules`, `snmp_exporter_auths`
- Alertmanager: `alertmanager_route`, `alertmanager_receivers`

## Version and packaging references

Pinned versions currently defined in defaults:

- `prometheus`: `3.5.2` (tarball + checksum)
- `alertmanager`: `0.32.0` (tarball + checksum)
- `node_exporter`: `1.11.1` (tarball + checksum)
- `blackbox_exporter`: `0.28.0` (tarball + checksum)
- `snmp_exporter`: `0.30.1` (tarball + checksum)

APT repository references:

- `grafana`, `loki`, `alloy` use key `https://apt.grafana.com/gpg-full.key`
- repository `deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main`

## Implementation note

The first implementation pass should favor a clean skeleton that another repository can consume, rather than an all-in-one monorepo deployment layout.
