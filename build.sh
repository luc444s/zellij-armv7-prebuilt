#!/usr/bin/env bash
# Reproduce the prebuilt zellij armv7 (32-bit ARM / Termux) artifacts.
#
# Requirements: rustup, cargo, Android NDK r27c, cargo-ndk.
# Usage: ./build.sh [ndk_path]
set -euo pipefail

ZELLIJ_VERSION="${ZELLIJ_VERSION:-0.45.1}"
NDK="${1:-${ANDROID_NDK_HOME:-$HOME/android-ndk-r27c}}"
ABI="${ABI:-armeabi-v7a}"      # -> target armv7-linux-androideabi
API="${API:-24}"
OUT="dist"

if [[ ! -d "$NDK" ]]; then
  echo "NDK not found at: $NDK" >&2
  echo "Download: https://dl.google.com/android/repository/android-ndk-r27c-linux.zip" >&2
  exit 1
fi

command -v cargo-ndk >/dev/null || cargo install cargo-ndk --locked

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

git clone --depth 1 --branch "v${ZELLIJ_VERSION}" \
  https://github.com/zellij-org/zellij.git "$work/zellij"
cd "$work/zellij"

# zellij pins its own toolchain via rust-toolchain.toml (1.95.0); add our targets there.
rustup target add --toolchain "$(grep -oP 'channel = "\K[^"]+' rust-toolchain.toml)" \
  armv7-linux-androideabi wasm32-wasip1

export ANDROID_NDK_HOME="$NDK"
export ANDROID_NDK_ROOT="$NDK"
# NOTE: cargo-ndk v4 uses -P (capital) for the API level; -p is swallowed by cargo.
cargo ndk -t "$ABI" -P "$API" build --release

bin="target/armv7-linux-androideabi/release/zellij"
[[ -f "$bin" ]] || { echo "build produced no binary" >&2; exit 1; }

mkdir -p "$OUT"
tar -czf "$OUT/zellij-${ZELLIJ_VERSION}-armv7-linux-androideabi.tar.gz" -C "$(dirname "$bin")" zellij

# Termux .deb (arch "arm"), installs to $PREFIX/bin/zellij
root="$work/deb/root"
mkdir -p "$root/DEBIAN" "$root/data/data/com.termux/files/usr/bin"
install -m 755 "$bin" "$root/data/data/com.termux/files/usr/bin/zellij"
cat > "$root/DEBIAN/control" <<EOF
Package: zellij
Version: ${ZELLIJ_VERSION}
Architecture: arm
Maintainer: luc444s <luc444s@users.noreply.github.com>
Installed-Size: $(du -k "$bin" | cut -f1)
Homepage: https://zellij.dev/
Description: A terminal workspace with batteries included
 Prebuilt for Termux on armeabi-v7a (32-bit ARM).
License: MIT
EOF
dpkg-deb -Zxz --build --root-owner-group "$root" "$OUT/zellij_${ZELLIJ_VERSION}_arm.deb"

( cd "$OUT" && sha256sum zellij-*.tar.gz zellij_*.deb > SHA256SUMS )
echo "Artifacts in $OUT/"
ls -lh "$OUT"
