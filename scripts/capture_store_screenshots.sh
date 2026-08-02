#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/screenshots/play-720x1280"
LOG="${1:-}"
mkdir -p "$OUT"

if [[ -z "$LOG" ]]; then
  echo "Usage: $0 <flutter-run-log-file>"
  exit 1
fi

perl -pi -e 's/\r\n/\n/g' "$0" 2>/dev/null || true

echo "Watching $LOG for SCREENSHOT_MARK..."
echo "Saving to $OUT (final size 720x1280)"

capture() {
  local name="$1"
  local raw="$OUT/${name}.raw.png"
  local mid="$OUT/${name}.mid.png"
  local final="$OUT/${name}.png"
  xcrun simctl io booted screenshot "$raw" >/dev/null

  # iPhone 16 screenshot ~1179x2556 (taller than 9:16).
  # Crop height to 9:16 of current width, then resize to 720x1280.
  local w h crop_h
  w=$(sips -g pixelWidth "$raw" 2>/dev/null | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$raw" 2>/dev/null | awk '/pixelHeight/{print $2}')
  crop_h=$(( w * 16 / 9 ))
  if (( crop_h > h )); then
    # Source wider than 9:16 — crop width instead
    local crop_w=$(( h * 9 / 16 ))
    sips -c "$h" "$crop_w" "$raw" --out "$mid" >/dev/null
  else
    sips -c "$crop_h" "$w" "$raw" --out "$mid" >/dev/null
  fi
  sips -z 1280 720 "$mid" --out "$final" >/dev/null
  rm -f "$raw" "$mid"

  w=$(sips -g pixelWidth "$final" 2>/dev/null | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$final" 2>/dev/null | awk '/pixelHeight/{print $2}')
  echo "✅ $name (${w}x${h})"
}

tail -n +1 -F "$LOG" 2>/dev/null | while IFS= read -r line; do
  if [[ "$line" == *SCREENSHOT_MARK:* ]]; then
    name="${line##*SCREENSHOT_MARK:}"
    name="${name//$'\r'/}"
    name="$(echo "$name" | tr -d '[:space:]')"
    [[ -n "$name" ]] || continue
    capture "$name"
  fi
  if [[ "$line" == *SCREENSHOT_TOUR_DONE* ]]; then
    echo "===== DONE ====="
    ls -lh "$OUT"/*.png 2>/dev/null | grep -v '\.raw\.' || true
    # stop tail
    pkill -P $$ tail 2>/dev/null || true
    exit 0
  fi
  if [[ "$line" == *SCREENSHOT_TOUR_ERROR* ]]; then
    echo "ERROR: $line"
    exit 1
  fi
done
