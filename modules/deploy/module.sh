#!/usr/bin/env bash
# @desc Deploy AEON CLI and configs to registered Raspberry Pis

MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mod_deploy_main() {
    local cmd="${1:-}"
    
    case "$cmd" in
        all)
            deploy_all
            ;;
        dashboard)
            deploy_dashboard "${2:-}"
            ;;
        config)
            deploy_config "${2:-}"
            ;;
        update)
            deploy_update
            ;;
        --help|-h|"")
            echo -e "${B}${W}${AGENT_ID:-aeon} deploy${N} — Remote Deployment"
            echo ""
            echo -e "  ${C}all${N}          Deploy AEON CLI to all hosts"
            echo -e "  ${C}dashboard${N}    Deploy dashboard scripts to [host|all]"
            echo -e "  ${C}config${N}       Push config to [host|all]"
            echo -e "  ${C}update${N}       Pull latest & redeploy"
            ;;
        *)
            log_error "Unknown command: $cmd"
            mod_deploy_main --help
            ;;
    esac
}

deploy_all() {
    source "$RCLI_LIB/ssh.sh"
    log_info "Deploying AEON CLI to all hosts..."
    echo ""
    
    while IFS=: read -r name host user role profile; do
        [ -z "$name" ] && continue
        echo -ne "  ${C}$name${N} ($host) ... "
        
        if ! ssh_test "$host" "$user"; then
            echo -e "${R}offline${N}"
            continue
        fi
        
        # Create remote directory
        ssh_exec "$host" "$user" "mkdir -p ~/rapoldio-cli"
        
        # Rsync the CLI
        rsync -az --delete \
            --exclude '.git' --exclude '.github' \
            "$RCLI_ROOT/" "${user}@${host}:~/rapoldio-cli/" 2>/dev/null
        
        # Symlink
        ssh_exec "$host" "$user" "ln -sf ~/rapoldio-cli/aeon ~/bin/${AGENT_ID:-aeon} 2>/dev/null; chmod +x ~/rapoldio-cli/aeon"
        
        echo -e "${G}✓ deployed${N}"
    done <<< "$(config_get_hosts)"
    
    echo ""
    log_success "Deployment complete"
}

deploy_dashboard() {
    source "$RCLI_LIB/ssh.sh"
    local target="${1:-all}"
    
    log_info "Deploying dashboard to ${W}$target${N}..."
    
    local hosts
    if [ "$target" = "all" ]; then
        hosts=$(config_get_hosts)
    else
        hosts=$(config_get_host "$target")
    fi
    
    while IFS=: read -r name host user role profile; do
        [ -z "$name" ] && continue
        [ "$role" != "dashboard" ] && continue
        
        echo -ne "  ${C}$name${N} ... "
        ssh_exec "$host" "$user" "mkdir -p ~/rapoldio-cli/modules/dashboard"
        rsync -az "$RCLI_ROOT/modules/dashboard/" "${user}@${host}:~/rapoldio-cli/modules/dashboard/" 2>/dev/null
        echo -e "${G}✓${N}"
    done <<< "$hosts"
}

deploy_config() {
    source "$RCLI_LIB/ssh.sh"
    local target="${1:-all}"
    
    log_info "Pushing config to ${W}$target${N}..."
    ssh_broadcast "mkdir -p ~/.rapoldio"
    
    while IFS=: read -r name host user role profile; do
        [ -z "$name" ] && continue
        echo -ne "  ${C}$name${N} ... "
        ssh_push "$host" "$user" "$RCLI_CONFIG_DIR/config.yaml" "~/.rapoldio/config.yaml"
        echo -e "${G}✓${N}"
    done <<< "$(config_get_hosts)"
}

deploy_update() {
    log_info "Updating AEON CLI..."
    cd "$RCLI_ROOT"
    git pull origin main 2>/dev/null || { log_error "Git pull failed"; return 1; }
    log_success "Updated to latest version"
    echo ""
    deploy_all
}
