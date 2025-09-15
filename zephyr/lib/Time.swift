// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

/// Time types designed for Zephyr
///
/// Zephyr manages time in terms of system tick intervals, derived from
/// a system constant (SYS_FREQUENCY).
/// This provides Duration and Instant types that
/// operate in system ticks, and conversions to and from timeouts.

import ZephyrSys

// The system time base. The system clock has this many ticks per second.
public var SYS_FREQUENCY: Int32 { return CONFIG_SYS_CLOCK_TICKS_PER_SEC }

// Zephyr can be configured for 64-bit or 32-bit time values.
// Set USE_64BIT_TICK to true for 64-bit, false for 32-bit.
#if USE_64BIT_TICK
public typealias Tick = UInt64
#else
public typealias Tick = UInt32
#endif

public protocol TimeoutConvertible {
  func asTimeout() -> Timeout
}

/// Marker type for "forever"
public struct Forever: TimeoutConvertible {}

/// Marker tye for "no wait"
public struct NoWait: TimeoutConvertible {}

/// Duration appropriate for Zephyr calls that expect a timeout.
/// The result will be a time interval from "now" (when call is made).
public struct Duration: Equatable,
                        Hashable,
                        CustomDebugStringConvertible,
                        TimeoutConvertible {
  public let ticks: Tick
}

/// An Instant appropriate for Zephyr calls that expect an absolute time.
/// The result will be an absolute time in terms of system ticks.
#if USE_64BIT_TICK
public struct Instant: Equatable,
                       Hashable,
                       CustomDebugStringConvertible,
                       TimeoutConvertible {
  public let ticks: Tick
}
#endif

/// Wrapper around the timeout type, so we can implement conversions.
/// This allows `From` and `Info` from the Duration/Instant types into the Zephyr types.
public struct Timeout: Equatable, CustomDebugStringConvertible, TimeoutConvertible {
  public let ticks: Int64   // k_timeout_t is a signed integer
}

// MARK: - Public API

/// Put the current thread to sleep for the given duration.
/// Returns a Duration roughly representing the remaining amount of time if the sleep was woken early.
@discardableResult
public func sleep<T: TimeoutConvertible>(_ timeout: T) -> Duration {
  let val = timeout.asTimeout()
  let rest: Int64 = kSleep(val.ticks)
  return Duration(ticks: Tick(rest > 0 ? rest : 0))
}

public extension Forever { func asTimeout() -> Timeout { .forever } }
public extension NoWait { func asTimeout() -> Timeout { .nowait  } }

public extension Duration {
  var debugDescription: String { "Duration(\(ticks) ticks)" }

  func asTimeout() -> Timeout { Timeout(self) }

  static func zero() -> Duration {
    Duration(ticks: 0)
  }

  static func from(milliseconds ms: UInt64) -> Duration {
    Duration(ticks: Tick(ms * UInt64(SYS_FREQUENCY) / 1000))
  }

  static func from(seconds s: UInt64) -> Duration {
    Duration(ticks: Tick(s * UInt64(SYS_FREQUENCY)))
  }
}

public extension Timeout {
  static let K_NO_WAIT: Int64 = 0
  static let K_FOREVER: Int64 = -1

  static let forever = Timeout(ticks: K_NO_WAIT)
  static let nowait = Timeout(ticks: K_NO_WAIT)

  var debugDescription: String {
    switch ticks {
    case Timeout.K_NO_WAIT: return "Timeout(NoWait)"
    case Timeout.K_FOREVER: return "Timeout(Forever)"
    default: return "Timeout(\(ticks) ticks)"
    }
  }

  init(_ duration: Duration) {
    self.ticks = Int64(duration.ticks)
    assert(
      self.ticks != Timeout.K_NO_WAIT && self.ticks != Timeout.K_FOREVER,
      "Duration cannot be K_NO_WAIT nor K_FOREVER",
    )
  }

  #if USE_64BIT_TICK
  init(_ instant: Instant) {
    // For absolute timeouts, Zephyr encodes as (-1 - ticks)
    self.ticks = -1 - Int64(instant.ticks)
    assert(
      self.ticks != Timeout.K_NO_WAIT && self.ticks != Timeout.K_FOREVER,
      "Instant cannot be K_NO_WAIT nor K_FOREVER"
    )
  }
  #endif

  func asTimeout() -> Timeout { self }
}

#if USE_64BIT_TICK
public extension Instant {
  var debugDescription: String { "Instant (\(ticks) ticks)" }

  init(ticks: Tick) { self.ticks = ticks }

  static func now() -> Instant {
    let current: Tick = getUptimeTicks()
    return Instant(ticks: current)
  }

  func asTimeout() -> Timeout { Timeout(self) }
}
#endif

// MARK: - Private API

func getUptimeTicks() -> Tick { return Tick(k_uptime_ticks()) }

func kSleep(_ ticks: Int64) -> Int64 {
  let timeout = k_timeout_t(ticks: Int64(ticks))
  return Int64(k_sleep(timeout))
}
