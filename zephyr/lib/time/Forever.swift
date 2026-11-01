// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// A timeout that never expires (`K_FOREVER`).
///
/// ```swift
/// sleep(Forever())
/// ```
public struct Forever {
  /// Creates the never-expiring timeout.
  public init() {}

  /// `K_FOREVER` as a `Timeout`.
  public func toTimeout() -> Timeout { .init(from: self) }
}

// MARK: - Extension

extension Forever:
  Sendable,
  TimeoutConvertible
{}
