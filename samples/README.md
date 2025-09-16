# Sample Applications and Libraries

This directory contains comprehensive examples demonstrating how to use Swift with Zephyr RTOS. The samples showcase different aspects of Swift development for embedded systems, from basic applications to reusable library modules.

## Overview

The samples are organized to demonstrate progressive complexity and different use cases:

- **Basic Applications**: Simple Swift programs that run on Zephyr
- **Library Modules**: Reusable Swift libraries that can be imported by applications
- **Advanced Examples**: Complex integrations showcasing advanced Swift and Zephyr features

## Sample Structure

### Application Samples (`app/`)

Complete Swift applications that can be built and run on Zephyr boards.

**Key Features Demonstrated:**

- Swift application structure and entry points
- Integration with Zephyr's main application framework
- Basic Swift syntax and embedded-appropriate programming patterns
- Configuration through `prj.conf` and CMake

**Files in Application Samples:**

- `src/Entrypoint.swift`: Main Swift application logic
- `CMakeLists.txt`: Build configuration using `swift_application()`
- `prj.conf`: Zephyr configuration enabling Swift support
- `sample.yml`: Sample metadata for testing and documentation

### Library Module Samples (`modules/`)

Reusable Swift libraries that demonstrate how to create modular Swift code for Zephyr.

**Key Features Demonstrated:**

- Swift library/module creation and organization
- Module configuration through Kconfig
- Inter-module dependencies and imports
- Public API design for Swift libraries

**Example: Hello Module (`modules/hello/`)**

- `lib/Hello.swift`: Swift library implementation
- `zephyr/module.yml`: Zephyr module definition
- `CMakeLists.txt`: Library build configuration
- `Kconfig`: Module-specific configuration options

## Getting Started

### Prerequisites

1. **Swift Toolchain**: Ensure you have Swift with Embedded Swift support installed
2. **Zephyr SDK**: Have Zephyr RTOS SDK properly configured
3. **Target Board**: A supported Zephyr board (physical or emulated)

### Building and Running Samples

#### Basic Application Sample

1. **Navigate to the application directory:**

   ```bash
   cd samples/app/
   ```

2. **Build for your target board:**

   ```bash
   west build -b <your_board>
   ```

3. **Flash and run:**
   ```bash
   west flash
   west attach
   ```

#### Library Module Sample

1. **Navigate to a project that uses the library:**

   ```bash
   cd samples/app/  # This app can import the hello module
   ```

2. **Ensure the library module is in the build path:**

   ```bash
   # The build system automatically discovers modules in samples/modules/
   ```

3. **Build with library support:**
   ```bash
   west build -b <your_board>
   ```

### Sample Applications

#### Hello World Application (`app/`)

**Purpose**: Demonstrates basic Swift application structure for Zephyr.

**Features:**

- Simple Swift entry point with `@_cdecl("entrypoint")`
- Basic print statements and control flow
- Integration with Zephyr's sleep and timing functions
- Proper configuration for Swift compilation

**Code Highlights:**

```swift
@_cdecl("entrypoint")
func entrypoint() {
    print("Hello from Swift!!!")

    while true {
        print("still running...")
        // Use Zephyr's sleep function
        k_sleep(K_MSEC(2000))
    }
}
```

#### Hello Library Module (`modules/hello/`)

**Purpose**: Demonstrates creating reusable Swift libraries for Zephyr.

**Features:**

- Swift library with public API
- Module configuration through Kconfig
- Integration with Zephyr's module system
- Template for creating custom libraries

**Code Highlights:**

```swift
public func greet(_ name: String) -> String {
    return "Hello, \(name) from Swift library!"
}

public struct HelloConfig {
    public static let version = "1.0.0"
}
```

## Development Patterns

### Application Development

**Entry Point Pattern:**

```swift
@_cdecl("entrypoint")
func entrypoint() {
    // Your application logic here
}
```

**Zephyr Integration:**

