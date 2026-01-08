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
bash install-linux.sh --version 1.96.7
rm install-linux.sh

which bindplane
ls -l /usr/bin/bindplane


echo "===== INITIALIZING BINDPLANE SERVER (AUTOMATED) ====="
sudo BINDPLANE_CONFIG_HOME="/var/lib/bindplane" /usr/bin/bindplane init server --config /etc/bindplane/config.yaml <<EOF
y                     # Confirm initialize server
$BP_LICENSE_KEY       # License key
y                     # Accept default for Server Host (can also pass VM_IP)
3001                  # Server Port
y                     # Accept default Remote URL
$BP_ADMIN_USER        # Username
$BP_ADMIN_PASS        # Password
$BP_ADMIN_PASS        # Confirm password
                       # Accept default Storage Type (postgres)
                       # PostgreSQL Host default
                       # PostgreSQL Port default
                       # PostgreSQL Database Name default
disable               # Postgres SSL mode
100                   # Max DB connections
$DB_USER               # PostgreSQL Username
$DB_PASS               # PostgreSQL Password
local                 # Event bus type
y                     # Finish initialization
EOF

echo "===== STARTING BINDPLANE SERVICE ====="
sudo systemctl enable bindplane
sudo systemctl restart bindplane

echo "===== FINAL STATUS ====="
systemctl is-active postgresql
systemctl is-active bindplane
