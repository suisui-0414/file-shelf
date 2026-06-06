#!/bin/bash
set -e
cd "$(dirname "$0")"

BUNDLE_NAME="FileShelf"
APP_DIR="build/${BUNDLE_NAME}.app"

# Compile
swift build -c release

# Assemble .app bundle
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"

cp ".build/release/${BUNDLE_NAME}" "${APP_DIR}/Contents/MacOS/${BUNDLE_NAME}"
cp "FileShelf/Info.plist" "${APP_DIR}/Contents/Info.plist"

# Ad-hoc sign
codesign --force --sign - "${APP_DIR}"

# 既存プロセスを終了してから再起動
pkill -x "${BUNDLE_NAME}" 2>/dev/null || true
sleep 0.3
open "${APP_DIR}"
echo "Launched: ${APP_DIR}"
