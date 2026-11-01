// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// A failed Zephyr call, decoded from the negative `-errno` it returned.
///
/// Embedded Swift has no `Codable`, so this only conforms to `Error` and
/// `Sendable`.
public enum ZephyrError: Error, Sendable, Equatable {
  case permission
  case noEntry
  case io
  case again
  case noMemory
  case busy
  case noDevice
  case invalidArgument
  case timedOut
  case other(Int32)
}

// MARK: - Extension

extension ZephyrError: CustomStringConvertible {
  public var description: String { "zephyr error errno:\(errno)" }
}

// MARK: - Public

public extension ZephyrError {
  /// - Parameter errno: A positive errno value.
  @inlinable
  init(errno: Int32) {
    switch errno {
    case EPERM: self = .permission
    case ENOENT: self = .noEntry
    case EIO: self = .io
    case EAGAIN: self = .again
    case ENOMEM: self = .noMemory
    case EBUSY: self = .busy
    case ENODEV: self = .noDevice
    case EINVAL: self = .invalidArgument
    case ETIMEDOUT: self = .timedOut
    default: self = .other(errno)
    }
  }

  /// The positive errno value this error was decoded from.
  var errno: Int32 {
    switch self {
    case .permission: EPERM
    case .noEntry: ENOENT
    case .io: EIO
    case .again: EAGAIN
    case .noMemory: ENOMEM
    case .busy: EBUSY
    case .noDevice: ENODEV
    case .invalidArgument: EINVAL
    case .timedOut: ETIMEDOUT
    case .other(let errno): errno
    }
  }
}
