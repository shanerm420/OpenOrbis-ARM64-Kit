# Third-Party Notices

This package contains or is derived from the following projects. Full license
texts are in `licenses/`; source locations and revision pins are in
`licenses/SOURCES.md`.

## OpenOrbis-PS4-Toolchain

- Upstream: https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain
- Revision: 0a1aaf9 (2026-02-27)
- License: GNU General Public License v3.0
- File: `licenses/OpenOrbis-LICENSE`
- Includes scripts, sample code, CRT/module sources, linker script, headers, and
  the SDK's x86-64 target support files.

## LibOrbisPkg / PkgTool

- Upstream: https://github.com/maxton/LibOrbisPkg
- Revision: tag v0.2, commit 72370ca
- License: GNU Lesser General Public License v3.0
- File: `licenses/LibOrbisPkg-LICENSE.txt`
- PkgTool.Core is published as a self-contained .NET 8 single-file executable for
  linux-arm64. The only source modification is in the `version` verb, replacing
  `Assembly.Location` with `Assembly.GetName().Version` so it works in a
  single-file app. PKG output and packaging behavior are unchanged.

## musl libc

- Upstream: https://github.com/OpenOrbis/musl
- Revision: 2b0bb8c (VERSION 1.2.0)
- License: MIT (as a whole; some files have other permissive licenses, see the
  copyright file)
- File: `licenses/musl-COPYRIGHT`
- Built for the `x86_64-pc-freebsd12-elf` PS4 target; shipped as `lib/libc.a` and
  the CRT objects.

## LLVM / clang / lld / compiler-rt / libc++ / libc++abi / libunwind

- Upstream: https://github.com/OpenOrbis/llvm-project (OpenOrbis fork used for
  target libraries and libc++ headers), revision e0aade4
- Host compiler/linker: LLVM 18.1.8 (Ubuntu `clang-18`, `lld-18`, `llvm-18`)
- Upstream project: https://llvm.org
- License: Apache License v2.0 WITH LLVM-exception
- File: `licenses/LLVM-LICENSE.TXT`
- Target libraries shipped: `libc++.a`, `libc++abi.a`, `libc++experimental.a`,
  `libunwind.a`, `libclang_rt.builtins-x86_64.a`.

## orbis-lib-gen

- Upstream: https://github.com/OpenOrbis/orbis-lib-gen
- Revision: 8443a65
- Used to generate the SCE library stubs (`lib/*.so`). The stubs are generated
  link-time artifacts. `libc.so` was removed on purpose so `-lc` resolves to
  `libc.a`.

## Go tools (create-fself, create-gp4, readoelf)

- create-fself: https://github.com/OpenOrbis/create-fself, revision f2da622
- create-gp4: https://github.com/OpenOrbis/create-gp4
- readoelf: https://github.com/OpenOrbis/readoelf
- Built with Go 1.26.8, `GOOS=linux GOARCH=arm64 CGO_ENABLED=0`.
- Go runtime license: BSD-3-Clause
- File: `licenses/Go-copyright.txt`

## .NET 8 runtime

- Upstream: https://github.com/dotnet/runtime
- License: MIT, plus third-party notices for components bundled in the runtime
- Files: `licenses/dotnet-LICENSE.txt`, `licenses/dotnet-ThirdPartyNotices.txt`
- Bundled inside the self-contained PkgTool.Core executable.

## Support modules bundled for the hello_world sample

- Files: `support/right.sprx`, `support/libc.prx`, `support/libSceFios2.prx`
- Origin: the official OpenOrbis-PS4-Toolchain v0.5.4 Linux x86_64 release sample
  (`samples/hello_world/sce_sys/about/right.sprx`,
  `samples/hello_world/sce_module/libc.prx`,
  `samples/hello_world/sce_module/libSceFios2.prx`).
- These are Sony/IDC runtime support files, not built by this project and not
  covered by the OpenOrbis license. They are included only because the sample PKG
  will not launch without them. Replace them with modules from your own console
  dump if you prefer.
- SHA-256:
  - `e3416f9c6152276b494982baf7b65ebcd8052274ffc42f95a776318022842b64  right.sprx`
  - `3f8236c5996cf8e9917b8d27706d9743f6603d89de3b9859eacbb9f466b19c01  libSceFios2.prx`
  - `39ad53672bb0b14895f8465eb1619478ab935f5afe5dbf69c15f02cfc0a75ce6  libc.prx`

## SDL2

SDL2 libraries are **not** included in this package. The SDL2 headers are part of
the upstream SDK headers. No SDL2 license text is therefore included, and samples
that link SDL2 will not build until SDL2 target libraries are added.

## Not included

The upstream `extra/` Windows installer and the ad-hoc `PkgTool-linux-arm64/`
folder from the working tree are not part of this distribution.
