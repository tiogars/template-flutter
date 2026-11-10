#!/usr/bin/env bash
# Builds release artifacts of the Flutter application and packages them for download.
#
# Usage: package-release.sh <android|linux>...
# Environment:
#   API_BASE_URL  Default API URL compiled into the application (default: http://localhost:8989)
#   OUTPUT_DIR    Destination directory, one sub-directory per platform (default: build/releases)
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_dir="${APP_DIR:-$script_dir/..}"
output_dir="${OUTPUT_DIR:-$app_dir/build/releases}"
api_base_url="${API_BASE_URL:-http://localhost:8989}"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <android|linux>..." >&2
  exit 64
fi
if [[ ! "$api_base_url" =~ ^https?://[^[:space:]\"\\]+$ ]]; then
  echo "API_BASE_URL must be an HTTP or HTTPS URL: $api_base_url" >&2
  exit 64
fi
api_base_url="${api_base_url%/}"

cd "$app_dir"
version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1 | tr -d '\r')"
built_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
dart_define="--dart-define=API_BASE_URL=$api_base_url"

flutter pub get

write_build_info() {
  printf '{\n  "version": "%s",\n  "apiBaseUrl": "%s",\n  "builtAt": "%s"\n}\n' \
    "$version" "$api_base_url" "$built_at" > "$1/build-info.json"
}

for platform in "$@"; do
  target="$output_dir/$platform"
  rm -rf "$target"
  mkdir -p "$target"
  case "$platform" in
    android)
      flutter build apk --release "$dart_define"
      cp build/app/outputs/flutter-apk/app-release.apk "$target/application-android.apk"
      ;;
    linux)
      flutter build linux --release "$dart_define"
      arch_dir="$(find build/linux -mindepth 1 -maxdepth 1 -type d | head -n 1)"
      arch="$(basename "$arch_dir")"
      tar -czf "$target/application-linux-$arch.tar.gz" \
        -C "$arch_dir/release" --transform 's,^bundle,application,' bundle
      ;;
    *)
      echo "Unsupported platform: $platform" >&2
      exit 64
      ;;
  esac
  write_build_info "$target"
  echo "Packaged $platform into $target"
done
