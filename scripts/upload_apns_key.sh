#!/usr/bin/env bash
# Загрузка APNs Auth Key (.p8) в Firebase для iOS push.
#
# Использование:
#   ./scripts/upload_apns_key.sh /path/to/AuthKey_XXXXXXXXXX.p8 KEY_ID
#
# Team ID берётся из Xcode-проекта (H9N9Q2MUA8).
# KEY_ID — 10 символов из имени файла AuthKey_XXXXXXXXXX.p8 или из Apple Developer → Keys.

set -euo pipefail

P8_PATH="${1:-}"
KEY_ID="${2:-}"
TEAM_ID="H9N9Q2MUA8"
PROJECT_ID="handy-35312"
IOS_APP_ID="1:408622761678:ios:ef7df3842115c64e19f29f"

if [[ -z "$P8_PATH" || -z "$KEY_ID" ]]; then
  echo "Usage: $0 /path/to/AuthKey_XXXXXXXXXX.p8 KEY_ID"
  echo ""
  echo "1) developer.apple.com → Certificates, Identifiers & Profiles → Keys → +"
  echo "2) Включите Apple Push Notifications service (APNs)"
  echo "3) Скачайте .p8 (один раз) и скопируйте Key ID"
  echo "4) Запустите этот скрипт"
  echo ""
  echo "Либо загрузите вручную:"
  echo "  https://console.firebase.google.com/project/${PROJECT_ID}/settings/cloudmessaging"
  exit 1
fi

if [[ ! -f "$P8_PATH" ]]; then
  echo "File not found: $P8_PATH"
  exit 1
fi

# Из имени AuthKey_AB12CD34EF.p8 можно взять Key ID автоматически
BASENAME="$(basename "$P8_PATH")"
if [[ "$KEY_ID" == "auto" && "$BASENAME" =~ AuthKey_([A-Z0-9]+)\.p8 ]]; then
  KEY_ID="${BASH_REMATCH[1]}"
fi

echo "Project:  $PROJECT_ID"
echo "iOS App:  $IOS_APP_ID"
echo "Team ID:  $TEAM_ID"
echo "Key ID:   $KEY_ID"
echo "Key file: $P8_PATH"
echo ""
echo "Firebase CLI не умеет загружать APNs .p8 автоматически."
echo "Откройте консоль и загрузите ключ:"
echo ""
echo "  https://console.firebase.google.com/project/${PROJECT_ID}/settings/cloudmessaging"
echo ""
echo "Apple app configuration → APNs Authentication Key → Upload"
echo "  • файл: $P8_PATH"
echo "  • Key ID: $KEY_ID"
echo "  • Team ID: $TEAM_ID"
echo ""

# macOS: открыть страницу и показать файл в Finder
if command -v open >/dev/null 2>&1; then
  open "https://console.firebase.google.com/project/${PROJECT_ID}/settings/cloudmessaging"
  open -R "$P8_PATH"
fi
