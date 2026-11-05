// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

#if CONFIG_DYNAMIC_THREAD

  import ZephyrSystem

  /// A kernel thread with a stack from `k_thread_stack_alloc`, available with
  /// `CONFIG_DYNAMIC_THREAD=y`.
  ///
  /// The owner must make sure the thread has terminated (``join(timeout:)``
  /// returned `true`, or ``abort()`` was called) before the value goes out of
  /// scope: `deinit` frees the stack.
  ///
  /// ```swift
  /// let thread = try Thread(stackSize: 4096)
  /// thread.start(priority: 7, context: nil) { _, _, _ in print("hi") }
  /// _ = thread.join(timeout: .forever)
  /// ```
  @safe public struct Thread: ~Copyable {
    /// The function a thread runs (`k_thread_entry_t`). `context` from
    /// ``start(priority:context:entry:)`` arrives as the first argument.
    public typealias Entry =
      @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Void

    // The kernel links the `k_thread` into its queues, so it lives on the heap
    // at a fixed address instead of inside this value.
    private let thread: UnsafeMutablePointer<k_thread>
    private let stack: UnsafeMutablePointer<k_thread_stack_t>
    private let stackSize: Int

    /// Frees the stack (`k_thread_stack_free`) and the thread object.
    deinit {
      // SAFETY: `stack` came from `k_thread_stack_alloc` and `thread` from
      // `allocate` in `init(stackSize:)`; this value owns both, and the owner
      // guarantees the thread has terminated.
      _ = unsafe k_thread_stack_free(stack)
      unsafe thread.deinitialize(count: 1)
      unsafe thread.deallocate()
    }
  }

  // MARK: - Public API

  public extension Thread {
    /// Allocates the thread and its stack; it does not run yet.
    ///
    /// - Parameter stackSize: The stack size in bytes.
    /// - Throws: `.noMemory` when the kernel heap has no room for the stack.
    init(stackSize: Int) throws(ZephyrError) {
      // SAFETY: a nil stack is rejected; `thread` is freshly allocated for one
      // `k_thread` and initialized before any use.
      guard let stack = unsafe k_thread_stack_alloc(stackSize, 0) else { throw .noMemory }
      let thread = UnsafeMutablePointer<k_thread>.allocate(capacity: 1)
      unsafe thread.initialize(to: .init())
      unsafe self.thread = thread
      unsafe self.stack = stack
      self.stackSize = stackSize
    }

    /// Starts the thread now (`k_thread_create`). Call it once.
    ///
    /// - Parameters:
    ///   - priority: The thread priority; lower values run first.
    ///   - context: Passed to `entry` as its first argument.
    ///   - entry: The function the thread runs.
    func start(priority: Int32, context: UnsafeMutableRawPointer?, entry: Entry) {
      // SAFETY: `thread` and `stack` (`stackSize` bytes) stay allocated until
      // `deinit`; `entry` is a C function; the caller keeps `context` valid.
      _ = unsafe k_thread_create(thread, stack, stackSize, entry, context, nil, nil, priority, 0, .noWait)
    }

    /// Names the thread (`k_thread_name_set`); does nothing without
    /// `CONFIG_THREAD_NAME`.
    ///
    /// - Parameter name: The name; Zephyr keeps a truncated copy.
    func setName(_ name: String) {
      // SAFETY: NUL-terminated name outlives the call; Zephyr copies it.
      _ = name.withCString { unsafe k_thread_name_set(thread, $0) }
    }

    /// Waits for the thread to terminate (`k_thread_join`).
    ///
    /// - Parameter timeout: How long to wait.
    /// - Returns: `true` when the thread has terminated.
    func join(timeout: KernelTimeout) -> Bool {
      // SAFETY: `thread` stays allocated for the life of `self`.
      unsafe k_thread_join(thread, timeout) == 0
    }

    /// Wakes the thread from a sleep early (`k_wakeup`).
    func wakeup() {
      // SAFETY: `thread` stays allocated for the life of `self`.
      unsafe k_wakeup(thread)
    }

    /// Terminates the thread wherever it is (`k_thread_abort`).
    func abort() {
      // SAFETY: `thread` stays allocated for the life of `self`.
      unsafe k_thread_abort(thread)
    }
  }

#endif
