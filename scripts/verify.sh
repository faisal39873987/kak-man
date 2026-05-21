#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Installing Flutter dependencies"
flutter pub get

echo "==> Running static analysis"
flutter analyze

echo "==> Running tests"
flutter test

echo "==> Building release web artifact"
flutter build web --release

echo "==> One Shot: Nerve Runner verification passed"
