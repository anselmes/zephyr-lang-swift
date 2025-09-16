#[=======================================================================[.rst:
Swift Support Functions
========================

This module provides high-level CMake functions for building Swift
libraries and applications in Zephyr RTOS projects.

Functions Provided
------------------

* ``swift_library()``     - Build Swift static libraries
* ``swift_application()`` - Build Swift applications with Zephyr integration

These functions handle Swift compilation, dependency management, and
integration with the Zephyr build system automatically.

#]=======================================================================]

# Include Swift library building functions Provides: swift_library()
include(${CMAKE_CURRENT_LIST_DIR}/Library.cmake)

# Include Swift application building functions Provides: swift_application()
include(${CMAKE_CURRENT_LIST_DIR}/Application.cmake)
