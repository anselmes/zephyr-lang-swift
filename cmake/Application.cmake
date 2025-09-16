#[=======================================================================[.rst:
Swift Application Building Functions
=====================================

This module provides the ``swift_application()`` function for building Swift
applications that run on Zephyr RTOS.

Functions
---------

.. cmake:command:: swift_application

  Builds a Swift application for Zephyr RTOS.

  .. code-block:: cmake

    swift_application()

  This function:

  * Discovers Swift source files in the ``src/`` directory
  * Compiles them with the Zephyr Swift runtime
  * Links against available Swift libraries automatically
  * Integrates with the Zephyr ``app`` target
  * Handles cross-compilation for embedded targets

  **Source File Discovery:**

  The function automatically finds all ``.swift`` files in the ``src/``
  directory of your project. No manual file listing is required.

  **Library Discovery:**

  The function automatically discovers and links against Swift libraries
  that have been built in the current project, including:

  * Core Zephyr Swift library (always included)
  * Project-specific Swift libraries (if present)
  * Common utility libraries (Hello, Utils, Common)

  **Integration:**

  The compiled Swift code is automatically integrated with the Zephyr
  ``app`` target, so no additional CMake configuration is needed.

  **Example Project Structure:**

  .. code-block:: text

    my_project/
    ├── CMakeLists.txt          # Contains swift_application()
    ├── prj.conf                # Contains CONFIG_SWIFT=y
    └── src/
        ├── entrypoint.swift    # Your Swift application code
        └── utils.swift         # Additional Swift files (optional)

#]=======================================================================]

# .rst: .. cmake:command:: swift_application
#
# Compiles Swift application sources and integrates them with Zephyr's app
# target.
#
# This function handles the complete build process for Swift applications: -
# Source file discovery in src/ directory - Swift library dependency resolution
# - Cross-compilation for embedded targets - Integration with Zephyr's build
# system - Final binary post-processing
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
  set(APP_SWIFT_MODULE_FILE
      "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.swiftmodule")

  # Build Swift module search paths for compilation Start with the core Zephyr
  # Swift module (always required)
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I"
       "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Discover available Swift libraries to link against TODO: Make this discovery
  # dynamic by scanning for *_compile targets
  set(AVAILABLE_LIBS "")
  set(POSSIBLE_MODULES "Hello" "Utils" "Common") # Common Swift library names

  # Check for each possible Swift library and add to includes/linking if found
  foreach(MODULE_NAME ${POSSIBLE_MODULES})
    if(TARGET ${MODULE_NAME}_compile)
      # Add the module's output directory to Swift include paths
      set(MODULE_PATH
          "${CMAKE_BINARY_DIR}/modules/${MODULE_NAME}/${MODULE_NAME}")
      list(APPEND INCLUDE_PATHS "-I" "${MODULE_PATH}")
      # Track this library for linking later
      list(APPEND AVAILABLE_LIBS "${MODULE_NAME}")
    endif()
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
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} # Cross-compilation target
                                                   # (e.g., thumbv7em-none-eabi)
      -wmo # Whole-module optimization for better performance
      -Osize # Optimize for code size (critical for embedded)
      -enable-experimental-feature Embedded # Enable Embedded Swift features
      -Xfrontend -function-sections # Separate functions into sections for
                                    # linker optimization
      -emit-object -o ${APP_SWIFT_OBJ_FILE} # Generate object file for linking
      ${SWIFT_DEFINES} # Add any Swift compilation defines
      ${INCLUDE_PATHS} # Add module search paths
      ${SWIFT_APPLICATION} # Include Zephyr application bootstrap
      ${SWIFT_SOURCES} # Include user application sources
    DEPENDS ${COMPILE_DEPS}
    COMMENT
      "Compiling Swift application ${PROJECT_NAME} with libraries: ${AVAILABLE_LIBS}"
  )

  # Create a compilation target to track Swift application build completion
  add_custom_target(${PROJECT_NAME}_compile DEPENDS ${APP_SWIFT_OBJ_FILE}
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
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash $<TARGET_FILE:app>
            $<TARGET_FILE:app>
    COMMENT "Removing .swift_modhash section from final binary")
endfunction()
