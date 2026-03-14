#!/usr/bin/env bash
set -euo pipefail

# Installer for the Document Generation service
# Run as root (sudo)

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
DEST=/opt/doc-gen
SERVICE_FILE=/etc/systemd/system/docgen.service

usage() {
  echo "Usage: sudo $0"
  exit 1
}

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

echo "Installing dependencies: pandoc, texlive-xetex, inotify-tools"
apt-get update
apt-get install -y pandoc texlive-xetex inotify-tools || {
  echo "Failed to install packages. Please install them manually and re-run the installer."
  exit 1
}

# Create destination folders
mkdir -p "$DEST"
rsync -av --exclude '.git' "$REPO_DIR/" "$DEST/"

# Ensure script is executable
chmod +x "$DEST/scripts/render.sh"

# Create logs dir
mkdir -p "$DEST/logs"
chown -R root:root "$DEST"
chmod -R 755 "$DEST"

# Install systemd service
cat > "$SERVICE_FILE" <<'SERVICE'
[Unit]
Description=Document Generation Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c '/opt/doc-gen/scripts/render.sh'
Restart=always
RestartSec=5
WorkingDirectory=/opt/doc-gen
# Run as root by default. Change User= and Group= if you want a less-privileged account.

[Install]
WantedBy=multi-user.target
SERVICE

# If running as a non-root user is desired, provide instructions:
cat >> "$SERVICE_FILE" <<'SERVICE_EXTRA'
# Example to run as 'docuser': edit the Unit and add under [Service]:
# User=docuser
# Group=docuser
SERVICE_EXTRA

systemctl daemon-reload
systemctl enable --now docgen.service

echo "Installation complete. Service 'docgen' enabled and started."

echo "Logs are written to /opt/doc-gen/logs/render.log"

echo "If you need to stop the service: sudo systemctl stop docgen"

exit 0
