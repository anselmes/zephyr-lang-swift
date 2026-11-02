// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// Turns a Zephyr return code into a typed throw.
///
/// ```swift
/// // `code` is the return value of a ZephyrSystem wrapper over a Zephyr call.
/// try check(code)
/// ```
///
/// - Parameter code: A Zephyr return value: negative `-errno` on failure.
/// - Returns: `code` when it is zero or positive.
/// - Throws: `ZephyrError` decoded from a negative `code`.
@inlinable
@discardableResult
public func check(_ code: Int32) throws(ZephyrError) -> Int32 {
  guard code >= 0 else { throw ZephyrError(errno: -code) }
  return code
}
