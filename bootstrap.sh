#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SECRETS_FILE="${REPO_DIR}/secrets.yaml"
CONTAINERS_DIR="${HOME}/.config/containers"

# ---------------------------------------------------------------------------
# Podman secrets
# ---------------------------------------------------------------------------
sync_secrets() {
    echo "Syncing Podman secrets from secrets.yaml..."
    local plaintext
    plaintext="$(sops --decrypt "$SECRETS_FILE")"

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local value
        value="$(echo "$plaintext" | yq -r ".\"${name}\"")"
        printf '%s' "$value" | podman secret create --replace "$name" -
        echo "  [OK] ${name}"
    done < <(echo "$plaintext" | yq -r 'keys | .[]')
}

# ---------------------------------------------------------------------------
# Podman volumes
# ---------------------------------------------------------------------------
create_volumes() {
    echo "Ensuring Podman volumes..."

    # traefik-acme - needs acme.json pre-created with 0600 permissions
    if podman volume exists traefik-acme; then
        echo "  [SKIP] traefik-acme (already exists)"
    else
        podman volume create traefik-acme >/dev/null
        local mp
        mp="$(podman volume inspect traefik-acme --format '{{.Mountpoint}}')"
        podman unshare touch "${mp}/acme.json"
        podman unshare chmod 600 "${mp}/acme.json"
        echo "  [OK] traefik-acme created and initialized"
    fi
}

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------
link_dir() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [[ -L "$dest" ]]; then
        local current
        current="$(readlink -f "$dest")"
        if [[ "$current" == "$(readlink -f "$src")" ]]; then
            echo "  [SKIP] ${dest} -> ${src} (already linked)"
            return 0
        fi
        echo "  [REPLACE] existing symlink at ${dest}"
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        echo "  [ERROR] ${dest} exists and is not a symlink. Refusing to overwrite."
        return 1
    fi

    ln -s "$src" "$dest"
    echo "  [OK] ${dest} -> ${src}"
}

create_symlinks() {
    echo "Creating symlinks..."
    link_dir "${REPO_DIR}/quadlet" "${CONTAINERS_DIR}/systemd"
    link_dir "${REPO_DIR}/apps"    "${CONTAINERS_DIR}/apps"
}

# ---------------------------------------------------------------------------
# Systemd reload
# ---------------------------------------------------------------------------
reload_systemd() {
    echo "Reloading systemd user daemon..."
    systemctl --user daemon-reload
    echo "  [OK] Reloaded"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    sync_secrets
    create_volumes
    create_symlinks
    reload_systemd
    echo "Bootstrap complete."
}

main "$@"
