// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// A failed Zephyr call, decoded from the negative `-errno` it returned.
///
/// Embedded Swift has no `Codable`, so this conforms to `Error`, `Sendable`,
/// `Equatable` and `CustomStringConvertible` only. Use `check(_:)` to produce
/// it from a return code.
///
/// ```swift
/// do {
///   try check(code)
/// } catch ZephyrError.timedOut {
///   retry()
/// } catch {
///   report(error.errno)
/// }
/// ```
public enum ZephyrError: Error, Sendable, Equatable {
  /// `EPERM`: the operation is not permitted.
  case permission
  /// `ENOENT`: no such file, entry or device node.
  case noEntry
  /// `EIO`: an I/O error.
  case io
  /// `EAGAIN`: the resource is temporarily unavailable; try again.
  case again
  /// `ENOMEM`: out of memory.
  case noMemory
  /// `EBUSY`: the resource is busy.
  case busy
  /// `ENODEV`: no such device.
  case noDevice
  /// `EINVAL`: an argument is invalid.
  case invalidArgument
  /// `ETIMEDOUT`: the operation timed out.
  case timedOut
  /// Any other errno, kept as its positive value.
  case other(Int32)
}

// MARK: - Extension

extension ZephyrError: CustomStringConvertible {
  /// A short description that carries the errno value.
  public var description: String { "zephyr error errno:\(errno)" }
}

// MARK: - Public

public extension ZephyrError {
  /// Decodes an errno value into the matching case.
  ///
  /// - Parameter errno: A positive errno value. Values without a dedicated
  ///   case become `.other(_:)`.
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
