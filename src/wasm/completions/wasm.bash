#!/usr/bin/env bash
# Bash completion script for WASM (Web App System Management)
# 
# Installation:
#   Option 1 - System-wide (requires sudo):
#     sudo cp wasm.bash /etc/bash_completion.d/wasm
#
#   Option 2 - User-local:
#     mkdir -p ~/.local/share/bash-completion/completions
#     cp wasm.bash ~/.local/share/bash-completion/completions/wasm
#
#   Option 3 - Manual in .bashrc:
#     source /path/to/wasm.bash
#
#   After installation, restart your shell or run: source ~/.bashrc

# Helper function to get list of deployed apps (domains)
_wasm_get_apps() {
    local apps_dir="/var/www/apps"
    if [[ -d "$apps_dir" ]]; then
        for app in "$apps_dir"/*/; do
            if [[ -d "$app" ]]; then
                basename "$app"
            fi
        done 2>/dev/null
    fi
}

# Helper function to get list of wasm services
_wasm_get_services() {
    systemctl list-units --type=service --all 2>/dev/null | \
        grep -E '^wasm-[^ ]+\.service' | \
        sed 's/^\(wasm-[^ ]*\)\.service.*/\1/' | \
        sed 's/^wasm-//'
}

# Helper function to get nginx sites
_wasm_get_nginx_sites() {
    local sites_dir="/etc/nginx/sites-available"
    if [[ -d "$sites_dir" ]]; then
        for site in "$sites_dir"/*; do
            if [[ -f "$site" && "$(basename "$site")" != "default" ]]; then
                basename "$site"
            fi
        done 2>/dev/null
    fi
}

# Helper function to get apache sites
_wasm_get_apache_sites() {
    local sites_dir="/etc/apache2/sites-available"
    if [[ -d "$sites_dir" ]]; then
        for site in "$sites_dir"/*.conf; do
            if [[ -f "$site" ]]; then
                basename "$site" .conf
            fi
        done 2>/dev/null
    fi
}

# Helper function to get all sites
_wasm_get_all_sites() {
    _wasm_get_nginx_sites
    _wasm_get_apache_sites
}

# Helper function to get SSL certificates
_wasm_get_certs() {
    local live_dir="/etc/letsencrypt/live"
    if [[ -d "$live_dir" ]]; then
        for cert in "$live_dir"/*/; do
            if [[ -d "$cert" ]]; then
                basename "$cert"
            fi
        done 2>/dev/null
    fi
}

