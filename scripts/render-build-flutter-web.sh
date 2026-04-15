#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-.}"
SDK_DIR="${HOME}/render-flutter-sdk"
API_BASE_URL="${SPETO_API_BASE_URL:?SPETO_API_BASE_URL must be set}"

if [ ! -x "${SDK_DIR}/bin/flutter" ]; then
  rm -rf "${SDK_DIR}"
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "${SDK_DIR}"
fi

export PATH="${SDK_DIR}/bin:${PATH}"

flutter config --enable-web >/dev/null

pushd "${APP_DIR}" >/dev/null
flutter pub get
flutter build web --release --dart-define=SPETO_API_BASE_URL="${API_BASE_URL}"
popd >/dev/null
