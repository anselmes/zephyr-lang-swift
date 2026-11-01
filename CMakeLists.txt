# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

# Swift make support

set(SWIFT_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")

# Enable Swift as a language with settings suited to cross-compiling Embedded
# Swift.  Called by the other functions in this file.
function(_enable_swift)
  # Use the Zephyr SDK's llvm-objcopy.  CMAKE_OBJCOPY must be set before
  # enable_language(Swift).
  if(ZEPHYR_SDK_INSTALL_DIR)
    set(CMAKE_OBJCOPY "${ZEPHYR_SDK_INSTALL_DIR}/llvm/bin/llvm-objcopy"
        CACHE FILEPATH "Object copy tool" FORCE)
  endif()

  # Skip the compiler sanity check: it builds a host-native executable, which
  # fails for cross-compilation toolchains.
  set(CMAKE_Swift_COMPILER_WORKS TRUE CACHE BOOL "Swift compiler works" FORCE)

  # On macOS, CMake finds swiftc through xcrun, which honors TOOLCHAINS.  Set
  # TOOLCHAINS="swift" to select the swift.org toolchain, since Xcode's Swift
  # lacks the LLVM backends for RISC-V and ARM embedded targets.  On Linux,
  # CMake searches PATH (swiftly's shim also honors TOOLCHAINS).
  enable_language(Swift)

  set(CMAKE_Swift_COMPILER_TARGET ${BUILD_TARGET})

  # Embedded Swift requires whole-module optimization.
  set(CMAKE_Swift_COMPILATION_MODE wholemodule)
endfunction()

# Zephyr targets are defined through Kconfig.  We need to map these to an
# appropriate llvm target triple.  This sets `SWIFT_TARGET` in the parent
# scope, or an error if the target is not yet supported by Swift.
function(_swift_map_target)
  # Map Zephyr targets to LLVM targets.
  if(CONFIG_CPU_CORTEX_M)
    if(CONFIG_CPU_CORTEX_M0 OR CONFIG_CPU_CORTEX_M0PLUS OR CONFIG_CPU_CORTEX_M1)
      set(SWIFT_TARGET "thumbv6m-none-eabi" PARENT_SCOPE)
    elseif(CONFIG_CPU_CORTEX_M3)
      set(SWIFT_TARGET "thumbv7m-none-eabi" PARENT_SCOPE)
    elseif(CONFIG_CPU_CORTEX_M4 OR CONFIG_CPU_CORTEX_M7)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET "thumbv7em-none-eabihf" PARENT_SCOPE)
      else()
        set(SWIFT_TARGET "thumbv7em-none-eabi" PARENT_SCOPE)
      endif()
    elseif(CONFIG_CPU_CORTEX_M23 OR CONFIG_CPU_CORTEX_M33 OR CONFIG_CPU_CORTEX_M35P OR CONFIG_CPU_CORTEX_M55)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET "thumbv8m.main-none-eabihf" PARENT_SCOPE)
      else()
        set(SWIFT_TARGET "thumbv8m.main-none-eabi" PARENT_SCOPE)
      endif()
    else()
      message(FATAL_ERROR "Unknown Cortex-M target.")
    endif()
  elseif(CONFIG_ARM64)
    set(SWIFT_TARGET "aarch64-none-elf" PARENT_SCOPE)
  elseif(CONFIG_RISCV)
    # The swift.org embedded modules use the "none-none-eabi" triple, which
    # differs from the SDK clang-runtimes naming ("none-elf").
    if(CONFIG_64BIT)
      set(SWIFT_TARGET "riscv64-none-none-eabi" PARENT_SCOPE)
    else()
      set(SWIFT_TARGET "riscv32-none-none-eabi" PARENT_SCOPE)
    endif()
  else()
    message(FATAL_ERROR "Swift: Add support for other target")
  endif()
endfunction()

