class CodexBattery < Formula
  desc "Tiny macOS menu bar battery for Codex quota"
  homepage "https://github.com/EOShoow/codex-battery"
  url "https://github.com/EOShoow/codex-battery/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "f0eab443ebb432865eb73d24d4805c7e2dfdda9d99780e6179a1f83359a3020e"
  license "MIT"

  depends_on :macos

  def install
    app = libexec/"CodexQuota.app"
    (app/"Contents/MacOS").mkpath

    system "swiftc", "Sources/main.swift",
           "-framework", "AppKit",
           "-o", app/"Contents/MacOS/CodexQuota"

    (app/"Contents").install "Info.plist"

    (bin/"codex-battery").write <<~EOS
      #!/usr/bin/env bash
      set -euo pipefail
      open -gj "#{app}"
    EOS

    (bin/"codex-battery-login").write <<~EOS
      #!/usr/bin/env bash
      set -euo pipefail

      LABEL="local.codex.quota.menu"
      PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
      APP="#{app}/Contents/MacOS/CodexQuota"

      case "${1:-install}" in
        install)
          mkdir -p "$HOME/Library/LaunchAgents"
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
        <string>/tmp/CodexQuota.out.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/CodexQuota.err.log</string>
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
          rm -f "$PLIST"
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
    assert_path_exists libexec/"CodexQuota.app/Contents/MacOS/CodexQuota"
    assert_match "Codex Battery", shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleName' #{libexec}/CodexQuota.app/Contents/Info.plist")
  end
end

