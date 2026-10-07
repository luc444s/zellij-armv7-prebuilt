# zellij for 32-bit ARM (Termux / armeabi-v7a) — prebuilt

Precompiled **zellij 0.45.1** binaries for **32-bit ARM Android devices** (ABI `armeabi-v7a`, Rust target `armv7-linux-androideabi`), ready to run in **Termux**.

## Why does this exist?

The official Termux package excludes 32-bit ARM:

```sh
# termux-packages/packages/zellij/build.sh
# wasmer doesn't support these platforms yet
TERMUX_PKG_EXCLUDED_ARCHES="arm, i686"
```

That comment is outdated: zellij 0.45.x uses **wasmi** (a pure-Rust WASM interpreter), which works fine on 32-bit. As a result, on an arm device `pkg install zellij` says *"No packages found"*, and the only way to get zellij is to compile it yourself.

These binaries are built from the **official upstream source** (tag `v0.45.1`, MIT) with the Android NDK; no source changes, no patches.

## Install

### Option A — add this apt repo, then plain `pkg install zellij` (recommended)

Register the repository once, then install zellij like any normal package:

```sh
mkdir -p "$PREFIX/etc/apt/sources.list.d"
echo "deb [trusted=yes] https://luc444s.github.io/zellij-armv7-prebuilt/ ./" \
  > "$PREFIX/etc/apt/sources.list.d/zellij.list"
pkg update
pkg install -y zellij
zellij --version
```

After that, `pkg upgrade` will also update zellij normally. (Unsigned repo → `trusted=yes`.)

### Option B — one-off `.deb` download

```sh
cd ~
curl -fsSLO https://github.com/luc444s/zellij-armv7-prebuilt/releases/download/v0.45.1/zellij_0.45.1_arm.deb
pkg install -y ./zellij_0.45.1_arm.deb   # or: dpkg -i ./zellij_0.45.1_arm.deb
zellij --version
```

Termux/apt then tracks it as a normal package (`dpkg -l zellij` → `ii`).

### Option C — plain tarball

```sh
curl -fsSL https://github.com/luc444s/zellij-armv7-prebuilt/releases/download/v0.45.1/zellij-0.45.1-armv7-linux-androideabi.tar.gz \
  | tar -xz -C "$PREFIX/bin"
chmod +x "$PREFIX/bin/zellij"
zellij --version
```

## Verify

```sh
sha256sum -c SHA256SUMS   # after downloading the assets
```

## Build details

- Source: `https://github.com/zellij-org/zellij` @ tag `v0.45.1` (MIT)
- Toolchain: Rust `1.95.0` (the version pinned by zellij's `rust-toolchain.toml`)
- NDK: `r27c`, API level 24
- Command:
  ```sh
  ANDROID_NDK_HOME=/path/to/android-ndk-r27c \
  cargo ndk -t armeabi-v7a -P 24 build --release
  ```
- Default features (`plugins_from_target`, `vendored_curl`, `web_server_capability`); OpenSSL, libcurl, nghttp2, SQLite and aws-lc-sys are cross-compiled and statically linked.
- Result: ELF 32-bit ARM PIE, interpreter `/system/bin/linker`, `NEEDED`: `libz.so libdl.so libm.so libc.so` (only bionic system libs).

## Notes / caveats

- **RAM:** this is aimed at low-end 32-bit phones (often ~1.7 GB RAM). zellij is not light; if it feels sluggish, try `zellij options --simplified-ui true`.
- If the status-bar font looks wrong, see <https://zellij.dev/documentation/compatibility.html>.
- This is an unofficial, best-effort build. The proper long-term fix is to remove `arm` from `TERMUX_PKG_EXCLUDED_ARCHES` upstream so `pkg install zellij` works for everyone.

## License

zellij is MIT-licensed. This repository only redistributes an unmodified build of the upstream project.
