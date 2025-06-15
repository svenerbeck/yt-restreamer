#!/bin/bash

CONFIG_FILE="/app/streams.json"
CHECK_INTERVAL=3600  # Sekunden
LOG_DIR="/app/logs"

mkdir -p "$LOG_DIR"

restart_stream() {
  local NAME=$1
  local YT_URL=$2
  local RTMP_OUT=$3

  echo "[$NAME] Pulling stream URL..."
  NEW_URL=$(yt-dlp -f best -g "$YT_URL")

  if [[ -z "$NEW_URL" ]]; then
    echo "[$NAME] ERROR: Kein Stream gefunden." >> "$LOG_DIR/$NAME.log"
    return
  fi

  # Vorherigen ffmpeg-Prozess beenden, falls vorhanden
  PID_FILE="/tmp/ffmpeg_${NAME}.pid"
  if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p $OLD_PID > /dev/null; then
      echo "[$NAME] Stoppe alten Stream ($OLD_PID)"
      kill -9 $OLD_PID
    fi
    rm -f "$PID_FILE"
  fi

  echo "[$NAME] Starte neuen Stream mit URL: $NEW_URL" >> "$LOG_DIR/$NAME.log"
  ffmpeg -re -i "$NEW_URL" -c copy -f flv "$RTMP_OUT" >> "$LOG_DIR/$NAME.log" 2>&1 &
  echo $! > "$PID_FILE"
}

# Initial starten
while read -r entry; do
  NAME=$(echo "$entry" | jq -r '.name')
  YT_URL=$(echo "$entry" | jq -r '.yt_url')
  RTMP_OUT=$(echo "$entry" | jq -r '.rtmp_out')

  restart_stream "$NAME" "$YT_URL" "$RTMP_OUT"
done < <(jq -c '.[]' "$CONFIG_FILE")

# Periodisch neu prüfen
while true; do
  sleep $CHECK_INTERVAL
  while read -r entry; do
    NAME=$(echo "$entry" | jq -r '.name')
    YT_URL=$(echo "$entry" | jq -r '.yt_url')
    RTMP_OUT=$(echo "$entry" | jq -r '.rtmp_out')

    restart_stream "$NAME" "$YT_URL" "$RTMP_OUT"
  done < <(jq -c '.[]' "$CONFIG_FILE")
done