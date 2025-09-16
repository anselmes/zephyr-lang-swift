#[=======================================================================[.rst:
Hello Swift Module - CMake Build Configuration
===============================================

This CMake build file configures the Hello Swift library module for Zephyr RTOS.
It demonstrates how to create conditional Swift library modules that can be
enabled/disabled through Zephyr's Kconfig system and imported by Swift applications.

Overview
--------

The Hello module serves as a template and example for creating Swift library
modules in Zephyr RTOS projects. It shows:

* **Conditional Compilation**: Module builds only when CONFIG_HELLO is enabled
* **Swift Library Creation**: Use of swift_library() function for module compilation
* **Module Organization**: Proper structure for reusable Swift libraries
* **Kconfig Integration**: Integration with Zephyr's configuration system

Module Purpose
--------------

**Template Functionality**
  Provides a working example of Swift module structure that developers
  can copy and adapt for their own Swift libraries.

**Integration Example**
  Demonstrates how Swift modules integrate with Zephyr's build system,
  configuration system, and module discovery mechanisms.

**Best Practices**
  Shows recommended patterns for Swift module development including
  conditional compilation, proper naming, and build configuration.

Build Behavior
--------------

**Conditional Building**
  The module only builds when ``CONFIG_HELLO=y`` is set in the project
  configuration (prj.conf). This demonstrates resource-efficient building
  where unused modules don't consume build time or binary space.

**Library Generation**
  When enabled, creates a static library containing compiled Swift code
  that can be linked into applications and imported in Swift source files.

**Module Interface**
  Generates Swift module interface files (.swiftmodule) that allow other
  Swift code to import and use this module's public APIs.

Usage Pattern
-------------

This CMakeLists.txt serves as a template for Swift library modules:

1. Add conditional compilation check for the module's Kconfig option
2. Use swift_library(MODULE_NAME <module_name>) to compile Swift sources into a static library
3. Close the conditional compilation block

Integration Requirements
------------------------

For this module to be usable by applications:

* Module directory must be added to ZEPHYR_EXTRA_MODULES
* CONFIG_HELLO must be enabled in the application's configuration
* Swift source files must be present in the lib/ directory
* Module must be properly defined in zephyr/module.yml

#]=======================================================================]

# ==============================================================================
# Hello Swift Module - CMake Build Configuration
# ==============================================================================
# This CMake build file configures the Hello Swift library module, demonstrating
# conditional module compilation and Swift library creation for Zephyr RTOS.
# ==============================================================================

# ==== Conditional Module Compilation ====
# Only build this Swift module when it's explicitly enabled through Kconfig This
# demonstrates resource-efficient building where unused modules are skipped

# Check if the Hello module is enabled in the project configuration CONFIG_HELLO
# is defined in this module's Kconfig file and can be enabled in the
# application's prj.conf with: CONFIG_HELLO=y
if(CONFIG_HELLO)

  # ==== Swift Library Module Definition ====
  # Define the Swift library module project and compile it into a static library

  # ==== Swift Library Compilation ====
  # Compile Swift source files into a static library module This function
  # handles: - Discovery of Swift source files in lib/ directory -
  # Cross-compilation for the target embedded architecture - Generation of Swift
  # module interface (.swiftmodule) files - Creation of static library target
  # for linking with applications - Integration with Zephyr's dependency and
  # build systems
  swift_library(MODULE_NAME Hello)

  # End conditional compilation block If CONFIG_HELLO is not enabled, this
  # entire module is skipped during build
endif()
