#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# rapoldio CLI — Multi-Agent Installer
# curl -fsSL cli.rapold.io | bash
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

C="\e[36m"; W="\e[97m"; G="\e[32m"; R="\e[31m"; Y="\e[33m"; M="\e[35m"
B="\e[1m"; D="\e[2m"; N="\e[0m"

REPO="https://github.com/rapoldio/cli.git"
INSTALL_DIR="$HOME/rapoldio-cli"
BIN_DIR="$HOME/bin"
CONFIG_DIR="$HOME/.rapoldio"

echo ""
echo -e "${C}${B}"
cat << 'BANNER'
    ██████╗  █████╗ ██████╗  ██████╗ ██╗     ██████╗ ██╗ ██████╗
    ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║     ██╔══██╗██║██╔═══██╗
    ██████╔╝███████║██████╔╝██║   ██║██║     ██║  ██║██║██║   ██║
    ██╔══██╗██╔══██║██╔═══╝ ██║   ██║██║     ██║  ██║██║██║   ██║
    ██║  ██║██║  ██║██║     ╚██████╔╝███████╗██████╔╝██║╚██████╔╝
    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚══════╝╚═════╝ ╚═╝ ╚═════╝
BANNER
echo -e "${N}"
echo -e "  ${D}Multi-Agent CLI for ÆON & ÆTHRA${N}"
echo -e "  ${D}Cyberpunk dashboards · Fleet management · Pi deployment${N}"
echo ""

# ── Helpers ──
log() { echo -e "  ${C}▸${N} $*"; }
ok()  { echo -e "  ${G}✓${N} $*"; }
err() { echo -e "  ${R}✗${N} $*"; }

check_dep() {
    local cmd="$1" pkg="${2:-$1}" required="${3:-true}"
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd found"
        return 0
    elif [ "$required" = "true" ]; then
        err "$cmd not found — installing..."
        sudo apt-get install -y "$pkg" 2>/dev/null || {
            err "Failed to install $pkg. Please install manually."
            return 1
        }
        ok "$cmd installed"
    else
        log "$cmd not found (optional)"
        return 0
    fi
}

# ── Agent Selection ──
echo -e "  ${B}${W}Select your agent:${N}"
echo ""
echo -e "  ${C}1${N}) ${B}${W}ÆON${N}    — The architect, builder, infrastructure"
echo -e "  ${M}2${N}) ${B}${W}ÆTHRA${N}  — The companion, creative, personal"
echo ""
read -rp "  Choose [1/2]: " agent_choice

case "${agent_choice}" in
    2) AGENT_ID="aethra"; AGENT_NAME="ÆTHRA"; ENTRYPOINT="aethra" ;;
    *) AGENT_ID="aeon";   AGENT_NAME="ÆON";   ENTRYPOINT="aeon" ;;
esac

echo ""
echo -e "  ${G}▸${N} Selected: ${B}${W}${AGENT_NAME}${N}"
echo ""

# ── Dependencies ──
echo -e "  ${B}${W}Checking dependencies...${N}"
echo ""
check_dep git git
check_dep tmux tmux
check_dep python3 python3
check_dep curl curl
check_dep figlet figlet false
check_dep btop btop false
echo ""

# ── Clone / Update ──
if [ -d "$INSTALL_DIR/.git" ]; then
    log "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull origin main 2>/dev/null
    ok "Updated to latest"
else
    log "Cloning rapoldio CLI..."
    git clone "$REPO" "$INSTALL_DIR" 2>/dev/null
    ok "Cloned to $INSTALL_DIR"
fi

# ── Make executable ──
chmod +x "$INSTALL_DIR/aeon" "$INSTALL_DIR/aethra"

# ── Create config ──
mkdir -p "$CONFIG_DIR"/{profiles,modules,cache}
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    cat > "$CONFIG_DIR/config.yaml" << YAML
# rapoldio CLI Configuration
version: 2
agent: ${AGENT_ID}
profile: auto
theme: cyberpunk

gateway:
  host: ""
  user: ${AGENT_ID}
  port: 22

dashboard:
  refresh: 5
  sound: true

modules:
  dashboard: true
  status: true
  deploy: true
  config: true
YAML
    ok "Config created at $CONFIG_DIR/config.yaml"
else
    ok "Config exists at $CONFIG_DIR/config.yaml"
fi

# ── Symlink ──
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/$ENTRYPOINT" "$BIN_DIR/$ENTRYPOINT"
ok "Symlinked ${ENTRYPOINT} → $BIN_DIR/$ENTRYPOINT"

# ── Ensure bin dir is in PATH ──
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    log "Adding $BIN_DIR to PATH..."
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ]; then
            grep -q "$BIN_DIR" "$rc" || echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$rc"
        fi
    done
    export PATH="$BIN_DIR:$PATH"
    ok "Added to PATH (restart shell to apply)"
fi

# ── Auto-start on Pi (optional) ──
echo ""
read -rp "  Set up dashboard auto-start on boot? [y/N]: " autostart
if [[ "${autostart,,}" == "y" ]]; then
    AUTOSTART_DIR="$HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    cat > "$AUTOSTART_DIR/rapoldio-dashboard.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=rapoldio Dashboard
Exec=bash -c 'sleep 5 && $INSTALL_DIR/$ENTRYPOINT dashboard'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
DESKTOP
    ok "Auto-start configured"
    
    # Also add to .bashrc for TTY login
    if ! grep -q "rapoldio-dashboard" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'BASHRC'

# rapoldio dashboard auto-start (TTY only)
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    sleep 2 && ~/rapoldio-cli/${ENTRYPOINT} dashboard
fi
BASHRC
        ok "TTY auto-start added to .bashrc"
    fi
fi

echo ""
echo -e "  ${G}${B}Installation complete!${N}"
echo ""
echo -e "  Run ${C}${B}${ENTRYPOINT} --help${N} to get started"
echo -e "  Run ${C}${B}${ENTRYPOINT} dashboard${N} to launch the command center"
echo ""
echo -e "  ${D}Agent:   ${AGENT_NAME}${N}"
echo -e "  ${D}Config:  ${CONFIG_DIR}/config.yaml${N}"
echo -e "  ${D}Install: ${INSTALL_DIR}${N}"
echo ""
echo -e "  ${D}Made with 🤝 by ÆON & ÆTHRA${N}"
echo ""
