# DeepSeek Harness Desktop for Linux

[![build-appimage](https://github.com/vander-x/dsh-desktop-linux/actions/workflows/build.yml/badge.svg)](https://github.com/vander-x/dsh-desktop-linux/actions/workflows/build.yml)
[![latest release](https://img.shields.io/github/v/release/vander-x/dsh-desktop-linux?label=download&sort=semver)](https://github.com/vander-x/dsh-desktop-linux/releases/latest)
[![platform](https://img.shields.io/badge/platform-linux%20x86__64-blue)](https://github.com/vander-x/dsh-desktop-linux#requirements)
[![license](https://img.shields.io/badge/app%20code-MIT-green)](https://github.com/deepseek-ai/deepseek-harness)

An **unofficial Linux build** of [DeepSeek Harness Desktop](https://github.com/deepseek-ai/deepseek-harness) — DeepSeek's open-source agent harness — packaged as a single AppImage.

DeepSeek ships desktop installers for macOS and Windows only. The upstream repository already contains everything Linux needs: an `electron-builder` `linux: AppImage` target, a Landlock sandbox build, and a WebAssembly fallback for the LibreOfficeKit office engine. This repository carries the small platform patch that closes the remaining gaps and a CI job that rebuilds the AppImage from every new upstream release.

- **Upstream code, no product changes** — 22 files patched, all listed and explained below.
- **Reproducible** — pinned upstream tag, patch applied on a clean checkout, build in public CI.
- **Auditable** — every claim in this README has the command that proves it.
- **Verified before publishing** — no release is produced from a developer machine; CI runs the packaged smoke and the AppImage check first.
- **Self-updating repository** — a daily workflow checks `@deepseek-ai/dsh@latest` and publishes a new release when upstream moves.

---

## Quick start

```sh
# One line: fetch, install the launcher and the desktop entry
curl -fsSL https://raw.githubusercontent.com/vander-x/dsh-desktop-linux/master/install.sh | bash

# Or manually, from https://github.com/vander-x/dsh-desktop-linux/releases/latest
chmod +x deepseek-harness-*-x86_64-unsigned.AppImage
./deepseek-harness-*-x86_64-unsigned.AppImage --no-sandbox
```

Then open **DeepSeek Harness** from the application menu, or run `dsh-desktop`.

First launch asks you to **sign in** to a DeepSeek account or paste an API key; that credential is what the agent uses. Without it the runtime stops with `MISSING_CREDENTIAL`, by design.

## Requirements

Measured from the shipped binaries with `objdump -T` and `ldd`, not guessed:

| Dependency | Needed | Where it comes from |
| --- | --- | --- |
| glibc | 2.28 | highest symbol version in `resources/runtime/bin/node` |
| libstdc++ | `GLIBCXX_3.4.21` (GCC 5+) | `node`, `sharp` |
| Desktop stack | GTK3, NSS, ALSA, ATK, Cairo | `ldd deepseek-harness` |
| Display | X11 or Wayland | Electron |
| FUSE | 2 (or `--appimage-extract-and-run`) | AppImage runtime |
| Architecture | x86_64 | only `linux-x64` is built |

Works on Ubuntu 20.04+, Debian 10+, Fedora 30+, openSUSE 15.2+, Arch, Mint 20+.
Does not work on glibc < 2.28 (CentOS 7, Ubuntu 16.04), headless servers, or ARM.

## How the build works

```
        ┌──────────────────────────────┐
        │ npm view @deepseek-ai/dsh    │  resolves the release to build
        │   @latest → 0.2.2-rc.5       │  (tag: dsh-v0.2.2-rc.5)
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ git clone --branch <tag>     │  pristine upstream checkout
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ git apply patches/           │  22 files, Linux platform support
        │   linux-x64.patch            │
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ pnpm install --frozen-lockfile│
        │ pnpm package:linux:x64        │  build → prepare runtime → package
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ packaged smoke (runs the     │  node, sharp, pty, pnpm, Office,
        │ real Host on real Node)      │  CLI plugin install/remove
        └──────────────┬───────────────┘
                       ▼
        ┌──────────────────────────────┐
        │ verify-appimage.sh           │  extract, dump config, boot window
        └──────────────┬───────────────┘
                       ▼
              GitHub Release (v<version>)
```

`scripts/build.sh` is the whole recipe and is the same command the workflow runs. Locally:

```sh
scripts/build.sh                 # builds whatever npm "latest" points to
scripts/build.sh dsh-v0.2.2-rc.5 # or an explicit upstream tag
scripts/verify-appimage.sh dist/*.AppImage
```

## Project layout

```
.
├── .github/workflows/build.yml   daily check + manual dispatch, builds and publishes the release
├── patches/linux-x64.patch       22-file patch against the upstream tag (the entire port)
├── scripts/build.sh              clone → patch → install → package → dist/
├── scripts/verify-appimage.sh    headless verification of a produced AppImage
├── install.sh                    downloads the latest release, installs launcher + desktop entry
└── README.md
```

Nothing else is tracked. The 244 MB upstream checkout and the 358 MB AppImage live in `.build/` and
`dist/`, both git-ignored.

## What the patch changes

Every hunk is upstream code; the columns say what breaks without it.

| Files | Change | Why it is needed |
| --- | --- | --- |
| `package-target.ts`, `desktop-build-paths.mjs`, `desktop-toolchain-preflight.ts`, `desktop-upload-plan.ts`, `*.d.mts` | register a `linux-x64` target (`--linux`, Electron binary at `electron`) | upstream accepts only `mac-arm64`, `mac-x64`, `win-x64` |
| `apps/desktop/package.json` | `package:linux:x64` script | entry point for the target above |
| `electron-builder-config.mjs` | `executableName: deepseek-harness`; skip the update policy manifest on Linux; unpack `**/dsh/**` | electron-builder derived the invalid name `@deepseek-aidsh-desktop`; the policy service does not exist for Linux; Node cannot read inside ASAR |
| `desktop-package-environment.mjs`, `desktop-auto-update-environment.mjs` | Linux is unsigned and has no update feed | release-only settings (`DSH_DESKTOP_MANDATORY_UPDATE_*`, COS buckets) are unavailable locally |
| `prepare-runtime.ts` | download standalone Node 24.21.0 into `runtime/bin/node` | Electron's Linux binary leaks its own GLib into the process and crashes sharp/libvips ([electron#46323](https://github.com/electron/electron/issues/46323)) |
| `apps/desktop/src/main.ts` | run the Host on `runtime/bin/node`; point it at `app.asar.unpacked/dsh` on Linux | same crash fix; real Node cannot read ASAR paths |
| `apps/desktop-host/src/runtime-layout.ts` (new), `cli.ts`, `index.ts` | resolve the runtime directory for dev, ASAR and unpacked layouts | `../runtime` resolved to `app.asar.unpacked/runtime` after the move |
| `apps/desktop/cli/dsh` | Linux branch using the bundled Node | the launcher was hardcoded to `Contents/MacOS/DeepSeek Harness` |
| `smoke-packaged-runtime.ts`, `tests/fixtures/pnpm-smoke.mjs` | run the packaged smoke on the real Node and accept it | the smoke asserted Electron-only `process.versions.electron` / `--expose-internals` |

Full diff: `patches/linux-x64.patch` (607 lines, 22 files).

## Audit it yourself

```sh
# 1. The patch applies to a pristine upstream tag
git clone --depth 1 --branch dsh-v0.2.2-rc.5 https://github.com/deepseek-ai/deepseek-harness.git up
git -C up apply --check patches/linux-x64.patch     # silent = clean

# 2. The patch touches only platform plumbing, never product logic
grep '^diff --git' patches/linux-x64.patch | wc -l   # 22
grep -E '^\+.*(eval|exec\(|child_process|https?://)' patches/linux-x64.patch | wc -l

# 3. The artifact is a real AppImage with the expected runtime
scripts/verify-appimage.sh dist/*.AppImage
# → cli: dump-config ok (1287 lines)
# → boot: window opened without fatal error

# 4. The packaged runtime loads native modules on real Node
#    (this is what the pipeline's smoke prints on success)
# → {"node":"24.21.0","platform":"linux","arch":"x64","koffi":true,"sharp":true,
#    "html":true,"pty":true,"pnpm":true,"grep":true,"glob":true}

# 5. The agent stack initializes and stops only for credentials
resources/runtime/cli/bin/dsh --profile headless "hello"
# → dsh: MISSING_CREDENTIAL: llm-deepseek: no API key for provider route "deepseek-official"
```

The CI log of any release contains the same smoke output plus the Office round trip
(DOCX/XLSX/PPTX → PDF), because the packaging pipeline runs them before publishing.

## Updating

The repository updates itself:

- `schedule: 0 6 * * *` (03:00 in UTC−3) reads `npm view @deepseek-ai/dsh@latest`, and if that version
  has no release yet, rebuilds and publishes `v<version>`.
- GitHub disables scheduled runs after 60 days without repository activity; re-enable under
  *Actions → build-appimage* or push any commit.
- Manual rebuild: `gh workflow run build-appimage -R vander-x/dsh-desktop-linux`.

Your installed copy does not auto-update (there is no upstream Linux feed). Re-run `install.sh`, or
download the new release.

## Known limitations

- **Unofficial and unsigned.** No Apple-style notarization, no DeepSeek signing key.
- **`--no-sandbox`.** An AppImage cannot keep the SUID bit on `chrome-sandbox`, so the launcher
  disables Chromium's sandbox. Run it from a trusted location.
- **Office runs on the WASM engine.** The native Linux engine exists on npm as
  `@deepseek-ai/libreoffice-kit-linux-x64-glibc`, but upstream's selector asks for `linux-x64` and
  falls back to WebAssembly. Slower, same output formats.
- **Electron-only extensions.** The Host runs on the bundled Node, so plugins that call Electron
  APIs from the Host process will not work.
- **Login shell probe warning** (`desktop login shell: /usr/bin/bash failed`) appears on some
  setups; the terminal feature still opens a shell.

## FAQ

**Is this official?** No. It is a community build; the application code is DeepSeek's (MIT).
**Where do the binaries come from?** GitHub Actions builds them from the upstream tag named in the
release notes. The workflow, patch and scripts are in this repository.
**Does it phone home?** It runs DeepSeek's own app; upstream telemetry settings apply
(`DSH_TELEMETRY_MODE=DISABLED` disables it).
**Can I keep using my DeepSeek account?** Yes — the app signs in normally; an API key also works.
**Why not just use the web app?** This is the desktop shell: local files, terminal, tray, background
tasks. Same UI, real process.
**Will my plugins work?** Plugins that only use the harness APIs do. Plugins that call Electron APIs
from the Host process do not, because the Host runs on Node here.

## License and credits

All application code belongs to DeepSeek AI and is MIT licensed
([deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)). This repository
contains only the platform patch, the build/verify scripts and the packaging workflow. If DeepSeek
ever publishes a Linux build, use theirs instead.
