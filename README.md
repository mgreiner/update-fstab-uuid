# update-fstab-uuid

Automatically keep macOS `/etc/fstab` UUID entries current across system updates.

## Problem

When you dual-boot from multiple volumes on macOS and use `/etc/fstab` to prevent certain volumes from auto-mounting, macOS updates can change the volume UUIDs, causing your fstab entries to become stale and ineffective.

## Solution

This script automatically detects the current UUID of a specified volume and updates the corresponding `/etc/fstab` entry to prevent it from auto-mounting. A LaunchDaemon runs the script at boot time to ensure the entries stay current.

## Files

- `update-fstab-uuid.sh` - Main script that updates fstab entries
- `com.mikegreiner.update-fstab-uuid.plist` - LaunchDaemon plist template
- `Makefile` - Installation/uninstallation automation
- `update-fstab-uuid.rb` - Homebrew formula

## Installation Methods

### Method 1: Using Make

```bash
# Install (specify the volume you want to PREVENT from mounting)
sudo make install VOLUME_NAME="Macintosh HD"

# Uninstall
sudo make uninstall
```

### Method 2: Using Homebrew

```bash
# Install the formula (local development)
brew install --formula ./update-fstab-uuid.rb

# Follow the caveats instructions to configure the volume name and load the LaunchDaemon
```

### Method 3: Manual Installation

```bash
# 1. Copy script to /usr/local/bin
sudo cp update-fstab-uuid.sh /usr/local/bin/
sudo chmod 755 /usr/local/bin/update-fstab-uuid.sh

# 2. Create plist with your volume name
sed 's/VOLUME_NAME_PLACEHOLDER/Macintosh HD/g' com.mikegreiner.update-fstab-uuid.plist > /tmp/com.mikegreiner.update-fstab-uuid.plist

# 3. Install and load the plist
sudo cp /tmp/com.mikegreiner.update-fstab-uuid.plist /Library/LaunchDaemons/
sudo chmod 644 /Library/LaunchDaemons/com.mikegreiner.update-fstab-uuid.plist
sudo launchctl load /Library/LaunchDaemons/com.mikegreiner.update-fstab-uuid.plist
```

## Usage

### Automatic (at boot)
Once installed, the script runs automatically at boot to update the fstab entry.

### Manual execution
```bash
sudo /usr/local/bin/update-fstab-uuid.sh "Volume Name"
```

## Example Use Case

You have two bootable volumes:
- "Work HD" - Your work system
- "Macintosh HD" - Your personal system

When booted into "Work HD", you want to prevent "Macintosh HD" from auto-mounting:

```bash
# Install on Work HD
sudo make install VOLUME_NAME="Macintosh HD"
```

When booted into "Macintosh HD", you want to prevent "Work HD" from auto-mounting:

```bash
# Install on Macintosh HD
sudo make install VOLUME_NAME="Work HD"
```

## Logs

The script logs to:
- `/var/log/update-fstab-uuid.log` - Standard output
- `/var/log/update-fstab-uuid.error.log` - Error output

## How It Works

1. Script takes a volume name as input
2. Looks up the current device and UUID for that volume using `diskutil`
3. Reads `/etc/fstab` and checks for existing entries
4. Updates the UUID if it has changed since the last run
5. Creates a backup at `/etc/fstab.bak`

## Requirements

- macOS with APFS volumes
- Root access (sudo)
- `diskutil` (standard on macOS)

## License

MIT

## Author

Created to solve the dual-boot volume management problem on macOS.
