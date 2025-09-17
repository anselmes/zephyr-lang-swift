
# Zephyr Swift Integration

Enable Swift language support in Zephyr RTOS projects with this module.

---

## Overview

This repository provides seamless integration of Swift into Zephyr-based applications. It allows you to write Zephyr modules and applications in Swift, leveraging Zephyr's build system and configuration.

---

## Prerequisites

- Zephyr RTOS (recommended: latest main branch)
- Swift toolchain (recommended: Swift 5.8+)
- CMake
- Git

---

## Installation & Setup

### 1. Clone as a Zephyr Module

Clone the `zephyr-lang-swift` repository into your Zephyr modules directory:

```sh
git clone https://github.com/anselmes/zephyr-lang-swift modules/lang/swift
```

In your project's `CMakeLists.txt`, uncomment or add:

```cmake
set(ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_SOURCE_DIR}/modules/lang/swift)
```

### 2. Add via West Manifest

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
      remotes: anselmes
      groups:
        - optional
```

No need to modify `CMakeLists.txt` for this method.

### 3. Use the Zephyr Mirror

Alternatively, use the Zephyr mirror with Swift support:

- [anselmes/zephyr (GitHub)](https://github.com/anselmes/zephyr)

---

## Example Usage

After setup, you can add Swift source files to your Zephyr app or library. See `samples/` and `lib/hello/Hello.swift` for examples.

---

## Troubleshooting & FAQ

- **Build errors?** Ensure your Swift toolchain is installed and available in your PATH.
- **Zephyr not finding Swift module?** Double-check the module path in `CMakeLists.txt` or manifest.
- **Unsupported Zephyr version?** Use the latest main branch for best compatibility.

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines. Issues and PRs are welcome!

---

## Resources

- [Zephyr Documentation](https://docs.zephyrproject.org/)
- [Swift Language](https://swift.org/)
- [Project Issues](https://github.com/anselmes/zephyr-lang-swift/issues)
