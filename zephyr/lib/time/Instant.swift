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
      // Add the whole seconds and the sub-second part separately, in 128 bits:
      // `duration.ticks` is already saturated, so it cannot reveal an overflow.
      let (seconds, attoseconds) = duration.components
      var (high, low) = seconds.multipliedFullWidth(by: Int64(SYS_FREQUENCY))
      func add(_ part: Int64) {
        let (sum, carry) = low.addingReportingOverflow(UInt64(bitPattern: part))
        low = sum
        high = high &+ (part < 0 ? -1 : 0) &+ (carry ? 1 : 0)
      }
      add(Duration(secondsComponent: 0, attosecondsComponent: attoseconds).kernelTicks)
      add(self.ticks)
      // The 128-bit total fits in `Tick` only if `high` is the sign extension of `low`.
      let fits = high == (Int64(bitPattern: low) < 0 ? -1 : 0)
      return Instant(ticks: fits ? Int64(bitPattern: low) : (high < 0 ? .min : .max))
    }
  }
#endif
