# Caret IDE

Caret IDE is a standalone, branded desktop IDE — a [VSCodium](https://github.com/VSCodium/vscodium)-based
build of VS Code (OSS) that ships the **Caret** extension (`caretAI.caret`) pre-installed as a
built-in. It is a homogeneous product: no Microsoft branding, telemetry stripped, the
extension gallery points at [Open VSX](https://open-vsx.org), and Caret is always present.

This repository contains only the **build tooling** (seeded from VSCodium). The VS Code OSS
source is downloaded at build time; the Caret extension is downloaded from Open VSX and
injected as a built-in. The extension's own source lives in its separate repo.

## How it's branded

- **`product.json`** (repo root) carries the Caret identity (`nameShort`/`nameLong`/
  `applicationName=caret`, `dataFolderName=.caret`, `urlProtocol=caret`, fresh Windows
  AppId GUIDs, `darwinBundleIdentifier=com.caretai.caret`, …). VSCodium's
  `prepare_vscode.sh` merges this **last**, so these values win.
- **Icons** live in `src/stable/resources/{darwin,linux,win32}` (Caret marks). Windows
  `.ico` is generated in CI from `build/caret/caret-logo.png` (macOS lacks the tooling).
- **Build env** defaults are set in `dev/build.sh` (`APP_NAME=Caret`, `BINARY_NAME=caret`,
  `ORG_NAME=caretAI`, `DISABLE_UPDATE=yes`). Override via environment in CI.

## Bundled extension (built-in + auto-update)

`build/caret/add-builtin-extension.sh` copies the **compiled** Caret extension (the
`extension/` payload of the `.vsix`) into the freshly-built app at
`…/resources/app/extensions/caretAI.caret/`. Anything there is a built-in: pre-installed,
non-uninstallable, no marketplace needed.

Because the bundled id (`caretAI.caret`) matches the Open VSX id, VS Code auto-updates the
built-in in place when a newer version is published to Open VSX — no IDE reinstall required.

## Building

### CI (all platforms — recommended)

`.github/workflows/build.yml` builds macOS (arm64+x64), Linux (x64) and Windows (x64),
downloads the Caret extension from Open VSX, injects it, and uploads installers. **This is
the only way to produce the Windows installer** (Inno Setup is Windows-only). Run it from the
Actions tab (workflow_dispatch); optionally tick "release" for a draft GitHub Release.

### Local (macOS / Linux)

```bash
# 1. Provide the Caret extension vsix at repo root (download from Open VSX or build it):
#    curl -fsSL "$(curl -fsSL https://open-vsx.org/api/caretAI/caret/latest \
#      | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).files.download))')" -o caret.vsix
# 2. Build + package:
./dev/build.sh -p
# Outputs land in ./assets (dmg/zip on macOS; deb/rpm/tar.gz on Linux).
```

Prerequisites: Node 22, Python 3, `jq`, plus the usual VS Code native build deps. See
VSCodium's [docs/howto-build.md](docs/howto-build.md).

## Updating from upstream VSCodium

```bash
git fetch upstream
git merge upstream/master   # resolve conflicts, mostly in product.json / dev/build.sh
```

## Signing

Builds are unsigned for now. macOS users: right-click → Open (or
`xattr -dr com.apple.quarantine /Applications/Caret.app`). Windows: SmartScreen → "Run
anyway". Add Apple notarization + Windows Authenticode before any wider rollout.
