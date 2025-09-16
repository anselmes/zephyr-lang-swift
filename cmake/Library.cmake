function(swift_library)
  _enable_swift()

  cmake_parse_arguments(PARSE_ARGV 0 SWIFTLIB "" "MODULE_NAME" "SOURCES")

  if(NOT SWIFTLIB_MODULE_NAME)
    set(SWIFTLIB_MODULE_NAME ${PROJECT_NAME})
  endif()

  if(NOT SWIFTLIB_SOURCES)
    file(GLOB_RECURSE SWIFTLIB_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")
  endif()

  if(NOT SWIFTLIB_SOURCES)
    message(WARNING "No Swift sources found for library ${SWIFTLIB_MODULE_NAME}")
    return()
  endif()

  set(MODULE_OBJ_FILE ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.o)
  set(MODULE_SWIFT_MODULE_FILE ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.swiftmodule)

  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME})

  _swift_map_target()

  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  set(COMPILE_DEPS ${SWIFTLIB_SOURCES})

  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -parse-as-library -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${MODULE_OBJ_FILE}
      -emit-module -emit-module-path ${MODULE_SWIFT_MODULE_FILE}
      -module-name ${SWIFTLIB_MODULE_NAME}
      ${SWIFT_DEFINES} ${INCLUDE_PATHS} ${SWIFTLIB_SOURCES}
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift library ${SWIFTLIB_MODULE_NAME}")

  add_library(${SWIFTLIB_MODULE_NAME} STATIC ${MODULE_OBJ_FILE})
  set_target_properties(${SWIFTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

  add_custom_target(${SWIFTLIB_MODULE_NAME}_compile DEPENDS ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE})
  add_dependencies(${SWIFTLIB_MODULE_NAME} ${SWIFTLIB_MODULE_NAME}_compile)
endfunction()
