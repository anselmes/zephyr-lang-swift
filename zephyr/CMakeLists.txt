#[=======================================================================[.rst:
Zephyr Swift Core Library
==========================

This CMakeLists.txt builds the core Zephyr Swift library that provides
Swift bindings and utilities for Zephyr RTOS functionality.

Components
----------

**Swift Sources** (``lib/``)
  Core Swift code that provides:

  * Zephyr RTOS API bindings
  * Swift-friendly wrappers for C functions
  * Memory management utilities
  * Time and threading abstractions
  * Hardware abstraction layer bindings

**Generated Artifacts**
  * ``Zephyr.o`` - Compiled object file containing Swift code
  * ``Zephyr.swiftmodule`` - Swift module interface for importing

**Integration**
  * Links with ZephyrSys for C runtime support
  * Imports Zephyr headers through bridging header
  * Provides Swift module for user applications and libraries

Build Process
-------------

The build process compiles Swift sources using embedded Swift features:

1. Discovers Swift source files in lib/ directory
2. Configures cross-compilation for the target architecture
3. Compiles with whole-module optimization for size
4. Generates both object file and Swift module interface
5. Creates static library target for linking

If no Swift sources are found, creates an interface library that still
provides access to ZephyrSys for C interoperability.

#]=======================================================================]

# Include Swift toolchain configuration functions This provides
# _swift_map_target() and _enable_swift() functions
include(${CMAKE_CURRENT_SOURCE_DIR}/../toolchain.cmake)

# Discover all Swift source files in the lib/ directory These contain the core
# Zephyr Swift library implementation
file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")

# Only build Swift library if we have Swift sources to compile
if(SWIFT_SOURCES)
  message(STATUS "Swift sources: ${SWIFT_SOURCES}")

  # Path to the zephyr-sys module for bridging headers and includes
  set(ZEPHYR_SYS_MODULE "${CMAKE_CURRENT_SOURCE_DIR}/../zephyr-sys")

  # Define output file paths for the compiled Zephyr Swift library Object file:
  # Contains compiled Swift code for the Zephyr library
  set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.o")
  # Module file: Contains Swift interface information for importing by other
  # Swift code
  set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.swiftmodule")

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

  # Create custom command to compile the core Zephyr Swift library
  add_custom_command(
    OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} # Cross-compilation target
                                                   # (e.g., thumbv7em-none-eabi)
      -parse-as-library # Compile as library (not executable)
      -wmo # Whole-module optimization for better embedded performance
      -Osize # Optimize for code size (critical for embedded)
      -enable-experimental-feature Embedded # Enable Embedded Swift features
      -Xfrontend -function-sections # Separate functions into sections for
                                    # linker optimization
      -emit-object -o ${SWIFT_OBJ_FILE} # Generate object file
      -emit-module -emit-module-path ${SWIFT_MODULE_FILE} # Generate Swift
                                                          # module interface
      -module-name Zephyr # Set the Swift module name to "Zephyr"
      ${SWIFT_DEFINES} # Add any Swift compilation defines
      # Include paths for Zephyr headers (order matters for proper resolution)
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated # Generated Zephyr headers
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr # Generated
                                                             # Zephyr-specific
                                                             # headers
      -I ${CMAKE_BINARY_DIR}/zephyr/include # Built Zephyr headers
      -I ${ZEPHYR_BASE}/include # Source Zephyr headers
      -I ${ZEPHYR_SYS_MODULE}/include # ZephyrSys bridging headers
      -I ${SYSROOT_DIR}/include # System headers
      -Xcc -isysroot=${SYSROOT_DIR} # Set system root for C headers
      # Import the bridging header to make C APIs available to Swift
      -import-bridging-header ${ZEPHYR_SYS_MODULE}/include/BridgingHeader.h
      ${SWIFT_SOURCES} # Swift source files to compile
    DEPENDS ${SWIFT_SOURCES}
    COMMENT "Compiling Swift sources for Zephyr")

  # Create a static library target containing the compiled Swift code
  add_library(Zephyr STATIC ${SWIFT_OBJ_FILE})

  # Set the linker language to C to ensure proper linking with Zephyr This is
  # necessary because CMake needs to know how to link the final binary
  set_target_properties(Zephyr PROPERTIES LINKER_LANGUAGE C)

  # Create a compilation target to track when Swift compilation is complete This
  # target is used by other Swift code to ensure proper build order
  add_custom_target(Zephyr_compile DEPENDS ${SWIFT_OBJ_FILE}
                                           ${SWIFT_MODULE_FILE})

  # Ensure Swift compilation happens after Zephyr's syscall headers are
  # generated This dependency is critical because Swift code may use Zephyr
  # system calls
  add_dependencies(Zephyr_compile syscall_list_h_target)

  # Make the Zephyr library target depend on successful Swift compilation
  add_dependencies(Zephyr Zephyr_compile)

  # Link with ZephyrSys to provide C runtime support for Swift code PUBLIC
  # linking means users of Zephyr library also get ZephyrSys functionality
  target_link_libraries(Zephyr PUBLIC ZephyrSys)

else()
  # Fallback: Create an interface library when no Swift sources are found This
  # still provides access to ZephyrSys for C interoperability even without Swift
  # code
  add_library(Zephyr INTERFACE)

  # Link with ZephyrSys through the interface to maintain C runtime support
  target_link_libraries(Zephyr INTERFACE ZephyrSys)
endif()
