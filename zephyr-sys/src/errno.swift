// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

public import ZephyrSystem

/// The positive errno values Zephyr calls return negated, for code that does
/// not import the C headers.
///
/// ```swift
/// if code == -Errno.timedOut { retry() }
/// ```
public enum Errno {
  /// `EPERM`: the operation is not permitted.
  @inlinable public static var permission: Int32 { EPERM }
  /// `ENOENT`: no such file, entry or device node.
  @inlinable public static var noEntry: Int32 { ENOENT }
  /// `EIO`: an I/O error.
  @inlinable public static var io: Int32 { EIO }
  /// `EAGAIN`: the resource is temporarily unavailable.
  @inlinable public static var again: Int32 { EAGAIN }
  /// `ENOMEM`: out of memory.
  @inlinable public static var noMemory: Int32 { ENOMEM }
  /// `EBUSY`: the resource is busy.
  @inlinable public static var busy: Int32 { EBUSY }
  /// `EEXIST`: the entry already exists.
  @inlinable public static var exists: Int32 { EEXIST }
  /// `ENODEV`: no such device.
  @inlinable public static var noDevice: Int32 { ENODEV }
  /// `EINVAL`: an argument is invalid.
  @inlinable public static var invalidArgument: Int32 { EINVAL }
  /// `ETIMEDOUT`: the operation timed out.
  @inlinable public static var timedOut: Int32 { ETIMEDOUT }
}
