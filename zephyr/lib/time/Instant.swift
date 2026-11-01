// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

#if CONFIG_TIMEOUT_64BIT
  /// A point in time, as kernel ticks since boot.
  ///
  /// Available when the build passes `-DCONFIG_TIMEOUT_64BIT`.
  ///
  /// ```swift
  /// let start = now()
  /// sleep(Duration.milliseconds(250))
  /// let elapsed = now().duration(since: start)
  /// ```
  public struct Instant {
    /// Kernel ticks since boot.
    public let ticks: Tick

    /// Creates an instant from a tick count.
    ///
    /// - Parameter ticks: Kernel ticks since boot.
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
    /// Orders instants by tick count.
    static func < (lhs: Instant, rhs: Instant) -> Bool {
      return lhs.ticks < rhs.ticks
    }

    /// Orders instants by tick count.
    static func > (lhs: Instant, rhs: Instant) -> Bool {
      return lhs.ticks > rhs.ticks
    }

    /// An absolute deadline that expires at this instant.
    func toTimeout() -> Timeout { Timeout(from: self) }

    /// The time between an earlier instant and this one.
    ///
    /// - Parameter earlier: The instant to measure from.
    /// - Returns: This instant minus `earlier`; negative when `earlier` is
    ///   later. A difference that does not fit in `Tick` saturates at its limits
    ///   instead of trapping.
    func duration(since earlier: Instant) -> Duration {
      let (difference, overflow) = self.ticks.subtractingReportingOverflow(earlier.ticks)
      return Duration(ticks: overflow ? (self.ticks < earlier.ticks ? .min : .max) : difference)
    }

    /// The instant a duration after this one.
    ///
    /// - Parameter duration: How far to move, forward or backward; rounded up
    ///   to whole ticks.
    /// - Returns: A new instant at `ticks + duration.ticks`. A result that does
    ///   not fit in `Tick` saturates at its limits instead of trapping.
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
      add(Duration(secondsComponent: 0, attosecondsComponent: attoseconds).nearestKernelTicks)
      add(self.ticks)
      // The 128-bit total fits in `Tick` only if `high` is the sign extension of `low`.
      let fits = high == (Int64(bitPattern: low) < 0 ? -1 : 0)
      return Instant(ticks: fits ? Int64(bitPattern: low) : (high < 0 ? .min : .max))
    }
  }
#endif
