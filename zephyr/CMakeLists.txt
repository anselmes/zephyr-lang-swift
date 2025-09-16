include(${CMAKE_CURRENT_SOURCE_DIR}/../toolchain.cmake)

file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")

if(SWIFT_SOURCES)
  message(STATUS "Swift sources: ${SWIFT_SOURCES}")

  set(ZEPHYR_SYS_MODULE "${CMAKE_CURRENT_SOURCE_DIR}/../zephyr-sys")

  set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.o")
  set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Zephyr.swiftmodule")

  _swift_map_target()

  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -parse-as-library -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${SWIFT_OBJ_FILE}
      -emit-module -emit-module-path ${SWIFT_MODULE_FILE}
      -module-name Zephyr
      ${SWIFT_DEFINES}
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated
      -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr
      -I ${CMAKE_BINARY_DIR}/zephyr/include
      -I ${ZEPHYR_BASE}/include
      -I ${ZEPHYR_SYS_MODULE}/include
      -I ${SYSROOT_DIR}/include
      -Xcc -isysroot=${SYSROOT_DIR}
      -import-bridging-header ${ZEPHYR_SYS_MODULE}/include/BridgingHeader.h
      ${SWIFT_SOURCES}
    DEPENDS ${SWIFT_SOURCES}
    COMMENT "Compiling Swift sources for Zephyr")

  add_library(Zephyr STATIC ${SWIFT_OBJ_FILE})
  set_target_properties(Zephyr PROPERTIES LINKER_LANGUAGE C)

  add_custom_target(Zephyr_compile DEPENDS ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE})
  add_dependencies(Zephyr_compile syscall_list_h_target)
  add_dependencies(Zephyr Zephyr_compile)

  target_link_libraries(Zephyr PUBLIC ZephyrSys)
else()
  # Fallback: empty library if no Swift sources
  add_library(Zephyr INTERFACE)
  target_link_libraries(Zephyr INTERFACE ZephyrSys)
endif()
