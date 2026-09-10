#!/bin/bash
# Compila ChamaFit en Release, la firma ad hoc y deja el .ipa en el escritorio.
#
#   scripts/build-adhoc.sh
#
# Requisitos: los iPhones destinatarios registrados en el equipo 47BY9SGLT7
# (Certificates, Identifiers & Profiles ▸ Devices). Cada UDID nuevo obliga a
# volver a ejecutar esto: el perfil ad hoc se regenera solo (-allowProvisioningUpdates).
#
# Instalar en un iPhone conectado:
#   xcrun devicectl device install app --device <UDID> ~/Desktop/ChamaFit-adhoc/ChamaFit.ipa
# o por AirDrop / Apple Configurator.

set -euo pipefail
cd "$(dirname "$0")/.."

OUT=~/Desktop/ChamaFit-adhoc
ARCHIVE=/tmp/ChamaFit.xcarchive
rm -rf "$ARCHIVE" "$OUT"
mkdir -p "$OUT"

cat > /tmp/ChamaFit-export.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>ad-hoc</string>
	<key>teamID</key><string>47BY9SGLT7</string>
	<key>signingStyle</key><string>automatic</string>
	<key>compileBitcode</key><false/>
	<key>thinning</key><string>&lt;none&gt;</string>
</dict>
</plist>
EOF

echo "▸ Archivando (Release)…"
xcodebuild -scheme FitnessApp -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" -allowProvisioningUpdates archive 2>&1 | grep -E 'error:|ARCHIVE (SUCCEEDED|FAILED)' || true

echo "▸ Exportando .ipa ad hoc…"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist /tmp/ChamaFit-export.plist \
  -exportPath "$OUT" -allowProvisioningUpdates 2>&1 | grep -E 'error:|EXPORT (SUCCEEDED|FAILED)' || true

if ls "$OUT"/*.ipa >/dev/null 2>&1; then
  mv "$OUT"/*.ipa "$OUT/ChamaFit.ipa"
  echo "✓ $OUT/ChamaFit.ipa ($(du -h "$OUT/ChamaFit.ipa" | cut -f1))"
  echo "  Dispositivos incluidos en el perfil:"
  security cms -D -i "$ARCHIVE/Products/Applications/FitnessApp.app/embedded.mobileprovision" 2>/dev/null \
    | plutil -extract ProvisionedDevices json -o - - 2>/dev/null | tr -d '[]"' | tr ',' '\n' | sed 's/^/    /'
else
  echo "✗ No se ha generado el .ipa. Revisa la salida de arriba"
  exit 1
fi
