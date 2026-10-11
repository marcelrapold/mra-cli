# Deployment Guide

> Deploy ÆON CLI across your Raspberry Pi fleet.

## Prerequisites

On each target Pi:
- SSH server running with key-based auth
- Bash 5.x, Python 3.9+, tmux 3.x
- Network connectivity (Tailscale recommended)

## Register Hosts

```bash
aeon config host add pi-living 192.168.1.10 aeon dashboard fhd
aeon config host add pi-office 100.81.x.x aeon dashboard uhd
```

## Deploy

```bash
# Full deployment to all hosts
aeon deploy all

# Dashboard scripts only
aeon deploy dashboard

# Config sync
aeon deploy config
```

## What Gets Deployed

`aeon deploy all` performs:
1. `rsync` of entire `cli/` directory (excluding `.git`)
2. Symlinks `aeon` to `~/bin/aeon` on each host
3. Sets executable permissions

## Auto-Start Dashboard on Boot

Add to each Pi's crontab or systemd:

```bash
# crontab -e
@reboot sleep 10 && /home/aeon/cli/aeon dashboard start
```

Or create a systemd service — see the [wiki](https://github.com/marcelrapold/mra-cli/wiki) for a template.

## Update Cycle

```bash
# Pull latest from GitHub and redeploy to all hosts
aeon deploy update
```
