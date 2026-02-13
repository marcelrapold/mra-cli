# Changelog

All notable changes to rapoldio CLI will be documented in this file.

## [1.0.0] — 2026-02-12

### Added
- 🎉 Initial release of modular rapoldio CLI framework
- Plugin-based module system with auto-discovery
- **Dashboard module** — Full tmux dashboard with 5-pane layout
  - Matrix rain top bar with figlet header
  - Right panel: live BTC/ETH/Gold charts, sparklines, news, weather, world clock
  - Status panel: gateway KPIs and service status
  - btop integration for system monitoring
- **Resolution profiles** — Auto-detect SD/HD/FHD/QHD/UHD with adaptive layouts
- **Status module** — System overview, gateway check, fleet health
- **Deploy module** — SSH-based parallel deployment to Pi fleet
- **Config module** — Interactive config management, host registry
- **Core libraries** — Colors, logging, box drawing, cached fetch, spinner
- **SSH helpers** — Remote exec, file transfer, broadcast, gateway shortcuts
- **One-liner installer** — `curl -fsSL aeon.rapold.io/aeoncli | bash`
- **Cyberpunk theme** — Neon cyan/magenta color scheme
- Comprehensive documentation suite
