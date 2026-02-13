#!/usr/bin/env bash
# @desc Launch the $(agent_display_name) COMMAND tmux dashboard with adaptive resolution
# ═══════════════════════════════════════════════════════════════════════════════
# Dashboard Module — Assembles the full tmux dashboard with:
#   - Matrix rain top bar with figlet header
#   - Right panel (markets, news, weather, KPIs)
#   - Gateway status panel
#   - btop system monitor
#   - OpenClaw TUI (center)
# ═══════════════════════════════════════════════════════════════════════════════

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SESSION_NAME="${AGENT_ID:-aeon}-dashboard"
REFRESH=$(config_get_nested "dashboard" "refresh" "5")

# ── Load resolution profile ──
load_profile() {
    local profile="${RCLI_PROFILE:-fhd}"
    local profile_file="$MOD_DIR/profiles/${profile}.conf"
    
    if [ ! -f "$profile_file" ]; then
        log_warn "Profile '${profile}' not found, falling back to fhd"
        profile_file="$MOD_DIR/profiles/fhd.conf"
    fi
    
    source "$profile_file"
    log_debug "Loaded profile: $profile (${COLS}x${ROWS})"
}

# ── Wait for gateway ──
wait_for_gateway() {
    local gw_host
    gw_host=$(gateway_host)
    [ -z "$gw_host" ] && return 0
    
    log_info "Waiting for gateway connection..."
    for _i in $(seq 1 30); do
        ssh_test "$gw_host" "$(gateway_user)" && return 0
        sleep 2
    done
    log_warn "Gateway unreachable, continuing without remote panels"
    return 1
}

# ── Build Dashboard ──
build_dashboard() {
    load_profile
    
    local cols rows
    cols=$(tput cols 2>/dev/null || echo "$COLS")
    rows=$(tput lines 2>/dev/null || echo "$ROWS")
    
    # Kill existing session
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    sleep 0.3
    
    # Create session
    tmux new-session -d -s "$SESSION_NAME" -x "$cols" -y "$rows"
    
    # ── Layout Assembly ──
    # Pane 0: Top bar (full width)
    tmux split-window -v -t "$SESSION_NAME:0.0" -l $((rows - TOP_H))
    
    # Pane 1+2: Left area | Right panel
    tmux split-window -h -t "$SESSION_NAME:0.1" -l "$RIGHT_W"
    
    # Pane 1 → Upper left | btop (lower left)
    tmux split-window -v -t "$SESSION_NAME:0.1" -l "$BTOP_H"
    
    # Upper left → Status | Center TUI
    tmux split-window -h -t "$SESSION_NAME:0.1" -l $((cols - RIGHT_W - LEFT_STATUS_W - 2))
    
    # ── Pane Commands ──
    # Pane 0: Top — Matrix rain + figlet
    tmux send-keys -t "$SESSION_NAME:0.0" \
        "watch -t -n $REFRESH 'bash $MOD_DIR/top_bar.sh'" Enter
    
    # Pane 1: Left — Gateway status
    local gw_host gw_user
    gw_host=$(gateway_host)
    gw_user=$(gateway_user)
    if [ -n "$gw_host" ]; then
        tmux send-keys -t "$SESSION_NAME:0.1" \
            "watch -t -n 30 'ssh ${gw_user}@${gw_host} bash /home/aeon/aeon_status.sh 2>/dev/null'" Enter
    else
        tmux send-keys -t "$SESSION_NAME:0.1" \
            "watch -t -n 30 'bash $MOD_DIR/status_panel.sh'" Enter
    fi
    
    # Pane 2: Center — OpenClaw TUI
    if [ -n "$gw_host" ]; then
        tmux send-keys -t "$SESSION_NAME:0.2" \
            "ssh -t ${gw_user}@${gw_host} 'openclaw tui' 2>/dev/null || { echo 'Connecting...'; sleep 5; ssh -t ${gw_user}@${gw_host} 'openclaw tui'; }" Enter
    else
        tmux send-keys -t "$SESSION_NAME:0.2" \
            "openclaw tui 2>/dev/null || echo 'OpenClaw TUI not available'" Enter
    fi
    
    # Pane 3: Bottom-left — btop
    if [ -n "$gw_host" ]; then
        tmux send-keys -t "$SESSION_NAME:0.3" \
            "ssh -t ${gw_user}@${gw_host} btop" Enter
    else
        tmux send-keys -t "$SESSION_NAME:0.3" "btop" Enter
    fi
    
    # Pane 4: Right — Markets + News + Weather
    tmux send-keys -t "$SESSION_NAME:0.4" \
        "watch -t -n $REFRESH 'bash $MOD_DIR/right_panel.sh'" Enter
    
    # ── Style ──
    tmux set -t "$SESSION_NAME" pane-border-style "fg=cyan"
    tmux set -t "$SESSION_NAME" pane-active-border-style "fg=brightcyan,bold"
    tmux set -t "$SESSION_NAME" status off
    
    # ── Startup Sound ──
    local sound
    sound=$(config_get_nested "dashboard" "startup_sound" "")
    if [ -n "$sound" ] && has_mpg123 && [ -f "$sound" ]; then
        mpg123 -a plughw:1,0 "$sound" >/dev/null 2>&1 &
    fi
    
    sleep 1
    tmux select-pane -t "$SESSION_NAME:0.2"
}

# ── Module Entry Point ──
mod_dashboard_main() {
    local cmd="${1:-start}"
    
    case "$cmd" in
        start|launch)
            require_cmd tmux
            require_cmd watch
            log_info "Launching $(agent_display_name) COMMAND Dashboard (${B}${RCLI_PROFILE}${N})"
            wait_for_gateway || true
            build_dashboard
            tmux attach-session -t "$SESSION_NAME"
            ;;
        stop|kill)
            tmux kill-session -t "$SESSION_NAME" 2>/dev/null
            log_success "Dashboard stopped"
            ;;
        status)
            if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                echo -e "${G}●${N} Dashboard is running"
                tmux list-panes -t "$SESSION_NAME" -F '  Pane #{pane_index}: #{pane_width}x#{pane_height} — #{pane_current_command}'
            else
                echo -e "${R}●${N} Dashboard is not running"
            fi
            ;;
        --help|-h)
            echo -e "${B}${W}${AGENT_ID:-aeon} dashboard${N} — $(agent_display_name) COMMAND Dashboard"
            echo ""
            echo -e "  ${C}start${N}    Launch dashboard (default)"
            echo -e "  ${C}stop${N}     Kill dashboard session"
            echo -e "  ${C}status${N}   Show dashboard status"
            ;;
        *)
            log_error "Unknown command: $cmd"
            mod_dashboard_main --help
            ;;
    esac
}
