# opnsense_telegraf

Configure the `os-telegraf` OPNsense plugin via the OPNsense REST API so that
system, interface and PF metrics become available for Prometheus (monitoring01)
to scrape. Requires the API-driven, `connection: local` pattern already used
by `cedille.opnsense.config` (see `AnsibleInfra/playbooks/infra/opnsense-config.yaml`)
— this role issues HTTPS calls to the firewall's management API from the
control node, it does not run anything over SSH on the box.

## État de validation (important)

This role was written and reviewed against the **published os-telegraf plugin
source** (`opnsense/plugins`, `net-mgmt/telegraf`, models + API controllers,
checked 2026-09-03), but **has never been run against a live OPNsense
instance** — the club's production CARP pair is off-limits for unconfirmed
changes. Endpoint paths, body keys and field names were cross-checked line by
line against the plugin's PHP controllers and XML models, so confidence is
reasonably high, but this is not the same as having seen a real 200 response.
Validate on a lab/test OPNsense (or with explicit sign-off before running
against prod) before trusting this blindly.

## Bug found in the previous attempt (`playbooks/infra/opnsense-telegraf.yaml`)

The unrun playbook this role replaces made three incorrect assumptions,
confirmed false against the actual plugin source:

1. **Wrong endpoints.** It called `POST /api/telegraf/output/setOutputs`,
   `POST /api/telegraf/input/setInputs` and `POST /api/telegraf/service/reload`.
   None of these exist. The real controllers
   (`OPNsense\Telegraf\Api\{Input,Output}Controller`, `ServiceController`)
   only expose `input/set`, `output/set`, and `service/reconfigure` (there is
   no `reload` action at all).
2. **Wrong output model — no remote_write support exists.** The playbook
   configured `output.prometheus_remote_write.{enabled,url}`. Neither
   `prometheus_remote_write` nor `prometheus_client` exist anywhere in
   `Output.xml`. os-telegraf's only Prometheus-related output is
   `prometheus_enable` / `prometheus_listen` (default port **9273**) /
   `prometheus_exclude` / `prometheus_stringaslabel` — a **pull-style native
   exporter**, not a push output. There is no HTTP/remote_write output in this
   plugin at all (checked every output section: InfluxDB v1/v2, Graphite,
   Graylog, Elasticsearch, Prometheus, Datadog, MQTT, OpenTelemetry — none do
   Prometheus remote_write; "prometheusremotewrite" only appears as an
   internal MQTT serializer enum value, unrelated).
   **Consequence:** this role does not attempt push/remote_write to
   monitoring01's Prometheus at all. Instead it enables the native exporter,
   and Prometheus on monitoring01 must **scrape** `<node>:9273/metrics` — see
   "Wiring it up" below. That already matches how every other exporter in
   this stack works (node_exporter, smartctl_exporter, pve_exporter), so this
   is arguably a *better* fit than the original push design, not just a
   correction.
3. **Wrong input field name.** It used `input.net`; the real field is
   `input.network` (`net` doesn't exist in `Input.xml` and would likely be
   silently dropped or rejected by validation).
4. **Missing `general.enabled`.** The old playbook called
   `service/start` directly without ever setting `general.enabled=1`. Per
   `ServiceController::reconfigureAction()`, the daemon is only (re)started if
   `general.enabled == 1` — without it, `service/reconfigure` regenerates
   `telegraf.conf` but leaves the daemon stopped.
5. **Missing `connection: local`.** The old playbook didn't set it, so the
   `uri` tasks would have run over SSH on the firewall itself (making an
   HTTPS request to its own management IP) instead of from the control node,
   unlike every other API-driven OPNsense playbook in this repo.

## What "toutes les métriques d'interfaces réseau" actually covers

`input.network` (`inputs.net` in Telegraf) gives per-interface **traffic
counters (bytes/packets in+out), errors, and drops**. It does **not** expose
an explicit interface admin/link up-down boolean — that's not something this
Telegraf input collects on FreeBSD. `blackbox_icmp_infra` already ICMP-probes
opnsense01/02 as a coarse reachability signal; a real up/down-per-interface
signal would need a separate `ifconfig`-parsing check (not implemented here —
flagged as a gap for a follow-up pass, not something os-telegraf can give
you out of the box).

## Wiring it up (not automated by this role — see playbook comments)

This role only configures the OPNsense side. To actually get data into Mimir:

1. Add a Prometheus scrape job in
   `AnsibleInfra/inventories/infra/group_vars/monitoring_core.yaml`
   (`prometheus_scrape_configs`) targeting
   `10.0.21.2:9273` / `10.0.21.3:9273` — done as part of this change, see
   `infra-opnsense.yaml`'s header comment.
2. Prometheus's existing `prometheus_remote_write` to Mimir then carries it
   onward automatically — no separate config needed there.
3. A basic dashboard was added at
   `AnsibleInfra/playbooks/monitoring/files/dashboards/infra-opnsense.json`
   (wired into `infra-dashboards.yaml`). Its PromQL uses Telegraf's standard
   `<measurement>_<field>` Prometheus-output naming convention
   (`telegraf_cpu_usage_idle`, `telegraf_mem_available`/`_total`,
   `telegraf_net_bytes_recv`/`_sent`/`_err_in`/`_err_out`/`_drop_in`/`_drop_out`,
   `telegraf_pf_state_table_current`) inferred from the `inputs.cpu` /
   `inputs.mem` / `inputs.net` / `inputs.pf` Telegraf plugins this role
   enables — **not confirmed against a real `/metrics` scrape**. Check the
   actual exposed metric names (`curl http://<node>:9273/metrics` once
   applied) and adjust panel queries if they don't match exactly.

## Variables

See `defaults/main.yaml`. Key ones:

- `opnsense_telegraf_manage_plugin` (default `true`) — installs `os-telegraf`
  via `oxlorg.opnsense.package` first.
- `opnsense_telegraf_general_body`, `opnsense_telegraf_input_body`,
  `opnsense_telegraf_output_body` — raw bodies posted to the respective
  `/api/telegraf/*/set` endpoints. Booleans are OPNsense-style `"1"`/`"0"`
  strings, matching the plugin's own field types.

## Requirements

- `os-telegraf` plugin (auto-installed unless `opnsense_telegraf_manage_plugin: false`).
- `vm_net.ip`, `opnsense_api_key`, `opnsense_api_secret` (already vaulted in
  `inventories/infra/group_vars/routers.yaml` / `host_vars/opnsense0{1,2}...yaml`).
- Play-level `connection: local` (see `infra-opnsense.yaml`).
- `oxlorg.opnsense` collection (already in `collections/requirements.yml`).
