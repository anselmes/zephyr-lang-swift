# cmake-format: off
# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

# CMake support for building Embedded Swift with Zephyr through SwiftPM.
#
# Swift code is described by Package.swift manifests: this module's root
# package (ZephyrSystem, ZephyrCore, Zephyr, ZephyrApplication) and one package
# per application. Swift needs the headers that a Zephyr build generates
# (autoconf.h, syscalls) and flags that depend on Kconfig, so `swift build`
# cannot run on its own. Instead, for every Zephyr build this file:
#
# 1. writes a SwiftPM toolset (swift/toolset.json in the build directory) with
#    the target options: -Osize, the Zephyr include paths, the C library
#    headers and the Kconfig defines Swift code tests with `#if`;
# 2. runs `swift build --product app` for the application's package, after
#    Zephyr has generated its headers;
# 3. links the static library it produces into the `app` target.
#
# The entry points are:
#   zephyr_swift_application()  Build the application package and link it.
#   zephyr_swift_library()      Register a Swift library module with Kconfig.
#   zephyr_swift_include_directories()
#                               Add header search paths to the Swift builds.
#
# Cache options:
#   ZEPHYR_SWIFT_OFFLINE       ON: use only the versions in Package.resolved and
#                              fail if it is missing or stale. Missing sources
#                              are still fetched. For CI.
#   ZEPHYR_SWIFT_LSP_CONFIG    ON (default): write .sourcekit-lsp/config.json
#                              into the application package for the editor.
#   ZEPHYR_SWIFT_BUILD_SYSTEM  SwiftPM build system, `native` by default.
# cmake-format: on

set(SWIFT_MODULE_DIR
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE INTERNAL "")

option(ZEPHYR_SWIFT_OFFLINE
       "Build Swift packages without resolving dependencies" OFF)
option(ZEPHYR_SWIFT_EMBEDDED
       "Compile every Swift package, dependencies included, as Embedded Swift"
       ON)
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
  # ZephyrCore compiles its wrappers only for the subsystems the build has:
  # FileSystem, Directory and File; CRC32; Thread (dynamic stacks).
  foreach(symbol IN ITEMS FILE_SYSTEM CRC DYNAMIC_THREAD)
    if(CONFIG_${symbol})
      list(APPEND defines "-DCONFIG_${symbol}")
    endif()
  endforeach()
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

