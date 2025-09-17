// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

/**
 * @file Hello.swift
 * @brief Hello Swift Library Module for Zephyr RTOS
 *
 * This Swift library module demonstrates how to create reusable Swift libraries
 * for Zephyr RTOS applications. It provides a simple "Hello World" functionality
 * that showcases Swift language features, integration with Zephyr APIs, and
 * proper module structure for embedded development.
 *
 * ## Module Purpose
 *
 * The Hello module serves as:
 * - A template for creating Swift libraries in Zephyr
 * - A demonstration of Swift-Zephyr API integration
 * - An example of proper public API design for Swift modules
 * - A showcase of embedded Swift programming patterns
 *
 * ## Key Features Demonstrated
 *
 * - **Public API Design**: Clean, Swift-idiomatic public interfaces
 * - **Configuration Integration**: Conditional compilation based on debug settings
 * - **Zephyr Integration**: Use of Zephyr timing and I/O functions
 * - **Type Safety**: Swift's type system applied to embedded programming
 * - **Module Organization**: Proper Swift module structure and exports
 *
 * ## Usage Example
 *
 * ```swift
 * import Hello
 *
 * // Use the structured API
 * Hello.run(timeout: 500)
 *
 * // Or use the function directly
 * hello(timeout: 2000)
 * ```
 *
 * @see Zephyr For core Zephyr Swift bindings
 */

import Zephyr

/**
 * @brief Hello Module Public Interface
 *
 * This structure provides the main public API for the Hello module,
 * encapsulating functionality in a namespace-style Swift pattern.
 * This demonstrates how to organize Swift library code for embedded
 * systems while maintaining clean, discoverable APIs.
 */
public struct Hello {
  /**
   * @brief Run the Hello module demonstration
   *
   * This static method provides the primary entry point for the Hello module
   * functionality. It demonstrates conditional compilation, debug information
   * handling, and delegation to implementation functions.
   *
   * @param timeout The delay timeout in milliseconds between iterations
   *                (default: 1000ms for a 1-second delay)
   *
   * Features demonstrated:
   * - Default parameter values for API convenience
   * - Conditional compilation for debug information
   * - Clean separation between public API and implementation
   * - Swift naming conventions for embedded development
   */
  public static func run(timeout: Int = 1000) {
    // Conditional compilation example: include debug output only when
    // CONFIG_SWIFT_DEBUG_INFO is enabled in the Zephyr configuration
    #if SWIFT_DEBUG_INFO
      print("debug: Module Hello compiled with debug info")
    #endif

    // Delegate to the main implementation function
    hello(timeout: timeout)
  }
}

/**
 * @brief Hello Module Implementation Function
 *
 * This function provides the core implementation of the Hello module
 * functionality. It demonstrates basic Swift programming patterns
 * suitable for embedded systems, including proper use of Zephyr's
 * timing APIs and infinite loop patterns common in embedded applications.
 *
 * @param timeout The delay timeout in milliseconds between loop iterations
 *                Default value provides a reasonable 1-second delay
 *
 * Implementation highlights:
 * - Use of Swift's Duration type for type-safe time handling
 * - Integration with Zephyr's sleep functionality through Swift bindings
 * - Infinite loop pattern typical of embedded applications
 * - Proper resource management without dynamic allocation
 * - Simple I/O through print statements for demonstration
 *
 * @note This function runs an infinite loop and will not return.
 *       This is typical behavior for embedded demonstration code.
 */
public func hello(timeout: Int = 1000) {
  // Initial greeting message to demonstrate basic I/O
  print("Hello from Swift!!!")

  // Create a Duration object using Swift's type-safe time representation
  // This demonstrates proper integration with Swift's standard library types
  let duration = Duration.milliseconds(timeout)

  // Main application loop - typical pattern for embedded applications
  // This loop demonstrates:
  // - Infinite execution model common in embedded systems
  // - Integration with Zephyr's sleep/timing functions
  // - Periodic output for system monitoring and debugging
  while true {
    // Use Zephyr's sleep function through Swift bindings
    // This allows the system to enter low-power states between iterations
    sleep(duration)

    // Periodic status message for monitoring and debugging
    print("still running...")
  }
}
