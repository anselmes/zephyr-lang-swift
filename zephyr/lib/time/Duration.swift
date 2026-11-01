// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

// MARK: - Extension

extension Duration: TimeoutConvertible {}

// MARK: - Public

public extension Duration {
  /// Whole kernel ticks, rounded to the nearest tick (integer math).
  ///
  /// The sign is kept, so a negative duration gives negative ticks; this is
  /// not the timeout encoding, which maps negative durations to `K_NO_WAIT` and
  /// rounds up. Rounding to nearest keeps instant arithmetic exact: durations
  /// built from ticks convert back to the same tick count.
  var ticks: Tick {
    Tick(clamping: nearestKernelTicks)
  }

  init(ticks: Tick) {
    let perSecond = Int64(SYS_FREQUENCY)
    let (seconds, remainder) = Int64(ticks).quotientAndRemainder(dividingBy: perSecond)
    // `remainder.magnitude < perSecond`, so the 128-bit product divided by
    // `perSecond` fits in 64 bits and keeps the sub-nanosecond part.
    var (high, low) = remainder.magnitude.multipliedFullWidth(by: 1_000_000_000_000_000_000)
    // Round to the nearest attosecond so repeated conversions do not drift.
    let (sum, carry) = low.addingReportingOverflow(UInt64(perSecond) / 2)
    low = sum
    if carry { high += 1 }
    let attoseconds = Int64(UInt64(perSecond).dividingFullWidth((high, low)).quotient)
    self.init(
      secondsComponent: seconds,
      attosecondsComponent: remainder < 0 ? -attoseconds : attoseconds)
  }

  func toTimeout() -> Timeout { .init(from: self) }
}
