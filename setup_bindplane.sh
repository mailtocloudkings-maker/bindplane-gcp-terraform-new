#!/bin/bash
set -euxo pipefail

# Parameters passed to the script
DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "===== INSTALLING DEPENDENCIES ====="
apt-get update -y
apt-get install -y curl wget gnupg lsb-release ca-certificates sudo apt-transport-https postgresql postgresql-contrib

echo "===== STARTING POSTGRESQL ====="
systemctl enable postgresql
systemctl start postgresql

echo "===== CREATING DATABASE AND USER ====="
sudo -u postgres psql -c "CREATE DATABASE bindplane;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "ALTER SCHEMA public OWNER TO $DB_USER;"

echo "===== INSTALLING BINDPLANE SERVER ====="
cd /tmp
curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh
bash install-linux.sh --version 1.96.7 --init
rm -f install-linux.sh

echo "===== VERIFYING BINDPLANE BINARY ====="
if ! command -v bindplane &> /dev/null; then
    echo "BindPlane binary not found! Installation failed."
    exit 1
fi

echo "===== AUTOMATED BINDPLANE INITIALIZATION ====="
BINDPLANE_CONFIG_HOME="/var/lib/bindplane" /usr/bin/bindplane init server --config /etc/bindplane/config.yaml <<EOF
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

echo "===== ENABLING AND STARTING BINDPLANE SERVICE ====="
systemctl enable bindplane
systemctl restart bindplane

echo "===== FINAL STATUS ====="
systemctl is-active postgresql
systemctl is-active bindplane
echo "✅ BindPlane server installed and running successfully!"