# Find the Swift libraries registered in ZEPHYR_SWIFT_LIBRARY_INFO that live in
# one of the extra modules.  Sets `SWIFT_INCLUDE_PATHS` (-I flags) and
# `SWIFT_AVAILABLE_LIBS` in the parent scope.  EXCLUDE_MODULE skips a library,
# so that it doesn't depend on itself.
function(_swift_discover_libraries)
  cmake_parse_arguments(PARSE_ARGV 0 SWIFTDISCO "" "EXCLUDE_MODULE" "")

  set(include_paths "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Normalize the extra module roots so that they can be compared by prefix.
  set(extra_module_dirs "")
  foreach(root ${ZEPHYR_EXTRA_MODULES} ${EXTRA_ZEPHYR_MODULES})
    if(NOT root)
      continue()
    endif()
    get_filename_component(root "${root}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    get_filename_component(root "${root}" REALPATH)
    if(IS_DIRECTORY "${root}")
      list(APPEND extra_module_dirs "${root}")
    endif()
  endforeach()
  list(REMOVE_DUPLICATES extra_module_dirs)

  # Registry entries have the form "module_name|source_dir".
  set(available_libs "")
  get_property(registry GLOBAL PROPERTY ZEPHYR_SWIFT_LIBRARY_INFO)
  foreach(entry ${registry})
    string(FIND "${entry}" "|" separator)
    if(separator LESS 0)
      continue()
    endif()
    string(SUBSTRING "${entry}" 0 ${separator} name)
    math(EXPR start "${separator} + 1")
    string(SUBSTRING "${entry}" ${start} -1 source_dir)

    if(name STREQUAL SWIFTDISCO_EXCLUDE_MODULE OR NOT TARGET ${name}_compile)
      continue()
    endif()

    foreach(dir ${extra_module_dirs})
      string(FIND "${source_dir}/" "${dir}/" pos)
      if(pos EQUAL 0)
        list(APPEND available_libs "${name}")
        list(APPEND include_paths "-I" "${CMAKE_BINARY_DIR}/modules/${name}")
        break()
      endif()
    endforeach()
  endforeach()
  list(REMOVE_DUPLICATES available_libs)

  set(SWIFT_INCLUDE_PATHS "${include_paths}" PARENT_SCOPE)
  set(SWIFT_AVAILABLE_LIBS "${available_libs}" PARENT_SCOPE)
endfunction()

# Build a Swift static library and register it so that applications can find
# it.  Without SOURCES, every .swift file below the current directory is used.
#
#   zephyr_swift_library([MODULE_NAME <name>] [SOURCES <file>...])
function(zephyr_swift_library)
  _enable_swift()

  # Needed so that custom driver classes using system calls are taken into
  # account.
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
    zephyr_syscall_include_directories(include)
    zephyr_include_directories(include)
  endif()

  cmake_parse_arguments(PARSE_ARGV 0 SWIFTLIB "" "MODULE_NAME" "SOURCES")

  if(NOT SWIFTLIB_MODULE_NAME)
    set(SWIFTLIB_MODULE_NAME ${PROJECT_NAME})
  endif()

  if(NOT SWIFTLIB_SOURCES)
    file(GLOB_RECURSE SWIFTLIB_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/*.swift")
  endif()

  if(NOT SWIFTLIB_SOURCES)
    message(WARNING "No Swift sources found for library ${SWIFTLIB_MODULE_NAME}")
    return()
  endif()

  set(MODULE_DIR ${CMAKE_BINARY_DIR}/modules/${SWIFTLIB_MODULE_NAME})
  set(MODULE_OBJ_FILE ${MODULE_DIR}/${SWIFTLIB_MODULE_NAME}.o)
  set(MODULE_SWIFT_MODULE_FILE ${MODULE_DIR}/${SWIFTLIB_MODULE_NAME}.swiftmodule)
  file(MAKE_DIRECTORY ${MODULE_DIR})

  _swift_map_target()
  message(STATUS "Building Swift llvm target ${SWIFT_TARGET}")

  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  _swift_discover_libraries(EXCLUDE_MODULE "${SWIFTLIB_MODULE_NAME}")

  # Build after the sources, the Zephyr module, and the libraries found above.
  set(COMPILE_DEPS ${SWIFTLIB_SOURCES})
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()
  foreach(lib ${SWIFT_AVAILABLE_LIBS})
    list(APPEND COMPILE_DEPS ${lib}_compile)
  endforeach()

  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)

  add_custom_command(
    OUTPUT ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET}
      -Osize
      -parse-as-library
      -strict-memory-safety
      -whole-module-optimization
      -enable-experimental-feature CImplementation
      -enable-experimental-feature Embedded
      -enable-experimental-feature Extern
      -enable-upcoming-feature StrictConcurrency
      -Xfrontend -function-sections
      -emit-object -o ${MODULE_OBJ_FILE}
      -emit-module -emit-module-path ${MODULE_SWIFT_MODULE_FILE}
      -module-name ${SWIFTLIB_MODULE_NAME}
      ${SWIFT_DEFINES}
      ${SWIFT_INCLUDE_PATHS}
      ${SWIFTLIB_SOURCES}
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift library ${SWIFTLIB_MODULE_NAME}"
  )

  add_library(${SWIFTLIB_MODULE_NAME} STATIC ${MODULE_OBJ_FILE})
  set_target_properties(${SWIFTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

  add_custom_target(${SWIFTLIB_MODULE_NAME}_compile
    DEPENDS ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
  )
  add_dependencies(${SWIFTLIB_MODULE_NAME} ${SWIFTLIB_MODULE_NAME}_compile)

  get_filename_component(source_dir "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
  set_property(GLOBAL APPEND PROPERTY ZEPHYR_SWIFT_LIBRARY_INFO
    "${SWIFTLIB_MODULE_NAME}|${source_dir}")
endfunction()

# Build the Swift sources in `src/` into the Zephyr `app` target, together with
# the application bootstrap and every Swift library found in the extra modules.
function(zephyr_swift_application)
  _enable_swift()

  file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift")

  # Provides main(), which calls the application's entrypoint().
  set(SWIFT_APPLICATION "${SWIFT_MODULE_DIR}/zephyr/src/Application.swift")

  set(APP_SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.o")
  set(APP_SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.swiftmodule")

  _swift_map_target()
  message(STATUS "Building Swift llvm target ${SWIFT_TARGET}")

  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  _swift_discover_libraries()

  set(COMPILE_DEPS ${SWIFT_SOURCES})
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()
  foreach(lib ${SWIFT_AVAILABLE_LIBS})
    list(APPEND COMPILE_DEPS ${lib}_compile)
  endforeach()

  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)

  add_custom_command(
    OUTPUT ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET}
      -Osize
      -strict-memory-safety
      -whole-module-optimization
      -enable-experimental-feature CImplementation
      -enable-experimental-feature Embedded
      -enable-experimental-feature Extern
      -enable-upcoming-feature StrictConcurrency
      -Xfrontend -function-sections
      -emit-object -o ${APP_SWIFT_OBJ_FILE}
      ${SWIFT_DEFINES}
      ${SWIFT_INCLUDE_PATHS}
      ${SWIFT_APPLICATION}
      ${SWIFT_SOURCES}
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift application ${PROJECT_NAME} with libraries: ${SWIFT_AVAILABLE_LIBS}"
  )

  add_custom_target(${PROJECT_NAME}_compile
    DEPENDS ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
  )

  target_sources(app PRIVATE ${APP_SWIFT_OBJ_FILE})
  add_dependencies(app ${PROJECT_NAME}_compile)

  target_link_libraries(app PRIVATE Zephyr)
  foreach(lib ${SWIFT_AVAILABLE_LIBS})
    target_link_libraries(app PRIVATE ${lib})
  endforeach()

  # The final link is done by the C toolchain.
  set_target_properties(app PROPERTIES LINKER_LANGUAGE C)

  # .swift_modhash is only used while compiling, so drop it from the binary.
  add_custom_command(
    TARGET app
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash $<TARGET_FILE:app> $<TARGET_FILE:app>
    COMMENT "Removing .swift_modhash section from final binary"
  )
endfunction()

if(CONFIG_SWIFT)
  # C runtime support (zephyr-sys), then the Swift library built on top of it.
  add_subdirectory(zephyr-sys)
  add_subdirectory(zephyr)
endif()
