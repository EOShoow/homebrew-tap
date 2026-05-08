class CodexBattery < Formula
  desc "Tiny macOS menu bar battery for Codex quota"
  homepage "https://github.com/EOShoow/codex-battery"
  url "https://github.com/EOShoow/codex-battery/archive/refs/tags/v0.1.23.tar.gz"
  sha256 "e821cd198ed58b82dc972473ea527205f7b8c2961057d1067ad95b1462618d17"
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

      Codex Battery asks the local Codex app-server for quota and reads ~/.codex for fallback stats. It does not upload your local logs.
    EOS
  end

  test do
    assert_path_exists libexec/"CodexBattery.app/Contents/MacOS/CodexBattery"
    assert_path_exists libexec/"CodexBattery.app/Contents/Resources/CodexBattery.icns"
    plist = libexec/"CodexBattery.app/Contents/Info.plist"
    assert_match "Codex Battery", shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleName' #{plist}")
  end
end
