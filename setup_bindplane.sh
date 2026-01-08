#!/bin/bash
set -euxo pipefail

DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

echo "===== INSTALLING POSTGRESQL ====="
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib

sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql

echo "===== CREATING DATABASE ====="
sudo -u postgres psql -c "CREATE DATABASE bindplane;"
echo "===== CREATING USER ====="
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
echo "===== GRANTING PRIVILEGES ====="
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "ALTER SCHEMA public OWNER TO $DB_USER;"

echo "===== INSTALLING BINDPLANE SERVER ====="
# Export license so installer picks it up
export BINDPLANE_LICENSE_KEY="$BP_LICENSE_KEY"

curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh
# Non-interactive install, pass license via env
sudo BINDPLANE_LICENSE_KEY="$BINDPLANE_LICENSE_KEY" bash install-linux.sh \
  --version 1.96.7 \
  --init \
  --admin-user "$BP_ADMIN_USER" \
  --admin-password "$BP_ADMIN_PASS"

rm install-linux.sh

sudo systemctl enable bindplane
sudo systemctl start bindplane

echo "✅ BindPlane installed and started successfully!"