# Store the elements of an array of toolset options in `out`, as JSON strings,
# one per line.
function(_swift_json_items out)
  set(items "")
  foreach(option IN LISTS ARGN)
    _swift_json_string(item "${option}")
    list(APPEND items "${item}")
  endforeach()
  list(JOIN items ",\n      " items)
  set(${out}
      "${items}"
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
#
# Two build directories of the same application may be configured at once, and
# both write the files that live in the package (.sourcekit-lsp/config.json).
# The content goes to a temporary file that is named after this build directory
# and sits next to `path`, and replaces `path` with a rename, which is atomic on
# one file system: neither configuration can remove the other's temporary file,
# and a reader never sees a half-written file.
function(_swift_write_if_changed path content)
  if(EXISTS "${path}")
    file(READ "${path}" existing)
    if(existing STREQUAL content)
      return()
    endif()
  endif()
  string(MD5 id "${CMAKE_BINARY_DIR}")
  set(tmp "${path}.${id}.tmp")
  file(WRITE "${tmp}" "${content}")
  file(RENAME "${tmp}" "${path}")
endfunction()

# Set SWIFT_ARCH_OPTIONS in the parent scope to the plain Clang options that
# select the ISA and ABI the application's C code is compiled for. Swift does
# not read Zephyr's compiler flags: without them it targets its own default
# for the triple (riscv32 includes the M, A and C extensions), so Swift code
# can contain multiplies, atomics and 16-bit compressed instructions that a
# core without them (Nios V/m is rv32i) traps on as illegal instructions, even
# though Zephyr's C code runs. Zephyr computes these two values from Kconfig in
# cmake/compiler/gcc/target_riscv.cmake; reuse them so that Swift always agrees
# with the C code and the kernel.
function(_swift_arch_options)
  set(options "")
  if(CONFIG_RISCV)
    if(riscv_march AND riscv_mabi)
      list(APPEND options "-march=${riscv_march}" "-mabi=${riscv_mabi}")
      message(STATUS "Swift: ISA ${riscv_march}, ABI ${riscv_mabi}")
    else()
      message(
        WARNING "Swift: riscv_march/riscv_mabi are not set; Swift uses its "
                "default ISA for ${SWIFT_TARGET}, which may not match the core")
    endif()
  endif()
  set(SWIFT_ARCH_OPTIONS
      "${options}"
      PARENT_SCOPE)
endfunction()

# Write the SwiftPM toolset for this build to `path`: the target options every
# Swift module is compiled with, and the Zephyr SDK's llvm-ar for archives. All
# modules get the same Clang options, so they share one build of the
# ZephyrSystem Clang module.
function(_swift_write_toolset path)
  _swift_sysroot_flags()
  _swift_defines()
  _swift_arch_options()

  # The same options for swiftc (through -Xcc) and for the C and C++ targets of
  # a package.
  set(swift_arch_options "")
  foreach(option IN LISTS SWIFT_ARCH_OPTIONS)
    list(APPEND swift_arch_options "-Xcc" "${option}")
  endforeach()

  # The directories that modules registered with
  # zephyr_swift_include_directories(), as -Xcc options for Swift and plain
  # options for C.
  get_property(extra_dirs GLOBAL PROPERTY ZEPHYR_SWIFT_INCLUDE_DIRECTORIES)
  set(extra_options "")
  set(extra_c_options "")
  foreach(dir IN LISTS extra_dirs)
    list(APPEND extra_options "-Xcc" "-I${dir}")
    list(APPEND extra_c_options "-I${dir}")
  endforeach()

  # A dependency's manifest cannot know it is built for firmware, so it does not
  # enable Embedded Swift itself; every module of the build has to agree on it.
  set(embedded_options "")
  if(ZEPHYR_SWIFT_EMBEDDED)
    set(embedded_options "-enable-experimental-feature" "Embedded")
  endif()

  set(options
      # Optimize for size; comes after the -O that SwiftPM passes for release.
      "-Osize"
      ${embedded_options}
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
      # Load the kernel configuration as macros in Swift's Clang importer too,
      # as Zephyr does for C, so a dependency's header that tests CONFIG_*
      # imports the same declarations its C implementation is compiled with.
      "-Xcc"
      "-imacros"
      "-Xcc"
      "${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr/autoconf.h"
      ${SWIFT_SYSROOT_FLAGS}
      ${swift_arch_options}
      ${extra_options})

  # SwiftPM does not hand the Swift compiler's -Xcc options on to the C and C++
  # targets of a package, so a C-backed dependency would not find Zephyr's or
  # the C library's headers. Give those compilers the same include paths as
  # plain options.
  set(c_options
      "-I${CMAKE_BINARY_DIR}/zephyr/include/generated"
      "-I${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr"
      "-I${CMAKE_BINARY_DIR}/zephyr/include"
      "-I${ZEPHYR_BASE}/include"
      ${SWIFT_SYSROOT_FLAGS})
  list(APPEND c_options ${extra_c_options})
  list(FILTER c_options EXCLUDE REGEX "^-Xcc$")
  list(APPEND c_options ${SWIFT_ARCH_OPTIONS})
  # Zephyr compiles its C and C++ with the kernel configuration loaded as macros
  # (-imacros autoconf.h). Do the same, or a dependency that includes Zephyr
  # headers sees no CONFIG_* symbols and can lay a type out differently from the
  # kernel, for example k_timeout_t with CONFIG_TIMEOUT_64BIT.
  list(APPEND c_options "-imacros"
       "${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr/autoconf.h")

  _swift_json_items(items ${options})
  _swift_json_items(c_items ${c_options})

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
  },
  \"cCompiler\": {
    \"extraCLIOptions\": [
      ${c_items}
    ]
  },
  \"cxxCompiler\": {
    \"extraCLIOptions\": [
      ${c_items}
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

