#[=======================================================================[.rst:
Swift Library Building Functions
=================================

This module provides the ``zephyr_swift_library()`` function for building Swift
static libraries that integrate seamlessly with Zephyr RTOS projects and the
Swift application build system.

Functions
---------

.. cmake:command:: zephyr_swift_library

  Builds a Swift static library with automatic registration and Zephyr integration.

  .. code-block:: cmake

    zephyr_swift_library([MODULE_NAME <name>] [SOURCES <file1> <file2> ...])

  **Parameters:**

  ``MODULE_NAME <name>``
    Optional. Name of the Swift module. Defaults to ``${PROJECT_NAME}``.
    This name is used for the module interface and library target.

  ``SOURCES <file1> <file2> ...``
    Optional. List of Swift source files to compile. If not provided,
    automatically discovers all ``.swift`` files in the current directory
    and subdirectories.

  **Key Features:**

  * **Automatic Source Discovery:** Recursively finds all ``.swift`` files in the library directory
  * **Global Registration:** Automatically registers the library in ``ZEPHYR_SWIFT_LIBRARY_INFO`` for application discovery
  * **Zephyr Integration:** Supports Zephyr system call includes and directory structures
  * **Optimized Compilation:** Uses embedded-specific optimizations and whole-module optimization
  * **Module Interface Generation:** Creates ``.swiftmodule`` files for import by other Swift code

  **Examples:**

  .. code-block:: cmake

    # Automatic discovery (uses all .swift files in current directory tree)
    zephyr_swift_library()

    # Explicit module name
    zephyr_swift_library(MODULE_NAME MySwiftLib)

    # Explicit sources with custom module name
    zephyr_swift_library(
      MODULE_NAME CustomLib
      SOURCES lib/Core.swift lib/Utils.swift
    )

  **Generated Artifacts:**

  The function creates:

  * A static library target named ``${MODULE_NAME}``
  * A compilation target named ``${MODULE_NAME}_compile``
  * Swift module interface file (``${MODULE_NAME}.swiftmodule``)
  * Compiled object file (``${MODULE_NAME}.o``)
  * Global registry entry for automatic application discovery

  **Directory Structure Integration:**

  The library supports Zephyr's standard directory conventions:

  .. code-block:: text

    my_swift_library/
    ├── CMakeLists.txt          # Contains zephyr_swift_library()
    ├── Kconfig                 # Library configuration options
    ├── include/                # C headers (automatically included)
    └── *.swift                 # Swift source files (auto-discovered)

  **Output Path Structure:**

  Compiled artifacts are placed in a clean directory structure:

  .. code-block:: text

    ${CMAKE_BINARY_DIR}/modules/${MODULE_NAME}/
    ├── ${MODULE_NAME}.o           # Compiled object file
    └── ${MODULE_NAME}.swiftmodule # Module interface

#]=======================================================================]

