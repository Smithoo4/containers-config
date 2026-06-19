#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="${HOME}/backups"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
MANIFEST="${BACKUP_DIR}/manifest.txt"

# ---------------------------------------------------------------------------
# Volumes to back up.
# ---------------------------------------------------------------------------
VOLUMES=(
    "traefik-acme"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() {
    echo "$*" | tee -a "$MANIFEST"
}

backup_volume() {
    local name="$1"
    local out="${BACKUP_DIR}/${name}.tar.zst"

    if ! podman volume exists "$name"; then
        log "  [SKIP] ${name} (volume does not exist)"
        return 0
    fi

    podman volume export "$name" | zstd -q -o "$out"
    local size
    size="$(du -h "$out" | cut -f1)"
    log "  [OK]   ${name} -> ${out##*/} (${size})"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    mkdir -p "$BACKUP_DIR"

    # Initialize manifest
    {
        echo "Backup created: $(date --iso-8601=seconds)"
        echo "Host:           $(hostname)"
        echo "Backup dir:     ${BACKUP_DIR}"
        echo "---"
    } > "$MANIFEST"

    echo "Backing up Podman volumes to ${BACKUP_DIR}..."
    for vol in "${VOLUMES[@]}"; do
        backup_volume "$vol"
    done

    echo "---" >> "$MANIFEST"
    echo "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)" >> "$MANIFEST"

    echo "Backup complete."
    echo "Manifest: ${MANIFEST}"
}

main "$@"
