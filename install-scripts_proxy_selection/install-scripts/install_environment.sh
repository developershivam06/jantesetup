#!/usr/bin/env bash
 
# Configuration script to set-up the Ubuntu environment for testing.
 
unalias -a
IFS=$'\n\t'
set -o nounset -o pipefail -o errtrace
trap 's=$?; echo "$0: Error $s on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
shopt -s nullglob
 
# Check whether the named argument exists as a command.
function require() { hash "$@" || exit 127; }
 
# Output all arguments to stderr.
function echoerr() { printf "%b " "$@" >&2; echo "" >&2; }

# Log an error message, and terminate with failure.
function die() { echoerr "${RED}ERROR:" "$@"; exit 1; }
 
# Log a message, depending on the configured log verbosity.
function log() { [ "$g_is_verbose" -gt 0 ] && echoerr "$@" || :; }

function main()
{
    echo "Do you want to use the porsche proxy?"
    read -rp "Proxy [yY/nN]" PROXY_VAR
    echo ""
    export PROXY_VAR
    # Explicitly state which commands are being used by this script, e.g.:
    require printf sed awk

    # Load helper files
    source config.sh
    source utils.sh
    source preconfig_proxy_apt_pypi_docker.sh
    source postconfig.sh

    if [ ! -e /usr/reboot_marker ] ; then
        promptForCredentials
        preconfig
        
        # Create reboot marker and request reboot
        sudo touch /usr/reboot_marker
        log "${GREEN}Reboot and run this script again"
    else 
        promptForCredentials
        postconfig

        # Add read permission
        sudo chmod +r /boot/vmlinuz-*
        
        # Remove reboot marker
        sudo rm /usr/reboot_marker
    fi
}
 
main "$@"
