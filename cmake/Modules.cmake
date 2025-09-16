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

# Simple function to add external Swift libraries from GitHub
function(swift_add_external_library REPO_URL MODULE_NAME)
  # This function can be extended later to fetch from GitHub
  # For now, it's a placeholder that could integrate with FetchContent
  message(STATUS "External library support available for ${MODULE_NAME} from ${REPO_URL}")
  message(STATUS "Implementation can be added when needed using FetchContent or git submodules")
endfunction()
