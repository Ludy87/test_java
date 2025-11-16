#!/bin/bash
set -euo pipefail

# === LD_LIBRARY_PATH für amd64 + arm64 (set -u safe) ===
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)
    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ;;
  aarch64)
    export LD_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ;;
esac

echo "Copying original files without overwriting existing files"
mkdir -p /usr/share/tessdata

if [ -d /usr/share/tessdata-original ]; then
  cp -r --update=none /usr/share/tessdata-original/. /usr/share/tessdata/ || true
fi

for version in 4.00 5; do
  SRC="/usr/share/tesseract-ocr/${version}/tessdata"
  if [ -d "$SRC" ] && [ "$(readlink -f "$SRC")" != "$(readlink -f /usr/share/tessdata)" ]; then
    cp -r --update=none "$SRC"/* /usr/share/tessdata/ || true
  fi
done

# Prepare temp dir
mkdir -p /tmp/stirling-pdf || true
chown -R stirlingpdfuser:stirlingpdfgroup /tmp/stirling-pdf || true
chmod -R 755 /tmp/stirling-pdf || true

# === 2. HINZUGEFÜGT: exec mit korrektem Java-Start (headless + LD_LIBRARY_PATH) ===
/scripts/init-without-ocr.sh "$@"
# === ENDE HINZUGEFÜGT ===
