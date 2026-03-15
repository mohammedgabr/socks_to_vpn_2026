# HEV Socks5 Tunnel CLI

High-performance SOCKS5 to VPN tunnel for macOS.

## 🚀 Quick Start

Run the automation script with your SOCKS5 URL:

```bash
sudo ./run-vpn.sh socks5://user:pass@host:port
```

## 📂 Files
- `hev-socks5-tunnel`: The core C-based engine.
- `run-vpn.sh`: Master script for TUN setup, routing, and cleanup.
- `tun.yml`: Generated automatically by the script.

## 🛑 Stop
Press **Ctrl+C** to stop the tunnel and restore normal network routes.
