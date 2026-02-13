#!/usr/bin/env bash
# Shared panel: Weather (Zurich)
C="\e[36m"; W="\e[97m"; G="\e[32m"; D="\e[2m"; B="\e[1m"; N="\e[0m"
CACHE_DIR="/tmp/aeon_markets"
mkdir -p "$CACHE_DIR"
WCACHE="$CACHE_DIR/weather.json"

AGE=999
[ -f "$WCACHE" ] && AGE=$(( $(date +%s) - $(stat -c %Y "$WCACHE") ))
if [ $AGE -gt 600 ]; then
    curl -sf --max-time 8 "https://api.open-meteo.com/v1/forecast?latitude=47.3769&longitude=8.5417&current=temperature_2m,weathercode,windspeed_10m,relative_humidity_2m&hourly=temperature_2m,weathercode&forecast_hours=12&timezone=Europe/Zurich" > "$WCACHE" 2>/dev/null
fi

python3 -c "
import json
WMO={0:'Clear',1:'Mostly Clear',2:'Partly Cloudy',3:'Overcast',45:'Fog',61:'Lt Rain',63:'Rain',65:'Hvy Rain',71:'Lt Snow',73:'Snow',80:'Showers',95:'Thunder'}
try:
    with open('$WCACHE') as f: wx=json.load(f)
    cur=wx['current']; t=cur.get('temperature_2m','?'); co=cur.get('weathercode',0)
    wi=cur.get('windspeed_10m','?'); hu=cur.get('relative_humidity_2m','?')
    print(f'\033[1m\033[97mZURICH\033[0m')
    print(f'\033[1m\033[97m{t}°C\033[0m \033[2m{WMO.get(co,\"Code \"+str(co))}\033[0m')
    print(f'\033[2mWind\033[0m \033[97m{wi} km/h\033[0m')
    print(f'\033[2mHumidity\033[0m \033[97m{hu}%\033[0m')
except: print('\033[2mNo weather data\033[0m')
" 2>/dev/null
