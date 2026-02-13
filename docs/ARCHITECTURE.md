# Architecture

> Deep reference for ÆON CLI internals, design decisions, and data flow.

## Design Principles

1. **Plugin-first** — Every feature is a module. Core provides loading, not logic.
2. **Zero-config start** — `aeon dashboard` works out of the box with sensible defaults.
3. **Profile-driven layouts** — Resolution detection selects the right tmux geometry automatically.
4. **Offline-tolerant** — Cached data keeps panels populated when APIs are unreachable.
5. **SSH-native** — Fleet management uses standard SSH, no agents or daemons required.

## System Layers

```
┌──────────────────────────────────────────────┐
│  User Command: aeon <module> [args]          │
├──────────────────────────────────────────────┤
│  Entry Point: ./aeon                         │
│  ├─ Parse global flags (--profile, --config) │
│  ├─ Load lib/*.sh                            │
│  ├─ config_init()                            │
│  ├─ detect_profile()                         │
│  └─ load_module() → modules/<name>/module.sh │
├──────────────────────────────────────────────┤
│  Libraries (lib/)                            │
│  ├─ core.sh    — Colors, logging, box draw   │
│  ├─ config.sh  — YAML config, host registry  │
│  ├─ detect.sh  — Resolution, hardware detect │
│  └─ ssh.sh     — Remote exec, fleet mgmt     │
├──────────────────────────────────────────────┤
│  Modules (modules/)                          │
│  ├─ dashboard/ — tmux dashboard builder      │
│  ├─ status/    — System status monitor       │
│  ├─ deploy/    — Fleet deployment            │
│  └─ config/    — Config management           │
├──────────────────────────────────────────────┤
│  Config (~/.rapoldio/)                           │
│  ├─ config.yaml  — Main settings             │
│  ├─ hosts.yaml   — Fleet registry            │
│  └─ cache/       — API response cache        │
└──────────────────────────────────────────────┘
```

## Module Loading

The plugin system is convention-based:

1. CLI receives `aeon <module>` command
2. Looks for `$RCLI_MODULES/<module>/module.sh`
3. Sources the file (inheriting all lib functions)
4. Calls `mod_<module>_main "$@"`

**Convention:** Each module MUST define `mod_<name>_main()` and include a `# @desc` comment.

## Resolution Profile System

Detection maps terminal columns to named profiles:

| Columns | Profile | Typical Resolution | Dashboard Layout |
|---------|---------|-------------------|-----------------|
| <101 | `sd` | 640×480 | Single column, no side panels |
| 101-159 | `hd` | 1280×720 | Two columns, compact panels |
| 160-212 | `fhd` | 1920×1080 | Three zones, full panels |
| 213-299 | `qhd` | 2560×1440 | Extended layout, larger charts |
| 300+ | `uhd` | 3840×2160 | All panels, maximum detail |

Each profile is a `.conf` file sourced by the dashboard module, exporting layout variables (`TOP_H`, `RIGHT_W`, `LEFT_STATUS_W`, `BTOP_H`).

## Dashboard tmux Layout

The dashboard builds a 5-pane tmux session:

```
┌───────────────────────────────────────────┐
│ Pane 0: Top Bar (full width, TOP_H rows)  │
├──────────┬──────────────────┬─────────────┤
│ Pane 1   │ Pane 2           │ Pane 4      │
│ Status   │ Center TUI       │ Right Panel │
│ (LEFT_W) │                  │ (RIGHT_W)   │
├──────────┴──────────────────┤             │
│ Pane 3: btop (BTOP_H rows)  │             │
└──────────────────────────────┴─────────────┘
```

## Data Caching

External API responses are cached to `/tmp/aeon_markets/` with configurable TTLs:

| Data Source | Cache File | TTL |
|-------------|-----------|-----|
| CoinGecko prices | `prices.json` | 120s |
| BTC 7d chart | `btc_chart.json` | 600s |
| ETH 7d chart | `eth_chart.json` | 600s |
| Gold chart | `gold_chart.json` | 600s |
| Crypto news RSS | `news.xml` | 300s |
| 20min news RSS | `news_20min.xml` | 300s |
| Weather | `weather.json` | 600s |

## Security Model

- SSH connections use `BatchMode=yes` and `StrictHostKeyChecking=no` for automation
- No passwords stored in config — uses SSH key auth
- Gateway host is the only externally-facing connection point
- Fleet Pis communicate only through the gateway over Tailscale
