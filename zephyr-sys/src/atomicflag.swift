// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// A flag that threads and interrupts set and read atomically (Zephyr
/// `atomic_t`).
///
/// ```swift
/// let done = AtomicFlag()
/// done.set()      // on one thread
/// done.isSet      // on another
/// ```
///
/// `@unchecked Sendable`: the value is only read and written through
/// Zephyr's atomic operations, at a heap address that does not move.
@safe public struct AtomicFlag: ~Copyable, @unchecked Sendable {
  private let storage: UnsafeMutablePointer<atomic_t>

  deinit {
    // SAFETY: `storage` was allocated and initialized in `init()`, and this
    // value is its only owner.
    unsafe storage.deinitialize(count: 1)
    unsafe storage.deallocate()
  }
}

// MARK: - Public API

public extension AtomicFlag {
  /// Whether the flag is set (`atomic_get`).
  var isSet: Bool {
    // SAFETY: `storage` stays allocated for the life of `self`.
    unsafe atomic_get(storage) != 0
  }

  /// Creates a cleared flag.
  init() {
    let storage = UnsafeMutablePointer<atomic_t>.allocate(capacity: 1)
    // SAFETY: freshly allocated for one `atomic_t`, initialized before use.
    unsafe storage.initialize(to: 0)
    unsafe self.storage = storage
  }

  /// Sets the flag (`atomic_set`).
  func set() {
    // SAFETY: `storage` stays allocated for the life of `self`.
    _ = unsafe atomic_set(storage, 1)
  }

  /// Clears the flag (`atomic_set`).
  func clear() {
    // SAFETY: `storage` stays allocated for the life of `self`.
    _ = unsafe atomic_set(storage, 0)
  }
}
