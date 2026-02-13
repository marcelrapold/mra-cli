#!/usr/bin/env bash
# ÆON COMMAND — Right panel: Markets, News, Weather, KPIs
# Ported from aeon_right_panel_v4.sh into modular structure
C="\e[36m"; W="\e[97m"; M="\e[35m"; Y="\e[33m"; G="\e[32m"; R="\e[31m"
B="\e[1m"; D="\e[2m"; N="\e[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="/tmp/aeon_markets"
mkdir -p "$CACHE_DIR"
CYCLE=$(( ($(date +%s) / 20) % 3 ))
COLS=$(tput cols 2>/dev/null || echo 55)

# ── Cached fetch helper ──
fetch_cached() {
  local URL="$1" CACHE="$2" TTL="$3" AGE=999
  [ -f "$CACHE" ] && AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
  if [ $AGE -gt "$TTL" ]; then
    local D
    D=$(curl -sf --max-time 8 "$URL" 2>/dev/null)
    [ -n "$D" ] && echo "$D" > "$CACHE"
  fi
}

# ── Fetch market data ──
fetch_cached "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd,chf&include_24hr_change=true" "$CACHE_DIR/prices.json" 120
fetch_cached "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=7" "$CACHE_DIR/btc_chart.json" 600
fetch_cached "https://api.coingecko.com/api/v3/coins/ethereum/market_chart?vs_currency=usd&days=7" "$CACHE_DIR/eth_chart.json" 600
fetch_cached "https://api.coingecko.com/api/v3/coins/tether-gold/market_chart?vs_currency=usd&days=7" "$CACHE_DIR/gold_chart.json" 600
fetch_cached "https://watcher.guru/news/feed" "$CACHE_DIR/news.xml" 300
fetch_cached "https://partner-feeds.20min.ch/rss/20minuten" "$CACHE_DIR/news_20min.xml" 300

# ── Render via Python ──
python3 - "$CACHE_DIR" "$CYCLE" "$COLS" << 'PYEOF'
import json, os, sys, subprocess as sp, re, xml.etree.ElementTree as ET

CACHE_DIR=sys.argv[1]; CYCLE=int(sys.argv[2]); COLS=int(sys.argv[3])

C="\033[36m"; W="\033[97m"; M="\033[35m"; Y="\033[33m"; G="\033[32m"; R="\033[31m"
B="\033[1m"; D="\033[2m"; N="\033[0m"

BOX_W=COLS-3
CHART_W=BOX_W-13
CHART_H=8

def vlen(s): return len(re.sub(r'\033\[[0-9;]*m', '', s))
def pad(s, w):
    d = w - vlen(s)
    return s + " " * d if d > 0 else s
def box_line(content, w=BOX_W):
    return f" {C}│{N}{pad(content, w)}{C}│{N}"
def load_json(p):
    try:
        with open(p) as f: return json.load(f)
    except: return None

