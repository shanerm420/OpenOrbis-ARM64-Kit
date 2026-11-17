# Corresponding source locations

Revision pins are the ones used for this build. Where a component was used as a
prebuilt host package, the distribution name and version are given.

## OpenOrbis-PS4-Toolchain (GPL-3.0)

- https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain
- Commit: `0a1aaf9` (2026-02-27)
- Provides: sample Makefiles, `samples/`, `src/`, `scripts/`, `link.x`, headers,
  build scripts, and this package's base layout.

## LibOrbisPkg / PkgTool (LGPL-3.0)

- https://github.com/maxton/LibOrbisPkg
- Tag `v0.2`, commit `72370ca`
- Built for `linux-arm64`, .NET 8, self-contained single-file.
- One source change: `PkgTool/Program.cs`, `version` verb uses
  `Assembly.GetName().Version` instead of `FileVersionInfo(Assembly.Location)`.
  `Assembly.Location` is empty in single-file apps, which made `version` crash.

## musl (MIT)

- https://github.com/OpenOrbis/musl
- Commit: `2b0bb8c`, `VERSION` = 1.2.0
- Built for `x86_64-pc-freebsd12-elf`; ships `lib/libc.a`, `crt1.o`,
  `Scrt1.o`, `crt_dyn.o`, `crti.o`, `crtn.o`, `rcrt1.o`, `crtlib.o`.

## LLVM project (Apache-2.0 WITH LLVM-exception)

- Target libraries and libc++ headers:
  https://github.com/OpenOrbis/llvm-project, commit `e0aade4`
- Host toolchain: LLVM 18.1.8 Ubuntu packages (`clang-18`, `clang++-18`,
  `lld-18`, `llvm-18`).
- Target artifacts: `libc++.a`, `libc++abi.a`, `libc++experimental.a`,
  `libunwind.a`, `libclang_rt.builtins-x86_64.a`, `include/c++/v1`.

## orbis-lib-gen

- https://github.com/OpenOrbis/orbis-lib-gen
- Commit: `8443a65`
- Used to generate the SCE module stubs. 427 were generated; `libc.so` is
  intentionally omitted, leaving 426 `.so` files (including `libkernel.so`).

## Go tools

- https://github.com/OpenOrbis/create-fself
  commit `f2da622`
- https://github.com/OpenOrbis/create-gp4
- https://github.com/OpenOrbis/readoelf
- Built with Go 1.26.8 (`GOOS=linux`, `GOARCH=arm64`, `CGO_ENABLED=0`).

## Go runtime (BSD-3-Clause)

- https://go.dev
- Version 1.26.8, statically linked into the three ARM64 tools.
- License text: `Go-copyright.txt` (Debian Go package copyright, includes the
  BSD-3-Clause notice).

## .NET 8 (MIT)

- https://github.com/dotnet/runtime
- .NET SDK 8.0.428 used to publish PkgTool.Core.
- Runtime bundled into the self-contained executable; see
  `dotnet-LICENSE.txt` and `dotnet-ThirdPartyNotices.txt`.

## Support modules

- Origin: official OpenOrbis-PS4-Toolchain v0.5.4 Linux x86_64 release,
  `samples/hello_world/`.
- https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain/releases
- These files are Sony/IDC runtime modules, not built from the above sources.
  See `THIRD_PARTY_NOTICES.md`.

## Build inputs not shipped

- musl, libc++, libc++abi, libunwind, compiler-rt, and orbis-lib-gen sources are
  not included in this archive. The upstream repositories and commits above are
  the corresponding source. The build steps are described in the upstream
  `build/build.sh` and in this package's README.
