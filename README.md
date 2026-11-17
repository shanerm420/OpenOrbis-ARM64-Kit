# OpenOrbis-ARM64-Kit

Unofficial community build, not affiliated with the OpenOrbis project.

**Repository note:** this GitHub repository contains the sources, scripts,
samples, documentation, and license/notice files. The ready-to-run ARM64 kit -
prebuilt host tools, x86-64 target libraries, support modules, and the verified
PKG - is attached to the release as `OpenOrbis-PS4-Toolchain-ARM64.tar.gz`.
Large sample media files are also included only in the release archive.

A self-contained PS4 homebrew SDK that runs **natively on ARM64 Linux** (tested in
Ubuntu 26.04 under proot on Termux/Android) and cross-compiles PS4 binaries for
`x86_64-pc-freebsd12-elf`, then builds installable fake `.pkg` files.

No qemu is needed for normal builds. Every host tool in this package is an ARM64
binary or a small shell adapter: the Go tools, PkgTool.Core, the linker and clang.

This is a port/repack of **OpenOrbis-PS4-Toolchain** at commit `0a1aaf9`
(2026-02-27), with the missing sample support files and packaging fixes needed to
produce a PKG that actually launches on hardware.

---

## Verified end-to-end on a real console

- Console: PS4 Pro, firmware 12.52, GoldHEN
- PKG installed and launched; live klog over netcat showed:

```
launchApp(BREW00083)
EXEC /app0/eboot.bin
main: Hello world! Waiting 2 seconds!
main: Done. Infinitely looping...
```

Reference artifact (unchanged, included in the release archive under `verified/`):

```
file:   IV0000-BREW00083_00-HELLOWORLD000000.pkg
size:   6,619,136 bytes
sha256: 8254c99553510caa2cb018cb6757727f811595a838cc8e2e3d35ebc037ceb471

eboot.bin: 1,211,200 bytes, 8 SELF entries
DT_SCE_FILENAME: hello_world/x64/Debug/hello_world.elf
pkg_validate: 28/28 [OK]
inner PFS: eboot.bin, sce_module/libc.prx, sce_module/libSceFios2.prx,
           sce_sys/about/right.sprx, sce_sys/keystone
```

Sample support files (from the official v0.5.4 Linux release; also in `support/`):

```
e3416f9c6152276b494982baf7b65ebcd8052274ffc42f95a776318022842b64  sce_sys/about/right.sprx
3f8236c5996cf8e9917b8d27706d9743f6603d89de3b9859eacbb9f466b19c01  sce_module/libSceFios2.prx
39ad53672bb0b14895f8465eb1619478ab935f5afe5dbf69c15f02cfc0a75ce6  sce_module/libc.prx
```

Note: PKG bytes are not deterministic (random package key material), so a rebuild
will have a different SHA-256. Validate structure, not the hash, when rebuilding.

---

## Requirements

- aarch64/arm64 Linux with glibc. Ubuntu 24.04/26.04 recommended. proot-distro
  Ubuntu inside Termux works and is what was used for this build.
- `clang-18`, `clang++-18`, `ld.lld-18` (LLVM 18.1.8 recommended), GNU make,
  python3, tar/gzip.
- `python3-pyelftools` for some helper scripts in `scripts/`.
- .NET 8 SDK only if you want to rebuild PkgTool.Core. The bundled copy is
  self-contained.
- A PS4 with GoldHEN to install fake PKGs.
- About 500 MB free disk for extraction.

Termux without proot is not a supported build host. The Android/Termux userspace
is not glibc and cannot run the bundled host binaries. Use proot-distro Ubuntu.

---

## Install

The Android shared storage (`/sdcard`) is mounted `noexec` and does not support
symlinks, so the toolchain cannot run from there. Copy it to `$HOME` first.

Option A - copy the folder (simple):

```
cp -a /sdcard/Download/OpenOrbis-PS4-Toolchain-ARM64 ~/
cd ~/OpenOrbis-PS4-Toolchain-ARM64

# Android shared storage does not preserve the executable bit on the folder
# copy, so set it once on setup.sh. setup.sh restores it on every bundled tool.
chmod +x setup.sh
./setup.sh
source ~/.bashrc        # or open a new shell
```

Option B - extract the tar (executable bits already preserved):

```
tar -xzf /sdcard/Download/OpenOrbis-PS4-Toolchain-ARM64.tar.gz -C ~/
cd ~/OpenOrbis-PS4-Toolchain-ARM64
./setup.sh
source ~/.bashrc
```

