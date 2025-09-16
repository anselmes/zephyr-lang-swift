set(SWIFT_MODULE_DIR
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE INTERNAL "")

add_subdirectory(zephyr-sys)
add_subdirectory(zephyr)

# Swift Library Registry System
# This global property tracks all registered Swift libraries and their metadata
set_property(GLOBAL PROPERTY SWIFT_LIBRARIES_REGISTRY "")

# Registry functions for Swift libraries
function(swift_register_library MODULE_NAME MODULE_PATH DEPENDENCIES)
  # Get current registry
  get_property(CURRENT_REGISTRY GLOBAL PROPERTY SWIFT_LIBRARIES_REGISTRY)

  # Create library entry: NAME|PATH|DEPS
  string(REPLACE ";" "," DEPS_STRING "${DEPENDENCIES}")
  set(LIBRARY_ENTRY "${MODULE_NAME}|${MODULE_PATH}|${DEPS_STRING}")

  # Add to registry
  list(APPEND CURRENT_REGISTRY "${LIBRARY_ENTRY}")
  set_property(GLOBAL PROPERTY SWIFT_LIBRARIES_REGISTRY "${CURRENT_REGISTRY}")

  message(STATUS "Registered Swift library: ${MODULE_NAME} at ${MODULE_PATH}")
endfunction()

function(swift_get_library_path MODULE_NAME OUT_PATH)
  get_property(REGISTRY GLOBAL PROPERTY SWIFT_LIBRARIES_REGISTRY)

  foreach(ENTRY ${REGISTRY})
    string(REPLACE "|" ";" ENTRY_PARTS "${ENTRY}")
    list(GET ENTRY_PARTS 0 ENTRY_NAME)
    if("${ENTRY_NAME}" STREQUAL "${MODULE_NAME}")
      list(GET ENTRY_PARTS 1 ENTRY_PATH)
      set(${OUT_PATH} "${ENTRY_PATH}" PARENT_SCOPE)
      return()
    endif()
  endforeach()

  set(${OUT_PATH} "" PARENT_SCOPE)
endfunction()

function(swift_get_library_dependencies MODULE_NAME OUT_DEPS)
  get_property(REGISTRY GLOBAL PROPERTY SWIFT_LIBRARIES_REGISTRY)

  foreach(ENTRY ${REGISTRY})
    string(REPLACE "|" ";" ENTRY_PARTS "${ENTRY}")
    list(GET ENTRY_PARTS 0 ENTRY_NAME)
    if("${ENTRY_NAME}" STREQUAL "${MODULE_NAME}")
      list(GET ENTRY_PARTS 2 DEPS_STRING)
      if(NOT "${DEPS_STRING}" STREQUAL "")
        string(REPLACE "," ";" DEPS_LIST "${DEPS_STRING}")
        set(${OUT_DEPS} "${DEPS_LIST}" PARENT_SCOPE)
      else()
        set(${OUT_DEPS} "" PARENT_SCOPE)
      endif()
      return()
    endif()
  endforeach()

  set(${OUT_DEPS} "" PARENT_SCOPE)
endfunction()

function(swift_get_all_libraries OUT_LIBS)
  get_property(REGISTRY GLOBAL PROPERTY SWIFT_LIBRARIES_REGISTRY)
  set(LIB_NAMES "")

  foreach(ENTRY ${REGISTRY})
    string(REPLACE "|" ";" ENTRY_PARTS "${ENTRY}")
    list(GET ENTRY_PARTS 0 ENTRY_NAME)
    list(APPEND LIB_NAMES "${ENTRY_NAME}")
  endforeach()

  set(${OUT_LIBS} "${LIB_NAMES}" PARENT_SCOPE)
endfunction()

function(swift_resolve_dependencies MODULE_NAME OUT_RESOLVED_DEPS)
  # Recursively resolve dependencies using topological sort
  set(VISITED "")
  set(RESOLVED "")
  set(TEMP_MARK "")

  swift_visit_dependency("${MODULE_NAME}" VISITED RESOLVED TEMP_MARK)

  # Remove the module itself from the resolved dependencies
  list(REMOVE_ITEM RESOLVED "${MODULE_NAME}")
  set(${OUT_RESOLVED_DEPS} "${RESOLVED}" PARENT_SCOPE)
endfunction()

