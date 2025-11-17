#!/bin/bash
# This script initializes environment variables and paths,
# prepares Tesseract data directories, and then runs the main init script.

set -euo pipefail

# === LD_LIBRARY_PATH ===
# Adjust the library path depending on CPU architecture.
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
  aarch64) export LD_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
esac

# Add LibreOffice program directory to library path.
export LD_LIBRARY_PATH="/usr/lib/libreoffice/program${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# === Python PATH ===
# Add virtual environments to PATH and PYTHONPATH.
export PATH="/opt/venv/bin:/opt/unoserver-venv/bin:$PATH"
export PYTHONPATH="/opt/venv/lib/python3.13/site-packages${PYTHONPATH:+:$PYTHONPATH}"

# === tessdata ===
# Prepare Tesseract OCR data directory.
mkdir -p /usr/share/tessdata

# Copy original tesseract data files if present.
if [ -d /usr/share/tessdata-original ]; then
  cp -r --update=none /usr/share/tessdata-original/. /usr/share/tessdata/ || true
fi

# Merge tessdata from different Tesseract versions if available.
for version in 4.00 5; do
  SRC="/usr/share/tesseract-ocr/${version}/tessdata"
  [ -d "$SRC" ] && cp -r --update=none "$SRC"/* /usr/share/tessdata/ 2>/dev/null || true
done

# === Temp dir ===
# Ensure the temporary directory exists and has proper permissions.
mkdir -p /tmp/stirling-pdf
chown -R stirlingpdfuser:stirlingpdfgroup /tmp/stirling-pdf || true
chmod -R 755 /tmp/stirling-pdf || true

# === Start application ===
# Run the main init script that handles the full startup logic.
exec /scripts/init-without-ocr.sh
