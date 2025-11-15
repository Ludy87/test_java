#!/bin/bash
set -euo pipefail

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

# Continue to main init
/scripts/init-without-ocr.sh "$@"
