// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

#if CONFIG_FILE_SYSTEM

  import ZephyrSystem

  /// A file or directory, as `fs_readdir` and `fs_stat` describe it
  /// (`struct fs_dirent`).
  public struct DirectoryEntry: Sendable {
    /// Whether the entry is a file or a directory.
    public let kind: Kind

    /// The entry's name, without its directory and without the NUL.
    public let name: [UInt8]

    /// The file's size in bytes; zero for a directory.
    public let size: Int

    /// Whether an entry is a file or a directory.
    public enum Kind: Sendable {
      /// `FS_DIR_ENTRY_FILE`.
      case file
      /// `FS_DIR_ENTRY_DIR`.
      case directory
    }
  }

  // MARK: - Internal

  extension DirectoryEntry {
    /// Copies an `fs_dirent`.
    init(_ entry: borrowing fs_dirent) {
      kind = entry.type == FS_DIR_ENTRY_DIR ? .directory : .file
      size = entry.size
      // `name` is a fixed `char[MAX_FILE_NAME + 1]`, imported as a tuple:
      // copy the bytes up to the NUL.
      name = withUnsafeBytes(of: entry.name) { raw in
        // SAFETY: `raw` covers the whole tuple, and `prefix` stops at the first
        // NUL or the end of the buffer, so only initialized bytes are copied.
        unsafe Array(raw.prefix { $0 != 0 })
      }
    }
  }

#endif
