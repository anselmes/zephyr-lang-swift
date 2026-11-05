// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

#if CONFIG_FILE_SYSTEM

  import ZephyrSystem

  /// An open directory (`fs_opendir`), closed when it goes out of scope.
  ///
  /// ```swift
  /// let directory = try Directory(path: "/lfs/apps")
  /// while let entry = try directory.next() {
  ///   print(entry.size)
  /// }
  /// ```
  @safe public struct Directory: ~Copyable {
    // The kernel keeps working on the same `fs_dir_t` across calls, so it
    // lives on the heap at a fixed address instead of inside this value.
    private let handle: UnsafeMutablePointer<fs_dir_t>

    /// Closes the directory (`fs_closedir`).
    deinit {
      // SAFETY: `handle` was allocated and initialized in `init(path:)`, this
      // value is its only owner, and it is closed, deinitialized and freed once.
      _ = unsafe fs_closedir(handle)
      unsafe handle.deinitialize(count: 1)
      unsafe handle.deallocate()
    }
  }

  // MARK: - Public API

  public extension Directory {
    /// Opens a directory (`fs_opendir`).
    ///
    /// - Parameter path: The directory to open.
    /// - Throws: The error `fs_opendir` returned, such as `.noEntry`.
    init(path: String) throws(ZephyrError) {
      let handle = UnsafeMutablePointer<fs_dir_t>.allocate(capacity: 1)
      // SAFETY: `handle` is freshly allocated for one `fs_dir_t`; `withCString`
      // gives `fs_opendir` a NUL-terminated path that outlives the call.
      unsafe handle.initialize(to: .init())
      unsafe fs_dir_t_init(handle)
      let result = path.withCString { unsafe fs_opendir(handle, $0) }
      guard result == 0 else {
        // SAFETY: the open failed, so nothing else refers to `handle`.
        unsafe handle.deinitialize(count: 1)
        unsafe handle.deallocate()
        throw ZephyrError(errno: -result)
      }
      unsafe self.handle = handle
    }

    /// The next entry (`fs_readdir`).
    ///
    /// - Returns: The entry, or `nil` at the end of the directory.
    /// - Throws: The error `fs_readdir` returned.
    func next() throws(ZephyrError) -> DirectoryEntry? {
      var entry: fs_dirent = .init()
      // SAFETY: `handle` is open until `deinit`; `&entry` points at one
      // `fs_dirent` that lives across the call.
      try check(unsafe fs_readdir(handle, &entry))
      let next = DirectoryEntry(entry)
      // fs_readdir reports the end of the directory with an empty name.
      return next.name.isEmpty ? nil : next
    }
  }

#endif
