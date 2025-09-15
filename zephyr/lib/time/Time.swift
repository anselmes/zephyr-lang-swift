// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

/// Time types designed for Zephyr
///
/// Zephyr manages time in terms of system tick intervals, derived from
/// a system constant (SYS_FREQUENCY).
/// This provides Duration and Instant types that
/// operate in system ticks, and conversions to and from timeouts.

import ZephyrSys

// MARK: - Public API

// Zephyr can be configured for 64-bit or 32-bit time values.
// Set CONFIG_TIMEOUT_64BIT to true for 64-bit, false for 32-bit.
#if CONFIG_TIMEOUT_64BIT
public typealias Tick = Int64
#else
public typealias Tick = Int32
#endif

// The system time base. The system clock has this many ticks per second.
public var SYS_FREQUENCY: Int32 { return CONFIG_SYS_CLOCK_TICKS_PER_SEC }

/// Marker type for "forever"
public struct Forever: Sendable, TimeoutConvertible {
  public func toTimeout() -> Timeout { Timeout(from: self) }
}

/// Marker tye for "no wait"
public struct NoWait: Sendable, TimeoutConvertible {
  public func toTimeout() -> Timeout { Timeout(from: self) }
}

/// Put the current thread to sleep for the given duration.
/// Returns a Duration roughly representing the remaining amount of time if the sleep was woken early.
@discardableResult
public func sleep<T: TimeoutConvertible>(_ timeout: T) -> Duration {
  let timeout = timeout.toTimeout()
  let rest = k_sleep(timeout.value)
  return .milliseconds(Int(rest))
}

#if CONFIG_TIMEOUT_64BIT
public func now() -> Instant {
  return Instant(ticks: Tick(k_uptime_ticks()))
}
#endif

// MARK: - Internal API

/// Convert from the Tick time type, which is unsigned, to the `k_ticks_t` type. When debug
/// assertions are enabled, it will panic on overflow.
func checkedCast<T: BinaryInteger, U: BinaryInteger>(_ value: T) -> U {
  #if DEBUG
  guard let result = U(exactly: value) else { fatalError("Overflow in time conversion") }
  return result
  #else
  return U(clamping: value)
  #endif
}
