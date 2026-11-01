// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

public import ZephyrSystem

public protocol TimeoutConvertible {
  func toTimeout() -> Timeout
}

public struct Timeout {
  public let value: k_timeout_t
}

// MARK: - Extension

extension Timeout:
  Equatable,
  Sendable
{}

// MARK: - Public

public extension Timeout {
  init(_ value: k_timeout_t) { self.value = value }

  init(from _: Forever) { self.value = .forever }
  init(from _: NoWait) { self.value = .noWait }

  /// Rounds up to whole ticks; a zero duration is `K_NO_WAIT`.
  init(from duration: Duration) { self.value = k_timeout_t(duration) }

  static func == (lhs: Timeout, rhs: Timeout) -> Bool {
    return lhs.value.ticks == rhs.value.ticks
  }

  #if CONFIG_TIMEOUT_64BIT
    init(from instant: Instant) { self.value = .absolute(ticks: instant.ticks) }
  #endif
}
