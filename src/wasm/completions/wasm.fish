# Fish completion script for WASM (Web App System Management)
#
# Installation:
#   Option 1 - System-wide (requires sudo):
#     sudo cp wasm.fish /usr/share/fish/vendor_completions.d/wasm.fish
#
#   Option 2 - User-local:
#     cp wasm.fish ~/.config/fish/completions/wasm.fish
#
#   Completions should work immediately or after: exec fish

# Disable file completions for commands
complete -c wasm -f

# Helper functions
function __wasm_get_apps
    set -l apps_dir "/var/www/apps"
    if test -d "$apps_dir"
        for app in $apps_dir/*/
            if test -d "$app"
                basename "$app"
            end
        end 2>/dev/null
    end
end

function __wasm_get_services
    systemctl list-units --type=service --all 2>/dev/null | \
        grep -E '^wasm-[^ ]+\.service' | \
        sed 's/^\(wasm-[^ ]*\)\.service.*/\1/' | \
        sed 's/^wasm-//'
end

function __wasm_get_sites
    set -l nginx_dir "/etc/nginx/sites-available"
    set -l apache_dir "/etc/apache2/sites-available"
    
    if test -d "$nginx_dir"
        for site in $nginx_dir/*
            if test -f "$site"; and test (basename "$site") != "default"
                basename "$site"
            end
        end 2>/dev/null
    end
    
    if test -d "$apache_dir"
        for site in $apache_dir/*.conf
            if test -f "$site"
                basename "$site" .conf
            end
        end 2>/dev/null
    end
end

function __wasm_get_certs
    set -l live_dir "/etc/letsencrypt/live"
    if test -d "$live_dir"
        for cert in $live_dir/*/
            if test -d "$cert"
                basename "$cert"
            end
        end 2>/dev/null
    end
end

# Check if we're at subcommand position
function __wasm_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

function __wasm_using_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -ge 2
        if contains -- $cmd[2] $argv
            return 0
        end
    end
    return 1
end

function __wasm_using_subcommand
    set -l cmd (commandline -opc)
    if test (count $cmd) -ge 3
        if contains -- $cmd[2] site service svc cert ssl certificate setup
            if contains -- $cmd[3] $argv
                return 0
            end
        end
    end
    return 1
end

# Global options
complete -c wasm -s h -l help -d 'Show help message'
complete -c wasm -s V -l version -d 'Show version'
complete -c wasm -s v -l verbose -d 'Enable verbose output'
complete -c wasm -s i -l interactive -d 'Run in interactive mode'
complete -c wasm -l no-color -d 'Disable colored output'

# Main commands
complete -c wasm -n __wasm_needs_command -a create -d 'Deploy a new web application'
complete -c wasm -n __wasm_needs_command -a new -d 'Deploy a new web application'
complete -c wasm -n __wasm_needs_command -a deploy -d 'Deploy a new web application'
complete -c wasm -n __wasm_needs_command -a list -d 'List deployed applications'
complete -c wasm -n __wasm_needs_command -a ls -d 'List deployed applications'
complete -c wasm -n __wasm_needs_command -a status -d 'Show application status'
complete -c wasm -n __wasm_needs_command -a info -d 'Show application status'
complete -c wasm -n __wasm_needs_command -a restart -d 'Restart an application'
complete -c wasm -n __wasm_needs_command -a stop -d 'Stop an application'
complete -c wasm -n __wasm_needs_command -a start -d 'Start an application'
complete -c wasm -n __wasm_needs_command -a update -d 'Update an application'
complete -c wasm -n __wasm_needs_command -a upgrade -d 'Update an application'
complete -c wasm -n __wasm_needs_command -a delete -d 'Delete an application'
complete -c wasm -n __wasm_needs_command -a remove -d 'Delete an application'
complete -c wasm -n __wasm_needs_command -a rm -d 'Delete an application'
complete -c wasm -n __wasm_needs_command -a logs -d 'View application logs'
complete -c wasm -n __wasm_needs_command -a site -d 'Manage web server sites'
complete -c wasm -n __wasm_needs_command -a service -d 'Manage systemd services'
complete -c wasm -n __wasm_needs_command -a svc -d 'Manage systemd services'
complete -c wasm -n __wasm_needs_command -a cert -d 'Manage SSL certificates'
complete -c wasm -n __wasm_needs_command -a ssl -d 'Manage SSL certificates'
complete -c wasm -n __wasm_needs_command -a certificate -d 'Manage SSL certificates'
complete -c wasm -n __wasm_needs_command -a setup -d 'Initial setup and configuration'

