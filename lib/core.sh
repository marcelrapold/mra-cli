#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ÆON CLI — Core Utilities
# Colors, logging, formatting, common helpers
# ═══════════════════════════════════════════════════════════════════════════════

# ── ANSI Colors ──
C="\e[36m"      # Cyan (primary)
W="\e[97m"      # White (bright)
M="\e[35m"      # Magenta
Y="\e[33m"      # Yellow
G="\e[32m"      # Green
R="\e[31m"      # Red
B="\e[1m"       # Bold
D="\e[2m"       # Dim
N="\e[0m"       # Reset
export C W M Y G R B D N

# Extended palette
CYAN_BG="\e[46m"
RED_BG="\e[41m"
GREEN_BG="\e[42m"

# ── Logging ──
log_info()    { echo -e "${C}[$(agent_display_name 2>/dev/null || echo RCLI)]${N} $*"; }
log_success() { echo -e "${G}[$(agent_display_name 2>/dev/null || echo RCLI)]${N} $*"; }
log_warn()    { echo -e "${Y}[$(agent_display_name 2>/dev/null || echo RCLI)]${N} $*" >&2; }
log_error()   { echo -e "${R}[$(agent_display_name 2>/dev/null || echo RCLI)]${N} $*" >&2; }
log_debug()   { [[ "${RCLI_DEBUG:-0}" == "1" ]] && echo -e "${D}[$(agent_display_name 2>/dev/null || echo RCLI)]${N} $*" >&2; }

# ── Terminal Helpers ──
term_cols() { tput cols 2>/dev/null || echo 80; }
term_rows() { tput lines 2>/dev/null || echo 24; }

# ── String Helpers ──
# Visual length (strips ANSI escape codes)
vlen() {
    local stripped
    stripped=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
    echo ${#stripped}
}

# Pad string to width
pad() {
    local str="$1" width="$2"
    local vl
    vl=$(vlen "$str")
    local diff=$((width - vl))
    if [ $diff -gt 0 ]; then
        printf "%s%*s" "$str" "$diff" ""
    else
        echo -n "$str"
    fi
}

# Center text within width
center() {
    local str="$1" width="$2"
    local vl
    vl=$(vlen "$str")
    local lpad=$(( (width - vl) / 2 ))
    [ $lpad -lt 0 ] && lpad=0
    printf "%*s%s" "$lpad" "" "$str"
}

# ── Box Drawing ──
# Unicode box characters
BOX_TL="┌" BOX_TR="┐" BOX_BL="└" BOX_BR="┘"
BOX_HZ="─" BOX_VT="│"
BOX_LT="├" BOX_RT="┤" BOX_TT="┬" BOX_BT="┴" BOX_CR="┼"

# Draw a box line with content
box_line() {
    local content="$1" width="${2:-$(( $(term_cols) - 4 ))}"
    echo -e " ${C}${BOX_VT}${N}$(pad "$content" "$width")${C}${BOX_VT}${N}"
}

box_top() {
    local width="${1:-$(( $(term_cols) - 4 ))}"
    echo -e " ${C}${BOX_TL}$(printf '%*s' "$width" '' | tr ' ' "$BOX_HZ")${BOX_TR}${N}"
}

box_bottom() {
    local width="${1:-$(( $(term_cols) - 4 ))}"
    echo -e " ${C}${BOX_BL}$(printf '%*s' "$width" '' | tr ' ' "$BOX_HZ")${BOX_BR}${N}"
}

box_separator() {
    local width="${1:-$(( $(term_cols) - 4 ))}"
    echo -e " ${C}${BOX_LT}$(printf '%*s' "$width" '' | tr ' ' "$BOX_HZ")${BOX_RT}${N}"
}

# ── Dependency Check ──
require_cmd() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: ${W}$cmd${N}"
        log_error "Install with: ${C}sudo apt install $pkg${N}"
        return 1
    fi
}

# ── Cached Fetch ──
# fetch_cached <url> <cache_file> <ttl_seconds>
fetch_cached() {
    local url="$1" cache="$2" ttl="$3"
    local age=999
    
    mkdir -p "$(dirname "$cache")"
    [ -f "$cache" ] && age=$(( $(date +%s) - $(stat -c %Y "$cache") ))
    
    if [ $age -gt "$ttl" ]; then
        local data
        data=$(curl -sf --max-time 8 "$url" 2>/dev/null)
        [ -n "$data" ] && echo "$data" > "$cache"
    fi
}

# ── Spinner ──
spinner() {
    local pid="$1" msg="${2:-Working...}"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${C}${frames[$i]}${N} %s" "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.1
    done
    printf "\r${G}✓${N} %s\n" "$msg"
}

# ── Version Compare ──
version_gte() {
    printf '%s\n%s' "$2" "$1" | sort -V -C
}
