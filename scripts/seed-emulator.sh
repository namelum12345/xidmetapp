#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../functions"
(test -d node_modules) || npm install
npm run seed:emulator
