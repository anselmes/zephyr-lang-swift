# Zephyr Swift Integration

Install the Swift module for Zephyr and make an application find it. For what the module provides and how to use it, see the [README](../README.md).

## Prerequisites

- Zephyr RTOS and the Zephyr SDK with its LLVM toolchain (1.0.1 was used)
- A Swift 6.4 or later toolchain from swift.org with Embedded Swift support, selected with `TOOLCHAINS=swift`. Xcode's Swift cannot target RISC-V or Arm embedded
- CMake 3.29 or later
- Git

## Installation

### Clone as a Zephyr module

Clone the `zephyr-lang-swift` repository into your Zephyr modules directory:

```bash
git clone https://github.com/anselmes/zephyr-lang-swift modules/lang/swift
```

Then add this line to the application's `CMakeLists.txt`, before `find_package(Zephyr)`. The clone lives in the Zephyr workspace, so the path starts at `ZEPHYR_WORKSPACE`; replace it with the checkout's location if you keep the clone elsewhere:

```cmake
set(ZEPHYR_EXTRA_MODULES $ENV{ZEPHYR_WORKSPACE}/modules/lang/swift)
```

### Add through the west manifest

Add the following to `$ZEPHYR_BASE/submanifests/optional.yaml`:

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

This method needs no change to `CMakeLists.txt`.

The fork and the manifest entry both place the module in the `optional` group, which west disables by default. Enable the group and fetch the module before building:

```bash
west config manifest.group-filter -- +optional
west update zephyr-lang-swift
```

### Use the Zephyr fork

The [anselmes/zephyr](https://github.com/anselmes/zephyr) fork carries the module. It keeps the module in the same `optional` group, so run the two `west` commands above to enable it.

## Example

After installing, add Swift sources to a Zephyr application or library. `samples/app` is a minimal application and `samples/app+lib/lib/hello/Hello.swift` is a small library. [samples/README.md](../samples/README.md) explains how to build and run them.

## Troubleshooting

- **Build errors?** Check that the swift.org toolchain is the one `swiftc` resolves to: set `TOOLCHAINS=swift` and run `swiftc --version`.
- **Zephyr cannot find the module?** Check the module path in `CMakeLists.txt` or the manifest.
- **`BOARD is not being defined`?** The samples read `ZEPHYR_BOARD` and `ZEPHYR_TOOLCHAIN_VARIANT` from the environment; source the `.env` created from `.env.example`.

## Contributing

The rules for code, commits and pull requests are in [AGENTS.md](../AGENTS.md). Issues and pull requests are welcome.

## Resources

- [Zephyr Documentation](https://docs.zephyrproject.org/)
- [Swift Language](https://swift.org/)
- [Project Issues](https://github.com/anselmes/zephyr-lang-swift/issues)
