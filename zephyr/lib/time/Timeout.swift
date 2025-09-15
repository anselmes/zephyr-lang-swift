// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSys

/// A type that can be converted into a Timeout.
/// This is implemented by Duration, Instant, and the marker types Forever and NoWait.
/// This allows functions that take timeouts to accept any of these types.
public protocol TimeoutConvertible {
  func toTimeout() -> Timeout
}

/// Wrapper around the timeout type, so we can implement conversions.
/// This allows `From` and `Info` from the Duration/Instant types into the Zephyr types.
public struct Timeout: Equatable, Sendable {
  public let value: k_timeout_t
}

public extension Timeout {
  static let forever = k_timeout_t(ticks: -1)
  static let nowait = k_timeout_t(ticks: 0)

  init(_ value: k_timeout_t) { self.value = value }

  init(from _: Forever) { self.value = Timeout.forever }
  init(from _: NoWait) { self.value = Timeout.nowait }

  init(from duration: Duration) {
    let ticks = checkedCast(duration.ticks) as k_ticks_t
    assert(ticks != Timeout.forever.ticks)
    assert(ticks != Timeout.nowait.ticks)
    self.value = k_timeout_t(ticks: ticks)
  }

  static func == (lhs: Timeout, rhs: Timeout) -> Bool {
    return lhs.value.ticks == rhs.value.ticks
  }

  #if CONFIG_TIMEOUT_64BIT
  init(from instant: Instant) {
    let ticks = checkedCast(instant.ticks) as k_ticks_t
    assert(ticks != Timeout.forever.ticks)
    assert(ticks != Timeout.nowait.ticks)
    self.value = k_timeout_t(ticks: -1 - ticks)
  }
  #endif
}
