#!/bin/bash
# Corre la batería de pruebas de ChamaFit en el iPhone de Jordi: unitarias del
# modelo (hospedadas en la app) y las de UI (XCUITest pulsa la pantalla como
# un dedo; si la app se cae, el test falla con el crash adjunto).
#
#   scripts/test-on-iphone.sh            # unitarias + UI oscuro + UI claro
#   scripts/test-on-iphone.sh unit       # solo unitarias (~10 s)
#   scripts/test-on-iphone.sh ui         # solo UI en modo oscuro
#   scripts/test-on-iphone.sh light      # solo UI en modo claro
#
# La app arranca con `--ui-tests`: dominio de UserDefaults aparte, así que los
# datos reales del iPhone no se tocan (se comprueba al final con un md5).
# Requisitos: iPhone desbloqueado, pantalla encendida y sin usarlo mientras
# corre la UI (unos 15 min por modo). Resultados y crash logs en
# ~/Desktop/ChamaFit-tests/<fecha>/.

set -uo pipefail
cd "$(dirname "$0")/.."

DEVICE=B45E5BC1-E8CB-5DB5-9E62-A5B506304AB0
DD=/tmp/dd-chamafit
OUT=~/Desktop/ChamaFit-tests/$(date +%Y-%m-%d_%H%M)
WHAT=${1:-all}
mkdir -p "$OUT"

snapshot() {
  rm -f "$OUT/$1.plist"
  xcrun devicectl device copy from --device $DEVICE --domain-type appDataContainer \
    --domain-identifier Mauri.FitnessApp --user mobile \
    --source "Library/Preferences/Mauri.FitnessApp.plist" --destination "$OUT/$1.plist" >/dev/null 2>&1
  md5 -q "$OUT/$1.plist" 2>/dev/null || echo "sin-datos"
}

echo "▸ Copia de los datos reales antes de empezar…"
BEFORE=$(snapshot antes)

echo "▸ Compilando app y tests…"
xcodebuild build-for-testing -scheme FitnessApp -destination "platform=iOS,id=$DEVICE" \
  -allowProvisioningUpdates -derivedDataPath "$DD" 2>&1 | grep -E 'error:|TEST BUILD (SUCCEEDED|FAILED)' | sort -u
RUN=$(ls "$DD"/Build/Products/FitnessApp_FitnessApp_iphoneos*.xctestrun | head -1)

run() {  # nombre, filtro -only-testing
  echo "▸ $1…"
  xcodebuild test-without-building -xctestrun "$RUN" -destination "platform=iOS,id=$DEVICE" \
    -only-testing:"$2" -resultBundlePath "$OUT/$1.xcresult" > "$OUT/$1.log" 2>&1
  grep -E "Test [Cc]ase.*(passed|failed)|Test run with|TEST EXECUTE" "$OUT/$1.log" | sed 's/^/   /' | tail -60
}

case $WHAT in
  unit)  run unitarias FitnessAppTests ;;
  ui)    run ui-oscuro FitnessAppUITests/ChamaFitUITests ;;
  light) run ui-claro FitnessAppUITests/LightModeUITests ;;
  *)     run unitarias FitnessAppTests
         run ui-oscuro FitnessAppUITests/ChamaFitUITests
         run ui-claro FitnessAppUITests/LightModeUITests ;;
esac

echo "▸ Crash logs del iPhone…"
mkdir -p "$OUT/crashes"
idevicecrashreport -n -k -e "$OUT/crashes" >/dev/null 2>&1 || idevicecrashreport -k -e "$OUT/crashes" >/dev/null 2>&1
CRASHES=$(ls "$OUT/crashes" 2>/dev/null | grep -i -E 'FitnessApp|ChamaFit|watchkit' | grep -v Runner || true)
if [ -n "$CRASHES" ]; then echo "   ⚠️ crashes de ChamaFit:"; echo "$CRASHES" | sed 's/^/     /'; else echo "   ninguno de ChamaFit"; fi

echo "▸ Datos reales tras las pruebas…"
AFTER=$(snapshot despues)
if [ "$BEFORE" = "$AFTER" ]; then echo "   intactos (md5 $AFTER)"; else echo "   ⚠️ HAN CAMBIADO: $BEFORE → $AFTER"; fi
echo "✓ Resultados en $OUT (abrir los .xcresult con Xcode para ver capturas)"
