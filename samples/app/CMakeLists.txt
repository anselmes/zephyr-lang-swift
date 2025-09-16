# ==============================================================================
# PROJECT CMAKE CONFIGURATION
# ==============================================================================
# This CMake build file configures a Zephyr RTOS embedded project with Swift
# language support. It handles the integration between Swift compiler settings
# and Zephyr's build system for embedded development.
# ==============================================================================

cmake_minimum_required(VERSION 3.29)

# ==== Environment ====

set(BOARD $ENV{ZEPHYR_BOARD})                                 # Target board for the application
set(BUILD_TARGET $ENV{ZEPHYR_BUILD_TARGET})                   # Target triple (e.g., arm-none-eabi)
set(CROSS_COMPILE $ENV{CROSS_COMPILE})                        # Cross-compiler prefix
set(DTC_OVERLAY_FILE $ENV{ZEPHYR_BOARD_OVERLAY})              # Device Tree overlay file
set(SYSROOT_DIR $ENV{SYSROOT_DIR})                            # Sysroot directory for cross-compilation
set(ZEPHYR_TOOLCHAIN_VARIANT $ENV{ZEPHYR_TOOLCHAIN_VARIANT})  # Toolchain variant name

# ==== Zephyr ====

# Add custom Zephyr modules (e.g., for Swift support)
# Uncomment and set the path to your custom Zephyr modules if needed
set(ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_LIST_DIR}/modules/hello)

# Find and include Zephyr RTOS package
# This initializes Zephyr's build system and makes its build targets available
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# ==== Configuration ====

# Define the project with Swift language support
project(app)
swift_application()
