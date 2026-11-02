# Swift Language Support for Zephyr

A Zephyr module that lets you write applications and libraries in Embedded Swift. It provides SwiftPM packages for the Zephyr C APIs and a small Swift library over the kernel, the CMake functions that build an application's Swift package for a Zephyr target, and the runtime support that Embedded Swift needs.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Supported architectures](#supported-architectures)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features

- **SwiftPM packages**: Swift code is described by `Package.swift`. This module's package provides `ZephyrCore`, `ZephyrSystem`, `Zephyr` and `ZephyrApplication`; applications and libraries depend on it by path or URL, and may use other Embedded-compatible packages.
- **CMake functions**: `zephyr_swift_application()` runs `swift build` for the application's package with the target options of the Zephyr build and links the result, and `zephyr_swift_library()` registers a library module with the Zephyr build.
- **Kconfig options**: `CONFIG_SWIFT` turns Swift support on, and `CONFIG_SWIFT_DEBUG_INFO` defines `SWIFT_DEBUG_INFO` for `#if` blocks in Swift code.
- **Runtime support** (`ZephyrSystem`): `posix_memalign` on top of the libc's `aligned_alloc`, which the Embedded Swift runtime calls for every heap allocation, and thin wrappers over the kernel (`Kernel`, `k_timeout_t` helpers).
- **Zephyr library** (`Zephyr`): `Duration`, `Timeout`, `Instant`, `sleep(_:)`, and `ZephyrError` with `check(_:)`, which turns a `-errno` return code into a typed throw.
- **C interoperability** (`ZephyrCore`): a Clang module exposes the Zephyr C APIs to Swift, and C functions can be implemented in Swift with `@c @implementation`.
- **Claude Code plugin** (`plugins/`): scaffolds a project, an application or a library.

## Prerequisites

1. A Swift 6.4 or later toolchain from swift.org with Embedded Swift support. Xcode's Swift lacks the RISC-V and Arm embedded backends, so select the swift.org toolchain with `TOOLCHAINS=swift`. With swiftly:

   ```bash
   swiftly install 6.4.0
   export TOOLCHAINS=swift
   ```

2. A Zephyr workspace with the Zephyr SDK and its LLVM toolchain (`ZEPHYR_TOOLCHAIN_VARIANT=zephyr/llvm`). The module was built and run with Zephyr SDK 1.0.1.
3. CMake 3.29 or later, `west`, and Git. SwiftPM comes with the Swift toolchain.

## Installation

Clone the module into your Zephyr workspace:

```bash
git clone https://github.com/anselmes/zephyr-lang-swift modules/lang/swift
```

Then make Zephyr find it, in one of two ways.

**From your application.** Set `ZEPHYR_EXTRA_MODULES` in the application's `CMakeLists.txt`, before `find_package(Zephyr)`. The clone lives in the Zephyr workspace, not beside the application, so the path starts at `ZEPHYR_WORKSPACE` (set by the samples' `.env.example`); replace it with the checkout's location if you keep the clone elsewhere:

```cmake
set(ZEPHYR_EXTRA_MODULES $ENV{ZEPHYR_WORKSPACE}/modules/lang/swift)
```

**From the west manifest.** Add the project to `$ZEPHYR_BASE/submanifests/optional.yaml`, which needs no change to `CMakeLists.txt`:

```yaml
manifest:
  remotes:
    - name: anselmes
      url-base: https://github.com/anselmes
  projects:
    - name: zephyr-lang-swift
      revision: main
      path: modules/lang/swift
      remote: anselmes
      groups:
        - optional
```

