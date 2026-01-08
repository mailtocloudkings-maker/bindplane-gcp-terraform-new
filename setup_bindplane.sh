#!/bin/bash
set -euxo pipefail

# Inputs from GitHub Actions
DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

echo "===== INSTALLING POSTGRESQL ====="
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib curl

echo "===== STARTING POSTGRESQL SERVICE ====="
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql

echo "===== CREATING DATABASE AND USER ====="
# Create user and database with privileges
sudo -i -u postgres psql <<PSQL
CREATE DATABASE IF NOT EXISTS bindplane;
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
   END IF;
END
\$do\$;

GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;
\c bindplane
GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;
ALTER SCHEMA public OWNER TO $DB_USER;
PSQL

echo "===== INSTALLING BINDPLANE SERVER ====="
curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh
BINDPLANE_LICENSE_KEY="$BP_LICENSE_KEY" bash install-linux.sh \
  --version 1.96.7 \
  --init \
  --admin-user "$BP_ADMIN_USER" \
  --admin-password "$BP_ADMIN_PASS"
rm install-linux.sh

echo "===== ENABLE AND START BINDPLANE SERVICE ====="
sudo systemctl enable bindplane
sudo systemctl start bindplane

echo "===== SERVICE STATUS ====="
sudo systemctl is-active postgresql
sudo systemctl is-active bindplane

echo "✅ PostgreSQL and BindPlane installation completed successfully!"
