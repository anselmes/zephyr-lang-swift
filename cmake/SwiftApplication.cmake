#[=======================================================================[.rst:
Swift Application Building Functions
=====================================

This module provides the ``zephyr_swift_application()`` function for building Swift
applications that integrate seamlessly with Zephyr RTOS.

Functions
---------

.. cmake:command:: zephyr_swift_application

  Builds a Swift application with automatic library discovery and Zephyr integration.

  .. code-block:: cmake

    zephyr_swift_application()

  **Key Features:**

  * **Automatic Source Discovery:** Finds all ``.swift`` files in the ``src/`` directory
  * **Intelligent Library Discovery:** Automatically discovers and links Swift libraries from extra modules
  * **Cross-Compilation Support:** Handles embedded target compilation with proper optimization
  * **Zephyr Integration:** Seamlessly integrates with Zephyr's ``app`` target and build system
  * **Module Path Resolution:** Resolves Swift module dependencies from ``ZEPHYR_EXTRA_MODULES``

  **Source File Discovery:**

  The function automatically discovers all ``.swift`` files in your project's ``src/``
  directory, following Zephyr's standard application structure convention.

  **Advanced Library Discovery:**

  The function performs sophisticated library discovery by:

  * Scanning ``ZEPHYR_EXTRA_MODULES`` and ``EXTRA_ZEPHYR_MODULES`` for Swift libraries
  * Reading the global ``ZEPHYR_SWIFT_LIBRARY_INFO`` registry for available modules
  * Automatically configuring include paths for discovered Swift modules
  * Establishing proper compilation dependencies between libraries and applications

  **Cross-Compilation & Optimization:**

  * Automatically determines Swift target triple based on Zephyr's CPU configuration
  * Applies embedded-specific optimizations (``-Osize``, ``-wmo``)
  * Enables Embedded Swift features and function sectioning for optimal binary size
  * Integrates with Zephyr's build system for seamless compilation

  **Example Project Structure:**

  .. code-block:: text

    my_project/
    ├── CMakeLists.txt          # Contains zephyr_swift_application()
    ├── prj.conf                # Contains CONFIG_SWIFT=y
    ├── src/
    │   ├── Entrypoint.swift    # Application entry point (defines entrypoint())
    │   └── Utils.swift         # Additional Swift modules (optional)
    └── modules/
        └── my_swift_lib/       # Custom Swift library (auto-discovered)
            ├── CMakeLists.txt  # Contains zephyr_swift_library()
            └── *.swift         # Swift library sources

  **Configuration Requirements:**

  Ensure your ``prj.conf`` includes:

  .. code-block:: kconfig

    CONFIG_SWIFT=y
    CONFIG_SWIFT_DEBUG_INFO=y  # Optional: enable debug information

#]=======================================================================]

