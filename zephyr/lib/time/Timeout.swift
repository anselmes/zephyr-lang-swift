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
  /// `K_FOREVER`; kept for source compatibility.
  static var forever: k_timeout_t { .forever }
  /// `K_NO_WAIT`; kept for source compatibility.
  static var nowait: k_timeout_t { .noWait }

  init(_ value: k_timeout_t) { self.value = value }

  init(from _: Forever) { self.value = .forever }
  init(from _: NoWait) { self.value = .noWait }

  /// Rounds up to whole ticks; a zero duration is `K_NO_WAIT`.
  init(from duration: Duration) { self.value = k_timeout_t(duration) }

  static func == (lhs: Timeout, rhs: Timeout) -> Bool {
    return lhs.value.ticks == rhs.value.ticks
  }

  #if CONFIG_TIMEOUT_64BIT
    /// An instant at or before boot has already passed, so it is `K_NO_WAIT`.
    init(from instant: Instant) {
      self.value = instant.ticks > 0 ? .absolute(ticks: instant.ticks) : .noWait
    }
  #endif
}
