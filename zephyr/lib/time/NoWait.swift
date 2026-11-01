// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// A timeout that does not block (`K_NO_WAIT`).
public struct NoWait {
  /// Creates the non-blocking timeout.
  public init() {}

  /// `K_NO_WAIT` as a `Timeout`.
  public func toTimeout() -> Timeout { .init(from: self) }
}

// MARK: - Extension

extension NoWait:
  Sendable,
  TimeoutConvertible
{}