If the executable bit on `setup.sh` was lost, `bash setup.sh` also works.

`setup.sh`:

- refuses to run from `/sdcard` or `/storage`
- installs build dependencies with apt when running as root
- makes the bundled tools executable
- adds `OO_PS4_TOOLCHAIN` and `host-tools/` to `~/.bashrc` (idempotent)
- runs a full hello_world build + PKG validation as a self-test

If you only want the environment and no dependency install:

```
SKIP_DEPS=1 ./setup.sh
```

---

## Build hello_world

```
cd "$OO_PS4_TOOLCHAIN/samples/hello_world"
make clean
make -j"$(nproc)"
ls -lh IV0000-BREW00083_00-HELLOWORLD000000.pkg
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" pkg_validate \
  IV0000-BREW00083_00-HELLOWORLD000000.pkg
```

The sample Makefile calls `$(OO_PS4_TOOLCHAIN)/bin/linux/...` (`CDIR=linux`) and
hardcodes `clang` / `clang++` / `ld.lld`. `setup.sh` puts `host-tools/` in PATH,
where those names resolve to `clang-18` / `clang++-18` / `ld.lld-18` (with a
fallback to unversioned LLVM if 18 is not installed).

If you run `make` in a shell that does not have the environment:

```
export OO_PS4_TOOLCHAIN="$HOME/OpenOrbis-PS4-Toolchain-ARM64"
export PATH="$OO_PS4_TOOLCHAIN/host-tools:$PATH"
```

Keep the directory layout intact. The samples include `../../_common/log.h`, so
copying only `samples/hello_world` elsewhere will break the build.

---

## Manual build (no make)

From `samples/hello_world`:

```
export OO_PS4_TOOLCHAIN="$HOME/OpenOrbis-PS4-Toolchain-ARM64"
export PATH="$OO_PS4_TOOLCHAIN/host-tools:$PATH"

mkdir -p hello_world/x64/Debug

clang --target=x86_64-pc-freebsd12-elf -fPIC -funwind-tables -c \
  -isysroot "$OO_PS4_TOOLCHAIN" \
  -isystem "$OO_PS4_TOOLCHAIN/include" \
  -isystem "$OO_PS4_TOOLCHAIN/include/c++/v1" \
  -o hello_world/x64/Debug/main.o hello_world/main.cpp

ld.lld hello_world/x64/Debug/main.o \
  -o hello_world/x64/Debug/hello_world.elf \
  -m elf_x86_64 -pie --script "$OO_PS4_TOOLCHAIN/link.x" --eh-frame-hdr \
  -L"$OO_PS4_TOOLCHAIN/lib" -lc -lkernel -lc++ \
  "$OO_PS4_TOOLCHAIN/lib/crt1.o"

"$OO_PS4_TOOLCHAIN/bin-arm64/create-fself" \
  -in=hello_world/x64/Debug/hello_world.elf \
  -out=hello_world/x64/Debug/hello_world.oelf \
  --eboot eboot.bin --paid 0x3800000000000011
```

Packaging (same steps the Makefile performs):

```
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_new sce_sys/param.sfo
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo APP_TYPE \
  --type Integer --maxsize 4 --value 1
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo APP_VER \
  --type Utf8 --maxsize 8 --value '01.00'
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo CATEGORY \
  --type Utf8 --maxsize 4 --value 'gd'
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo CONTENT_ID \
  --type Utf8 --maxsize 48 --value 'IV0000-BREW00083_00-HELLOWORLD000000'
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo DOWNLOAD_DATA_SIZE \
  --type Integer --maxsize 4 --value 0
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo SYSTEM_VER \
  --type Integer --maxsize 4 --value 0
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo TITLE \
  --type Utf8 --maxsize 128 --value 'OpenOrbis Hello World Sample'
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo TITLE_ID \
  --type Utf8 --maxsize 12 --value 'BREW00083'
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" sfo_setentry sce_sys/param.sfo VERSION \
  --type Utf8 --maxsize 8 --value '1.00'

"$OO_PS4_TOOLCHAIN/bin-arm64/create-gp4" -out pkg.gp4 \
  --content-id=IV0000-BREW00083_00-HELLOWORLD000000 \
  --files "eboot.bin sce_sys/about/right.sprx sce_sys/param.sfo sce_sys/icon0.png sce_module/libSceFios2.prx sce_module/libc.prx"

"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" pkg_build pkg.gp4 .
```

`-in=` must stay a **relative** path (`hello_world/x64/Debug/hello_world.elf`).
create-fself embeds that string as `DT_SCE_FILENAME` in the SELF. Absolute paths
leak host paths and differ from the official reference binaries.

