// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

/// `posix_memalign` for the Embedded Swift runtime, which calls it for every
/// heap allocation (`swift_slowAlloc`). Zephyr's common libc malloc
/// (`lib/libc/common/source/stdlib/malloc.c`) provides `aligned_alloc` and
/// `free` but not `posix_memalign`, so this fills the gap on top of
/// `aligned_alloc`. Memory comes from the libc arena sized by
/// `CONFIG_COMMON_LIBC_MALLOC_ARENA_SIZE`; `free()` releases it.
///
/// - Returns: `0` on success, `EINVAL` for a bad alignment,
///   `ENOMEM` when the arena is exhausted (POSIX semantics).
// swift-format-ignore: AlwaysUseLowerCamelCase
@c @implementation
public func posix_memalign(
  _ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
  _ alignment: Int,
  _ size: Int,
) -> Int32 {
  // POSIX: a power of two and a multiple of sizeof(void *); `Int` is pointer-sized.
  guard alignment >= MemoryLayout<Int>.size, alignment & (alignment - 1) == 0 else {
    return EINVAL
  }
  // SAFETY: aligned_alloc returns nil or a block of at least `size` bytes
  // aligned to `alignment`, owned by the caller until free().
  guard let block = unsafe aligned_alloc(alignment, size) else { return ENOMEM }
  // SAFETY: the caller passes the address of one writable pointer slot.
  unsafe memptr.pointee = block
  return 0
}
