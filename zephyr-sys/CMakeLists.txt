# Include Swift toolchain configuration functions This provides
# _swift_map_target() and _enable_swift() functions
include(${CMAKE_CURRENT_SOURCE_DIR}/../toolchain.cmake)

# Discover all Swift source files in the zephyr-sys directory structure
# These contain Swift implementations of C headers and runtime functions using @c @implementation
file(GLOB_RECURSE SWIFT_SOURCES
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift"
     "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.swift")

# Require Swift sources to build the library
if(NOT SWIFT_SOURCES)
  message(FATAL_ERROR "No Swift sources found in ZephyrSys. Swift implementation is required.")
endif()

# Define output file paths for the compiled Swift components
set(SWIFT_OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSys.o")
set(SWIFT_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/ZephyrSys.swiftmodule")

# Determine the Swift target triple based on Zephyr's CPU configuration
_swift_map_target()

# Configure Swift compilation defines based on Zephyr configuration
set(SWIFT_DEFINES "")
if(CONFIG_SWIFT_DEBUG_INFO)
  list(APPEND SWIFT_DEFINES "-DSWIFT_DEBUG_INFO")   # Enable Swift debug information when configured in Zephyr
endif()

# Locate the Swift compiler executable
find_program(SWIFTC_EXECUTABLE swiftc REQUIRED)

# Create custom command to compile Swift sources with C header implementations
add_custom_command(
  OUTPUT ${SWIFT_OBJ_FILE} ${SWIFT_MODULE_FILE}
  COMMAND
    ${SWIFTC_EXECUTABLE} -target ${SWIFT_TARGET}                          # Cross-compilation target
    -parse-as-library                                                     # Compile as library
    -wmo                                                                  # Whole-module optimization
    -Osize                                                                # Optimize for code size
    -enable-experimental-feature Embedded                                 # Enable Embedded Swift features
    -enable-experimental-feature CImplementation                          # Enable @c @implementation feature
    -Xfrontend -function-sections                                         # Separate functions into sections

    -emit-object -o ${SWIFT_OBJ_FILE}                                     # Generate object file
    -emit-module -emit-module-path ${SWIFT_MODULE_FILE}                   # Generate Swift module interface
    -module-name ZephyrSys                                                # Set the Swift module name to "ZephyrSys"
    ${SWIFT_DEFINES}                                                      # Add any Swift compilation defines

    # Include paths for Zephyr headers
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated                       # Generated Zephyr headers
    -I ${CMAKE_BINARY_DIR}/zephyr/include/generated/zephyr                # Generated Zephyr-specific headers
    -I ${CMAKE_BINARY_DIR}/zephyr/include                                 # Built Zephyr headers
    -I ${ZEPHYR_BASE}/include                                             # Source Zephyr headers
    -I ${CMAKE_CURRENT_SOURCE_DIR}/include                                # ZephyrSys bridging headers
    -I ${SYSROOT_DIR}/include                                             # System headers

    # Set system root for C headers
    -Xcc -isysroot=${SYSROOT_DIR}

    # Define that we're in a Zephyr build environment for the C preprocessor
    -Xcc -DZEPHYR_BUILD_ENV

    # Import the bridging header to make C APIs available to Swift
    -import-bridging-header ${CMAKE_CURRENT_SOURCE_DIR}/include/BridgingHeader.h

    # Swift source files to compile
    ${SWIFT_SOURCES}
  DEPENDS ${SWIFT_SOURCES}
  COMMENT "Compiling Swift sources for ZephyrSys")

# Create the ZephyrSys static library target containing Swift implementations
add_library(ZephyrSys STATIC)

# Set the linker language to C to ensure proper linking with Zephyr This is
# necessary because CMake needs to know how to link the final binary
set_target_properties(ZephyrSys PROPERTIES LINKER_LANGUAGE C)

# Create a compilation target to track when Swift compilation is complete
add_custom_target(ZephyrSys_swift_compile DEPENDS ${SWIFT_OBJ_FILE}
                                                   ${SWIFT_MODULE_FILE})

# Ensure Swift compilation happens after Zephyr's syscall headers are generated
add_dependencies(ZephyrSys_swift_compile syscall_list_h_target)

# Add the compiled Swift object file to the library
target_sources(ZephyrSys PRIVATE ${SWIFT_OBJ_FILE})

# Make the ZephyrSys library target depend on successful Swift compilation
add_dependencies(ZephyrSys ZephyrSys_swift_compile)

# Make the include directory publicly available This contains bridging headers
# and module maps that Swift imports PUBLIC visibility means other targets
# linking to ZephyrSys get these includes
target_include_directories(ZephyrSys PUBLIC include)

# Link with the core Zephyr kernel and libraries PUBLIC linking means that
# targets depending on ZephyrSys also get Zephyr This ensures Swift code has
# access to all Zephyr RTOS functionality
target_link_libraries(ZephyrSys PUBLIC zephyr)
