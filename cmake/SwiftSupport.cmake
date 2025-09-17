#[=======================================================================[.rst:
Swift Support Functions for Zephyr RTOS
========================================

This module provides the primary CMake interface for building Swift libraries
and applications in Zephyr RTOS projects. It serves as the main entry point
for Swift language support, combining library and application building
capabilities with intelligent dependency management.

Primary Functions
-----------------

* ``zephyr_swift_library()``     - Build Swift static libraries with global registration
* ``zephyr_swift_application()`` - Build Swift applications with automatic library discovery

**Key Features:**

* **Automatic Discovery:** Both functions automatically discover source files and dependencies
* **Global Registry:** Libraries register themselves for automatic application discovery
* **Zephyr Integration:** Full integration with Zephyr's build system, configuration, and conventions
* **Cross-Compilation:** Transparent support for embedded target architectures
* **Optimization:** Embedded-specific compiler optimizations and binary post-processing

**Usage Pattern:**

For a typical Zephyr project with Swift support:

.. code-block:: cmake

  # In your application's CMakeLists.txt
  find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
  project(my_swift_app)

  # Enable Swift and build application
  zephyr_swift_application()

.. code-block:: cmake

  # In a Swift library's CMakeLists.txt
  zephyr_swift_library(MODULE_NAME MyLib)

**Dependency Management:**

The system automatically handles:

* Swift module discovery from ``ZEPHYR_EXTRA_MODULES``
* Include path resolution for discovered libraries
* Compilation ordering to ensure dependencies are built first
* Linking of Swift libraries into the final application

**Integration Requirements:**

Ensure your ``prj.conf`` includes:

.. code-block:: kconfig

  CONFIG_SWIFT=y

#]=======================================================================]

# Include Swift library building functions Provides: swift_library()
include(${CMAKE_CURRENT_LIST_DIR}/Library.cmake)

# Include Swift application building functions Provides: swift_application()
include(${CMAKE_CURRENT_LIST_DIR}/Application.cmake)
