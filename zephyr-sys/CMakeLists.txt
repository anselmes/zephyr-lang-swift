#[=======================================================================[.rst:
ZephyrSystem - Swift Runtime Support Library (Swift 6.4 Implementation)
=====================================================================

This CMake file builds the ZephyrSystem library using Swift 6.4's embedded mode
and enhanced C interoperability features. The library provides essential
runtime support for Swift code running on Zephyr RTOS.

## Swift 6.4 Features

This build configuration leverages Swift 6.4's improvements:

**@c and @implementation Attributes**
  Swift functions can implement C interfaces using @c @implementation,
  providing type-safe implementations that maintain C ABI compatibility.

**Embedded Swift Mode**
  Optimized Swift subset for resource-constrained embedded systems:
  - Reduced memory footprint
  - Minimal runtime requirements
  - Size-optimized compilation
  - Function sections for better linking

**Enhanced C Interoperability**
  Improved tolerance of C signature mismatches and better bridging
  header processing for seamless Swift-C integration.

## Build Process

1. **Swift Source Discovery**: Locate all .swift files in src/ and lib/
2. **Target Configuration**: Map Zephyr's target architecture to Swift
3. **Cross-Compilation**: Compile Swift to object files for embedded target
4. **Library Creation**: Package Swift objects into static library
5. **Integration**: Link with Zephyr kernel and provide public headers

## Output Components

**ZephyrSystem.o**
  Compiled Swift object code containing C-compatible function implementations

**ZephyrSystem.swiftmodule**
  Swift module interface for importing by other Swift code

**Static Library**
  Linkable library providing Swift runtime support for Zephyr applications

## Dependencies

- Swift 6.4+ compiler with embedded features
- Zephyr RTOS build environment
- Cross-compilation toolchain (SYSROOT_DIR, CROSS_COMPILE)
- Generated Zephyr headers and syscall interfaces

#]=======================================================================]

# Discover all Swift source files in the zephyr-sys directory structure
# src/: Core Swift implementations of C runtime functions using @c @implementation
# lib/: Additional Swift libraries and utilities for enhanced functionality
file(GLOB_RECURSE SWIFT_SOURCES
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift"
     "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")

# Ensure Swift sources are available - this is a Swift-only implementation
# The ZephyrSystem library requires Swift 6.4+ for @c @implementation support
if(NOT SWIFT_SOURCES)
  message(FATAL_ERROR "No Swift sources found in ZephyrSystem. Swift implementation is required.")
endif()

list(LENGTH SWIFT_SOURCES SWIFT_SOURCES_COUNT)
message(STATUS "ZephyrSystem: Found ${SWIFT_SOURCES_COUNT} Swift source files")
message(STATUS "ZephyrSystem: Swift sources: ${SWIFT_SOURCES}")

# Define output file paths for the compiled Swift components
# These files are generated during the Swift compilation process
set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSystem.o")        # Compiled object code
set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSystem.swiftmodule")  # Swift module interface

# Determine the Swift target triple based on Zephyr's CPU configuration
# This function maps Zephyr's CONFIG_ARCH and CONFIG_SOC to appropriate
# Swift target triples (e.g., thumbv7em-none-eabi for ARM Cortex-M)
_swift_map_target()

message(STATUS "ZephyrSystem: Swift target triple: ${SWIFT_TARGET}")

# Configure Swift compilation defines based on Zephyr configuration
# These defines control conditional compilation in Swift source code
set(SWIFT_DEFINES "")
if(CONFIG_SWIFT_DEBUG_INFO)
  list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")   # Enable Swift debug information when configured in Zephyr
  message(STATUS "ZephyrSystem: Debug information enabled")
endif()

# Additional Swift defines can be added here based on Zephyr configuration:
# if(CONFIG_SWIFT_FEATURE_X)
#   list(APPEND SWIFT_DEFINES "-DSWIFT_FEATURE_X")
# endif()

# Locate the Swift compiler executable.
# swiftly's PATH shim respects the TOOLCHAINS env var on all platforms —
# set TOOLCHAINS="swift" to select the swift.org toolchain.
find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
if(NOT SWIFTC_EXECUTABLE)
  message(FATAL_ERROR "Swift compiler not found. Please install Swift 6.4+ with embedded support.")
endif()

message(STATUS "ZephyrSystem: Using Swift compiler: ${SWIFTC_EXECUTABLE}")

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
    message(STATUS "ZephyrSystem: Using SDK clang-runtimes headers: ${_sdk_include_dir}")
  else()
    message(WARNING "ZephyrSystem: No SDK clang-runtimes headers found for ${SWIFT_TARGET} — standard C headers may be missing")
  endif()
  unset(_sdk_multilib_incs)
  unset(_sdk_include_dir)
  unset(_sdk_clang_arch)
