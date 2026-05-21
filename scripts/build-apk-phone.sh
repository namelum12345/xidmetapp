#!/usr/bin/env bash
# APK (release) — fiziki telefon PC-dəki Firebase emulyatorlarına qoşulsun.
#
# Fiziki telefon üçün kompüterin Wi-Fi IP-si lazımdır (127.0.0.1 telefonda özünü göstərir).
# Əvvəl: npm run emulators:all  (və ya lazım olan emulyatorlar)
#
# Nümunələr:
#   bash scripts/build-apk-phone.sh
#   bash scripts/build-apk-phone.sh 192.168.1.42
#   bash scripts/build-apk-phone.sh --split-per-abi
#
# 10.0.2.2 YALNIZ Android Virtual Device (AVD) üçündür; fiziki telefonda
# istifadə etməyin — orada PC-nin Wi-Fi IP-si lazımdır.
# Hər halda əvvəl PC-də: npm run emulators  (Auth :9099, Firestore :8080)
#
# Environment: FIREBASE_EMULATOR_HOST əvvəlcədən təyin olunubsa o üstünlük verilir.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IP="${FIREBASE_EMULATOR_HOST:-}"
EXTRA=()
for a in "$@"; do
  if [[ -z "${IP}" ]] && [[ "$a" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    IP="$a"
  else
    EXTRA+=("$a")
  fi
done
if [[ -z "$IP" ]]; then
  IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
if [[ -z "$IP" ]]; then
  echo "IP tapılmadı. Ver: FIREBASE_EMULATOR_HOST=192.168.x.x bash scripts/build-apk-phone.sh" >&2
  exit 1
fi

echo "FIREBASE_EMULATOR_HOST=$IP"
echo "Çıxış: build/app/outputs/flutter-apk/app-release.apk"

flutter build apk --release \
  --dart-define=FIREBASE_EMULATOR_HOST="$IP" \
  "${EXTRA[@]}"
