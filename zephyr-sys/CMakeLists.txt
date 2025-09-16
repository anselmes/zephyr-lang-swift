add_library(ZephyrSys STATIC)

file(GLOB_RECURSE C_SOURCES
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
     "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.c")

target_sources(ZephyrSys PRIVATE ${C_SOURCES})
target_include_directories(ZephyrSys PUBLIC include)

target_link_libraries(ZephyrSys PUBLIC zephyr)
