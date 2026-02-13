#!/usr/bin/env bash
# ÆON-specific panel: Agent Status
C="\e[36m"; W="\e[97m"; M="\e[35m"; G="\e[32m"; Y="\e[33m"
B="\e[1m"; D="\e[2m"; N="\e[0m"

echo -e "${B}${W}ÆON STATUS${N}"
echo ""
echo -e " ${G}●${N} Status: ${G}operational${N}"
echo -e " ${D}Agent:${N} ${W}aeon${N}"
echo -e " ${D}Identity:${N} ${C}ÆON${N}"
echo -e " ${D}Version:${N} ${W}$(cat "${RCLI_ROOT:-/tmp/cli}/lib/main.sh" 2>/dev/null | grep 'RCLI_VERSION=' | head -1 | cut -d'"' -f2)${N}"
