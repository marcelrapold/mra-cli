<div align="center">

```
    ██████╗  █████╗ ██████╗  ██████╗ ██╗     ██████╗ ██╗ ██████╗
    ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║     ██╔══██╗██║██╔═══██╗
    ██████╔╝███████║██████╔╝██║   ██║██║     ██║  ██║██║██║   ██║
    ██╔══██╗██╔══██║██╔═══╝ ██║   ██║██║     ██║  ██║██║██║   ██║
    ██║  ██║██║  ██║██║     ╚██████╔╝███████╗██████╔╝██║╚██████╔╝
    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚══════╝╚═════╝ ╚═╝ ╚═════╝
```

<h3>rapoldio CLI</h3>
<p><em>Multi-agent CLI for ÆON & ÆTHRA — Cyberpunk dashboards, fleet management, Pi deployment</em></p>

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)]()
[![License](https://img.shields.io/github/license/rapoldio/cli)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash_5.x-4EAA25?logo=gnubash)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?logo=python)](https://python.org)
[![Platform](https://img.shields.io/badge/Platform-Raspberry_Pi-C51A4A?logo=raspberrypi)](https://www.raspberrypi.com/)

</div>

---

## Overview

**rapoldio CLI** is a multi-agent, modular command-line framework for managing a fleet of Raspberry Pis. It powers cyberpunk-styled tmux dashboards featuring matrix rain animations, live cryptocurrency charts, world clocks, weather feeds, news tickers, and system monitoring.

### 🤖 The Agent Concept

This CLI supports **two AI agent identities** that share the same codebase but have distinct personalities:

| Agent | Identity | Focus |
|-------|----------|-------|
| **ÆON** | The Architect | Infrastructure, building, deployment, systems |
| **ÆTHRA** | The Companion | Creative, personal, monitoring, insight |

Each agent gets its own entrypoint (`aeon` / `aethra`), dashboard branding, task panels, and status displays — while sharing the same core modules, fleet management, and market/weather/news panels.

## Key Features

- 🤖 **Multi-Agent** — Two agent identities (ÆON & ÆTHRA) with shared infrastructure
- 🎨 **Adaptive Resolution** — Auto-detects SD/HD/FHD/QHD/UHD and adjusts tmux layout
- 🐉 **Matrix Rain Top Bar** — Animated katakana rain behind centered figlet header
- 📈 **Live Market Charts** — 7-day BTC/ETH/Gold charts with sparklines (CoinGecko API)
- 🌍 **World Clock & Weather** — Multi-timezone display with Zurich weather (Open-Meteo)
- 📰 **News Ticker** — Rotating crypto & local news feeds (RSS)
- 🔧 **Plugin System** — Drop a `module.sh` into `modules/` and it auto-registers
- 🚀 **Fleet Deployment** — SSH-based push to all registered Pis in parallel

## Quick Install

```bash
curl -fsSL cli.rapold.io | bash
```

The installer will ask you to choose your agent (ÆON or ÆTHRA) and set everything up.

### Manual Install

```bash
git clone https://github.com/rapoldio/cli.git ~/rapoldio-cli
cd ~/rapoldio-cli
chmod +x aeon aethra
./install.sh
```

## Usage

```bash
# Launch dashboard (as your chosen agent)
aeon dashboard
aethra dashboard

# Force a resolution profile
aeon --profile uhd dashboard

# System status
aeon status

# Fleet management
aeon deploy all
aeon config host add pi-living 192.168.1.10

# Configuration
aeon config show
aeon config edit
```

## Architecture

```
rapoldio-cli/
├── aeon                         # ÆON agent entrypoint
├── aethra                       # ÆTHRA agent entrypoint
├── lib/
│   ├── main.sh                  # Shared CLI framework (sourced by entrypoints)
│   ├── core.sh                  # Colors, logging, box drawing, helpers
│   ├── config.sh                # YAML config management (~/.rapoldio/)
│   ├── detect.sh                # Resolution & hardware auto-detection
│   └── ssh.sh                   # SSH/rsync fleet management helpers
├── modules/
│   ├── dashboard/
│   │   ├── module.sh            # Dashboard launcher (agent-aware)
│   │   ├── top_bar.sh           # Matrix rain + figlet header
│   │   ├── right_panel.sh       # Markets, news, weather, clocks
│   │   ├── status_panel.sh      # Local system status fallback
│   │   ├── panels/
│   │   │   ├── shared/          # News, Weather, Crypto, Clock, System
│   │   │   ├── aeon/            # ÆON-specific (tasks, status)
│   │   │   └── aethra/          # ÆTHRA-specific (tasks, status)
│   │   └── profiles/            # Resolution configs (sd/hd/fhd/qhd/uhd)
│   ├── status/                  # System & fleet status
│   ├── deploy/                  # SSH fleet deployment
│   └── config/                  # Configuration management
├── install.sh                   # Multi-agent installer
├── profiles/                    # Theme profiles
└── docs/                        # Documentation
```

## Configuration

Config lives in `~/.rapoldio/`:

| File | Description |
|------|-------------|
| `config.yaml` | Main config (agent, gateway, theme, modules) |
| `hosts.yaml` | Pi fleet registry |
| `cache/` | API response cache |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AGENT_ID` | Active agent identity | from config |
| `RCLI_CONFIG_DIR` | Config directory | `~/.rapoldio` |
| `RCLI_PROFILE` | Force resolution profile | auto-detect |
| `RCLI_DEBUG` | Enable debug logging | `0` |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Shell** | Bash 5.x — CLI framework, module loader, tmux orchestration |
| **Rendering** | Python 3.9+ — Matrix rain, chart rendering, data formatting |
| **Terminal** | tmux — Multi-pane dashboard layout |
| **Data** | CoinGecko, Open-Meteo, RSS — Markets, weather, news |
| **Remote** | SSH / rsync — Fleet management |
| **Platform** | Raspberry Pi OS |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). In short:

1. Fork → feature branch → PR
2. Follow plugin conventions in `docs/MODULES.md`
3. Run `shellcheck` on scripts

## License

[MIT](LICENSE)

---

<div align="center">

**v2.0.0** · Made with 🤝 by **ÆON & ÆTHRA**

</div>
