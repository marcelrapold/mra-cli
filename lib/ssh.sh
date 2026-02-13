#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ÆON CLI — SSH & Remote Execution Helpers
# Manages SSH connections to registered Pi fleet
# ═══════════════════════════════════════════════════════════════════════════════

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes -o LogLevel=ERROR"

# ── Remote Execution ──
ssh_exec() {
    local host="$1" user="${2:-aeon}"
    shift 2
    local cmd="$*"
    ssh $SSH_OPTS "${user}@${host}" "$cmd" 2>/dev/null
}

ssh_exec_tty() {
    local host="$1" user="${2:-aeon}"
    shift 2
    local cmd="$*"
    ssh -t $SSH_OPTS "${user}@${host}" "$cmd" 2>/dev/null
}

# ── Connection Test ──
ssh_test() {
    local host="$1" user="${2:-aeon}"
    ssh $SSH_OPTS "${user}@${host}" "true" 2>/dev/null
}

ssh_test_hosts() {
    local results=()
    while IFS=: read -r name host user role profile; do
        [ -z "$name" ] && continue
        if ssh_test "$host" "$user"; then
            results+=("${G}●${N} ${W}$name${N} ($host) — ${G}online${N}")
        else
            results+=("${R}●${N} ${W}$name${N} ($host) — ${R}offline${N}")
        fi
    done <<< "$(config_get_hosts)"
    
    for r in "${results[@]}"; do
        echo -e "  $r"
    done
}

# ── File Transfer ──
ssh_push() {
    local host="$1" user="$2" src="$3" dst="$4"
    scp $SSH_OPTS "$src" "${user}@${host}:${dst}" 2>/dev/null
}

ssh_pull() {
    local host="$1" user="$2" src="$3" dst="$4"
    scp $SSH_OPTS "${user}@${host}:${src}" "$dst" 2>/dev/null
}

# ── Batch Execution (all hosts) ──
ssh_broadcast() {
    local cmd="$1"
    local pids=()
    local hosts=()
    
    while IFS=: read -r name host user role profile; do
        [ -z "$name" ] && continue
        hosts+=("$name")
        ssh_exec "$host" "$user" "$cmd" &
        pids+=($!)
    done <<< "$(config_get_hosts)"
    
    for i in "${!pids[@]}"; do
        if wait "${pids[$i]}" 2>/dev/null; then
            echo -e "  ${G}✓${N} ${hosts[$i]}"
        else
            echo -e "  ${R}✗${N} ${hosts[$i]}"
        fi
    done
}

# ── Gateway Helpers ──
gateway_host() {
    config_get_nested "gateway" "host"
}

gateway_user() {
    config_get_nested "gateway" "user" "aeon"
}

gateway_exec() {
    local gw_host gw_user
    gw_host=$(gateway_host)
    gw_user=$(gateway_user)
    
    if [ -z "$gw_host" ]; then
        log_error "Gateway host not configured. Run: ${C}config gateway${N}"
        return 1
    fi
    
    ssh_exec "$gw_host" "$gw_user" "$@"
}
