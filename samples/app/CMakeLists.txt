# ==============================================================================
# PROJECT CMAKE CONFIGURATION
# ==============================================================================
# This CMake build file configures a Zephyr RTOS embedded project with Swift
# language support. It handles the integration between Swift compiler settings
# and Zephyr's build system for embedded development.
# ==============================================================================

cmake_minimum_required(VERSION 3.29)

set(BOARD $ENV{ZEPHYR_BOARD})                                 # Target board for the application
set(BUILD_TARGET $ENV{ZEPHYR_BUILD_TARGET})                   # Target triple (e.g., arm-none-eabi)
set(CROSS_COMPILE $ENV{CROSS_COMPILE})                        # Cross-compiler prefix
set(DTC_OVERLAY_FILE $ENV{ZEPHYR_BOARD_OVERLAY})              # Device Tree overlay file
set(SYSROOT_DIR $ENV{SYSROOT_DIR})                            # Sysroot directory for cross-compilation
set(ZEPHYR_TOOLCHAIN_VARIANT $ENV{ZEPHYR_TOOLCHAIN_VARIANT})  # Toolchain variant name

set(ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_LIST_DIR}/modules/hello)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(app)
swift_application()
