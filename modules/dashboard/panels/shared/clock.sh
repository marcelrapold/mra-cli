#!/usr/bin/env bash
# Shared panel: World Clock
C="\e[36m"; W="\e[97m"; G="\e[32m"; R="\e[31m"
B="\e[1m"; D="\e[2m"; N="\e[0m"

echo -e "${B}${W}WORLD CLOCK${N}"
python3 -c "
from datetime import datetime
try:
    import zoneinfo
except ImportError:
    try:
        from backports import zoneinfo
    except:
        zoneinfo = None

if zoneinfo:
    for lab, tzn in [('ZH','Europe/Zurich'),('NYC','America/New_York'),('TYO','Asia/Tokyo'),('SYD','Australia/Sydney'),('LON','Europe/London')]:
        try:
            tz = zoneinfo.ZoneInfo(tzn)
            now = datetime.now(tz)
            ts = now.strftime('%H:%M')
            h = now.hour
            dow = now.weekday()
            if dow < 5 and 9 <= h < 17:
                mkt = '\033[32mOPEN\033[0m'
            elif dow >= 5:
                mkt = '\033[31mWE\033[0m'
            else:
                mkt = '\033[2mclosed\033[0m'
            print(f' \033[36m{lab:>3}\033[0m \033[1m\033[97m{ts}\033[0m {mkt}')
        except:
            print(f' {lab:>3} ??:??')
" 2>/dev/null
