// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

public import ZephyrSystem

/// A value that can be turned into a kernel `Timeout`.
///
/// `Duration`, `Forever`, `NoWait` and, when 64-bit ticks are enabled,
/// `Instant` conform, so each can be passed to `sleep(_:)`.
public protocol TimeoutConvertible {
  /// The kernel timeout this value stands for.
  func toTimeout() -> Timeout
}

/// A kernel timeout (`k_timeout_t`) with a Swift-native construction API.
public struct Timeout {
  /// The underlying `k_timeout_t`, ready to pass to a Zephyr C API.
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

  /// Wraps an existing `k_timeout_t`.
  ///
  /// - Parameter value: The timeout to wrap.
  init(_ value: k_timeout_t) { self.value = value }

  /// Creates `K_FOREVER`.
  init(from _: Forever) { self.value = .forever }

  /// Creates `K_NO_WAIT`.
  init(from _: NoWait) { self.value = .noWait }

  /// Creates a relative timeout from a duration.
  ///
  /// Rounds up to whole ticks; a zero duration is `K_NO_WAIT`.
  ///
  /// - Parameter duration: The duration to wait.
  init(from duration: Duration) { self.value = k_timeout_t(duration) }

  /// Two timeouts are equal when they carry the same tick value.
  static func == (lhs: Timeout, rhs: Timeout) -> Bool {
    return lhs.value.ticks == rhs.value.ticks
  }

  #if CONFIG_TIMEOUT_64BIT
    /// Creates an absolute deadline that expires at an instant. An instant at
    /// or before boot has already passed, so it becomes `K_NO_WAIT`.
    ///
    /// Available when the build passes `-DCONFIG_TIMEOUT_64BIT`.
    ///
    /// - Parameter instant: The point in time to wait until.
    init(from instant: Instant) {
      self.value = instant.ticks > 0 ? .absolute(ticks: instant.ticks) : .noWait
    }
  #endif
}
