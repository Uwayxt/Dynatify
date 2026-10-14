cask "dynatify" do
  version "1.0.0"
  sha256 "b4dfd6322393bed72a13644092864c8a217edda99703938c5e3b5cb93fe3849b"

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
