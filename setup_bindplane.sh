#!/bin/bash
set -euxo pipefail

DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

echo "===== INSTALLING POSTGRESQL ====="

sudo apt-get install -y postgresql postgresql-contrib curl

sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql

echo "===== CREATING DATABASE ====="
sudo -u postgres psql -c "CREATE DATABASE bindplane;" || true

echo "===== CREATING USER ====="
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" || true

echo "===== GRANTING PRIVILEGES ====="
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;" || true
sudo -u postgres psql -d bindplane -c "GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;" || true
sudo -u postgres psql -d bindplane -c "ALTER SCHEMA public OWNER TO $DB_USER;" || true

echo "===== INSTALLING BINDPLANE SERVER ====="
cd /tmp
curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh

# Run exactly the manual command but feed the license key and default values automatically
bash install-linux.sh --version 1.96.7 --init <<EOF
y
$BP_LICENSE_KEY
0.0.0.0
3001
http://$(hostname -I | awk '{print $1}'):3001
Single User
$BP_ADMIN_USER
$BP_ADMIN_PASS
$BP_ADMIN_PASS
postgres
localhost
5432
bindplane
disable
100
$DB_USER
$DB_PASS
local
EOF

rm install-linux.sh

echo "===== ENABLE AND START BINDPLANE ====="
sudo systemctl enable bindplane
sudo systemctl restart bindplane

echo "===== FINAL STATUS ====="
systemctl is-active postgresql
systemctl is-active bindplane
