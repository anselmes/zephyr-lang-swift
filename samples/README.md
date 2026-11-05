# Swift Samples

Three samples show how to build Swift applications and libraries for Zephyr with this module. Each is a Swift package (`Package.swift`) that depends on this module's package by path, and the applications are built and run with `west`, and each has been built for `qemu_riscv32/qemu_virt_riscv32/smp` with Zephyr SDK 1.0.1 and its LLVM toolchain. Other boards are not covered by these samples.

## Table of Contents

- [Samples](#samples)
- [Prerequisites](#prerequisites)
- [Build and run](#build-and-run)
- [Application: app](#application-app)
- [Application with a library: app+lib](#application-with-a-library-applib)
- [Library: lib](#library-lib)
- [Configuration](#configuration)
- [Create your own](#create-your-own)
- [Troubleshooting](#troubleshooting)

## Samples

| Directory | What it is                                                              | Build it with `west` |
| --------- | ----------------------------------------------------------------------- | -------------------- |
| `app`     | A Swift application that prints a greeting and sleeps in a loop         | yes                  |
| `app+lib` | A Zephyr module with the Hello library, plus an application using it    | yes                  |
| `lib`     | The Hello library as a standalone Zephyr module, without an application | no                   |

`lib` and `app+lib/lib` contain the same Hello library. `app+lib` is the self-contained combined sample; `lib` is the standalone module for readers who want only the library. A module is not an application, so running `west build` in `lib` fails with `Unknown CMake command "add_subdirectory_ifdef"`.

## Prerequisites

1. A Swift 6.4 or later toolchain from swift.org with Embedded Swift support. Xcode's Swift lacks the RISC-V and Arm embedded backends. Select the swift.org toolchain with `TOOLCHAINS=swift`.
2. A Zephyr workspace with the Zephyr SDK (1.0.1 was used) and its LLVM toolchain.
3. This repository registered as a Zephyr module in that workspace. The samples do not register it: without it `CONFIG_SWIFT` and `zephyr_swift_application()` do not exist. Add it to the west manifest first, then enable the `optional` group and fetch it (`west config manifest.group-filter -- +optional`, `west update zephyr-lang-swift`), as described in [Add through the west manifest](../doc/README.md#add-through-the-west-manifest).
4. A board, physical or emulated. The samples use QEMU.

The samples read the board and toolchain from environment variables. Copy `.env.example` to `.env` in the application directory, adjust `ZEPHYR_WORKSPACE`, and source it:

```bash
cd samples/app
cp .env.example .env
source .env
```

The combined sample is its own application, so its `.env.example` sits next to its `CMakeLists.txt`:

```bash
cd samples/app+lib
cp .env.example .env
source .env
```

`.env` is git-ignored. The variables it sets are `ZEPHYR_WORKSPACE`, `TOOLCHAINS`, `ZEPHYR_TOOLCHAIN_VARIANT` (`zephyr/llvm`) and `ZEPHYR_BOARD`.

## Build and run

From an application directory, with the environment sourced:

```bash
west build -p -t run
```

`-p` starts from a clean build directory and `-t run` boots the image in QEMU. Leave QEMU with `Ctrl+a`, then `x`. For another board, pass it with `-b <board>`, which takes precedence over `ZEPHYR_BOARD`, and use `west flash` and `west attach` instead of `-t run`.

## Application: app

`app/src/Entrypoint.swift` defines the entry point, which the C `main` in `zephyr/src/Application.swift` calls:

```swift
@c(entrypoint)
func entrypoint() {
  print("Hello from Swift!!!")
  while true {
    sleep(Duration.milliseconds(1000))
  }
}
```

Expected output:

```text
*** Booting Zephyr OS build <version> ***
Hello from Swift!!!
```

## Application with a library: app+lib

The application is `app+lib` itself, which is also a Zephyr module. `app+lib/Package.swift` describes both the `Hello` library target (`lib/hello`) and the `App` target (`src`) that depends on it, and `zephyr_swift_application()` in `CMakeLists.txt` finds that manifest in the same directory. The `CMakeLists.txt` also appends its own directory to `ZEPHYR_EXTRA_MODULES`: it is a Zephyr module (`zephyr/module.yml`) that provides the library's Kconfig option, which the application's `prj.conf` enables with `CONFIG_HELLO=y`. The source imports the library:

```swift
import Hello
import Zephyr

@c(entrypoint)
func entrypoint() {
  print("Hello from Swift app+lib!!!")
  Hello.run()
  while true {
    sleep(Duration.milliseconds(2000))
  }
}
```

`Hello.run()` never returns, so the `while true` loop after it is never reached. Expected output:

```text
Hello from Swift app+lib!!!
Hello from Swift!!!
```

The library logs `still running...` every second with `Log.info`, which prints only when logging is on. Uncomment `CONFIG_LOG=y` in `prj.conf` to see it:

```text
Hello from Swift app+lib!!!
Hello from Swift!!!
[00:00:01.020,000] <inf> swift: still running...
[00:00:02.030,000] <inf> swift: still running...
```

The application's source files are in `app+lib/src`.

## Library: lib

The Hello library (`lib/hello`) exports two entry points, both of which print a greeting and then log `still running...` every `timeout` milliseconds, and never return:

```swift
public func hello(timeout: Int = 1000)

public struct Hello {
  public static func run(timeout: Int = 1000)
}
```

`lib/Package.swift` makes the library a package of its own with a `Hello` product, which an application adds to its `Package.swift`; SwiftPM then compiles it as part of the application. `lib/hello/Kconfig` defines `CONFIG_HELLO`, and `lib/CMakeLists.txt` registers the library with `zephyr_swift_library(MODULE_NAME Hello)` only when it is set, which defines `CONFIG_HELLO` for Swift code.

## Configuration

Both applications set these options in `prj.conf`:

| Option                                 | Purpose                                                                                           |
| -------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `CONFIG_SWIFT`                         | Enables Swift support                                                                             |
| `CONFIG_MINIMAL_LIBC`                  | The libc that the Embedded Swift runtime allocates through                                        |
| `CONFIG_COMMON_LIBC_MALLOC_ARENA_SIZE` | Heap size in bytes. The minimal libc defaults it to zero, so set it for the board and application |
| `CONFIG_SWIFT_DEBUG_INFO`              | Optional. Defines `SWIFT_DEBUG_INFO` for `#if` blocks; adds no `-g`                               |
| `CONFIG_LOG`                           | Optional. Prints `Log` output, including the `CONFIG_SWIFT_DEBUG_INFO` lines                      |
| `CONFIG_HELLO`                         | `app+lib` only. Builds the Hello library                                                          |

## Create your own

To start an application, copy `app` and edit `src/Entrypoint.swift`, `prj.conf`, `CMakeLists.txt` and `Package.swift`. The copy depends on this module by the relative path `../..`, so change that path, or use the URL form shown in the [README](../README.md#an-application):

```bash
cp -r samples/app my_app
```

To start a library, copy the whole module (`app+lib/zephyr/module.yml` and `app+lib/lib/`, not just `lib/hello`), rename the library, its Kconfig option and its `zephyr/module.yml` entry, and add it as a target to a `Package.swift`. Then add the library to the application's `Package.swift`, and the copied module root to `ZEPHYR_EXTRA_MODULES` in the application's `CMakeLists.txt` so Zephyr discovers its Kconfig option. The repository also ships a Claude Code plugin (`plugins/`) that scaffolds both.

## Troubleshooting

| Symptom                                         | Likely cause and fix                                                                              |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `unable to load standard library for target`    | Xcode's Swift was selected. Set `TOOLCHAINS=swift` and use a Swift 6.4+ toolchain from swift.org. |
| `Unable to find 'x86_64-zephyr-elf'` in the SDK | `ZEPHYR_TOOLCHAIN_VARIANT` is not set. Source `.env` (it sets `zephyr/llvm`).                     |
| `BOARD is not being defined`                    | Neither `ZEPHYR_BOARD` nor `-b <board>` gave a board. Source `.env`, or pass `-b <board>`.        |
| `no such module 'Hello'`                        | The application's `Package.swift` does not depend on the `Hello` target or product.               |
| `could not build C module 'ZephyrSystem'`       | Zephyr has not generated its headers yet. Build with `west build`, not `swift build` alone.       |
| `west twister -T samples/` finds nothing        | The `sample.yml` files have no `tests:` section yet, so twister has no test cases to run.         |
