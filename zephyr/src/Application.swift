// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

/**
 @file Application.swift
 @brief Main Application Entry Point for Zephyr Swift Applications

 This file provides the main entry point for Swift applications running on
 Zephyr RTOS. It demonstrates Swift 6.3's @c attribute for creating C-compatible
 main functions that can be called by the Zephyr kernel.

 ## Swift 6.3 Features

 - **@c attribute**: Creates C-compatible function symbols
 - **Embedded Swift**: Optimized for resource-constrained environments
 - **Conditional compilation**: Debug features controlled by build flags
 - **C interoperability**: Seamless integration with Zephyr C APIs

 ## Integration with Zephyr

 This main function serves as the entry point for Swift applications in the
 Zephyr RTOS environment. The @c(main) attribute ensures the function is
 callable from C code with the standard main() signature.

 ## Application Flow

 1. Zephyr kernel initializes and calls main()
 2. Swift runtime initialization (if needed)
 3. Debug information output (if enabled)
 4. Application-specific entry point execution

 @see entrypoint() User-defined application logic
 */

/**
 @brief Main entry point for Zephyr Swift applications

 This function serves as the primary entry point for Swift applications
 running on Zephyr RTOS. The @c(main) attribute makes this function
 callable from C code as a standard main() function.

 ## C Compatibility

 The @c attribute ensures:
 - C-compatible symbol generation (no Swift name mangling)
 - Standard C calling conventions
 - Proper integration with Zephyr's application lifecycle

 ## Debug Features

 When SWIFT_DEBUG_INFO is defined during compilation:
 - Outputs debug information to console
 - Enables additional runtime diagnostics
 - Useful for development and troubleshooting

 ## Application Entry

 After initialization, this function calls entrypoint() which should
 contain the main application logic. This separation allows for:
 - Clean separation of concerns
 - Reusable application patterns
 - Consistent initialization across applications

 @note The entrypoint() function must be implemented by the application
 */
@c(main)
public func main() {
  // Enable debug output when configured during build
  #if SWIFT_DEBUG_INFO
  print("Zephyr Swift Application - Debug info enabled")
  print("Swift 6.3 Embedded Mode Active")
  #endif

  // Call the application-specific entry point
  // This function should be implemented by the user application
  entrypoint()
}
