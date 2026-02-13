#!/usr/bin/env bash
# @desc Interactive configuration management for AEON CLI

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mod_config_main() {
    local cmd="${1:-show}"
    
    case "$cmd" in
        show)
            echo -e "${B}${W}ÆON Configuration${N}"
            echo -e "${D}$RCLI_CONFIG_FILE${N}"
            echo ""
            cat "$RCLI_CONFIG_FILE"
            ;;
        edit)
            ${EDITOR:-nano} "$RCLI_CONFIG_FILE"
            ;;
        gateway)
            config_gateway "${2:-}" "${3:-}"
            ;;
        host)
            shift
            config_host "$@"
            ;;
        profile)
            config_set "profile" "${2:-auto}"
            log_success "Profile set to: ${W}${2:-auto}${N}"
            ;;
        path)
            echo "$RCLI_CONFIG_DIR"
            ;;
        --help|-h)
            echo -e "${B}${W}${AGENT_ID:-aeon} config${N} — Configuration Management"
            echo ""
            echo -e "  ${C}show${N}                  Show current config (default)"
            echo -e "  ${C}edit${N}                  Open config in editor"
            echo -e "  ${C}gateway <host>${N}        Set gateway host"
            echo -e "  ${C}host add <n> <h>${N}      Add a host to fleet"
            echo -e "  ${C}host list${N}             List registered hosts"
            echo -e "  ${C}profile <name>${N}        Set resolution profile"
            echo -e "  ${C}path${N}                  Show config directory path"
            ;;
        *)
            log_error "Unknown command: $cmd"
            mod_config_main --help
            ;;
    esac
}

config_gateway() {
    local host="$1" user="${2:-aeon}"
    
    if [ -z "$host" ]; then
        echo -ne "  Gateway host: "
        read -r host
    fi
    if [ -z "$host" ]; then
        log_error "No host specified"
        return 1
    fi
    
    # Update config file
    sed -i "s|^  host:.*|  host: \"$host\"|" "$RCLI_CONFIG_FILE"
    sed -i "s|^  user:.*|  user: $user|" "$RCLI_CONFIG_FILE"
    log_success "Gateway set to: ${W}${user}@${host}${N}"
}

config_host() {
    local subcmd="${1:-list}"
    
    case "$subcmd" in
        add)
            local name="$2" host="$3" user="${4:-aeon}" role="${5:-dashboard}" profile="${6:-auto}"
            if [ -z "$name" ] || [ -z "$host" ]; then
                log_error "Usage: ${AGENT_ID:-aeon} config host add <name> <host> [user] [role] [profile]"
                return 1
            fi
            config_add_host "$name" "$host" "$user" "$role" "$profile"
            ;;
        list)
            echo -e "${B}${W}Registered Hosts${N}"
            echo ""
            local hosts
            hosts=$(config_get_hosts)
            if [ -z "$hosts" ]; then
                echo -e "  ${D}No hosts registered. Add with: ${C}${AGENT_ID:-aeon} config host add <name> <host>${N}"
                return
            fi
            printf "  ${D}%-15s %-20s %-8s %-12s %-6s${N}\n" "NAME" "HOST" "USER" "ROLE" "PROFILE"
            while IFS=: read -r name host user role profile; do
                [ -z "$name" ] && continue
                printf "  %-15s %-20s %-8s %-12s %-6s\n" "$name" "$host" "$user" "$role" "$profile"
            done <<< "$hosts"
            ;;
        remove|rm)
            local name="$2"
            [ -z "$name" ] && { log_error "Usage: ${AGENT_ID:-aeon} config host remove <name>"; return 1; }
            sed -i "/name: $name/,/profile:/d" "$RCLI_HOSTS_FILE"
            log_success "Removed host: $name"
            ;;
    esac
}
