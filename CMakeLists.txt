set(SWIFT_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")

add_subdirectory(zephyr-sys)
add_subdirectory(zephyr)

function(_swift_map_target)
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
      message(FATAL_ERROR "Swift: Unsupported ARM Cortex-M variant")
    endif()
  elseif(CONFIG_ARM64)
    set(SWIFT_TARGET "aarch64-none-elf" PARENT_SCOPE)
  elseif(CONFIG_RISCV)
    if(CONFIG_64BIT)
      set(SWIFT_TARGET "riscv64-none-elf" PARENT_SCOPE)
    else()
      set(SWIFT_TARGET "riscv32-none-elf" PARENT_SCOPE)
    endif()
  else()
    message(FATAL_ERROR "Swift: Add support for other target architectures")
  endif()
endfunction()

function(swift_application)
  # Set global Swift compiler flags
  # These flags enable embedded development features and configure optimizations
  add_compile_options(
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-enable-experimental-feature Embedded>"          # Enable Swift for embedded systems feature
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xfrontend -function-sections>"                  # Place each function in its own section for better link-time optimization
  )

  # Find all Swift source files
  file(GLOB_RECURSE SWIFT_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift"
    "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift"
  )

  # Create output paths for Swift application
  set(APP_SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.o")
  set(APP_SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.swiftmodule")

  # FIXME: This logic duplicates the target architecture mapping found in zephyr/CMakeLists.txt lines 12-42. Consider extracting this into the _swift_map_target function and calling it here to avoid code duplication.
  # Get the Swift target architecture
  if(CONFIG_RISCV)
    if(CONFIG_64BIT)
      set(SWIFT_TARGET "riscv64-none-none-eabi")
    else()
      set(SWIFT_TARGET "riscv32-none-none-eabi")
    endif()
  elseif(CONFIG_ARM64)
    set(SWIFT_TARGET "aarch64-none-elf")
  elseif(CONFIG_CPU_CORTEX_M)
    # Add Cortex-M variants here if needed
    set(SWIFT_TARGET "thumbv7m-none-eabi")
  else()
    message(FATAL_ERROR "Swift: Add support for other target architectures")
  endif()

  # Custom command to compile Swift main application
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
    COMMAND ${SWIFTC_EXECUTABLE}
      -target ${SWIFT_TARGET}
      -parse-as-library
      -wmo
      -Osize
      -enable-experimental-feature Embedded
      -Xfrontend -function-sections
      -emit-object -o ${APP_SWIFT_OBJ_FILE}
      -emit-module -emit-module-path ${APP_SWIFT_MODULE_FILE}
      -module-name ${PROJECT_NAME}
      -I ${CMAKE_CURRENT_BINARY_DIR}/modules/lang-swift/zephyr
      ${SWIFT_SOURCES}
    DEPENDS ${SWIFT_SOURCES} ZephyrSwift_compile
    COMMENT "Compiling Swift application ${PROJECT_NAME}"
  )

  # Add custom target to ensure Swift compilation happens
  add_custom_target(${PROJECT_NAME}_compile DEPENDS ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE})

  # Add the Swift object file directly to the app target sources
  # This ensures the Swift object is linked with full access to Zephyr symbols
  target_sources(app PRIVATE ${APP_SWIFT_OBJ_FILE})
  add_dependencies(app ${PROJECT_NAME}_compile)

  # Link the ZephyrSwift library for additional Swift utilities
  target_link_libraries(app PRIVATE ZephyrSwift)

  # Set linker language for the app target to ensure proper linking
  set_target_properties(app PROPERTIES LINKER_LANGUAGE C)

  # Post-build step: Remove the .swift_modhash section from the final binary
  # The .swift_modhash section is used for incremental compilation but is not needed in the final embedded binary.
  # Removing it reduces binary size and removes unnecessary metadata.
  add_custom_command(TARGET app POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash $<TARGET_FILE:app> $<TARGET_FILE:app>
    COMMENT "Removing .swift_modhash section from final binary"
  )
endfunction()