# Main completion function
_wasm_completion() {
    local cur prev words cword
    _init_completion || return

    # Top-level commands
    local commands="create new deploy list ls status info restart stop start update upgrade delete remove rm logs site service svc cert ssl certificate setup --help --version --verbose --interactive --no-color"
    
    # Webapp actions that take a domain
    local webapp_domain_commands="status info restart stop start update upgrade delete remove rm logs"
    
    # Site actions
    local site_actions="create list ls enable disable delete remove rm show cat"
    
    # Service actions  
    local service_actions="create list ls status info start stop restart logs delete remove rm"
    
    # Cert actions
    local cert_actions="create obtain new list ls info show renew revoke delete remove rm"
    
    # Setup actions
    local setup_actions="init completions permissions"
    
    # App types
    local app_types="nextjs nodejs vite python static auto"
    
    # Webservers
    local webservers="nginx apache"
    
    # Package managers
    local package_managers="npm pnpm bun auto"

    case ${cword} in
        1)
            # First argument - complete commands
            COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
            return
            ;;
    esac

    # Get the command (first non-option argument)
    local cmd=""
    local subcmd=""
    local i
    for ((i=1; i < cword; i++)); do
        case "${words[i]}" in
            -*)
                continue
                ;;
            *)
                if [[ -z "$cmd" ]]; then
                    cmd="${words[i]}"
                elif [[ -z "$subcmd" ]]; then
                    subcmd="${words[i]}"
                fi
                ;;
        esac
    done

    # Handle site subcommands
    if [[ "$cmd" == "site" ]]; then
        case "$subcmd" in
            "")
                COMPREPLY=($(compgen -W "${site_actions}" -- "${cur}"))
                return
                ;;
            create)
                case "$prev" in
                    -d|--domain)
                        # Domain input - no completion
                        return
                        ;;
                    -w|--webserver)
                        COMPREPLY=($(compgen -W "${webservers}" -- "${cur}"))
                        return
                        ;;
                    -t|--template)
                        COMPREPLY=($(compgen -W "proxy static" -- "${cur}"))
                        return
                        ;;
                    -p|--port)
                        # Port number - no completion
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-d --domain -w --webserver -t --template -p --port" -- "${cur}"))
                return
                ;;
            enable|disable|show|cat)
                if [[ "$prev" == "$subcmd" ]]; then
                    COMPREPLY=($(compgen -W "$(_wasm_get_all_sites)" -- "${cur}"))
                fi
                return
                ;;
            delete|remove|rm)
                case "$prev" in
                    delete|remove|rm)
                        COMPREPLY=($(compgen -W "$(_wasm_get_all_sites)" -- "${cur}"))
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-f --force" -- "${cur}"))
                return
                ;;
            list|ls)
                case "$prev" in
                    -w|--webserver)
                        COMPREPLY=($(compgen -W "nginx apache all" -- "${cur}"))
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-w --webserver" -- "${cur}"))
                return
                ;;
        esac
        return
    fi

    # Handle service subcommands
    if [[ "$cmd" == "service" || "$cmd" == "svc" ]]; then
        case "$subcmd" in
            "")
                COMPREPLY=($(compgen -W "${service_actions}" -- "${cur}"))
                return
                ;;
            create)
                case "$prev" in
                    -n|--name)
                        return
                        ;;
                    -c|--command)
                        return
                        ;;
                    -d|--directory)
                        _filedir -d
                        return
                        ;;
                    -u|--user)
                        COMPREPLY=($(compgen -u -- "${cur}"))
                        return
                        ;;
                    --description)
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-n --name -c --command -d --directory -u --user --description" -- "${cur}"))
                return
                ;;
            status|info|start|stop|restart)
                if [[ "$prev" == "$subcmd" ]]; then
                    COMPREPLY=($(compgen -W "$(_wasm_get_services)" -- "${cur}"))
                fi
                return
                ;;
            logs)
                case "$prev" in
                    logs)
                        COMPREPLY=($(compgen -W "$(_wasm_get_services)" -- "${cur}"))
                        return
                        ;;
                    -n|--lines)
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-f --follow -n --lines" -- "${cur}"))
                return
                ;;
            delete|remove|rm)
                case "$prev" in
                    delete|remove|rm)
                        COMPREPLY=($(compgen -W "$(_wasm_get_services)" -- "${cur}"))
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-f --force" -- "${cur}"))
                return
                ;;
            list|ls)
                COMPREPLY=($(compgen -W "-a --all" -- "${cur}"))
                return
                ;;
        esac
        return
    fi

    # Handle cert subcommands
    if [[ "$cmd" == "cert" || "$cmd" == "ssl" || "$cmd" == "certificate" ]]; then
        case "$subcmd" in
            "")
                COMPREPLY=($(compgen -W "${cert_actions}" -- "${cur}"))
                return
                ;;
            create|obtain|new)
                case "$prev" in
                    -d|--domain)
                        return
                        ;;
                    -e|--email)
                        return
                        ;;
                    -w|--webroot)
                        _filedir -d
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-d --domain -e --email -w --webroot --standalone --nginx --apache --dry-run" -- "${cur}"))
                return
                ;;
            info|show)
                if [[ "$prev" == "$subcmd" ]]; then
                    COMPREPLY=($(compgen -W "$(_wasm_get_certs)" -- "${cur}"))
                fi
                return
                ;;
            renew)
                case "$prev" in
                    -d|--domain)
                        COMPREPLY=($(compgen -W "$(_wasm_get_certs)" -- "${cur}"))
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-d --domain --force --dry-run" -- "${cur}"))
                return
                ;;
            revoke)
                if [[ "$prev" == "revoke" ]]; then
                    COMPREPLY=($(compgen -W "$(_wasm_get_certs)" -- "${cur}"))
                    return
                fi
                COMPREPLY=($(compgen -W "--delete" -- "${cur}"))
                return
                ;;
            delete|remove|rm)
                case "$prev" in
                    delete|remove|rm)
                        COMPREPLY=($(compgen -W "$(_wasm_get_certs)" -- "${cur}"))
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-f --force" -- "${cur}"))
                return
                ;;
        esac
        return
    fi

    # Handle setup subcommands
    if [[ "$cmd" == "setup" ]]; then
        case "$subcmd" in
            "")
                COMPREPLY=($(compgen -W "${setup_actions}" -- "${cur}"))
                return
                ;;
            completions)
                case "$prev" in
                    -s|--shell)
                        COMPREPLY=($(compgen -W "bash zsh fish" -- "${cur}"))
                        return
                        ;;
                esac
                COMPREPLY=($(compgen -W "-s --shell -u --user-only" -- "${cur}"))
                return
                ;;
            init|permissions)
                # No additional arguments
                return
                ;;
        esac
        return
    fi

    # Handle webapp commands (top-level)
    case "$cmd" in
        create|new|deploy)
            case "$prev" in
                -d|--domain)
                    return
                    ;;
                -s|--source)
                    _filedir
                    return
                    ;;
                -t|--type)
                    COMPREPLY=($(compgen -W "${app_types}" -- "${cur}"))
                    return
                    ;;
                -p|--port)
                    return
                    ;;
                -w|--webserver)
                    COMPREPLY=($(compgen -W "${webservers}" -- "${cur}"))
                    return
                    ;;
                -b|--branch)
                    return
                    ;;
                --env-file)
                    _filedir
                    return
                    ;;
                --pm|--package-manager)
                    COMPREPLY=($(compgen -W "${package_managers}" -- "${cur}"))
                    return
                    ;;
            esac
            COMPREPLY=($(compgen -W "-d --domain -s --source -t --type -p --port -w --webserver -b --branch --no-ssl --env-file --pm --package-manager" -- "${cur}"))
            return
            ;;
        status|info|restart|stop|start)
            if [[ "$prev" == "$cmd" ]]; then
                COMPREPLY=($(compgen -W "$(_wasm_get_apps)" -- "${cur}"))
            fi
            return
            ;;
        update|upgrade)
            case "$prev" in
                update|upgrade)
                    COMPREPLY=($(compgen -W "$(_wasm_get_apps)" -- "${cur}"))
                    return
                    ;;
                -s|--source)
                    _filedir
                    return
                    ;;
                -b|--branch)
                    return
                    ;;
                --pm|--package-manager)
                    COMPREPLY=($(compgen -W "${package_managers}" -- "${cur}"))
                    return
                    ;;
            esac
            COMPREPLY=($(compgen -W "-s --source -b --branch --pm --package-manager" -- "${cur}"))
            return
            ;;
        delete|remove|rm)
            case "$prev" in
                delete|remove|rm)
                    COMPREPLY=($(compgen -W "$(_wasm_get_apps)" -- "${cur}"))
                    return
                    ;;
            esac
            COMPREPLY=($(compgen -W "-f --force --keep-files" -- "${cur}"))
            return
            ;;
        logs)
            case "$prev" in
                logs)
                    COMPREPLY=($(compgen -W "$(_wasm_get_apps)" -- "${cur}"))
                    return
                    ;;
                -n|--lines)
                    return
                    ;;
            esac
            COMPREPLY=($(compgen -W "-f --follow -n --lines" -- "${cur}"))
            return
            ;;
        list|ls)
            # No further completion needed
            return
            ;;
    esac
}

# Register the completion function
complete -F _wasm_completion wasm
