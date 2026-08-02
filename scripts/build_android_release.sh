#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Flutter pub get"
flutter pub get

DEFINES=()
if [[ -f dart_defines.json ]]; then
  DEFINES+=(--dart-define-from-file=dart_defines.json)
else
  echo "⚠️ dart_defines.json не найден — карты/DaData могут быть без ключей"
fi

echo "==> Build Android App Bundle (Google Play / RuStore)"
flutter build appbundle --release "${DEFINES[@]}"

echo "==> Build Android APK (RuStore fallback / sideload)"
flutter build apk --release "${DEFINES[@]}"

OUT_DIR="build/store-release"
mkdir -p "$OUT_DIR"

AAB="build/app/outputs/bundle/release/app-release.aab"
APK="build/app/outputs/flutter-apk/app-release.apk"

VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
SAFE_VERSION="${VERSION//+/-}"

if [[ -f "$AAB" ]]; then
  cp "$AAB" "$OUT_DIR/nerobot-${SAFE_VERSION}-play.aab"
  cp "$AAB" "$OUT_DIR/nerobot-${SAFE_VERSION}-rustore.aab"
  echo "✅ AAB ready"
else
  echo "❌ AAB not found"
  exit 1
fi

if [[ -f "$APK" ]]; then
  cp "$APK" "$OUT_DIR/nerobot-${SAFE_VERSION}-rustore.apk"
  echo "✅ APK ready"
else
  echo "❌ APK not found"
  exit 1
fi

echo ""
echo "Store artifacts ($VERSION):"
ls -lh "$OUT_DIR"