The [anselmes/zephyr](https://github.com/anselmes/zephyr) fork also carries the module.

The fork and the manifest entry both place the module in the `optional` group, which west disables by default. Enable the group and fetch the module before building:

```bash
west config manifest.group-filter -- +optional
west update zephyr-lang-swift
```

## Usage

### An application

1. Enable Swift in `prj.conf`. The Embedded Swift runtime allocates from the libc heap, so a libc with a nonzero heap is required:

   ```kconfig
   CONFIG_SWIFT=y
   CONFIG_MINIMAL_LIBC=y
   CONFIG_COMMON_LIBC_MALLOC_ARENA_SIZE=4096
   ```

   The minimal libc defaults the arena to zero bytes, which leaves no heap and makes every Swift allocation fail. Size it for your board and application.

2. Describe the application as a Swift package in `Package.swift`. The application is a target with a static library product, named `App` by default, that depends on `Zephyr` and on `ZephyrApplication`, which provides the C `main`. The target triple and Zephyr's include paths come from the build, so the manifest carries only the Embedded Swift settings:

   ```swift
   // swift-tools-version: 6.4
   import PackageDescription

   let settings: [SwiftSetting] = [
     .strictMemorySafety(),
     .enableUpcomingFeature("ExistentialAny"),
     .enableUpcomingFeature("InternalImportsByDefault"),
     .enableUpcomingFeature("MemberImportVisibility"),
     .enableExperimentalFeature("CImplementation"),
     .enableExperimentalFeature("Embedded"),
     .enableExperimentalFeature("Extern"),
   ]

   let package = Package(
     name: "my-swift-app",
     products: [.library(name: "App", type: .static, targets: ["App"])],
     dependencies: [
       .package(url: "https://github.com/anselmes/zephyr-lang-swift", branch: "main")
     ],
     targets: [
       .target(
         name: "App",
         dependencies: [
           .product(name: "Zephyr", package: "zephyr-lang-swift"),
           .product(name: "ZephyrApplication", package: "zephyr-lang-swift"),
         ],
         path: "src",
         swiftSettings: settings,
       )
     ],
     swiftLanguageModes: [.v6],
   )
   ```

   Declare `settings` before `package`: top-level manifest code runs in order, so a later declaration is still empty when `package` reads it. Inside a west workspace, depend on the module by path instead, as the samples do with `.package(name: "zephyr-lang-swift", path: "../..")`.

3. Build the package from `CMakeLists.txt`. `zephyr_swift_application()` finds the nearest `Package.swift` at or above the application directory; pass `PACKAGE_DIR` or `PRODUCT` to choose another:

   ```cmake
   cmake_minimum_required(VERSION 3.29)
   # `west build -b <board>` wins; otherwise use ZEPHYR_BOARD.
   if(NOT DEFINED BOARD AND DEFINED ENV{ZEPHYR_BOARD})
     set(BOARD $ENV{ZEPHYR_BOARD})
   endif()
   find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
   project(my_swift_app)

   zephyr_swift_application()
   ```

4. Define the entry point in `src/Entrypoint.swift`. The C `main` provided by this module calls it:

   ```swift
   import Zephyr

   @c(entrypoint)
   func entrypoint() {
     print("Hello from Swift on Zephyr!")
     while true {
       sleep(Duration.milliseconds(1000))
     }
   }
   ```

5. Build and run it in QEMU, with the board and toolchain from your environment:

   ```bash
   west build -p -t run
   ```

`samples/` has working versions of all of this, including the `.env.example` that sets the board and toolchain. See [samples/README.md](samples/README.md).

### A library

A library is a target of a Swift package. Applications that use it list it in their own `Package.swift`, as a target of the same package or a product of another one, and SwiftPM compiles it with the application:

```swift
.target(
  name: "MyLibrary",
  dependencies: [.product(name: "Zephyr", package: "zephyr-lang-swift")],
  path: "lib/my-library",
  exclude: ["CMakeLists.txt", "Kconfig"],
  swiftSettings: settings,
)
```

To give the library a Kconfig option and C headers, also make its directory part of a Zephyr module (`zephyr/module.yml`) and register it in a `CMakeLists.txt`. Registration compiles nothing; it exposes the library's `include/` directory to Zephyr and defines `CONFIG_MYLIBRARY` for Swift code when that symbol is enabled:

```cmake
zephyr_swift_library(MODULE_NAME MyLibrary)
```

```swift
// MyLibrary.swift
public func myFunction() -> String {
  "Hello from MyLibrary!"
}
```

An application imports it with `import MyLibrary`. `samples/app+lib` shows the full setup, including the Kconfig option that enables the library.

### The Zephyr library

```swift
import Zephyr

sleep(Duration.milliseconds(250))     // relative timeout, rounded up to whole ticks
sleep(Forever())                      // K_FOREVER

let start = now()                     // kernel ticks since boot
let elapsed = now().duration(since: start)

do {
  try check(code)                     // code < 0 is -errno
} catch ZephyrError.timedOut {
  retry()
} catch {
  report(error)                       // every other ZephyrError case
}
```

`Instant` and `now()` are available when the build defines `CONFIG_TIMEOUT_64BIT`, which Zephyr's default configuration does.

## Configuration

| Option                    | Description                                                     | Default        |
| ------------------------- | --------------------------------------------------------------- | -------------- |
| `CONFIG_SWIFT`            | Enable Swift language support                                   | `n`            |
| `CONFIG_SWIFT_DEBUG_INFO` | Define `SWIFT_DEBUG_INFO` for Swift code; adds no debug symbols | `y` if `DEBUG` |

With `CONFIG_SWIFT=y`, the module also makes `CONFIG_LOG_MODE_IMMEDIATE` the default log mode, so `Log` output and `print()` output appear in order. Set `CONFIG_LOG_MODE_DEFERRED=y` in `prj.conf` to use deferred logging instead. `Log` logs nothing with `CONFIG_LOG_MODE_MINIMAL=y`, which builds no logging core to log into.

Swift code cannot see `CONFIG_*` macros, so a Kconfig symbol used in an `#if` needs a matching `-D` in `_swift_defines()` in `CMakeLists.txt`, which writes it to the build's SwiftPM toolset. `CONFIG_TIMEOUT_64BIT`, `CONFIG_LOG` and `CONFIG_LOG_MODE_DEFERRED` already have one.

These CMake cache options change how the Swift package is built. Pass them to `west build` after `--`, for example `west build -- -DZEPHYR_SWIFT_OFFLINE=ON`:

| Option                      | Description                                                                                      | Default  |
| --------------------------- | ------------------------------------------------------------------------------------------------ | -------- |
| `ZEPHYR_SWIFT_OFFLINE`      | Never resolve package dependencies; fail when `Package.resolved` is missing or stale. Use in CI. | `OFF`    |
| `ZEPHYR_SWIFT_LSP_CONFIG`   | Write `.sourcekit-lsp/config.json` into the application package for the editor                   | `ON`     |
| `ZEPHYR_SWIFT_BUILD_SYSTEM` | The SwiftPM build system                                                                         | `native` |

## Architecture

```text
swift/
├── Package.swift      # ZephyrCore, ZephyrSystem, Zephyr, ZephyrApplication
├── CMakeLists.txt     # zephyr_swift_application(), zephyr_swift_library()
├── Kconfig            # CONFIG_SWIFT, CONFIG_SWIFT_DEBUG_INFO
├── zephyr-sys/
│   ├── include/       # ZephyrCore: BridgingHeader.h and module.modulemap
│   └── src/           # ZephyrSystem: init, kernel, log, malloc and timeout
├── zephyr/
│   ├── lib/           # Zephyr: Duration, Timeout, Instant, sleep, Log, ZephyrError
│   └── src/           # ZephyrApplication: the C main that calls entrypoint()
├── samples/           # app, lib and app+lib
├── plugins/           # Claude Code plugin
├── doc/               # Installation guide
└── tests/             # Reserved for Ztest/Twister cases (empty)
```

The package's targets depend on each other in this order: `ZephyrCore` (a Clang module over `BridgingHeader.h`) ← `ZephyrSystem` ← `Zephyr` ← `ZephyrApplication` ← the application.

Swift imports headers that only a Zephyr build generates, and its target options depend on Kconfig, so `swift build` does not run on its own. `west build` drives it:

1. Kconfig turns Swift support on, and configuring writes `.build/swift/toolset.json`: `-Osize`, the Zephyr include paths, the C library headers and the Kconfig defines.
2. Zephyr generates its headers.
3. `swift build --product App` builds the application's package for the board's target triple, into `.build/swift/`.
4. The static library it produces is linked into the Zephyr image with `--whole-archive`, so that Swift's `main` replaces the kernel's weak one.

## Supported architectures

The build system maps these CPUs to a Swift target triple. Only the RISC-V 32-bit target has been built and run, in QEMU (`qemu_riscv32/qemu_virt_riscv32/smp`) with Zephyr SDK 1.0.1.

| Architecture                | Target triple                 | Status                |
| --------------------------- | ----------------------------- | --------------------- |
| Arm Cortex-M0/M0+/M1        | `thumbv6m-none-eabi`          | mapped, not tested    |
| Arm Cortex-M3               | `thumbv7m-none-eabi`          | mapped, not tested    |
| Arm Cortex-M4/M7            | `thumbv7em-none-eabi[hf]`     | mapped, not tested    |
| Arm Cortex-M23/M33/M35P/M55 | `thumbv8m.main-none-eabi[hf]` | mapped, not tested    |
| Arm 64-bit (AArch64)        | `aarch64-none-elf`            | mapped, not tested    |
| RISC-V 32-bit               | `riscv32-none-none-eabi`      | built and run in QEMU |
| RISC-V 64-bit               | `riscv64-none-none-eabi`      | mapped, not tested    |

## Development

Rules for contributors and agents (code style, Embedded Swift constraints, commits, pull requests) are in [AGENTS.md](AGENTS.md).

To add an architecture, map it to a Swift target triple in `_swift_map_target()` in `CMakeLists.txt` and build a sample for it.

To add runtime support that Swift needs from C:

1. Declare the C function in `zephyr-sys/include/core.h`, which `BridgingHeader.h` includes.
2. Implement it in `zephyr-sys/src` with `@c @implementation`, so the compiler checks the signature against the declaration.
3. Document it. Target options belong in `_swift_write_toolset()` in `CMakeLists.txt`; language settings belong in the `settings` of each `Package.swift`.

### Working on Swift code

`west build` remains the way to build and run an image. To iterate on Swift without building the whole image, let CMake generate the build directory first. Configuring writes the SwiftPM toolset, `.build/swift/swift-build.sh` with the exact `swift build` command, and `.sourcekit-lsp/config.json` in the application package, so SourceKit-LSP in your editor resolves `ZephyrCore` and the Zephyr headers of that build:

```bash
cd samples/app
west build -b qemu_riscv32/qemu_virt_riscv32/smp --cmake-only   # generate .build/ with CMake
west build -t swift_build                                       # generate Zephyr's headers, compile Swift
.build/swift/swift-build.sh                                      # recompile Swift only; add -v to see the flags
west build -t run                                               # build and run the image
```

`swift-build.sh` needs the headers that the `swift_build` target generates, and says so if they are missing. Configuring with plain CMake works the same way: `cmake -G Ninja -B build -DBOARD=qemu_riscv32/qemu_virt_riscv32/smp`, then `ninja -C build swift_build`.

To use another SwiftPM package, add it to the application's `Package.swift` and rebuild. SwiftPM resolves it on the next build and caches it under `.build/swift/cache`. Commit the `Package.resolved` it writes, so every build uses the same versions, and configure CI with `-DZEPHYR_SWIFT_OFFLINE=ON`. The package must build with Embedded Swift for a bare-metal target: no Foundation, and no unsafe flags when it is pinned to a version range.

Check a change by building both buildable samples:

```bash
(cd samples/app && west build -p -t run)
(cd samples/app+lib/app && west build -p -t run)
```

## Troubleshooting

| Symptom                                         | Likely cause and fix                                                                                         |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `unable to load standard library for target`    | Xcode's Swift was selected. Set `TOOLCHAINS=swift` and use a Swift 6.4+ toolchain from swift.org.            |
| `Unable to find 'x86_64-zephyr-elf'` in the SDK | `ZEPHYR_TOOLCHAIN_VARIANT` is not set. Use `zephyr/llvm`.                                                    |
| `could not build C module 'ZephyrCore'`         | Zephyr has not generated its headers. Build the `swift_build` target or the image, not `swift build` alone.  |
| `no Package.swift in ... or a parent directory` | The application has no Swift package. Add a `Package.swift`, or pass `PACKAGE_DIR`.                          |
| `undefined reference to 'entrypoint'`           | The application has no `@c(entrypoint) func entrypoint()`.                                                   |
| `no such module` for a library                  | The application's `Package.swift` does not depend on the library's target or product.                        |
| Package resolution fails                        | A dependency cannot be fetched. Check the network, or build offline from a committed `Package.resolved`.     |
| Stale Swift errors after moving a build         | `.build/swift` holds SwiftPM's state for the old paths. Rebuild with `west build -p`.                        |
| A header edit changes nothing                   | SwiftPM does not rebuild when only a `ZephyrCore` header changes. Edit a Swift file too, or `west build -p`. |
| `'--build-system native' has been deprecated`   | Expected: SwiftPM's default build system cannot archive ELF objects yet (see `ZEPHYR_SWIFT_BUILD_SYSTEM`).   |

## License

Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

This project is licensed under the GNU General Public License, version 3 (GPL-3.0). See [LICENSE](LICENSE) for details.
