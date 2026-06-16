#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="${REPO_DIR}/templates"
EXPORT_VARS='$SUBDOMAIN $BASE_DOMAIN $BASIC_AUTH_USERS'

# When called with --render, sops has already injected the env vars
if [[ "${1:-}" == "--render" ]]; then
    find "$TEMPLATES_DIR" -type f | while read -r src; do
        rel="${src#${TEMPLATES_DIR}/}"
        dest="${REPO_DIR}/${rel}"
        mkdir -p "$(dirname "$dest")"
        envsubst "$EXPORT_VARS" < "$src" > "$dest"
        echo "  Rendered: ${rel}"
    done
    exit 0
fi

# Main entry point
echo "Decrypting and rendering templates..."
sops exec-env "${REPO_DIR}/vars.env" "$0 --render"
echo "Done."