# create/new/deploy options
complete -c wasm -n '__wasm_using_command create new deploy' -s d -l domain -d 'Target domain name'
complete -c wasm -n '__wasm_using_command create new deploy' -s s -l source -d 'Source (Git URL or local path)'
complete -c wasm -n '__wasm_using_command create new deploy' -s t -l type -xa 'nextjs nodejs vite python static auto' -d 'Application type'
complete -c wasm -n '__wasm_using_command create new deploy' -s p -l port -d 'Application port'
complete -c wasm -n '__wasm_using_command create new deploy' -s w -l webserver -xa 'nginx apache' -d 'Web server to use'
complete -c wasm -n '__wasm_using_command create new deploy' -s b -l branch -d 'Git branch to deploy'
complete -c wasm -n '__wasm_using_command create new deploy' -l no-ssl -d 'Skip SSL certificate configuration'
complete -c wasm -n '__wasm_using_command create new deploy' -l env-file -d 'Path to environment file'
complete -c wasm -n '__wasm_using_command create new deploy' -l pm -l package-manager -xa 'npm pnpm bun auto' -d 'Package manager to use'

# status/info/restart/stop/start - complete with apps
complete -c wasm -n '__wasm_using_command status info restart stop start' -xa '(__wasm_get_apps)' -d 'Application'

# update/upgrade options
complete -c wasm -n '__wasm_using_command update upgrade' -xa '(__wasm_get_apps)' -d 'Application'
complete -c wasm -n '__wasm_using_command update upgrade' -s s -l source -d 'New source URL'
complete -c wasm -n '__wasm_using_command update upgrade' -s b -l branch -d 'Git branch'
complete -c wasm -n '__wasm_using_command update upgrade' -l pm -l package-manager -xa 'npm pnpm bun auto' -d 'Package manager'

# delete/remove/rm options
complete -c wasm -n '__wasm_using_command delete remove rm' -xa '(__wasm_get_apps)' -d 'Application'
complete -c wasm -n '__wasm_using_command delete remove rm' -s f -l force -d 'Skip confirmation'
complete -c wasm -n '__wasm_using_command delete remove rm' -l keep-files -d 'Keep application files'

# logs options
complete -c wasm -n '__wasm_using_command logs' -xa '(__wasm_get_apps)' -d 'Application'
complete -c wasm -n '__wasm_using_command logs' -s f -l follow -d 'Follow log output'
complete -c wasm -n '__wasm_using_command logs' -s n -l lines -d 'Number of lines'

# site subcommands
complete -c wasm -n '__wasm_using_command site' -a create -d 'Create a new site configuration'
complete -c wasm -n '__wasm_using_command site' -a list -d 'List all sites'
complete -c wasm -n '__wasm_using_command site' -a ls -d 'List all sites'
complete -c wasm -n '__wasm_using_command site' -a enable -d 'Enable a site'
complete -c wasm -n '__wasm_using_command site' -a disable -d 'Disable a site'
complete -c wasm -n '__wasm_using_command site' -a delete -d 'Delete a site'
complete -c wasm -n '__wasm_using_command site' -a remove -d 'Delete a site'
complete -c wasm -n '__wasm_using_command site' -a rm -d 'Delete a site'
complete -c wasm -n '__wasm_using_command site' -a show -d 'Show site configuration'
complete -c wasm -n '__wasm_using_command site' -a cat -d 'Show site configuration'

# site create options
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command site' -s d -l domain -d 'Domain name'
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command site' -s w -l webserver -xa 'nginx apache' -d 'Web server'
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command site' -s t -l template -xa 'proxy static' -d 'Configuration template'
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command site' -s p -l port -d 'Backend port'

# site list options
complete -c wasm -n '__wasm_using_subcommand list ls; and __wasm_using_command site' -s w -l webserver -xa 'nginx apache all' -d 'Filter by web server'

# site enable/disable/show/cat - complete with sites
complete -c wasm -n '__wasm_using_subcommand enable disable show cat; and __wasm_using_command site' -xa '(__wasm_get_sites)' -d 'Site'

# site delete options
complete -c wasm -n '__wasm_using_subcommand delete remove rm; and __wasm_using_command site' -xa '(__wasm_get_sites)' -d 'Site'
complete -c wasm -n '__wasm_using_subcommand delete remove rm; and __wasm_using_command site' -s f -l force -d 'Skip confirmation'

# service subcommands
complete -c wasm -n '__wasm_using_command service svc' -a create -d 'Create a new service'
complete -c wasm -n '__wasm_using_command service svc' -a list -d 'List managed services'
complete -c wasm -n '__wasm_using_command service svc' -a ls -d 'List managed services'
complete -c wasm -n '__wasm_using_command service svc' -a status -d 'Show service status'
complete -c wasm -n '__wasm_using_command service svc' -a info -d 'Show service status'
complete -c wasm -n '__wasm_using_command service svc' -a start -d 'Start a service'
complete -c wasm -n '__wasm_using_command service svc' -a stop -d 'Stop a service'
complete -c wasm -n '__wasm_using_command service svc' -a restart -d 'Restart a service'
complete -c wasm -n '__wasm_using_command service svc' -a logs -d 'View service logs'
complete -c wasm -n '__wasm_using_command service svc' -a delete -d 'Delete a service'
complete -c wasm -n '__wasm_using_command service svc' -a remove -d 'Delete a service'
complete -c wasm -n '__wasm_using_command service svc' -a rm -d 'Delete a service'

