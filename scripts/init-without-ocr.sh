#!/bin/bash
set -euo pipefail

# ---------- Helpers ----------
log() { printf '%s\n' "$*" >&2; }

# Ermittelt einen funktionsfähigen XDG_RUNTIME_DIR-Pfad pro Laufzeit-User.
setup_xdg_runtime_dir() {
  local ruser="stirlingpdfuser"
  local ruid rgid rgrp cand dir ok=0

  if id -u "$ruser" >/dev/null 2>&1; then
    ruid="$(id -u "$ruser")"
    rgid="$(id -g "$ruser")"
    rgrp="$(getent group "$rgid" | cut -d: -f1 || echo "$rgid")"
  else
    # Fallback: aktueller User
    ruid="$(id -u)"
    rgid="$(id -g)"
    rgrp="$(getent group "$rgid" | cut -d: -f1 || echo "$rgid")"
    ruser="$(id -un)"
  fi

  # Kandidaten in Reihenfolge: /run/user/<uid>, /tmp/xdg-<uid>, $HOME/.xdg-runtime
  # /run/user ist POSIX-konform falls vorhanden; ansonsten sicherer Fallback in /tmp oder HOME
  local -a candidates=("/run/user/${ruid}" "/tmp/xdg-${ruid}" "${HOME}/.xdg-runtime")

  for cand in "${candidates[@]}"; do
    dir="$cand"
    # Erstellen, falls nicht vorhanden
    mkdir -p "$dir" 2>/dev/null || true

    if [ -d "$dir" ]; then
      # Wenn root: Eigentümer auf Laufzeit-User setzen
      if [ "$(id -u)" -eq 0 ]; then
        chown "${ruser}:${rgrp}" "$dir" 2>/dev/null || true
      fi

      # Schreibbarkeit prüfen
      if sudo -u "${ruser}" test -w "$dir" 2>/dev/null || [ -w "$dir" ]; then
        chmod 700 "$dir" 2>/dev/null || true
        export XDG_RUNTIME_DIR="$dir"
        log "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"
        ok=1
        break
      fi
    fi
  done

  if [ "$ok" -ne 1 ]; then
    # Letzter Fallback: unset → dconf nutzt dann i.d.R. Nutzer-Home (kann Warnungen reduzieren)
    log "[WARN] Could not prepare a writable XDG_RUNTIME_DIR for UID ${ruid}. dconf may log warnings."
    unset XDG_RUNTIME_DIR || true
  fi
}

# ---------- Version / Env / Umask ----------
# VERSION_TAG-Fallback aus Build-Artefakt
if [ -z "${VERSION_TAG:-}" ] && [ -f /etc/stirling_version ]; then
  VERSION_TAG="$(tr -d '\r\n' < /etc/stirling_version)"
  export VERSION_TAG
fi

export JAVA_TOOL_OPTIONS="${JAVA_BASE_OPTS:-} ${JAVA_CUSTOM_OPTS:-}"
log "running with JAVA_TOOL_OPTIONS ${JAVA_BASE_OPTS:-} ${JAVA_CUSTOM_OPTS:-}"
log "Running Stirling PDF with DISABLE_ADDITIONAL_FEATURES=${DISABLE_ADDITIONAL_FEATURES:-} and VERSION_TAG=${VERSION_TAG:-<unset>}"

# UMASK robust (Default 022)
UMASK_VAL="${UMASK:-022}"
umask "$UMASK_VAL" 2>/dev/null || umask 022

# ---------- Optional: Zusatzfeatures (deaktiviert/Infoausgabe) ----------
if [[ "${INSTALL_BOOK_AND_ADVANCED_HTML_OPS:-false}" == "true" && "${FAT_DOCKER:-true}" != "true" ]]; then
  log "issue with calibre in current version, feature currently disabled on Stirling-PDF"
fi

# Security-JAR nur in Slim-Variante ziehen
if [[ "${FAT_DOCKER:-true}" != "true" ]]; then
  /scripts/download-security-jar.sh || true
fi

# (Alpine-only) Fonts-Installer hier NICHT ausführen; für Ubuntu anpassen, falls benötigt
# if [[ -n "${LANGS:-}" ]]; then
#   /scripts/installFonts-debian.sh $LANGS
# fi

# ---------- XDG_RUNTIME_DIR pro User ----------
setup_xdg_runtime_dir

# ---------- UID/GID-Remap nur als root ----------
if [ "$(id -u)" -eq 0 ]; then
  if id -u stirlingpdfuser >/dev/null 2>&1; then
    if [ -n "${PUID:-}" ] && [ "$PUID" != "$(id -u stirlingpdfuser)" ]; then
      usermod -o -u "$PUID" stirlingpdfuser || true
    fi
  fi
  if getent group stirlingpdfgroup >/dev/null 2>&1; then
    if [ -n "${PGID:-}" ] && [ "$PGID" != "$(getent group stirlingpdfgroup | cut -d: -f3)" ]; then
      groupmod -o -g "$PGID" stirlingpdfgroup || true
    fi
  fi
fi

# ---------- Rechte / Eigentümer ----------
log "Setting permissions and ownership for necessary directories..."
mkdir -p /tmp/stirling-pdf /logs /configs /customFiles /pipeline || true

# Nur existierende Pfade chownen (Ubuntu: /usr/share/fonts/truetype)
CHOWN_PATHS=("$HOME" "/logs" "/scripts" "/configs" "/customFiles" "/pipeline" "/tmp/stirling-pdf" "/app.jar")
[ -d /usr/share/fonts/truetype ] && CHOWN_PATHS+=("/usr/share/fonts/truetype")

CHOWN_OK=true
for p in "${CHOWN_PATHS[@]}"; do
  if [ -e "$p" ]; then
    chown -R "stirlingpdfuser:stirlingpdfgroup" "$p" 2>/dev/null || CHOWN_OK=false
    chmod -R 755 "$p" 2>/dev/null || true
  fi
done

# ---------- Übergang zum App-User ----------
# Wenn chown ok und wir root sind → als stirlingpdfuser starten, sonst als aktueller User
if $CHOWN_OK && [ "$(id -u)" -eq 0 ]; then
  exec su-exec stirlingpdfuser "$@"
else
  [ "$CHOWN_OK" = false ] && log "[WARN] Chown failed, running as current user"
  exec "$@"
fi
