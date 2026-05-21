#!/usr/bin/env bash
# Bütün lokal Firebase emulator proseslərini dayandırır.
set -u

PATTERNS=(
  "firebase emulators:start"
  "firebase-tools"
  "cloud-firestore-emulator"
  "firebase-database-emulator"
  "firebase-storage-rules-runtime"
  "pubsub-emulator"
)

for pat in "${PATTERNS[@]}"; do
  pkill -f "$pat" 2>/dev/null || true
done

sleep 1

PORTS_PATTERN=':(8080|9099|5001|9199|4000|4400|4500|9150)\b'

remaining=$(ss -ltn 2>/dev/null | grep -E "$PORTS_PATTERN" || true)
if [[ -z "$remaining" ]]; then
  echo "✓ Bütün emulator portları sərbəstdir"
  exit 0
fi

echo "⚠  Hələ də işləyir, daha sərt -9 göndərilir:"
echo "$remaining"

for pat in "${PATTERNS[@]}"; do
  pkill -9 -f "$pat" 2>/dev/null || true
done

sleep 1
remaining=$(ss -ltn 2>/dev/null | grep -E "$PORTS_PATTERN" || true)
if [[ -z "$remaining" ]]; then
  echo "✓ Dayandırıldı"
else
  echo "✖  Hələ də dinləyən portlar var:"
  echo "$remaining"
  exit 1
fi
