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
- [X] Convert [quadlet-traefik-tutorial](https://github.com/Smithoo4/quadlet-traefik-tutorial) to [containers-config](https://github.com/Smithoo4/containers-config) repo for further deployment
- [ ] Add [SOPS](https://github.com/getsops/sops) for storing secrets (encrypted `vars.env` with config + secrets)
- [ ] Convert Quadlet files to templates with `${DOMAIN}` variable substitution via `envsubst`
- [ ] `bootstrap.sh` — single script that handles both first install and recovery:
    - Decrypt `vars.env` in memory via `sops exec-env`
    - Render Quadlet templates via `envsubst`
    - Create/update Podman secrets (`--replace`) from SOPS
    - Restore volumes from backup if present, otherwise initialize blank
    - Create Podman networks
    - `systemctl --user daemon-reload` and start/restart services
- [ ] `backup.sh` — export Podman volumes and runtime data
    - Export Podman volumes to `~/backups/` (e.g. `podman volume export`)
    - Include metadata (volume names, timestamps)
    - Compress backups (e.g. `zstd`)

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
- [ ] Identify and add CrowdSec runtime data (database, bouncer API keys) to Phase 3 backup/restore scripts.

### Phase 5: Monitoring
 - [ ] Set up a monitoring stack to track OS health, container health, and service availability.
    - [ ]  **Metrics collection options**
      - [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) + [vmalert](https://docs.victoriametrics.com/vmalert/) + [Alertmanager](https://github.com/prometheus/alertmanager) — Lightweight, low RAM, built-in long-term storage.
      - [Prometheus](https://prometheus.io/) + [Alertmanager](https://github.com/prometheus/alertmanager) — Industry standard, largest ecosystem and documentation.
      - [Beszel](https://github.com/henrygd/beszel) — All-in-one lightweight alternative with built-in container monitoring, alerting, and dashboard. Minimal setup.
    - [ ] Identify and add monitoring runtime data (metrics database) to Phase 3 backup/restore scripts if retention matters
    - [ ] **[prometheus-node_exporter](https://github.com/prometheus/node_exporter)** - Already installed on the MicroOS base exposing OS metrics on `:9100`.
    - [ ] **[prometheus-podman-exporter](https://github.com/containers/prometheus-podman-exporter)** — Container exposing Podman container state, health, and resource metrics on `:9882`.
    - [ ] **Health checks** — Add `HealthCmd` to every Quadlet `.container` file. Required for `podman auto-update --rollback` to detect and roll back broken images.
    - [ ] **[Traefik Metrics](https://doc.traefik.io/traefik/observability/metrics/prometheus/)** — Built-in Prometheus metrics on `:8080/metrics`, enabled with `metrics: prometheus: {}` in `traefik.yml`.
    - [ ] **CrowdSec Prometheus metrics** — Engine exposes metrics on `:6060/metrics` (decisions, alerts, scenario counts).
    - [ ] **Alerting / Notifications**
      - Configure Alertmanager (or equivalent) for notifications.
      - Support SMTP (email).
      - Define basic alert rules (e.g. host down, container unhealthy, high CPU/memory, failed updates).
      
 ### Phase 6: Authentication & SSO
- [ ] Evaluate and deploy a self-hosted SSO / Identity Provider.
    - **Options to evaluate:**
      - **[Authentik](https://goauthentik.io/)** — Full IdP with OIDC, SAML, LDAP, visual flow editor. Most popular homelab choice, but heavier (PostgreSQL + Redis).
      - **[Authelia](https://www.authelia.com/) + [lldap](https://github.com/lldap/lldap)** — Lightweight forward-auth with OIDC support. YAML config, minimal resources.
      - **[Kanidm](https://kanidm.com/)** — Rust-based IdP with built-in LDAP + OIDC. Lightweight and modern.
      - **[Keycloak](https://www.keycloak.org/)** — Enterprise standard (Red Hat). Steep learning curve but great for learning enterprise IAM.
- [ ] Implement Traefik forward auth middleware for SSO-protected routes.
- [ ] Centralized authentication for all services (OIDC, SAML).
    - Test with Traefik dashboard, monitoring dashboards, or a demo app.
- [ ] Chain with CrowdSec middleware — CrowdSec (IP reputation) runs before forward auth (SSO check).
- [ ] Identify and add SSO runtime data (database, secrets, media) to Phase 3 backup/restore scripts. **Critical — losing this means rebuilding all identity config and user accounts.**

### Phase 7: File Storage & Collaboration
- [ ] Evaluate and deploy storage/collaboration platform
    - Options: OpenCloud, Pydio Cells, Nextcloud, Seafile
- [ ] Authentication & SSO integration
- [ ] CrowdSec integration (if applicable)
- [ ] Metrics and monitoring integration
- [ ] Full-text document search (PDF and Office documents)
- [ ] Evaluate Office integration (Collabora, OnlyOffice)
- [ ] Evaluate desktop and mobile applications
- [ ] Identify and add runtime data (databases, file storage, indexes) to Phase 3 backup/restore scripts (**Critical**)

### Phase 8: Photo Management
- [ ] Evaluate and deploy photo management solution
    - Options: Immich, PhotoPrism, Lychee, or reuse Phase 7 solution
- [ ] Authentication & SSO integration
- [ ] CrowdSec integration (if applicable)
- [ ] Metrics and monitoring integration
- [ ] Identify and add runtime data (photo libraries, metadata DB) to Phase 3 backup/restore scripts (**Critical — primary data store**)

### Phase 9: Recipe Management
- [ ] Evaluate and deploy recipe management solution
    - Options: Mealie, Tandoor Recipes, Grocy
- [ ] Authentication & SSO integration
- [ ] CrowdSec integration (if applicable)
- [ ] Metrics and monitoring integration
- [ ] Identify and add runtime data (database, uploaded assets) to Phase 3 backup/restore scripts

### Phase 10: DNS Sinkhole (Optional)
- [ ] Evaluate and deploy DNS sinkhole
    - Options: AdGuard Home, Pi-hole, Blocky, Technitium DNS Server
- [ ] Authentication & SSO integration (if supported)
- [ ] Metrics and monitoring integration
- [ ] Identify and add runtime data (blocklists, config, queries if retained) to Phase 3 backup/restore scripts

### Phase 11: Backup & Disaster Recovery
- [ ] Select storage backend (ZFS, Btrfs, or external NAS/RAID)
- [ ] Implement backup solution
    - Use Restic or equivalent
    - Integrate with Podman volumes (e.g. `podman volume export` → Restic)
    - Ensure encryption and deduplication
- [ ] Define backup scope
    - OS configuration (MicroOS, ignition, etc.)
    - Application configs
    - All identified runtime data from Phases 4–10
- [ ] Implement off-site backups (remote storage, S3-compatible, etc.)
- [ ] Test restore procedures (full system + individual services)
- [ ] Define retention policy (daily/weekly/monthly)





