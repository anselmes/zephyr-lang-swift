if(CONFIG_SWIFT)
  set(SWIFT_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")

  add_subdirectory(zephyr-sys)
  add_subdirectory(zephyr)

  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/SwiftSupport.cmake)
endif()
