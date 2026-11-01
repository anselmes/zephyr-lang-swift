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

  /// `K_TICKS(ticks)`.
  public static func ticks(_ ticks: k_ticks_t) -> k_timeout_t {
    k_timeout_t(ticks: ticks)
  }

  /// `K_TIMEOUT_ABS_TICKS(ticks)`: an absolute deadline in kernel ticks since
  /// boot. Negative values clamp to boot time.
  public static func absolute(ticks: k_ticks_t) -> k_timeout_t {
    k_timeout_t(ticks: -1 - max(ticks, 0))
  }

  /// Converts a `Duration` using integer math only (no floating point).
  /// Rounds up to whole ticks, so a non-zero duration never becomes
  /// `K_NO_WAIT`. Zero and negative durations become `K_NO_WAIT`; durations
  /// too long for `k_ticks_t` clamp to the longest finite timeout.
  public init(_ duration: Duration) {
    let (seconds, attoseconds) = duration.components
    guard seconds >= 0, attoseconds >= 0, seconds > 0 || attoseconds > 0 else {
      self = .noWait
      return
    }
    let ticksPerSecond = Int64(CONFIG_SYS_CLOCK_TICKS_PER_SEC)
    // Nanoseconds are at most 1e9 here, so `nanoseconds * ticksPerSecond`
    // cannot overflow for any tick rate Zephyr supports.
    let nanoseconds = (attoseconds + 999_999_999) / 1_000_000_000
    let fractional = (nanoseconds * ticksPerSecond + 999_999_999) / 1_000_000_000
    let (whole, overflow) = seconds.multipliedReportingOverflow(by: ticksPerSecond)
    let longest = Int64.max - 1
    let total = overflow ? longest : (whole > longest - fractional ? longest : whole + fractional)
    self = k_timeout_t(ticks: total)
  }
}
