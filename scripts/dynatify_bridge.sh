#!/bin/bash
# Dynatify High-Speed Music Bridge Daemon • by @uwayxt
# Bypasses macOS -1743 TCC restrictions by running in user terminal session

PIDFILE="/tmp/dynatify_bridge.pid"
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        kill "$OLD_PID" 2>/dev/null || true
    fi
fi
echo $$ > "$PIDFILE"

STATE_FILE="/tmp/dynatify_state.json"
CMD_FILE="/tmp/dynatify_cmd"

handle_cmd() {
    if [ -f "$CMD_FILE" ]; then
        CMD=$(cat "$CMD_FILE" 2>/dev/null)
        rm -f "$CMD_FILE" 2>/dev/null
        if [ -n "$CMD" ]; then
            case "$CMD" in
                playpause)
                    osascript -e 'if application "Spotify" is running then tell application "Spotify" to playpause' -e 'if application "Music" is running then tell application "Music" to playpause' 2>/dev/null
                    ;;
                next)
                    osascript -e 'if application "Spotify" is running then tell application "Spotify" to next track' -e 'if application "Music" is running then tell application "Music" to next track' 2>/dev/null
                    ;;
                previous)
                    osascript -e 'if application "Spotify" is running then tell application "Spotify" to previous track' -e 'if application "Music" is running then tell application "Music" to previous track' 2>/dev/null
                    ;;
                seek:*)
                    SEC="${CMD#seek:}"
                    osascript -e "if application \"Spotify\" is running then tell application \"Spotify\" to set player position to $SEC" -e "if application \"Music\" is running then tell application \"Music\" to set player position to $SEC" 2>/dev/null
                    ;;
                vol:*)
                    VOL="${CMD#vol:}"
                    osascript -e "if application \"Spotify\" is running then tell application \"Spotify\" to set sound volume to $VOL" -e "if application \"Music\" is running then tell application \"Music\" to set sound volume to $VOL" 2>/dev/null
                    ;;
            esac
        fi
    fi
}

query_music() {
    RAW=$(osascript << 'APPLESCRIPT' 2>/dev/null
if application "Spotify" is running then
    tell application "Spotify"
        set pState to (player state as string)
        if pState is not "stopped" then
            set tName to name of current track
            set tArtist to artist of current track
            set tAlbum to album of current track
            set tDur to (duration of current track) / 1000
            set tPos to player position
            set tVol to sound volume
            set isPlaying to (pState is "playing")
            set artURL to ""
            try
                set artURL to artwork url of current track
            end try
            return "SPOTIFY|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tDur as string) & "|||" & (tPos as string) & "|||" & (isPlaying as string) & "|||" & artURL & "|||" & (tVol as string)
        end if
    end tell
end if
if application "Music" is running then
    tell application "Music"
        set pState to (player state as string)
        if pState is not "stopped" then
            set tTrack to current track
            set tName to name of tTrack
            set tArtist to artist of tTrack
            set tAlbum to album of tTrack
            set tDur to duration of tTrack
            set tPos to player position
            set tVol to sound volume
            set isPlaying to (pState is "playing")
            return "APPLE_MUSIC|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tDur as string) & "|||" & (tPos as string) & "|||" & (isPlaying as string) & "||||||" & (tVol as string)
        end if
    end tell
end if
return "NONE"
APPLESCRIPT
)

    if [ -n "$RAW" ] && [ "$RAW" != "NONE" ]; then
        python3 -c "
import sys, json

raw = '''$RAW'''
parts = raw.split('|||')
if len(parts) >= 8:
    source = 'Spotify' if parts[0] == 'SPOTIFY' else 'Apple Music'
    title = parts[1].strip()
    artist = parts[2].strip()
    album = parts[3].strip()
    def num(s):
        try:
            return float(s.replace(',', '.').strip())
        except:
            return 0.0
    dur = num(parts[4])
    pos = num(parts[5])
    playing = parts[6].strip().lower() == 'true'
    art = parts[7].strip()
    vol = num(parts[8]) if len(parts) > 8 else 80.0
    data = {
        'source': source,
        'title': title,
        'artist': artist,
        'album': album,
        'duration': dur,
        'position': pos,
        'isPlaying': playing,
        'artworkURL': art,
        'volume': vol,
        'timestamp': '$(date +%s)'
    }
    with open('/tmp/dynatify_state.tmp', 'w') as f:
        json.dump(data, f)
" 2>/dev/null
        if [ -f "/tmp/dynatify_state.tmp" ]; then
            mv /tmp/dynatify_state.tmp "$STATE_FILE"
        fi
    else
        echo '{"isPlaying": false, "stopped": true}' > "$STATE_FILE"
    fi
}

# Main event loop
while true; do
    handle_cmd
    query_music
    for i in {1..8}; do
        handle_cmd
        sleep 0.1
    done
done
