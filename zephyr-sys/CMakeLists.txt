#[=======================================================================[.rst:
ZephyrSys - Swift Runtime Support Library
==========================================

This library provides the low-level C runtime support required for Swift
code to run on Zephyr RTOS. It bridges the gap between Swift's runtime
expectations and Zephyr's embedded C environment.

Components
----------

**C Runtime Stubs** (``src/``)
  Implementation of C library functions that Swift expects but may not
  be available in Zephyr's minimal C library, such as:

  * ``aligned_alloc`` and ``posix_memalign`` for memory alignment
  * ``getentropy`` for random number generation
  * Other POSIX compatibility functions

**Bridging Headers** (``include/``)
  C header files that expose Zephyr functionality to Swift:

  * ``BridgingHeader.h`` - Main bridging header for Swift imports
  * ``module.modulemap`` - Clang module map for Swift interoperability

**Additional Libraries** (``lib/``)
  Optional C libraries that extend Zephyr functionality for Swift use.

Purpose
-------

Swift's runtime assumes the presence of certain C library functions and
headers that may not exist in Zephyr's minimal embedded environment.
This library provides stub implementations and compatibility shims to
make Swift code work seamlessly with Zephyr RTOS.

The library is built as a static library and linked into all Swift
applications and libraries to provide the necessary runtime support.

#]=======================================================================]

# Create the ZephyrSys static library target
# This library contains C runtime stubs and bridging code needed by Swift
add_library(ZephyrSys STATIC)

# Discover all C source files in the zephyr-sys directory structure
# src/: Core runtime stub implementations (e.g., aligned_alloc, getentropy)
# lib/: Additional C libraries and utilities for Swift interop
file(GLOB_RECURSE C_SOURCES
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
     "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.c")

# Add all discovered C sources to the ZephyrSys library
# These provide the runtime functions that Swift code expects to be available
target_sources(ZephyrSys PRIVATE ${C_SOURCES})

# Make the include directory publicly available
# This contains bridging headers and module maps that Swift imports
# PUBLIC visibility means other targets linking to ZephyrSys get these includes
target_include_directories(ZephyrSys PUBLIC include)

# Link with the core Zephyr kernel and libraries
# PUBLIC linking means that targets depending on ZephyrSys also get Zephyr
# This ensures Swift code has access to all Zephyr RTOS functionality
target_link_libraries(ZephyrSys PUBLIC zephyr)
