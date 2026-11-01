# Swift Language Support for Zephyr

A Zephyr module that lets you write applications and libraries in Embedded Swift. It provides the CMake functions that compile Swift for a Zephyr target, the runtime support that Embedded Swift needs, and a small Swift library over the Zephyr kernel.

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

- **CMake functions**: `zephyr_swift_application()` builds the Swift sources in `src/` into a Zephyr application, and `zephyr_swift_library()` builds a Swift module that applications can import.
- **Kconfig options**: `CONFIG_SWIFT` turns Swift support on, and `CONFIG_SWIFT_DEBUG_INFO` defines `SWIFT_DEBUG_INFO` for `#if` blocks in Swift code.
- **Runtime support** (`ZephyrSystem`): `posix_memalign` on top of the libc's `aligned_alloc`, which the Embedded Swift runtime calls for every heap allocation, and thin wrappers over the kernel (`Kernel`, `k_timeout_t` helpers).
- **Zephyr library** (`Zephyr`): `Duration`, `Timeout`, `Instant`, `sleep(_:)`, and `ZephyrError` with `check(_:)`, which turns a `-errno` return code into a typed throw.
- **C interoperability**: a bridging header exposes the Zephyr C APIs to Swift, and C functions can be implemented in Swift with `@c @implementation`.
- **Claude Code plugin** (`plugins/`): scaffolds a project, an application or a library.

## Prerequisites

1. A Swift 6.4 or later toolchain from swift.org with Embedded Swift support. Xcode's Swift lacks the RISC-V and Arm embedded backends, so select the swift.org toolchain with `TOOLCHAINS=swift`. With swiftly:

   ```bash
   swiftly install 6.4.0
   export TOOLCHAINS=swift
   ```

2. A Zephyr workspace with the Zephyr SDK and its LLVM toolchain (`ZEPHYR_TOOLCHAIN_VARIANT=zephyr/llvm`). The module was built and run with Zephyr SDK 1.0.1.
3. CMake 3.29 or later, `west`, and Git.

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

2. Build the Swift sources in `src/` from `CMakeLists.txt`:

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

3. Define the entry point in `src/Entrypoint.swift`. The C `main` provided by this module calls it:

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

4. Build and run it in QEMU, with the board and toolchain from your environment:

   ```bash
   west build -p -t run
   ```

`samples/` has working versions of all of this, including the `.env.example` that sets the board and toolchain. See [samples/README.md](samples/README.md).

### A library

Put the library in its own directory with a `CMakeLists.txt` that names the module, and expose it as a Zephyr module with `zephyr/module.yml`:

```cmake
zephyr_swift_library(MODULE_NAME MyLibrary)
```

```swift
// MyLibrary.swift
public func myFunction() -> String {
  "Hello from MyLibrary!"
}
```

An application imports it with `import MyLibrary` once the module is in its `ZEPHYR_EXTRA_MODULES`. `samples/app+lib` shows the full setup, including the Kconfig option that gates the library.

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

Swift code cannot see `CONFIG_*` macros, so a Kconfig symbol used in an `#if` needs a matching `-D` in the module's `swiftc` calls. `CONFIG_TIMEOUT_64BIT` already has one.

## Architecture

```text
swift/
├── CMakeLists.txt     # zephyr_swift_application(), zephyr_swift_library()
├── Kconfig            # CONFIG_SWIFT, CONFIG_SWIFT_DEBUG_INFO
├── zephyr-sys/        # ZephyrSystem: runtime support in Swift
│   ├── src/           # init, kernel, malloc and timeout sources
│   └── include/       # BridgingHeader.h and module.modulemap
├── zephyr/            # Zephyr: the high-level Swift library
│   ├── lib/           # Duration, Timeout, Instant, sleep, ZephyrError, check
│   └── src/           # Application.swift: the C main that calls entrypoint()
├── samples/           # app, lib and app+lib
├── plugins/           # Claude Code plugin
├── doc/               # Installation guide
└── tests/             # Reserved for Ztest/Twister cases (empty)
```

Swift is compiled with plain `swiftc` calls, not SwiftPM. The build order is:

1. Kconfig turns Swift support on.
2. `ZephyrSystem` is compiled from `zephyr-sys/src`, with `BridgingHeader.h` as the bridging header.
3. `Zephyr` is compiled from `zephyr/lib` and imports `ZephyrSystem`.
4. The application, and any libraries it uses, are compiled against both modules.
5. Everything is linked into the Zephyr image.

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

1. Declare the C function in `zephyr-sys/include/BridgingHeader.h`.
2. Implement it in `zephyr-sys/src` with `@c @implementation`, so the compiler checks the signature against the declaration.
3. Document it, and keep the `swiftc` flag lists in `zephyr-sys`, `zephyr` and the root `CMakeLists.txt` in step.

Check a change by building both buildable samples:

```bash
(cd samples/app && west build -p -t run)
(cd samples/app+lib/app && west build -p -t run)
```

## Troubleshooting

| Symptom                                         | Likely cause and fix                                                                              |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `unable to load standard library for target`    | Xcode's Swift was selected. Set `TOOLCHAINS=swift` and use a Swift 6.4+ toolchain from swift.org. |
| `Unable to find 'x86_64-zephyr-elf'` in the SDK | `ZEPHYR_TOOLCHAIN_VARIANT` is not set. Use `zephyr/llvm`.                                         |
| `error: unknown argument: '...'` from swiftc    | A flag that swiftc does not accept is in one of the module's `swiftc` calls (see Development).    |
| `undefined reference to 'entrypoint'`           | The application has no `@c(entrypoint) func entrypoint()`.                                        |
| `no such module` for a library                  | The library is missing from `ZEPHYR_EXTRA_MODULES`, or its Kconfig option is off.                 |

## License

Copyright (c) [<schubert@anselm.es>](mailto:schubert@anselm.es)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
