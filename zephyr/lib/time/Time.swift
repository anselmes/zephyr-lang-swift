// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

#if CONFIG_TIMEOUT_64BIT
  public typealias Tick = Int64
#else
  public typealias Tick = Int32
#endif

// swift-format-ignore: AlwaysUseLowerCamelCase
public var SYS_FREQUENCY: Int32 { return CONFIG_SYS_CLOCK_TICKS_PER_SEC }

// MARK: - Public

/// Sleeps the calling thread (`k_sleep`).
///
/// - Returns: The time left when another thread woke this one early.
@discardableResult
public func sleep<T: TimeoutConvertible>(_ timeout: T) -> Duration {
  Kernel.sleep(timeout: timeout.toTimeout().value)
}

#if CONFIG_TIMEOUT_64BIT
  public func now() -> Instant {
    return .init(ticks: Tick(Kernel.uptimeTicks))
  }
#endif
