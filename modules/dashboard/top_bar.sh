#!/usr/bin/env bash
# ÆON COMMAND — Top bar: Matrix rain behind centered figlet
# Ported from Pi reference scripts into modular structure
C="\e[36m"; W="\e[97m"; M="\e[35m"; Y="\e[33m"; G="\e[32m"
B="\e[1m"; D="\e[2m"; N="\e[0m"

COLS=$(tput cols 2>/dev/null || echo 160)

F=$(($(date +%s) % 3))
case $F in 0) P="${C}" ;; 1) P="${W}" ;; 2) P="${M}" ;; esac

HOST=$(hostname | tr '[:lower:]' '[:upper:]')
TIME=$(date '+%H:%M:%S')
DAY=$(date '+%a %d %b %Y')

# Figlet header
FIGLET=$(figlet -w "$COLS" -f block "${AGENT_ID^^} COMMAND" 2>/dev/null \
      || figlet -f slant "${AGENT_ID^^} COMMAND" 2>/dev/null \
      || echo "  ÆON COMMAND")
readarray -t FLINES <<< "$FIGLET"
MAXW=0; for line in "${FLINES[@]}"; do [ ${#line} -gt $MAXW ] && MAXW=${#line}; done
PAD=$(( (COLS - MAXW) / 2 )); [ $PAD -lt 0 ] && PAD=0
FROWS=${#FLINES[@]}
ROWS=$((FROWS + 6))

# Composite matrix rain + figlet via python
echo ""
python3 - "$COLS" "$ROWS" "$PAD" "$MAXW" "$(date +%s)" "$FROWS" "${FLINES[@]}" << 'PYEOF'
import sys
args = sys.argv[1:]
COLS = int(args[0]); ROWS = int(args[1]); PAD = int(args[2]); MAXW = int(args[3])
SEED = int(args[4]); FROWS = int(args[5])
FLINES = args[6:]
FROW_OFFSET = (ROWS - len(FLINES)) // 2

KANA = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
KANA += "ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ"

DG = "\033[38;5;236m"; MG = "\033[38;5;240m"; LG = "\033[38;5;244m"
BG = "\033[38;5;248m"; N = "\033[0m"; B = "\033[1m"

for r in range(ROWS):
    fr = r - FROW_OFFSET
    fl = FLINES[fr] if 0 <= fr < len(FLINES) else ""
    line = ""
    for col in range(COLS):
        fpos = col - PAD
        if 0 <= fpos < len(fl) and fl[fpos] != ' ':
            line += B + "\033[36m" + fl[fpos] + N
        else:
            h = (col * 2654435761 + SEED * 17) & 0xFFFFFFFF
            drop_speed = 1 + (h % 3)
            drop_phase = (h >> 4) % (ROWS + 6)
            drop_pos = (SEED * drop_speed + drop_phase) % (ROWS + 6)
            if (h % 5) < 2:
                line += " "; continue
            dist = r - (drop_pos % (ROWS + 3))
            idx = (h + r * 7 + SEED) % len(KANA)
            ch = KANA[idx]
            if dist == 0: line += BG + ch + N
            elif dist == 1: line += LG + ch + N
            elif 2 <= dist <= 3: line += MG + ch + N
            elif 4 <= dist <= 5: line += DG + ch + N
            else: line += " "
    print(line)
PYEOF

# Scanner line
SW=$((COLS - 4))
SP=$(($(date +%s) % SW))
SCAN=""
for i in $(seq 0 $((SW-1))); do
  if [ $i -eq $SP ]; then SCAN="${SCAN}${W}◆${N}"
  elif [ $((i-SP)) -eq 1 ] || [ $((SP-i)) -eq 1 ]; then SCAN="${SCAN}${C}◇${N}"
  else SCAN="${SCAN}${D}${C}─${N}"; fi
done
printf " ${C}┌${N}${SCAN}${C}┐${N}\n"

# Status line
STATUS="${W}${HOST}${N} ${D}│${N} ${G}● ONLINE${N} ${D}│${N} ${Y}${TIME} ${DAY}${N}"
printf " ${C}│${N}%*s${STATUS}%*s${C}│${N}\n" $(( (COLS - 60) / 2 )) "" $(( (COLS - 60) / 2 )) ""
