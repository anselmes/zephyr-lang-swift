// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

// MARK: - Extension

extension Duration: TimeoutConvertible {}

// MARK: - Public

public extension Duration {
  /// Whole kernel ticks, rounded up (integer math).
  ///
  /// The sign is kept, so a negative duration gives negative ticks; this is
  /// not the timeout encoding, which maps negative durations to `K_NO_WAIT`.
  var ticks: Tick {
    Tick(clamping: kernelTicks)
  }

  init(ticks: Tick) {
    let perSecond = Int64(SYS_FREQUENCY)
    let (seconds, remainder) = Int64(ticks).quotientAndRemainder(dividingBy: perSecond)
    // `remainder.magnitude < perSecond`, so the 128-bit product divided by
    // `perSecond` fits in 64 bits and keeps the sub-nanosecond part.
    let (high, low) = remainder.magnitude.multipliedFullWidth(by: 1_000_000_000_000_000_000)
    let attoseconds = Int64(UInt64(perSecond).dividingFullWidth((high, low)).quotient)
    self.init(
      secondsComponent: seconds,
      attosecondsComponent: remainder < 0 ? -attoseconds : attoseconds)
  }

  func toTimeout() -> Timeout { .init(from: self) }
}
