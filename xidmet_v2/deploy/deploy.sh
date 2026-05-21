#!/usr/bin/env bash
# =============================================================
# Xidmət App — Əl ilə Deploy Skripti
# İstifadə: ./xidmet_v2/deploy/deploy.sh
# =============================================================
set -euo pipefail

SSH_USER="${SSH_USER:-root}"
SSH_HOST="${SSH_HOST:-178.105.207.145}"
DEPLOY_PATH="${DEPLOY_PATH:-/root/xidmet}"

echo "Deploya başlanır → $SSH_USER@$SSH_HOST:$DEPLOY_PATH"

ssh "$SSH_USER@$SSH_HOST" bash << REMOTE
set -e
cd $DEPLOY_PATH

echo "--- Git pull ---"
git pull origin main

echo "--- Python asılılıqları ---"
cd xidmet_v2/backend
source venv/bin/activate
pip install -r requirements.txt -q

echo "--- Servis yenidən başladılır ---"
systemctl restart xidmet

echo "--- Servis statusu ---"
systemctl is-active xidmet && echo "Servis işləyir" || echo "Servis başlamadı!"

echo "Deploy tamamlandı!"
REMOTE
