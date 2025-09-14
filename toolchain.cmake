function(_swift_map_target)
  if(CONFIG_CPU_CORTEX_M)
    if(CONFIG_CPU_CORTEX_M0
       OR CONFIG_CPU_CORTEX_M0PLUS
       OR CONFIG_CPU_CORTEX_M1)
      set(SWIFT_TARGET
          "thumbv6m-none-eabi"
          PARENT_SCOPE)
    elseif(CONFIG_CPU_CORTEX_M3)
      set(SWIFT_TARGET
          "thumbv7m-none-eabi"
          PARENT_SCOPE)
    elseif(CONFIG_CPU_CORTEX_M4 OR CONFIG_CPU_CORTEX_M7)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET
            "thumbv7em-none-eabihf"
            PARENT_SCOPE)
      else()
        set(SWIFT_TARGET
            "thumbv7em-none-eabi"
            PARENT_SCOPE)
      endif()
    elseif(
      CONFIG_CPU_CORTEX_M23
      OR CONFIG_CPU_CORTEX_M33
      OR CONFIG_CPU_CORTEX_M35P
      OR CONFIG_CPU_CORTEX_M55)
      if(CONFIG_FP_HARDABI)
        set(SWIFT_TARGET
            "thumbv8m.main-none-eabihf"
            PARENT_SCOPE)
      else()
        set(SWIFT_TARGET
            "thumbv8m.main-none-eabi"
            PARENT_SCOPE)
      endif()
    else()
      message(FATAL_ERROR "Swift: Unsupported ARM Cortex-M variant")
    endif()
  elseif(CONFIG_ARM64)
    set(SWIFT_TARGET
        "aarch64-none-elf"
        PARENT_SCOPE)
  elseif(CONFIG_RISCV)
    if(CONFIG_64BIT)
      set(SWIFT_TARGET
          "riscv64-none-none-eabi"
          PARENT_SCOPE)
    else()
      set(SWIFT_TARGET
          "riscv32-none-none-eabi"
          PARENT_SCOPE)
    endif()
  else()
    message(FATAL_ERROR "Swift: Add support for other target architectures")
  endif()
endfunction()
