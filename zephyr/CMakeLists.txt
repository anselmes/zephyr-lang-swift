#[=======================================================================[.rst:
Zephyr Swift Library - High-Level Swift APIs for Zephyr RTOS
=============================================================

This CMake file builds the main Zephyr Swift library, which provides
high-level Swift APIs and applications for Zephyr RTOS. It builds upon
the ZephyrSys library to offer Swift-native interfaces to Zephyr functionality.

## Library Structure

**lib/** - Core Zephyr Swift library implementation
  High-level Swift APIs that wrap and enhance Zephyr C APIs with
  Swift-native interfaces, type safety, and modern language features.

**src/** - Application entry points and utilities
  Swift application scaffolding and entry point implementations
  using @c attributes for C compatibility.

## Swift 6.3 Features

**@c Attributes**
  Swift functions marked with @c can be called from C code,
  enabling Swift applications to serve as Zephyr main() functions.

**Embedded Swift Mode**
  Optimized compilation for resource-constrained embedded systems:
  - Whole-module optimization for better performance
  - Size optimization for minimal memory footprint
  - Function sections for optimal linking

**Module System**
  Swift modules provide clean interfaces and encapsulation:
  - Zephyr module for high-level APIs
  - ZephyrSys dependency for runtime support
  - Clear separation between Swift and C interfaces

## Build Options

**With Swift Sources**
  When Swift library sources are found, builds a comprehensive
  Swift library with full API support and applications.

**Interface-Only Mode**
  When no Swift sources are present, creates an interface library
  that still provides access to ZephyrSys for C interoperability.

## Integration

This library integrates with:
- ZephyrSys for runtime support and C interoperability
- Zephyr kernel for system calls and hardware access
- Application code for high-level Swift development

#]=======================================================================]

# Include Swift toolchain configuration functions
# This provides _swift_map_target() and _enable_swift() functions for
# configuring cross-compilation and Swift-specific build settings
include(${CMAKE_CURRENT_SOURCE_DIR}/../toolchain.cmake)

# Discover all Swift source files in the lib/ directory
# lib/: Core Zephyr Swift library implementation providing high-level APIs
# These files contain Swift wrappers and enhancements for Zephyr C APIs
file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")

# Only build Swift library if we have Swift sources to compile
# This allows the build to succeed even without Swift library implementation
if(SWIFT_SOURCES)
  message(STATUS "Zephyr Swift Library: Found Swift sources, building full library")
  message(STATUS "Zephyr Swift Library: Swift sources: ${SWIFT_SOURCES}")

  # Path to the zephyr-sys module for bridging headers and runtime support
  # This module provides C interoperability and runtime functions needed by Swift
  set(ZEPHYR_SYS_MODULE "${CMAKE_CURRENT_SOURCE_DIR}/../zephyr-sys")

  # Define output file paths for the compiled Zephyr Swift library
  # Object file: Contains compiled Swift code for the high-level Zephyr library
  set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.o")
  # Module file: Contains Swift interface information for importing by other Swift code
  set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.swiftmodule")

  message(STATUS "Zephyr Swift Library: Output object: ${SWIFT_OBJ_FILE}")
  message(STATUS "Zephyr Swift Library: Output module: ${SWIFT_MODULE_FILE}")

  # Determine the Swift target triple based on Zephyr's CPU configuration
  # This maps Zephyr's architecture settings to appropriate Swift targets
  _swift_map_target()

  # Configure Swift compilation defines based on Zephyr configuration
  # These defines enable conditional compilation for debug and feature flags
  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    # Enable Swift debug information when configured in Zephyr
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
    message(STATUS "Zephyr Swift Library: Debug information enabled")
  endif()

  # Additional feature flags can be added here based on Zephyr configuration
  # Example:
  # if(CONFIG_SWIFT_ASYNC_SUPPORT)
  #   list(APPEND SWIFT_DEFINES "-DSWIFT_ASYNC_SUPPORT")
  # endif()

  # Locate the Swift compiler executable.
  # swiftly's PATH shim respects the TOOLCHAINS env var on all platforms —
  # set TOOLCHAINS="swift" to select the swift.org toolchain.
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  message(STATUS "Zephyr Swift Library: Using Swift compiler: ${SWIFTC_EXECUTABLE}")

  # Compute system header flags for Swift cross-compilation.
  # Priority: 1) SYSROOT_DIR env var (cross-compile variant)
  #           2) SDK clang-runtimes headers (zephyr/llvm variant — includes picolibc.h)
  #           3) empty (no system headers — likely to fail at compile time)
  set(SWIFT_SYSROOT_INCLUDE_FLAGS "")
  set(SWIFT_SYSROOT_FLAGS "")
  if(SYSROOT_DIR)
    list(APPEND SWIFT_SYSROOT_INCLUDE_FLAGS "-I" "${SYSROOT_DIR}/include")
    list(APPEND SWIFT_SYSROOT_FLAGS "-Xcc" "-isysroot=${SYSROOT_DIR}")
  elseif(ZEPHYR_SDK_INSTALL_DIR AND SWIFT_TARGET)
    # The Zephyr SDK's clang-runtimes contain both errno.h and picolibc.h
    # (the generated config header required by picolibc's sys/features.h).
    # The SDK uses LLVM/clang triple naming (riscv32-none-elf) while Swift embedded
    # modules use ABI triple naming (riscv32-none-none-eabi) — map as needed.
    set(_sdk_clang_arch "${SWIFT_TARGET}")
    string(REGEX REPLACE "^(riscv[0-9]+)-none-none-eabi$" "\\1-none-elf" _sdk_clang_arch "${_sdk_clang_arch}")
    # Find the first non-exception multilib include directory for this target.
    file(GLOB _sdk_multilib_incs
      "${ZEPHYR_SDK_INSTALL_DIR}/llvm/lib/clang-runtimes/${_sdk_clang_arch}/*/include"
    )
    foreach(_dir IN LISTS _sdk_multilib_incs)
      if(NOT "${_dir}" MATCHES "exn_rtti" AND EXISTS "${_dir}/errno.h")
        set(_sdk_include_dir "${_dir}")
        break()
      endif()
    endforeach()
    if(_sdk_include_dir)
      list(APPEND SWIFT_SYSROOT_INCLUDE_FLAGS "-I" "${_sdk_include_dir}")
      message(STATUS "Zephyr Swift Library: Using SDK clang-runtimes headers: ${_sdk_include_dir}")
    else()
      message(WARNING "Zephyr Swift Library: No SDK clang-runtimes headers found for ${SWIFT_TARGET} — standard C headers may be missing")
    endif()
    unset(_sdk_multilib_incs)
    unset(_sdk_include_dir)
    unset(_sdk_clang_arch)
  else()
    message(WARNING "Zephyr Swift Library: No sysroot or SDK headers found — standard C headers may be missing")
  endif()

  # Create custom command to compile the core Zephyr Swift library
  # This builds high-level Swift APIs that depend on ZephyrSys for runtime support
  add_custom_command(
    OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE}

      # === Target Configuration ===
      -target ${SWIFT_TARGET}                                 # Cross-compilation target (e.g., thumbv7em-none-eabi)

      # === Swift Language Features ===
      -Osize                                                  # Optimize for code size (critical for embedded systems)
      -parse-as-library                                       # Compile as library (not executable)
      -strict-memory-safety                                   # Enforce strict memory safety checks
      -whole-module-optimization                              # Whole-module optimization for better embedded performance
      -enable-experimental-feature CImplementation            # Enable C interop features
      -enable-experimental-feature Embedded                   # Enable Embedded Swift features (reduced runtime)
      -enable-experimental-feature Extern                     # Enable extern Swift features
      -enable-upcoming-feature StrictConcurrency              # Enable strict concurrency checks

      # === Code Generation ===
      -Xfrontend -function-sections                           # Separate functions into sections for linker optimization

      # === Output Generation ===
      -emit-object -o ${SWIFT_OBJ_FILE}                       # Generate object file
      -emit-module -emit-module-path ${SWIFT_MODULE_FILE}     # Generate Swift module interface
      -module-name Zephyr                                     # Set the Swift module name to "Zephyr"

      # === Compilation Defines ===
      ${SWIFT_DEFINES}                                        # Add any Swift compilation defines

      # === Include Paths (order matters for proper resolution) ===
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated         # Generated Zephyr headers
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr  # Generated Zephyr-specific headers
      -I ${CMAKE_BINARY_DIR}/zephyr/include                   # Built Zephyr headers
      -I ${ZEPHYR_BASE}/include                               # Source Zephyr headers
      -I ${ZEPHYR_SYS_MODULE}/include                         # ZephyrSys bridging headers
      ${SWIFT_SYSROOT_INCLUDE_FLAGS}                          # System C library headers

      # === Cross-Compilation Configuration ===
      ${SWIFT_SYSROOT_FLAGS}                                  # Sysroot for C headers (cross-compile only)

      # === C Interoperability ===
      -import-bridging-header ${ZEPHYR_SYS_MODULE}/include/BridgingHeader.h  # Import C APIs to Swift

      # === Source Files ===
      ${SWIFT_SOURCES}                                        # Swift source files to compile

    DEPENDS ${SWIFT_SOURCES}
    COMMENT "Compiling Swift sources for Zephyr high-level library")

  # Create a static library target containing the compiled Swift code
  # This library provides high-level Swift APIs for Zephyr development
  add_library(Zephyr STATIC ${SWIFT_OBJ_FILE})

  # Set the linker language to C to ensure proper linking with Zephyr
  # This is necessary because CMake needs to know how to link the final binary
  # and Zephyr applications are ultimately C-based executables
  set_target_properties(Zephyr PROPERTIES LINKER_LANGUAGE C)

  # Create a compilation target to track when Swift compilation is complete
  # This target is used by other Swift code to ensure proper build order
  add_custom_target(Zephyr_compile DEPENDS ${SWIFT_OBJ_FILE}
                                           ${SWIFT_MODULE_FILE})

  # Ensure Swift compilation happens after Zephyr's syscall headers are generated
  # This dependency is critical because Swift code may use Zephyr system calls
  # and needs the generated syscall interfaces to be available
  add_dependencies(Zephyr_compile syscall_list_h_target)

  # Make the Zephyr library target depend on successful Swift compilation
  # This ensures the library is only created after Swift compilation succeeds
  add_dependencies(Zephyr Zephyr_compile)

  # Link with ZephyrSys to provide C runtime support for Swift code
  # PUBLIC linking means users of Zephyr library also get ZephyrSys functionality
  # This provides essential runtime support like @c/@implementation functions
  target_link_libraries(Zephyr PUBLIC ZephyrSys)

  message(STATUS "Zephyr Swift Library: Successfully configured full Swift library")

else()
  # Fallback: Create an interface library when no Swift sources are found
  # This still provides access to ZephyrSys for C interoperability even without
  # Swift library implementation, allowing gradual adoption of Swift features
  message(STATUS "Zephyr Swift Library: No Swift sources found, creating interface library")
  add_library(Zephyr INTERFACE)

  # Link with ZephyrSys through the interface to maintain C runtime support
  # INTERFACE linking means targets that depend on Zephyr get ZephyrSys
  target_link_libraries(Zephyr INTERFACE ZephyrSys)

  message(STATUS "Zephyr Swift Library: Interface library provides ZephyrSys access")
endif()
