#!/bin/bash
set -euxo pipefail

# ---------------------------
# Parameters from GitHub Actions
# ---------------------------
DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

echo "===== INSTALLING POSTGRESQL ====="
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib

echo "Starting and enabling PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "===== CREATING DATABASE AND USER ====="
sudo -i -u postgres psql <<PSQL
-- Create database if not exists
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bindplane') THEN
      CREATE DATABASE bindplane;
   END IF;
END
\$\$;

-- Create user if not exists
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
   END IF;
END
\$\$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;

-- Connect to bindplane and set schema privileges
\c bindplane
GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;
ALTER SCHEMA public OWNER TO $DB_USER;
PSQL

echo "===== INSTALLING BINDPLANE SERVER ====="
# Download and run BindPlane installer
curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh

# Provide license key from parameter
sudo BINDPLANE_LICENSE_KEY="$BP_LICENSE_KEY" bash install-linux.sh --version 1.96.7 --init \
  --admin-user "$BP_ADMIN_USER" --admin-password "$BP_ADMIN_PASS"

rm install-linux.sh

echo "Enabling and starting BindPlane service..."
sudo systemctl enable bindplane
sudo systemctl start bindplane

echo "===== INSTALLATION COMPLETE ====="
sudo systemctl status postgresql --no-pager
sudo systemctl status bindplane --no-pager
