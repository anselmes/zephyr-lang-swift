#[=======================================================================[.rst:
Swift Language Support for Zephyr RTOS
=======================================

This module provides comprehensive Swift language support for Zephyr RTOS,
enabling developers to write embedded applications and libraries using
Swift's modern syntax and safety features.

Overview
--------

The Swift language module integrates with Zephyr's build system to:

* Compile Swift source code for embedded targets
* Provide Swift runtime support through zephyr-sys
* Enable Swift libraries and applications in Zephyr projects
* Support cross-compilation for ARM, RISC-V, and other architectures

Components
----------

* **zephyr-sys**: Low-level C runtime stubs and bridging headers
* **zephyr**: Core Swift library with Zephyr RTOS bindings
* **cmake/**: CMake functions for Swift library and application building

Usage
-----

To enable Swift support in your Zephyr project, add to your prj.conf:

.. code-block:: kconfig

   CONFIG_SWIFT=y

Then use the provided CMake functions in your CMakeLists.txt:

.. code-block:: cmake

   swift_application()      # For Swift applications
   swift_library()          # For Swift libraries

Configuration Options
---------------------

* ``CONFIG_SWIFT``:             Enable Swift language support
* ``CONFIG_SWIFT_DEBUG_INFO``:  Enable debug information in Swift compilation

#]=======================================================================]

# Only enable Swift support when explicitly configured in Zephyr
if(CONFIG_SWIFT)

  # Store the Swift module directory path for use by other CMake functions
  # This allows Swift support functions to locate resources and templates
  set(SWIFT_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "Path to Swift module directory")

  # Build the low-level C runtime support library first
  # This provides necessary C stubs and bridging headers for Swift
  add_subdirectory(zephyr-sys)

  # Build the core Zephyr Swift library
  # This provides Swift bindings for Zephyr RTOS functionality
  add_subdirectory(zephyr)

  # Include Swift application and library building functions
  # This makes swift_application() and swift_library() functions available
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/SwiftSupport.cmake)

endif()
