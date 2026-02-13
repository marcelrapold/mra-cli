# Resolution Profiles

> How ÆON CLI adapts to different screen sizes and resolutions.

## Overview

ÆON CLI auto-detects terminal dimensions and selects a resolution profile that controls the tmux dashboard layout. This ensures optimal use of screen real estate from a 640×480 display to a 4K monitor.

## Profile Detection

Detection uses terminal column count (`tput cols`):

```
Terminal Columns → Profile Selection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
< 101 cols  ─────→  SD   (640×480)
101-159     ─────→  HD   (1280×720)
160-212     ─────→  FHD  (1920×1080)
213-299     ─────→  QHD  (2560×1440)
300+        ─────→  UHD  (3840×2160)
```

Override with: `aeon --profile <name> dashboard` or `export RCLI_PROFILE=uhd`

## Profile Parameters

Each profile defines these tmux layout variables:

| Parameter | Description |
|-----------|-------------|
| `COLS` | Expected terminal width |
| `ROWS` | Expected terminal height |
| `TOP_H` | Top bar height (matrix rain + figlet) |
| `RIGHT_W` | Right panel width (markets, news, weather) |
| `LEFT_STATUS_W` | Left status panel width |
| `BTOP_H` | btop panel height |

## Profile Details

### SD — 640×480

Minimal single-column layout. No side panels. Top bar and main content only.

```
COLS=80  ROWS=24  TOP_H=6  RIGHT_W=30  LEFT_STATUS_W=20  BTOP_H=10
```

### HD — 1280×720

Compact two-column layout. Reduced chart sizes.

```
COLS=106  ROWS=35  TOP_H=8  RIGHT_W=40  LEFT_STATUS_W=22  BTOP_H=16
```

### FHD — 1920×1080 (Default)

Standard three-zone layout. Full panels with comfortable spacing.

```
COLS=160  ROWS=45  TOP_H=8  RIGHT_W=55  LEFT_STATUS_W=25  BTOP_H=24
```

### QHD — 2560×1440

Extended layout with larger charts and more news items.

```
COLS=213  ROWS=60  TOP_H=10  RIGHT_W=60  LEFT_STATUS_W=28  BTOP_H=28
```

### UHD — 3840×2160

Maximum detail. All panels expanded. Full chart resolution.

```
COLS=320  ROWS=90  TOP_H=15  RIGHT_W=65  LEFT_STATUS_W=30  BTOP_H=35
```

## Custom Profiles

Create a custom profile at `modules/dashboard/profiles/<name>.conf`:

```bash
# My custom profile
COLS=200
ROWS=55
TOP_H=10
RIGHT_W=58
LEFT_STATUS_W=26
BTOP_H=26
```

Use it: `aeon --profile custom dashboard`
