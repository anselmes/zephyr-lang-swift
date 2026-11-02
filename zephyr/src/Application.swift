// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr
import ZephyrCore

/// The C `main` that Zephyr calls once the kernel is up.
///
/// `@c(main)` gives the function the unmangled C symbol `main`, so Zephyr's
/// application startup finds it. It calls `entrypoint()`, which every Swift
/// application provides:
///
/// ```swift
/// @c(entrypoint)
/// func entrypoint() {
///   while true { sleep(Duration.milliseconds(1000)) }
/// }
/// ```
///
/// When the build defines `SWIFT_DEBUG_INFO` (`CONFIG_SWIFT_DEBUG_INFO=y`),
/// two debug-level lines are logged first; they appear only with `CONFIG_LOG=y`
/// and `CONFIG_LOG_DEFAULT_LEVEL=4`.
///
/// - Important: `entrypoint()` must be implemented by the application. The
///   link fails without it.
@c(main)
public func main() {
  #if SWIFT_DEBUG_INFO
    Log.info("Zephyr Swift Application - Debug info enabled")
    Log.info("Swift Embedded Mode Active")
  #endif

  entrypoint()
}

/// Raises a fatal kernel panic through Zephyr's `k_panic()`.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c
public func swift_panic_wrap() {
  zephyr_panic()
}
