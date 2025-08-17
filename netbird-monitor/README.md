# NetBird Connection Monitor

A systemd-based service for automatic monitoring and restoration of NetBird connections.

## Description

The NetBird Connection Monitor continuously monitors the number of connected peers in a NetBird network. When the number of connected peers falls below a configured threshold, NetBird is automatically restarted to restore connections.

## Features

- ✅ Automatic monitoring of NetBird peer connections
- ✅ Configurable threshold for minimum peer count
- ✅ Systemd timer for regular checks (default every 15 minutes)
- ✅ Comprehensive logging with automatic log rotation
- ✅ Debian package for easy installation
- ✅ Fully configurable

## Prerequisites

- Debian/Ubuntu-based system
- NetBird already installed and configured
- Systemd
- Root privileges for installation

## Installation

### Option 1: Debian Package (Recommended)

```bash
# Install package
sudo dpkg -i netbird-monitor-1.0.deb

# Fix missing dependencies if needed
sudo apt-get install -f
```

### Option 2: Manual Installation

```bash
# Clone repository
git clone https://github.com/username/netbird-monitor.git
cd netbird-monitor

# Run installation script
sudo ./install.sh
```

## Files and Components

### Monitor Script
```bash
/usr/local/bin/netbird-monitor.sh
```

### Systemd Services
```bash
/etc/systemd/system/netbird-monitor.service
/etc/systemd/system/netbird-monitor.timer
```

### Logrotate Configuration
```bash
/etc/logrotate.d/netbird-monitor
```

### Log File
```bash
/var/log/netbird-monitor.log
```

## Configuration

### Adjust Threshold

Edit the monitor script to change the minimum peer threshold:

```bash
sudo nano /usr/local/bin/netbird-monitor.sh

# Change line:
MIN_PEERS=3  # Set to desired value
```

### Adjust Check Interval

Edit the systemd timer:

```bash
sudo nano /etc/systemd/system/netbird-monitor.timer

# For 15-minute interval:
OnBootSec=15min
OnUnitActiveSec=15min

# For 5-minute interval:
OnBootSec=5min
OnUnitActiveSec=5min
```

After changes, reload systemd:

```bash
sudo systemctl daemon-reload
sudo systemctl restart netbird-monitor.timer
```

## Usage

### Check Service Status

```bash
# Timer status
systemctl status netbird-monitor.timer

# Service status
systemctl status netbird-monitor.service

# Show recent executions
journalctl -u netbird-monitor.service -n 20
```

### View Logs

```bash
# Follow live log
tail -f /var/log/netbird-monitor.log

# Show last 50 lines
tail -n 50 /var/log/netbird-monitor.log

# List log files
ls -la /var/log/netbird-monitor*
```

### Manual Test

```bash
# Run script manually
sudo /usr/local/bin/netbird-monitor.sh

# Check NetBird status
netbird status
```

### Service Management

```bash
# Start timer
sudo systemctl start netbird-monitor.timer

# Stop timer
sudo systemctl stop netbird-monitor.timer

# Enable timer (autostart)
sudo systemctl enable netbird-monitor.timer

# Disable timer
sudo systemctl disable netbird-monitor.timer
```

## Log Format

The system logs all activities in the following format:

```
2025-08-17 10:30:15 - INFO: NetBird monitor started
2025-08-17 10:30:15 - INFO: Connected peers: 5/8
2025-08-17 10:30:15 - INFO: NetBird status OK (5/8 peers)
2025-08-17 10:30:15 - INFO: NetBird monitor finished
```

When issues occur:

```
2025-08-17 10:35:15 - WARNING: Only 2 peers connected (minimum: 3). Restarting NetBird...
2025-08-17 10:35:18 - INFO: NetBird successfully restarted
```

## Troubleshooting

### Common Issues

#### Timer not running
```bash
# Check timer status
systemctl status netbird-monitor.timer

# Start timer manually
sudo systemctl start netbird-monitor.timer
```

#### Script errors
```bash
# Check script permissions
ls -la /usr/local/bin/netbird-monitor.sh

# Set permissions
sudo chmod +x /usr/local/bin/netbird-monitor.sh
```

#### NetBird command not found
```bash
# Check NetBird installation
which netbird
netbird version

# Check PATH
echo $PATH
```

#### Log file not writable
```bash
# Check log file permissions
ls -la /var/log/netbird-monitor.log

# Fix permissions
sudo touch /var/log/netbird-monitor.log
sudo chmod 644 /var/log/netbird-monitor.log
```

### Debug Mode

For detailed troubleshooting, run the script with debug output:

```bash
# Run script with debug output
sudo bash -x /usr/local/bin/netbird-monitor.sh
```

### Test Logrotate

```bash
# Test logrotate configuration
sudo logrotate -d /etc/logrotate.d/netbird-monitor

# Manual rotation
sudo logrotate -f /etc/logrotate.d/netbird-monitor
```

## Uninstallation

### Remove Debian Package
```bash
sudo dpkg -r netbird-monitor
```

### Manual Uninstallation
```bash
# Stop and disable services
sudo systemctl stop netbird-monitor.timer
sudo systemctl disable netbird-monitor.timer

# Remove files
sudo rm /usr/local/bin/netbird-monitor.sh
sudo rm /etc/systemd/system/netbird-monitor.service
sudo rm /etc/systemd/system/netbird-monitor.timer
sudo rm /etc/logrotate.d/netbird-monitor

# Reload systemd
sudo systemctl daemon-reload

# Optional: Remove log files
sudo rm /var/log/netbird-monitor*
```

## Development

### Building Package

```bash
# Prepare package structure
mkdir -p netbird-monitor-1.0/{DEBIAN,usr/local/bin,etc/systemd/system,etc/logrotate.d}

# Copy files
cp netbird-monitor.sh netbird-monitor-1.0/usr/local/bin/
cp netbird-monitor.service netbird-monitor-1.0/etc/systemd/system/
cp netbird-monitor.timer netbird-monitor-1.0/etc/systemd/system/
cp netbird-monitor.logrotate netbird-monitor-1.0/etc/logrotate.d/netbird-monitor

# Build Debian package
dpkg-deb --build netbird-monitor-1.0
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## Why GPL v3?

This project uses GPL v3 to ensure that any improvements or modifications to this monitoring script remain open source and benefit the entire community. This aligns with the open source philosophy of NetBird and promotes collaborative development.

## Disclaimer

**DISCLAIMER OF WARRANTY AND LIMITATION OF LIABILITY**

This software is provided "as is" without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

Use this software at your own risk. The authors are not responsible for any damage or data loss that may occur from using this software.

## Support

For issues and questions:

- Create an issue on GitHub
- Check the NetBird documentation: https://docs.netbird.io/
- Visit the NetBird community: https://github.com/netbirdio/netbird

Note: This is an unofficial monitoring script and is not affiliated with or endorsed by NetBird.

## Changelog

### Version 1.0
- Initial release
- Basic NetBird monitoring
- Systemd timer integration
- Debian package support
- Logrotate integration

