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
