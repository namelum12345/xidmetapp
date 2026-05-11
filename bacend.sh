#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

PROJECT_ID="${FIREBASE_PROJECT_ID:-demo-qonsudan-xidmet}"

FIREBASE_CMD=""
if command -v firebase >/dev/null 2>&1; then
  FIREBASE_CMD="firebase"
elif command -v npx >/dev/null 2>&1; then
  FIREBASE_CMD="npx --yes firebase-tools"
  echo "firebase CLI global tapilmadi, npx firebase-tools istifade olunacaq..."
else
  echo "Ne firebase, ne de npx tapildi. Qurasdirin: npm i -g firebase-tools"
  exit 1
fi

if [ ! -d "$ROOT_DIR/functions/node_modules" ]; then
  echo "Functions asililiqlari qurasdirilir..."
  npm --prefix "$ROOT_DIR/functions" install
fi

echo "Firebase emulatorlari basladilir (project: $PROJECT_ID)"
echo "Auth:9099 Firestore:8080 Functions:5001 UI:4000"

$FIREBASE_CMD emulators:start --project "$PROJECT_ID" --only auth,firestore,functions
