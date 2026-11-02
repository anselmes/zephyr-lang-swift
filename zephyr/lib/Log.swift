// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrCore
import ZephyrSystem

/// Logging to Zephyr's `swift` log module, without heap allocation.
///
/// Messages are string literals (`StaticString`), so Swift never allocates or
/// copies the text, and the logger keeps a pointer to it. Logging is not free
/// of buffering: with `CONFIG_LOG_MODE_DEFERRED` the logger records each
/// message in its own log buffer (`CONFIG_LOG_BUFFER_SIZE`) and prints it later
/// from its thread, and messages are dropped when that buffer is full. Nothing
/// is logged unless the build sets `CONFIG_LOG=y`, and messages more verbose
/// than `CONFIG_LOG_DEFAULT_LEVEL` (info by default) are dropped.
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
