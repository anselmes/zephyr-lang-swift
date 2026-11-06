// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

#if CONFIG_FILE_SYSTEM

  import ZephyrSystem

  /// An open file (`fs_open`), closed when it goes out of scope.
  ///
  /// ```swift
  /// let file = try File(path: "/lfs/apps/hello.wasm", mode: .read)
  /// var bytes = [UInt8](repeating: 0, count: 256)
  /// var span = bytes.mutableSpan.mutableBytes
  /// let count = try file.read(into: &span)
  /// ```
  @safe public struct File: ~Copyable {
    // The kernel keeps working on the same `fs_file_t` across calls, so it
    // lives on the heap at a fixed address instead of inside this value.
    private let handle: UnsafeMutablePointer<fs_file_t>

    /// How a file is opened (`FS_O_*`).
    public struct Mode: OptionSet, Sendable {
      /// The `fs_mode_t` bits.
      public let rawValue: UInt8

      /// Creates a mode from `fs_mode_t` bits.
      public init(rawValue: UInt8) { self.rawValue = rawValue }

      /// `FS_O_READ`.
      public static var read: Mode { .init(rawValue: UInt8(FS_O_READ)) }
      /// `FS_O_WRITE`.
      public static var write: Mode { .init(rawValue: UInt8(FS_O_WRITE)) }
      /// `FS_O_CREATE`: create the file when it does not exist.
      public static var create: Mode { .init(rawValue: UInt8(FS_O_CREATE)) }
      /// `FS_O_TRUNC`: empty the file when it is opened.
      public static var truncate: Mode { .init(rawValue: UInt8(FS_O_TRUNC)) }
      /// `FS_O_APPEND`: write at the end.
      public static var append: Mode { .init(rawValue: UInt8(FS_O_APPEND)) }
    }

    /// Closes the file (`fs_close`), which also flushes what was written.
    deinit {
      // SAFETY: `handle` was allocated and initialized in `init(path:mode:)`,
      // this value is its only owner, and it is closed and freed once.
      _ = unsafe fs_close(handle)
      unsafe handle.deinitialize(count: 1)
      unsafe handle.deallocate()
    }
  }

  // MARK: - Public API

  public extension File {
    /// Opens a file (`fs_open`).
    ///
    /// - Parameters:
    ///   - path: The file to open.
    ///   - mode: How to open it.
    /// - Throws: The error `fs_open` returned, such as `.noEntry`.
    init(path: String, mode: Mode) throws(ZephyrError) {
      let handle = UnsafeMutablePointer<fs_file_t>.allocate(capacity: 1)
      // SAFETY: `handle` is freshly allocated for one `fs_file_t`; `withCString`
      // gives `fs_open` a NUL-terminated path that outlives the call.
      unsafe handle.initialize(to: .init())
      unsafe fs_file_t_init(handle)
      let result = path.withCString { unsafe fs_open(handle, $0, mode.rawValue) }
      guard result == 0 else {
        // SAFETY: the open failed, so nothing else refers to `handle`.
        unsafe handle.deinitialize(count: 1)
        unsafe handle.deallocate()
        throw ZephyrError(errno: -result)
      }
      unsafe self.handle = handle
    }

    /// Reads until `buffer` is full or the file ends (`fs_read`).
    ///
    /// - Parameter buffer: Where the bytes go.
    /// - Returns: The number of bytes read; less than `buffer.byteCount` only
    ///   at the end of the file.
    /// - Throws: The error `fs_read` returned.
    func read(into buffer: inout MutableRawSpan) throws(ZephyrError) -> Int {
      var offset = 0
      while offset < buffer.byteCount {
        var rest = buffer._mutatingExtracting(droppingFirst: offset)
        // SAFETY: `handle` is open until `deinit`; the span bounds the write to
        // the unread part of `buffer`.
        let count = unsafe zephyr_fs_read(handle, &rest)
        guard count >= 0 else { throw ZephyrError(errno: Int32(-count)) }
        if count == 0 { break }
        offset += count
      }
      return offset
    }

    /// Writes all of `bytes` (`fs_write`).
    ///
    /// - Parameter bytes: The bytes to write.
    /// - Throws: The error `fs_write` returned; `.noMemory` when the volume is
    ///   full.
    func write(_ bytes: RawSpan) throws(ZephyrError) {
      var offset = 0
      while offset < bytes.byteCount {
        // SAFETY: `handle` is open until `deinit`; the span bounds the read to
        // the unwritten part of `bytes`.
        let count = unsafe zephyr_fs_write(handle, bytes.extracting(droppingFirst: offset))
        guard count > 0 else { throw count < 0 ? ZephyrError(errno: Int32(-count)) : .noMemory }
        offset += count
      }
    }
  }

#endif
