# cmake-format: off
# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

# CMake support for building Embedded Swift with Zephyr through SwiftPM.
#
# Swift code is described by Package.swift manifests: this module's root
# package (ZephyrCore, ZephyrSystem, Zephyr, ZephyrApplication) and one package
# per application. Swift needs the headers that a Zephyr build generates
# (autoconf.h, syscalls) and flags that depend on Kconfig, so `swift build`
# cannot run on its own. Instead, for every Zephyr build this file:
#
# 1. writes a SwiftPM toolset (build/swift/toolset.json) with the target
#    options: -Osize, the Zephyr include paths, the C library headers and the
#    Kconfig defines Swift code tests with `#if`;
# 2. runs `swift build --product App` for the application's package, after
#    Zephyr has generated its headers;
# 3. links the static library it produces into the `app` target.
#
# The entry points are:
#   zephyr_swift_application()  Build the application package and link it.
#   zephyr_swift_library()      Register a Swift library module with Kconfig.
#
# Cache options:
#   ZEPHYR_SWIFT_OFFLINE       ON: never resolve package dependencies; fail if
#                              Package.resolved is missing or stale. For CI.
#   ZEPHYR_SWIFT_LSP_CONFIG    ON (default): write .sourcekit-lsp/config.json
#                              into the application package for the editor.
#   ZEPHYR_SWIFT_BUILD_SYSTEM  SwiftPM build system, `native` by default.
# cmake-format: on

set(SWIFT_MODULE_DIR
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE INTERNAL "")

option(ZEPHYR_SWIFT_OFFLINE
       "Build Swift packages without resolving dependencies" OFF)
option(ZEPHYR_SWIFT_LSP_CONFIG
       "Write .sourcekit-lsp/config.json into the application package" ON)
# The default build system (swiftbuild) archives with the host's libtool, which
# cannot create ELF archives, so the native build system is used.
set(ZEPHYR_SWIFT_BUILD_SYSTEM
    "native"
    CACHE STRING "SwiftPM build system for Swift packages")

# Zephyr targets are defined through Kconfig.  We need to map these to an
# appropriate llvm target triple.  This sets `SWIFT_TARGET` in the parent scope,
# or an error if the target is not yet supported by Swift.
function(_swift_map_target)
  # Map Zephyr targets to LLVM targets.
  if(CONFIG_CPU_CORTEX_M)
    if(CONFIG_CPU_CORTEX_M0
       OR CONFIG_CPU_CORTEX_M0PLUS
       OR CONFIG_CPU_CORTEX_M1)
      set(SWIFT_TARGET
          "thumbv6m-none-eabi"
          PARENT_SCOPE)
    elseif(CONFIG_CPU_CORTEX_M3)
      set(SWIFT_TARGET
          "thumbv7m-none-eabi"
          PARENT_SCOPE)
    elseif(CONFIG_CPU_CORTEX_M4 OR CONFIG_CPU_CORTEX_M7)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET
            "thumbv7em-none-eabihf"
            PARENT_SCOPE)
      else()
        set(SWIFT_TARGET
            "thumbv7em-none-eabi"
            PARENT_SCOPE)
      endif()
    elseif(
      CONFIG_CPU_CORTEX_M23
      OR CONFIG_CPU_CORTEX_M33
      OR CONFIG_CPU_CORTEX_M35P
      OR CONFIG_CPU_CORTEX_M55)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET
            "thumbv8m.main-none-eabihf"
            PARENT_SCOPE)
      else()
        set(SWIFT_TARGET
            "thumbv8m.main-none-eabi"
            PARENT_SCOPE)
      endif()
    else()
      message(FATAL_ERROR "Unknown Cortex-M target.")
    endif()
  elseif(CONFIG_ARM64)
    set(SWIFT_TARGET
        "aarch64-none-elf"
        PARENT_SCOPE)
  elseif(CONFIG_RISCV)
    # The swift.org embedded modules use the "none-none-eabi" triple, which
    # differs from the SDK clang-runtimes naming ("none-elf").
    if(CONFIG_64BIT)
      set(SWIFT_TARGET
          "riscv64-none-none-eabi"
          PARENT_SCOPE)
    else()
      set(SWIFT_TARGET
          "riscv32-none-none-eabi"
          PARENT_SCOPE)
    endif()
  else()
    message(FATAL_ERROR "Swift: Add support for other target")
  endif()
