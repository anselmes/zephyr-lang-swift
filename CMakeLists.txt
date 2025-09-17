#[=======================================================================[.rst:
Swift Language Support for Zephyr RTOS
=======================================

This module provides comprehensive Swift language support for Zephyr RTOS,
enabling developers to write embedded applications and libraries using
Swift's modern syntax, memory safety features, and performance characteristics
optimized for resource-constrained embedded systems.

Architecture Overview
---------------------

The Swift language module consists of three primary components that work
together to provide seamless Swift integration with Zephyr RTOS:

**Core Components:**

* **zephyr-sys**: Low-level C runtime stubs, system call bridges, and C header interfaces
* **zephyr**: High-level Swift library providing Zephyr RTOS APIs and embedded abstractions
* **cmake/**: CMake build system integration with intelligent dependency management

**Build System Features:**

* **Automatic Discovery**: Intelligent source file and library discovery across project modules
* **Global Registration**: Libraries automatically register for application dependency resolution
* **Cross-Compilation**: Transparent support for ARM Cortex-M, ARM64, RISC-V, and other architectures
* **Embedded Optimization**: Specialized compiler flags for minimal code size and optimal performance

Primary Functions
-----------------

The module provides high-level CMake functions for Swift development:

.. code-block:: cmake

   zephyr_swift_application()   # Build Swift applications with automatic library linking
   zephyr_swift_library()       # Build Swift libraries with global registration

**Advanced Library Discovery:**

The system automatically discovers and links Swift libraries from:

* Project-local modules in your source tree
* External modules specified in ``ZEPHYR_EXTRA_MODULES``
* Registered libraries in the global ``ZEPHYR_SWIFT_LIBRARY_INFO`` registry

Getting Started
---------------

**1. Enable Swift Support:**

Add to your ``prj.conf``:

.. code-block:: kconfig

   CONFIG_SWIFT=y
   CONFIG_SWIFT_DEBUG_INFO=y  # Optional: enable debug information

**2. Build Swift Applications:**

In your application's ``CMakeLists.txt``:

.. code-block:: cmake

   find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
   project(my_swift_app)

   # Automatically discovers src/*.swift and links available libraries
   zephyr_swift_application()

**3. Build Swift Libraries:**

In your library's ``CMakeLists.txt``:

.. code-block:: cmake

   # Registers library globally for application discovery
   zephyr_swift_library(MODULE_NAME MySwiftLib)

Configuration Options
---------------------

* ``CONFIG_SWIFT``:             Enable Swift language support and build system integration
* ``CONFIG_SWIFT_DEBUG_INFO``:  Include debug information in Swift compilation for development

Supported Targets
-----------------

* **ARM Cortex-M**: M0/M0+/M1/M3/M4/M7/M23/M33/M35P/M55 with optional FPU support
* **ARM64**: AArch64 processors
* **RISC-V**: Both 32-bit and 64-bit RISC-V implementations

#]=======================================================================]

# Only enable Swift support when explicitly configured in Zephyr
if(CONFIG_SWIFT)

  # Store the Swift module directory path for global access by other CMake functions
  # This enables Swift support functions to locate templates, resources, and the
  # Application.swift bootstrap code used by zephyr_swift_application()
  set(SWIFT_MODULE_DIR
      "${CMAKE_CURRENT_LIST_DIR}"
      CACHE INTERNAL "Path to Swift module directory for resource location")

  # Build the foundational C runtime support library (zephyr-sys)
  # This provides essential C stubs, system call bridges, and header interfaces
  # required for Swift code to interact with Zephyr's C-based kernel APIs
  add_subdirectory(zephyr-sys)

  # Build the core Zephyr Swift library (zephyr module)
  # This provides high-level Swift APIs and abstractions for Zephyr RTOS
  # functionality, built on top of the zephyr-sys foundation
  add_subdirectory(zephyr)

  # Include Swift application and library building functions
  # This makes zephyr_swift_application() and zephyr_swift_library() functions
  # available to projects that include this module
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/SwiftSupport.cmake)

endif()
