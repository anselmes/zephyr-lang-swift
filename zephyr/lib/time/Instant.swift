// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

#if CONFIG_TIMEOUT_64BIT
  public struct Instant {
    public let ticks: Tick

    public init(ticks: Tick) { self.ticks = ticks }
  }

  // MARK: - Extension

  extension Instant:
    Comparable,
    Equatable,
    Sendable,
    TimeoutConvertible
  {}

  // MARK: - Public

  public extension Instant {
    static func < (lhs: Instant, rhs: Instant) -> Bool {
      return lhs.ticks < rhs.ticks
    }

    static func > (lhs: Instant, rhs: Instant) -> Bool {
      return lhs.ticks > rhs.ticks
    }

    func toTimeout() -> Timeout { Timeout(from: self) }

    /// Saturates at `Tick.min`/`Tick.max` ticks instead of trapping when the
    /// difference does not fit.
    func duration(since earlier: Instant) -> Duration {
      let (difference, overflow) = self.ticks.subtractingReportingOverflow(earlier.ticks)
      return Duration(ticks: overflow ? (self.ticks < earlier.ticks ? .min : .max) : difference)
    }

    /// Saturates at `Tick.min`/`Tick.max` ticks instead of trapping when the
    /// result does not fit.
    func advance(by duration: Duration) -> Instant {
      let delta = duration.ticks
      let (sum, overflow) = self.ticks.addingReportingOverflow(delta)
      return Instant(ticks: overflow ? (delta < 0 ? .min : .max) : sum)
    }
  }
#endif
