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
