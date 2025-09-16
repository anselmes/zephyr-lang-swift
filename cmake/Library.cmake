function(swift_library)
  _enable_swift()

  # Parse arguments: MODULE_NAME, SOURCES
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

  # Set up paths
  set(MODULE_OBJ_FILE
      ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.o)
  set(MODULE_SWIFT_MODULE_FILE
      ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME}/${SWIFTLIB_MODULE_NAME}.swiftmodule)

  # Ensure output directory exists
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${SWIFTLIB_MODULE_NAME})

  # Get the Swift target architecture
  _swift_map_target()

  # Set up Swift compilation flags
  set(SWIFT_DEFINES "")
  if(CONFIG_SWIFT_DEBUG_INFO)
    list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")
  endif()

  # Build include paths - always include Zephyr, others are optional
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Build dependency targets for compilation order
  set(COMPILE_DEPS ${SWIFTLIB_SOURCES})

  # Always depend on Zephyr if it exists
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

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
      ${SWIFT_DEFINES} ${INCLUDE_PATHS} ${SWIFTLIB_SOURCES}
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling Swift library ${SWIFTLIB_MODULE_NAME}")

  # Create a static library for the Swift module
  add_library(${SWIFTLIB_MODULE_NAME} STATIC ${MODULE_OBJ_FILE})
  set_target_properties(${SWIFTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

  # Add custom target to ensure compilation happens
  add_custom_target(${SWIFTLIB_MODULE_NAME}_compile DEPENDS ${MODULE_OBJ_FILE}
                                                   ${MODULE_SWIFT_MODULE_FILE})
  add_dependencies(${SWIFTLIB_MODULE_NAME} ${SWIFTLIB_MODULE_NAME}_compile)
endfunction()

# function(swift_create_external_library)
#   # Parse arguments
#   cmake_parse_arguments(PARSE_ARGV 0 EXTLIB "" "MODULE_NAME" "SOURCES;DEPENDENCIES")

#   # Set up paths
#   set(MODULE_OBJ_FILE
#       ${CMAKE_BINARY_DIR}/external_swift_libs/${EXTLIB_MODULE_NAME}/${EXTLIB_MODULE_NAME}.o)
#   set(MODULE_SWIFT_MODULE_FILE
#       ${CMAKE_BINARY_DIR}/external_swift_libs/${EXTLIB_MODULE_NAME}/${EXTLIB_MODULE_NAME}.swiftmodule)
#   set(MODULE_PATH ${CMAKE_BINARY_DIR}/external_swift_libs/${EXTLIB_MODULE_NAME})

#   # Register this library in the global registry
#   swift_register_library(${EXTLIB_MODULE_NAME} ${MODULE_PATH} "${EXTLIB_DEPENDENCIES}")

#   # Ensure output directory exists
#   file(MAKE_DIRECTORY ${MODULE_PATH})

#   # Get the Swift target architecture
#   _swift_map_target()

#   # Build include paths for dependencies
#   set(INCLUDE_PATHS "")
#   list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

#   # Add paths for declared dependencies
#   foreach(DEP ${EXTLIB_DEPENDENCIES})
#     swift_get_library_path(${DEP} DEP_PATH)
#     if(DEP_PATH)
#       list(APPEND INCLUDE_PATHS "-I" "${DEP_PATH}")
#     else()
#       message(WARNING "Dependency ${DEP} not found for external library ${EXTLIB_MODULE_NAME}")
#     endif()
#   endforeach()

#   # Build dependency targets for compilation order
#   set(COMPILE_DEPS ${EXTLIB_SOURCES})

#   # Always depend on Zephyr if it exists
#   if(TARGET Zephyr_compile)
#     list(APPEND COMPILE_DEPS Zephyr_compile)
#   endif()

#   # Add dependencies on other Swift libraries
#   foreach(DEP ${EXTLIB_DEPENDENCIES})
#     if(TARGET ${DEP}_compile)
#       list(APPEND COMPILE_DEPS ${DEP}_compile)
#     endif()
#   endforeach()

#   # Custom command to compile Swift library
#   find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
#   add_custom_command(
#     OUTPUT ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
#     COMMAND
#       ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -parse-as-library -wmo -Osize
#       -enable-experimental-feature Embedded -Xfrontend -function-sections
#       -emit-object -o ${MODULE_OBJ_FILE}
#       -emit-module -emit-module-path ${MODULE_SWIFT_MODULE_FILE}
#       -module-name ${EXTLIB_MODULE_NAME}
#       ${INCLUDE_PATHS}
#       ${EXTLIB_SOURCES}
#     DEPENDS ${COMPILE_DEPS}
#     COMMENT "Compiling external Swift library ${EXTLIB_MODULE_NAME}")

#   # Create a static library for the Swift module
#   add_library(${EXTLIB_MODULE_NAME} STATIC ${MODULE_OBJ_FILE})
#   set_target_properties(${EXTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

#   # Add custom target to ensure compilation happens
#   add_custom_target(${EXTLIB_MODULE_NAME}_compile DEPENDS ${MODULE_OBJ_FILE}
#                                                    ${MODULE_SWIFT_MODULE_FILE})
#   add_dependencies(${EXTLIB_MODULE_NAME} ${EXTLIB_MODULE_NAME}_compile)
# endfunction()