# .rst: .. cmake:command:: zephyr_swift_application
#
# Compiles Swift application sources with intelligent library discovery and
# seamless Zephyr integration.
#
# This function provides a comprehensive build pipeline for Swift applications:
#
# **Core Functionality:**
# - Automatic Swift source file discovery in the ``src/`` directory
# - Advanced Swift library dependency resolution via module registry
# - Intelligent module path resolution from ``ZEPHYR_EXTRA_MODULES``
# - Cross-compilation targeting with embedded-specific optimizations
# - Complete integration with Zephyr's build system and ``app`` target
# - Post-build binary optimization (removal of unnecessary Swift metadata)
#
# **Library Discovery Process:**
# The function performs sophisticated dependency resolution by scanning the
# global ``ZEPHYR_SWIFT_LIBRARY_INFO`` registry, filtering for libraries
# within the configured extra module directories, and automatically setting
# up include paths and link dependencies.
#
function(zephyr_swift_application)
  # Enable Swift language support and configure compiler settings
  _enable_swift()

  # Discover all Swift source files in the src/ directory This follows Zephyr's
  # convention where application sources go in src/
  file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift")

  # Include the core Zephyr Swift application bootstrap code This provides the
  # main() function and entrypoint() delegation
  set(SWIFT_APPLICATION "${SWIFT_MODULE_DIR}/zephyr/src/Application.swift")

  # Define output file paths for the compiled Swift application Object file:
  # Contains the compiled machine code for the application
  set(APP_SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.o")
  # Module file: Contains Swift interface information (for debugging/tooling)
  set(APP_SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.swiftmodule")

  # Build Swift module search paths for compilation Start with the core Zephyr
  # Swift module (always required)
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Discover available Swift libraries registered during configuration
  set(AVAILABLE_LIBS "")

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

  foreach(MODULE_NAME ${POSSIBLE_MODULES})
    # Add the module's output directory to Swift include paths
    set(MODULE_PATH "${CMAKE_BINARY_DIR}/modules/${MODULE_NAME}")
    list(APPEND INCLUDE_PATHS "-I" "${MODULE_PATH}")
    # Track this library for linking later
    list(APPEND AVAILABLE_LIBS "${MODULE_NAME}")
  endforeach()

  # Build the dependency chain to ensure proper compilation order Start with the
  # application's Swift source files
  set(COMPILE_DEPS ${SWIFT_SOURCES})

  # Ensure the core Zephyr Swift library is compiled first This is essential
  # since applications typically import Zephyr functionality
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

  # Add dependencies on all discovered Swift libraries This ensures they are
  # compiled before the application
  foreach(LIB ${AVAILABLE_LIBS})
    if(TARGET ${LIB}_compile)
      list(APPEND COMPILE_DEPS ${LIB}_compile)
    endif()
  endforeach()

  # Determine the Swift target triple based on Zephyr's CPU configuration
  _swift_map_target()

  # Configure Swift compilation defines based on Zephyr configuration
  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    # Enable Swift debug information when configured in Zephyr
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  # Locate the Swift compiler executable
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)

  # Create custom command to compile Swift application with all dependencies
  add_custom_command(
    OUTPUT ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET}  # Cross-compilation target (e.g., thumbv7em-none-eabi)
      -wmo                                          # Whole-module optimization for better performance
      -Osize                                        # Optimize for code size (critical for embedded)
      -enable-experimental-feature Embedded         # Enable Embedded Swift features
      -Xfrontend -function-sections                 # Separate functions into sections for linker optimization
      -emit-object -o ${APP_SWIFT_OBJ_FILE}         # Generate object file for linking

      ${SWIFT_DEFINES}                              # Add any Swift compilation defines
      ${INCLUDE_PATHS}                              # Add module search paths
      ${SWIFT_APPLICATION}                          # Include Zephyr application bootstrap
      ${SWIFT_SOURCES}                              # Include user application sources
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift application ${PROJECT_NAME} with libraries: ${AVAILABLE_LIBS}")

  # Create a compilation target to track Swift application build completion
  add_custom_target(${PROJECT_NAME}_compile
                    DEPENDS
                    ${APP_SWIFT_OBJ_FILE}
                    ${APP_SWIFT_MODULE_FILE})

  # Integrate the compiled Swift object file with Zephyr's app target This adds
  # the Swift code to the final executable
  target_sources(app PRIVATE ${APP_SWIFT_OBJ_FILE})
  add_dependencies(app ${PROJECT_NAME}_compile)

  # Link the core Zephyr Swift library (provides runtime support)
  target_link_libraries(app PRIVATE Zephyr)

  # Link all discovered Swift libraries This ensures Swift libraries are
  # available at runtime
  foreach(LIB ${AVAILABLE_LIBS})
    if(TARGET ${LIB})
      target_link_libraries(app PRIVATE ${LIB})
    endif()
  endforeach()

  # Set the linker language to C to ensure proper integration with Zephyr This
  # is necessary because the final executable links C and Swift code together
  set_target_properties(app PROPERTIES LINKER_LANGUAGE C)

  # Post-build step: Clean up Swift-specific sections from the final binary The
  # .swift_modhash section is used during compilation but not needed in the
  # final embedded binary Removing it reduces binary size and eliminates
  # unnecessary embedded metadata
  add_custom_command(
    TARGET app
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash $<TARGET_FILE:app> $<TARGET_FILE:app>
    COMMENT "Removing .swift_modhash section from final binary")
endfunction()
