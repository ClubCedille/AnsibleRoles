#!/usr/bin/env python3
"""Export Docker Compose container state as Prometheus metrics via node_exporter textfile collector.

Config read from environment: COMPOSE_DIR, OUTPUT_PATH.
Any additional env var is exposed as a label on all metrics (e.g. LABEL_app=myapp).
Containers are discovered dynamically via `docker compose ps` — no service name is hardcoded.
"""
import calendar
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
from collections import OrderedDict

COMPOSE_DIR = os.environ.get("COMPOSE_DIR", "")
OUTPUT_PATH = os.environ.get(
    "OUTPUT_PATH", "/var/lib/node_exporter/textfile_collector/docker_state.prom"
)
COMPOSE_FILE = os.path.join(COMPOSE_DIR, "docker-compose.yml")

EXTRA_LABELS = {
    k[6:].lower(): v
    for k, v in os.environ.items()
    if k.startswith("LABEL_")
}

HEALTH_VALUES = {"healthy": 1, "starting": 0, "unhealthy": -1}

METRIC_HELP = OrderedDict([
    ("docker_state_exporter_up",
     ("Whether the exporter run completed without error", "gauge")),
    ("docker_state_exporter_last_run_seconds",
     ("Unix timestamp of the last exporter run", "gauge")),
    ("docker_container_state",
     ("Container running state (1=running, 0=not running)", "gauge")),
    ("docker_container_restart_count",
     ("Docker restart count for the container", "gauge")),
    ("docker_container_start_time_seconds",
     ("Unix timestamp the container last started", "gauge")),
    ("docker_container_health",
     ("Healthcheck status (1=healthy, 0=starting, -1=unhealthy)", "gauge")),
    ("docker_container_port_published",
     ("Published host:container port mapping (informational)", "gauge")),
    ("docker_container_port_open",
     ("Whether the published host port accepts local TCP connections", "gauge")),
])


def esc(value):
    return str(value).replace("\\", "\\\\").replace('"', '\\"')


def base_labels(extra=None):
    labels = dict(EXTRA_LABELS)
    labels["instance"] = socket.gethostname()
    if extra:
        labels.update(extra)
    return ",".join(f'{k}="{esc(v)}"' for k, v in labels.items())


def run_json(cmd):
    """Run cmd and parse stdout as JSON (array or NDJSON)."""
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
    if out.returncode != 0:
        return None, out.stderr.strip()
    text = out.stdout.strip()
    if not text:
        return [], None
    try:
        data = json.loads(text)
        return (data if isinstance(data, list) else [data]), None
    except json.JSONDecodeError:
        items = []
        try:
            for line in text.splitlines():
                line = line.strip()
                if line:
                    items.append(json.loads(line))
        except json.JSONDecodeError as exc:
            return None, f"invalid JSON output: {exc}"
        return items, None


def parse_docker_timestamp(value):
    """Parse a Docker RFC3339 timestamp (StartedAt). Returns None if never started."""
    if not value or value.startswith("0001-01-01"):
        return None
    try:
        head = value.split(".")[0].rstrip("Z")
        return calendar.timegm(time.strptime(head, "%Y-%m-%dT%H:%M:%S"))
    except ValueError:
        return None


def tcp_check(host, port, timeout=1.5):
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


def collect(metrics):
    if not os.path.isfile(COMPOSE_FILE):
        return f"compose file not found: {COMPOSE_FILE}"

    containers, err = run_json(
        ["docker", "compose", "-f", COMPOSE_FILE, "ps", "-a", "--format", "json"]
    )
    if err:
        return f"docker compose ps failed: {err}"

    for c in containers:
        service = c.get("Service") or "unknown"
        container_id = c.get("ID")
        name = c.get("Name") or container_id or "unknown"
        if not container_id:
            continue

        inspected, ierr = run_json(["docker", "inspect", container_id])
        if ierr or not inspected:
            continue
        info = inspected[0]
        state = info.get("State", {})
        status = state.get("Status", "unknown")
        running = 1 if status == "running" else 0
        restart_count = info.get("RestartCount", 0)
        image = info.get("Config", {}).get("Image", "")

        lbl = base_labels({"service": service, "container": name, "image": image})
        metrics["docker_container_state"].append((lbl, running))
        metrics["docker_container_restart_count"].append((lbl, restart_count))

        start_ts = parse_docker_timestamp(state.get("StartedAt"))
        if start_ts is not None and running:
            metrics["docker_container_start_time_seconds"].append((lbl, start_ts))

        health = state.get("Health", {}).get("Status")
        if health:
            metrics["docker_container_health"].append(
                (lbl, HEALTH_VALUES.get(health, -2))
            )

        ports = info.get("NetworkSettings", {}).get("Ports") or {}
        for container_port_proto, bindings in ports.items():
            if not bindings:
                continue
            container_port, _, proto = container_port_proto.partition("/")
            proto = proto or "tcp"
            for binding in bindings:
                host_port = binding.get("HostPort")
                if not host_port:
                    continue
                port_lbl = base_labels({
                    "service": service,
                    "container": name,
                    "container_port": container_port,
                    "host_port": host_port,
                    "proto": proto,
                })
                metrics["docker_container_port_published"].append((port_lbl, 1))
                open_state = 1 if tcp_check("127.0.0.1", int(host_port)) else 0
                metrics["docker_container_port_open"].append((port_lbl, open_state))

    return None


def render(metrics):
    out = []
    for name, (help_text, mtype) in METRIC_HELP.items():
        samples = metrics.get(name, [])
        if not samples:
            continue
        out.append(f"# HELP {name} {help_text}")
        out.append(f"# TYPE {name} {mtype}")
        for lbl, value in samples:
            out.append(f"{name}{{{lbl}}} {value}")
    return "\n".join(out) + "\n"


def write_atomic(path, content):
    out_dir = os.path.dirname(path) or "."
    fd, tmp_path = tempfile.mkstemp(dir=out_dir, prefix=".docker_state-")
    try:
        with os.fdopen(fd, "w") as fh:
            fh.write(content)
        os.chmod(tmp_path, 0o644)
        os.replace(tmp_path, path)
    except Exception:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise


def main():
    metrics = {name: [] for name in METRIC_HELP}
    error = collect(metrics)

    metrics["docker_state_exporter_up"].append(
        (base_labels(), 0 if error else 1)
    )
    metrics["docker_state_exporter_last_run_seconds"].append(
        (base_labels(), int(time.time()))
    )

    write_atomic(OUTPUT_PATH, render(metrics))

    if error:
        print(f"docker_state_exporter: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
