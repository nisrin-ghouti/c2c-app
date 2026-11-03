#!/usr/bin/env bash
# Launch c2c-app on an Android emulator (starts one if needed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

EMULATOR_ID="${C2C_ANDROID_EMULATOR:-Medium_Phone_API_36.1}"
BOOT_TIMEOUT_SEC="${C2C_ANDROID_BOOT_TIMEOUT:-120}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter not found on PATH" >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "error: missing .env at $ROOT (copy from .env.example if you have one)" >&2
  exit 1
fi

android_device_id() {
  flutter devices --machine 2>/dev/null \
    | python3 -c '
import json, sys
try:
    devices = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for d in devices:
    if d.get("targetPlatform", "").startswith("android") and d.get("id"):
        print(d["id"])
        break
' 2>/dev/null || true
}

DEVICE_ID="$(android_device_id)"

if [[ -z "$DEVICE_ID" ]]; then
  echo "No Android device found. Launching emulator: $EMULATOR_ID"
  flutter emulators --launch "$EMULATOR_ID" >/dev/null

  echo -n "Waiting for emulator"
  deadline=$((SECONDS + BOOT_TIMEOUT_SEC))
  while (( SECONDS < deadline )); do
    DEVICE_ID="$(android_device_id)"
    if [[ -n "$DEVICE_ID" ]]; then
      echo
      break
    fi
    echo -n "."
    sleep 2
  done

  if [[ -z "$DEVICE_ID" ]]; then
    echo
    echo "error: timed out after ${BOOT_TIMEOUT_SEC}s waiting for an Android device" >&2
    exit 1
  fi
fi

echo "Using Android device: $DEVICE_ID"
flutter pub get
exec flutter run -d "$DEVICE_ID" "$@"