```swift
import Zephyr

func useZephyrAPIs() {
    // Access Zephyr kernel functions
    k_sleep(K_MSEC(1000))

    // Use Zephyr device APIs
    // let gpio = device_get_binding("GPIO_0")
}
```

### Library Development

**Public API Design:**

```swift
// Make functions and types public for other modules
public func libraryFunction() -> String {
    return "Library response"
}

public struct LibraryType {
    public let value: Int
    public init(value: Int) {
        self.value = value
    }
}
```

**Module Configuration:**

- Use Kconfig for optional features
- Provide sensible defaults
- Document configuration options

## Configuration Examples

### Basic Swift Application (`prj.conf`)

```kconfig
# Enable Swift language support
CONFIG_SWIFT=y

# Enable debug information during development
CONFIG_SWIFT_DEBUG_INFO=y

# Standard Zephyr options
CONFIG_PRINTK=y
CONFIG_CONSOLE=y
CONFIG_UART_CONSOLE=y
```

### Application with Library Modules

```kconfig
# Enable Swift and specific modules
CONFIG_SWIFT=y
CONFIG_HELLO=y  # Enable the Hello library module

# Debug configuration
CONFIG_SWIFT_DEBUG_INFO=y
CONFIG_DEBUG=y
```

## Testing Samples

### Automated Testing

The samples include automated test configurations:

```bash
# Run sample tests using Zephyr's testing framework
west twister -T samples/ --platform qemu_riscv32
```

### Manual Testing

1. **Build for QEMU:**

   ```bash
   west build -b qemu_riscv32
   ```

2. **Run in emulation:**

   ```bash
   west build -t run
   ```

3. **Verify output:**
   Look for Swift print statements in the console output.

## Customizing Samples

### Creating New Applications

1. **Copy the basic app structure:**

   ```bash
   cp -r samples/app/ my_new_app/
   ```

2. **Modify the Swift code:**
   Edit `src/Entrypoint.swift` with your application logic.

3. **Update configuration:**
   Modify `prj.conf` and `CMakeLists.txt` as needed.

### Creating New Libraries

1. **Copy the hello module structure:**

   ```bash
   cp -r samples/modules/hello/ samples/modules/my_library/
   ```

2. **Update the module definition:**
   - Change the module name in `zephyr/module.yml`
   - Update Kconfig options and help text
   - Modify the CMakeLists.txt module name

3. **Implement your library:**
   Replace the Swift code in `lib/` with your implementation.

## Best Practices

### Performance Considerations

- Use `@_optimize(speed)` or `@_optimize(size)` attributes where appropriate
- Prefer value types over reference types for better performance
- Minimize dynamic memory allocation in embedded contexts

### Memory Management

- Be aware of Swift's automatic reference counting (ARC)
- Use `@_unsafeInheritExecutor` for performance-critical code
- Consider memory constraints of your target platform

### Debugging

- Enable `CONFIG_SWIFT_DEBUG_INFO=y` during development
- Use conditional compilation for debug-only code:
  ```swift
  #if SWIFT_DEBUG_INFO
      print("Debug: operation completed")
  #endif
  ```

### Integration

- Follow Zephyr's naming conventions for consistency
- Use Zephyr's error handling patterns
- Integrate properly with Zephyr's device model when needed

## Troubleshooting

### Common Issues

1. **Build Failures:**
   - Verify Swift toolchain installation
   - Check that CONFIG_SWIFT=y in prj.conf
   - Ensure target architecture is supported

2. **Runtime Issues:**
   - Check stack size configuration
   - Verify memory constraints are met
   - Enable debug information for better error messages

3. **Module Import Issues:**
   - Ensure module is properly configured in Kconfig
   - Check that module build dependencies are correct
   - Verify module.yml configuration

### Getting Help

- Check the main README.md for general Swift support information
- Review Zephyr documentation for board-specific requirements
- Examine build logs for specific error messages
- Test with QEMU emulation before hardware deployment
