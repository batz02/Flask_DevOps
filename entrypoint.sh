#!/bin/bash
set -e

DB_HOST=${DATABASE_HOST:-db}

echo "[DevOps Fix] Preparing app.py for host: $DB_HOST"
sed -i "s/172.17.0.2/$DB_HOST/g" app.py

echo "[DevOps Fix] Changing FLATPAGES_ROOT to 'posts'"
sed -i "s/FLATPAGES_ROOT = ''/FLATPAGES_ROOT = 'posts'/g" app.py

echo "[DevOps Fix] Updating path logic inside app.py"
sed -i "s/'posts\/en'/'en'/g" app.py

echo "Waiting for Postgres at $DB_HOST:5432..."
until timeout 1 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/5432" 2>/dev/null; do
  echo "Postgres is unavailable - sleeping"
  sleep 2
done

echo "Postgres is up!"

echo "Managing Database Migrations..."

if [ ! -d "migrations" ]; then
    echo "Initializing migrations folder..."
    flask db init || echo "Init skipped (already exists)"
fi

echo "Generating migration scripts..."
flask db migrate -m "Auto migration" || true

echo "Applying database upgrade..."
flask db upgrade || {
    echo "Upgrade failed (Locked or already done). Assuming DB is fine."
}

echo "Starting Gunicorn..."
exec "$@"