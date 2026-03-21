#!/bin/bash

# Check for parameter
if [ -z "$1" ]; then
  echo "Usage: sudo $0 socks5://[user:pass@]host:port"
  exit 1
fi

PROXY_URL=$1

# Parse URL using python3 (built-in on macOS) for reliability
HOST=$(python3 -c "from urllib.parse import urlparse; u = urlparse('$PROXY_URL'); print(u.hostname)")
PORT=$(python3 -c "from urllib.parse import urlparse; u = urlparse('$PROXY_URL'); print(u.port or 1080)")
USER=$(python3 -c "from urllib.parse import urlparse; u = urlparse('$PROXY_URL'); print(u.username or '')")
PASS=$(python3 -c "from urllib.parse import urlparse; u = urlparse('$PROXY_URL'); print(u.password or '')")

if [ -z "$HOST" ]; then
  echo "Error: Invalid proxy URL"
  exit 1
fi

# Resolve Host to IP for routing
PROXY_IP=$(dig +short $HOST | head -n1)
if [ -z "$PROXY_IP" ]; then
  # Might be an IP already
  PROXY_IP=$HOST
fi

# Configuration
CONFIG="tun.yml"
BINARY="./hev-socks5-tunnel"
TUN_NAME="utun10"
TUN_IP="10.0.0.1"
TUN_GW="10.0.0.2"

# Check for root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo)"
  exit 1
fi

# Generate tun.yml dynamically
cat <<EOF > $CONFIG
tunnel:
  name: $TUN_NAME
  mtu: 1500
  address: $TUN_IP
  netmask: 255.255.255.0
  gateway: $TUN_GW

socks5:
  port: $PORT
  address: $PROXY_IP
  username: $USER
  password: $PASS
  udp: 'udp'

misc:
  log-level: ${LOG_LEVEL:-warn}
  udp-read-write-timeout: 60000
EOF

# Get default gateway
GATEWAY=$(route -n get default | grep gateway | awk '{print $2}')
echo "Detected default gateway: $GATEWAY"
echo "Proxy Target: $HOST ($PROXY_IP:$PORT)"

# Start HEV in background
echo "Starting HEV Socks5 Tunnel..."
$BINARY $CONFIG > hev.log 2>&1 &
HEV_PID=$!

# Wait for interface
echo "Waiting for $TUN_NAME..."
sleep 2

# Configure Interface
ifconfig $TUN_NAME $TUN_IP $TUN_GW up

# Routing
echo "Configuring routes..."
# 1. Protect proxy traffic
route add $PROXY_IP $GATEWAY
# 2. Redirect all traffic
route add 0.0.0.0/1 $TUN_GW
route add 128.0.0.0/1 $TUN_GW

echo "VPN is UP. Traffic is tunneled through $HOST"
echo "Press Ctrl+C to stop."

# Cleanup on exit
cleanup() {
    echo ""
    echo "Cleaning up..."
    route delete 0.0.0.0/1 $TUN_GW
    route delete 128.0.0.0/1 $TUN_GW
    route delete $PROXY_IP $GATEWAY
    kill $HEV_PID
    exit
}

trap cleanup SIGINT SIGTERM

# Keep script running
wait $HEV_PID
