#!/bin/bash
# Backend işə salma skripti
cd "$(dirname "$0")"

# Virtual environment yarat (ilk dəfə)
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Virtual environment yaradıldı"
fi

# Aktivləşdir
source venv/bin/activate

# Paketləri quraşdır
pip install -r requirements.txt -q

echo ""
echo "🚀 Qonşudan Xidmət Backend başlayır..."
echo "📍 URL: http://127.0.0.1:8000"
echo "📚 Docs: http://127.0.0.1:8000/docs"
echo "👤 Superadmin: super@admin.az / superadmin123"
echo ""

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