# Add header search paths to every Swift build of this Zephyr build, for the C
# headers of a library that Swift modules import (a Clang module that includes
# them) and that Zephyr itself does not provide.
#
# ~~~
#   zephyr_swift_include_directories(<dir>...)
# ~~~
#
# The directories become `-Xcc -I<dir>` options in the SwiftPM toolset and plain
# `-I<dir>` options for the C targets of a package. Call it from a module's
# CMakeLists.txt, before zephyr_swift_application() writes the toolset.
function(zephyr_swift_include_directories)
  set_property(GLOBAL APPEND PROPERTY ZEPHYR_SWIFT_INCLUDE_DIRECTORIES ${ARGN})
endfunction()

# Enable traits of the application's Swift package in every `swift build` of
# this Zephyr build, for example to turn on a runtime that its manifest forwards
# to a dependency (`.package(…, traits: [.trait(name: "X", condition: …)])`).
#
# ~~~
#   zephyr_swift_traits(<trait>...)
# ~~~
#
# SwiftPM's `--traits` replaces the package's default traits, and rejects
# `defaults` for a package that declares none, so the application should leave
# its default traits empty and choose all of them here. Call it from a module's
# CMakeLists.txt, or from the application's, before zephyr_swift_application().
function(zephyr_swift_traits)
  set_property(GLOBAL APPEND PROPERTY ZEPHYR_SWIFT_TRAITS ${ARGN})
endfunction()

# Build the application's Swift package and link it into the Zephyr `app`
# target.
#
# ~~~
#   zephyr_swift_application([PACKAGE_DIR <dir>] [PRODUCT <name>])
# ~~~
#
# PACKAGE_DIR defaults to the nearest directory at or above the application that
# holds a Package.swift. PRODUCT is the package's static library product, `app`
# by default; it holds the application, every Swift module it depends on and
# ZephyrApplication's C `main`.
#
# ~~~
# Besides the build itself, configuring writes, under swift/ in the build
# directory:
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
    set(SWIFTAPP_PRODUCT "app")
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
  get_property(traits GLOBAL PROPERTY ZEPHYR_SWIFT_TRAITS)
  if(traits)
    list(REMOVE_DUPLICATES traits)
    list(JOIN traits "," traits)
    list(APPEND build_args --traits "${traits}")
  endif()

  # Environment for `swift build`: the toolchain selection, and where this
  # module lives, for manifests that resolve zephyr-lang-swift by path.
  set(build_env "ZEPHYR_LANG_SWIFT_PATH=${SWIFT_MODULE_DIR}")
  if(DEFINED ENV{TOOLCHAINS})
    list(APPEND build_env "TOOLCHAINS=$ENV{TOOLCHAINS}")
  endif()

  # SwiftPM runs on every build. Its planner tracks the whole package graph, so
  # a change in this module, in the application package or in any package the
  # application depends on, by path or by URL, is noticed; CMake cannot list
  # those inputs up front. When nothing changed SwiftPM only plans and leaves
  # the archive alone, and the archive is a byproduct, so Ninja does not relink
  # the image.
  add_custom_target(
    swift_build
    COMMAND ${CMAKE_COMMAND} -E env ${build_env} ${SWIFT_EXECUTABLE}
            ${build_args}
    BYPRODUCTS "${archive}"
    DEPENDS "${toolset}"
    WORKING_DIRECTORY "${package_dir}"
    COMMENT "Building Swift package ${package_dir} (${SWIFTAPP_PRODUCT})"
    USES_TERMINAL)

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

  # SourceKit-LSP configuration, so the editor resolves ZephyrSystem and the
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
