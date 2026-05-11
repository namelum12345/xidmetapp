#!/usr/bin/env bash
# Bir əmrlə: Auth + Firestore emulyatorları + Flutter Chrome.
# Veb portu: FLUTTER_WEB_PORT (məs. 8081), yoxsa 8081-dən başlayan ilk boş port.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

die() { echo "❌ $*" >&2; exit 1; }

# Qoşulma qəbul olunursa portda dinləyici var (Flutter üçün məşğul).
tcp_port_busy() {
  bash -c "echo >/dev/tcp/127.0.0.1/$1" 2>/dev/null
}

first_free_flutter_web_port() {
  local from=${1:-8081}
  local to=${2:-8115}
  local p
  for p in $(seq "$from" "$to"); do
    tcp_port_busy "$p" && continue
    echo "$p"
    return 0
  done
  return 1
}

command -v flutter >/dev/null || die "flutter PATH-də yoxdur"
command -v node >/dev/null || die "node PATH-də yoxdur"

(test -d node_modules) || npm install

wait_tcp() {
  local port=$1
  local label=$2
  local i
  for i in $(seq 1 90); do
    if bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null; then
      echo "✓ $label (127.0.0.1:$port)"
      return 0
    fi
    if ! kill -0 "$EMU_PID" 2>/dev/null; then
      echo "Emulyator prosesi dayandı. Son log:" >&2
      tail -50 "$EMU_LOG" >&2 || true
      die "Emulyator başlamadı"
    fi
    sleep 1
  done
  die "$label portu $port açılmadı (90 s gözləmə)"
}

EMU_LOG="$ROOT/.emulator-run.log"
rm -f "$EMU_LOG"
echo "→ Emulyatorlar başlayır (Auth + Firestore). Log: $EMU_LOG"

(
  cd "$ROOT"
  exec env CI=true npx firebase emulators:start --only auth,firestore
) >>"$EMU_LOG" 2>&1 &
EMU_PID=$!

cleanup() {
  echo "→ Emulyator dayandırılır (PID $EMU_PID)..."
  kill "$EMU_PID" 2>/dev/null || true
  wait "$EMU_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "→ Portlar gözlənilir..."
wait_tcp 9099 "Auth emulyator"
wait_tcp 8080 "Firestore emulyator"

echo "→ Demo hesablar (superadmin, admin, user, worker)"
bash "$ROOT/scripts/seed-emulator.sh"

echo "→ flutter pub get"
flutter pub get

WEB_PORT="${FLUTTER_WEB_PORT:-}"
if [[ -n "$WEB_PORT" ]]; then
  if tcp_port_busy "$WEB_PORT"; then
    die "FLUTTER_WEB_PORT=$WEB_PORT məşğuldur (əvvəlki flutter/chrome?). Prosesi bağla və ya başqa port seç."
  fi
else
  WEB_PORT="$(first_free_flutter_web_port 8081 8115)" || die "8081–8115 arasında boş veb portu yoxdur"
fi

echo "→ Flutter Chrome: http://localhost:$WEB_PORT | Emulator UI: http://127.0.0.1:4000"
exec flutter run -d chrome --web-port="$WEB_PORT"
