// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSys

/// An Instant appropriate for Zephyr calls that expect an absolute time.
/// The result will be an absolute time in terms of system ticks.
#if CONFIG_TIMEOUT_64BIT
public struct Instant: Equatable, Comparable, Sendable, TimeoutConvertible {
  public let ticks: Tick
}

public extension Instant {
  init(ticks: Tick) { self.ticks = ticks }

  static func < (lhs: Instant, rhs: Instant) -> Bool {
    return lhs.ticks < rhs.ticks
  }

  static func > (lhs: Instant, rhs: Instant) -> Bool {
    return lhs.ticks > rhs.ticks
  }

  func toTimeout() -> Timeout { Timeout(from: self) }

  func duration(since earlier: Instant) -> Duration {
    return Duration(ticks: self.ticks - earlier.ticks)
  }

  func advance(by duration: Duration) -> Instant {
    return Instant(ticks: self.ticks + duration.ticks)
  }
}
#endif
