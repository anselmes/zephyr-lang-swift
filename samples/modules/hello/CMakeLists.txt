# ==============================================================================
# PROJECT CMAKE CONFIGURATION
# ==============================================================================
# This CMake build file configures a Zephyr RTOS embedded project with Swift
# language support. It handles the integration between Swift compiler settings
# and Zephyr's build system for embedded development.
# ==============================================================================

if(CONFIG_HELLO)

project(Hello)
enable_language(Swift)
swift_library()

endif()
