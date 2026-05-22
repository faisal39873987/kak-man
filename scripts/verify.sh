#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

clean_macos_resource_forks() {
  find . -name '._*' -delete
}

echo "==> Installing Flutter dependencies"
flutter pub get
clean_macos_resource_forks

echo "==> Running static analysis"
flutter analyze
clean_macos_resource_forks

echo "==> Running tests"
flutter test --no-pub
clean_macos_resource_forks

echo "==> Building release web artifact"
flutter build web --release --no-wasm-dry-run --no-pub

echo "==> One Shot: Nerve Runner verification passed"
