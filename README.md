# Swift Language Support

A comprehensive module that enables Swift programming language support in Zephyr RTOS projects, bringing modern language features and memory safety to embedded systems development.

## Overview

This module integrates Swift's powerful programming language capabilities with Zephyr RTOS, enabling developers to write embedded applications using Swift's modern syntax, type safety, and performance characteristics. The module provides complete toolchain integration, runtime support, and seamless C-Swift interoperability.

## Features

### Core Capabilities

- **Cross-compilation Support**: Compile Swift code for ARM Cortex-M, RISC-V, and AArch64 targets
- **Embedded Swift Integration**: Full support for Embedded Swift experimental features
- **Memory Safety**: Leverage Swift's memory management and safety features in embedded contexts
- **Performance Optimization**: Whole-module optimization and size-optimized builds for embedded systems

### Build System Integration

- **CMake Integration**: Native CMake functions for Swift applications and libraries
- **Kconfig Support**: Configuration options integrated with Zephyr's configuration system
- **Dependency Management**: Automatic dependency resolution between Swift modules
- **Module System**: Support for reusable Swift libraries and modules

### Runtime Support

- **C Runtime Stubs**: Implementation of required C library functions for Swift runtime
- **Memory Allocation**: Custom aligned memory allocation for Swift's requirements
- **POSIX Compatibility**: Essential POSIX function stubs for Swift runtime operation
- **Bridging Headers**: Seamless integration between Swift and Zephyr C APIs

## Quick Start

### Prerequisites

1. **Swift Toolchain**: Install Swift with Embedded Swift support

   ```bash
   # Download and install Swift toolchain with embedded support
   # Follow Swift.org installation instructions for your platform
   ```

2. **Zephyr SDK**: Ensure you have Zephyr SDK installed and configured

### Enabling Swift Support

1. **Configure your project** (`prj.conf`):

   ```kconfig
   CONFIG_SWIFT=y
   CONFIG_SWIFT_DEBUG_INFO=y  # Optional, for debug builds
   ```

2. **Create a Swift application** (`CMakeLists.txt`):

   ```cmake
   find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
   project(my_swift_app)

   swift_application()
   ```

3. **Write Swift code** (`src/main.swift`):

   ```swift
   import Zephyr

   @_cdecl("entrypoint")
   func entrypoint() {
       print("Hello from Swift on Zephyr!")

       while true {
           // Your embedded Swift application logic
           k_sleep(K_MSEC(1000))
       }
   }
   ```

### Building Swift Libraries

Create reusable Swift libraries for your projects:

```cmake
# In your library's CMakeLists.txt
swift_library(MODULE_NAME MyLibrary)
```

```swift
// In lib/MyLibrary.swift
public func myFunction() -> String {
    return "Hello from MyLibrary!"
}
```

## Architecture

### Module Structure

```empty
swift/
├── CMakeLists.txt          # Main build configuration
├── Kconfig                 # Configuration options
├── toolchain.cmake         # Swift toolchain integration
├── zephyr-sys/             # C runtime support library
│   ├── src/                # C stub implementations
│   └── include/            # Bridging headers and module maps
├── zephyr/                 # Core Swift library
│   ├── lib/                # Swift Zephyr bindings
│   └── src/                # Application bootstrap
├── cmake/                  # CMake helper functions
│   ├── Application.cmake   # swift_application() function
│   └── Library.cmake       # swift_library() function
└── samples/                # Example applications and libraries
```

### Compilation Flow

1. **Configuration**: Kconfig options enable Swift support
2. **Toolchain Setup**: Swift compiler configured for target architecture
3. **Runtime Building**: zephyr-sys C library provides Swift runtime support
4. **Core Library**: Zephyr Swift library compiled with Zephyr bindings
5. **Application/Library**: User Swift code compiled and linked
6. **Integration**: All components linked into final Zephyr binary

## Supported Architectures

| Architecture                | Status | Target Triple                 |
| --------------------------- | ------ | ----------------------------- |
| ARM Cortex-M0/M0+/M1        | ✅     | `thumbv6m-none-eabi`          |
| ARM Cortex-M3               | ✅     | `thumbv7m-none-eabi`          |
| ARM Cortex-M4/M7            | ✅     | `thumbv7em-none-eabi[hf]`     |
| ARM Cortex-M23/M33/M35P/M55 | ✅     | `thumbv8m.main-none-eabi[hf]` |
| ARM 64-bit (AArch64)        | ✅     | `aarch64-none-elf`            |
| RISC-V 32-bit               | ✅     | `riscv32-none-none-eabi`      |
| RISC-V 64-bit               | ✅     | `riscv64-none-none-eabi`      |

## Examples

### Basic Application

See `samples/app/` for a complete Swift application example.

### Swift Library Module

See `samples/modules/hello/` for a reusable Swift library example.

### Advanced Integration

Check the `tests/` directory for comprehensive integration examples.

## Configuration Options

| Option                    | Description                   | Default        |
| ------------------------- | ----------------------------- | -------------- |
| `CONFIG_SWIFT`            | Enable Swift language support | `n`            |
| `CONFIG_SWIFT_DEBUG_INFO` | Include debug information     | `y` if `DEBUG` |

## Development

### Adding New Architectures

To add support for a new architecture:

1. Update `_swift_map_target()` in `toolchain.cmake`
2. Add appropriate Swift target triple mapping
3. Test cross-compilation for the new target

### Extending Runtime Support

To add new C runtime functions:

1. Add stub implementations to `zephyr-sys/src/`
2. Update `BridgingHeader.h` to expose new functions
3. Document the additions in relevant files

## Troubleshooting

### Common Issues

1. **Swift Toolchain Not Found**
   - Ensure Swift is installed and in your PATH
   - Verify Embedded Swift support is available

2. **Compilation Errors**
   - Check target architecture support
   - Verify Kconfig options are correct
   - Ensure all dependencies are built

3. **Linking Issues**
   - Verify proper build order with dependencies
   - Check that all required libraries are linked

### Debug Information

Enable debug builds for better error messages:

```kconfig
CONFIG_SWIFT_DEBUG_INFO=y
CONFIG_DEBUG=y
```

## Contributing

Contributions are welcome! Please ensure:

- All new features include comprehensive documentation
- Code follows the existing style and patterns
- Changes are tested across supported architectures
- Commit messages are clear and descriptive

---

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
