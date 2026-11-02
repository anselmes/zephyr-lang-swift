// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrCore
import ZephyrSystem

/// Allocation-free logging to Zephyr's `swift` log module.
///
/// Messages are string literals (`StaticString`), so logging never copies or
/// allocates. Nothing is logged unless the build sets `CONFIG_LOG=y`, and
/// messages below `CONFIG_LOG_DEFAULT_LEVEL` (info by default) are dropped.
///
/// ```swift
/// import Zephyr
///
/// Log.info("Sensor ready")
/// Log.error("Sensor read failed")
/// ```
public enum Log {
  /// Logs `message` at error level (`LOG_ERR`).
  ///
  /// - Parameter message: The text to log.
  public static func error(_ message: StaticString) {
    Kernel.log(level: UInt32(LOG_LEVEL_ERR), message)
  }

  /// Logs `message` at warning level (`LOG_WRN`).
  ///
  /// - Parameter message: The text to log.
  public static func warning(_ message: StaticString) {
    Kernel.log(level: UInt32(LOG_LEVEL_WRN), message)
  }

  /// Logs `message` at info level (`LOG_INF`).
  ///
  /// - Parameter message: The text to log.
  public static func info(_ message: StaticString) {
    Kernel.log(level: UInt32(LOG_LEVEL_INF), message)
  }

  /// Logs `message` at debug level (`LOG_DBG`).
  ///
  /// - Parameter message: The text to log.
  public static func debug(_ message: StaticString) {
    Kernel.log(level: UInt32(LOG_LEVEL_DBG), message)
  }
}
