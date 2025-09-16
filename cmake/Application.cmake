function(swift_application)
  _enable_swift()

  # Find all Swift source files
  file(GLOB_RECURSE SWIFT_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift")

  set(SWIFT_APPLICATION "${SWIFT_MODULE_DIR}/zephyr/src/Application.swift")

  # Create output paths for Swift application
  set(APP_SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.o")
  set(APP_SWIFT_MODULE_FILE
      "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.swiftmodule")

  # Build include paths - start with Zephyr
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Check for common Swift modules that might be available
  set(AVAILABLE_LIBS "")
  set(POSSIBLE_MODULES "Hello" "Utils" "Common") # Add more as needed

  foreach(MODULE_NAME ${POSSIBLE_MODULES})
    if(TARGET ${MODULE_NAME}_compile)
      set(MODULE_PATH "${CMAKE_BINARY_DIR}/modules/${MODULE_NAME}/${MODULE_NAME}")
      list(APPEND INCLUDE_PATHS "-I" "${MODULE_PATH}")
      list(APPEND AVAILABLE_LIBS "${MODULE_NAME}")
    endif()
  endforeach()

  # Build dependency targets for compilation order
  set(COMPILE_DEPS ${SWIFT_SOURCES})

  # Always depend on Zephyr if it exists
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

  # Add dependencies on discovered Swift libraries
  foreach(LIB ${AVAILABLE_LIBS})
    if(TARGET ${LIB}_compile)
      list(APPEND COMPILE_DEPS ${LIB}_compile)
    endif()
  endforeach()

  # Get the Swift target architecture
  _swift_map_target()

  # Set up Swift compilation flags
  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  # Custom command to compile Swift main application
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${APP_SWIFT_OBJ_FILE}
      ${SWIFT_DEFINES}
      ${INCLUDE_PATHS}
      ${SWIFT_APPLICATION} ${SWIFT_SOURCES}
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift application ${PROJECT_NAME} with libraries: ${AVAILABLE_LIBS}")

  # Add custom target to ensure Swift compilation happens
  add_custom_target(${PROJECT_NAME}_compile DEPENDS ${APP_SWIFT_OBJ_FILE}
                                                    ${APP_SWIFT_MODULE_FILE})

  # Add the Swift object file directly to the app target sources
  target_sources(app PRIVATE ${APP_SWIFT_OBJ_FILE})
  add_dependencies(app ${PROJECT_NAME}_compile)

  # Link the Zephyr library for additional Swift utilities
  target_link_libraries(app PRIVATE Zephyr)

  # Link discovered Swift libraries
  foreach(LIB ${AVAILABLE_LIBS})
    if(TARGET ${LIB})
      target_link_libraries(app PRIVATE ${LIB})
    endif()
  endforeach()

  # Set linker language for the app target to ensure proper linking
  set_target_properties(app PROPERTIES LINKER_LANGUAGE C)

  # Post-build step: Remove the .swift_modhash section from the final binary
  add_custom_command(
    TARGET app
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash $<TARGET_FILE:app>
            $<TARGET_FILE:app>
    COMMENT "Removing .swift_modhash section from final binary")
endfunction()
