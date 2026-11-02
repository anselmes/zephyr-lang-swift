# SPDX-License-Identifier: GPL-3.0 Copyright (c) 2025 Schubert Anselme
# <schubert@anselm.es>

# ZephyrSystem: the Swift runtime support for Zephyr.
#
# Compiles src/*.swift with swiftc (not SwiftPM) into ZephyrSystem.o and
# ZephyrSystem.swiftmodule, and packages the object in a static library: - the C
# functions the Embedded Swift runtime needs (posix_memalign), which implement
# the declarations in include/BridgingHeader.h with `@c @implementation` -
# Kernel and the k_timeout_t helpers, thin wrappers over the Zephyr C API
#
# Requires a Swift 6.4+ toolchain with Embedded Swift support (swift.org, not
# Xcode's; select it with TOOLCHAINS=swift), the Zephyr SDK and the generated
# Zephyr headers.

# Discover the Swift sources: src/ holds the implementations. lib/ is globbed
# too, but this module has no lib/ directory today.
file(GLOB_RECURSE SWIFT_SOURCES CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift"
     "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")

# This module is Swift-only, so an empty glob is a configuration error.
if(NOT SWIFT_SOURCES)
  message(
    FATAL_ERROR
      "No Swift sources found in ZephyrSystem. Swift implementation is required."
  )
endif()

list(LENGTH SWIFT_SOURCES SWIFT_SOURCES_COUNT)
message(STATUS "ZephyrSystem: Found ${SWIFT_SOURCES_COUNT} Swift source files")
message(STATUS "ZephyrSystem: Swift sources: ${SWIFT_SOURCES}")

# Output files of the swiftc invocation below
set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSystem.o")
set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSystem.swiftmodule")

# Map the CPU Zephyr is configured for (CONFIG_CPU_CORTEX_*, CONFIG_ARM64,
# CONFIG_RISCV) to a Swift target triple, such as thumbv7em-none-eabi or
# riscv32-none-none-eabi. Sets SWIFT_TARGET; unsupported CPUs are an error.
_swift_map_target()

message(STATUS "ZephyrSystem: Swift target triple: ${SWIFT_TARGET}")

# Kconfig symbols that Swift code tests with `#if`. Swift cannot see CONFIG_*
# macros, so each one needs its own -D here (and in the other swiftc calls).
set(SWIFT_DEFINES "")
if(CONFIG_SWIFT_DEBUG_INFO)
  list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  message(STATUS "ZephyrSystem: Debug information enabled")
endif()
if(CONFIG_TIMEOUT_64BIT)
  # Tick is Int64 and Instant, now() and absolute timeouts are compiled in.
  list(APPEND SWIFT_DEFINES "-DCONFIG_TIMEOUT_64BIT")
endif()
if(CONFIG_LOG)
  # zephyr_log (zephyr-sys/src/log.swift) logs; without it, it does nothing.
  list(APPEND SWIFT_DEFINES "-DCONFIG_LOG")
endif()
if(CONFIG_LOG_MODE_DEFERRED)
  # zephyr_log hands messages to the logger's buffer instead of building them on
  # the stack.
  list(APPEND SWIFT_DEFINES "-DCONFIG_LOG_MODE_DEFERRED")
endif()
if(NOT CONFIG_STACK_CANARIES)
  # swiftc adds stack protectors to functions that take the address of a local,
  # but Zephyr only provides __stack_chk_guard with CONFIG_STACK_CANARIES.
  list(APPEND SWIFT_DEFINES "-Xfrontend" "-disable-stack-protector")
endif()

# Locate the Swift compiler executable. swiftly's PATH shim respects the
# TOOLCHAINS env var on all platforms — set TOOLCHAINS="swift" to select the
# swift.org toolchain.
find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)

message(STATUS "ZephyrSystem: Using Swift compiler: ${SWIFTC_EXECUTABLE}")

# Compute system header flags for Swift cross-compilation. Priority: 1)
# SYSROOT_DIR env var (cross-compile variant) 2) SDK clang-runtimes headers
# (zephyr/llvm variant — includes picolibc.h) 3) empty (no system headers —
# likely to fail at compile time)
set(SWIFT_SYSROOT_INCLUDE_FLAGS "")
set(SWIFT_SYSROOT_FLAGS "")
if(SYSROOT_DIR)
  list(APPEND SWIFT_SYSROOT_INCLUDE_FLAGS "-I" "${SYSROOT_DIR}/include")
  list(APPEND SWIFT_SYSROOT_FLAGS "-Xcc" "-isysroot=${SYSROOT_DIR}")
