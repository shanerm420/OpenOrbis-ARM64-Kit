#!/usr/bin/env bash
# OpenOrbis PS4 Toolchain - ARM64 native build - environment setup + self-test
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_DEPS="${SKIP_DEPS:-0}"
INSTALL_DOTNET="${INSTALL_DOTNET:-0}"

say()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

case "$ROOT" in
  /sdcard/*|/storage/*|/mnt/media_rw/*)
    die "This folder is on a noexec filesystem. Copy it to \$HOME first:
  cp -a \"$ROOT\" ~/ && cd ~/$(basename "$ROOT") && ./setup.sh" ;;
esac

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) warn "Host architecture is $(uname -m); the bundled binaries are ARM64 and will not run here." ;;
esac

if [ "$SKIP_DEPS" != 1 ]; then
  if command -v apt-get >/dev/null 2>&1 && [ "$(id -u)" = 0 ]; then
    say "Installing build dependencies (LLVM 18, make, python3, pyelftools)..."
    apt-get update -qq || warn "apt-get update failed; continuing with installed packages."
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
      clang-18 lld-18 llvm-18 make python3 python3-pyelftools \
      ca-certificates curl tar gzip \
      || warn "Some packages failed to install; continuing."
    if [ "$INSTALL_DOTNET" = 1 ] && ! command -v dotnet >/dev/null 2>&1; then
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq dotnet-sdk-8.0 \
        || warn "dotnet-sdk-8.0 is not available from apt. The bundled PkgTool is self-contained, so builds still work."
    fi
  else
    warn "Not root or apt-get unavailable; skipping dependency install."
    warn "Install manually: clang-18 lld-18 make python3 python3-pyelftools"
  fi
fi

missing=""
for t in clang-18 clang++-18 ld.lld-18 make python3; do
  command -v "$t" >/dev/null 2>&1 || missing="$missing $t"
done
if [ -n "$missing" ]; then
  warn "Missing host tools:$missing"
  warn "The host-tools adapters will fall back to clang/clang++/ld.lld, which must be LLVM 18-compatible."
fi

if ! command -v dotnet >/dev/null 2>&1; then
  warn "dotnet SDK not found. Not required: the bundled PkgTool.Core is self-contained."
  warn "Set INSTALL_DOTNET=1 (as root) or install .NET 8 only if you want to rebuild PkgTool."
fi

say "Making bundled tools executable..."
chmod 755 "$ROOT"/bin-arm64/create-fself \
          "$ROOT"/bin-arm64/create-gp4 \
          "$ROOT"/bin-arm64/readoelf \
          "$ROOT"/bin-arm64/PkgTool.Core \
          "$ROOT"/bin-arm64/create-eboot \
          "$ROOT"/host-tools/clang \
          "$ROOT"/host-tools/clang++ \
          "$ROOT"/host-tools/ld.lld \
          "$ROOT"/bin/linux/PkgTool.Core \
          "$ROOT"/bin/linux/create-fself \
          "$ROOT"/bin/linux/create-gp4 \
          "$ROOT"/bin/linux/readoelf \
          "$ROOT"/setup.sh

BASHRC="$HOME/.bashrc"
if ! grep -q '>>> OpenOrbis-PS4-Toolchain-ARM64 >>>' "$BASHRC" 2>/dev/null; then
  {
    printf '\n# >>> OpenOrbis-PS4-Toolchain-ARM64 >>>\n'
    printf 'export OO_PS4_TOOLCHAIN="%s"\n' "$ROOT"
    printf 'export PATH="%s/host-tools:$PATH"\n' "$ROOT"
    printf '# <<< OpenOrbis-PS4-Toolchain-ARM64 <<<\n'
  } >> "$BASHRC"
  say "Added OO_PS4_TOOLCHAIN and host-tools to $BASHRC"
else
  say "Environment already present in $BASHRC"
fi

export OO_PS4_TOOLCHAIN="$ROOT"
export PATH="$ROOT/host-tools:$PATH"

LOG="${TMPDIR:-/tmp}/oo-ps4-selftest.log"
VLOG="${TMPDIR:-/tmp}/oo-ps4-validate.log"
JOBS="$(nproc 2>/dev/null || echo 2)"

say "Self-test: building samples/hello_world with $JOBS jobs..."
(
  cd "$ROOT/samples/hello_world"
  make clean >/dev/null 2>&1 || true
  make -j"$JOBS"
) >"$LOG" 2>&1 || {
  tail -n 40 "$LOG" >&2 || true
  die "Self-test build failed. Full log: $LOG"
}

PKG="$ROOT/samples/hello_world/IV0000-BREW00083_00-HELLOWORLD000000.pkg"
[ -f "$PKG" ] || die "Build finished but $PKG was not created. See $LOG"

"$ROOT/bin-arm64/PkgTool.Core" pkg_validate "$PKG" >"$VLOG" 2>&1 || {
  tail -n 20 "$VLOG" >&2 || true
  die "pkg_validate failed. Full log: $VLOG"
}
OK_COUNT="$(grep -c '^\[OK\]' "$VLOG" || true)"

say "Self-test PASSED ($OK_COUNT validation checks)."
printf '\n'
printf '  Toolchain: %s\n' "$ROOT"
printf '  Built PKG: %s\n' "$PKG"
printf '  Size:      %s bytes\n' "$(stat -c %s "$PKG")"
printf '  SHA-256:   %s\n' "$(sha256sum "$PKG" | cut -d' ' -f1)"
printf '\n'
printf '  Known-good reference: %s\n' "$ROOT/verified/IV0000-BREW00083_00-HELLOWORLD000000.pkg"
printf '  sha256: 8254c99553510caa2cb018cb6757727f811595a838cc8e2e3d35ebc037ceb471\n'
printf '\n'
printf '  Open a new shell or run: source %s\n' "$BASHRC"
printf '  Then: cd "$OO_PS4_TOOLCHAIN/samples/hello_world" && make\n'
