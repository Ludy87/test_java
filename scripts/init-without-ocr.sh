#!/bin/bash
set -euo pipefail

# ---------- Kleine Logger-Helfer ----------
log() { printf '%s\n' "$*" >&2; }

# === 1. HINZUGEFÜGT: LD_LIBRARY_PATH für amd64 + arm64 ===
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH ;;
  aarch64) export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH ;;
esac
# === ENDE HINZUGEFÜGT ===

# ---------- VERSION_TAG: Fallback aus Build-Stage ----------
if [ -z "${VERSION_TAG:-}" ] && [ -f /etc/stirling_version ]; then
  VERSION_TAG="$(tr -d '\r\n' < /etc/stirling_version)"
  export VERSION_TAG
fi

# ---------- JAVA_OPTS ----------
export JAVA_TOOL_OPTIONS="${JAVA_BASE_OPTS:-} ${JAVA_CUSTOM_OPTS:-}"
export JAVA_TOOL_OPTIONS="-Djava.awt.headless=true ${JAVA_TOOL_OPTIONS}"
log "running with JAVA_TOOL_OPTIONS ${JAVA_TOOL_OPTIONS}"
log "Running Stirling PDF with DISABLE_ADDITIONAL_FEATURES=${DISABLE_ADDITIONAL_FEATURES:-} and VERSION_TAG=${VERSION_TAG:-<unset>}"

# ---------- UMASK robust ----------
UMASK_VAL="${UMASK:-022}"
umask "$UMASK_VAL" 2>/dev/null || umask 022

# ---------- XDG_RUNTIME_DIR: ERZWINGE /tmp/xdg-<UID> ----------
# Keine Versuche mit /run/user – dconf will 0700 + Besitz; /tmp ist zuverlässig im Container.
RUNTIME_USER="stirlingpdfuser"
if id -u "$RUNTIME_USER" >/dev/null 2>&1; then
  RUID="$(id -u "$RUNTIME_USER")"
  RGRP="$(id -gn "$RUNTIME_USER")"
else
  RUID="$(id -u)"
  RGRP="$(id -gn)"
  RUNTIME_USER="$(id -un)"
fi

export XDG_RUNTIME_DIR="/tmp/xdg-${RUID}"
mkdir -p "${XDG_RUNTIME_DIR}" || true
# Besitzer nur setzen, wenn wir root sind
if [ "$(id -u)" -eq 0 ]; then
  chown "${RUNTIME_USER}:${RGRP}" "${XDG_RUNTIME_DIR}" 2>/dev/null || true
fi
chmod 700 "${XDG_RUNTIME_DIR}" 2>/dev/null || true
log "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"

# ---------- Optional-Zeug (deaktiviert/harmlos) ----------
if [[ "${INSTALL_BOOK_AND_ADVANCED_HTML_OPS:-false}" == "true" && "${FAT_DOCKER:-true}" != "true" ]]; then
  log "issue with calibre in current version, feature currently disabled on Stirling-PDF"
fi

if [[ "${FAT_DOCKER:-true}" != "true" ]]; then
  /scripts/download-security-jar.sh || true
fi

# ---------- UID/GID remappen (nur als root) ----------
if [ "$(id -u)" -eq 0 ]; then
  if id -u stirlingpdfuser >/dev/null 2>&1; then
    if [ -n "${PUID:-}" ] && [ "$PUID" != "$(id -u stirlingpdfuser)" ]; then
      usermod -o -u "$PUID" stirlingpdfuser || true
      # XDG-Verzeichnis ggf. auch neu zuordnen
      chown stirlingpdfuser:stirlingpdfgroup "${XDG_RUNTIME_DIR}" 2>/dev/null || true
    fi
  fi
  if getent group stirlingpdfgroup >/dev/null 2>&1; then
    if [ -n "${PGID:-}" ] && [ "$PGID" != "$(getent group stirlingpdfgroup | cut -d: -f3)" ]; then
      groupmod -o -g "$PGID" stirlingpdfgroup || true
    fi
  fi
fi

# ---------- Verzeichnisse + Rechte ----------
log "Setting permissions and ownership for necessary directories..."
mkdir -p /tmp/stirling-pdf /logs /configs /customFiles /pipeline || true

CHOWN_PATHS=("$HOME" "/logs" "/scripts" "/configs" "/customFiles" "/pipeline" "/tmp/stirling-pdf" "/app.jar")
[ -d /usr/share/fonts/truetype ] && CHOWN_PATHS+=("/usr/share/fonts/truetype")
CHOWN_OK=true
for p in "${CHOWN_PATHS[@]}"; do
  if [ -e "$p" ]; then
    chown -R "stirlingpdfuser:stirlingpdfgroup" "$p" 2>/dev/null || CHOWN_OK=false
    chmod -R 755 "$p" 2>/dev/null || true
  fi
done

# ---------- Start als App-User (wenn möglich) ----------
if $CHOWN_OK && [ "$(id -u)" -eq 0 ]; then
  exec su-exec stirlingpdfuser "$@"
else
  [ "$CHOWN_OK" = false ] && log "[WARN] Chown failed, running as current user"
  exec "$@"
fi
