#!/bin/bash

# update-fstab-uuid.sh
# Updates /etc/fstab to prevent a specified volume from auto-mounting
# Usage: update-fstab-uuid.sh "Volume Name"

set -euo pipefail

# Determine Homebrew prefix for config file location
if [[ -d "/opt/homebrew" ]]; then
    BREW_PREFIX="/opt/homebrew"
elif [[ -d "/usr/local" ]]; then
    BREW_PREFIX="/usr/local"
else
    BREW_PREFIX="/usr/local"
fi

CONFIG_FILE="${BREW_PREFIX}/etc/update-fstab-uuid.conf"
FSTAB_FILE="/etc/fstab"
FSTAB_BACKUP="/etc/fstab.bak"

# Get volume name from command-line argument or config file
VOLUME_NAME="${1:-}"
if [[ -z "$VOLUME_NAME" ]] && [[ -f "$CONFIG_FILE" ]]; then
    VOLUME_NAME=$(cat "$CONFIG_FILE" | grep -v '^#' | grep -v '^[[:space:]]*$' | head -n 1)
fi

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if volume name was provided
if [[ -z "$VOLUME_NAME" ]]; then
    log_error "No volume name specified"
    log_error "Usage: $0 \"Volume Name\""
    log_error "Example: $0 \"Macintosh HD\""
    log_error ""
    log_error "Alternatively, create config file: $CONFIG_FILE"
    log_error "with the volume name on the first line"
    exit 1
fi

# Get the current UUID of the specified volume
log_info "Looking up UUID for volume: $VOLUME_NAME"

# First, find the device identifier for this volume
DEVICE=$(diskutil list | grep -A 1 "$VOLUME_NAME" | grep -v "Data" | awk '{print $NF}' | grep "^disk" | head -n 1)

if [[ -z "$DEVICE" ]]; then
    log_error "Could not find device for volume: $VOLUME_NAME"
    log_error "Available volumes:"
    diskutil list | grep -E "^\s+[0-9]+:" | grep -v "Data" | awk -F'  +' '{print "  - " $NF}'
    exit 1
fi

log_info "Found device: $DEVICE"

# Get UUID from diskutil
CURRENT_UUID=$(diskutil info "$DEVICE" | grep "Volume UUID" | awk '{print $NF}')

if [[ -z "$CURRENT_UUID" ]]; then
    log_error "Could not determine UUID for device: $DEVICE"
    exit 1
fi

log_info "Current UUID: $CURRENT_UUID"

# Create fstab if it doesn't exist
if [[ ! -f "$FSTAB_FILE" ]]; then
    log_info "Creating $FSTAB_FILE"
    touch "$FSTAB_FILE"
    chmod 644 "$FSTAB_FILE"
fi

# Backup current fstab
cp "$FSTAB_FILE" "$FSTAB_BACKUP"

# Check if there's already an entry for this UUID
if grep -q "UUID=$CURRENT_UUID" "$FSTAB_FILE"; then
    log_info "fstab already contains correct UUID entry for $VOLUME_NAME"
    exit 0
fi

# Look for any existing entry that mentions preventing mount for this volume
# We'll look for comments or old UUIDs
TEMP_FILE=$(mktemp)

# Flag to track if we found and updated an old entry
UPDATED=false

# Read fstab line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if this line has a comment identifying it as our managed entry
    if [[ "$line" =~ ^#.*"$VOLUME_NAME" ]]; then
        # Next line should be the UUID entry, but let's keep the comment
        echo "$line" >> "$TEMP_FILE"
        # Read the next line (should be the old UUID entry)
        read -r next_line || true
        # Replace it with the new UUID
        echo "UUID=$CURRENT_UUID none apfs rw,noauto 0 0" >> "$TEMP_FILE"
        UPDATED=true
        log_info "Updated existing fstab entry for $VOLUME_NAME"
    elif [[ "$line" =~ UUID=.*none.*noauto ]] && [[ "$UPDATED" == "false" ]]; then
        # This looks like a noauto entry but without our comment
        # We'll assume it might be for our volume and update it
        echo "# Prevent auto-mount of $VOLUME_NAME" >> "$TEMP_FILE"
        echo "UUID=$CURRENT_UUID none apfs rw,noauto 0 0" >> "$TEMP_FILE"
        UPDATED=true
        log_warn "Found orphaned noauto entry, updated with current $VOLUME_NAME UUID"
    else
        # Keep all other lines as-is
        echo "$line" >> "$TEMP_FILE"
    fi
done < "$FSTAB_FILE"

# If we didn't find an existing entry, add a new one
if [[ "$UPDATED" == "false" ]]; then
    log_info "Adding new fstab entry for $VOLUME_NAME"
    {
        echo ""
        echo "# Prevent auto-mount of $VOLUME_NAME"
        echo "UUID=$CURRENT_UUID none apfs rw,noauto 0 0"
    } >> "$TEMP_FILE"
fi

# Replace fstab with updated version
mv "$TEMP_FILE" "$FSTAB_FILE"
chmod 644 "$FSTAB_FILE"

log_info "fstab updated successfully"
log_info "Backup saved to: $FSTAB_BACKUP"

exit 0
