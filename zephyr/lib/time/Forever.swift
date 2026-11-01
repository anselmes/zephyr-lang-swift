// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

public struct Forever {
  public init() {}

  public func toTimeout() -> Timeout { .init(from: self) }
}

// MARK: - Extension

extension Forever:
  Sendable,
  TimeoutConvertible
{}
