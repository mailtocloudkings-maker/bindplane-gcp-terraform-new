#!/bin/bash
set -euxo pipefail

DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

# Install PostgreSQL
apt-get update -y
apt-get install -y curl apt-transport-https gnupg lsb-release
apt-get install -y postgresql postgresql-contrib curl

systemctl enable postgresql
systemctl start postgresql

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE bindplane;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "ALTER SCHEMA public OWNER TO $DB_USER;"

### ---------------- INSTALL BINDPLANE ---------------- ###
cd /tmp
curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o install-linux.sh
bash install-linux.sh --version 1.96.7 --init <<EOF
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

rm -f install-linux.sh

### ---------------- CREATE SERVICE USER ---------------- ###
useradd -r -s /bin/false bindplane || true
mkdir -p /var/lib/bindplane
chown -R bindplane:bindplane /var/lib/bindplane /etc/bindplane

### ---------------- CREATE SYSTEMD SERVICE ---------------- ###
tee /etc/systemd/system/bindplane.service >/dev/null <<'EOF'
[Unit]
Description=BindPlane Server
After=network.target postgresql.service

[Service]
Type=simple
User=bindplane
Group=bindplane
ExecStart=/usr/local/bin/bindplane server --config /etc/bindplane/config.yaml
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

### ---------------- START SERVICE ---------------- ###
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable bindplane
systemctl restart bindplane

### ---------------- VERIFY ---------------- ###
systemctl is-active postgresql
systemctl is-active bindplane
