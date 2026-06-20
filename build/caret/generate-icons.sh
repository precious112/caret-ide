#!/usr/bin/env bash
# Generate Caret-branded platform app icons from build/caret/caret-logo.png.
# Intended to run in CI on Linux (needs ImageMagick + icoutils). On macOS the
# committed code.icns / code.png are generated with sips/iconutil instead.
#
# Produces (only the main app marks; VSCodium's file-type icons are left as-is):
#   src/stable/resources/win32/code.ico
#   src/stable/resources/linux/code.png
#   src/stable/resources/server/{code-192,code-512}.png, favicon.ico
#   src/stable/resources/darwin/code.icns   (if png2icns is available)
# shellcheck disable=SC2086
set -e

SRC="build/caret/caret-logo.png"
QUALITY="${QUALITY:-stable}"
RES="src/${QUALITY}/resources"

command -v convert >/dev/null || { echo "ImageMagick 'convert' not found"; exit 1; }

mkdir -p "${RES}/win32" "${RES}/linux" "${RES}/server" "${RES}/darwin"

# Windows .ico (multi-size)
convert "${SRC}" -define icon:auto-resize=256,128,96,64,48,32,24,16 "${RES}/win32/code.ico"

# Linux png + server icons
convert "${SRC}" -resize 512x512 "${RES}/linux/code.png"
convert "${SRC}" -resize 192x192 "${RES}/server/code-192.png"
convert "${SRC}" -resize 512x512 "${RES}/server/code-512.png"
convert "${SRC}" -define icon:auto-resize=64,32,16 "${RES}/server/favicon.ico"

# macOS .icns (optional — only if png2icns present; macOS uses sips/iconutil locally)
if command -v png2icns >/dev/null; then
  for s in 16 32 128 256 512 1024; do convert "${SRC}" -resize ${s}x${s} "/tmp/caret_${s}.png"; done
  png2icns "${RES}/darwin/code.icns" /tmp/caret_1024.png /tmp/caret_512.png /tmp/caret_256.png /tmp/caret_128.png /tmp/caret_32.png /tmp/caret_16.png
  rm -f /tmp/caret_*.png
fi

echo "Caret icons generated under ${RES}"
