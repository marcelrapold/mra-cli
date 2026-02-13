#!/usr/bin/env bash
# ÆON COMMAND — Status panel: Local system status (fallback when no gateway)
C="\e[36m"; W="\e[97m"; M="\e[35m"; Y="\e[33m"; G="\e[32m"; R="\e[31m"
B="\e[1m"; D="\e[2m"; N="\e[0m"

COLS=$(tput cols 2>/dev/null || echo 30)
BOX_W=$((COLS - 3))

box_top()    { echo -e " ${C}┌$(printf '%*s' "$BOX_W" '' | tr ' ' '─')┐${N}"; }
box_bottom() { echo -e " ${C}└$(printf '%*s' "$BOX_W" '' | tr ' ' '─')┘${N}"; }
box_line() {
    local content="$1"
    local stripped
    stripped=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$((BOX_W - ${#stripped}))
    [ $pad -lt 0 ] && pad=0
    printf " ${C}│${N}%b%*s${C}│${N}\n" "$content" "$pad" ""
}

# ── System Info ──
HOST=$(hostname)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "?")
CPU=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "?")
MEM_TOTAL=$(free -h 2>/dev/null | awk '/Mem:/{print $2}' || echo "?")
MEM_USED=$(free -h 2>/dev/null | awk '/Mem:/{print $3}' || echo "?")
DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $5}' || echo "?")
LOAD=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo "?")
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "?")

box_top
box_line " ${B}${W}SYSTEM STATUS${N}"
box_line " ${D}Host${N}    ${W}${HOST}${N}"
box_line " ${D}Uptime${N}  ${G}${UPTIME}${N}"
box_line " ${D}CPU${N}     ${W}${CPU} cores${N}"
box_line " ${D}Memory${N}  ${W}${MEM_USED} / ${MEM_TOTAL}${N}"
box_line " ${D}Disk${N}    ${W}${DISK}${N}"
box_line " ${D}Load${N}    ${W}${LOAD}${N}"
box_line " ${D}IP${N}      ${C}${IP}${N}"
box_line ""

# ── Services ──
box_line " ${B}${W}SERVICES${N}"
for svc in ssh tailscaled docker openclaw; do
    if systemctl is-active "$svc" &>/dev/null; then
        box_line " ${G}●${N} ${svc}"
    elif systemctl is-enabled "$svc" &>/dev/null; then
        box_line " ${Y}●${N} ${svc} ${D}(stopped)${N}"
    fi
done
box_bottom
