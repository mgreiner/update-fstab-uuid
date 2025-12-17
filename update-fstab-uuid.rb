class UpdateFstabUuid < Formula
  desc "Keep macOS fstab UUID entries current across system updates"
  homepage "https://github.com/yourusername/update-fstab-uuid"
  url "file://#{Dir.pwd}" # For local development; update with actual URL when published
  version "1.0.0"

  def install
    # Install the main script
    bin.install "update-fstab-uuid.sh"

    # Install the plist template to share directory for reference
    (share/"update-fstab-uuid").install "com.mikegreiner.update-fstab-uuid.plist"
  end

  def caveats
    <<~EOS
      To complete installation, you need to:

      1. Customize the LaunchDaemon plist with the volume name you want to prevent from auto-mounting:

         sudo sed 's/VOLUME_NAME_PLACEHOLDER/Macintosh HD/g' \\
           #{share}/update-fstab-uuid/com.mikegreiner.update-fstab-uuid.plist > \\
           /tmp/com.mikegreiner.update-fstab-uuid.plist

         (Replace "Macintosh HD" with your target volume name)

      2. Install the plist to LaunchDaemons:

         sudo cp /tmp/com.mikegreiner.update-fstab-uuid.plist \\
           /Library/LaunchDaemons/com.mikegreiner.update-fstab-uuid.plist

         sudo chmod 644 /Library/LaunchDaemons/com.mikegreiner.update-fstab-uuid.plist

      3. Load the LaunchDaemon:

         sudo launchctl load /Library/LaunchDaemons/com.mikegreiner.update-fstab-uuid.plist

      The script will now run automatically at boot to keep your fstab entries current.

      To run manually:
         sudo #{bin}/update-fstab-uuid.sh "Volume Name"

      Logs are written to:
         /var/log/update-fstab-uuid.log
         /var/log/update-fstab-uuid.error.log

      To uninstall the LaunchDaemon:
         sudo launchctl unload /Library/LaunchDaemons/com.mikegreiner.update-fstab-uuid.plist
         sudo rm /Library/LaunchDaemons/com.mikegreiner.update-fstab-uuid.plist
    EOS
  end

  test do
    # Test that the script exists and is executable
    assert_predicate bin/"update-fstab-uuid.sh", :exist?
    assert_predicate bin/"update-fstab-uuid.sh", :executable?

    # Test that running without arguments shows usage
    output = shell_output("#{bin}/update-fstab-uuid.sh 2>&1", 1)
    assert_match "Usage:", output
  end
end
