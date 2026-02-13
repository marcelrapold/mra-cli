#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ÆON CLI — Configuration Management
# Manages ~/.rapoldio/ config directory, YAML config, host registry
# ═══════════════════════════════════════════════════════════════════════════════

RCLI_CONFIG_DIR="${RCLI_CONFIG_DIR:-$HOME/.rapoldio}"
RCLI_CONFIG_FILE="$RCLI_CONFIG_DIR/config.yaml"
RCLI_HOSTS_FILE="$RCLI_CONFIG_DIR/hosts.yaml"
RCLI_CACHE_DIR="$RCLI_CONFIG_DIR/cache"

# ── Initialize Config ──
config_init() {
    mkdir -p "$RCLI_CONFIG_DIR"/{profiles,modules,cache}
    
    if [ ! -f "$RCLI_CONFIG_FILE" ]; then
        cat > "$RCLI_CONFIG_FILE" << 'YAML'
# rapoldio CLI Configuration
version: 2
agent: aeon  # aeon or aethra
profile: auto
theme: cyberpunk

gateway:
  host: ""
  user: aeon
  port: 22

dashboard:
  refresh: 5
  sound: true
  startup_sound: ~/aeon_startup.mp3

modules:
  dashboard: true
  status: true
  deploy: true
  config: true
YAML
        log_info "Created default config: ${C}$RCLI_CONFIG_FILE${N}"
    fi
    
    if [ ! -f "$RCLI_HOSTS_FILE" ]; then
        cat > "$RCLI_HOSTS_FILE" << 'YAML'
# ÆON Host Registry
# Define your Raspberry Pi fleet here
hosts: []
  # - name: pi-living
  #   host: 192.168.1.10
  #   user: aeon
  #   role: dashboard
  #   profile: fhd
  # - name: pi-office
  #   host: 192.168.1.11
  #   user: aeon
  #   role: dashboard
  #   profile: uhd
YAML
    fi
}

# ── Config Getters (simple YAML parsing without dependencies) ──
config_get() {
    local key="$1" default="${2:-}"
    local value
    value=$(grep -E "^${key}:" "$RCLI_CONFIG_FILE" 2>/dev/null | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/#.*//' | xargs)
    echo "${value:-$default}"
}

config_get_nested() {
    local section="$1" key="$2" default="${3:-}"
    local value
    value=$(awk "/^${section}:/{found=1;next} /^[^ ]/{found=0} found && /^ *${key}:/{print}" "$RCLI_CONFIG_FILE" 2>/dev/null | head -1 | sed "s/.*${key}:[[:space:]]*//" | sed 's/#.*//' | xargs)
    echo "${value:-$default}"
}

# ── Config Setters ──
config_set() {
    local key="$1" value="$2"
    if grep -q "^${key}:" "$RCLI_CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}:.*|${key}: ${value}|" "$RCLI_CONFIG_FILE"
    else
        echo "${key}: ${value}" >> "$RCLI_CONFIG_FILE"
    fi
}

# ── Host Registry ──
config_get_hosts() {
    # Returns host entries as "name:host:user:role:profile" lines
    awk '/^  - name:/{name=$3} /host:/{h=$2} /user:/{u=$2} /role:/{r=$2} /profile:/{p=$2; print name":"h":"u":"r":"p}' "$RCLI_HOSTS_FILE" 2>/dev/null
}

config_get_host() {
    local name="$1"
    config_get_hosts | grep "^${name}:" | head -1
}

config_add_host() {
    local name="$1" host="$2" user="${3:-aeon}" role="${4:-dashboard}" profile="${5:-auto}"
    cat >> "$RCLI_HOSTS_FILE" << YAML
  - name: $name
    host: $host
    user: $user
    role: $role
    profile: $profile
YAML
    log_success "Added host: ${W}$name${N} ($host)"
}
