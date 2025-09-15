// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr

public struct Hello {
  public static func run(timeout: Int = 1000) {
    hello(timeout: timeout)
  }
}

/// This function prints an initial greeting message and then
/// enters an infinite loop that keeps the application running
/// continuously, which is a common pattern in embedded systems applications.
public func hello(timeout: Int = 1000) {
  // Display initial greeting message
  print("Hello from Swift!!!")

  // Sleep duration in milliseconds
  let duration = Duration.milliseconds(timeout)

  // Enter infinite loop to keep the application running
  // This pattern is common in embedded systems where the application
  // should continue running until power is removed
  while true {
    // Pause execution for the duration specified by the timeout parameter (in milliseconds)
    sleep(duration)

    // Print a status message to indicate the application is still alive
    print("still running...")
  }
}