# service create options
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command service svc' -s n -l name -d 'Service name'
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command service svc' -s c -l command -d 'Command to execute'
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command service svc' -s d -l directory -d 'Working directory'
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command service svc' -s u -l user -d 'User to run as'
complete -c wasm -n '__wasm_using_subcommand create; and __wasm_using_command service svc' -l description -d 'Service description'

# service list options
complete -c wasm -n '__wasm_using_subcommand list ls; and __wasm_using_command service svc' -s a -l all -d 'Show all system services'

# service status/start/stop/restart - complete with services
complete -c wasm -n '__wasm_using_subcommand status info start stop restart; and __wasm_using_command service svc' -xa '(__wasm_get_services)' -d 'Service'

# service logs options
complete -c wasm -n '__wasm_using_subcommand logs; and __wasm_using_command service svc' -xa '(__wasm_get_services)' -d 'Service'
complete -c wasm -n '__wasm_using_subcommand logs; and __wasm_using_command service svc' -s f -l follow -d 'Follow log output'
complete -c wasm -n '__wasm_using_subcommand logs; and __wasm_using_command service svc' -s n -l lines -d 'Number of lines'

# service delete options
complete -c wasm -n '__wasm_using_subcommand delete remove rm; and __wasm_using_command service svc' -xa '(__wasm_get_services)' -d 'Service'
complete -c wasm -n '__wasm_using_subcommand delete remove rm; and __wasm_using_command service svc' -s f -l force -d 'Skip confirmation'

# cert subcommands
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a create -d 'Obtain a new certificate'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a obtain -d 'Obtain a new certificate'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a new -d 'Obtain a new certificate'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a list -d 'List all certificates'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a ls -d 'List all certificates'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a info -d 'Show certificate info'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a show -d 'Show certificate info'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a renew -d 'Renew certificates'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a revoke -d 'Revoke a certificate'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a delete -d 'Delete a certificate'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a remove -d 'Delete a certificate'
complete -c wasm -n '__wasm_using_command cert ssl certificate' -a rm -d 'Delete a certificate'

# cert create options
complete -c wasm -n '__wasm_using_subcommand create obtain new; and __wasm_using_command cert ssl certificate' -s d -l domain -d 'Domain name'
complete -c wasm -n '__wasm_using_subcommand create obtain new; and __wasm_using_command cert ssl certificate' -s e -l email -d 'Email for registration'
complete -c wasm -n '__wasm_using_subcommand create obtain new; and __wasm_using_command cert ssl certificate' -s w -l webroot -d 'Webroot path'
complete -c wasm -n '__wasm_using_subcommand create obtain new; and __wasm_using_command cert ssl certificate' -l standalone -d 'Use standalone mode'
complete -c wasm -n '__wasm_using_subcommand create obtain new; and __wasm_using_command cert ssl certificate' -l nginx -d 'Use Nginx plugin'
complete -c wasm -n '__wasm_using_subcommand create obtain new; and __wasm_using_command cert ssl certificate' -l apache -d 'Use Apache plugin'
complete -c wasm -n '__wasm_using_subcommand create obtain new; and __wasm_using_command cert ssl certificate' -l dry-run -d 'Test without obtaining'

# cert info/show - complete with certs
complete -c wasm -n '__wasm_using_subcommand info show; and __wasm_using_command cert ssl certificate' -xa '(__wasm_get_certs)' -d 'Certificate'

# cert renew options
complete -c wasm -n '__wasm_using_subcommand renew; and __wasm_using_command cert ssl certificate' -s d -l domain -xa '(__wasm_get_certs)' -d 'Specific domain'
complete -c wasm -n '__wasm_using_subcommand renew; and __wasm_using_command cert ssl certificate' -l force -d 'Force renewal'
complete -c wasm -n '__wasm_using_subcommand renew; and __wasm_using_command cert ssl certificate' -l dry-run -d 'Test without renewing'

# cert revoke options
complete -c wasm -n '__wasm_using_subcommand revoke; and __wasm_using_command cert ssl certificate' -xa '(__wasm_get_certs)' -d 'Certificate'
complete -c wasm -n '__wasm_using_subcommand revoke; and __wasm_using_command cert ssl certificate' -l delete -d 'Delete after revoking'

# cert delete options
complete -c wasm -n '__wasm_using_subcommand delete remove rm; and __wasm_using_command cert ssl certificate' -xa '(__wasm_get_certs)' -d 'Certificate'
complete -c wasm -n '__wasm_using_subcommand delete remove rm; and __wasm_using_command cert ssl certificate' -s f -l force -d 'Skip confirmation'

# setup subcommands
complete -c wasm -n '__wasm_using_command setup' -a init -d 'Initialize WASM directories and configuration'
complete -c wasm -n '__wasm_using_command setup' -a completions -d 'Install shell completions'
complete -c wasm -n '__wasm_using_command setup' -a permissions -d 'Check permission status'

# setup completions options
complete -c wasm -n '__wasm_using_subcommand completions; and __wasm_using_command setup' -s s -l shell -xa 'bash zsh fish' -d 'Shell type'
complete -c wasm -n '__wasm_using_subcommand completions; and __wasm_using_command setup' -s u -l user-only -d 'Install for current user only'
