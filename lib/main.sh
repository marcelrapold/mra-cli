#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# rapoldio CLI — Shared Main Library
# Sourced by agent entrypoints (aeon, aethra)
# ═══════════════════════════════════════════════════════════════════════════════

RCLI_VERSION="2.0.0"
RCLI_ROOT="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
RCLI_CONFIG_DIR="${RCLI_CONFIG_DIR:-$HOME/.rapoldio}"
RCLI_LIB="$RCLI_ROOT/lib"
RCLI_MODULES="$RCLI_ROOT/modules"

# Agent ID (set by entrypoint)
export AGENT_ID="${AGENT_ID:-aeon}"

# ── Load core libraries ──
source "$RCLI_LIB/core.sh"
source "$RCLI_LIB/config.sh"
source "$RCLI_LIB/detect.sh"

# ── Agent display names ──
agent_display_name() {
    case "${AGENT_ID}" in
        aeon)   echo "ÆON" ;;
        aethra) echo "ÆTHRA" ;;
        *)      echo "${AGENT_ID}" ;;
    esac
}

# ── ASCII Logo ──
show_logo() {
    if [ "$AGENT_ID" = "aethra" ]; then
        cat << 'EOF'

     ░█████╗░███████╗████████╗██╗░░██╗██████╗░░█████╗░
     ██╔══██╗██╔════╝╚══██╔══╝██║░░██║██╔══██╗██╔══██╗
     ███████║█████╗░░░░░██║░░░███████║██████╔╝███████║
     ██╔══██║██╔══╝░░░░░██║░░░██╔══██║██╔══██╗██╔══██║
     ██║░░██║███████╗░░░██║░░░██║░░██║██║░░██║██║░░██║
     ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝

EOF
    else
        cat << 'EOF'

     ░█████╗░███████╗░█████╗░███╗░░██╗     ░█████╗░██╗░░░░░██╗
     ██╔══██╗██╔════╝██╔══██╗████╗░██║    ██╔══██╗██║░░░░░██║
     ███████║█████╗░░██║░░██║██╔██╗██║    ██║░░╚═╝██║░░░░░██║
     ██╔══██║██╔══╝░░██║░░██║██║╚████║    ██║░░██╗██║░░░░░██║
     ██║░░██║███████╗╚█████╔╝██║░╚███║    ╚█████╔╝███████╗██║
     ╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝░░╚══╝     ╚════╝░╚══════╝╚═╝

EOF
    fi
}

# ── Help ──
show_help() {
    local agent_name
    agent_name=$(agent_display_name)
    show_logo
    echo -e "${C}${B}${agent_name} CLI${N} ${D}v${RCLI_VERSION}${N} — Modular Command Center"
    echo ""
    echo -e "${W}USAGE${N}"
    echo -e "  ${AGENT_ID} <module> [command] [options]"
    echo ""
    echo -e "${W}MODULES${N}"
    
    for mod_dir in "$RCLI_MODULES"/*/; do
        [ -f "$mod_dir/module.sh" ] || continue
        mod_name=$(basename "$mod_dir")
        mod_desc=$(grep '^# @desc' "$mod_dir/module.sh" 2>/dev/null | head -1 | sed 's/^# @desc //')
        [ -z "$mod_desc" ] && mod_desc="No description"
        printf "  ${C}%-12s${N} %s\n" "$mod_name" "$mod_desc"
    done
    
    echo ""
    echo -e "${W}OPTIONS${N}"
    echo -e "  ${C}--version${N}     Show version"
    echo -e "  ${C}--help${N}        Show this help"
    echo -e "  ${C}--profile${N}     Set resolution profile (sd/hd/fhd/qhd/uhd)"
    echo -e "  ${C}--config${N}      Path to config file"
    echo ""
    echo -e "${D}Agent: ${AGENT_ID} | Config: ${RCLI_CONFIG_DIR}/config.yaml${N}"
}

# ── Module loader ──
load_module() {
    local module="$1"
    shift
    local mod_path="$RCLI_MODULES/$module/module.sh"
    
    if [ ! -f "$mod_path" ]; then
        log_error "Unknown module: $module"
        echo ""
        echo -e "Available modules:"
        for mod_dir in "$RCLI_MODULES"/*/; do
            [ -f "$mod_dir/module.sh" ] && echo -e "  ${C}$(basename "$mod_dir")${N}"
        done
        exit 1
    fi
    
    source "$mod_path"
    
    local func="mod_${module}_main"
    if declare -f "$func" > /dev/null 2>&1; then
        "$func" "$@"
    else
        log_error "Module '$module' missing entry function: $func"
        exit 1
    fi
}

# ── Main ──
rcli_main() {
    config_init
    
    local profile=""
    local args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version|-v)
                echo "${AGENT_ID} v${RCLI_VERSION}"
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --profile)
                profile="$2"
                export RCLI_PROFILE="$profile"
                shift 2
                ;;
            --config)
                export RCLI_CONFIG_DIR="$2"
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    if [ ${#args[@]} -eq 0 ]; then
        show_help
        exit 0
    fi
    
    if [ -z "$profile" ]; then
        detect_profile
    fi
    
    load_module "${args[@]}"
}
