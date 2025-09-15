// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSys

extension Duration: TimeoutConvertible {}

public extension Duration {
  /// Get the duration as system ticks
  var ticks: Tick {
    let totalNanoSeconds = self.components.seconds * 1_000_000_000 + Int64(self.components.attoseconds / 1_000_000_000)
    let ticksPerNanoSecond = Double(SYS_FREQUENCY) / 1_000_000_000.0
    return Tick(Double(totalNanoSeconds) * ticksPerNanoSecond)
  }

  /// Create a Duration from system ticks
  init(ticks: Tick) {
    let seconds = Double(ticks) / Double(SYS_FREQUENCY)
    self = .seconds(seconds)
  }

  /// Convert to Timeout
  func toTimeout() -> Timeout { Timeout(from: self) }
}
