#!/bin/bash
set -euxo pipefail

DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

echo "===== INSTALL POSTGRESQL ====="
apt-get update -y
apt-get install -y postgresql postgresql-contrib curl

systemctl start postgresql

echo "===== CREATE POSTGRES USER & DATABASE ====="
sudo -u postgres psql <<EOF
DO \$\$ BEGIN
IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
  CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASS';
END IF;
END \$\$;

DO \$\$ BEGIN
IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bindplane') THEN
  CREATE DATABASE bindplane OWNER $DB_USER;
END IF;
END \$\$;
EOF

echo "===== INSTALL BINDPLANE SERVER ====="
curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh
BINDPLANE_LICENSE_KEY="$BP_LICENSE_KEY" bash install-linux.sh --version 1.96.7 --init \
  --admin-user "$BP_ADMIN_USER" --admin-password "$BP_ADMIN_PASS"
rm install-linux.sh

systemctl restart bindplane-server
systemctl restart bindplane-agent

echo "===== SERVICE STATUS ====="
systemctl is-active postgresql
systemctl is-active bindplane-server
