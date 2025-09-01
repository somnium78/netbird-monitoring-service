#!/bin/bash
set -e

echo "Testing NetBird Monitoring Service..."

# Check if files exist
echo "Checking files..."
test -f src/netbird-monitor.sh && echo "✅ Script exists"
test -f src/netbird-monitor.service && echo "✅ Service file exists"
test -f src/netbird-monitor.timer && echo "✅ Timer file exists"

# Test script syntax
echo "Testing script syntax..."
bash -n src/netbird-monitor.sh && echo "✅ Script syntax OK"

# Test systemd files
echo "Testing systemd files..."
systemd-analyze verify src/netbird-monitor.service && echo "✅ Service file valid"
systemd-analyze verify src/netbird-monitor.timer && echo "✅ Timer file valid"

echo "✅ All tests passed"