endfunction()

# Find the C library headers (errno.h, stdlib.h) for SWIFT_TARGET and set
# SWIFT_SYSROOT_FLAGS in the parent scope to the -Xcc options that add them.
# Priority: 1) SYSROOT_DIR (a custom cross toolchain), 2) the Zephyr SDK's
# clang-runtimes headers (zephyr/llvm, which also provide picolibc.h), 3) none.
function(_swift_sysroot_flags)
  set(flags "")
  if(SYSROOT_DIR)
    list(APPEND flags "-Xcc" "-I${SYSROOT_DIR}/include" "-Xcc"
         "--sysroot=${SYSROOT_DIR}")
  elseif(ZEPHYR_SDK_INSTALL_DIR)
    # The SDK uses LLVM/clang triple naming (riscv32-none-elf) while Swift
    # embedded modules use ABI triple naming (riscv32-none-none-eabi).
    string(REGEX REPLACE "^(riscv[0-9]+)-none-none-eabi$" "\\1-none-elf" arch
                         "${SWIFT_TARGET}")
    # The first multilib include directory without exceptions that has the C
    # library headers.
    file(GLOB includes
         "${ZEPHYR_SDK_INSTALL_DIR}/llvm/lib/clang-runtimes/${arch}/*/include")
    foreach(dir IN LISTS includes)
      if(NOT dir MATCHES "exn_rtti" AND EXISTS "${dir}/errno.h")
        list(APPEND flags "-Xcc" "-I${dir}")
        message(STATUS "Swift: C library headers: ${dir}")
        break()
      endif()
    endforeach()
  endif()
  if(NOT flags)
    message(
      WARNING
        "Swift: no C library headers found for ${SWIFT_TARGET}; set SYSROOT_DIR"
    )
  endif()
  set(SWIFT_SYSROOT_FLAGS
      "${flags}"
      PARENT_SCOPE)
endfunction()

# Set SWIFT_DEFINES in the parent scope to the swiftc options derived from
# Kconfig. Swift cannot see CONFIG_* macros, so each symbol that Swift code
# tests with `#if` needs its own -D here.
function(_swift_defines)
  set(defines "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND defines "-DSWIFT_DEBUG_INFO")
  endif()
  if(CONFIG_TIMEOUT_64BIT)
    # Tick is Int64 and Instant, now() and absolute timeouts are compiled in.
    list(APPEND defines "-DCONFIG_TIMEOUT_64BIT")
  endif()
  if(CONFIG_LOG)
    # zephyr_log (zephyr-sys/src/log.swift) logs; without it, it does nothing.
    list(APPEND defines "-DCONFIG_LOG")
  endif()
  if(CONFIG_LOG_MODE_DEFERRED)
    # zephyr_log hands messages to the logger's buffer instead of building them
    # on the stack.
    list(APPEND defines "-DCONFIG_LOG_MODE_DEFERRED")
  endif()
  if(NOT CONFIG_STACK_CANARIES)
    # swiftc adds stack protectors to functions that take the address of a
    # local, but Zephyr only provides __stack_chk_guard with
    # CONFIG_STACK_CANARIES.
    list(APPEND defines "-Xfrontend" "-disable-stack-protector")
  endif()

  # A library registered with zephyr_swift_library() gets a define for its
  # Kconfig symbol when it is enabled, so code can test `#if CONFIG_HELLO`.
  get_property(libraries GLOBAL PROPERTY ZEPHYR_SWIFT_LIBRARIES)
  foreach(library IN LISTS libraries)
    string(TOUPPER "${library}" symbol)
    if(CONFIG_${symbol})
      list(APPEND defines "-DCONFIG_${symbol}")
    endif()
  endforeach()

  set(SWIFT_DEFINES
      "${defines}"
      PARENT_SCOPE)
endfunction()

# Quote `value` for JSON and store it in `out`.
function(_swift_json_string out value)
  string(REPLACE "\\" "\\\\" value "${value}")
  string(REPLACE "\"" "\\\"" value "${value}")
  set(${out}
      "\"${value}\""
      PARENT_SCOPE)
endfunction()

# Quote `value` for a POSIX shell and store it in `out`.
function(_swift_shell_string out value)
  string(REPLACE "'" "'\\''" value "${value}")
  set(${out}
      "'${value}'"
      PARENT_SCOPE)
endfunction()

# Write `content` to `path` only when it differs from the file there, so that
# reconfiguring does not touch the file and rebuild Swift needlessly.
function(_swift_write_if_changed path content)
  file(WRITE "${path}.tmp" "${content}")
  file(COPY_FILE "${path}.tmp" "${path}" ONLY_IF_DIFFERENT)
  file(REMOVE "${path}.tmp")
endfunction()

# Write the SwiftPM toolset for this build to `path`: the target options every
# Swift module is compiled with, and the Zephyr SDK's llvm-ar for archives. All
# modules get the same Clang options, so they share one build of the ZephyrCore
# Clang module.
function(_swift_write_toolset path)
  _swift_sysroot_flags()
  _swift_defines()

  set(options
      # Optimize for size; comes after the -O that SwiftPM passes for release.
      "-Osize"
      # One section per function, so the linker's --gc-sections can drop unused
      # code.
      "-Xfrontend"
      "-function-sections"
      ${SWIFT_DEFINES}
      # Generated headers first (autoconf.h, syscalls), then Zephyr's own.
      "-Xcc"
      "-I${CMAKE_BINARY_DIR}/zephyr/include/generated"
      "-Xcc"
      "-I${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr"
      "-Xcc"
      "-I${CMAKE_BINARY_DIR}/zephyr/include"
      "-Xcc"
      "-I${ZEPHYR_BASE}/include"
      ${SWIFT_SYSROOT_FLAGS})

  set(items "")
  foreach(option IN LISTS options)
    _swift_json_string(item "${option}")
    list(APPEND items "${item}")
  endforeach()
  list(JOIN items ",\n      " items)

  set(librarian "")
  if(ZEPHYR_SDK_INSTALL_DIR AND EXISTS
                                "${ZEPHYR_SDK_INSTALL_DIR}/llvm/bin/llvm-ar")
    _swift_json_string(ar "${ZEPHYR_SDK_INSTALL_DIR}/llvm/bin/llvm-ar")
    set(librarian ",\n  \"librarian\": { \"path\": ${ar} }")
  endif()

  _swift_write_if_changed(
    "${path}"
    "{
  \"schemaVersion\": \"1.0\",
  \"swiftCompiler\": {
    \"extraCLIOptions\": [
      ${items}
    ]
  }${librarian}
}
")
endfunction()

