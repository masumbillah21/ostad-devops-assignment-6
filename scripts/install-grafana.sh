#!/usr/bin/env bash
# ==============================================================================
# Script: install-grafana.sh
# Purpose: Manually install Grafana via official APT repo and provision datasources
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo "Installing Grafana OSS (Manual Native Package on Ubuntu)..."
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root or with sudo."
  exit 1
fi

# 1. Install prerequisites
echo "[1/5] Installing prerequisite packages..."
apt-get update -y
apt-get install -y apt-transport-https software-properties-common wget curl gnupg

# 2. Add Grafana GPG key and official repository
echo "[2/5] Adding Grafana GPG key and official repository..."
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# 3. Update and install Grafana
echo "[3/5] Installing grafana package..."
apt-get update -y
apt-get install -y grafana

# 4. Copy provisioning files and dashboard
echo "[4/5] Provisioning datasources (Prometheus, Loki) and dashboard..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p /etc/grafana/provisioning/datasources/
mkdir -p /etc/grafana/provisioning/dashboards/
mkdir -p /var/lib/grafana/dashboards/

if [ -f "${SCRIPT_DIR}/../configs/grafana/provisioning/datasources/datasources.yaml" ]; then
  cp "${SCRIPT_DIR}/../configs/grafana/provisioning/datasources/datasources.yaml" /etc/grafana/provisioning/datasources/
fi

if [ -f "${SCRIPT_DIR}/../configs/grafana/provisioning/dashboards/dashboards.yaml" ]; then
  cp "${SCRIPT_DIR}/../configs/grafana/provisioning/dashboards/dashboards.yaml" /etc/grafana/provisioning/dashboards/
fi

if [ -f "${SCRIPT_DIR}/../configs/grafana/dashboards/system-metrics.json" ]; then
  cp "${SCRIPT_DIR}/../configs/grafana/dashboards/system-metrics.json" /var/lib/grafana/dashboards/
fi

chown -R grafana:grafana /etc/grafana/provisioning /var/lib/grafana/dashboards

# 5. Enable and start Grafana service
echo "[5/5] Starting grafana-server systemd service..."
systemctl daemon-reload
systemctl enable grafana-server
systemctl restart grafana-server

sleep 3
if systemctl is-active --quiet grafana-server; then
  echo "=========================================================="
  echo "✓ Grafana installed and started successfully!"
  echo "✓ Web UI: http://localhost:3000 (Default user: admin / admin)"
  echo "✓ Prometheus and Loki datasources auto-provisioned"
  echo "✓ System Metrics Dashboard loaded at /var/lib/grafana/dashboards"
  echo "=========================================================="
else
  echo "Warning: Grafana service is not active. Check: journalctl -u grafana-server -n 50"
  exit 1
fi
