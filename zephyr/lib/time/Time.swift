// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSys

// MARK: - Public API

#if CONFIG_TIMEOUT_64BIT
public typealias Tick = Int64
#else
public typealias Tick = Int32
#endif

public var SYS_FREQUENCY: Int32 { return CONFIG_SYS_CLOCK_TICKS_PER_SEC }

public struct Forever: Sendable, TimeoutConvertible {
  public func toTimeout() -> Timeout { Timeout(from: self) }
}

public struct NoWait: Sendable, TimeoutConvertible {
  public func toTimeout() -> Timeout { Timeout(from: self) }
}

@discardableResult
public func sleep<T: TimeoutConvertible>(_ timeout: T) -> Duration {
  let timeout = timeout.toTimeout()
  let rest = k_sleep(timeout.value)
  return .milliseconds(Int(rest))
}

#if CONFIG_TIMEOUT_64BIT
public func now() -> Instant {
  return Instant(ticks: Tick(k_uptime_ticks()))
}
#endif

// MARK: - Internal API

func checkedCast<T: BinaryInteger, U: BinaryInteger>(_ value: T) -> U {
  #if DEBUG
  guard let result = U(exactly: value) else { fatalError("Overflow in time conversion") }
  return result
  #else
  return U(clamping: value)
  #endif
}