else()
  message(WARNING "ZephyrSystem: No sysroot or SDK headers found — standard C headers may be missing")
endif()

# Create custom command to compile Swift sources with C header implementations
# This command uses Swift 6.4's embedded mode and @c @implementation features
add_custom_command(
  OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
  COMMAND
    ${SWIFTC_EXECUTABLE}

    # === Target Configuration ===
    -target ${SWIFT_TARGET}                               # Cross-compilation target (e.g., thumbv7em-none-eabi)

    # === Swift Language Features ===
    -Osize                                                  # Optimize for code size (critical for embedded systems)
    -swift-version 6
    -parse-as-library                                       # Compile as library (not executable)
    -strict-memory-safety                                   # Enforce strict memory safety checks
    -whole-module-optimization                              # Whole-module optimization for better embedded performance
    -enable-experimental-feature CImplementation            # Enable C interop features
    -enable-experimental-feature Embedded                   # Enable Embedded Swift features (reduced runtime)
    -enable-experimental-feature Extern                     # Enable extern Swift features
    -enable-upcoming-feature ExistentialAny
    -enable-upcoming-feature InternalImportsByDefault
    -enable-upcoming-feature MemberImportVisibility

    # === Code Generation ===
    -Xfrontend -function-sections                           # Separate functions into sections for linker optimization

    # === Output Generation ===
    -emit-object -o ${SWIFT_OBJ_FILE}                       # Generate object file for linking
    -emit-module -emit-module-path ${SWIFT_MODULE_FILE}     # Generate Swift module interface
    -module-name ZephyrSystem                                  # Set the Swift module name to "ZephyrSystem"

    # === Compilation Defines ===
    ${SWIFT_DEFINES}                                        # Add any Swift compilation defines from Zephyr config

    # === Include Paths (order matters for proper resolution) ===
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated         # Generated Zephyr headers (autoconf.h, etc.)
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr  # Generated Zephyr-specific headers
    -I ${CMAKE_BINARY_DIR}/zephyr/include                   # Built Zephyr headers
    -I ${ZEPHYR_BASE}/include                               # Source Zephyr headers from tree
    -I ${CMAKE_CURRENT_SOURCE_DIR}/include                  # ZephyrSystem bridging headers
    ${SWIFT_SYSROOT_INCLUDE_FLAGS}                          # System C library headers

    # === Cross-Compilation Configuration ===
    ${SWIFT_SYSROOT_FLAGS}                                  # Sysroot for C headers (cross-compile only)
    -Xcc -DZEPHYR_BUILD_ENV                                 # Define that we're in a Zephyr build environment

    # === C Interoperability ===
    -import-bridging-header ${CMAKE_CURRENT_SOURCE_DIR}/include/BridgingHeader.h  # Import C APIs to Swift

    # === Source Files ===
    ${SWIFT_SOURCES}                                        # Swift source files to compile

  DEPENDS ${SWIFT_SOURCES}
  COMMENT "Compiling Swift sources for ZephyrSystem with @c @implementation support")

# Create the ZephyrSystem static library target containing Swift implementations
add_library(ZephyrSystem STATIC)

# Set the linker language to C to ensure proper linking with Zephyr This is
# necessary because CMake needs to know how to link the final binary
set_target_properties(ZephyrSystem PROPERTIES LINKER_LANGUAGE C)

# Create a compilation target to track when Swift compilation is complete
add_custom_target(ZephyrSystem_swift_compile DEPENDS ${SWIFT_OBJ_FILE}
                                                  ${SWIFT_MODULE_FILE})

# Ensure Swift compilation happens after Zephyr's syscall headers are generated
add_dependencies(ZephyrSystem_swift_compile syscall_list_h_target)

# Add the compiled Swift object file to the library
target_sources(ZephyrSystem PRIVATE ${SWIFT_OBJ_FILE})

# Make the ZephyrSystem library target depend on successful Swift compilation
add_dependencies(ZephyrSystem ZephyrSystem_swift_compile)

# Make the include directory publicly available This contains bridging headers
# and module maps that Swift imports PUBLIC visibility means other targets
# linking to ZephyrSystem get these includes
target_include_directories(ZephyrSystem PUBLIC include)

# Directory holding ZephyrSystem.swiftmodule, so dependent Swift builds (the
# Zephyr library) can add it to their module search path with -I.
set_target_properties(ZephyrSystem PROPERTIES
  SWIFT_MODULE_DIR "${CMAKE_CURRENT_BINARY_DIR}")

# Link with the core Zephyr kernel and libraries PUBLIC linking means that
# targets depending on ZephyrSystem also get Zephyr This ensures Swift code has
# access to all Zephyr RTOS functionality
target_link_libraries(ZephyrSystem PUBLIC zephyr)
