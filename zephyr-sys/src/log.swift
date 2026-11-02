// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrCore

/// Logs `msg` to Zephyr's `swift` log module: `LOG_ERR("%s", msg)` and the
/// other `LOG_*` macros, written in Swift.
///
/// The macros are variadic and cannot be imported, so this does what they
/// expand to: it filters by level, packs a `"%s"` message with one string
/// argument and hands it to `z_log_msg_static_create`. The `swift` log source
/// and the level limit come from BridgingHeader.h. Read-only strings are kept
/// by pointer; the logger copies any other string before it returns.
///
/// Nothing is logged unless the build sets `CONFIG_LOG=y`. Messages above
/// `CONFIG_LOG_DEFAULT_LEVEL` and `CONFIG_LOG_MAX_LEVEL` are dropped, or above
/// `CONFIG_LOG_OVERRIDE_LEVEL` when that is set.
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
    guard level <= UInt32(ZEPHYR_SWIFT_LOG_LEVEL), let msg = unsafe msg else { return }

    // The cbprintf package for `"%s", msg`: header and format string, then the
    // one argument, laid out like the C struct cbprintf expects.
    let format: StaticString = "%s"
    var header = unsafe cbprintf_package_hdr_ext()
    // SAFETY: `utf8Start` points to the static, NUL-terminated literal, and
    // UInt8 and CChar have the same size and alignment. The field is `char *`,
    // but cbprintf only reads the format.
    unsafe header.fmt = UnsafeMutableRawPointer(mutating: format.utf8Start).assumingMemoryBound(to: CChar.self)
    var package = unsafe (header, msg)
    let packageSize = unsafe MemoryLayout.size(ofValue: package)
    // The package length is counted in 32-bit words.
    unsafe package.0.hdr.desc.len = UInt8(packageSize / MemoryLayout<UInt32>.size)

    var descriptor = log_msg_desc()
    descriptor.level = level
    descriptor.package_len = UInt32(packageSize)

    #if CONFIG_LOG_MODE_DEFERRED
      // Deferred mode: the logger allocates the message in its buffer, copies
      // the package into it and prints it later from its thread.
      withUnsafeMutableBytes(of: &package) { bytes in
        // SAFETY: `bytes` covers the whole package for the duration of the
        // call, and z_log_msg_static_create copies it before returning. The
        // source is the `swift` log source data in BridgingHeader.h.
        unsafe z_log_msg_static_create(zephyr_swift_log_source(), descriptor, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), nil)
      }
    #else
      // Immediate mode has no message buffer, so, like the LOG_* macros, build
      // the whole message on the stack (header, then the package in its `data`
      // field) and let z_log_msg_finalize print it before returning. Zephyr
      // asserts that `sizeof(struct log_msg)` is the offset of `data`, so the
      // package that follows the header in this tuple lands exactly there.
      var message = unsafe (log_msg(), package)
      withUnsafeMutableBytes(of: &message) { bytes in
        // SAFETY: `bytes` covers the header and the package, which only holds
        // pointer-sized values, so pointer alignment is enough. The message is
        // processed before z_log_msg_finalize returns. The source is the
        // `swift` log source data in BridgingHeader.h.
        unsafe z_log_msg_finalize(bytes.baseAddress?.assumingMemoryBound(to: log_msg.self), zephyr_swift_log_source(), descriptor, nil)
      }
    #endif
  #endif
}

extension Kernel {
  /// Logs `message` to Zephyr's `swift` log module (`zephyr_log`).
  ///
  /// The message is a `StaticString`, so it lives in read-only memory and is
  /// passed without copying or allocation. Applications use `Log` from the
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
