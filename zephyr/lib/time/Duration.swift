// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

// MARK: - Extension

extension Duration: TimeoutConvertible {}

// MARK: - Public

public extension Duration {
  /// Whole kernel ticks, rounded up (integer math).
  var ticks: Tick {
    Tick(clamping: k_timeout_t(self).ticks)
  }

  init(ticks: Tick) {
    let perSecond = Int64(SYS_FREQUENCY)
    let (seconds, remainder) = Int64(ticks).quotientAndRemainder(dividingBy: perSecond)
    // `remainder < perSecond`, so the product stays far below Int64.max.
    self = .seconds(seconds) + .nanoseconds(remainder * 1_000_000_000 / perSecond)
  }

  func toTimeout() -> Timeout { Timeout(from: self) }
}
