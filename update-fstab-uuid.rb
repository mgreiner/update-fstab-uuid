class UpdateFstabUuid < Formula
  desc "Keep macOS fstab UUID entries current across system updates"
  homepage "https://github.com/mgreiner/update-fstab-uuid"
  url "https://github.com/mgreiner/update-fstab-uuid/archive/refs/heads/main.tar.gz"
  version "1.0.0"

  def install
    # Install the main script
    bin.install "update-fstab-uuid.sh"

    # Install the plist template to share directory for reference
    (share/"update-fstab-uuid").install "com.mikegreiner.update-fstab-uuid.plist"
  end

  def post_install
    # Prompt for volume name and save to config file
    config_file = etc/"update-fstab-uuid.conf"

    unless config_file.exist?
      print "\n"
      print "Enter the name of the volume to prevent from auto-mounting\n"
      print "(e.g., 'Macintosh HD', 'Work HD', etc.): "
      volume_name = $stdin.gets&.chomp

      if volume_name && !volume_name.empty?
        config_file.write("# Volume name for update-fstab-uuid\n#{volume_name}\n")
        ohai "Configuration saved to #{config_file}"
        ohai "To start the service, run: brew services start update-fstab-uuid"
      else
        opoo "No volume name provided. You can configure it later by editing #{config_file}"
      end
    end
  end

  service do
    run [opt_bin/"update-fstab-uuid.sh"]
    run_type :immediate
    require_root true
    log_path "/var/log/update-fstab-uuid.log"
    error_log_path "/var/log/update-fstab-uuid.error.log"
  end

  def caveats
    config_file = etc/"update-fstab-uuid.conf"
    volume_name = config_file.exist? ? config_file.read.lines.grep_v(/^#/).first&.chomp : nil

    s = <<~EOS
      Configuration saved to: #{config_file}
    EOS

    if volume_name && !volume_name.empty?
      s += <<~EOS
        Volume configured: #{volume_name}

        To start the service and enable it at boot:
          brew services start update-fstab-uuid

        This will prompt for your password to install and load the LaunchDaemon.
      EOS
    else
      s += <<~EOS
        No volume configured yet. Edit #{config_file} and add the volume name.

        Then start the service:
          brew services start update-fstab-uuid
      EOS
    end

    s += <<~EOS

      To run manually:
        sudo #{opt_bin}/update-fstab-uuid.sh "Volume Name"

      Logs:
        /var/log/update-fstab-uuid.log
        /var/log/update-fstab-uuid.error.log

      To stop the service:
        brew services stop update-fstab-uuid
    EOS

    s
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
