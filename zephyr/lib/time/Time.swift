// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrCore
import ZephyrSystem

#if CONFIG_TIMEOUT_64BIT
  /// The integer type of a kernel tick count: `Int64` when the build passes
  /// `-DCONFIG_TIMEOUT_64BIT` (Zephyr's default), `Int32` otherwise.
  public typealias Tick = Int64
#else
  /// The integer type of a kernel tick count: `Int64` when the build passes
  /// `-DCONFIG_TIMEOUT_64BIT` (Zephyr's default), `Int32` otherwise.
  public typealias Tick = Int32
#endif

/// Kernel ticks per second (`CONFIG_SYS_CLOCK_TICKS_PER_SEC`).
// swift-format-ignore: AlwaysUseLowerCamelCase
public var SYS_FREQUENCY: Int32 { return CONFIG_SYS_CLOCK_TICKS_PER_SEC }

// MARK: - Public

/// Sleeps the calling thread (`k_sleep`).
///
/// ```swift
/// sleep(Duration.milliseconds(1000))
/// sleep(Forever())
/// ```
///
/// - Parameter timeout: How long to sleep: a `Duration`, `Forever`, `NoWait`
///   or, when 64-bit ticks are enabled, an `Instant`.
/// - Returns: The time left when another thread woke this one early, else
///   `.zero`.
@discardableResult
public func sleep<T: TimeoutConvertible>(_ timeout: T) -> Duration {
  Kernel.sleep(timeout: timeout.toTimeout().value)
}

#if CONFIG_TIMEOUT_64BIT
  /// The current time, as kernel ticks since boot (`k_uptime_ticks`).
  ///
  /// Available when the build passes `-DCONFIG_TIMEOUT_64BIT`.
  public func now() -> Instant {
    return .init(ticks: Tick(Kernel.uptimeTicks))
  }
#endif
