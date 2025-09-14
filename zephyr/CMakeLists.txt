include(${CMAKE_CURRENT_SOURCE_DIR}/../toolchain.cmake)

# Find all Swift source files
file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift")

if(SWIFT_SOURCES)
  message(STATUS "Swift sources: ${SWIFT_SOURCES}")

  # Path to ZephyrSys module
  set(ZEPHYR_SYS_MODULE "${CMAKE_CURRENT_SOURCE_DIR}/../zephyr-sys")

  # Create output paths
  set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.o")
  set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.swiftmodule")

  # Get the Swift target architecture from parent scope
  _swift_map_target()

  # Custom command to compile Swift sources
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -parse-as-library -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${SWIFT_OBJ_FILE}
      -emit-module -emit-module-path ${SWIFT_MODULE_FILE}
      -module-name Zephyr
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr
      -I ${CMAKE_BINARY_DIR}/zephyr/include
      -I ${ZEPHYR_BASE}/include
      -I ${ZEPHYR_SYS_MODULE}/include
      -I ${SYSROOT_DIR}/include
      -import-bridging-header ${ZEPHYR_SYS_MODULE}/include/BridgingHeader.h
      -Xcc -isysroot=${SYSROOT_DIR}
      ${SWIFT_SOURCES}
    DEPENDS ${SWIFT_SOURCES}
    COMMENT "Compiling Swift sources for Zephyr")

  # Create a static library that contains the Swift object
  add_library(Zephyr STATIC ${SWIFT_OBJ_FILE})
  set_target_properties(Zephyr PROPERTIES LINKER_LANGUAGE C)

  # Add custom target to ensure Swift compilation happens
  add_custom_target(Zephyr_compile DEPENDS ${SWIFT_OBJ_FILE}
                                                ${SWIFT_MODULE_FILE})
  add_dependencies(Zephyr_compile syscall_list_h_target)
  add_dependencies(Zephyr Zephyr_compile)

  # Link with zephyr-sys
  target_link_libraries(Zephyr PUBLIC ZephyrSys)
else()
  # Fallback: empty library if no Swift sources
  add_library(Zephyr INTERFACE)
  target_link_libraries(Zephyr INTERFACE ZephyrSys)
endif()
