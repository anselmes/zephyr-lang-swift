// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

/// Thin, allocation-free wrappers over the Zephyr kernel calls the hosts use.
///
/// ```swift
/// Kernel.sleep(for: .milliseconds(500))
/// print(Kernel.uptimeMilliseconds)
/// ```
public enum Kernel {
  /// Milliseconds since boot (`k_uptime_get`).
  public static var uptimeMilliseconds: Int64 {
    k_uptime_get()
  }

  /// Sleeps the calling thread (`k_msleep`). Durations beyond `Int32.max`
  /// milliseconds are clamped. Returns early if another thread calls
  /// `k_wakeup` on this one.
  public static func sleep(for duration: Duration) {
    let (seconds, attoseconds) = duration.components
    let milliseconds = seconds &* 1_000 &+ attoseconds / 1_000_000_000_000_000
    _ = k_msleep(Int32(clamping: milliseconds))
  }

  /// Gives up the CPU to threads of equal priority (`k_yield`).
  public static func yield() {
    k_yield()
  }
}
