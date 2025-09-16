// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

/**
 * @file Entrypoint.swift
 * @brief Swift Application Entry Point for Zephyr RTOS
 *
 * This file demonstrates how to create a basic Swift application that runs
 * on Zephyr RTOS. It shows the fundamental patterns and structures needed
 * for Swift application development in embedded systems.
 *
 * ## Application Structure
 *
 * The application follows the standard Zephyr-Swift integration pattern:
 * - Configuration constants for application behavior
 * - Public entrypoint function that serves as the Swift main function
 * - Integration with Zephyr's timing and I/O systems
 * - Infinite loop pattern typical of embedded applications
 *
 * ## Key Concepts Demonstrated
 *
 * - **Entry Point Definition**: How to define the application entry point for Swift-Zephyr integration
 * - **Constant Declaration**: Proper declaration and use of application constants
 * - **Zephyr Integration**: Direct use of Zephyr APIs through Swift bindings
 * - **Type Safety**: Use of Swift's type system (Duration) for embedded programming
 * - **Application Lifecycle**: Typical embedded application infinite loop pattern
 *
 * ## Integration with Zephyr
 *
 * This application integrates with Zephyr through:
 * - The Application.swift bootstrap that calls this entrypoint function
 * - Direct use of Zephyr's sleep and I/O functions through Swift bindings
 * - Proper resource management suitable for embedded constraints
 *
 * ## Usage Pattern
 *
 * This serves as a template for Swift applications on Zephyr:
 * 1. Import necessary Zephyr functionality
 * 2. Define application constants and configuration
 * 3. Implement the public entrypoint() function
 * 4. Use appropriate embedded programming patterns
 *
 * @see Application.swift For the C-callable bootstrap that invokes this function
 * @see Zephyr For available Zephyr API bindings
 */

import Zephyr

// Application configuration constants
// These constants define the timing behavior of the application and demonstrate
// proper Swift coding practices for embedded systems

/**
 * @brief Timeout interval in milliseconds
 *
 * This constant defines the delay between application loop iterations.
 * Using a constant makes the timing configurable and clearly documents
 * the application's timing behavior.
 *
 * Value: 1000ms (1 second) - provides a reasonable demonstration pace
 */
let TIMEOUT_INTERVAL: Double = 1000

/**
 * @brief Pre-computed sleep duration
 *
 * This constant demonstrates Swift's type-safe approach to time handling
 * by using the Duration type. Pre-computing the duration avoids repeated
 * calculations in the main loop, which is important for embedded performance.
 *
 * The Duration type provides type safety and clear semantics for time values,
 * reducing errors common in embedded programming with raw time values.
 */
let SLEEP_DURATION = Duration.milliseconds(TIMEOUT_INTERVAL)

/**
 * @brief Swift Application Entry Point
 *
 * This function serves as the main entry point for the Swift application
 * running on Zephyr RTOS. It is called by the Application.swift bootstrap
 * code and represents the start of Swift application execution.
 *
 * ## Function Purpose
 *
 * The entrypoint function demonstrates:
 * - Basic Swift application structure for embedded systems
 * - Integration with Zephyr's I/O and timing systems
 * - Proper infinite loop patterns for embedded applications
 * - Use of pre-computed constants for performance
 *
 * ## Application Behavior
 *
 * The application follows a simple pattern:
 * 1. Print an initial greeting message
 * 2. Enter an infinite loop (typical for embedded applications)
 * 3. Sleep for the configured interval using Zephyr's sleep function
 * 4. Print a status message to show the application is running
 * 5. Repeat the loop indefinitely
 *
 * ## Embedded Programming Patterns
 *
 * This function demonstrates several important embedded programming concepts:
 * - **Infinite execution**: Most embedded applications run continuously
 * - **Periodic operation**: Regular timing intervals for predictable behavior
 * - **Low-power integration**: Using sleep allows the system to enter low-power states
 * - **Status monitoring**: Periodic output helps with debugging and monitoring
 * - **Resource efficiency**: Minimal memory allocation and simple control flow
 *
 * @note This function never returns, which is typical for embedded main functions.
 *       The infinite loop ensures the application continues running until
 *       the system is powered down or reset.
 */
public func entrypoint() {
  // Initial greeting message - demonstrates basic I/O capability
  // This provides immediate feedback that the Swift application has started
  print("Hello from Swift!!!")

  // Main application loop - typical embedded application pattern
  // This infinite loop represents the core application lifecycle:
  // - Perform periodic tasks
  // - Sleep to allow system power management
  // - Provide status feedback for monitoring
  while true {
    // Sleep for the configured duration using Zephyr's sleep function
    // This demonstrates:
    // - Integration with Zephyr's timing APIs through Swift bindings
    // - Proper use of pre-computed Duration values
    // - Power-efficient operation by yielding CPU time
    sleep(SLEEP_DURATION)

    // Periodic status message for system monitoring and debugging
    // This helps developers verify the application is running correctly
    // and provides a simple form of "heartbeat" monitoring
    print("still running...")
  }
}
