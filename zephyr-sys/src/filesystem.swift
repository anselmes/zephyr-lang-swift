// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

#if CONFIG_FILE_SYSTEM

  import ZephyrSystem

  /// File-system calls that take a path (`fs_mkdir`, `fs_stat`, `fs_unlink`).
  ///
  /// Available with `CONFIG_FILE_SYSTEM=y`. Paths are absolute and start with a
  /// mount point, such as `/lfs/apps`.
  ///
  /// ```swift
  /// do {
  ///   try FileSystem.makeDirectory("/lfs/apps")
  /// } catch .exists {
  ///   // Already there.
  /// }
  /// ```
  public enum FileSystem {}

  // MARK: - Public API

  public extension FileSystem {
    /// Creates a directory (`fs_mkdir`).
    ///
    /// - Parameter path: The directory to create.
    /// - Throws: `.exists` when it already exists, or the error `fs_mkdir`
    ///   returned.
    static func makeDirectory(_ path: String) throws(ZephyrError) {
      try check(path.withCString { unsafe fs_mkdir($0) })
    }

    /// Looks up a file or directory (`fs_stat`).
    ///
    /// - Parameter path: The entry to look up.
    /// - Returns: Its kind, name and size.
    /// - Throws: `.noEntry` when it does not exist, or the error `fs_stat`
    ///   returned.
    static func entry(at path: String) throws(ZephyrError) -> DirectoryEntry {
      var entry: fs_dirent = .init()
      try check(path.withCString { unsafe fs_stat($0, &entry) })
      return .init(entry)
    }

    /// Removes a file or an empty directory (`fs_unlink`).
    ///
    /// - Parameter path: The entry to remove.
    static func remove(_ path: String) throws(ZephyrError) {
      try check(path.withCString { unsafe fs_unlink($0) })
    }
  }

#endif
