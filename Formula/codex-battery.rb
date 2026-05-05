class CodexBattery < Formula
  desc "Tiny macOS menu bar battery for Codex quota"
  homepage "https://github.com/EOShoow/codex-battery"
  url "https://github.com/EOShoow/codex-battery/archive/refs/tags/v0.1.16.tar.gz"
  sha256 "60cc81c9969da923e7fc57b3304a71e760842741a063f52f99d3361221cd62b2"
  license "MIT"

  depends_on :macos

  def install
    app = libexec/"CodexBattery.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath

    system "swiftc", "Sources/main.swift",
           "-framework", "AppKit",
           "-o", app/"Contents/MacOS/CodexBattery"

    (app/"Contents").install "Info.plist"
    (app/"Contents/Resources").install "Resources/CodexBattery.icns"

    (bin/"codex-battery").write <<~EOS
      #!/usr/bin/env bash
      set -euo pipefail
      open -gj "#{app}"
    EOS

    (bin/"codex-battery-login").write <<~EOS
      #!/usr/bin/env bash
      set -euo pipefail

      LABEL="local.codex.battery.menu"
      OLD_LABEL="local.codex.quota.menu"
      PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
      OLD_PLIST="$HOME/Library/LaunchAgents/$OLD_LABEL.plist"
      APP="#{app}/Contents/MacOS/CodexBattery"

      case "${1:-install}" in
        install)
          mkdir -p "$HOME/Library/LaunchAgents"
          launchctl bootout "gui/$(id -u)/$OLD_LABEL" 2>/dev/null || true
          rm -f "$OLD_PLIST"
          cat > "$PLIST" <<PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>$LABEL</string>
        <key>ProgramArguments</key>
        <array>
          <string>$APP</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>StandardOutPath</key>
        <string>/tmp/CodexBattery.out.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/CodexBattery.err.log</string>
      </dict>
      </plist>
      PLIST
          launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
          launchctl bootstrap "gui/$(id -u)" "$PLIST"
          launchctl kickstart -k "gui/$(id -u)/$LABEL"
          echo "Installed login item: $PLIST"
          ;;
        uninstall)
          launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
          launchctl bootout "gui/$(id -u)/$OLD_LABEL" 2>/dev/null || true
          rm -f "$PLIST"
          rm -f "$OLD_PLIST"
          echo "Removed login item: $PLIST"
          ;;
        *)
          echo "Usage: codex-battery-login [install|uninstall]" >&2
          exit 2
          ;;
      esac
    EOS
  end

  def caveats
    <<~EOS
      Start Codex Battery:
        codex-battery

      Install login startup:
        codex-battery-login install

      Remove login startup:
        codex-battery-login uninstall

      Codex Battery reads local Codex state from ~/.codex. It does not upload data.
    EOS
  end

  test do
    assert_path_exists libexec/"CodexBattery.app/Contents/MacOS/CodexBattery"
    assert_path_exists libexec/"CodexBattery.app/Contents/Resources/CodexBattery.icns"
    assert_match "Codex Battery", shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleName' #{libexec}/CodexBattery.app/Contents/Info.plist")
  end
end
