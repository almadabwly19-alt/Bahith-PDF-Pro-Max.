#!/usr/bin/env bash
set -euo pipefail
# Run this from the repository root after CREATE_PROJECT.sh has generated the project.
if [ ! -f settings.gradle.kts ] || [ ! -d app ]; then
  echo "Run ./CREATE_PROJECT.sh first."
  exit 1
fi
gradle :app:assembleDebug --no-daemon --stacktrace
echo "APK: app/build/outputs/apk/debug/app-debug.apk"
