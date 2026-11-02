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
  /// With `CONFIG_SWIFT_DEBUG_INFO=y`, it first logs an info line, which shows
  /// with `CONFIG_LOG=y` at the default log level (info). A lower
  /// `CONFIG_LOG_DEFAULT_LEVEL` hides it.
  ///
  /// - Parameter timeout: Milliseconds between `still running...` messages.
  public static func run(timeout: Int = 1000) {
    // Logged only when CONFIG_SWIFT_DEBUG_INFO is enabled.
    #if SWIFT_DEBUG_INFO
      Log.info("Module Hello compiled with debug info")
    #endif

    hello(timeout: timeout)
  }
}

/// Prints a greeting, then logs `still running...` every `timeout`
/// milliseconds. Never returns.
///
/// The greeting is always printed. The `still running...` lines are log
/// messages at info level, so they appear only when the build sets
/// `CONFIG_LOG=y` and the log level is at least info, which is the default
/// (`CONFIG_LOG_DEFAULT_LEVEL`).
///
/// - Parameter timeout: Milliseconds between `still running...` messages.
public func hello(timeout: Int = 1000) {
  // The greeting is printed, not logged, so it shows even when logging is off.
  print("Hello from Swift!!!")

  let duration: Duration = .milliseconds(timeout)
  while true {
    sleep(duration)
    Log.info("still running...")
  }
}
