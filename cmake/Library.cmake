#[=======================================================================[.rst:
Swift Library Building Functions
=================================

This module provides the ``swift_library()`` function for building Swift
static libraries that can be used in Zephyr RTOS projects.

Functions
---------

.. cmake:command:: swift_library

  Builds a Swift static library from Swift source files.

  .. code-block:: cmake

    swift_library([MODULE_NAME <name>] [SOURCES <file1> <file2> ...])

  **Options:**

  ``MODULE_NAME <name>``
    Optional. Name of the Swift module. Defaults to ``${PROJECT_NAME}``.

  ``SOURCES <file1> <file2> ...``
    Optional. List of Swift source files. If not provided, automatically
    discovers all ``.swift`` files in the ``lib/`` directory.

  **Example:**

  .. code-block:: cmake

    # Automatic discovery (uses all .swift files in lib/)
    swift_library()

    # Explicit module name
    swift_library(MODULE_NAME MySwiftLib)

    # Explicit sources
    swift_library(SOURCES src/module.swift src/utils.swift)

  The function creates:

  * A static library target named ``${MODULE_NAME}``
  * A compilation target named ``${MODULE_NAME}_compile``
  * Swift module file for import by other Swift code
  * Proper dependency chain with the Zephyr Swift runtime

#]=======================================================================]

#.rst:
# .. cmake:command:: swift_library
#
#   Compiles Swift source files into a static library for embedded use.
#
#   This function handles all aspects of Swift library compilation including:
#   - Source file discovery and compilation
#   - Module interface generation
#   - Dependency management with other Swift modules
#   - Integration with Zephyr's build system
#
function(swift_library)
  # Enable Swift language support and configure compiler settings
  _enable_swift()

  # Parse function arguments using CMake's argument parsing
  # MODULE_NAME: Optional name for the Swift module (defaults to PROJECT_NAME)
  # SOURCES: Optional list of Swift source files (auto-discovered if not provided)
  cmake_parse_arguments(PARSE_ARGV 0 SWIFTLIB "" "MODULE_NAME" "SOURCES")

  # Determine the module name - use provided name or fall back to project name
  if(NOT SWIFTLIB_MODULE_NAME)
    set(SWIFTLIB_MODULE_NAME ${PROJECT_NAME})
  endif()

  # Discover Swift source files if not explicitly provided
  # Convention: Swift library sources are located in lib/ directory
  if(NOT SWIFTLIB_SOURCES)
    file(GLOB_RECURSE SWIFTLIB_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")
  endif()

  # Validate that we have Swift sources to compile
  if(NOT SWIFTLIB_SOURCES)
    message(WARNING "No Swift sources found for library ${SWIFTLIB_MODULE_NAME}")
    return()
  endif()

  # Set up output file paths for the compiled Swift module
  # Object file: Contains the compiled machine code for the library
  set(MODULE_OBJ_FILE ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.o)
  # Module file: Contains Swift interface information for importing
  set(MODULE_SWIFT_MODULE_FILE ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.swiftmodule)

  # Create the output directory for module artifacts
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME})

  # Determine the Swift target triple based on Zephyr's CPU configuration
  _swift_map_target()

  # Configure Swift compilation defines based on Zephyr configuration
  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    # Enable Swift debug information when configured in Zephyr
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  # Build Swift module search paths for compilation
  # Include the core Zephyr Swift module so libraries can import Zephyr functionality
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Set up compilation dependencies to ensure proper build order
  # Always depend on the source files themselves
  set(COMPILE_DEPS ${SWIFTLIB_SOURCES})

  # Ensure the Zephyr Swift library is compiled before this library
  # This is necessary because Swift libraries may import Zephyr
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

  # Locate the Swift compiler executable
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)

  # Create custom command to compile Swift sources into object file and module
  add_custom_command(
    OUTPUT ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE}
      -target ${SWIFT_TARGET}                                     # Cross-compilation target (e.g., thumbv7em-none-eabi)
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

  # Set the linker language to C to ensure proper linking with Zephyr
  # This is necessary because CMake needs to know how to link the final binary
  set_target_properties(${SWIFTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

  # Create a compilation target to ensure Swift compilation happens in the right order
  # This target represents the completion of Swift compilation for this library
  add_custom_target(${SWIFTLIB_MODULE_NAME}_compile DEPENDS ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE})

  # Make the library target depend on successful compilation
  # This ensures the Swift code is compiled before the library is considered "built"
  add_dependencies(${SWIFTLIB_MODULE_NAME} ${SWIFTLIB_MODULE_NAME}_compile)
endfunction()
