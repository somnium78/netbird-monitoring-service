#!/bin/bash
set -e

echo "Installing NetBird Monitoring Service..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Copy files
cp src/netbird-monitor.sh /usr/local/bin/
cp src/netbird-monitor.service /etc/systemd/system/
cp src/netbird-monitor.timer /etc/systemd/system/
cp src/netbird-monitor.logrotate /etc/logrotate.d/netbird-monitor

# Create directories
mkdir -p /etc/netbird
mkdir -p /var/log/netbird

# Copy config if it doesn't exist
if [ ! -f /etc/netbird/monitor.conf ]; then
    cp src/netbird-monitor.conf.example /etc/netbird/monitor.conf
    echo "Created /etc/netbird/monitor.conf - please configure it"
fi

# Set permissions
chmod +x /usr/local/bin/netbird-monitor.sh
chmod 600 /etc/netbird/monitor.conf
chown root:root /var/log/netbird
chmod 755 /var/log/netbird

# Enable and start service
systemctl daemon-reload
systemctl enable netbird-monitor.timer
systemctl start netbird-monitor.timer

echo "✅ NetBird Monitoring Service installed successfully"
echo "Configure /etc/netbird/monitor.conf and check status with:"
echo "systemctl status netbird-monitor.timer"