elseif(ZEPHYR_SDK_INSTALL_DIR AND SWIFT_TARGET)
  # The Zephyr SDK's clang-runtimes contain both errno.h and picolibc.h (the
  # generated config header required by picolibc's sys/features.h). The SDK uses
  # LLVM/clang triple naming (riscv32-none-elf) while Swift embedded modules use
  # ABI triple naming (riscv32-none-none-eabi) — map as needed.
  set(_sdk_clang_arch "${SWIFT_TARGET}")
  string(REGEX REPLACE "^(riscv[0-9]+)-none-none-eabi$" "\\1-none-elf"
                       _sdk_clang_arch "${_sdk_clang_arch}")
  # Find the first non-exception multilib include directory for this target.
  file(
    GLOB
    _sdk_multilib_incs
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
    message(
      STATUS
        "ZephyrSystem: Using SDK clang-runtimes headers: ${_sdk_include_dir}")
  else()
    message(
      WARNING
        "ZephyrSystem: No SDK clang-runtimes headers found for ${SWIFT_TARGET} — standard C headers may be missing"
    )
  endif()
  unset(_sdk_multilib_incs)
  unset(_sdk_include_dir)
  unset(_sdk_clang_arch)
else()
  message(
    WARNING
      "ZephyrSystem: No sysroot or SDK headers found — standard C headers may be missing"
  )
endif()

# Compile the Swift sources to ZephyrSystem.o and ZephyrSystem.swiftmodule. The
# flag set is shared with the zephyr and root CMakeLists.txt swiftc calls; keep
# the three in step.
add_custom_command(
  OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
  COMMAND
    ${SWIFTC_EXECUTABLE}
    # === Target Configuration ===
    -target ${SWIFT_TARGET} # Cross-compilation target (see _swift_map_target)
    # === Swift Language Features ===
    -Osize # Optimize for code size (critical for embedded systems)
    -swift-version 6 -parse-as-library # Compile as library (not executable)
    -strict-memory-safety # Enforce strict memory safety checks
    -whole-module-optimization # Whole-module optimization for better embedded
                               # performance
    -enable-experimental-feature CImplementation # Allow @c @implementation
                                                 # (implement C declarations in
                                                 # Swift)
    -enable-experimental-feature Embedded # Embedded Swift: no runtime metadata
                                          # or reflection
    -enable-experimental-feature Extern # Enable the @extern attribute
    -enable-upcoming-feature ExistentialAny # Require `any` on existential types
    -enable-upcoming-feature InternalImportsByDefault # `import` is internal;
                                                      # `public import` lets its
                                                      # types appear in public
                                                      # API
    -enable-upcoming-feature MemberImportVisibility # Members need their module
                                                    # imported in the file
    # === Code Generation ===
    -Xfrontend -function-sections # Separate functions into sections for linker
                                  # optimization
    # === Output Generation ===
    -emit-object -o ${SWIFT_OBJ_FILE} # Generate object file for linking
    -emit-module -emit-module-path ${SWIFT_MODULE_FILE} # Generate Swift module
                                                        # interface
    -module-name ZephyrSystem # Swift module name
    # === Compilation Defines ===
    ${SWIFT_DEFINES} # Add any Swift compilation defines from Zephyr config
    # === Include Paths (order matters for proper resolution) ===
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated # Generated Zephyr headers
                                                    # (autoconf.h, etc.)
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr # Generated
                                                           # Zephyr-specific
                                                           # headers
    -I ${CMAKE_BINARY_DIR}/zephyr/include # Built Zephyr headers
    -I ${ZEPHYR_BASE}/include # Source Zephyr headers from tree
    -I ${CMAKE_CURRENT_SOURCE_DIR}/include # ZephyrSystem bridging headers
    ${SWIFT_SYSROOT_INCLUDE_FLAGS} # System C library headers
    # === Cross-Compilation Configuration ===
    ${SWIFT_SYSROOT_FLAGS} # Sysroot for C headers (cross-compile only)
    -Xcc -DZEPHYR_BUILD_ENV # Passed to the C importer while reading the headers
    # === C Interoperability ===
    -import-bridging-header
    ${CMAKE_CURRENT_SOURCE_DIR}/include/BridgingHeader.h # Import C APIs to
                                                         # Swift
    # === Source Files ===
    ${SWIFT_SOURCES} # Swift source files to compile
  DEPENDS ${SWIFT_SOURCES}
  COMMENT
    "Compiling Swift sources for ZephyrSystem with @c @implementation support")

# Static library that carries the Swift object file
add_library(ZephyrSystem STATIC)

# The library has no C sources, so tell CMake to link it with the C toolchain.
set_target_properties(ZephyrSystem PROPERTIES LINKER_LANGUAGE C)

# Target that other targets depend on to wait for the Swift compilation
add_custom_target(ZephyrSystem_swift_compile DEPENDS ${SWIFT_OBJ_FILE}
                                                     ${SWIFT_MODULE_FILE})

# Ensure Swift compilation happens after Zephyr's syscall headers are generated
add_dependencies(ZephyrSystem_swift_compile syscall_list_h_target)

# Add the compiled Swift object file to the library
target_sources(ZephyrSystem PRIVATE ${SWIFT_OBJ_FILE})

# Make the ZephyrSystem library target depend on successful Swift compilation
add_dependencies(ZephyrSystem ZephyrSystem_swift_compile)

# Publish include/ (BridgingHeader.h, module.modulemap) to targets that link
# ZephyrSystem.
target_include_directories(ZephyrSystem PUBLIC include)

# Directory holding ZephyrSystem.swiftmodule, so dependent Swift builds (the
# Zephyr library) can add it to their module search path with -I.
set_target_properties(ZephyrSystem PROPERTIES SWIFT_MODULE_DIR
                                              "${CMAKE_CURRENT_BINARY_DIR}")

# Link the Zephyr kernel; PUBLIC so that dependents get it too.
target_link_libraries(ZephyrSystem PUBLIC zephyr)

# swiftc puts a module hash in `.swift_modhash`. The Zephyr linker script has no
# place for it, so ld.lld (--orphan-handling=warn) warns on every link. Discard
# it.
zephyr_linker_sources(SECTIONS ${CMAKE_CURRENT_LIST_DIR}/swift_orphans.ld)
