#!/usr/bin/env sh

RED='\033[0;31m'
YELLOW='\033[0;33m'
DARK_GRAY='\033[90m'
LIGHT_CYAN='\033[0;96m'
LIGHT_GREEN='\033[0;92m'
DARK_CYAN='\033[0;36m'
NO_COLOR='\033[0m'
BOLD='\033[1m'

# =========
# Logging Functions
# =========

log() {
    local level="$1"
    local color="$2"
    local message="$3"
    printf '%b\n' "${color}${BOLD}${level}${NO_COLOR} ${NO_COLOR}${message}"
}

error() {
    log "ERROR  " "$RED" "$1"
}

debug() {
    log "DEBUG  " "$DARK_CYAN" "$1"
}

warning() {
    log "WARNING" "$YELLOW" "$1"
}

prompt() {
    read -p "$(printf '%b' "${LIGHT_GREEN}${BOLD}PROMPT ${NO_COLOR} ${NO_COLOR}${1} ")" PLATFORM
}

# =========
# Start
# =========

warning "This script is intended for developers only, please ensure you have a jailbroken device with palera1n and have TrollStore installed before proceeding."
prompt "Enter custom platform (leave empty for default 'package'): "

if [ -z "$PLATFORM" ]; then
    PLATFORM="package"
fi

if [ "$PLATFORM" = "package" ]; then
    debug "Running 'make package'"
    make package >/dev/null 2>&1
else
    debug "Running 'make PLATFORM=${PLATFORM} SCHEME=palera1nLoader package'"
    make PLATFORM="${PLATFORM}" SCHEME=palera1nLoader package >/dev/null 2>&1
fi

if [ $? -ne 0 ]; then
    error "Make command failed, please debug compilation errors manually with the makefile"
    exit 1
else
    debug "Make command completed successfully, attempting to install to device..."
fi

if [ ! -f packages/palera1nLoader.ipa ]; then
    error "'packages/palera1nLoader.ipa' does not exist?"
    exit 1
fi

debug "Uploading 'palera1nLoader.ipa' to 'root@127.0.0.1:/var/root/palera1nLoader.ipa'"

scp_output=$(scp -O -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "ProxyCommand=inetcat 44" packages/palera1nLoader.ipa root@127.0.0.1:/var/root/palera1nLoader.ipa 2>&1)
if [ $? -ne 0 ]; then
    echo "$scp_output" | while IFS= read -r line; do
        error "$line"
    done
    exit 1
else
    echo "$scp_output" | while IFS= read -r line; do
        debug "$line"
    done
fi

warning "Application will not work with iOS 14 and below! Make sure you're on the correct versions"

ssh_output=$(ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "ProxyCommand=inetcat 44" root@127.0.0.1 << 'EOF'
    uicache -u /cores/binpack/Applications/palera1nLoader.app
    /private/var/containers/Bundle/Application/*/TrollStore.app/trollstorehelper install custom /var/root/palera1nLoader.ipa
    if [ $? -ne 0 ]; then
        error "trollstorehelper command failed"
        exit 1
    fi

    echo "Installed /var/root/palera1nLoader.ipa via TrollStore"

    rm -rf /var/root/palera1nLoader.ipa >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to remove /var/root/palera1nLoader.ipa"
        exit 1
    fi
    
    echo "Removed /var/root/palera1nLoader.ipa"
EOF
)

if [ $? -ne 0 ]; then
    echo "$ssh_output" | while IFS= read -r line; do
        error "$line"
    done
else
    echo "$ssh_output" | while IFS= read -r line; do
        debug "$line"
    done
fi

debug "Done? You somehow made it here congrats big nerd"

