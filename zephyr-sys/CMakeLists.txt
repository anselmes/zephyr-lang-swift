# Define the zephyr-sys library
add_library(ZephyrSys STATIC)

# Find all C source files (stubs, etc.)
file(GLOB_RECURSE C_SOURCES
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
     "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.c")

# Add C sources if any
target_sources(ZephyrSys PRIVATE ${C_SOURCES})
target_include_directories(ZephyrSys PUBLIC include)

# Link with Zephyr if available
target_link_libraries(ZephyrSys PUBLIC zephyr)
