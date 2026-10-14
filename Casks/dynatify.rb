cask "dynatify" do
  version "1.0.0"
  sha256 "8e2ea324a2748fff6f80765459b89c989e7dda8c0e87773ec82dcf747be3ec78"

  url "https://github.com/Uwayxt/Dynatify/releases/download/v#{version}/Dynatify.zip"
  name "Dynatify"
  desc "Dynamic Island & Real-Time Synced Lyrics for Spotify & Apple Music on macOS"
  homepage "https://github.com/Uwayxt/Dynatify"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :sonoma

  app "Dynatify.app"

  zap trash: [
    "~/Library/Application Support/Dynatify",
    "~/Library/Caches/com.uwayxt.Dynatify",
    "~/Library/Preferences/com.uwayxt.Dynatify.plist",
  ]
end
