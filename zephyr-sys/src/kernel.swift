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
    // Clamp the seconds first so the millisecond count cannot overflow Int64
    // before it is clamped to Int32.
    let limit = Int64(Int32.max) / 1_000 + 1
    let milliseconds = max(min(seconds, limit), -limit) * 1_000 + attoseconds / 1_000_000_000_000_000
    _ = k_msleep(Int32(clamping: milliseconds))
  }

  /// Gives up the CPU to threads of equal priority (`k_yield`).
  public static func yield() {
    k_yield()
  }

  /// Kernel ticks since boot (`k_uptime_ticks`).
  public static var uptimeTicks: Int64 {
    k_uptime_ticks()
  }

  /// Sleeps for a kernel timeout (`k_sleep`). A `.forever` sleep suspends the
  /// thread until another thread calls `k_thread_resume` on it; `k_wakeup` does
  /// not end it.
  ///
  /// - Returns: The time left when the sleep ended early, else `.zero`. A
  ///   resumed `.forever` sleep reports `.zero`.
  @discardableResult
  public static func sleep(timeout: k_timeout_t) -> Duration {
    // k_sleep returns K_TICKS_FOREVER (-1) when a forever sleep is resumed.
    .milliseconds(Int(max(k_sleep(timeout), 0)))
  }
}
