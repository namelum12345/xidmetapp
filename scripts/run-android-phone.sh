#!/usr/bin/env bash
# USB / şəbəkə ilə telefona işlət: emulyator eyni PC-də olanda LAN IP istifadə et.
#
#   bash scripts/run-android-phone.sh
#   bash scripts/run-android-phone.sh 192.168.0.15
#
# Environment: FIREBASE_EMULATOR_HOST növbəti ilə eyni məntiq.

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
  echo "IP tapılmadı." >&2
  exit 1
fi

echo "FIREBASE_EMULATOR_HOST=$IP"
exec flutter run --dart-define=FIREBASE_EMULATOR_HOST="$IP" "${EXTRA[@]}"
