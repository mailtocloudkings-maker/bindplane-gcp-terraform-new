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

# Install BindPlane
cd /tmp
curl -fsSlL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh && bash install-linux.sh --version 1.96.7 && rm install-linux.sh

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


# Enable and start BindPlane
systemctl enable bindplane
systemctl restart bindplane
systemctl is-active postgresql
systemctl is-active bindplane