---

## Install the PKG on the PS4

1. Copy the `.pkg` to the root of a USB drive (commonly `/mnt/usb0/` on the PS4).
2. On the PS4: GoldHEN -> Package Installer (or Debug Settings -> Game ->
   Package Installer).
3. If an older build with the same title ID (`BREW00083`) is installed, delete
   it first. Fake PKGs use the same content ID/version as the previous install
   and the installer will refuse or the old eboot may run.

This is a fake PKG signed with debug keys. It requires GoldHEN (or another HEN
that supports fake PKGs). It will not install on a stock console.

---

## What was fixed for ARM64 (full list)

The upstream release ships x86-64 host executables and x86-64-built target
libraries. Everything below was required to get a working ARM64-native pipeline
and a PKG that launches.

1. **Cross-compile target.** The host clang is an aarch64 compiler. PS4 code must
   be built with `--target=x86_64-pc-freebsd12-elf`, and lld must be told
   `-m elf_x86_64`. Without this, clang emits aarch64 objects and the link fails
   or produces an invalid eboot.

2. **LLVM 18 and name adapters.** The official v0.5.4 release is built with LLVM
   18. The sample Makefiles hardcode `clang`, `clang++`, `ld.lld`.
   `host-tools/clang`, `host-tools/clang++`, `host-tools/ld.lld` are small
   adapters that exec `clang-18`, `clang++-18`, `ld.lld-18`, with a fallback to
   the unversioned names. LLVM 18.1.8 was used here.

3. **musl libc for the PS4 target.** musl (OpenOrbis fork, VERSION 1.2.0) is built
   for `x86_64-pc-freebsd12-elf` and installed as `lib/libc.a` plus the CRT
   objects: `crt1.o`, `Scrt1.o`, `crt_dyn.o`, `crti.o`, `crtn.o`, `rcrt1.o`.
   `-isysroot "$OO_PS4_TOOLCHAIN"` makes the include/library search work.

4. **compiler-rt builtins for x86-64.** The builtins must be the x86-64 target
   library (`lib/libclang_rt.builtins-x86_64.a`), not the host's aarch64 builtins.
   This is a separate build from the host compiler-rt.

5. **libc++ stack for x86-64.** `libc++.a`, `libc++abi.a`,
   `libc++experimental.a`, `libunwind.a` are built for the PS4 target, and the
   headers live in `include/c++/v1`. Command line includes
   `-isystem "$OO_PS4_TOOLCHAIN/include/c++/v1"`.

6. **crtlib.o.** Built from `src/crt/crtlib.c` with the PS4 target and placed in
   `lib/`; it is part of the normal link set.

7. **SCE library stubs.** 427 `.so` stubs were generated with `orbis-lib-gen`
   using an `x86_64-linux-gnu-gcc` wrapper (the host gcc is aarch64 and cannot
   produce x86-64 stubs by default). `libc.so` was then **removed on purpose**, so
   `-lc` resolves to the static `libc.a` instead of a bogus dynamic libc stub.
   The package ships 426 `.so` stubs (425 SCE modules + `libkernel.so`).

8. **CMake 4 compatibility.** Building the old musl/libc++ sources with a modern
   CMake fails on the removed pre-3.5 compatibility policy. Use
   `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` when rebuilding those libraries.

9. **llvm-config stub.** The library build scripts call `llvm-config`. The host
   `llvm-config` points at aarch64 paths, so a stub/fake `llvm-config` was placed
   first in PATH with the correct cross-build flags. Without this, CMake picks up
   host paths and tries to link aarch64 objects.

10. **Go tools rebuilt for arm64.** `create-fself`, `create-gp4`, `readoelf` are
    built with `GOARCH=arm64` (Go 1.26.8). During bring-up, ARM64
    `create-fself` produced byte-identical output to the official x86-64 binary
    when run under qemu with the same input.

11. **PkgTool.Core for linux-arm64.** The official release ships an x64-only
    PkgTool. LibOrbisPkg tag `v0.2` (commit `72370ca`, the 0.2.231-generation
    tool) was published for `linux-arm64` with .NET 8, `--self-contained`,
    `PublishSingleFile`, so no .NET runtime is needed on the device. The bundled
    copy reports `0.2.0.0`. The `version` verb was patched to work in a
    single-file app (`Assembly.Location` is empty there), and the adapter
    `bin/linux/PkgTool.Core` exports
    `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` for minimal proot images without
    ICU.

