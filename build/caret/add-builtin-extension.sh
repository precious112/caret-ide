#!/usr/bin/env bash
# Inject the pre-built Caret extension into the freshly-built app as a BUILT-IN
# (system) extension. Anything under <app>/resources/app/extensions is loaded from
# disk at startup, pre-installed and non-uninstallable — no marketplace needed.
#
# We ship only the COMPILED extension (the `extension/` folder from the .vsix); the
# extension's source lives in its own repo. The extension id is kept in sync with the
# Open VSX id (caretAI.caret) so VS Code can auto-update the built-in in place from
# Open VSX when a newer version is published.
#
# Inputs (env):
#   OS_NAME       osx | linux | windows   (set by dev/build.sh)
#   VSCODE_ARCH   arm64 | x64 | ...        (set by dev/build.sh)
#   CARET_VSIX    path to the Caret .vsix  (default: ./caret.vsix)
#   EXTENSION_ID  built-in folder name     (default: caretAI.caret)
# shellcheck disable=SC1091

set -e

CARET_VSIX="${CARET_VSIX:-./caret.vsix}"
EXTENSION_ID="${EXTENSION_ID:-caretAI.caret}"

if [[ ! -f "${CARET_VSIX}" ]]; then
  echo "ERROR: Caret vsix not found at '${CARET_VSIX}'. Set CARET_VSIX or place caret.vsix at repo root." >&2
  exit 1
fi

# Resolve the packaged app's resources/app directory for this platform.
NAME_SHORT="$( node -p "require('./vscode/product.json').nameShort" )"

case "${OS_NAME}" in
  osx)     APP_ROOT="VSCode-darwin-${VSCODE_ARCH}/${NAME_SHORT}.app/Contents/Resources/app" ;;
  windows) APP_ROOT="VSCode-win32-${VSCODE_ARCH}/resources/app" ;;
  *)       APP_ROOT="VSCode-linux-${VSCODE_ARCH}/resources/app" ;;
esac

if [[ ! -d "${APP_ROOT}" ]]; then
  echo "ERROR: built app not found at '${APP_ROOT}'. Run the build first." >&2
  exit 1
fi

DEST="${APP_ROOT}/extensions/${EXTENSION_ID}"
echo "Bundling Caret extension as built-in -> ${DEST}"

# Extract the vsix's extension/ payload into the built-in extensions dir.
TMP_DIR="$( mktemp -d )"
trap 'rm -rf "${TMP_DIR}"' EXIT
unzip -q "${CARET_VSIX}" "extension/*" -d "${TMP_DIR}"

rm -rf "${DEST}"
mkdir -p "${DEST}"
cp -R "${TMP_DIR}/extension/." "${DEST}/"

# VS Code treats a built-in as valid if it has a package.json; verify.
if [[ ! -f "${DEST}/package.json" ]]; then
  echo "ERROR: extension package.json missing after copy — vsix layout unexpected." >&2
  exit 1
fi

echo "Caret extension bundled as built-in ($( node -p "require('./${DEST}/package.json').publisher + '.' + require('./${DEST}/package.json').name + '@' + require('./${DEST}/package.json').version" ))"
