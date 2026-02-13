#!/usr/bin/env bash
# @desc System status overview — gateway, services, fleet health

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mod_status_main() {
    local cmd="${1:-overview}"
    
    case "$cmd" in
        overview|show)
            show_status_overview
            ;;
        gateway|gw)
            show_gateway_status
            ;;
        fleet|hosts)
            source "$RCLI_LIB/ssh.sh"
            echo -e "${B}${W}Fleet Status${N}"
            echo ""
            ssh_test_hosts
            ;;
        --help|-h)
            echo -e "${B}${W}${AGENT_ID:-aeon} status${N} — System Status Monitor"
            echo ""
            echo -e "  ${C}overview${N}   Full status overview (default)"
            echo -e "  ${C}gateway${N}    Gateway connection status"
            echo -e "  ${C}fleet${N}      Test all registered hosts"
            ;;
        *)
            log_error "Unknown command: $cmd"
            mod_status_main --help
            ;;
    esac
}

show_status_overview() {
    local cols
    cols=$(term_cols)
    
    echo ""
    echo -e "  ${B}${C}╔══════════════════════════════════╗${N}"
    echo -e "  ${B}${C}║${N}  ${B}${W}$(agent_display_name) COMMAND${N} v${RCLI_VERSION}            ${B}${C}║${N}"
    echo -e "  ${B}${C}║${N}  Status: ${G}● ONLINE${N}               ${B}${C}║${N}"
    echo -e "  ${B}${C}║${N}  Profile: ${W}${RCLI_PROFILE}${N} $(profile_info "$RCLI_PROFILE" | head -c 20)  ${B}${C}║${N}"
    echo -e "  ${B}${C}╚══════════════════════════════════╝${N}"
    echo ""
    
    # Local system
    echo -e "  ${B}${W}Local System${N}"
    echo -e "  Host:    ${W}$(hostname)${N}"
    echo -e "  Uptime:  ${G}$(uptime -p 2>/dev/null | sed 's/up //')${N}"
    echo -e "  Memory:  ${W}$(free -h 2>/dev/null | awk '/Mem:/{print $3 " / " $2}')${N}"
    echo -e "  Disk:    ${W}$(df -h / 2>/dev/null | awk 'NR==2{print $3 " / " $2 " (" $5 ")"}')${N}"
    echo -e "  Load:    ${W}$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')${N}"
    echo ""
    
    # Hardware
    local hw
    hw=$(detect_hardware)
    [ -n "$hw" ] && echo -e "  ${B}${W}Hardware${N}: ${C}$hw${N}" && echo ""
    
    # Gateway
    show_gateway_status
}

show_gateway_status() {
    source "$RCLI_LIB/ssh.sh"
    local gw_host gw_user
    gw_host=$(gateway_host)
    gw_user=$(gateway_user)
    
    echo -e "  ${B}${W}Gateway${N}"
    if [ -z "$gw_host" ]; then
        echo -e "  ${Y}●${N} Not configured — run ${C}aeon config gateway${N}"
        return
    fi
    
    echo -ne "  Connecting to ${C}${gw_host}${N}... "
    if ssh_test "$gw_host" "$gw_user"; then
        echo -e "${G}● Connected${N}"
        local remote_uptime
        remote_uptime=$(ssh_exec "$gw_host" "$gw_user" "uptime -p" 2>/dev/null | sed 's/up //')
        [ -n "$remote_uptime" ] && echo -e "  Uptime:  ${G}$remote_uptime${N}"
    else
        echo -e "${R}● Unreachable${N}"
    fi
    echo ""
}
