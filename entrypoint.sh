#!/bin/bash
set -e

DB_HOST=${DATABASE_HOST:-db}

echo "[DevOps Fix] Preparing app.py for host: $DB_HOST"
sed -i "s/172.17.0.2/$DB_HOST/g" app.py

echo "Waiting for Postgres at $DB_HOST:5432..."

until timeout 1 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/5432" 2>/dev/null; do
  echo "Postgres is unavailable - sleeping"
  sleep 2
done

echo "Postgres is up! Running migrations..."

echo "Running Database Migrations..."
if [ ! -d "migrations" ]; then
    flask db init
fi

flask db migrate -m "Initial migration" || true
flask db upgrade

echo "Starting Gunicorn..."
exec "$@"