# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Zephyr: the Swift library with the high-level Zephyr APIs (Duration,
# Timeout, sleep, ZephyrError, check). It builds on ZephyrSystem.
#
# Compiles lib/**/*.swift with swiftc (not SwiftPM) into Zephyr.o and
# Zephyr.swiftmodule, packaged as a static library. src/Application.swift (the
# C `main`) is not part of it: zephyr_swift_application() in the root
# CMakeLists.txt compiles it into each application.
#
# Without any lib/ Swift sources, Zephyr is only an interface library that
# forwards ZephyrSystem.
#
# Also publishes the ZEPHYR_SWIFT_CLIENT_FLAGS global property (see below).

# Discover the library's Swift sources under lib/
file(GLOB_RECURSE SWIFT_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")

# Build the library only when there are Swift sources; otherwise fall through
# to the interface library at the end of the file.
if(SWIFT_SOURCES)
  message(STATUS "Zephyr Swift Library: Found Swift sources, building full library")
  message(STATUS "Zephyr Swift Library: Swift sources: ${SWIFT_SOURCES}")

  # The zephyr-sys module: bridging header and runtime support
  set(ZEPHYR_SYS_MODULE "${CMAKE_CURRENT_SOURCE_DIR}/../zephyr-sys")

  # ZephyrSystem.swiftmodule, which this library imports
  get_target_property(ZEPHYR_SYS_SWIFT_MODULE_DIR ZephyrSystem SWIFT_MODULE_DIR)
  set(ZEPHYR_SYS_SWIFT_MODULE "${ZEPHYR_SYS_SWIFT_MODULE_DIR}/ZephyrSystem.swiftmodule")
  set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.o")
  # Output files of the swiftc invocation below
  set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.swiftmodule")

  message(STATUS "Zephyr Swift Library: Output object: ${SWIFT_OBJ_FILE}")
  message(STATUS "Zephyr Swift Library: Output module: ${SWIFT_MODULE_FILE}")

  # Map the CPU Zephyr is configured for to a Swift target triple (sets
  # SWIFT_TARGET; see _swift_map_target in the root CMakeLists.txt)
  _swift_map_target()

  # Kconfig symbols that Swift code tests with `#if`. Swift cannot see CONFIG_*
  # macros, so each one needs its own -D here (and in the other swiftc calls).
  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
    message(STATUS "Zephyr Swift Library: Debug information enabled")
  endif()
  if(CONFIG_TIMEOUT_64BIT)
    # Tick is Int64 and Instant, now() and absolute timeouts are compiled in.
    list(APPEND SWIFT_DEFINES "-DCONFIG_TIMEOUT_64BIT")
  endif()

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

  # ZEPHYR_SWIFT_CLIENT_FLAGS: the swiftc flags every Swift client of Zephyr
  # (an application or a library) needs to load Zephyr.swiftmodule. The module
  # refers to C types such as k_timeout_t through the bridging header and to
  # Kernel through ZephyrSystem, so clients need the same include paths, the
  # sysroot headers, ZephyrSystem.swiftmodule and the bridging header.
  # _swift_discover_libraries in the root CMakeLists.txt adds them to
  # SWIFT_INCLUDE_PATHS. Keep this list in step with the swiftc call below.
  set_property(GLOBAL PROPERTY ZEPHYR_SWIFT_CLIENT_FLAGS
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr
    -I ${CMAKE_BINARY_DIR}/zephyr/include
    -I ${ZEPHYR_BASE}/include
    -I ${ZEPHYR_SYS_MODULE}/include
    -I ${ZEPHYR_SYS_SWIFT_MODULE_DIR}
    ${SWIFT_SYSROOT_INCLUDE_FLAGS}
    ${SWIFT_SYSROOT_FLAGS}
    -import-bridging-header ${ZEPHYR_SYS_MODULE}/include/BridgingHeader.h
  )

  # Compile the library to Zephyr.o and Zephyr.swiftmodule. The flag set is
  # shared with the zephyr-sys and root CMakeLists.txt swiftc calls; keep the
  # three in step.
  add_custom_command(
    OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE}

      # === Target Configuration ===
      -target ${SWIFT_TARGET}                                 # Cross-compilation target (see _swift_map_target)

      # === Swift Language Features ===
      -Osize                                                  # Optimize for code size (critical for embedded systems)
      -swift-version 6
      -parse-as-library                                       # Compile as library (not executable)
      -strict-memory-safety                                   # Enforce strict memory safety checks
      -whole-module-optimization                              # Whole-module optimization for better embedded performance
      -enable-experimental-feature CImplementation            # Allow @c @implementation (implement C declarations in Swift)
      -enable-experimental-feature Embedded                   # Embedded Swift: no runtime metadata or reflection
      -enable-experimental-feature Extern                     # Enable the @extern attribute
      -enable-upcoming-feature ExistentialAny                 # Require `any` on existential types
      -enable-upcoming-feature InternalImportsByDefault       # `import` is internal; `public import` lets its types appear in public API
      -enable-upcoming-feature MemberImportVisibility         # Members need their module imported in the file

      # === Code Generation ===
      -Xfrontend -function-sections                           # Separate functions into sections for linker optimization

      # === Output Generation ===
      -emit-object -o ${SWIFT_OBJ_FILE}                       # Generate object file
      -emit-module -emit-module-path ${SWIFT_MODULE_FILE}     # Generate Swift module interface
      -module-name Zephyr                                     # Swift module name

      # === Compilation Defines ===
      ${SWIFT_DEFINES}                                        # Kconfig-derived defines (see above)

      # === Include Paths (order matters for proper resolution) ===
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated         # Generated Zephyr headers
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr  # Generated Zephyr-specific headers
      -I ${CMAKE_BINARY_DIR}/zephyr/include                   # Built Zephyr headers
      -I ${ZEPHYR_BASE}/include                               # Source Zephyr headers
      -I ${ZEPHYR_SYS_MODULE}/include                         # ZephyrSystem bridging headers
      -I ${ZEPHYR_SYS_SWIFT_MODULE_DIR}                       # ZephyrSystem.swiftmodule (Kernel, k_timeout_t helpers)
      ${SWIFT_SYSROOT_INCLUDE_FLAGS}                          # System C library headers

      # === Cross-Compilation Configuration ===
      ${SWIFT_SYSROOT_FLAGS}                                  # Sysroot for C headers (cross-compile only)

      # === C Interoperability ===
      -import-bridging-header ${ZEPHYR_SYS_MODULE}/include/BridgingHeader.h  # Import C APIs to Swift

      # === Source Files ===
      ${SWIFT_SOURCES}                                        # Swift source files to compile

    DEPENDS ${SWIFT_SOURCES} ${ZEPHYR_SYS_SWIFT_MODULE}
    COMMENT "Compiling Swift sources for Zephyr high-level library")

  # Static library that carries the Swift object file
  add_library(Zephyr STATIC ${SWIFT_OBJ_FILE})

  # The library has no C sources, so tell CMake to link it with the C toolchain.
  set_target_properties(Zephyr PROPERTIES LINKER_LANGUAGE C)

  # Target that other Swift builds depend on to wait for this compilation
  add_custom_target(Zephyr_compile DEPENDS ${SWIFT_OBJ_FILE}
                                           ${SWIFT_MODULE_FILE})

  # Compile after Zephyr's syscall headers are generated (the bridging header
  # includes them) and after ZephyrSystem.swiftmodule exists.
  add_dependencies(Zephyr_compile syscall_list_h_target ZephyrSystem_swift_compile)

  # Build the library only after the Swift compilation succeeded
  add_dependencies(Zephyr Zephyr_compile)

  # Link ZephyrSystem (posix_memalign and the other runtime support); PUBLIC so
  # that dependents get it too.
  target_link_libraries(Zephyr PUBLIC ZephyrSystem)

  message(STATUS "Zephyr Swift Library: Successfully configured full Swift library")

else()
  # No Swift sources: an interface library that only forwards ZephyrSystem.
  message(STATUS "Zephyr Swift Library: No Swift sources found, creating interface library")
  add_library(Zephyr INTERFACE)

  # Targets that depend on Zephyr get ZephyrSystem.
  target_link_libraries(Zephyr INTERFACE ZephyrSystem)

  message(STATUS "Zephyr Swift Library: Interface library provides ZephyrSystem access")
endif()