def line_chart(prices, w=CHART_W, h=CHART_H, color=C):
    if not prices or len(prices)<2: return ["  No data"]
    step=max(1,len(prices)//w); s=[prices[i] for i in range(0,len(prices),step)][:w]
    mn,mx=min(s),max(s); rng=mx-mn if mx!=mn else 1
    grid=[[" "]*len(s) for _ in range(h)]
    prev_row=None
    for col,val in enumerate(s):
        row=h-1-int((val-mn)/rng*(h-1)); row=max(0,min(h-1,row))
        grid[row][col]="●"
        if prev_row is not None:
            lo,hi=min(row,prev_row)+1,max(row,prev_row)
            for r in range(lo,hi): grid[r][col]="│"
        prev_row=row
    lines=[]
    for row in range(h):
        if row==0: lbl=f"${mx:>8,.0f}"
        elif row==h-1: lbl=f"${mn:>8,.0f}"
        elif row==h//2: lbl=f"${(mx+mn)/2:>8,.0f}"
        else: lbl=" "*9
        lines.append(f"{D}{lbl}{N} {color}{''.join(grid[row])}{N}")
    return lines

def sparkline(prices, w=20):
    bars="▁▂▃▄▅▆▇█"
    if not prices: return "─"*w
    step=max(1,len(prices)//w); s=[prices[i] for i in range(0,len(prices),step)][:w]
    mn,mx=min(s),max(s); rng=mx-mn if mx!=mn else 1
    return "".join(bars[min(7,int((v-mn)/rng*7))] for v in s)

prices=load_json(f"{CACHE_DIR}/prices.json") or {}
hists=[load_json(f"{CACHE_DIR}/btc_chart.json"), load_json(f"{CACHE_DIR}/gold_chart.json"), load_json(f"{CACHE_DIR}/eth_chart.json")]
cfgs=[{"name":"₿ BTC","color":C,"key":"bitcoin"}, {"name":"◈ GOLD","color":Y,"key":""}, {"name":"Ξ ETH","color":M,"key":"ethereum"}]
cfg=cfgs[CYCLE]; hist=hists[CYCLE]
hp=[p[1] for p in hist.get("prices",[])] if hist else []
dots=" ".join(f"{W}●{N}" if i==CYCLE else f"{D}○{N}" for i in range(3))

# ── CHART BOX ──
print(f" {C}┌{'─'*BOX_W}┐{N}")
print(box_line(f" {B}{W}{cfg['name']}{N} 7D {dots}"))
for ln in line_chart(hp):
    cl=vlen(ln); lpad=(BOX_W-cl)//2; print(box_line(" "*lpad+ln))

k=cfg["key"]
if k and k in prices:
    p=prices[k]; usd=p.get("usd",0); chg=p.get("usd_24h_change",0)
    cc=G if chg>=0 else R; arr="▲" if chg>=0 else "▼"
    chf=p.get("chf",""); cs=f" {D}CHF {chf:,.0f}{N}" if chf else ""
    pt=f"{B}{W}${usd:>10,.0f}{N}{cs} {cc}{arr}{chg:+.1f}%{N}"; lpad=(BOX_W-vlen(pt))//2; print(box_line(" "*lpad+pt))
elif hp:
    pt=f"{B}{Y}${hp[-1]:>10,.0f}{N}"; lpad=(BOX_W-vlen(pt))//2; print(box_line(" "*lpad+pt))

sw=BOX_W//2-6
for i,oc in enumerate(cfgs):
    if i==CYCLE: continue
    h2=hists[i]; hp2=[p[1] for p in h2.get("prices",[])] if h2 else []
    sp2=sparkline(hp2,sw) if hp2 else "─"*sw
    pn=f"${hp2[-1]:,.0f}" if hp2 else "?"
    sl=f" {oc['color']}{oc['name']}{N} {W}{pn}{N} {oc['color']}{sp2}{N}"
    lpad=(BOX_W-vlen(sl))//2; print(box_line(" "*lpad+sl))
print(f" {C}└{'─'*BOX_W}┘{N}")

# ── NEWS ──
_news_cycle=(int(sp.getoutput("date +%s"))//20)%2
print(f" {C}┌{'─'*BOX_W}┐{N}")
if _news_cycle==0:
    print(box_line(f" {B}{R}◆ CRYPTO NEWS{N}"))
    _nfile=f"{CACHE_DIR}/news.xml"
else:
    print(box_line(f" {B}{R}◆ 20min ZÜRICH{N}"))
    _nfile=f"{CACHE_DIR}/news_20min.xml"
try:
    _tree=ET.parse(_nfile); _items=_tree.findall('.//item')[:20]
    _off=(int(sp.getoutput("date +%s"))//20)%max(1,len(_items)-3)
    _tw=BOX_W-4; _colors=[C, W, M, Y]
    for _idx, _item in enumerate(_items[_off:_off+4]):
        _t=(_item.find('title').text or "?")[:_tw]
        print(box_line(f" {_colors[_idx%len(_colors)]}▸{N} {_t}"))
except: print(box_line(f" {D}Loading...{N}"))
print(f" {C}└{'─'*BOX_W}┘{N}")

# ── WEATHER + WORLD CLOCK ──
import json as _json, time as _time, os as _os
from datetime import datetime
try: import zoneinfo
except ImportError:
    try: from backports import zoneinfo
    except: zoneinfo = None

bw=(COLS-5)//2; TL="┌"; TR="┐"; BL="└"; BR="┘"; HZ="─"; VT="│"; hzl=HZ*bw

WCACHE=f"{CACHE_DIR}/weather.json"; _age=999
if _os.path.exists(WCACHE): _age=_time.time()-_os.path.getmtime(WCACHE)
if _age>600:
    try:
        import urllib.request
        _url="https://api.open-meteo.com/v1/forecast?latitude=47.3769&longitude=8.5417&current=temperature_2m,weathercode,windspeed_10m,relative_humidity_2m&hourly=temperature_2m,weathercode&forecast_hours=12&timezone=Europe/Zurich"
        _data=urllib.request.urlopen(_url,timeout=8).read()
        with open(WCACHE,"wb") as _f: _f.write(_data)
    except: pass
_wx=None
try:
    with open(WCACHE) as _f: _wx=_json.load(_f)
except: pass

_WMO={0:"Clear",1:"Mostly Clear",2:"Partly Cloudy",3:"Overcast",45:"Fog",48:"Rime Fog",51:"Lt Drizzle",53:"Drizzle",55:"Hvy Drizzle",61:"Lt Rain",63:"Rain",65:"Hvy Rain",71:"Lt Snow",73:"Snow",75:"Hvy Snow",80:"Showers",95:"Thunder"}
_wl=[]
if _wx and "current" in _wx:
    _cur=_wx["current"]; _t=_cur.get("temperature_2m","?"); _co=_cur.get("weathercode",0); _wi=_cur.get("windspeed_10m","?"); _hu=_cur.get("relative_humidity_2m","?")
    _wl.append(f"{B}{W}ZURICH{N}"); _wl.append(f"{B}{W}{_t}°C{N} {D}{_WMO.get(_co,f'Code {_co}')}{N}")
    _wl.append(f"{D}Wind{N} {W}{_wi} km/h{N}"); _wl.append(f"{D}Humidity{N} {W}{_hu}%{N}")
    if "hourly" in _wx:
        _ht=_wx["hourly"].get("temperature_2m",[])
        _fc=[f"{_ht[i]:.0f}°" for i in [3,6,9] if i<len(_ht)]
        if _fc: _wl.append(f"{D}+3h  +6h  +9h{N}"); _wl.append(f"{C}{'   '.join(_fc)}{N}")
else: _wl=[f"{D}No weather{N}"]

_cl=[f"{B}{W}WORLD CLOCK{N}"]
if zoneinfo:
    for _lab, _tzn in [("ZH","Europe/Zurich"),("NYC","America/New_York"),("TYO","Asia/Tokyo"),("SYD","Australia/Sydney"),("LON","Europe/London")]:
        try:
            _tz=zoneinfo.ZoneInfo(_tzn); _now=datetime.now(_tz); _ts=_now.strftime("%H:%M"); _h=_now.hour; _dow=_now.weekday()
            if _dow<5 and 9<=_h<17: _mkt=f"{G}OPEN{N}"
            elif _dow>=5: _mkt=f"{R}WE{N}"
            else: _mkt=f"{D}closed{N}"
            _cl.append(f" {C}{_lab:>3}{N} {B}{W}{_ts}{N} {_mkt}")
        except: _cl.append(f" {_lab:>3} ??:??")

print(f" {C}{TL}{hzl}{TR}{TL}{hzl}{TR}{N}")
_mr=max(len(_wl),len(_cl),6)
for _r in range(_mr):
    _wt=_wl[_r] if _r<len(_wl) else ""; _ct=_cl[_r] if _r<len(_cl) else ""
    print(f" {C}{VT}{N}{pad(f' {_wt}',bw)}{C}{VT}{VT}{N}{pad(f' {_ct}',bw)}{C}{VT}{N}")
print(f" {C}{BL}{hzl}{BR}{BL}{hzl}{BR}{N}")
PYEOF
