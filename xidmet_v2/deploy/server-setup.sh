#!/usr/bin/env bash
# =============================================================
# Xidmət App — Serverdə İlk Quraşdırma (bir dəfəlik icra edin)
# İstifadə: bash deploy/server-setup.sh
# =============================================================
set -euo pipefail

REPO_URL="git@github.com:namelum12345/xidmetapp.git"
DEPLOY_PATH="/root/xidmet"
DOMAIN="xidmet.ecoguard.online"
BACKEND_PORT="8001"

echo "========================================="
echo "  Xidmət App Server Setup"
echo "========================================="

# ── 1. System paketləri ──────────────────────────────────────
echo "[1/7] Sistem paketləri yenilənir..."
apt-get update -y
apt-get install -y git curl python3 python3-pip python3-venv build-essential nginx

# ── 2. Repo klonla ───────────────────────────────────────────
echo "[2/7] Repo klonlanır..."
mkdir -p "$(dirname "$DEPLOY_PATH")"
if [ -d "$DEPLOY_PATH/.git" ]; then
    echo "  Repo artıq var, pull edilir..."
    git -C "$DEPLOY_PATH" pull origin main
else
    git clone "$REPO_URL" "$DEPLOY_PATH"
fi

cd "$DEPLOY_PATH"

# ── 3. Python virtual environment ────────────────────────────
echo "[3/7] Python venv yaradılır..."
cd xidmet_v2/backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
deactivate

cd "$DEPLOY_PATH"

# ── 4. Uploads qovluğu ───────────────────────────────────────
echo "[4/7] Uploads qovluğu yaradılır..."
mkdir -p xidmet_v2/backend/uploads
chmod 755 xidmet_v2/backend/uploads

# ── 5. Systemd servis faylı ──────────────────────────────────
echo "[5/7] Systemd servis quraşdırılır..."
cat > /etc/systemd/system/xidmet.service << EOF
[Unit]
Description=Xidmet App FastAPI Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DEPLOY_PATH/xidmet_v2/backend
ExecStart=$DEPLOY_PATH/xidmet_v2/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port $BACKEND_PORT
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xidmet
systemctl start xidmet
sleep 2
systemctl is-active xidmet && echo "  Backend işləyir (port $BACKEND_PORT)" || echo "  Backend başlamadı, log yoxlayın: journalctl -u xidmet"

# ── 6. Nginx konfiqurasiyası ─────────────────────────────────
echo "[6/7] Nginx konfiqurasiya edilir..."
cat > /etc/nginx/sites-available/xidmet << EOF
server {
    listen 80;
    server_name $DOMAIN;

    client_max_body_size 20M;

    location /uploads/ {
        alias $DEPLOY_PATH/xidmet_v2/backend/uploads/;
    }

    location / {
        proxy_pass http://127.0.0.1:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/xidmet /etc/nginx/sites-enabled/xidmet
nginx -t && systemctl reload nginx

# ── 7. SSL (Certbot) ─────────────────────────────────────────
echo "[7/7] SSL sertifikatı..."
if command -v certbot &> /dev/null; then
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@ecoguard.online || true
else
    apt-get install -y certbot python3-certbot-nginx
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@ecoguard.online || true
fi

echo ""
echo "========================================="
echo "  Setup tamamlandı!"
echo "  API: https://$DOMAIN"
echo "  Docs: https://$DOMAIN/docs"
echo "  Log: journalctl -u xidmet -f"
echo "========================================="