# Set `out` to the directory of the nearest Package.swift at or above `dir`.
function(_swift_find_package out dir)
  set(current "${dir}")
  while(NOT EXISTS "${current}/Package.swift")
    get_filename_component(parent "${current}" DIRECTORY)
    if(parent STREQUAL current)
      message(
        FATAL_ERROR
          "Swift: no Package.swift in ${dir} or a parent directory. "
          "zephyr_swift_application() builds the application's Swift package.")
    endif()
    set(current "${parent}")
  endwhile()
  set(${out}
      "${current}"
      PARENT_SCOPE)
endfunction()

# Register a Swift library module: a directory of a Zephyr module that holds a
# target of a Swift package, usually enabled by a Kconfig symbol of the same
# name (CONFIG_HELLO for MODULE_NAME Hello).
#
# ~~~
#   zephyr_swift_library([MODULE_NAME <name>])
# ~~~
#
# SwiftPM compiles the library as part of every application package that depends
# on it, so this function does not compile anything. It exposes the library's
# include/ directory, if any, to the Zephyr build (including syscall
# generation), and defines CONFIG_<NAME> for Swift code when the symbol is on.
function(zephyr_swift_library)
  cmake_parse_arguments(PARSE_ARGV 0 SWIFTLIB "" "MODULE_NAME" "SOURCES")
  if(NOT SWIFTLIB_MODULE_NAME)
    set(SWIFTLIB_MODULE_NAME ${PROJECT_NAME})
  endif()
  if(SWIFTLIB_SOURCES)
    message(WARNING "zephyr_swift_library(${SWIFTLIB_MODULE_NAME}): SOURCES "
                    "is ignored; the target's sources come from Package.swift")
  endif()

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
    zephyr_syscall_include_directories(include)
    zephyr_include_directories(include)
  endif()

  set_property(GLOBAL APPEND PROPERTY ZEPHYR_SWIFT_LIBRARIES
                                      "${SWIFTLIB_MODULE_NAME}")
  message(STATUS "Swift: library ${SWIFTLIB_MODULE_NAME} "
                 "(built by the application's Package.swift)")