function(swift_visit_dependency MODULE_NAME VISITED RESOLVED TEMP_MARK)
  # Check if already resolved
  list(FIND ${RESOLVED} "${MODULE_NAME}" FOUND_RESOLVED)
  if(NOT FOUND_RESOLVED EQUAL -1)
    return()
  endif()

  # Check for circular dependency
  list(FIND ${TEMP_MARK} "${MODULE_NAME}" FOUND_TEMP)
  if(NOT FOUND_TEMP EQUAL -1)
    message(FATAL_ERROR "Circular dependency detected involving ${MODULE_NAME}")
  endif()

  # Mark as temporarily visited
  list(APPEND ${TEMP_MARK} "${MODULE_NAME}")
  set(${TEMP_MARK} "${${TEMP_MARK}}" PARENT_SCOPE)

  # Get dependencies for this module
  swift_get_library_dependencies("${MODULE_NAME}" DEPS)

  # Visit each dependency
  foreach(DEP ${DEPS})
    swift_visit_dependency("${DEP}" ${VISITED} ${RESOLVED} ${TEMP_MARK})
  endforeach()

  # Remove from temporary mark
  list(REMOVE_ITEM ${TEMP_MARK} "${MODULE_NAME}")
  set(${TEMP_MARK} "${${TEMP_MARK}}" PARENT_SCOPE)

  # Add to resolved
  list(APPEND ${RESOLVED} "${MODULE_NAME}")
  set(${RESOLVED} "${${RESOLVED}}" PARENT_SCOPE)
endfunction()

function(swift_detect_imports_from_sources SOURCES OUT_IMPORTS)
  set(IMPORTS "")

  foreach(SOURCE_FILE ${SOURCES})
    if(EXISTS "${SOURCE_FILE}")
      file(READ "${SOURCE_FILE}" CONTENT)
      # Find import statements
      string(REGEX MATCHALL "import[ \t]+([A-Za-z_][A-Za-z0-9_]*)" IMPORT_MATCHES "${CONTENT}")

      foreach(MATCH ${IMPORT_MATCHES})
        string(REGEX REPLACE "import[ \t]+" "" MODULE_NAME "${MATCH}")
        # Skip system imports like Foundation, etc.
        if(NOT MODULE_NAME MATCHES "^(Foundation|Swift|_Concurrency)$")
          list(APPEND IMPORTS "${MODULE_NAME}")
        endif()
      endforeach()
    endif()
  endforeach()

  # Remove duplicates
  list(REMOVE_DUPLICATES IMPORTS)
  set(${OUT_IMPORTS} "${IMPORTS}" PARENT_SCOPE)
endfunction()

