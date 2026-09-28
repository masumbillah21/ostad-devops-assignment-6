#!/usr/bin/env bash
# ==============================================================================
# Script: install-promtail.sh
# Purpose: Manually install and configure Promtail on Ubuntu as a systemd service
# ==============================================================================

set -euo pipefail

PROMTAIL_VERSION="${1:-3.0.0}"

# Detect system architecture
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH_RAW}" && exit 1 ;;
esac

echo "=========================================================="
echo "Installing Promtail v${PROMTAIL_VERSION} (${ARCH})..."
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root or with sudo."
  exit 1
fi

apt-get update -y
apt-get install -y unzip curl

# 1. Create dedicated system user with adm group access (for /var/log access)
if id -u promtail >/dev/null 2>&1; then
  echo "[1/5] User 'promtail' already exists. Adding to adm group..."
  usermod -aG adm promtail || true
else
  echo "[1/5] Creating 'promtail' system user..."
  useradd --no-create-home --shell /bin/false -G adm promtail
fi

# 2. Create directories
echo "[2/5] Creating directory /etc/promtail..."
mkdir -p /etc/promtail

# 3. Download and extract Promtail binary
ZIP_NAME="promtail-linux-${ARCH}.zip"
DOWNLOAD_URL="https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/${ZIP_NAME}"
TEMP_DIR="$(mktemp -d)"

echo "[3/5] Downloading ${DOWNLOAD_URL}..."
curl -fsSL "${DOWNLOAD_URL}" -o "${TEMP_DIR}/${ZIP_NAME}"
unzip -q "${TEMP_DIR}/${ZIP_NAME}" -d "${TEMP_DIR}"

# Copy binary
cp "${TEMP_DIR}/promtail-linux-${ARCH}" /usr/local/bin/promtail
chmod 755 /usr/local/bin/promtail

# 4. Copy configuration
echo "[4/5] Setting up configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="${SCRIPT_DIR}/../configs/promtail/promtail-config.yaml"

if [ -f "${REPO_CONFIG}" ]; then
  cp "${REPO_CONFIG}" /etc/promtail/promtail-config.yaml
else
  cat <<'EOF' > /etc/promtail/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
  - job_name: syslog
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          __path__: /var/log/syslog
EOF
fi

chown -R promtail:promtail /etc/promtail
touch /var/log/positions.yaml
chown promtail:promtail /var/log/positions.yaml

# 5. Configure systemd service
echo "[5/5] Creating /etc/systemd/system/promtail.service..."
REPO_SERVICE="${SCRIPT_DIR}/../configs/promtail/promtail.service"
if [ -f "${REPO_SERVICE}" ]; then
  cp "${REPO_SERVICE}" /etc/systemd/system/promtail.service
else
  cat <<'EOF' > /etc/systemd/system/promtail.service
[Unit]
Description=Promtail Log Collector Agent
Documentation=https://grafana.com/docs/loki/latest/clients/promtail/
After=network.target loki.service

[Service]
User=promtail
Group=promtail
SupplementaryGroups=adm
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yaml
Restart=always
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
fi

# Cleanup
rm -rf "${TEMP_DIR}"

# Reload systemd and start service
systemctl daemon-reload
systemctl enable promtail
systemctl restart promtail

sleep 3
if systemctl is-active --quiet promtail; then
  echo "=========================================================="
  echo "✓ Promtail v${PROMTAIL_VERSION} installed successfully!"
  echo "✓ Shipping logs to Loki (http://localhost:3100)"
  echo "✓ Health Check: http://localhost:9080/ready"
  echo "=========================================================="
else
  echo "Warning: Promtail service is not active. Check: journalctl -u promtail -n 50"
  exit 1
fi
