// SPDX-Licence-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr

/// The main entry point for the Zephyr Swift application.
///
/// This struct serves as the application's entry point and contains
/// the main execution loop for the program.
@main
public struct Entrypoint {
  /// The primary entry function for the application.
  ///
  /// This function is automatically called when the program starts.
  /// It prints an initial greeting message and then enters an infinite
  /// loop that keeps the application running continuously, which is a
  /// common pattern in embedded systems applications.
  public static func main() {
    // Display initial greeting message
    print("Hello from Swift!!!")

    // Enter infinite loop to keep the application running
    // This pattern is common in embedded systems where the application
    // should continue running until power is removed
    while true {
      // Pause execution for 1 second
      sleep(Duration.from(milliseconds: 1000))

      // Print a status message to indicate the application is still alive
      print("still running...")
    }
  }
}
