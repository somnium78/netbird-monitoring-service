#!/bin/bash
set -e

# Read version from central file
if [ -f VERSION ]; then
    VERSION=$(cat VERSION)
else
    VERSION="1.1.0"
fi

PACKAGE_NAME="netbird-monitoring-service"
ARCH="all"
BUILD_DIR="build"
DEB_DIR="${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}"

echo "Building ${PACKAGE_NAME} v${VERSION}"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$DEB_DIR"

# Create directory structure
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/local/bin"
mkdir -p "$DEB_DIR/etc/netbird"
mkdir -p "$DEB_DIR/etc/systemd/system"
mkdir -p "$DEB_DIR/etc/logrotate.d"
mkdir -p "$DEB_DIR/var/log/netbird"

# Copy files from src directory
cp src/netbird-monitor.sh "$DEB_DIR/usr/local/bin/"
cp src/netbird-monitor.service "$DEB_DIR/etc/systemd/system/"
cp src/netbird-monitor.timer "$DEB_DIR/etc/systemd/system/"
cp src/netbird-monitor.logrotate "$DEB_DIR/etc/logrotate.d/netbird-monitor"
cp src/netbird-monitor.conf.example "$DEB_DIR/etc/netbird/monitor.conf"

# Make script executable
chmod +x "$DEB_DIR/usr/local/bin/netbird-monitor.sh"

# Create control file with package replacement
cat > "$DEB_DIR/DEBIAN/control" << CONTROL_EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: admin
Priority: optional
Architecture: $ARCH
Depends: systemd, bash, curl
Replaces: netbird-monitor (<< 1.1.0)
Conflicts: netbird-monitor (<< 1.1.0)
Provides: netbird-monitor
Maintainer: somnium78 <user@example.com>
Description: NetBird Monitoring Service
 A systemd service and timer for monitoring NetBird VPN connections.
 Provides automated monitoring and alerting for NetBird network status.
 .
 This package replaces the old netbird-monitor package.
CONTROL_EOF

# Create postinst script
cat > "$DEB_DIR/DEBIAN/postinst" << 'POSTINST_EOF'
#!/bin/bash
set -e

# Create log directory
mkdir -p /var/log/netbird
chown root:root /var/log/netbird
chmod 755 /var/log/netbird

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable netbird-monitor.timer
systemctl start netbird-monitor.timer

echo "✅ NetBird Monitoring Service installed"
echo "Configure /etc/netbird/monitor.conf and check status with:"
echo "systemctl status netbird-monitor.timer"

# Migration message
if [ "$1" = "configure" ] && [ -n "$2" ]; then
    echo "📦 Successfully upgraded from netbird-monitor to netbird-monitoring-service"
fi
POSTINST_EOF

# Create prerm script
cat > "$DEB_DIR/DEBIAN/prerm" << 'PRERM_EOF'
#!/bin/bash
set -e

# Stop and disable services
systemctl stop netbird-monitor.timer || true
systemctl disable netbird-monitor.timer || true
systemctl stop netbird-monitor.service || true
PRERM_EOF

chmod +x "$DEB_DIR/DEBIAN/postinst"
chmod +x "$DEB_DIR/DEBIAN/prerm"

# Build package
dpkg-deb --build "$DEB_DIR"
mv "${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" .

echo "✅ Built: ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
ls -la *.deb
