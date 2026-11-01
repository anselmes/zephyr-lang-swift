// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

/// Swift spellings of Zephyr's timeout macros (`K_NO_WAIT`, `K_FOREVER`,
/// `K_MSEC`). They are compound-literal and function-like macros
/// (include/zephyr/sys/clock.h, include/zephyr/sys/time_units.h), which
/// Swift cannot import.
///
/// `k_ticks_t` is `int64_t` with `CONFIG_TIMEOUT_64BIT=y` (Zephyr's default) and
/// `uint32_t` otherwise. `K_TICKS_FOREVER` is `(k_ticks_t)-1`, so it is `-1` in
/// the first case and `UInt32.max` in the second; finite conversions here clamp
/// below it. Absolute deadlines exist only in 64-bit builds.
///
/// ```swift
/// _ = k_thread_join(tid, .milliseconds(500))
/// ```
extension k_timeout_t {
  /// `K_NO_WAIT`.
  public static var noWait: k_timeout_t { k_timeout_t(ticks: 0) }

  /// `K_FOREVER`.
  public static var forever: k_timeout_t { k_timeout_t(ticks: k_ticks_t(truncatingIfNeeded: -1)) }

  /// The longest finite tick count: `k_ticks_t.max`, less one when the type is
  /// unsigned because `UInt32.max` is `K_TICKS_FOREVER`.
  private static var longestFinite: k_ticks_t { k_ticks_t.isSigned ? .max : .max - 1 }

  /// Clamps a tick count to the finite range of `k_ticks_t`.
  private init(clamping ticks: Int64) {
    self.init(ticks: k_ticks_t(clamping: min(ticks, Int64(Self.longestFinite))))
  }

  /// `K_MSEC(ms)`: rounds up to whole ticks, like `k_ms_to_ticks_ceil64`.
  /// Zero and negative values become `K_NO_WAIT`.
  public static func milliseconds(_ milliseconds: Int32) -> k_timeout_t {
    guard milliseconds > 0 else { return .noWait }
    let ticksPerSecond = Int64(CONFIG_SYS_CLOCK_TICKS_PER_SEC)
    let ticks = (Int64(milliseconds) * ticksPerSecond + 999) / 1_000
    return k_timeout_t(clamping: ticks)
  }

  /// `K_TICKS(ticks)`.
  public static func ticks(_ ticks: k_ticks_t) -> k_timeout_t {
    .init(ticks: ticks)
  }

  #if CONFIG_TIMEOUT_64BIT
    /// `K_TIMEOUT_ABS_TICKS(ticks)`: an absolute deadline in kernel ticks since
    /// boot. Zephyr reserves `-1` for `K_FOREVER` and encodes the absolute tick
    /// `t` as `-2 - t`. Negative values clamp to boot time, and values too large
    /// to encode clamp to the latest deadline.
    ///
    /// Available when the build passes `-DCONFIG_TIMEOUT_64BIT`; without it
    /// `k_ticks_t` is unsigned and Zephyr has no absolute encoding.
    public static func absolute(ticks: k_ticks_t) -> k_timeout_t {
      .init(ticks: -2 - min(max(ticks, 0), k_ticks_t.max - 1))
    }
  #endif

  /// Converts a `Duration` using integer math only (no floating point).
  /// Rounds up to whole ticks, so a positive duration never becomes
  /// `K_NO_WAIT`. Zero and negative durations become `K_NO_WAIT`; durations
  /// too long for `k_ticks_t` clamp to the longest finite timeout.
  public init(_ duration: Duration) {
    let ticks = duration.kernelTicks
    guard ticks > 0 else {
      self = .noWait
      return
    }
    self = k_timeout_t(clamping: ticks)
  }
}

extension Duration {
  /// The duration in kernel ticks, as a signed 64-bit count.
  ///
  /// The magnitude is rounded up to whole ticks straight from the seconds and
  /// attoseconds, so sub-nanosecond precision is kept and a tick-exact duration
  /// is not rounded up twice. The sign is kept, which makes this suitable for
  /// instant arithmetic. Results saturate at `Int64.min` and `Int64.max`; the
  /// timeout conversions apply their own, tighter limits.
  public var kernelTicks: Int64 {
    let (seconds, attoseconds) = components
    let perSecond = UInt64(CONFIG_SYS_CLOCK_TICKS_PER_SEC)
    let negative = self < .zero
    // The signed range is asymmetric: -2^63 is representable, 2^63 is not.
    let limit = UInt64(Int64.max) + (negative ? 1 : 0)

    var fraction: UInt64 = 0
    let atto = attoseconds.magnitude
    if atto > 0 {
      // atto < 1e18, so the 128-bit product divided by 1e18 fits in 64 bits.
      // ceil(p / 1e18) == floor((p - 1) / 1e18) + 1 for p > 0.
      var (high, low) = atto.multipliedFullWidth(by: perSecond)
      if low == 0 {
        high -= 1
        low = .max
      } else {
        low -= 1
      }
      fraction = UInt64(1_000_000_000_000_000_000).dividingFullWidth((high, low)).quotient + 1
    }

    let (whole, overflow) = seconds.magnitude.multipliedReportingOverflow(by: perSecond)
    let magnitude = overflow || whole > limit || fraction > limit - whole ? limit : whole + fraction
    if negative {
      return magnitude > UInt64(Int64.max) ? .min : -Int64(magnitude)
    }
    return Int64(magnitude)
  }
}
