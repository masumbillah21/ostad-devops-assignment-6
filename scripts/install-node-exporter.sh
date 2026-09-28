#!/usr/bin/env bash
# ==============================================================================
# Script: install-node-exporter.sh
# Purpose: Manually install and configure Node Exporter on Ubuntu as a systemd service
# ==============================================================================

set -euo pipefail

NODE_EXPORTER_VERSION="${1:-1.8.2}"

# Detect system architecture
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH_RAW}" && exit 1 ;;
esac

echo "=========================================================="
echo "Installing Node Exporter v${NODE_EXPORTER_VERSION} (${ARCH})..."
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root or with sudo."
  exit 1
fi

# 1. Create dedicated system user
if id -u node_exporter >/dev/null 2>&1; then
  echo "[1/4] User 'node_exporter' already exists. Skipping user creation."
else
  echo "[1/4] Creating 'node_exporter' system user..."
  useradd --no-create-home --shell /bin/false node_exporter
fi

# 2. Download and extract Node Exporter
TAR_NAME="node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${TAR_NAME}"
TEMP_DIR="$(mktemp -d)"

echo "[2/4] Downloading ${DOWNLOAD_URL}..."
curl -fsSL "${DOWNLOAD_URL}" -o "${TEMP_DIR}/${TAR_NAME}"
tar -xzf "${TEMP_DIR}/${TAR_NAME}" -C "${TEMP_DIR}"

# 3. Copy binary
echo "[3/4] Installing binary to /usr/local/bin/node_exporter..."
cp "${TEMP_DIR}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter" /usr/local/bin/
chmod 755 /usr/local/bin/node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# 4. Configure systemd service
echo "[4/4] Setting up systemd service..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_SERVICE="${SCRIPT_DIR}/../configs/node-exporter/node_exporter.service"

if [ -f "${REPO_SERVICE}" ]; then
  cp "${REPO_SERVICE}" /etc/systemd/system/node_exporter.service
else
  cat <<'EOF' > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter Prometheus Exporter for Machine Metrics
Documentation=https://prometheus.io/docs/guides/node-exporter/
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=0.0.0.0:9100
Restart=always
RestartSec=3s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
fi

# Cleanup
rm -rf "${TEMP_DIR}"

# Reload systemd and start service
systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter

sleep 2
if systemctl is-active --quiet node_exporter; then
  echo "=========================================================="
  echo "✓ Node Exporter v${NODE_EXPORTER_VERSION} installed successfully!"
  echo "✓ Metrics Endpoint: http://localhost:9100/metrics"
  echo "=========================================================="
else
  echo "Warning: Node Exporter service is not active. Check: journalctl -u node_exporter -n 50"
  exit 1
fi
