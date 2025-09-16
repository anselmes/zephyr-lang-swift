#[=======================================================================[.rst:
Swift Application Sample - CMake Build Configuration
====================================================

This CMake build file configures a complete Swift application sample for
Zephyr RTOS. It demonstrates the integration between Swift language support
and Zephyr's build system, showing how to configure environment variables,
module dependencies, and Swift compilation for embedded development.

Overview
--------

This sample application serves as a comprehensive example of:

* **Environment Integration**: Proper use of environment variables for cross-compilation
* **Module Dependencies**: Integration with Swift library modules (Hello module)
* **Zephyr Integration**: Standard Zephyr project structure and package discovery
* **Swift Application**: Use of the swift_application() function for Swift compilation

Key Components
--------------

**Environment Configuration**
  Uses environment variables to configure cross-compilation toolchain,
  target board selection, and system root directories.

**Module Integration**
  Demonstrates how to include additional Swift modules (Hello module)
  that can be imported and used by the main application.

**Build Integration**
  Integrates with Zephyr's standard build system while adding Swift
  compilation capabilities through the swift_application() function.

Usage Pattern
-------------

This CMakeLists.txt serves as a template for Swift applications:

1. Set up environment variables for cross-compilation
2. Configure additional Swift modules as needed
3. Find and configure the Zephyr package
4. Define the project with appropriate naming
5. Enable Swift compilation with swift_application()

Environment Variables Required
------------------------------

* ``ZEPHYR_BOARD``: Target board (e.g., qemu_riscv32, nucleo_f746zg)
* ``CROSS_COMPILE``: Path to cross-compiler toolchain
* ``SYSROOT_DIR``: System root directory for cross-compilation
* ``ZEPHYR_TOOLCHAIN_VARIANT``: Toolchain variant identifier
* ``ZEPHYR_BASE``: Path to Zephyr RTOS installation

#]=======================================================================]

# ==============================================================================
# Swift Application Sample - CMake Build Configuration
# ==============================================================================
# This CMake build file configures a complete Swift application sample for
# Zephyr RTOS, demonstrating environment integration, module dependencies, and
# Swift compilation setup for embedded development.
# ==============================================================================

# Specify minimum CMake version required for this project Version 3.29 is
# required for advanced Swift language support and modern CMake features used in
# Zephyr's build system
cmake_minimum_required(VERSION 3.29)

# ==== Environment Variable Configuration ====
# These variables capture environment settings needed for cross-compilation and
# Zephyr board configuration. They must be set in the build environment before
# running CMake (typically through env.example or similar setup).

# Target board configuration for Zephyr RTOS This determines which board support
# package and device tree to use Examples: qemu_riscv32, nucleo_f746zg, esp32,
# nrf52840dk_nrf52840
set(BOARD $ENV{ZEPHYR_BOARD})

# Cross-compiler toolchain prefix path Points to the cross-compilation toolchain
# binaries with prefix Example:
# /opt/zephyr-sdk/arm-zephyr-eabi/bin/arm-zephyr-eabi-
set(CROSS_COMPILE $ENV{CROSS_COMPILE})

# Device Tree overlay file specification (optional) Allows customization of
# board device tree configuration Used when board-specific hardware
# modifications or additions are needed
set(DTC_OVERLAY_FILE $ENV{ZEPHYR_BOARD_OVERLAY})

# System root directory for cross-compilation Contains target system headers,
# libraries, and runtime files Essential for proper cross-compilation linking
# and header resolution
set(SYSROOT_DIR $ENV{SYSROOT_DIR})

# Zephyr toolchain variant identifier Specifies which toolchain variant to use
# for compilation Options: zephyr, gnuarmemb, xtools, cross-compile
set(ZEPHYR_TOOLCHAIN_VARIANT $ENV{ZEPHYR_TOOLCHAIN_VARIANT})

# ==== Additional Module Configuration ====
# Configure additional Zephyr modules that this application depends on This
# allows the application to import and use Swift libraries from other modules

# Add the Hello Swift module as an extra module for this application This makes
# the Hello module available for import in Swift code The path is relative to
# this CMakeLists.txt file location After this configuration, Swift code can
# use: import Hello
set(ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_LIST_DIR}/modules/hello)

# ==== Zephyr Package Discovery and Configuration ====
# Locate and configure the Zephyr RTOS package and build system This step is
# essential for all Zephyr applications and must come before project()

# Find the Zephyr package using the ZEPHYR_BASE environment variable This
# configures the Zephyr build system, toolchain integration, and makes Zephyr's
# CMake functions and targets available REQUIRED ensures the build fails if
# Zephyr cannot be found
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# ==== Project Definition ====
# Define the CMake project with a name and enable Swift application compilation

# Define the project name as "app" (standard Zephyr application name) This
# creates the main application target that Swift code will be linked into
project(app)

# ==== Swift Application Compilation ====
# Enable Swift language compilation for this Zephyr application This function
# handles: - Discovery of Swift source files in src/ directory -
# Cross-compilation setup for the target architecture - Integration with
# Zephyr's build system and linking - Module dependency resolution and include
# path setup - Final binary generation with Swift and C code combined
swift_application()
