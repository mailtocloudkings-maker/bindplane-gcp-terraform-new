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

# ---------- GitHub Runner ----------
mkdir -p /actions-runner
cd /actions-runner

curl -L -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v2.314.1/actions-runner-linux-x64-2.314.1.tar.gz
tar xzf actions-runner.tar.gz

./config.sh --url https://github.com/YOURORG/YOURREPO \
            --token ${RUNNER_TOKEN} \
            --name bindplane-vm \
            --labels bindplane \
            --unattended

./svc.sh install
./svc.sh start
systemctl restart bindplane

### ---------------- VERIFY ---------------- ###
systemctl is-active postgresql
systemctl is-active bindplane
