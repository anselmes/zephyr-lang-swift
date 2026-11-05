// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// A Zephyr log severity (`LOG_LEVEL_ERR` to `LOG_LEVEL_DBG`).
///
/// ```swift
/// Kernel.log(.info, "Sensor ready")
/// ```
public enum LogLevel: Sendable {
  /// `LOG_LEVEL_ERR`.
  case error
  /// `LOG_LEVEL_WRN`.
  case warning
  /// `LOG_LEVEL_INF`.
  case info
  /// `LOG_LEVEL_DBG`.
  case debug
}

// MARK: - Public API

public extension LogLevel {
  /// The `LOG_LEVEL_*` value Zephyr's logger expects.
  var zephyrLevel: UInt32 {
    switch self {
    case .error: UInt32(LOG_LEVEL_ERR)
    case .warning: UInt32(LOG_LEVEL_WRN)
    case .info: UInt32(LOG_LEVEL_INF)
    case .debug: UInt32(LOG_LEVEL_DBG)
    }
  }
}
