// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

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
/// two lines are printed first.
///
/// - Important: `entrypoint()` must be implemented by the application. The
///   link fails without it.
@c(main)
public func main() {
  #if SWIFT_DEBUG_INFO
    print("Zephyr Swift Application - Debug info enabled")
    print("Swift 6.4 Embedded Mode Active")
  #endif

  entrypoint()
}
