# opnsense_syslog

Configure an OPNsense remote syslog destination via the `oxlorg.opnsense.syslog`
module, pointing at the Alloy syslog receiver already running on monitoring01
(the same receiver used for the Nexus switch — see
`cedille.monitoring.alloy` and
`AnsibleInfra/playbooks/monitoring/infra-syslog-switches.yaml`). Requires
`connection: local` at the play level, same as `opnsense_telegraf`.

Scope is deliberately broad: **system + firewall + CARP/HA**, per the club's
stated need for CARP/HA troubleshooting visibility — not a narrow allowlist
like the switch integration (which only keeps interface/STP events). No
facility/level filtering is applied by default; trim later if volume becomes
a problem (`opnsense_syslog_facility` / `opnsense_syslog_level`).

## État de validation (important — read before trusting this)

**The syslog wire format emitted by OPNsense has not been empirically
verified.** This is exactly the class of bug that broke the Nexus switch
syslog integration for a full investigation cycle: NX-OS silently emitted a
non-RFC3164-conformant frame, Alloy's `rfc3164` parser dropped every message
with **zero errors anywhere** (nothing in Alloy's logs, nothing in
`loki_source_syslog_parsing_errors_total` — the messages were rejected before
even reaching the parser's error path), and it was only found by comparing
`tcpdump` (packets arriving fine) against Alloy's internal metrics. See
`AnsibleInfra/playbooks/monitoring/KNOWN_ISSUES.md` for the full writeup.

OPNsense's remote syslog (syslog-ng under the hood) has an explicit
`rfc5424` toggle per destination (`OPNsense\Syslog\Syslog.xml`, default
`false` — i.e. legacy/BSD-ish framing). This role defaults
`opnsense_syslog_rfc5424: false`, paired with `syslog_format: rfc3164` on the
Alloy side (see `infra-syslog-switches.yaml`). **This pairing has not been
tested against real traffic.** Before trusting it:

1. Apply this role (after explicit human sign-off — see top-level playbook).
2. Generate some traffic (e.g. trigger a CARP state change, or just wait for
   normal firewall logging).
3. On monitoring01, check Alloy's own metrics at `:12345/metrics`:
   - `loki_source_syslog_entries_total{...}` for the opnsense listener port —
     confirms messages are arriving and parsing.
   - `loki_source_syslog_parsing_errors_total` — should stay at 0.
   - `loki_process_dropped_lines_total{reason=...}` — distinguishes
     "parsed but filtered by keep_regex" from other drop reasons.
4. If entries stay at 0 despite confirmed packet arrival (`tcpdump port 5140`
   on monitoring01), switch `syslog_format` to `raw` on the Alloy source for
   this listener, exactly as was done for the Nexus switch — no change needed
   on the OPNsense side for that fallback.

## Per-node listener port — why

`cedille.monitoring.alloy`'s `config.alloy.j2` applies **one static label set
per `loki.source.syslog` listener** (see the role's `alloy_syslog_sources`
loop) — there's no per-message dynamic host labeling. Since opnsense01 and
opnsense02 are two distinct log sources that both need distinguishable
`instance` labels in Loki, each gets **its own listener port** on
monitoring01's Alloy instance (5140 / 5141 in `infra-syslog-switches.yaml`,
matching `opnsense_syslog_alloy_port` in each node's `host_vars`) rather than
sharing the switch's port 514. `opnsense_syslog_port` has no default in this
role on purpose — it must come from `host_vars` per node, so a missing value
fails loudly instead of both nodes silently colliding on the same port.

## Variables

See `defaults/main.yaml`. Requires `opnsense_syslog_alloy_port` to be set in
host_vars (not provided here — no safe default across two nodes).

## Requirements

- `vm_net.ip`, `opnsense_api_key`, `opnsense_api_secret` (vaulted, already in
  inventory).
- Play-level `connection: local`.
- `oxlorg.opnsense` collection.
- The Alloy syslog receiver side (`alloy_syslog_sources` entries for
  opnsense01/02) must be deployed separately via
  `infra-syslog-switches.yaml` — this role only configures the OPNsense-side
  destination, not the receiver.
