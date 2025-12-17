# Makefile for update-fstab-uuid
# Install script and launchd plist to keep fstab UUID entries current

# Volume to prevent from auto-mounting (can be overridden)
# Example: make install VOLUME_NAME="Macintosh HD"
VOLUME_NAME ?= Macintosh HD

# Installation paths
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
LAUNCHD_DIR = /Library/LaunchDaemons

# Files
SCRIPT = update-fstab-uuid.sh
PLIST_TEMPLATE = com.mikegreiner.update-fstab-uuid.plist
PLIST_NAME = com.mikegreiner.update-fstab-uuid.plist
PLIST_DEST = $(LAUNCHD_DIR)/$(PLIST_NAME)
SCRIPT_DEST = $(BINDIR)/$(SCRIPT)

.PHONY: all install uninstall clean check-root

all:
	@echo "Usage:"
	@echo "  make install VOLUME_NAME=\"Volume Name\"  - Install script and launchd plist"
	@echo "  make uninstall                           - Remove installed files"
	@echo ""
	@echo "Current VOLUME_NAME: $(VOLUME_NAME)"

check-root:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "Error: Installation must be run as root (use sudo make install)"; \
		exit 1; \
	fi

install: check-root
	@echo "Installing update-fstab-uuid..."
	@echo "Volume to prevent from mounting: $(VOLUME_NAME)"

	# Install script
	@echo "Installing script to $(SCRIPT_DEST)..."
	@install -m 755 $(SCRIPT) $(SCRIPT_DEST)

	# Create and install plist with correct volume name
	@echo "Creating launchd plist..."
	@sed 's/VOLUME_NAME_PLACEHOLDER/$(VOLUME_NAME)/g' $(PLIST_TEMPLATE) > /tmp/$(PLIST_NAME)
	@install -m 644 /tmp/$(PLIST_NAME) $(PLIST_DEST)
	@rm /tmp/$(PLIST_NAME)

	# Load the launchd plist
	@echo "Loading launchd plist..."
	@launchctl unload $(PLIST_DEST) 2>/dev/null || true
	@launchctl load $(PLIST_DEST)

	@echo ""
	@echo "Installation complete!"
	@echo "The script will run automatically at boot to update fstab entries for: $(VOLUME_NAME)"
	@echo ""
	@echo "To run manually:"
	@echo "  sudo $(SCRIPT_DEST) \"$(VOLUME_NAME)\""
	@echo ""
	@echo "Logs are available at:"
	@echo "  /var/log/update-fstab-uuid.log"
	@echo "  /var/log/update-fstab-uuid.error.log"

uninstall: check-root
	@echo "Uninstalling update-fstab-uuid..."

	# Unload and remove launchd plist
	@if [ -f $(PLIST_DEST) ]; then \
		echo "Unloading launchd plist..."; \
		launchctl unload $(PLIST_DEST) 2>/dev/null || true; \
		rm -f $(PLIST_DEST); \
	fi

	# Remove script
	@if [ -f $(SCRIPT_DEST) ]; then \
		echo "Removing script..."; \
		rm -f $(SCRIPT_DEST); \
	fi

	@echo "Uninstallation complete!"

clean:
	@echo "Nothing to clean (source files not modified)"
