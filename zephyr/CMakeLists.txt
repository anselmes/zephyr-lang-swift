# Find all Swift source files
file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift")

if(SWIFT_SOURCES)
  message(STATUS "Swift sources: ${SWIFT_SOURCES}")

  # Create output paths
  set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSwift.o")
  set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSwift.swiftmodule")

  # Get the Swift target architecture from parent scope
  if(CONFIG_RISCV)
    # FIXME: The RISC-V target triples use 'none-none-eabi' but other architectures use different patterns (e.g., 'aarch64-none-elf'). Consider standardizing the target triple format or documenting why RISC-V requires this specific format.
    if(CONFIG_64BIT)
      set(SWIFT_TARGET "riscv64-none-none-eabi")
    else()
      set(SWIFT_TARGET "riscv32-none-none-eabi")
    endif()
  elseif(CONFIG_ARM64)
    set(SWIFT_TARGET "aarch64-none-elf")
  elseif(CONFIG_CPU_CORTEX_M)
    if(CONFIG_CPU_CORTEX_M0 OR CONFIG_CPU_CORTEX_M0PLUS OR CONFIG_CPU_CORTEX_M1)
      set(SWIFT_TARGET "thumbv6m-none-eabi")
    elseif(CONFIG_CPU_CORTEX_M3)
      set(SWIFT_TARGET "thumbv7m-none-eabi")
    elseif(CONFIG_CPU_CORTEX_M4 OR CONFIG_CPU_CORTEX_M7)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET "thumbv7em-none-eabihf")
      else()
        set(SWIFT_TARGET "thumbv7em-none-eabi")
      endif()
    elseif(CONFIG_CPU_CORTEX_M23 OR CONFIG_CPU_CORTEX_M33 OR CONFIG_CPU_CORTEX_M35P OR CONFIG_CPU_CORTEX_M55)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET "thumbv8m.main-none-eabihf")
      else()
        set(SWIFT_TARGET "thumbv8m.main-none-eabi")
      endif()
    else()
      message(FATAL_ERROR "Swift: Unsupported ARM Cortex-M variant")
    endif()
  else()
    message(FATAL_ERROR "Swift: Add support for other target architectures")
  endif()

  # Custom command to compile Swift sources
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
    COMMAND ${SWIFTC_EXECUTABLE}
      -target ${SWIFT_TARGET}
      -parse-as-library
      -wmo
      -Osize
      -enable-experimental-feature Embedded
      -Xfrontend -function-sections
      -emit-object -o ${SWIFT_OBJ_FILE}
      -emit-module -emit-module-path ${SWIFT_MODULE_FILE}
      -module-name ZephyrSwift
      ${SWIFT_SOURCES}
    DEPENDS ${SWIFT_SOURCES}
    COMMENT "Compiling Swift sources for ZephyrSwift"
  )

  # Create a static library that contains the Swift object
  add_library(ZephyrSwift STATIC ${SWIFT_OBJ_FILE})
  set_target_properties(ZephyrSwift PROPERTIES
    LINKER_LANGUAGE C
  )

  # Add custom target to ensure Swift compilation happens
  add_custom_target(ZephyrSwift_compile DEPENDS ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE})
  add_dependencies(ZephyrSwift ZephyrSwift_compile)

  # Link with zephyr-sys
  target_link_libraries(ZephyrSwift PUBLIC ZephyrSys)

else()
  # Fallback: empty library if no Swift sources
  add_library(ZephyrSwift INTERFACE)
  target_link_libraries(ZephyrSwift INTERFACE ZephyrSys)
endif()
