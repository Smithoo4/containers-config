# containers-config

Declarative container configuration for rootless Podman with Quadlet.

This repository is both testing and development of a homeserver configuration and a personal learning project. The end goal is a self-hosted environment running applications like [Nextcloud](https://nextcloud.com/), [Immich](https://immich.app/), etc. built up gradually and intentionally. There is no rush — the journey and the understanding gained along the way matter as much as the destination.

---

## Prerequisites

### Host OS

The host is [OpenSUSE MicroOS](https://microos.opensuse.org/), provisioned using Ignition. The Ignition configuration used to set up the host lives in a separate repository:

➜ [Smithoo4/MicroOS-fuel-ignition](https://github.com/Smithoo4/MicroOS-fuel-ignition)

### DuckDNS

[DuckDNS](https://www.duckdns.org/) is used for dynamic DNS and Let's Encrypt DNS-01 certificate challenges. A DuckDNS account with a configured subdomain is required. The API token is stored as a Podman secret.

---

## Directory Structure

```
containers-config/                  # Git repository for configuration backup
├── .git/
├── quadlet/                        # Quadlet unit files (symlinked to ~/.config/containers/systemd)
│   ├── *.network
│   └── *.container
├── apps/                           # Application configurations (symlinked to ~/.config/containers/apps)
│   └── <app>/
│       └── ...
└── README.md

Podman Volumes (runtime, not in git)
```

**Why This Structure?**
- **Git tracking**: All configuration files are version controlled
- **XDG compliance**: Symlinks maintain standard paths for Quadlet and applications
- **Easy backup**: The entire configuration is in one git repository
- **Podman volumes**: Runtime data (like `acme.json`) stored separately in named volumes

---

## Services

- **Traefik** - Reverse proxy with automatic HTTPS (Let's Encrypt)
- **webapp** - Demo web application

---

## Roadmap & Implementation

### Phase 1: Host OS

 - [X] [MicroOS-fuel-ignition](https://github.com/Smithoo4/MicroOS-fuel-ignition)

### Phase 2: Reverse Proxy and Directory Structure
 - [X] [quadlet-traefik-tutorial](https://github.com/Smithoo4/quadlet-traefik-tutorial)

### Phase 3: Configuration Management
 - [X]  Convert [quadlet-traefik-tutorial](https://github.com/Smithoo4/quadlet-traefik-tutorial) to a [containers-config](https://github.com/Smithoo4/containers-config) repo for further deployment
 - [ ] Add [SOPS](https://github.com/getsops/sops) for storing secrets
 - [ ] Restore script (Bash script to create symlinked, podman secrets, Volumes, etc.)
 - [ ] Backup script (Bash script to export podman volumes to ~/backups/)
 - [ ] Update Restore script to incorporate Backup output for volume restoration

### Phase 4: Security (CrowdSec)
- [ ] Replace firewalld with raw nftables.
    - Write base nftables ruleset (SSH, Cockpit, HTTP, HTTPS, and HTTP/3).
    - Verify rootless Podman networking still works.
    - Remove firewalld package.
- [ ] Install CrowdSec engine as a container, firewall bouncer on the host.
- [ ] Configure collections: `traefik`, `http-cve`, `linux`, `sshd`.
- [ ] SSH protection via firewall bouncer.
- [ ] Traefik protection:
    - [ ] Firewall bouncer (kernel-level blocking via nftables).
    - [ ] Traefik Bouncer Plugin (application-level blocking, captcha, AppSec/WAF).
    - [ ] Custom scenario to block IP-only / unknown SNI requests.
- [ ] Whitelist own IPs to prevent self-banning during testing.
- [ ] Evaluate CrowdSec Console — cloud dashboard + community blocklist.

### Phase X: Monitoring
 - [ ] Set up a monitoring stack to track OS health, container health, and service availability.
    - **Metrics collection options**
      - [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) + [vmalert](https://docs.victoriametrics.com/vmalert/) + [Alertmanager](https://github.com/prometheus/alertmanager) — Lightweight, low RAM, built-in long-term storage.
      - [Prometheus](https://prometheus.io/) + [Alertmanager](https://github.com/prometheus/alertmanager) — Industry standard, largest ecosystem and documentation.
      - [Beszel](https://github.com/henrygd/beszel) — All-in-one lightweight alternative with built-in container monitoring, alerting, and dashboard. Minimal setup.
    - **[prometheus-node_exporter](https://github.com/prometheus/node_exporter)** - Already installed on the MicroOS base exposing OS metrics on `:9100`.
    - **[prometheus-podman-exporter](https://github.com/containers/prometheus-podman-exporter)** — Container exposing Podman container state, health, and resource metrics on `:9882`.
    - **Health checks** — Add `HealthCmd` to every Quadlet `.container` file. Required for `podman auto-update --rollback` to detect and roll back broken images.
    - **[Traefik Metrics](https://doc.traefik.io/traefik/observability/metrics/prometheus/)** — Built-in Prometheus metrics on `:8080/metrics`, enabled with `metrics: prometheus: {}` in `traefik.yml`.
    - **CrowdSec Prometheus metrics** — Engine exposes metrics on `:6060/metrics` (decisions, alerts, scenario counts). Integrate when CrowdSec is deployed in Phase 4.

### Phase X: Backup
  - [ ] Backup script using Restic (pipe `podman volume export` directly into Restic for encrypted, deduplicated backups)





