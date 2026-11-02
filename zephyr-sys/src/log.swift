// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrCore

/// Logs `msg` to Zephyr's `swift` log module: `LOG_ERR("%s", msg)` and the
/// other `LOG_*` macros, written in Swift.
///
/// The macros are variadic and cannot be imported, so this does what they do:
/// it drops messages that the `swift` source's filters reject, then hands a
/// `"%s"` message with one string argument to the logger through the wrappers
/// in log.h. The logger packages the argument: it keeps a pointer to a string
/// in read-only memory and copies every other string, so `msg` may be a buffer
/// on the caller's stack.
///
/// Nothing is logged unless the build sets `CONFIG_LOG=y`. Messages above
/// `CONFIG_LOG_DEFAULT_LEVEL` and `CONFIG_LOG_MAX_LEVEL` are dropped, or above
/// `CONFIG_LOG_OVERRIDE_LEVEL` when that is set, and with
/// `CONFIG_LOG_RUNTIME_FILTERING=y` so are messages above the source's runtime
/// level, before they take any room in the log buffer.
///
/// - Parameters:
///   - level: A Zephyr severity: `LOG_LEVEL_ERR` (1), `LOG_LEVEL_WRN` (2),
///     `LOG_LEVEL_INF` (3) or `LOG_LEVEL_DBG` (4); other values log at debug.
///   - msg: A NUL-terminated string; nothing is logged for `NULL`.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c @implementation
public func zephyr_log(_ level: UInt32, _ msg: UnsafePointer<CChar>?) {
  #if CONFIG_LOG
    let level = (UInt32(LOG_LEVEL_ERR)...UInt32(LOG_LEVEL_DBG)).contains(level) ? level : UInt32(LOG_LEVEL_DBG)
    guard let msg = unsafe msg, zephyr_swift_log_enabled(level) else { return }

    // SAFETY: `msg` is a non-NULL, NUL-terminated string that the caller keeps
    // valid for this call (the documented contract). The logger only reads it
    // while packaging the message, and copies it unless it is read-only.
    unsafe zephyr_swift_log_message(level, msg)
  #endif
}

extension Kernel {
  /// Logs `message` to Zephyr's `swift` log module (`zephyr_log`).
  ///
  /// The message is a `StaticString`, so it lives in read-only memory and the
  /// logger keeps a pointer to it instead of copying the text; the logger still
  /// records the message in its own buffer. Applications use `Log` from the
  /// `Zephyr` library instead.
  ///
  /// - Parameters:
  ///   - level: A Zephyr severity, `LOG_LEVEL_ERR` (1) to `LOG_LEVEL_DBG` (4).
  ///   - message: The text to log.
  public static func log(level: UInt32, _ message: StaticString) {
    // A string literal is stored as a NUL-terminated UTF-8 C string. A
    // single-scalar StaticString has no such storage, so it is skipped rather
    // than trapping in `utf8Start`.
    guard message.hasPointerRepresentation else { return }
    // SAFETY: `utf8Start` points to static, immutable, NUL-terminated UTF-8
    // that lives for the whole program, and UInt8 and CChar have the same
    // size and alignment; zephyr_log only reads it.
    unsafe zephyr_log(level, UnsafeRawPointer(message.utf8Start).assumingMemoryBound(to: CChar.self))
  }
}
