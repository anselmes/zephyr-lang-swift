// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

#if CONFIG_CRC

  import ZephyrSystem

  /// CRC-32 checksums (`include/zephyr/sys/crc.h`), available with
  /// `CONFIG_CRC=y`.
  ///
  /// ```swift
  /// var crc: UInt32 = 0
  /// crc = CRC32.ieee(chunk.span.bytes, updating: crc)
  /// ```
  public enum CRC32 {
    /// The IEEE 802.3 CRC-32 of `bytes`, continued from `crc`
    /// (`crc32_ieee_update`).
    ///
    /// - Parameters:
    ///   - bytes: The bytes to add.
    ///   - crc: The checksum so far; zero to start.
    /// - Returns: The checksum including `bytes`.
    public static func ieee(_ bytes: RawSpan, updating crc: UInt32 = 0) -> UInt32 {
      bytes.withUnsafeBytes { raw in
        unsafe crc32_ieee_update(crc, raw.baseAddress?.assumingMemoryBound(to: UInt8.self), raw.count)
      }
    }
  }

#endif
