// Copyright (c) 2024 Linaro LTD
// SPDX-License-Identifier: Apache-2.0

import ZephyrSys

public typealias ZephyrResult<T> = Swift.Result<T, ZephyrError>

public struct ZephyrError {
  public let errno: Int32

  @inlinable
  public init(errno: Int32) {
    self.errno = errno
  }
}

// MARK: - Extension

extension ZephyrError:
  CustomDebugStringConvertible,
  CustomStringConvertible,
  Sendable,
  Swift.Error
  {}

// MARK: - Public

public extension ZephyrError {
  var description: String { "zephyr error errno:\(errno)" }
  var debugDescription: String { "zephyr error errno:\(errno)" }
}

public extension Result where Failure == ZephyrError {
  @inlinable
  func get() throws -> Success {
    switch self {
    case .success(let value):
      return value
    case .failure(let error):
      throw error
    }
  }
}

@inlinable
public func toResult(_ code: Int32) -> ZephyrResult<Int32> {
  if code < 0 {
    .failure(ZephyrError(errno: Int32(-code)))
  } else {
    .success(code)
  }
}

@inlinable
public func toResultVoid(_ code: Int32) -> ZephyrResult<Void> {
  toResult(code).map { _ in () }
}
