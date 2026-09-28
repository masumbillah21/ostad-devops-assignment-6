#!/usr/bin/env bash
# ==============================================================================
# Script: setup-github-runner.sh
# Purpose: Guide and automate GitHub Actions Self-Hosted Runner setup on Ubuntu
# ==============================================================================

set -euo pipefail

RUNNER_VERSION="2.321.0"

# Detect system architecture
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64)  RUNNER_ARCH="x64" ;;
  aarch64|arm64) RUNNER_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH_RAW}" && exit 1 ;;
esac

echo "=========================================================="
echo "GitHub Actions Self-Hosted Runner Setup (${RUNNER_ARCH})"
echo "=========================================================="

if [ "$EUID" -eq 0 ]; then
  echo "Note: GitHub Actions Runner should NOT be run directly as root."
  echo "Please run this script as your regular non-root user (e.g., ubuntu or $(logname 2>/dev/null || echo 'current user'))."
  echo "Sudo permissions will be requested only when installing the systemd service."
  exit 1
fi

REPO_URL="${1:-}"
REG_TOKEN="${2:-}"

if [ -z "$REPO_URL" ] || [ -z "$REG_TOKEN" ]; then
  echo "Usage: ./scripts/setup-github-runner.sh <GITHUB_REPO_URL> <RUNNER_REGISTRATION_TOKEN>"
  echo "Example: ./scripts/setup-github-runner.sh https://github.com/my-user/devops-practice A1B2C3D4E5F6G7..."
  echo ""
  echo "To get your token:"
  echo "1. Go to your GitHub repository -> Settings -> Actions -> Runners"
  echo "2. Click 'New self-hosted runner'"
  echo "3. Copy the token provided under 'Configure'"
  echo ""
  read -r -p "Enter GitHub Repository URL (e.g. https://github.com/username/repo): " REPO_URL
  read -r -p "Enter Runner Registration Token: " REG_TOKEN
fi

RUNNER_DIR="${HOME}/actions-runner"
mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

TAR_NAME="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${TAR_NAME}"

echo "[1/4] Downloading GitHub Actions runner package..."
curl -o "${TAR_NAME}" -L "${DOWNLOAD_URL}"

echo "[2/4] Extracting installer..."
tar xzf "./${TAR_NAME}"
rm -f "./${TAR_NAME}"

echo "[3/4] Configuring runner..."
./config.sh --url "${REPO_URL}" --token "${REG_TOKEN}" --name "$(hostname)-runner" --work "_work" --unattended --replace

echo "[4/4] Installing runner as a systemd service..."
sudo ./svc.sh install
sudo ./svc.sh start

sleep 2
sudo ./svc.sh status

echo "=========================================================="
echo "✓ GitHub Actions Self-Hosted Runner is now ONLINE!"
echo "✓ Check your repo Settings -> Actions -> Runners to see it marked green (Idle/Online)"
echo "=========================================================="
