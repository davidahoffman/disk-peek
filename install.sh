#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ "$(uname -m)" != "arm64" ]]; then
  printf 'Disk Peek currently supports Apple silicon Macs only.\n' >&2
  exit 1
fi

install_directory="${HOME}/Applications"
installed_app="$install_directory/Disk Peek.app"
build_app="$PWD/build/Xcode/Build/Products/Release/Disk Peek.app"

if [[ -e "$installed_app" ]]; then
  printf 'An installation already exists at %s\nQuit it and move it somewhere safe before installing an update. Nothing was replaced.\n' "$installed_app" >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null || ! xcrun --find xcodebuild >/dev/null 2>&1; then
  printf 'Install full Xcode and XcodeGen first. See the README for prerequisites.\n' >&2
  exit 1
fi

bash build.sh
mkdir -p "$install_directory"
# Do not overwrite if another installation appeared while the build was running.
if [[ -e "$installed_app" ]]; then
  printf 'An installation appeared during the build. Nothing was replaced.\n' >&2
  exit 1
fi
ditto "$build_app" "$installed_app"
codesign --verify --deep --strict "$installed_app"

launch_services="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$launch_services" -u "$build_app"
"$launch_services" -f "$installed_app"
pluginkit -a "$installed_app/Contents/PlugIns/DiskPeekWidget.appex"
open "$installed_app"
printf 'Installed. Right-click the desktop, choose Edit Widgets, then choose Disk Peek.\n'
