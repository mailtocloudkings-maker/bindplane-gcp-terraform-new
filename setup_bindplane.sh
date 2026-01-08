#!/bin/bash
set -euxo pipefail

DB_USER="$1"
DB_PASS="$2"
BP_ADMIN_USER="$3"
BP_ADMIN_PASS="$4"
BP_LICENSE_KEY="$5"

echo "===== INSTALLING DEPENDENCIES ====="

sudo apt-get install -y software-properties-common
sudo add-apt-repository universe -y

sudo apt-get install -y postgresql postgresql-contrib expect curl

sudo systemctl enable postgresql
sudo systemctl start postgresql

sleep 5

echo "===== CREATING DATABASE ====="
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='bindplane'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE bindplane;"

echo "===== CREATING USER ====="
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

echo "===== GRANTING PRIVILEGES ====="
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bindplane TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d bindplane -c "ALTER SCHEMA public OWNER TO $DB_USER;"

echo "===== INSTALLING BINDPLANE ====="
sudo curl -fsSL https://storage.googleapis.com/bindplane-op-releases/bindplane/latest/install-linux.sh -o /tmp/install-linux.sh
sudo bash /tmp/install-linux.sh --version 1.96.7 --init || true

echo "===== INITIALIZING BINDPLANE (AUTOMATED) ====="
sudo expect <<EOF
set timeout 180

spawn sudo BINDPLANE_CONFIG_HOME="/var/lib/bindplane" /usr/local/bin/bindplane init server --config /etc/bindplane/config.yaml

expect "License Key"
send "$BP_LICENSE_KEY\r"

expect "Server Host"
send "\r"

expect "Server Port"
send "3001\r"

expect "Remote URL"
send "\r"

expect "authentication method"
send "\r"

expect "Username"
send "$BP_ADMIN_USER\r"

expect "Password"
send "$BP_ADMIN_PASS\r"

expect "Confirm password"
send "$BP_ADMIN_PASS\r"

expect "Storage Type"
send "\r"

expect "PostgreSQL Host"
send "\r"

expect "PostgreSQL Port"
send "\r"

expect "PostgreSQL Database Name"
send "\r"

expect "Postgres SSL mode"
send "\r"

expect "Maximum Number of Database Connections"
send "\r"

expect "PostgreSQL Username"
send "$DB_USER\r"

expect "PostgreSQL Password"
send "$DB_PASS\r"

expect "Event Bus Type"
send "\r"

expect eof
EOF

echo "===== STARTING BINDPLANE SERVICE ====="
sudo systemctl enable bindplane
sudo systemctl restart bindplane

sleep 5

echo "===== FINAL STATUS ====="
systemctl is-active postgresql
systemctl is-active bindplane
