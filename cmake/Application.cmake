function(swift_application)
  _enable_swift()

  file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift")

  set(SWIFT_APPLICATION "${SWIFT_MODULE_DIR}/zephyr/src/Application.swift")

  set(APP_SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.o")
  set(APP_SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.swiftmodule")

  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  set(AVAILABLE_LIBS "")
  set(POSSIBLE_MODULES "Hello" "Utils" "Common") # FIXME: Discover dynamically

  foreach(MODULE_NAME ${POSSIBLE_MODULES})
    if(TARGET ${MODULE_NAME}_compile)
      set(MODULE_PATH "${CMAKE_BINARY_DIR}/modules/${MODULE_NAME}/${MODULE_NAME}")
      list(APPEND INCLUDE_PATHS "-I" "${MODULE_PATH}")
      list(APPEND AVAILABLE_LIBS "${MODULE_NAME}")
    endif()
  endforeach()

  set(COMPILE_DEPS ${SWIFT_SOURCES})

  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

  foreach(LIB ${AVAILABLE_LIBS})
    if(TARGET ${LIB}_compile)
      list(APPEND COMPILE_DEPS ${LIB}_compile)
    endif()
  endforeach()

  _swift_map_target()

  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${APP_SWIFT_OBJ_FILE}
      ${SWIFT_DEFINES} ${INCLUDE_PATHS} ${SWIFT_APPLICATION} ${SWIFT_SOURCES}
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift application ${PROJECT_NAME} with libraries: ${AVAILABLE_LIBS}")

  add_custom_target(${PROJECT_NAME}_compile DEPENDS ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE})

  target_sources(app PRIVATE ${APP_SWIFT_OBJ_FILE})
  add_dependencies(app ${PROJECT_NAME}_compile)

  target_link_libraries(app PRIVATE Zephyr)

  foreach(LIB ${AVAILABLE_LIBS})
    if(TARGET ${LIB})
      target_link_libraries(app PRIVATE ${LIB})
    endif()
  endforeach()

  set_target_properties(app PROPERTIES LINKER_LANGUAGE C)

  add_custom_command(
    TARGET app
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash $<TARGET_FILE:app> $<TARGET_FILE:app>
    COMMENT "Removing .swift_modhash section from final binary")
endfunction()
