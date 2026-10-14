cask "dynatify" do
  version "1.0.0"
  sha256 "771b734a5cbdea30cea4ee799495105ebf0af56ddde96bdbc3f8af6f550b50ab"

  url "https://github.com/Uwayxt/Dynatify/releases/download/v#{version}/Dynatify.zip"
  name "Dynatify"
  desc "Dynamic Island & Real-Time Synced Lyrics for Spotify & Apple Music on macOS"
  homepage "https://github.com/Uwayxt/Dynatify"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "Dynatify.app"

  uninstall quit: "com.uwayxt.Dynatify",
            delete: [
              "~/Library/Application Support/Dynatify",
              "~/Library/Preferences/com.uwayxt.Dynatify.plist",
            ]

  zap trash: [
    "~/Library/Application Support/Dynatify",
    "~/Library/Caches/com.uwayxt.Dynatify",
    "~/Library/Preferences/com.uwayxt.Dynatify.plist",
  ]
end