12. **Makefile compatibility.** The sample Makefiles use
    `$(TOOLCHAIN)/bin/$(CDIR)` with `CDIR=linux`. `bin/linux/` contains wrappers
    for `PkgTool.Core`, `create-gp4`, `create-fself`, and `readoelf` that exec the
    ARM64 binaries in `bin-arm64/`. No edits to the sample Makefiles are needed.

13. **Missing sample support modules.** The repo ships only `.gitkeep` in
    `samples/hello_world/sce_sys/about` and `samples/hello_world/sce_module`. The
    PKG must contain `sce_sys/about/right.sprx`, `sce_module/libc.prx`, and
    `sce_module/libSceFios2.prx`. Without them the PKG installs but fails at
    launch with "The data is corrupted" (CE-...). They were copied from the
    official v0.5.4 release sample and are included in `support/` with hashes.

14. **Correct `DT_SCE_FILENAME`.** Build the intermediate ELF at
    `hello_world/x64/Debug/hello_world.elf` and pass that **relative** path to
    `create-fself -in=`. The string is embedded in the SELF dynamic section; the
    official reference uses exactly this value.

15. **`OO_PS4_TOOLCHAIN` must be exported.** `create-fself` locates
    `libkernel.so` through `OO_PS4_TOOLCHAIN` when processing imports. `setup.sh`
    and the Makefiles export it; manual commands must too.