# .rst: .. cmake:command:: zephyr_swift_library
#
# Compiles Swift source files into a static library with global registration
# and comprehensive Zephyr integration.
#
# This function provides a complete library build pipeline including:
#
# **Core Compilation:**
# - Recursive Swift source file discovery throughout the library directory
# - Embedded-optimized Swift compilation with whole-module optimization
# - Generation of both object files and Swift module interfaces
# - Proper dependency management with the Zephyr Swift runtime
#
# **Zephyr Integration:**
# - Automatic integration with Zephyr's include directory conventions
# - Support for system call header includes when ``include/`` directory exists
# - Seamless linking with Zephyr's build system and other Swift components
#
# **Global Registration:**
# - Automatic registration in ``ZEPHYR_SWIFT_LIBRARY_INFO`` global property
# - Enables automatic discovery by Swift applications during build process
# - Maintains source directory associations for module path resolution
#
function(zephyr_swift_library)
  # Enable Swift language support and configure compiler settings
  _enable_swift()

  # This is needed so that custom driver classes using system calls are taken into
  # account
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
    zephyr_syscall_include_directories(include)
    zephyr_include_directories(include)
  endif()

  # Parse function arguments using CMake's argument parsing
  # MODULE_NAME: Optional name for the Swift module (defaults to PROJECT_NAME)
  # SOURCES: Optional list of Swift source files (auto-discovered if not provided)
  cmake_parse_arguments(PARSE_ARGV 0 SWIFTLIB "" "MODULE_NAME" "SOURCES")

  # Determine the module name - use provided name or fall back to project name
  if(NOT SWIFTLIB_MODULE_NAME)
    set(SWIFTLIB_MODULE_NAME ${PROJECT_NAME})
  endif()

  # Discover Swift source files if not explicitly provided
  # Convention: Swift library sources are discovered recursively from the current
  # source directory, allowing flexible organization within the library directory
  if(NOT SWIFTLIB_SOURCES)
    file(GLOB_RECURSE SWIFTLIB_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/*.swift")
  endif()

  # Validate that we have Swift sources to compile
  if(NOT SWIFTLIB_SOURCES)
    message(WARNING "No Swift sources found for library ${SWIFTLIB_MODULE_NAME}")
    return()
  endif()

  # Configure structured output paths for compiled Swift module artifacts
  # Using a clean directory structure: modules/{module_name}/
  # This organization enables clean separation of different module artifacts and
  # provides predictable paths for Swift applications to discover compiled modules

  # Object file: Contains the compiled machine code for the library
  set(MODULE_OBJ_FILE
    ${CMAKE_BINARY_DIR}/modules/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.o
  )
  # Module interface file: Contains Swift type information for importing by other modules
  set(MODULE_SWIFT_MODULE_FILE
      ${CMAKE_BINARY_DIR}/modules/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.swiftmodule)

  # Create the output directory for module artifacts
  file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/modules/${SWIFTLIB_MODULE_NAME})

  # Determine the Swift target triple based on Zephyr's CPU configuration
  _swift_map_target()

  # Configure Swift compilation defines based on Zephyr configuration
  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    # Enable Swift debug information when configured in Zephyr
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  # Build Swift module search paths for compilation Include the core Zephyr
  # Swift module so libraries can import Zephyr functionality
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Set up compilation dependencies to ensure proper build order Always depend
  # on the source files themselves
  set(COMPILE_DEPS ${SWIFTLIB_SOURCES})

  # Ensure the Zephyr Swift library is compiled before this library This is
  # necessary because Swift libraries may import Zephyr
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

  # Locate the Swift compiler executable
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)

  # Create custom command to compile Swift sources into object file and module
  add_custom_command(
    OUTPUT ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET}                # Cross-compilation target (e.g., thumbv7em-none-eabi)
      -parse-as-library                                           # Compile as library (not executable)
      -wmo                                                        # Whole-module optimization for better embedded performance
      -Osize                                                      # Optimize for code size (critical for embedded)
      -enable-experimental-feature Embedded                       # Enable Embedded Swift features
      -Xfrontend -function-sections                               # Separate functions into sections for linker optimization

      -emit-object -o ${MODULE_OBJ_FILE}                          # Generate object file
      -emit-module -emit-module-path ${MODULE_SWIFT_MODULE_FILE}  # Generate module interface
      -module-name ${SWIFTLIB_MODULE_NAME}                        # Set the Swift module name

      ${SWIFT_DEFINES}                                            # Add any Swift compilation defines
      ${INCLUDE_PATHS}                                            # Add module search paths
      ${SWIFTLIB_SOURCES}                                         # Source files to compile
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift library ${SWIFTLIB_MODULE_NAME}")

  # Create a static library target containing the Swift object file
  add_library(${SWIFTLIB_MODULE_NAME} STATIC ${MODULE_OBJ_FILE})

  # Set the linker language to C to ensure proper linking with Zephyr This is
  # necessary because CMake needs to know how to link the final binary
  set_target_properties(${SWIFTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

  # Create a compilation target to ensure Swift compilation happens in the right
  # order This target represents the completion of Swift compilation for this
  # library
  add_custom_target(${SWIFTLIB_MODULE_NAME}_compile
                    DEPENDS ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE})

  # Make the library target depend on successful compilation This ensures the
  # Swift code is compiled before the library is considered "built"
  add_dependencies(${SWIFTLIB_MODULE_NAME} ${SWIFTLIB_MODULE_NAME}_compile)

  # Register this Swift library so applications can discover it later
  get_filename_component(_SWIFT_LIBRARY_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
  set_property(GLOBAL APPEND PROPERTY ZEPHYR_SWIFT_LIBRARY_INFO "${SWIFTLIB_MODULE_NAME}|${_SWIFT_LIBRARY_SOURCE_DIR}")
endfunction()
