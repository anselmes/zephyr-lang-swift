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
