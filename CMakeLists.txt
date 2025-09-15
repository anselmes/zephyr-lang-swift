set(SWIFT_MODULE_DIR
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE INTERNAL "")

add_subdirectory(zephyr-sys)
add_subdirectory(zephyr)

function(swift_library)
  # Parse arguments
  cmake_parse_arguments(PARSE_ARGV 0 SWIFTLIB "" "MODULE_NAME" "SOURCES")

  # Use project name if MODULE_NAME not provided
  if(NOT SWIFTLIB_MODULE_NAME)
    set(SWIFTLIB_MODULE_NAME ${PROJECT_NAME})
  endif()

  # Find Swift sources if not provided
  if(NOT SWIFTLIB_SOURCES)
    file(GLOB_RECURSE SWIFTLIB_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")
  endif()

  # Ensure we have sources
  if(NOT SWIFTLIB_SOURCES)
    message(WARNING "No Swift sources found for library ${SWIFTLIB_MODULE_NAME}")
    return()
  endif()

  set(MODULE_OBJ_FILE
      ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.o)
  set(MODULE_SWIFT_MODULE_FILE
      ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.swiftmodule)

  # Ensure output directory exists
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME})

  # Get the Swift target architecture
  _swift_map_target()

  # Custom command to compile Swift library
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -parse-as-library -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${MODULE_OBJ_FILE}
      -emit-module -emit-module-path ${MODULE_SWIFT_MODULE_FILE}
      -module-name ${SWIFTLIB_MODULE_NAME}


      # -I ${CMAKE_BINARY_DIR}/zephyr/include/generated
      # -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr
      # -I ${CMAKE_BINARY_DIR}/zephyr/include
      # -I ${ZEPHYR_BASE}/include

      -I ${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr
      ${SWIFTLIB_SOURCES}
    DEPENDS ${SWIFTLIB_SOURCES} Zephyr_compile
    COMMENT "Compiling Swift library ${SWIFTLIB_MODULE_NAME}")

  # Create a static library for the Swift module
  add_library(${SWIFTLIB_MODULE_NAME} STATIC ${MODULE_OBJ_FILE})
  set_target_properties(${SWIFTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

  # Add custom target to ensure compilation happens
  add_custom_target(${SWIFTLIB_MODULE_NAME}_compile DEPENDS ${MODULE_OBJ_FILE}
                                                   ${MODULE_SWIFT_MODULE_FILE})
  add_dependencies(${SWIFTLIB_MODULE_NAME} ${SWIFTLIB_MODULE_NAME}_compile)
endfunction()

function(swift_application)
  # Find all Swift source files
  file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift")

  set(SWIFT_APPLICATION "${SWIFT_MODULE_DIR}/zephyr/src/Application.swift")

  # Create output paths for Swift application
  set(APP_SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.o")
  set(APP_SWIFT_MODULE_FILE
      "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.swiftmodule")

  # Get the Swift target architecture
  _swift_map_target()

  # Custom command to compile Swift main application
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${APP_SWIFT_OBJ_FILE}

      # -emit-module -emit-module-path ${APP_SWIFT_MODULE_FILE}
      # -module-name ${PROJECT_NAME}

      # -I ${CMAKE_BINARY_DIR}/zephyr/include/generated
      # -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr
      # -I ${CMAKE_BINARY_DIR}/zephyr/include
      # -I ${ZEPHYR_BASE}/include

      -I ${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr
      -I ${CMAKE_BINARY_DIR}/modules/hello/Hello
      ${SWIFT_APPLICATION} ${SWIFT_SOURCES}
    DEPENDS ${SWIFT_SOURCES} Zephyr_compile Hello_compile
    COMMENT "Compiling Swift application ${PROJECT_NAME}")

  # Add custom target to ensure Swift compilation happens
  add_custom_target(${PROJECT_NAME}_compile DEPENDS ${APP_SWIFT_OBJ_FILE}
                                                    ${APP_SWIFT_MODULE_FILE})

  # Add the Swift object file directly to the app target sources This ensures
  # the Swift object is linked with full access to Zephyr symbols
  target_sources(app PRIVATE ${APP_SWIFT_OBJ_FILE})
  add_dependencies(app ${PROJECT_NAME}_compile)

  # Link the Zephyr library for additional Swift utilities
  target_link_libraries(app PRIVATE Zephyr)

  # Set linker language for the app target to ensure proper linking
  set_target_properties(app PROPERTIES LINKER_LANGUAGE C)

  # Post-build step: Remove the .swift_modhash section from the final binary The
  # .swift_modhash section is used for incremental compilation but is not needed
  # in the final embedded binary. Removing it reduces binary size and removes
  # unnecessary metadata.
  add_custom_command(
    TARGET app
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash $<TARGET_FILE:app>
            $<TARGET_FILE:app>
    COMMENT "Removing .swift_modhash section from final binary")
endfunction()
