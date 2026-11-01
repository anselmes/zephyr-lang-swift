// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

/// Swift spellings of Zephyr's timeout macros (`K_NO_WAIT`, `K_FOREVER`,
/// `K_MSEC`). They are compound-literal and function-like macros
/// (include/zephyr/sys/clock.h, include/zephyr/sys/time_units.h), which
/// Swift cannot import.
///
/// Assumes `CONFIG_TIMEOUT_64BIT=y` (Zephyr's default), where `k_ticks_t`
/// is `int64_t` and `K_TICKS_FOREVER` is `-1`.
///
/// ```swift
/// _ = k_thread_join(tid, .milliseconds(500))
/// ```
extension k_timeout_t {
  /// `K_NO_WAIT`.
  public static var noWait: k_timeout_t { k_timeout_t(ticks: 0) }

  /// `K_FOREVER`.
  public static var forever: k_timeout_t { k_timeout_t(ticks: -1) }

  /// `K_MSEC(ms)`: rounds up to whole ticks, like `k_ms_to_ticks_ceil64`.
  /// Negative values become `K_NO_WAIT`.
  public static func milliseconds(_ milliseconds: Int32) -> k_timeout_t {
    guard milliseconds > 0 else { return .noWait }
    let ticksPerSecond = Int64(CONFIG_SYS_CLOCK_TICKS_PER_SEC)
    let ticks = (Int64(milliseconds) * ticksPerSecond + 999) / 1_000
    return k_timeout_t(ticks: ticks)
  }
}
