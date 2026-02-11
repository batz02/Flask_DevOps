#!/bin/bash
set -e

echo "🔧 [DevOps Fix] Replacing hardcoded DB IP in app.py..."
# Sostituisce 172.17.0.2 con 'db' (il nome del servizio nel docker-compose)
sed -i 's/172.17.0.2/db/g' app.py

echo "⏳ Waiting for Postgres to be ready..."
# Un semplice loop per aspettare che il DB sia su (evita crash all'avvio)
while ! timeout 1 bash -c "cat < /dev/null > /dev/tcp/db/5432"; do
  sleep 1
done

echo "🚀 Running Database Migrations..."
# Inizializza il DB se non esiste la cartella migrations
if [ ! -d "migrations" ]; then
    flask db init
fi

# Esegue la migrazione e l'upgrade come da README
flask db migrate -m "Initial migration" || true
flask db upgrade

echo "🟢 Starting Gunicorn..."
exec "$@"