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

# .rst: .. cmake:command:: _swift_discover_libraries
#
# Internal function to discover available Swift libraries from the global registry
# and build include paths and dependency lists for compilation.
#
# This function encapsulates the common library discovery logic used by both
# zephyr_swift_application() and zephyr_swift_library() functions.
#
# **Parameters:**
#
# ``EXCLUDE_MODULE <name>``
#   Optional. Module name to exclude from discovery (used by libraries to avoid
#   circular dependencies with themselves).
#
# **Output Variables:**
#
# ``SWIFT_INCLUDE_PATHS``
#   List of "-I" flags for Swift module search paths
#
# ``SWIFT_AVAILABLE_LIBS``
#   List of discovered library names for dependency management
#
function(_swift_discover_libraries)
  # Parse function arguments
  cmake_parse_arguments(PARSE_ARGV 0 SWIFTDISCO "" "EXCLUDE_MODULE" "")

  # Initialize output variables in parent scope
  set(SWIFT_INCLUDE_PATHS "" PARENT_SCOPE)
  set(SWIFT_AVAILABLE_LIBS "" PARENT_SCOPE)

  # Start with the core Zephyr Swift module (always required)
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Build a comprehensive list of extra module directories for Swift library discovery
  # This includes both ZEPHYR_EXTRA_MODULES (user-specified) and EXTRA_ZEPHYR_MODULES
  # (Zephyr's merged list). We normalize all paths to absolute, real paths to ensure
  # consistent matching during library discovery.
  set(_SWIFT_EXTRA_MODULE_DIRS "")
  foreach(_SWIFT_MODULE_ROOT ${ZEPHYR_EXTRA_MODULES} ${EXTRA_ZEPHYR_MODULES})
    if(NOT _SWIFT_MODULE_ROOT)
      continue()
    endif()
    # Convert relative paths to absolute paths based on current source directory
    set(_SWIFT_MODULE_ROOT_ABS "${_SWIFT_MODULE_ROOT}")
    if(NOT IS_ABSOLUTE "${_SWIFT_MODULE_ROOT_ABS}")
      get_filename_component(_SWIFT_MODULE_ROOT_ABS "${_SWIFT_MODULE_ROOT_ABS}" ABSOLUTE
                             BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
    # Resolve any symbolic links to get the canonical path
    get_filename_component(_SWIFT_MODULE_ROOT_ABS "${_SWIFT_MODULE_ROOT_ABS}" REALPATH)
    if(IS_DIRECTORY "${_SWIFT_MODULE_ROOT_ABS}")
      list(APPEND _SWIFT_EXTRA_MODULE_DIRS "${_SWIFT_MODULE_ROOT_ABS}")
    endif()
  endforeach()
  list(REMOVE_DUPLICATES _SWIFT_EXTRA_MODULE_DIRS)

  # Discover available Swift libraries from the global registry
  # The ZEPHYR_SWIFT_LIBRARY_INFO property contains entries in "name|source_dir" format
  # We filter these to include only libraries within our configured extra module directories
  set(POSSIBLE_MODULES "")
  get_property(_SWIFT_LIBRARY_REGISTRY GLOBAL PROPERTY ZEPHYR_SWIFT_LIBRARY_INFO)
  if(_SWIFT_LIBRARY_REGISTRY)
    foreach(_ENTRY ${_SWIFT_LIBRARY_REGISTRY})
      # Parse the registry entry format: "module_name|source_directory"
      string(FIND "${_ENTRY}" "|" _ENTRY_SEPARATOR)
      if(_ENTRY_SEPARATOR LESS 0)
        continue() # Skip malformed entries
      endif()
      string(SUBSTRING "${_ENTRY}" 0 ${_ENTRY_SEPARATOR} _REGISTERED_MODULE_NAME)
      math(EXPR _ENTRY_VALUE_START "${_ENTRY_SEPARATOR} + 1")
      string(SUBSTRING "${_ENTRY}" ${_ENTRY_VALUE_START} -1 _REGISTERED_SOURCE_DIR)

      # Skip the excluded module (used by libraries to avoid circular dependencies)
      if(SWIFTDISCO_EXCLUDE_MODULE AND "${_REGISTERED_MODULE_NAME}" STREQUAL "${SWIFTDISCO_EXCLUDE_MODULE}")
        continue()
      endif()

      # Check if this library's source directory is within our extra module paths
      # This ensures we only link libraries that are part of the current project's modules
      set(_MODULE_IN_EXTRA FALSE)
      foreach(_MODULE_DIR ${_SWIFT_EXTRA_MODULE_DIRS})
        string(FIND "${_REGISTERED_SOURCE_DIR}/" "${_MODULE_DIR}/" _MATCH_POS)
        if(_MATCH_POS EQUAL 0)
          set(_MODULE_IN_EXTRA TRUE)
          break()
        endif()
      endforeach()

      # Skip libraries that aren't in our extra module directories
      if(NOT _MODULE_IN_EXTRA)
        continue()
      endif()

      # Verify that the library's compilation target exists before including it
      if(NOT TARGET ${_REGISTERED_MODULE_NAME}_compile)
        continue()
      endif()

      list(APPEND POSSIBLE_MODULES "${_REGISTERED_MODULE_NAME}")
    endforeach()
    list(REMOVE_DUPLICATES POSSIBLE_MODULES)
  endif()

  # Build include paths and track available libraries
  set(AVAILABLE_LIBS "")
  foreach(MODULE_NAME ${POSSIBLE_MODULES})
    # Add the module's output directory to Swift include paths
    set(MODULE_PATH "${CMAKE_BINARY_DIR}/modules/${MODULE_NAME}")
    list(APPEND INCLUDE_PATHS "-I" "${MODULE_PATH}")
    # Track this library for dependency management
    list(APPEND AVAILABLE_LIBS "${MODULE_NAME}")
  endforeach()

  # Set output variables in parent scope
  set(SWIFT_INCLUDE_PATHS "${INCLUDE_PATHS}" PARENT_SCOPE)
  set(SWIFT_AVAILABLE_LIBS "${AVAILABLE_LIBS}" PARENT_SCOPE)
endfunction()

# Include Swift library building functions Provides: swift_library()
include(${CMAKE_CURRENT_LIST_DIR}/SwiftLibrary.cmake)

# Include Swift application building functions Provides: swift_application()
include(${CMAKE_CURRENT_LIST_DIR}/SwiftApplication.cmake)
