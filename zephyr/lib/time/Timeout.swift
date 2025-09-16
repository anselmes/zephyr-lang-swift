// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSys

public protocol TimeoutConvertible {
  func toTimeout() -> Timeout
}

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
