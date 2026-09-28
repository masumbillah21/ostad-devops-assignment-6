#!/usr/bin/env bash
# ==============================================================================
# Script: install-all.sh
# Purpose: Master setup script to manually install all monitoring and logging
#          components on an Ubuntu Server (VMware VM)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root or with sudo."
  echo "Usage: sudo ./scripts/install-all.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "    DevOps Batch 14 - Full Stack Server Monitoring Setup  "
echo "=========================================================="
echo "Installing: Node Exporter, Prometheus, Grafana, Loki, Promtail"
echo "=========================================================="

# Ensure execute permissions on all helper scripts
chmod +x "${SCRIPT_DIR}"/*.sh

# Step 1: Install Node Exporter
echo ""
echo ">>> STEP 1: Installing Node Exporter..."
bash "${SCRIPT_DIR}/install-node-exporter.sh"

# Step 2: Install Prometheus
echo ""
echo ">>> STEP 2: Installing Prometheus..."
bash "${SCRIPT_DIR}/install-prometheus.sh"

# Step 3: Install Grafana
echo ""
echo ">>> STEP 3: Installing Grafana..."
bash "${SCRIPT_DIR}/install-grafana.sh"

# Step 4: Install Loki
echo ""
echo ">>> STEP 4: Installing Loki..."
bash "${SCRIPT_DIR}/install-loki.sh"

# Step 5: Install Promtail
echo ""
echo ">>> STEP 5: Installing Promtail..."
bash "${SCRIPT_DIR}/install-promtail.sh"

echo ""
echo "=========================================================="
echo "               DEPLOYMENT SUMMARY & STATUS                "
echo "=========================================================="
echo ""
printf "%-20s %-12s %-30s\n" "Component" "Status" "URL / Endpoint"
printf "%-20s %-12s %-30s\n" "--------------------" "------------" "------------------------------"

check_service() {
  local service_name="$1"
  local url="$2"
  local status="INACTIVE"
  if systemctl is-active --quiet "${service_name}"; then
    status="RUNNING (OK)"
  fi
  printf "%-20s %-12s %-30s\n" "${service_name}" "${status}" "${url}"
}

check_service "node_exporter" "http://localhost:9100/metrics"
check_service "prometheus"    "http://localhost:9090"
check_service "grafana-server" "http://localhost:3000 (admin/admin)"
check_service "loki"          "http://localhost:3100/ready"
check_service "promtail"      "http://localhost:9080/ready"

echo "=========================================================="
echo "✓ All monitoring and logging services are installed and active!"
echo "✓ To set up GitHub Actions runner: ./scripts/setup-github-runner.sh"
echo "=========================================================="
