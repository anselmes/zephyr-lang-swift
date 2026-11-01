// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr

/// Namespace of the Hello sample library.
///
/// ```swift
/// import Hello
///
/// Hello.run(timeout: 500)
/// ```
public struct Hello {
  /// Runs the Hello demonstration; see `hello(timeout:)`. Never returns.
  ///
  /// - Parameter timeout: Milliseconds between messages.
  public static func run(timeout: Int = 1000) {
    // Printed only when CONFIG_SWIFT_DEBUG_INFO is enabled.
    #if SWIFT_DEBUG_INFO
      print("debug: Module Hello compiled with debug info")
    #endif

    hello(timeout: timeout)
  }
}

/// Prints a greeting, then `still running...` every `timeout` milliseconds.
/// Never returns.
///
/// - Parameter timeout: Milliseconds between messages.
public func hello(timeout: Int = 1000) {
  print("Hello from Swift!!!")

  let duration: Duration = .milliseconds(timeout)
  while true {
    sleep(duration)
    print("still running...")
  }
}