# External Library Integration Functions
function(swift_fetch_github_library REPO_URL MODULE_NAME)
  # Parse arguments for optional parameters
  cmake_parse_arguments(PARSE_ARGV 2 FETCH "" "TAG;BRANCH;SOURCE_DIR" "DEPENDENCIES")

  # Set defaults
  if(NOT FETCH_TAG AND NOT FETCH_BRANCH)
    set(FETCH_TAG "main")
  endif()

  if(NOT FETCH_SOURCE_DIR)
    set(FETCH_SOURCE_DIR "lib")
  endif()

  # Create external libraries directory
  set(EXTERNAL_LIB_DIR "${CMAKE_BINARY_DIR}/external_swift_libs")
  file(MAKE_DIRECTORY "${EXTERNAL_LIB_DIR}")

  # Set the local path for this library
  set(LOCAL_LIB_PATH "${EXTERNAL_LIB_DIR}/${MODULE_NAME}")

  # Check if already downloaded
  if(NOT EXISTS "${LOCAL_LIB_PATH}")
    message(STATUS "Fetching Swift library ${MODULE_NAME} from ${REPO_URL}")

    # Clone the repository
    find_program(GIT_EXECUTABLE git REQUIRED)

    if(FETCH_TAG)
      execute_process(
        COMMAND ${GIT_EXECUTABLE} clone --depth 1 --branch ${FETCH_TAG} ${REPO_URL} ${LOCAL_LIB_PATH}
        RESULT_VARIABLE GIT_RESULT
        OUTPUT_QUIET
        ERROR_QUIET
      )
    elseif(FETCH_BRANCH)
      execute_process(
        COMMAND ${GIT_EXECUTABLE} clone --depth 1 --branch ${FETCH_BRANCH} ${REPO_URL} ${LOCAL_LIB_PATH}
        RESULT_VARIABLE GIT_RESULT
        OUTPUT_QUIET
        ERROR_QUIET
      )
    endif()

    if(NOT GIT_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to fetch Swift library ${MODULE_NAME} from ${REPO_URL}")
    endif()
  else()
    message(STATUS "Swift library ${MODULE_NAME} already exists at ${LOCAL_LIB_PATH}")
  endif()

  # Find Swift sources in the specified directory
  file(GLOB_RECURSE LIB_SOURCES "${LOCAL_LIB_PATH}/${FETCH_SOURCE_DIR}/*.swift")

  if(NOT LIB_SOURCES)
    message(FATAL_ERROR "No Swift sources found in ${LOCAL_LIB_PATH}/${FETCH_SOURCE_DIR}")
  endif()

  # Create the library using our swift_library function
  swift_create_external_library(
    MODULE_NAME ${MODULE_NAME}
    SOURCES ${LIB_SOURCES}
    DEPENDENCIES ${FETCH_DEPENDENCIES}
  )
endfunction()

function(swift_create_external_library)
  # Parse arguments
  cmake_parse_arguments(PARSE_ARGV 0 EXTLIB "" "MODULE_NAME" "SOURCES;DEPENDENCIES")

  # Set up paths
  set(MODULE_OBJ_FILE
      ${CMAKE_BINARY_DIR}/external_swift_libs/${EXTLIB_MODULE_NAME}/${EXTLIB_MODULE_NAME}.o)
  set(MODULE_SWIFT_MODULE_FILE
      ${CMAKE_BINARY_DIR}/external_swift_libs/${EXTLIB_MODULE_NAME}/${EXTLIB_MODULE_NAME}.swiftmodule)
  set(MODULE_PATH ${CMAKE_BINARY_DIR}/external_swift_libs/${EXTLIB_MODULE_NAME})

  # Register this library in the global registry
  swift_register_library(${EXTLIB_MODULE_NAME} ${MODULE_PATH} "${EXTLIB_DEPENDENCIES}")

  # Ensure output directory exists
  file(MAKE_DIRECTORY ${MODULE_PATH})

  # Get the Swift target architecture
  _swift_map_target()

  # Build include paths for dependencies
  set(INCLUDE_PATHS "")
  list(APPEND INCLUDE_PATHS "-I" "${CMAKE_BINARY_DIR}/modules/lang-swift/zephyr")

  # Add paths for declared dependencies
  foreach(DEP ${EXTLIB_DEPENDENCIES})
    swift_get_library_path(${DEP} DEP_PATH)
    if(DEP_PATH)
      list(APPEND INCLUDE_PATHS "-I" "${DEP_PATH}")
    else()
      message(WARNING "Dependency ${DEP} not found for external library ${EXTLIB_MODULE_NAME}")
    endif()
  endforeach()

  # Build dependency targets for compilation order
  set(COMPILE_DEPS ${EXTLIB_SOURCES})

  # Always depend on Zephyr if it exists
  if(TARGET Zephyr_compile)
    list(APPEND COMPILE_DEPS Zephyr_compile)
  endif()

  # Add dependencies on other Swift libraries
  foreach(DEP ${EXTLIB_DEPENDENCIES})
    if(TARGET ${DEP}_compile)
      list(APPEND COMPILE_DEPS ${DEP}_compile)
    endif()
  endforeach()

  # Custom command to compile Swift library
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${MODULE_OBJ_FILE} ${MODULE_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -parse-as-library -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${MODULE_OBJ_FILE}
      -emit-module -emit-module-path ${MODULE_SWIFT_MODULE_FILE}
      -module-name ${EXTLIB_MODULE_NAME}
      ${INCLUDE_PATHS}
      ${EXTLIB_SOURCES}
    DEPENDS ${COMPILE_DEPS}
    COMMENT "Compiling external Swift library ${EXTLIB_MODULE_NAME}")

  # Create a static library for the Swift module
  add_library(${EXTLIB_MODULE_NAME} STATIC ${MODULE_OBJ_FILE})
  set_target_properties(${EXTLIB_MODULE_NAME} PROPERTIES LINKER_LANGUAGE C)

  # Add custom target to ensure compilation happens
  add_custom_target(${EXTLIB_MODULE_NAME}_compile DEPENDS ${MODULE_OBJ_FILE}
                                                   ${MODULE_SWIFT_MODULE_FILE})
  add_dependencies(${EXTLIB_MODULE_NAME} ${EXTLIB_MODULE_NAME}_compile)
endfunction()

# Convenience function to add a Swift package from a URL
function(swift_add_package REPO_URL)
  # Parse arguments
  cmake_parse_arguments(PARSE_ARGV 1 PKG "" "NAME;TAG;BRANCH;SOURCE_DIR" "DEPENDENCIES")

  # Extract module name from URL if not provided
  if(NOT PKG_NAME)
    string(REGEX REPLACE ".*/([^/]+)\\.git$" "\\1" PKG_NAME "${REPO_URL}")
    string(REGEX REPLACE ".*/([^/]+)$" "\\1" PKG_NAME "${PKG_NAME}")
  endif()

  # Forward to fetch function
  swift_fetch_github_library(
    ${REPO_URL}
    ${PKG_NAME}
    ${PKG_UNPARSED_ARGUMENTS}
  )
endfunction()

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
      ${INCLUDE_PATHS}
      ${SWIFTLIB_SOURCES}
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

  # Custom command to compile Swift main application
  find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)
  add_custom_command(
    OUTPUT ${APP_SWIFT_OBJ_FILE} ${APP_SWIFT_MODULE_FILE}
    COMMAND
      ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET} -wmo -Osize
      -enable-experimental-feature Embedded -Xfrontend -function-sections
      -emit-object -o ${APP_SWIFT_OBJ_FILE}
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

# Simple function to add external Swift libraries from GitHub
function(swift_add_external_library REPO_URL MODULE_NAME)
  # This function can be extended later to fetch from GitHub
  # For now, it's a placeholder that could integrate with FetchContent
  message(STATUS "External library support available for ${MODULE_NAME} from ${REPO_URL}")
  message(STATUS "Implementation can be added when needed using FetchContent or git submodules")
endfunction()
