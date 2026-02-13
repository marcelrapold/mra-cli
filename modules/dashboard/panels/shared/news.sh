#!/usr/bin/env bash
# Shared panel: News feeds
C="\e[36m"; W="\e[97m"; R="\e[31m"; M="\e[35m"; Y="\e[33m"
B="\e[1m"; D="\e[2m"; N="\e[0m"
CACHE_DIR="/tmp/aeon_markets"
mkdir -p "$CACHE_DIR"

curl -sf --max-time 8 "https://watcher.guru/news/feed" > "$CACHE_DIR/news.xml" 2>/dev/null &
curl -sf --max-time 8 "https://partner-feeds.20min.ch/rss/20minuten" > "$CACHE_DIR/news_20min.xml" 2>/dev/null &
wait

echo -e "${B}${R}◆ NEWS${N}"
python3 -c "
import xml.etree.ElementTree as ET
colors=['\033[36m','\033[97m','\033[35m','\033[33m']
for src in ['$CACHE_DIR/news.xml','$CACHE_DIR/news_20min.xml']:
    try:
        tree=ET.parse(src); items=tree.findall('.//item')[:3]
        for i,item in enumerate(items):
            t=(item.find('title').text or '?')[:60]
            print(f' {colors[i%4]}▸\033[0m {t}')
    except: pass
" 2>/dev/null