16. **Correct SELF layout.** The tools here are from toolchain HEAD (`f2da622`),
    which produces the 8-entry SELF layout used by the working v0.5.2/v0.5.4
    samples. The official v0.5.3 release tool produced a 10-entry layout that
    fails to launch (upstream issue #283). Do not mix old `create-fself` binaries
    with this package.

17. **Keystone handling.** `PkgTool pkg_build` generates `sce_sys/keystone`
    automatically. Do not add a keystone file to the GP4 manually; it appears in
    the inner PFS and that is expected.

18. **Fake PKG signing.** PkgTool uses the standard fake debug RIF/keys. The
    console must run GoldHEN (or equivalent) and any previous install with the
    same content ID must be removed before installing a rebuild.

19. **`/sdcard` limitations.** Android's `/sdcard` is mounted `noexec` and does
    not support symlinks. This package contains no symlinks and `setup.sh`
    refuses to run from `/sdcard`; copy the folder to `$HOME` and use it there.

20. **Termux build host.** The build must run in a glibc userspace (proot Ubuntu).
    Android/Termux binaries are linked against bionic and cannot load the bundled
    glibc ARM64 executables.

---

## Verify an existing PKG

```
cd "$OO_PS4_TOOLCHAIN/verified"
sha256sum -c SHA256SUMS
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" pkg_validate \
  IV0000-BREW00083_00-HELLOWORLD000000.pkg
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" pkg_extractinnerpfs \
  IV0000-BREW00083_00-HELLOWORLD000000.pkg /tmp/inner.pfs
"$OO_PS4_TOOLCHAIN/bin-arm64/PkgTool.Core" pfs_extract --verbose \
  /tmp/inner.pfs /tmp/inner-out
```

Expected inner files: `uroot/eboot.bin`, `uroot/sce_module/libc.prx`,
`uroot/sce_module/libSceFios2.prx`, `uroot/sce_sys/about/right.sprx`,
`uroot/sce_sys/keystone`.

`support/SHA256SUMS` matches the three support modules byte-for-byte.

---

## Layout

| Path | Contents |
| --- | --- |
| `bin-arm64/` | ARM64 host tools: `create-fself`, `create-gp4`, `readoelf`, `PkgTool.Core` (single-file, self-contained), `create-eboot` wrapper |
| `bin/linux/` | Compatibility wrappers used by the sample Makefiles |
| `host-tools/` | `clang` / `clang++` / `ld.lld` adapters for LLVM 18 |
| `lib/` | x86-64 PS4 target libraries: musl, libc++, libc++abi, libunwind, compiler-rt builtins, CRT objects, 426 SCE `.so` stubs |
| `include/` | musl, libc++ (`include/c++/v1`), orbis, SDL2/GLES headers, and the rest of the SDK headers |
| `link.x` | PS4 linker script |
| `samples/` | Upstream samples, including a ready-to-build `hello_world` and the verified PKG |
| `support/` | The three support modules required by the hello_world PKG |
| `verified/` | Proven PKG + eboot + `SHA256SUMS` |
| `scripts/`, `src/`, `build/`, `tests/`, `docs/` | Upstream helpers, CRT/module sources, build scripts, tests and documentation |
| `licenses/` | License texts and source locations |

Legacy `extra/` (Windows installer) and the ad-hoc x86-era `PkgTool-linux-arm64/`
from the working tree were deliberately not included.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| PKG installs but launch says "The data is corrupted" | Support modules missing from the inner PFS. Check `pkg_extractinnerpfs` + `pfs_extract`; the sample needs `right.sprx`, `libc.prx`, `libSceFios2.prx`. Also delete any older install with the same title ID. |
| `make` says `clang: error: unknown target triple` | You are using a host compiler that does not understand the FreeBSD target, or PATH order is wrong. Use the bundled `host-tools` adapters and LLVM 18. |
| `cannot find -lc` | `libc.so` is intentionally absent. Link with `-L"$OO_PS4_TOOLCHAIN/lib"` and let `-lc` find `libc.a`. |
| `create-fself` cannot find `libkernel.so` | Export `OO_PS4_TOOLCHAIN` to the toolchain root. |
| PkgTool aborts with a globalization/ICU error | Use the `bin/linux/PkgTool.Core` adapter (sets invariant globalization) or set `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`. |
| `Permission denied` running a tool from `/sdcard` | `/sdcard` is `noexec`. Copy the folder to `$HOME`. |
| `make` fails on `../../_common/log.h` | The sample was separated from `samples/_common`. Keep the original layout. |
| `version` verb of an old PkgTool crashes | This package includes a patched single-file build; use `bin-arm64/PkgTool.Core` from this folder. |
| Installer rejects the PKG | GoldHEN not active, wrong firmware, or an existing install with the same content ID/version. |

---

## Rebuilding the host tools (optional)

Go tools (sources from OpenOrbis; build on the phone):

```
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o bin-arm64/create-fself ./create-fself
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o bin-arm64/create-gp4   ./create-gp4
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o bin-arm64/readoelf    ./readoelf
```

PkgTool (LibOrbisPkg v0.2, requires .NET 8 SDK):

```
dotnet publish PkgTool.Core/PkgTool.Core.csproj -c Release -r linux-arm64 \
  --self-contained true -p:PublishSingleFile=true \
  -p:IncludeNativeLibrariesForSelfExtract=true \
  -p:DebugType=None -p:DebugSymbols=false -o out
```

The public LibOrbisPkg target framework is `netcoreapp3.0`; it was changed to
`net8.0` to publish with the current SDK. This does not change PKG output.

The x86-64 target libraries were rebuilt from the OpenOrbis musl (1.2.0) and
llvm-project forks plus `orbis-lib-gen`. See `licenses/SOURCES.md` for the exact
upstream locations and commits.

---

## Known limitations

- SDL2 libraries are not bundled (the upstream release includes SDL2 builds; this
  package does not). Samples that need SDL2 will link-fail until those target
  libraries are added.
- Only `hello_world` was validated on hardware. Other samples were not run.
- The support modules libc.prx and libSceFios2.prx are stub modules made by the OpenOrbis project, and right.sprx is a file by IDC distributed with the OpenOrbis samples. All three come from the official OpenOrbis v0.5.4 release and were not built by this project. The licensing status of right.sprx was not independently verified, so anyone redistributing it should check with the OpenOrbis project. You can also replace all three with copies from the official release.
- There are no macOS or Windows host adapter directories; this package targets
  ARM64 Linux only. The Makefile's Darwin branch is left untouched but unused.
- The legacy `create-eboot` CLI is provided as a wrapper around `create-fself`.
  There is no separate `create-lib` binary in the current upstream tool layout.

---

## Licenses and sources

See `licenses/` and `THIRD_PARTY_NOTICES.md`.

- OpenOrbis-PS4-Toolchain: GPLv3 (`licenses/OpenOrbis-LICENSE`)
- LibOrbisPkg / PkgTool: LGPLv3 (`licenses/LibOrbisPkg-LICENSE.txt`)
- musl libc: MIT (`licenses/musl-COPYRIGHT`)
- LLVM/clang/lld/compiler-rt/libc++/libunwind: Apache-2.0 WITH LLVM-exception
  (`licenses/LLVM-LICENSE.TXT`)
- .NET 8 runtime: MIT + third-party notices (`licenses/dotnet-*`)
- Go runtime (in the ARM64 tools): BSD-3-Clause (`licenses/Go-copyright.txt`)

Corresponding source locations and revision pins are listed in
`licenses/SOURCES.md`. This package is intended for personal homebrew use; comply
with the upstream licenses if you redistribute it.
