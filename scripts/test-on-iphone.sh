#!/bin/bash
# Corre la batería de pruebas de ChamaFit en el iPhone de Jordi: unitarias del
# modelo (hospedadas en la app) y las de UI (XCUITest pulsa la pantalla como
# un dedo; si la app se cae, el test falla con el crash adjunto).
#
#   scripts/test-on-iphone.sh            # unitarias + UI oscuro + UI claro
#   scripts/test-on-iphone.sh unit       # solo unitarias (~10 s)
#   scripts/test-on-iphone.sh ui         # solo UI en modo oscuro
#   scripts/test-on-iphone.sh light      # solo UI en modo claro
#   scripts/test-on-iphone.sh lang       # la app en inglés y en catalán
#   scripts/test-on-iphone.sh only <id>… # solo esos tests (-only-testing)
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

START=$(date +%Y-%m-%d-%H%M%S)

snapshot() {
  rm -f "$OUT/$1.plist"
  # Recién desbloqueado, devicectl a veces falla: hasta 5 intentos.
  for _ in 1 2 3 4 5; do
    xcrun devicectl device copy from --device $DEVICE --domain-type appDataContainer \
      --domain-identifier Mauri.FitnessApp --user mobile \
      --source "Library/Preferences/Mauri.FitnessApp.plist" --destination "$OUT/$1.plist" >/dev/null 2>&1
    [ -s "$OUT/$1.plist" ] && break
    sleep 5
  done
  md5 -q "$OUT/$1.plist" 2>/dev/null || echo "sin-datos"
}

# Con el iPhone bloqueado la app no arranca y xcodebuild se queda esperando
# sin decir nada. Mientras la app de pruebas está abierta la pantalla no se
# apaga, pero entre compilación y prueba sí: mejor Bloqueo automático = Nunca.
wait_unlocked() {
  if xcrun devicectl device info lockState --device $DEVICE 2>/dev/null | grep -q "passcodeRequired: true"; then
    echo "⚠️ El iPhone está bloqueado: desbloquéalo (y pon Bloqueo automático en Nunca mientras dura)."
    until ! xcrun devicectl device info lockState --device $DEVICE 2>/dev/null | grep -q "passcodeRequired: true"; do sleep 3; done
  fi
}

echo "▸ Compilando app y tests…"
xcodebuild build-for-testing -scheme FitnessApp -destination "platform=iOS,id=$DEVICE" \
  -allowProvisioningUpdates -derivedDataPath "$DD" 2>&1 | grep -E 'error:|TEST BUILD (SUCCEEDED|FAILED)' | sort -u
RUN=$(ls "$DD"/Build/Products/FitnessApp_FitnessApp_iphoneos*.xctestrun | head -1)

wait_unlocked
echo "▸ Copia de los datos reales antes de empezar…"
BEFORE=$(snapshot antes)

run() {  # nombre, filtros -only-testing (uno o varios)
  local name=$1; shift
  local filters=(); for f in "$@"; do filters+=(-only-testing:"$f"); done
  set -- "$name"
  echo "▸ $1…"
  # Si el iPhone se bloquea al lanzar, el runner no llega a arrancar: se espera
  # a que lo desbloqueen y se vuelve a intentar (hasta 30 veces).
  for attempt in $(seq 1 30); do
    wait_unlocked   # justo antes: compilar tarda y el iPhone se bloquea mientras
    rm -rf "$OUT/$1.xcresult"
    xcodebuild test-without-building -xctestrun "$RUN" -destination "platform=iOS,id=$DEVICE" \
      "${filters[@]}" -resultBundlePath "$OUT/$1.xcresult" > "$OUT/$1.log" 2>&1
    if grep -q "Lost pending connection to the test runner before launch\|because the device is locked\|may need to be unlocked\|Timed out waiting for all destinations\|Unable to find a destination matching" "$OUT/$1.log" \
       && ! grep -q "Test [Cc]ase.*passed" "$OUT/$1.log"; then
      echo "   (el iPhone se bloqueó al lanzar; reintento $attempt)"
      sleep 5
      continue
    fi
    break
  done
  grep -E "Test [Cc]ase.*(passed|failed)|Test run with|TEST EXECUTE" "$OUT/$1.log" | sed 's/^/   /' | tail -60
}

case $WHAT in
  unit)  run unitarias FitnessAppTests ;;
  ui)    run ui-oscuro FitnessAppUITests/ChamaFitUITests ;;
  light) run ui-claro FitnessAppUITests/LightModeUITests ;;
  lang)  run idiomas FitnessAppUITests/LanguageUITests ;;
  only)  shift; run solo "$@" ;;   # p. ej. only FitnessAppUITests/ChamaFitUITests/test18_AmrapBlock [otro…]
  *)     run unitarias FitnessAppTests
         run ui-oscuro FitnessAppUITests/ChamaFitUITests
         run ui-claro FitnessAppUITests/LightModeUITests
         run idiomas FitnessAppUITests/LanguageUITests ;;
esac

echo "▸ Crash logs del iPhone…"
mkdir -p "$OUT/crashes"
idevicecrashreport -n -k -e "$OUT/crashes" >/dev/null 2>&1 || idevicecrashreport -k -e "$OUT/crashes" >/dev/null 2>&1
# idevicecrashreport -k deja los del iPhone: solo cuentan los de esta batería.
CRASHES=$(ls "$OUT/crashes" 2>/dev/null | grep -i -E 'FitnessApp|ChamaFit|watchkit' | grep -v Runner \
  | awk -v s="$START" '{ if (match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}/) && substr($0, RSTART, RLENGTH) >= s) print }' || true)
if [ -n "$CRASHES" ]; then echo "   ⚠️ crashes de ChamaFit:"; echo "$CRASHES" | sed 's/^/     /'; else echo "   ninguno de ChamaFit"; fi

echo "▸ Datos reales tras las pruebas…"
AFTER=$(snapshot despues)
if [ "$BEFORE" = "$AFTER" ]; then echo "   intactos (md5 $AFTER)"
elif [ ! -s "$OUT/antes.plist" ] || [ ! -s "$OUT/despues.plist" ]; then echo "   ⚠️ no se pudo copiar los datos (antes: $BEFORE · después: $AFTER)"
else
  # El JSON de los diccionarios cambia de orden en cada guardado: se compara el contenido.
  python3 scripts/compare-real-data.py "$OUT/antes.plist" "$OUT/despues.plist" | sed 's/^/   /'
fi
echo "✓ Resultados en $OUT (abrir los .xcresult con Xcode para ver capturas)"
