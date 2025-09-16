#[=======================================================================[.rst:
Swift Toolchain for Zephyr RTOS
--------------------------------

This module provides CMake functions and utilities to enable Swift language
support in Zephyr RTOS projects. It handles Swift compiler configuration,
target architecture mapping, and integration with the Zephyr build system.

Functions
^^^^^^^^^

.. cmake:command:: _enable_swift

  Configures CMake to use Swift with settings optimized for embedded systems.

  This function sets up the Swift compiler with whole-module optimization
  and appropriate target configuration for Zephyr RTOS projects.

  **Internal use only** - Called automatically by other Swift functions.

.. cmake:command:: _swift_map_target

  Maps Zephyr's CPU configuration to appropriate Swift target triples.

  This function analyzes Zephyr's CPU configuration variables and sets
  the SWIFT_TARGET variable in the parent scope to the correct Swift
  target triple for cross-compilation.

  Supported architectures:
  - ARM Cortex-M (M0, M0+, M1, M3, M4, M7, M23, M33, M35P, M55)
  - ARM64 (AArch64)
  - RISC-V (32-bit and 64-bit)

  **Internal use only** - Called automatically by Swift compilation functions.

#]=======================================================================]

# .rst: .. cmake:command:: _enable_swift
#
# Enables Swift language support in CMake with embedded-specific settings.
#
# This internal function configures the Swift compiler for use in Zephyr
# embedded systems, setting up whole-module optimization and target
# configuration.
#
function(_enable_swift)
  # Enable Swift as a supported language in this CMake project
  enable_language(Swift)

  # Set the target triple for the Swift compiler to match Zephyr's build target
  # This ensures Swift generates code for the correct embedded architecture
  set(CMAKE_Swift_COMPILER_TARGET ${BUILD_TARGET})

  # Enable whole-module optimization (WMO) which is required for Embedded Swift
  # WMO allows better optimization and smaller code size for embedded systems
  set(CMAKE_Swift_COMPILATION_MODE wholemodule)

  # Explicitly indicate that the Swift compiler is functional and ready to use
  # This prevents CMake from running additional compiler tests
  set(CMAKE_Swift_COMPILER_WORKS true)
endfunction()

# .rst: .. cmake:command:: _swift_map_target
#
# Maps Zephyr CPU configuration to Swift target triples.
#
# This internal function analyzes Zephyr's CPU configuration variables and
# determines the appropriate Swift target triple for cross-compilation. The
# target triple is set in the SWIFT_TARGET variable in the parent scope.
#
# **Supported Architectures:**
#
# * **ARM Cortex-M Series:** - Cortex-M0/M0+/M1: thumbv6m-none-eabi - Cortex-M3:
#   thumbv7m-none-eabi - Cortex-M4/M7: thumbv7em-none-eabi[hf] (hf = hardware
#   floating point) - Cortex-M23/M33/M35P/M55: thumbv8m.main-none-eabi[hf]
#
# * **ARM 64-bit:** aarch64-none-elf
#
# * **RISC-V:** riscv32/riscv64-none-none-eabi
#
# The function automatically detects floating-point ABI configuration and
# selects the appropriate hard-float variant when available.
#
function(_swift_map_target)
  # ARM Cortex-M family processors
  if(CONFIG_CPU_CORTEX_M)

    # Cortex-M0, M0+, M1 - ARMv6-M architecture These are the most basic
    # Cortex-M cores with Thumb instruction set only
    if(CONFIG_CPU_CORTEX_M0
       OR CONFIG_CPU_CORTEX_M0PLUS
       OR CONFIG_CPU_CORTEX_M1)
      set(SWIFT_TARGET
          "thumbv6m-none-eabi"
          PARENT_SCOPE)

      # Cortex-M3 - ARMv7-M architecture Adds more advanced Thumb-2 instructions
      # but no floating-point unit
    elseif(CONFIG_CPU_CORTEX_M3)
      set(SWIFT_TARGET
          "thumbv7m-none-eabi"
          PARENT_SCOPE)

      # Cortex-M4, M7 - ARMv7E-M architecture with optional FPU These cores
      # support DSP instructions and optional floating-point
    elseif(CONFIG_CPU_CORTEX_M4 OR CONFIG_CPU_CORTEX_M7)
      if(CONFIG_FP_HARDABI)
        # Use hardware floating-point ABI when FPU is available and configured
        set(SWIFT_TARGET
            "thumbv7em-none-eabihf"
            PARENT_SCOPE)
      else()
        # Use software floating-point ABI when FPU is disabled or unavailable
        set(SWIFT_TARGET
            "thumbv7em-none-eabi"
            PARENT_SCOPE)
      endif()

      # Cortex-M23, M33, M35P, M55 - ARMv8-M architecture Latest generation with
      # TrustZone security extensions and optional FPU
    elseif(
      CONFIG_CPU_CORTEX_M23
      OR CONFIG_CPU_CORTEX_M33
      OR CONFIG_CPU_CORTEX_M35P
      OR CONFIG_CPU_CORTEX_M55)
      if(CONFIG_FP_HARDABI)
        # Use hardware floating-point ABI for ARMv8-M with FPU
        set(SWIFT_TARGET
            "thumbv8m.main-none-eabihf"
            PARENT_SCOPE)
      else()
        # Use software floating-point ABI for ARMv8-M without FPU
        set(SWIFT_TARGET
            "thumbv8m.main-none-eabi"
            PARENT_SCOPE)
      endif()

    else()
      # Unsupported Cortex-M variant - this should not happen with current
      # Zephyr
      message(FATAL_ERROR "Swift: Unsupported ARM Cortex-M variant detected")
    endif()

    # ARM 64-bit (AArch64) processors
  elseif(CONFIG_ARM64)
    # Standard AArch64 target for 64-bit ARM processors
    set(SWIFT_TARGET
        "aarch64-none-elf"
        PARENT_SCOPE)

    # RISC-V processors (both 32-bit and 64-bit variants)
  elseif(CONFIG_RISCV)
    if(CONFIG_64BIT)
      # 64-bit RISC-V target
      set(SWIFT_TARGET
          "riscv64-none-none-eabi"
          PARENT_SCOPE)
    else()
      # 32-bit RISC-V target
      set(SWIFT_TARGET
          "riscv32-none-none-eabi"
          PARENT_SCOPE)
    endif()

  else()
    # Architecture not yet supported - extend this function for new
    # architectures
    message(
      FATAL_ERROR
        "Swift: Architecture not supported. Please add support for this target architecture."
    )
  endif()
endfunction()
