// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

// MARK: - Extension

extension Duration: TimeoutConvertible {}

// MARK: - Public

public extension Duration {
  /// The duration in whole kernel ticks, rounded to the nearest tick (integer
  /// math).
  ///
  /// The sign is kept, so a negative duration gives negative ticks and zero
  /// gives zero. This is not the timeout encoding, which rounds up and maps
  /// negative durations to `K_NO_WAIT`. Rounding to nearest keeps instant
  /// arithmetic exact: a duration built from ticks converts back to the same
  /// tick count. Values too long for `Tick` clamp to its limits.
  var ticks: Tick {
    Tick(clamping: nearestKernelTicks)
  }

  /// Creates a duration from a number of kernel ticks.
  ///
  /// The sub-second part is truncated toward zero to whole attoseconds, so a
  /// tick rate that does not divide one second evenly loses less than one
  /// attosecond per tick. `ticks` (nearest) converts the result back to the
  /// same tick count. A timeout (round up) does too for positive counts; zero
  /// and negative counts become `K_NO_WAIT`, which carries zero ticks.
  ///
  /// - Parameter ticks: The number of kernel ticks.
  init(ticks: Tick) {
    let perSecond = Int64(SYS_FREQUENCY)
    let (seconds, remainder) = Int64(ticks).quotientAndRemainder(dividingBy: perSecond)
    // `remainder.magnitude < perSecond`, so the 128-bit product divided by
    // `perSecond` fits in 64 bits and keeps the sub-nanosecond part.
    let (high, low) = remainder.magnitude.multipliedFullWidth(by: 1_000_000_000_000_000_000)
    // Truncate toward zero: the error is under one attosecond, and both the
    // round-up (timeout) and nearest (instant) conversions recover `ticks`.
    let attoseconds = Int64(UInt64(perSecond).dividingFullWidth((high, low)).quotient)
    self.init(
      secondsComponent: seconds,
      attosecondsComponent: remainder < 0 ? -attoseconds : attoseconds,
    )
  }

  /// A relative timeout for this duration.
  func toTimeout() -> Timeout { .init(from: self) }
}
