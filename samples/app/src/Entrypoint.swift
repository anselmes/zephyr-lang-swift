// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr

// Timeout interval in milliseconds
let TIMEOUT_INTERVAL: Double = 1000

// Sleep duration in milliseconds
let SLEEP_DURATION = Duration.milliseconds(TIMEOUT_INTERVAL)

/// The main entry point for the Zephyr Swift application.
///
/// This struct serves as the application's entry point and contains
/// the main execution loop for the program.
public func entrypoint() {
  // Display initial greeting message
  print("Hello from Swift!!!")

  // Enter infinite loop to keep the application running
  // This pattern is common in embedded systems where the application
  // should continue running until power is removed
  while true {
    // Pause execution for 1 second
    sleep(SLEEP_DURATION)

    // Print a status message to indicate the application is still alive
    print("still running...")
  }
}
