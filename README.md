# NetBird Monitoring Service

A systemd-based monitoring service for NetBird VPN connections with automated alerting and logging.

## Description

The NetBird Monitoring Service provides continuous monitoring of NetBird VPN connections using a systemd timer. It checks connection status, peer availability, and network health, providing alerts and detailed logging for network administrators.

## Features

- ✅ Automated NetBird connection monitoring via systemd timer
- ✅ NetBird API integration for real-time status checks
- ✅ Configurable monitoring intervals and thresholds
- ✅ Comprehensive logging with log rotation
- ✅ Alert notifications (webhook/email support)
- ✅ Automated package builds for Debian and RHEL/CentOS
- ✅ GitHub Actions CI/CD pipeline
- ✅ Easy configuration management
- ✅ Automatic upgrade from old netbird-monitor package

## Prerequisites

- Linux system with systemd
- NetBird client installed and configured
- NetBird API access token (optional for advanced features)
- curl installed
- Root privileges for installation

## Installation

### Package Installation (Recommended)

Download the latest release packages from GitHub:

**Debian/Ubuntu:**
- Download: netbird-monitoring-service_*_all.deb
- Install: sudo dpkg -i netbird-monitoring-service_*.deb

**RHEL8/Rocky8:**
- Download: netbird-monitoring-service-*-el8.rpm
- Install: sudo rpm -i netbird-monitoring-service-*-el8.rpm

**RHEL9/Rocky9:**
- Download: netbird-monitoring-service-*-el9.rpm
- Install: sudo rpm -i netbird-monitoring-service-*-el9.rpm

### Automatic Upgrade from Old Package

If you have the old netbird-monitor package installed, the new package will automatically replace it:
- Old package: netbird-monitor (version 1.0-3 and below)
- New package: netbird-monitoring-service (version 1.1.0+)
- Configuration and functionality remain compatible
- No manual intervention required

### Manual Installation

Clone repository:
- git clone https://github.com/somnium78/netbird-monitoring-service.git
- cd netbird-monitoring-service

Run installation script:
- sudo ./scripts/install.sh

## Configuration

Edit the configuration file:
- sudo nano /etc/netbird/monitor.conf

Example configuration:
- NETBIRD_API_URL="https://api.netbird.io"
- NETBIRD_API_TOKEN="your_api_token_here"
- CHECK_INTERVAL=300
- LOG_LEVEL="INFO"
- ALERT_THRESHOLD=5
- WEBHOOK_URL=""
- EMAIL_RECIPIENT=""

### Environment Variables (Alternative Configuration)

You can also configure the service using systemd environment variables:
- sudo systemctl edit netbird-monitor.service

Add environment variables:
- [Service]
- Environment="MIN_PEERS=3"
- Environment="STATUS_TIMEOUT=10"

Available environment variables:
- MIN_PEERS: Minimum number of connected peers (default: 3)
- STATUS_TIMEOUT: Timeout for netbird status command in seconds (default: 10)

### Adjust Check Interval

Edit the systemd timer to change monitoring frequency:
- sudo nano /etc/systemd/system/netbird-monitor.timer

For different intervals:
- 5 minutes: OnBootSec=5min, OnUnitActiveSec=5min
- 15 minutes (default): OnBootSec=15min, OnUnitActiveSec=15min
- 30 minutes: OnBootSec=30min, OnUnitActiveSec=30min

Apply configuration changes:
- sudo systemctl daemon-reload
- sudo systemctl restart netbird-monitor.timer

## Usage

### Service Management

Check timer status:
- systemctl status netbird-monitor.timer

Check service status:
- systemctl status netbird-monitor.service

View logs:
- journalctl -u netbird-monitor.service -f
- tail -f /var/log/netbird/monitor.log

Manual monitoring run:
- sudo /usr/local/bin/netbird-monitor.sh

Run test suite:
- sudo ./scripts/test.sh

### Service Control

Start/stop timer:
- sudo systemctl start netbird-monitor.timer
- sudo systemctl stop netbird-monitor.timer

Enable/disable autostart:
- sudo systemctl enable netbird-monitor.timer
- sudo systemctl disable netbird-monitor.timer

Check next scheduled run:
- sudo systemctl list-timers netbird-monitor.timer

## How It Works

1. **Timer:** systemd timer runs monitoring checks at configured intervals
2. **Status Check:** Queries NetBird status for connection information
3. **Peer Count:** Monitors number of connected peers against threshold
4. **Auto-Restart:** Restarts NetBird service when peer count is too low
5. **Logging:** Comprehensive logging with automatic rotation
6. **Conditional Monitoring:** Only runs when NetBird service is enabled

## Log Format

The system logs all activities with timestamps:

