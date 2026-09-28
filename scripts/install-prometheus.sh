#!/usr/bin/env bash
# ==============================================================================
# Script: install-prometheus.sh
# Purpose: Manually install and configure Prometheus on Ubuntu as a systemd service
# ==============================================================================

set -euo pipefail

PROMETHEUS_VERSION="${1:-2.54.1}"

# Detect system architecture
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH_RAW}" && exit 1 ;;
esac

echo "=========================================================="
echo "Installing Prometheus v${PROMETHEUS_VERSION} (${ARCH})..."
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root or with sudo."
  exit 1
fi

# 1. Create dedicated system user
if id -u prometheus >/dev/null 2>&1; then
  echo "[1/6] User 'prometheus' already exists. Skipping user creation."
else
  echo "[1/6] Creating 'prometheus' system user..."
  useradd --no-create-home --shell /bin/false prometheus
fi

# 2. Create required directory tree
echo "[2/6] Creating directories in /etc/prometheus and /var/lib/prometheus..."
mkdir -p /etc/prometheus /var/lib/prometheus

# 3. Download and extract Prometheus tarball
TAR_NAME="prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${TAR_NAME}"
TEMP_DIR="$(mktemp -d)"

echo "[3/6] Downloading ${DOWNLOAD_URL}..."
curl -fsSL "${DOWNLOAD_URL}" -o "${TEMP_DIR}/${TAR_NAME}"
tar -xzf "${TEMP_DIR}/${TAR_NAME}" -C "${TEMP_DIR}"

# 4. Copy binaries and web assets
echo "[4/6] Installing binaries to /usr/local/bin..."
cp "${TEMP_DIR}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}/prometheus" /usr/local/bin/
cp "${TEMP_DIR}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}/promtool" /usr/local/bin/
chmod 755 /usr/local/bin/prometheus /usr/local/bin/promtool

cp -r "${TEMP_DIR}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}/consoles" /etc/prometheus/ 2>/dev/null || true
cp -r "${TEMP_DIR}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}/console_libraries" /etc/prometheus/ 2>/dev/null || true

# 5. Copy or create prometheus.yml
echo "[5/6] Configuring prometheus.yml..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="${SCRIPT_DIR}/../configs/prometheus/prometheus.yml"

if [ -f "${REPO_CONFIG}" ]; then
  cp "${REPO_CONFIG}" /etc/prometheus/prometheus.yml
else
  cat <<'EOF' > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF
fi

# Set directory permissions
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chmod 755 /etc/prometheus
chmod 755 /var/lib/prometheus

# 6. Configure systemd service
echo "[6/6] Creating /etc/systemd/system/prometheus.service..."
REPO_SERVICE="${SCRIPT_DIR}/../configs/prometheus/prometheus.service"
if [ -f "${REPO_SERVICE}" ]; then
  cp "${REPO_SERVICE}" /etc/systemd/system/prometheus.service
else
  cat <<'EOF' > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Time Series Collection and Alerting Server
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle

ExecReload=/bin/kill -HUP $MAINPID
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
systemctl enable prometheus
systemctl restart prometheus

sleep 2
if systemctl is-active --quiet prometheus; then
  echo "=========================================================="
  echo "✓ Prometheus v${PROMETHEUS_VERSION} installed successfully!"
  echo "✓ Web UI: http://localhost:9090"
  echo "✓ Targets URL: http://localhost:9090/targets"
  echo "=========================================================="
else
  echo "Warning: Prometheus service is not active. Check: journalctl -u prometheus -n 50"
  exit 1
fi
