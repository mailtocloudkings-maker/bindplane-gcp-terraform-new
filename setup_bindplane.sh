#!/bin/bash
set -euxo pipefail

DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

# Install PostgreSQL
apt-get update -y
apt-get install -y postgresql postgresql-contrib curl

systemctl enable postgresql
systemctl start postgresql

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE bindplane;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "ALTER SCHEMA public OWNER TO $DB_USER;"


echo "===== INSTALLING BINDPLANE SERVER ====="
cd /tmp
curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh

# Feed interactive prompts automatically
sudo bash install-linux.sh --version 1.96.7 <<EOF
y
$BP_LICENSE_KEY
y
3001
y
$BP_ADMIN_USER
$BP_ADMIN_PASS
$BP_ADMIN_PASS

disable
100
$DB_USER
$DB_PASS
local
y
EOF

echo "===== BINDPLANE SERVER INSTALLED AND INITIALIZED ====="
sudo systemctl enable bindplane
sudo systemctl restart bindplane

echo "===== FINAL STATUS ====="
systemctl is-active postgresql
systemctl is-active bindplane