Normal operation:
- 2025-09-01 10:30:15 - INFO: NetBird monitor started
- 2025-09-01 10:30:15 - INFO: Connected peers: 5/8
- 2025-09-01 10:30:15 - INFO: NetBird status OK (5/8 peers)

When issues occur:
- 2025-09-01 10:35:15 - WARNING: Only 2 peers connected (minimum: 3). Restarting NetBird...
- 2025-09-01 10:35:18 - INFO: NetBird successfully restarted

## Files and Components

### Scripts and Binaries
- /usr/local/bin/netbird-monitor.sh - Main monitoring script

### Systemd Services
- /etc/systemd/system/netbird-monitor.service - Service definition
- /etc/systemd/system/netbird-monitor.timer - Timer configuration

### Configuration
- /etc/netbird/monitor.conf - Main configuration file

### Logging
- /var/log/netbird/monitor.log - Main log file
- /etc/logrotate.d/netbird-monitor - Log rotation configuration

## Security Notes

### Configuration File Security

Set correct permissions for configuration file:
- sudo chmod 600 /etc/netbird/monitor.conf
- sudo chown root:root /etc/netbird/monitor.conf

### Best Practices

- Never commit API tokens to repositories
- Use restricted API tokens with minimal required permissions
- Rotate API tokens regularly
- Use HTTPS for all API connections
- Monitor log files for security events

## Troubleshooting

### Common Issues

**Timer not running:**
- systemctl status netbird-monitor.timer
- sudo systemctl start netbird-monitor.timer

**Script errors:**
- ls -la /usr/local/bin/netbird-monitor.sh
- sudo chmod +x /usr/local/bin/netbird-monitor.sh

**NetBird command not found:**
- which netbird
- netbird version

**Log file not writable:**
- sudo mkdir -p /var/log/netbird
- sudo chmod 755 /var/log/netbird

### Debug Mode

Run with debug output:
- sudo bash -x /usr/local/bin/netbird-monitor.sh
- sudo DEBUG=1 /usr/local/bin/netbird-monitor.sh

### Test Logrotate

Test logrotate configuration:
- sudo logrotate -d /etc/logrotate.d/netbird-monitor
- sudo logrotate -f /etc/logrotate.d/netbird-monitor

## Development and Building

### Building Packages Locally

Build Debian package:
- chmod +x build-deb.sh && ./build-deb.sh

### Automated Builds

The project uses GitHub Actions for automated package building:
- **Triggers:** Git tags starting with 'v' (e.g., v1.1.0)
- **Outputs:** .deb and .rpm packages for multiple distributions
- **Releases:** Automatic GitHub releases with attached packages

Create a new release:
1. Update VERSION file
2. Commit changes: git commit -m "Release version X.Y.Z"
3. Create tag: git tag -a vX.Y.Z -m "Release version X.Y.Z"
4. Push: git push origin main && git push origin vX.Y.Z

## Uninstallation

### Package Uninstallation

**Debian/Ubuntu:**
- sudo apt remove netbird-monitoring-service

**RHEL/CentOS:**
- sudo rpm -e netbird-monitoring-service

### Manual Uninstallation

1. Stop and disable services:
   - sudo systemctl stop netbird-monitor.timer
   - sudo systemctl disable netbird-monitor.timer
   - sudo systemctl stop netbird-monitor.service

2. Remove files:
   - sudo rm /usr/local/bin/netbird-monitor.sh
   - sudo rm /etc/systemd/system/netbird-monitor.service
   - sudo rm /etc/systemd/system/netbird-monitor.timer
   - sudo rm /etc/logrotate.d/netbird-monitor
   - sudo rm -rf /etc/netbird/
   - sudo rm -rf /var/log/netbird/

3. Reload systemd:
   - sudo systemctl daemon-reload

## Changelog

See CHANGELOG.md for detailed version history and changes.

### Version 1.1.0
- Restructured repository with automated builds
- Added package replacement for netbird-monitor
- Multi-platform support (Debian + RHEL/CentOS)
- GitHub Actions CI/CD integration
- Improved configuration management

### Version 1.0-3 (Legacy)
- Manual DEB package structure
- Basic NetBird monitoring functionality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

### Why GPL v3?

This project uses GPL v3 to ensure that any improvements or modifications to this monitoring script remain open source and benefit the entire community. This aligns with the open source philosophy of NetBird and promotes collaborative development.

## Disclaimer

**DISCLAIMER OF WARRANTY AND LIMITATION OF LIABILITY**

This software is provided "as is" without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

Use this software at your own risk. The authors are not responsible for any damage or data loss that may occur from using this software.

## Support

For issues and questions:
- Create an issue on GitHub
- Check NetBird documentation: https://docs.netbird.io/
- Visit the NetBird community: https://github.com/netbirdio/netbird

Note: This is an unofficial monitoring service and is not affiliated with or endorsed by NetBird.

