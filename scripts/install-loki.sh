#!/usr/bin/env bash
# ==============================================================================
# Script: install-loki.sh
# Purpose: Manually install and configure Loki on Ubuntu as a systemd service
# ==============================================================================

set -euo pipefail

LOKI_VERSION="${1:-3.0.0}"

# Detect system architecture
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH_RAW}" && exit 1 ;;
esac

echo "=========================================================="
echo "Installing Loki v${LOKI_VERSION} (${ARCH})..."
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root or with sudo."
  exit 1
fi

apt-get update -y
apt-get install -y unzip curl

# 1. Create dedicated system user
if id -u loki >/dev/null 2>&1; then
  echo "[1/5] User 'loki' already exists. Skipping user creation."
else
  echo "[1/5] Creating 'loki' system user..."
  useradd --no-create-home --shell /bin/false loki
fi

# 2. Create directories
echo "[2/5] Creating directories in /etc/loki and /var/lib/loki..."
mkdir -p /etc/loki /var/lib/loki /var/lib/loki/chunks /var/lib/loki/rules /var/lib/loki/compactor

# 3. Download and extract Loki binary
ZIP_NAME="loki-linux-${ARCH}.zip"
DOWNLOAD_URL="https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/${ZIP_NAME}"
TEMP_DIR="$(mktemp -d)"

echo "[3/5] Downloading ${DOWNLOAD_URL}..."
curl -fsSL "${DOWNLOAD_URL}" -o "${TEMP_DIR}/${ZIP_NAME}"
unzip -q "${TEMP_DIR}/${ZIP_NAME}" -d "${TEMP_DIR}"

# Copy binary
cp "${TEMP_DIR}/loki-linux-${ARCH}" /usr/local/bin/loki
chmod 755 /usr/local/bin/loki

# 4. Copy configuration
echo "[4/5] Setting up configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="${SCRIPT_DIR}/../configs/loki/loki-config.yaml"

if [ -f "${REPO_CONFIG}" ]; then
  cp "${REPO_CONFIG}" /etc/loki/loki-config.yaml
else
  cat <<'EOF' > /etc/loki/loki-config.yaml
auth_enabled: false
server:
  http_listen_port: 3100
common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory
schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
storage_config:
  tsdb:
    dir: /var/lib/loki/tsdb
  filesystem:
    directory: /var/lib/loki/chunks
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_query_length: 721h
EOF
fi

chown -R loki:loki /etc/loki /var/lib/loki

# 5. Configure systemd service
echo "[5/5] Creating /etc/systemd/system/loki.service..."
REPO_SERVICE="${SCRIPT_DIR}/../configs/loki/loki.service"
if [ -f "${REPO_SERVICE}" ]; then
  cp "${REPO_SERVICE}" /etc/systemd/system/loki.service
else
  cat <<'EOF' > /etc/systemd/system/loki.service
[Unit]
Description=Loki Log Aggregation System
Documentation=https://grafana.com/docs/loki/latest/
After=network.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-config.yaml
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
systemctl enable loki
systemctl restart loki

sleep 3
if systemctl is-active --quiet loki; then
  echo "=========================================================="
  echo "✓ Loki v${LOKI_VERSION} installed successfully!"
  echo "✓ API Endpoint: http://localhost:3100/ready"
  echo "=========================================================="
else
  echo "Warning: Loki service is not active. Check: journalctl -u loki -n 50"
  exit 1
fi
