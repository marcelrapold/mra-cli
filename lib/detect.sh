#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ÆON CLI — Resolution & Hardware Detection
# Auto-detects display resolution, terminal size, and hardware capabilities
# ═══════════════════════════════════════════════════════════════════════════════

# Resolution profile thresholds (based on terminal columns)
# SD:  ≤100 cols  (640x480 @ typical font)
# HD:  101-159    (1280x720)
# FHD: 160-212    (1920x1080)
# QHD: 213-299    (2560x1440)
# UHD: 300+       (3840x2160)

detect_profile() {
    if [ -n "${RCLI_PROFILE:-}" ]; then
        log_debug "Profile override: $RCLI_PROFILE"
        return
    fi
    
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    
    if [ "$cols" -ge 300 ]; then
        export RCLI_PROFILE="uhd"
    elif [ "$cols" -ge 213 ]; then
        export RCLI_PROFILE="qhd"
    elif [ "$cols" -ge 160 ]; then
        export RCLI_PROFILE="fhd"
    elif [ "$cols" -ge 101 ]; then
        export RCLI_PROFILE="hd"
    else
        export RCLI_PROFILE="sd"
    fi
    
    log_debug "Detected profile: ${RCLI_PROFILE} (${cols} cols)"
}

# ── Hardware Detection ──
detect_hardware() {
    local hw="unknown"
    
    if [ -f /proc/device-tree/model ]; then
        hw=$(tr -d '\0' < /proc/device-tree/model)
    elif [ -f /proc/cpuinfo ]; then
        hw=$(grep -m1 "Model" /proc/cpuinfo | cut -d: -f2 | xargs)
    fi
    
    echo "$hw"
}

detect_pi_model() {
    local model
    model=$(detect_hardware)
    
    case "$model" in
        *"Pi 5"*)   echo "pi5" ;;
        *"Pi 4"*)   echo "pi4" ;;
        *"Pi 3"*)   echo "pi3" ;;
        *"Pi Zero"*) echo "pizero" ;;
        *)          echo "generic" ;;
    esac
}

# ── Display Detection ──
detect_resolution() {
    # Try multiple methods to detect actual screen resolution
    local res=""
    
    # Method 1: xrandr
    if command -v xrandr &>/dev/null; then
        res=$(xrandr 2>/dev/null | grep '\*' | head -1 | awk '{print $1}')
    fi
    
    # Method 2: fbset (framebuffer)
    if [ -z "$res" ] && command -v fbset &>/dev/null; then
        res=$(fbset 2>/dev/null | grep "geometry" | awk '{print $2"x"$3}')
    fi
    
    # Method 3: /sys/class/graphics
    if [ -z "$res" ] && [ -f /sys/class/graphics/fb0/virtual_size ]; then
        res=$(cat /sys/class/graphics/fb0/virtual_size | tr ',' 'x')
    fi
    
    # Method 4: tvservice (Raspberry Pi specific)
    if [ -z "$res" ] && command -v tvservice &>/dev/null; then
        res=$(tvservice -s 2>/dev/null | grep -oP '\d+x\d+')
    fi
    
    echo "${res:-unknown}"
}

# ── Profile Info ──
profile_info() {
    local profile="${1:-$RCLI_PROFILE}"
    case "$profile" in
        sd)  echo "SD (640×480) — Minimal layout, single column" ;;
        hd)  echo "HD (1280×720) — Compact two-column layout" ;;
        fhd) echo "FHD (1920×1080) — Standard three-zone layout" ;;
        qhd) echo "QHD (2560×1440) — Extended layout with extra panels" ;;
        uhd) echo "UHD/4K (3840×2160) — Full layout with all panels" ;;
        *)   echo "Unknown profile: $profile" ;;
    esac
}

# ── Capability Check ──
has_figlet()  { command -v figlet &>/dev/null; }
has_tmux()    { command -v tmux &>/dev/null; }
has_btop()    { command -v btop &>/dev/null; }
has_python3() { command -v python3 &>/dev/null; }
has_ssh()     { command -v ssh &>/dev/null; }
has_mpg123()  { command -v mpg123 &>/dev/null; }
