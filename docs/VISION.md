# ÆEON Dashboard System — Vision Document

> *"Ein Terminal ist kein Kompromiss. Es ist ein Statement."*

Stand: 2026-02-12 | Author: ÆEON + Marcel

---

## Inhaltsverzeichnis

1. [Modul-System Architektur](#1-modul-system-architektur)
2. [Board-Katalog](#2-board-katalog)
3. [Input/Control System](#3-inputcontrol-system)
4. [Technische Deep-Dives](#4-technische-deep-dives)
5. [Pane/Card Katalog](#5-panecard-katalog)
6. [Roadmap](#6-roadmap)
7. [Crazy Ideas / Moonshots](#7-crazy-ideas--moonshots)

---

## 1. Modul-System Architektur

### Grundprinzip

Alles besteht aus drei Ebenen:

```
┌─────────────────────────────────────────┐
│  Board       (Layout + Pane-Sammlung)   │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │  Pane  │ │  Pane  │ │  Pane  │      │
│  │ ┌────┐ │ │ ┌────┐ │ │ ┌────┐ │      │
│  │ │Card│ │ │ │Card│ │ │ │Card│ │      │
│  │ └────┘ │ │ └────┘ │ │ └────┘ │      │
│  └────────┘ └────────┘ └────────┘      │
└─────────────────────────────────────────┘
```

- **Card** — Atomare Dateneinheit. Ein Wert, ein Chart, ein Feed. Hat eine `render(width, height)` Methode.
- **Pane** — Container für eine oder mehrere Cards. Hat Borders, Title, Refresh-Logic.
- **Board** — Definiert welche Panes wo stehen. Hat ein Grid-Layout.

### Composability

Jede Pane ist ein unabhängiges Modul mit:
- `id`: Eindeutiger Name (`cpu-usage`, `btc-chart`, `now-playing`)
- `source`: Datenquelle (command, API, file, websocket)
- `refresh`: Intervall in Sekunden (oder `stream` für Live-Daten)
- `size`: `{ minW, minH, preferredW, preferredH }`
- `render(data, width, height) → string[]`: Pure Function, gibt Terminal-Lines zurück

### Board = Layout + Panes

Ein Board ist eine deklarative Komposition:

```yaml
# boards/ops.yaml
board:
  name: "Ops Board"
  id: ops
  hotkey: "C-1"          # Ctrl+1
  voice_trigger: "ops"
  layout: grid
  
  panes:
    - id: btop-mini
      position: { row: 0, col: 0, rowSpan: 2, colSpan: 2 }
      
    - id: gateway-status
      position: { row: 0, col: 2, rowSpan: 1, colSpan: 1 }
      
    - id: docker-containers
      position: { row: 1, col: 2, rowSpan: 1, colSpan: 1 }
      
    - id: error-log
      position: { row: 2, col: 0, rowSpan: 1, colSpan: 3 }
```

### Grid-System

Das Grid passt sich dynamisch an die Terminal-Grösse an:

| Auflösung | Spalten | Typischer Einsatz |
|-----------|---------|-------------------|
| < 120 cols | 2 | Laptop Terminal |
| 120-200 cols | 3 | Standard Monitor |
| 200-300 cols | 4 | Ultrawide / TV 1080p |
| 300+ cols | 6 | TV 4K mit kleiner Schrift |

Panes können `colSpan`/`rowSpan` nutzen um grössere Bereiche einzunehmen. Bei zu wenig Platz: Panes mit niedrigster `priority` werden ausgeblendet.

### Board-Switching

| Methode | Trigger | Latenz | Difficulty |
|---------|---------|--------|------------|
| Hotkey (tmux) | `Ctrl+1..9` | <50ms | ✅ Easy |
| CLI Command | `aeon board ops` | <100ms | ✅ Easy |
| Voice | "ÆEON, Ops Board" | 1-3s | 🔶 Hard |
| Hardware Remote | Button Press | <200ms | 🔶 Medium |
| Web Remote | Tap on Phone | <500ms | 🔶 Medium |
| Timer/Schedule | Cron-basiert | exact | ✅ Easy |
| Auto-Switch | Event-basiert (z.B. Alert → Ops) | <1s | 🔶 Medium |

### Config-Format

**YAML** ist der klare Winner:
- Human-readable und -editable
- Guter Tooling-Support
- Passt zum bestehenden ÆEON Config-Style

Struktur:
```
~/.config/aeon/
├── boards/
│   ├── ops.yaml
│   ├── investor.yaml
│   ├── news.yaml
│   └── media.yaml
├── panes/
│   ├── btc-chart.yaml      # Pane-spezifische Config (API Keys etc.)
│   └── hue-rooms.yaml
└── dashboard.yaml           # Global: Default Board, Refresh, Theme
```

**Difficulty: ✅ Easy** — YAML Parsing + Grid Layout Engine. Hauptarbeit ist ein sauberes Schema.

---

## 2. Board-Katalog

### 2.1 Ops Board

> Alles im Blick. System Health auf einen Blick.

**ASCII Layout (3-Spalten, 1080p TV):**
```
┌──────────────────────┬─────────────┬─────────────┐
│                      │  Gateway    │  Docker     │
│    btop-mini         │  Status     │  Containers │
│    (CPU/RAM/Net)     │  ● Online   │  12 running │
│                      │  Uptime 47d │  2 stopped  │
│                      ├─────────────┼─────────────┤
│                      │  Git        │  CI/CD      │
│                      │  Activity   │  Pipeline   │
├──────────────────────┴─────────────┴─────────────┤
│  Error Log (scrolling, color-coded)               │
│  [ERROR] 12:03 gateway timeout on /api/health ... │
│  [WARN]  12:01 disk usage 87% on /data ...        │
├───────────────────────┬──────────────────────────-┤
│  Network Traffic      │  Uptime / SLA             │
│  ▁▂▃▅▇▅▃▂▁▂▃▅▇      │  99.97% (30d)             │
└───────────────────────┴───────────────────────────┘
```

**Panes & Datenquellen:**

| Pane | Source | Refresh | Difficulty |
|------|--------|---------|------------|
| btop-mini | `btop` embedded oder eigenes /proc parsing | 2s | ✅ Easy |
| Gateway Status | `openclaw gateway status` | 10s | ✅ Easy |
| Docker Containers | `docker ps --format` | 10s | ✅ Easy |
| Git Activity | `git log --oneline -10` pro Repo | 60s | ✅ Easy |
| CI/CD Status | GitHub Actions API / Webhook | 30s | 🔶 Medium |
| Error Log | Tail von Log-Files oder journalctl | Stream | ✅ Easy |
| Network Traffic | /proc/net/dev oder `vnstat` | 2s | ✅ Easy |
| Uptime/SLA | Custom Tracking (Ping + Log) | 60s | 🔶 Medium |

**Besondere Features:**
- Error Log: Farbkodierung (rot = error, gelb = warn, grau = info)
- Alerts: Pane-Border wird ROT wenn Critical Errors auftreten
- btop-mini: Reduzierte Ansicht — nur CPU Bars + RAM + Top 5 Procs

### 2.2 Investor Cockpit

> Portfolio Performance. Markets at a glance. Data-driven decisions.

**ASCII Layout:**
```
┌─────────────────────────────────────────────────────┐
│  PORTFOLIO TOTAL: CHF 847'231  ▲ +2.3% (24h)       │
├────────────────────────┬────────────────────────────┤
│                        │                            │
│   ₿ BTC                │   Ξ ETH                   │
│   CHF 94'521           │   CHF 3'847               │
│   ▲ +4.2%              │   ▲ +1.8%                 │
│                        │                            │
│   ╭──────────────╮     │   ╭──────────────╮        │
│   │  ▁▂▃▅▇█▇▅▃▅▇│     │   │  ▅▃▂▁▂▃▅▇█▇▅│        │
│   ╰──────────────╯     │   ╰──────────────╯        │
│                        │                            │
├────────────────────────┼────────────────────────────┤
│  Watchlist             │  Fear & Greed Index        │
│  SOL   $187  ▲ +5.1%  │                            │
│  GOLD  $2847 ▼ -0.3%  │      ┌───────┐            │
│  NVDA  $891  ▲ +1.2%  │      │  72   │            │
│  TSLA  $342  ▼ -2.1%  │      │ GREED │            │
│  SPY   $521  ▲ +0.4%  │      └───────┘            │
├────────────────────────┴────────────────────────────┤
│  📰 Top Movers: DOGE +18% | GME -12% | AAPL +3%   │
│  Breaking: Fed signals rate hold through Q2 2026    │
└─────────────────────────────────────────────────────┘
```

**Panes & Datenquellen:**

| Pane | Source | Refresh | Difficulty |
|------|--------|---------|------------|
| Portfolio Total | Aggregation aller Assets | 30s | 🔶 Medium |
| BTC/ETH Charts | CoinGecko / Binance API | 15s | ✅ Easy |
| Gold Chart | Metals API / Yahoo Finance | 60s | ✅ Easy |
| Watchlist | Multi-API (Crypto + Stocks) | 30s | 🔶 Medium |
| P&L | Berechnung aus Portfolio-Config | 30s | 🔶 Medium |
| Fear & Greed | alternative.me API | 300s | ✅ Easy |
| Top Movers | CoinGecko Top Gainers/Losers | 60s | ✅ Easy |
| News Ticker | RSS + Crypto News API | 120s | ✅ Easy |

**Besondere Features:**
- Charts: Sparklines via `spark` oder eigene Unicode-Charts (▁▂▃▄▅▆▇█)
- Portfolio Config: YAML mit Holdings (`btc: 1.5`, `eth: 20`, `gold_oz: 5`)
- Farbkodierung: Grün = Gewinn, Rot = Verlust, mit Intensity je nach %
- Grössere Charts für BTC/ETH — die sind die Hauptpositionen

### 2.3 News Board

> Stay informed. Curated feeds, zero noise.

**ASCII Layout:**
```
┌──────────────────────┬──────────────────────────────┐
│  🔥 TECH NEWS        │  🤖 AI NEWS                  │
│                      │                              │
│  ● OpenAI releases   │  ● New paper: Scaling       │
│    GPT-5 Turbo...    │    Laws for Terminal AI...   │
│  ● Apple Vision Pro  │  ● Anthropic ships Claude    │
│    2 leaked specs    │    Opus 5 with...            │
│  ● Linux 7.0 kernel  │  ● Local LLMs hit 90%       │
│    major rewrite     │    GPT-4 quality on...       │
│                      │                              │
├──────────────────────┼──────────────────────────────┤
│  🌍 WORLD NEWS       │  📱 SOCIAL                   │
│                      │                              │
│  ● Swiss parliament  │  𝕏 @elonmusk: "..."         │
│    votes on AI reg   │  𝕏 @karpathy: "..."         │
│  ● EU carbon tax     │  🟠 r/selfhosted: Top post  │
│    takes effect      │  🟣 HN #1: Show HN: ...     │
│  ● NASA confirms     │                              │
│    Mars sample       │                              │
├──────────────────────┴──────────────────────────────┤
│  ▶▶▶ BREAKING: Fed holds rates │ BTC breaks 100k │ │
│      Swiss GDP +2.1% │ OpenAI IPO confirmed ◀◀◀    │
└─────────────────────────────────────────────────────┘
```

**Panes & Datenquellen:**

| Pane | Source | Refresh | Difficulty |
|------|--------|---------|------------|
| Tech News | HN API, The Verge RSS, Ars RSS | 300s | ✅ Easy |
| AI News | ArXiv RSS, PH AI, AI News RSS | 300s | ✅ Easy |
| World News | Reuters RSS, 20min RSS | 300s | ✅ Easy |
| Social Feed | Twitter/X API (oder Nitter scrape), Reddit API | 120s | 🔶 Medium |
| Breaking Ticker | Aggregation aller Feeds, scrollend | 60s | 🔶 Medium |

**Besondere Features:**
- Scrollende Headlines am Bottom (Marquee-Style)
- Color-Coding nach Kategorie
- Klick/Select auf Headline → öffnet im Browser (wenn gewünscht)
- AI-Zusammenfassung der Top Stories (via lokales LLM oder API)

### 2.4 Media Dash (Cozy Ambient Moodboard)

> Lean back. Vibe. Let the room breathe.

**ASCII Layout:**
```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                  🎵 Now Playing                     │
│                                                     │
│         ╔══════════════════════╗                     │
│         ║                      ║                     │
│         ║    ██████████████    ║                     │
│         ║    ██ ALBUM ART ██    ║                     │
│         ║    ██████████████    ║                     │
│         ║                      ║                     │
│         ╚══════════════════════╝                     │
│                                                     │
│    Massive Attack — Teardrop                        │
│    Mezzanine (1998)                                 │
│                                                     │
│    ▁▂▃▅▇█▇▅▃▂▁▂▃▅▇█▇▅▃▂▁▂▃▅▇█▇▅▃▂▁ ← cava       │
│    ━━━━━━━━━━━━━━━━━━━●━━━━━━━━━  3:42 / 5:31     │
│                                                     │
├───────────────────────┬─────────────────────────────┤
│  💡 Hue Rooms         │  🎨 Active Scene            │
│                       │                             │
│  Wohnzimmer  ● ████  │  "Tropical Twilight"        │
│  Büro        ● ████  │                             │
│  Schlafzimmer ○ off  │  ████████████████████       │
│  Küche       ● ████  │  (scene color palette)      │
└───────────────────────┴─────────────────────────────┘
```

**Panes & Datenquellen:**

| Pane | Source | Refresh | Difficulty |
|------|--------|---------|------------|
| Now Playing | Spotify API / spotifyd | 5s | 🔶 Medium |
| Album Art | Spotify API → chafa/sixel | 5s (on track change) | 🔶 Medium |
| Waveform/Visualizer | cava (FIFO audio) | Realtime | 🔶 Medium |
| Progress Bar | Spotify API | 1s | ✅ Easy |
| Hue Room Status | Hue Bridge API | 10s | 🔶 Medium |
| Scene Selector | Hue Bridge API | On demand | 🔶 Medium |
| Lyrics | Genius API / lyrics.ovh | On track change | 🔶 Medium |

**Besondere Features:**
- Album Art: Gross dargestellt via `chafa` (Sixel oder Kitty Protocol falls Terminal supported)
- Waveform: `cava` im Pane — braucht Audio-Output auf dem Pi
- Hue-Farben: Jeder Raum zeigt seine aktuelle Farbe als Terminal-Color-Block
- Ambient Mode: Board-Hintergrund ändert sich passend zur Album Art Dominant Color
- Scene Cycling: Automatischer Szenenwechsel alle X Minuten

---

## 3. Input/Control System

### 3.1 Hotkeys (tmux-basiert)

**Implementierung:** tmux keybindings die `aeon board <name>` aufrufen.

```bash
# ~/.tmux.conf
bind -n C-F1 run-shell "aeon board ops"
bind -n C-F2 run-shell "aeon board investor"
bind -n C-F3 run-shell "aeon board news"
bind -n C-F4 run-shell "aeon board media"
bind -n C-F5 run-shell "aeon board cycle"    # Next Board
```

**Difficulty: ✅ Easy** — Paar Zeilen tmux Config. Sofort umsetzbar.

### 3.2 Voice Control

**Architecture:**
```
Mikrofon → Wake Word Detection → Audio Capture → STT → Command Parser → Action
                (always on)        (on wake)     (Whisper)  (simple matching)
```

**Optionen für Wake Word:**

| Lösung | Latenz | Accuracy | Offline | Cost | Difficulty |
|--------|--------|----------|---------|------|------------|
| Porcupine (Picovoice) | <100ms | Sehr gut | ✅ | Free tier | 🔶 Medium |
| OpenWakeWord | <200ms | Gut | ✅ | Free | 🔶 Medium |
| Whisper always-on | N/A | N/A | ✅ | CPU-heavy | ❌ Unrealistisch |

**Empfehlung:** Porcupine für Wake Word ("Hey ÆEON") + Whisper.cpp für Command STT.

**Pi5 Performance für Whisper.cpp:**
- Whisper tiny: ~1s für 5s Audio → ✅ Totally machbar
- Whisper base: ~3s für 5s Audio → ✅ Akzeptabel
- Whisper small: ~8s für 5s Audio → 🔶 Grenzwertig
- Whisper medium/large: ❌ Zu langsam

**Command Set (bewusst klein gehalten):**
```
"ops board" / "show ops" / "monitoring"  → Board: Ops
"investor" / "portfolio" / "markets"     → Board: Investor
"news"                                   → Board: News
"music" / "media" / "cozy"              → Board: Media
"next" / "weiter"                        → Nächstes Board
"lights [scene]"                         → Hue Scene wechseln
"play" / "pause" / "skip"               → Spotify Control
```

**Hardware:** USB-Mikrofon oder ReSpeaker HAT für Pi. Budget: ~$20-40.

**Difficulty: 🔴 Hard** — Wake Word + STT + Command Parsing + Mikrofon-Setup. Aber machbar auf Pi5.

### 3.3 Hardware Remote

#### Option A: Apple TV Remote (Siri Remote Gen 1/2)

**Wie es funktioniert:**
- Apple TV Remote ist ein BLE HID Device
- Kann mit Linux Bluetooth Stack gepairt werden (bluetoothctl)
- Buttons werden als HID Input Events gemappt
- `evtest` / `evdev` zum Auslesen, dann Custom Mapping

**Button Mapping:**
| Button | Event | Aktion |
|--------|-------|--------|
| Menu | KEY_BACK | Previous Board |
| Play/Pause | KEY_PLAYPAUSE | Spotify Play/Pause |
| Up | KEY_UP | Board: Ops |
| Down | KEY_DOWN | Board: Media |
| Left | KEY_LEFT | Board: News |
| Right | KEY_RIGHT | Board: Investor |
| Select (Click) | KEY_ENTER | Cycle sub-view |
| Touch Swipe | Axis Events | Scroll in active Pane |

**Realitäts-Check:** BLE Pairing mit Apple Remote auf Linux ist **tricky aber documented**. Die Gen 1 (Aluminium, ohne Touchpad) ist einfacher zu mappen. Gen 2 (mit Touchpad) hat komplexere Events.

**Difficulty: 🔶 Medium** — BLE Pairing ist der schwierigste Part. Danach ist es simples Event-Mapping.

#### Option B: ESP32 Custom Remote

```
ESP32 + Mikrofon + 4 Buttons + Batterie
        │
        ├── Button 1-4: Board Switch (BLE HID oder MQTT)
        ├── Mikrofon: Wake Word + Command → MQTT/HTTP to Pi
        └── Battery: 18650 LiPo, Wochen Laufzeit
```

**Difficulty: 🔴 Hard** — Custom Hardware, Firmware, 3D-Druck Gehäuse. Aber: Ultimative Kontrolle.

#### Option C: Flic Button

- 1 Button = 1 Action, aber: Single/Double/Hold = 3 Actions
- Flic Hub oder direkt via BLE
- `flicd` Linux Daemon existiert

**Difficulty: ✅ Easy** — Out of the box. Aber limitiert (max 3 Actions pro Button).

#### Option D: Stream Deck Mini (6 Buttons)

- Nativ auf Linux via `streamdeck` Python Library
- Jeder Button kann Icon + Action haben
- 6 Buttons = 4 Boards + Cycle + Special

**Difficulty: ✅ Easy** — Beste out-of-the-box Lösung. ~$80.

#### Option E: Smartphone Web Remote

- Express/Fastify Server auf dem Pi
- Simplestest Web-UI mit grossen Buttons
- QR-Code am TV für Quick Connect
- Progressive Web App für Home Screen

**Difficulty: 🔶 Medium** — Web Server + UI. Aber sehr flexibel.

**Empfehlung Reihenfolge:**
1. 🥇 Hotkeys (sofort, kostenlos)
2. 🥈 Web Remote auf Phone (flexibel, kein Extra-Hardware)
3. 🥉 Stream Deck Mini (premium feel)
4. 🏅 Apple TV Remote (cool factor, aber fiddly)
5. 🎯 ESP32 Custom (Moonshot-Projekt)

---

## 4. Technische Deep-Dives

### 4.1 Spotify Integration

**Stack:**
```
Spotify Account
    │
    ├── spotifyd (Daemon auf Pi, spielt Audio ab)
    │   └── ALSA/PulseAudio → HDMI Audio Out
    │
    ├── Spotify Web API (Metadata, Control)
    │   ├── Now Playing: GET /v1/me/player/currently-playing
    │   ├── Control: PUT /v1/me/player/play|pause|next
    │   └── Album Art URL → chafa für Terminal-Rendering
    │
    └── cava (Audio Visualizer)
        └── Liest von PulseAudio Monitor oder FIFO
```

**spotifyd auf Pi:**
- Rust-basiert, sehr leichtgewichtig
- Pi wird als Spotify Connect Device sichtbar
- Audio über HDMI zum TV
- `cargo install spotifyd` oder Debian Package

**Album Art Rendering:**
```bash
# Download + Render in einem Step
curl -s "$ALBUM_ART_URL" | chafa --size=40x20 --symbols=block -
```

Optionen:
- `chafa`: Breit unterstützt, gute Qualität. ✅ Empfohlen.
- Sixel: Bessere Qualität, braucht Sixel-fähiges Terminal (xterm, foot, mlterm)
- Kitty Protocol: Beste Qualität, nur in Kitty Terminal
- Für Pi + TV: `chafa` mit Unicode Blocks ist der pragmatischste Weg

**Waveform/Visualizer (cava):**
```bash
# cava config für Pane-Integration
[general]
framerate = 30
bars = 40

[output]
method = raw
raw_target = /tmp/cava.fifo
data_format = ascii
ascii_max_range = 8
```

Dann liest die Pane aus dem FIFO und rendert die Bars als Unicode: ▁▂▃▄▅▆▇█

**Difficulty: 🔶 Medium** — spotifyd Setup + API Auth + cava Integration. 1-2 Tage Arbeit.

### 4.2 Philips Hue Integration

**Hue Bridge API:**
```
Bridge Discovery: https://discovery.meethue.com/
Auth: POST /api → Press Bridge Button → Get API Key
Lights: GET /api/<key>/lights
Groups: GET /api/<key>/groups
Scenes: GET /api/<key>/scenes
Set State: PUT /api/<key>/lights/<id>/state
```

**Terminal-Visualisierung:**
```bash
# Farbe als Terminal-Block darstellen
# Hue gibt xy-Farbraum → convert to RGB → ANSI 24-bit color
printf "\e[48;2;${r};${g};${b}m    \e[0m"  # Farbblock
```

Jeder Raum bekommt:
- Name
- On/Off Status (● / ○)
- Aktuelle Farbe als Block (████)
- Helligkeit als Bar

**Scene Control:**
```bash
# Scene aktivieren
curl -X PUT "http://$BRIDGE/api/$KEY/groups/$GROUP/action" \
  -d '{"scene": "$SCENE_ID"}'
```

**Difficulty: 🔶 Medium** — API ist gut dokumentiert. Hauptaufwand: xy→RGB Conversion und saubere Darstellung.

### 4.3 Apple TV Remote BLE

**Pairing Process:**
```bash
bluetoothctl
> scan on
# Apple TV Remote shows as "Apple TV Remote" or similar
> pair XX:XX:XX:XX:XX:XX
> trust XX:XX:XX:XX:XX:XX
> connect XX:XX:XX:XX:XX:XX
```

**Event Reading:**
```bash
# Find input device
ls /dev/input/event*
# Read events
evtest /dev/input/event<N>
# Or via Python evdev:
from evdev import InputDevice, categorize, ecodes
dev = InputDevice('/dev/input/event<N>')
for event in dev.read_loop():
    if event.type == ecodes.EV_KEY:
        print(categorize(event))
```

**Daemon:** Kleiner Python/Node Script der Events liest und `aeon board <X>` aufruft.

**Bekannte Gotchas:**
- BLE Pairing kann Random Disconnects haben → Reconnect-Logic nötig
- Gen 2 Siri Remote: Touchpad Events sind komplexer (ABS_X, ABS_Y)
- Manche Buttons senden IR statt BLE (Home Button) → funktionieren nicht

**Difficulty: 🔶 Medium** — Pairing ist der nervigste Teil. Evdev-Mapping ist straightforward.

### 4.4 Voice Commands (Whisper.cpp + Porcupine)

**Setup:**
```
1. porcupine_demo_mic → Läuft dauerhaft, hört auf "Hey ÆEON"
2. Wake detected → Startet Audio Recording (3-5 Sekunden)
3. Audio → whisper.cpp (tiny model) → Text
4. Text → Simple Command Matcher → Action
5. Action → aeon board <X> / spotify play / hue scene <X>
```

**Whisper.cpp auf Pi5:**
```bash
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp && make -j4
# Download tiny model (75MB)
bash ./models/download-ggml-model.sh tiny
# Test
./main -m models/ggml-tiny.bin -f audio.wav
```

Pi5 hat 4x Cortex-A76 @ 2.4GHz — genug für Whisper tiny in ~1s.

**Porcupine Wake Word:**
```python
import pvporcupine
porcupine = pvporcupine.create(
    access_key='...',
    keyword_paths=['hey-aeon.ppn']  # Custom Wake Word
)
# Custom Wake Word via Picovoice Console trainierbar
```

**Difficulty: 🔴 Hard** — Viele Moving Parts. Aber jede einzelne Komponente ist well-documented.

### 4.5 Album Art im Terminal

**Vergleich:**

| Methode | Qualität | Kompatibilität | Speed |
|---------|----------|----------------|-------|
| chafa (Unicode blocks) | ★★★☆ | Jedes Terminal | Fast |
| chafa (Sixel) | ★★★★ | xterm, foot, mlterm | Fast |
| Kitty Protocol | ★★★★★ | Nur Kitty | Fast |
| ASCII Art (jp2a) | ★★☆☆ | Überall | Fast |
| w3m-img | ★★★★ | X11 terminals | Medium |

**Empfehlung für Pi + TV Setup:**
- Wenn Kitty als Terminal: Kitty Protocol (pixel-perfect)
- Sonst: chafa mit `--symbols=block+border` und grosser Size
- Fallback: ASCII Art ist immer noch cool genug

---

## 5. Pane/Card Katalog

Kompletter Katalog aller denkbaren Panes, gruppiert nach Kategorie.

### 🖥️ System

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `cpu-bars` | CPU Usage per Core als Balken | /proc/stat | ✅ Easy |
| `ram-gauge` | RAM Usage Gauge | /proc/meminfo | ✅ Easy |
| `disk-usage` | Disk Usage pro Mount | df | ✅ Easy |
| `network-traffic` | RX/TX Sparkline | /proc/net/dev | ✅ Easy |
| `cpu-temp` | Temperatur (Pi spezifisch) | vcgencmd | ✅ Easy |
| `top-procs` | Top N Processes | ps / /proc | ✅ Easy |
| `btop-embed` | btop im Pane (subprocess) | btop | ✅ Easy |
| `docker-ps` | Running Containers | docker API | ✅ Easy |
| `systemd-status` | Service Status Overview | systemctl | ✅ Easy |
| `journal-tail` | Live Log Stream | journalctl -f | ✅ Easy |
| `gateway-status` | OpenClaw Gateway | openclaw CLI | ✅ Easy |
| `ssh-sessions` | Active SSH Sessions | who/w | ✅ Easy |
| `tailscale-status` | Tailscale Network Map | tailscale status | ✅ Easy |

### 📈 Market

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `price-chart` | Candlestick/Line Chart | CoinGecko/Yahoo | 🔶 Medium |
| `sparkline` | Mini Preis-Sparkline | CoinGecko | ✅ Easy |
| `ticker` | Preis + 24h Change | Multiple APIs | ✅ Easy |
| `portfolio-total` | Aggregierter Portfoliowert | Config + APIs | 🔶 Medium |
| `portfolio-table` | Holdings-Tabelle mit P&L | Config + APIs | 🔶 Medium |
| `fear-greed` | Fear & Greed Index Gauge | alternative.me | ✅ Easy |
| `top-movers` | Biggest Gainers/Losers | CoinGecko | ✅ Easy |
| `watchlist` | Benutzerdefinierte Asset-Liste | Config + APIs | ✅ Easy |
| `gas-tracker` | Ethereum Gas Prices | Etherscan API | ✅ Easy |
| `market-cap` | Total Crypto Market Cap | CoinGecko | ✅ Easy |

### 📰 News

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `rss-feed` | Generischer RSS Reader | Any RSS | ✅ Easy |
| `hn-top` | Hacker News Top Stories | HN API | ✅ Easy |
| `reddit-feed` | Subreddit Top Posts | Reddit API | 🔶 Medium |
| `twitter-feed` | Twitter/X Mentions/Timeline | X API / Nitter | 🔴 Hard |
| `breaking-ticker` | Scrollende Breaking News | Aggregation | 🔶 Medium |
| `ai-papers` | Latest AI Papers | ArXiv RSS | ✅ Easy |
| `product-hunt` | Trending Products | PH API | ✅ Easy |

### 🎵 Media

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `now-playing` | Track + Artist + Album | Spotify API | 🔶 Medium |
| `album-art` | Cover Art im Terminal | Spotify → chafa | 🔶 Medium |
| `waveform` | Audio Visualizer | cava | 🔶 Medium |
| `progress-bar` | Playback Progress | Spotify API | ✅ Easy |
| `playlist` | Current Playlist | Spotify API | 🔶 Medium |
| `volume-control` | Volume Slider | Spotify/ALSA | ✅ Easy |
| `lyrics` | Song Lyrics (scrollend) | Genius API | 🔶 Medium |
| `recent-tracks` | Recently Played | Spotify API | ✅ Easy |

### 💡 Smart Home

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `hue-rooms` | Raum-Übersicht mit Farben | Hue Bridge API | 🔶 Medium |
| `hue-scene-picker` | Scene Selector | Hue Bridge API | 🔶 Medium |
| `hue-single-light` | Einzelne Lampe Detail | Hue Bridge API | 🔶 Medium |
| `temp-sensors` | Temperatur-Sensoren | Hue / HomeAssistant | 🔶 Medium |
| `motion-log` | Motion Sensor Events | Hue Bridge API | 🔶 Medium |

### 📋 Productivity

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `calendar` | Upcoming Events | CalDAV / Google Cal | 🔶 Medium |
| `todo-list` | Task List | Todoist API / Local | ✅ Easy |
| `pomodoro` | Pomodoro Timer | Local | ✅ Easy |
| `focus-timer` | Deep Work Timer | Local | ✅ Easy |
| `world-clock` | Mehrere Zeitzonen | System | ✅ Easy |
| `countdown` | Countdown zu Event | Config | ✅ Easy |

### 🎮 Fun / Ambient

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `big-clock` | Grosse ASCII Uhr | System | ✅ Easy |
| `matrix-rain` | Matrix-Style Animation | Local | ✅ Easy |
| `ascii-art` | Rotating ASCII Art | Local/API | ✅ Easy |
| `game-of-life` | Conway's Game of Life | Local | ✅ Easy |
| `weather` | Wetter mit ASCII Art | wttr.in | ✅ Easy |
| `quote-of-day` | Inspirational Quote | API | ✅ Easy |
| `pipes` | Pipes.sh Style Animation | Local | ✅ Easy |

### 🔧 Meta

| Pane | Beschreibung | Source | Difficulty |
|------|-------------|--------|------------|
| `board-switcher` | Board-Auswahl Overlay | Internal | ✅ Easy |
| `remote-status` | Connected Remotes/Inputs | Internal | ✅ Easy |
| `voice-log` | Voice Command History | Internal | ✅ Easy |
| `session-info` | Uptime, Board, FPS | Internal | ✅ Easy |
| `qr-remote` | QR Code für Web Remote | Internal | ✅ Easy |

---

## 6. Roadmap

### Phase 1: Foundation (jetzt → 2 Wochen)
> *Was wir (fast) schon haben — polieren und formalisieren.*

- [ ] Pane-Abstraction Layer definieren (Interface/Protocol)
- [ ] Board Config Schema (YAML) finalisieren
- [ ] Grid Layout Engine (responsive, tmux-basiert)
- [ ] `aeon board <name>` CLI Command
- [ ] Ops Board mit 6-8 Panes
- [ ] Investor Cockpit mit Charts + Portfolio
- [ ] Hotkey Board-Switching (tmux keybindings)

**Komponenten:** Node.js/Bash, tmux, bestehender ÆEON CLI Code
**Effort:** ~40h

### Phase 2: News + Polish (Woche 3-4)
> *Content-Boards und bessere UX.*

- [ ] News Board (RSS, HN, AI Papers)
- [ ] Breaking News Ticker (scrollend)
- [ ] Pane Refresh Engine (individuell pro Pane)
- [ ] Error Handling + Graceful Degradation
- [ ] Board Transition Animations (optional: Fade/Slide)
- [ ] `aeon board list` / `aeon board edit`

**Komponenten:** RSS Parser, News APIs
**Effort:** ~30h

### Phase 3: Media Dash (Woche 5-8)
> *Das "Wow"-Board. Spotify + Hue + Ambient.*

- [ ] spotifyd auf Pi einrichten
- [ ] Spotify API Integration (Now Playing, Control)
- [ ] Album Art Rendering (chafa)
- [ ] cava Visualizer Integration
- [ ] Hue Bridge Discovery + Auth
- [ ] Hue Room Status Pane
- [ ] Hue Scene Switcher
- [ ] Ambient Color Mode (Board-Farben aus Album Art)

**Komponenten:** spotifyd, cava, chafa, Hue Bridge
**Effort:** ~60h

### Phase 4: Voice + Remote (Woche 9-12)
> *Hands-free Control. The future is now.*

- [ ] Porcupine Wake Word Setup ("Hey ÆEON")
- [ ] Whisper.cpp STT auf Pi5
- [ ] Command Parser + Action Mapping
- [ ] USB Mic / ReSpeaker HAT einrichten
- [ ] Apple TV Remote BLE Pairing
- [ ] Remote Event → Board Switch Daemon
- [ ] Feedback: Audio Confirmation oder Visual Flash

**Komponenten:** Porcupine SDK, Whisper.cpp, BLE Stack, Mikrofon
**Effort:** ~80h

### Phase 5: Web Remote + Custom Boards (Woche 13-16)
> *Demokratisierung. Jeder kann Boards bauen.*

- [ ] Web Remote Server (Express/Fastify auf Pi)
- [ ] Web UI: Board Buttons, Pane Preview, Spotify Control
- [ ] QR Code am TV für Quick-Connect
- [ ] PWA Support (Home Screen auf Phone)
- [ ] Custom Board Builder (YAML + Live Preview)
- [ ] Board Sharing (Export/Import)
- [ ] Documentation + Examples

**Komponenten:** Web Framework, Simple Frontend (Preact/Vanilla)
**Effort:** ~60h

---

## 7. Crazy Ideas / Moonshots

### 🎬 AirPlay Receiver auf dem Pi
> Dashboard als Apple TV Replacement.

Der Pi wird zum AirPlay Target. Wenn jemand vom iPhone castet, pausiert das Dashboard und zeigt den AirPlay Stream. Danach: zurück zum Board.

- Tool: `uxplay` (Open Source AirPlay Server)
- Pi5 hat genug Power für AirPlay 1 (Audio + Video Mirroring)
- AirPlay 2 (Multi-Room Audio) ist komplexer aber möglich

**Difficulty: 🔶 Medium** | **Cool Factor: 🔥🔥🔥🔥**

### 🗣️ Siri Shortcuts Integration
> "Hey Siri, switch to investor board"

Siri Shortcut → HTTP Request an Pi Web Server → Board Switch. Funktioniert über das Web Remote Backend.

**Difficulty: ✅ Easy** (wenn Web Remote steht) | **Cool Factor: 🔥🔥🔥**

### 🏠 Home Assistant Integration
> Zwei-Wege: Dashboard zeigt HA Daten, HA steuert Dashboard.

- HA Sensoren als Pane-Datenquellen (Temp, Humidity, Strom, etc.)
- HA Automations können Boards wechseln (z.B. "Guten Morgen" → News Board)
- MQTT als gemeinsamer Bus

**Difficulty: 🔶 Medium** | **Cool Factor: 🔥🔥🔥🔥**

### 😴 Smart Screensaver Mode
> Dashboard dimmt bei Inaktivität. Wacht auf bei Bewegung.

```
Inaktiv 5min → Board wechselt zu "Ambient Clock" (grosse Uhr, dunkle Farben)
Inaktiv 15min → Screen dimmt (HDMI CEC → TV Standby)
PIR Sensor detected → HDMI CEC → TV On → Letztes Board
```

Hardware: PIR Sensor am GPIO ($3), HDMI CEC via `cec-utils`.

**Difficulty: 🔶 Medium** | **Cool Factor: 🔥🔥🔥🔥🔥**

### 🔄 Multi-Pi Sync
> Alle Pis im Haus wechseln gleichzeitig das Board.

MQTT Pub/Sub: Ein Pi ist Master, sendet Board-Change Events. Alle Slaves folgen.

```
Pi-Wohnzimmer (Master) → MQTT "aeon/board/switch" → "investor"
Pi-Büro (Slave) → Empfängt → Wechselt zu Investor
Pi-Küche (Slave) → Empfängt → Wechselt zu Investor
```

Oder: Jeder Pi kann Master sein (last-write-wins).

**Difficulty: ✅ Easy** (mit MQTT) | **Cool Factor: 🔥🔥🔥**

### 🎨 Generative Ambient Art
> Lokales Stable Diffusion generiert Hintergrundbilder passend zum Board/Mood.

Pi5 mit 8GB RAM kann Stable Diffusion (mit Optimierungen) in ~30-60s pro Bild. Nicht realtime, aber: alle paar Minuten ein neues Ambient-Bild generieren.

- SD.cpp oder stable-diffusion.cpp für ARM
- Tiny Models (SD Turbo, LCM) für schnellere Inferenz
- Prompt basierend auf Board-Thema oder aktueller Musik

**Difficulty: 🔴 Hard** | **Cool Factor: 🔥🔥🔥🔥🔥** | **Realistisch: Eher Pi5 mit USB AI Accelerator**

### 🔊 Ambient Sound Design
> Jedes Board hat seinen eigenen Soundtrack.

| Board | Sound |
|-------|-------|
| Ops | Subtle cyberpunk ambient, soft synth pads |
| Investor | Lo-fi beats, trading floor ambience |
| News | Newsroom typing, muffled TV news |
| Media | (eigene Musik — Spotify!) |

Implementation: `mpv` oder `ffplay` im Hintergrund, Crossfade beim Board-Switch.

**Difficulty: ✅ Easy** | **Cool Factor: 🔥🔥🔥**

### 💡 LED Strip Ambilight
> WS2812B LED Strip am TV-Rahmen, Farben passend zum Board/Content.

```
Pi GPIO → WS2812B Strip (rPi_ws281x Library)
Board Switch → LED Color Theme
Media Board → Album Art Dominant Colors
Ops Board → Grün (healthy) / Rot (alerts)
```

- ~$15 für LED Strip + Level Shifter
- `rpi_ws281x` Python Library
- Oder: WLED auf ESP32 (WiFi-controlled, MQTT)

**Difficulty: 🔶 Medium** | **Cool Factor: 🔥🔥🔥🔥🔥**

### 📱 Dashboard als iOS Widget
> Glanceable Dashboard-Info auf dem iPhone Lock Screen.

Kleiner Server liefert Daten → iOS Scriptable Widget zeigt Portfolio/Status.

**Difficulty: 🔶 Medium** | **Cool Factor: 🔥🔥🔥**

### 🎙️ ÆEON Voice Persona
> Dashboard antwortet mit Stimme. TTS Feedback für Commands.

"Hey ÆEON, wie steht Bitcoin?"
→ "Bitcoin steht bei 94'500 Franken, plus 4.2 Prozent in den letzten 24 Stunden."

- Piper TTS (lokal, schnell, offline) oder ElevenLabs API
- Pi5 kann Piper in Realtime

**Difficulty: 🔶 Medium** | **Cool Factor: 🔥🔥🔥🔥🔥**

---

## Zusammenfassung

### Was macht dieses System besonders?

1. **Terminal-Native** — Kein Electron, kein Browser, kein Overhead. Pure Terminal Performance.
2. **Modular** — Panes sind Lego-Steine. Jeder kann seine eigenen Boards zusammenstellen.
3. **Pi-First** — Designed für Raspberry Pi + TV. Minimale Hardware, maximaler Impact.
4. **Multi-Modal Input** — Hotkeys, Voice, Remote, Web — was gerade griffbereit ist.
5. **Ambient Computing** — Das Dashboard ist kein Tool das man öffnet. Es ist einfach *da*.

### Quick Wins (diese Woche machbar)
- [x] Board YAML Schema definieren
- [x] `aeon board` CLI Subcommand
- [x] Ops Board + Investor Cockpit (existieren fast schon)
- [x] tmux Hotkey Bindings

### Das ist die Vision.
> Ein Netzwerk aus Raspberry Pis, jeder mit einem TV, jeder ein Fenster in eine andere Welt. Ops. Markets. News. Music. Alles im Terminal. Alles modular. Alles unter deiner Kontrolle — per Tastatur, Stimme, oder einem kleinen Remote der auf dem Couchtisch liegt.

*Let's build this.* 🚀

---

*Dieses Dokument ist lebendig. Es wächst mit dem Projekt.*
*Last updated: 2026-02-12 by ÆEON*