endfunction()

# Build the application's Swift package and link it into the Zephyr `app`
# target.
#
# ~~~
#   zephyr_swift_application([PACKAGE_DIR <dir>] [PRODUCT <name>])
# ~~~
#
# PACKAGE_DIR defaults to the nearest directory at or above the application that
# holds a Package.swift. PRODUCT is the package's static library product, `App`
# by default; it holds the application, every Swift module it depends on and
# ZephyrApplication's C `main`.
#
# ~~~
# Besides the build itself, configuring writes, under build/swift/:
#   toolset.json    the target options for `swift build`
#   swift-build.sh  the exact `swift build` command, for compiling Swift alone
# and, with ZEPHYR_SWIFT_LSP_CONFIG, <package>/.sourcekit-lsp/config.json.
# The `swift_build` target compiles the Swift package without linking.
# ~~~
function(zephyr_swift_application)
  cmake_parse_arguments(PARSE_ARGV 0 SWIFTAPP "" "PACKAGE_DIR;PRODUCT" "")
  if(NOT SWIFTAPP_PACKAGE_DIR)
    _swift_find_package(SWIFTAPP_PACKAGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()
  get_filename_component(package_dir "${SWIFTAPP_PACKAGE_DIR}" ABSOLUTE)
  if(NOT SWIFTAPP_PRODUCT)
    set(SWIFTAPP_PRODUCT "App")
  endif()

  _swift_map_target()
  message(STATUS "Swift: package ${package_dir}, product ${SWIFTAPP_PRODUCT}, "
                 "target ${SWIFT_TARGET}")

  # `swift` from the same toolchain as `swiftc`. On macOS, set TOOLCHAINS=swift
  # to select the swift.org toolchain: Xcode's Swift lacks the Embedded Swift
  # standard library for these targets.
  find_program(SWIFT_EXECUTABLE swift REQUIRED)

  set(swift_dir "${CMAKE_BINARY_DIR}/swift")
  set(toolset "${swift_dir}/toolset.json")
  set(archive "${swift_dir}/${SWIFT_TARGET}/release/lib${SWIFTAPP_PRODUCT}.a")
  file(MAKE_DIRECTORY "${swift_dir}")
  _swift_write_toolset("${toolset}")

  set(build_args
      build
      --build-system
      ${ZEPHYR_SWIFT_BUILD_SYSTEM}
      --package-path
      ${package_dir}
      --scratch-path
      ${swift_dir}
      --cache-path
      ${swift_dir}/cache
      --configuration
      release
      --triple
      ${SWIFT_TARGET}
      --toolset
      ${toolset}
      --product
      ${SWIFTAPP_PRODUCT})
  if(ZEPHYR_SWIFT_OFFLINE)
    list(APPEND build_args --disable-automatic-resolution)
  endif()

  # Environment for `swift build`: the toolchain selection, and where this
  # module lives, for manifests that resolve zephyr-lang-swift by path.
  set(build_env "ZEPHYR_LANG_SWIFT_PATH=${SWIFT_MODULE_DIR}")
  if(DEFINED ENV{TOOLCHAINS})
    list(APPEND build_env "TOOLCHAINS=$ENV{TOOLCHAINS}")
  endif()

  # Rebuild when a Swift source, manifest, lock file or ZephyrCore header of the
  # application package or of this module changes. SwiftPM itself decides what
  # to recompile. Build directories are skipped.
  file(
    GLOB_RECURSE
    inputs
    CONFIGURE_DEPENDS
    "${package_dir}/*.swift"
    "${package_dir}/Package.resolved"
    "${SWIFT_MODULE_DIR}/Package.swift"
    "${SWIFT_MODULE_DIR}/zephyr/*.swift"
    "${SWIFT_MODULE_DIR}/zephyr-sys/*.swift"
    "${SWIFT_MODULE_DIR}/zephyr-sys/include/*")
  list(FILTER inputs EXCLUDE REGEX "/(\\.build|build|\\.swiftpm)/")
  list(REMOVE_DUPLICATES inputs)

  add_custom_command(
    OUTPUT "${archive}"
    COMMAND ${CMAKE_COMMAND} -E env ${build_env} ${SWIFT_EXECUTABLE}
            ${build_args}
    DEPENDS ${inputs} "${toolset}"
    WORKING_DIRECTORY "${package_dir}"
    COMMENT "Building Swift package ${package_dir} (${SWIFTAPP_PRODUCT})"
    USES_TERMINAL)
  add_custom_target(swift_build DEPENDS "${archive}")

  # Swift imports Zephyr's generated headers (syscalls, offsets, version).
  if(TARGET zephyr_generated_headers)
    add_dependencies(swift_build zephyr_generated_headers)
  endif()
  if(TARGET ${SYSCALL_LIST_H_TARGET})
    add_dependencies(swift_build ${SYSCALL_LIST_H_TARGET})
  endif()

  # `app` needs a source file of its own; all of its code is in the archive.
  target_sources(app PRIVATE ${ZEPHYR_BASE}/misc/empty_file.c)
  # Zephyr links the kernel, which has a weak `main`, outside --whole-archive.
  # The linker would not extract the archive member with Swift's `main` to
  # replace it, so link the whole archive. One `-Wl,` item, so that CMake cannot
  # reorder or deduplicate its parts; --gc-sections drops whatever the image
  # does not use.
  target_link_libraries(
    app PRIVATE "-Wl,--whole-archive,${archive},--no-whole-archive")
  # Relink the image when the archive changes.
  set_property(
    TARGET app
    APPEND
    PROPERTY INTERFACE_LINK_DEPENDS "${archive}")
  add_dependencies(app swift_build)
  # The final link is done by the C toolchain.
  set_target_properties(app PROPERTIES LINKER_LANGUAGE C)

  # swift-build.sh: the same `swift build`, for compiling Swift on its own after
  # `west build -t swift_build` has generated Zephyr's headers. Extra arguments
  # are passed on, for example -v.
  set(command "")
  foreach(word IN LISTS build_env)
    _swift_shell_string(quoted "${word}")
    string(APPEND command "${quoted} ")
  endforeach()
  foreach(word ${SWIFT_EXECUTABLE} ${build_args})
    _swift_shell_string(quoted "${word}")
    string(APPEND command "${quoted} ")
  endforeach()
  # syscall_list.h is generated at build time, not when configuring.
  _swift_shell_string(
    headers
    "${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr/syscall_list.h")
  _swift_write_if_changed(
    "${swift_dir}/swift-build.sh"
    "#!/usr/bin/env bash
# Generated by zephyr_swift_application(); regenerated by every configure.
# Builds the Swift package of this Zephyr build without linking the image.
# Usage: swift-build.sh [swift build options...], for example -v.
set -Eeuo pipefail
if [[ ! -e ${headers} ]]; then
  echo 'Zephyr has not generated its headers yet; run: west build -t swift_build' >&2
  exit 1
fi
exec env ${command}\"$@\"
")
  file(
    CHMOD
    "${swift_dir}/swift-build.sh"
    PERMISSIONS
    OWNER_READ
    OWNER_WRITE
    OWNER_EXECUTE
    GROUP_READ
    GROUP_EXECUTE
    WORLD_READ
    WORLD_EXECUTE)

  # SourceKit-LSP configuration, so the editor resolves ZephyrCore and the
  # Zephyr headers of this build. It has its own scratch path: the editor's
  # builds must not race the image build.
  if(ZEPHYR_SWIFT_LSP_CONFIG)
    _swift_json_string(triple "${SWIFT_TARGET}")
    _swift_json_string(lsp_toolset "${toolset}")
    _swift_json_string(lsp_scratch "${CMAKE_BINARY_DIR}/swift-lsp")
    file(MAKE_DIRECTORY "${package_dir}/.sourcekit-lsp")
    _swift_write_if_changed(
      "${package_dir}/.sourcekit-lsp/config.json"
      "{
  \"swiftPM\": {
    \"configuration\": \"release\",
    \"scratchPath\": ${lsp_scratch},
    \"triple\": ${triple},
    \"toolsets\": [${lsp_toolset}]
  }
}
")
  endif()
endfunction()

if(CONFIG_SWIFT)
  # swiftc emits sections that no image needs (.swift_modhash,
  # .swift1_autolink_entries). Discard them instead of letting ld.lld warn that
  # they are orphans.
  zephyr_linker_sources(SECTIONS
                        ${CMAKE_CURRENT_LIST_DIR}/zephyr-sys/swift_orphans.ld)
endif()
