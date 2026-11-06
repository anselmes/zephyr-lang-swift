// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

// ZephyrSystem C Interface Declarations
//
// Functions declared here are implemented in Swift with `@c @implementation`,
// which makes the compiler check each Swift signature against this C
// declaration.

#pragma once

#include "bounds.h"  // NOLINT(build/include_subdir)

#ifdef __cplusplus
extern "C" {
#endif

#if defined(CONFIG_CRC)
// `crc32_ieee_update` with the length attached to the buffer, so Swift calls it
// with a `Span<UInt8>` instead of a pointer and a count.
static inline uint32_t zephyr_crc32_ieee_update(
    uint32_t crc, const uint8_t *ZEPHYR_COUNTED_BY(len) ZEPHYR_NOESCAPE data,
    size_t len) {
  return crc32_ieee_update(crc, data, len);
}
#endif

#if defined(CONFIG_FILE_SYSTEM)
// `fs_read` and `fs_write` with the size attached to the buffer, so Swift calls
// them with a `MutableRawSpan` and a `RawSpan`.
static inline ssize_t zephyr_fs_read(struct fs_file_t *zfp,
                                     void *ZEPHYR_SIZED_BY(size)
                                         ZEPHYR_NOESCAPE ptr,
                                     size_t size) {
  return fs_read(zfp, ptr, size);
}

static inline ssize_t zephyr_fs_write(struct fs_file_t *zfp,
                                      const void *ZEPHYR_SIZED_BY(size)
                                          ZEPHYR_NOESCAPE ptr,
                                      size_t size) {
  return fs_write(zfp, ptr, size);
}
#endif

// `k_panic()` is a function-like macro, which Swift cannot import. This inline
// wrapper gives Swift a real function to call.
static inline void zephyr_panic(void) { k_panic(); }

// POSIX aligned allocation, implemented in zephyr-sys/src/malloc.swift. The
// Embedded Swift runtime calls it for every heap allocation. It is built on
// `aligned_alloc` from Zephyr's common libc malloc.
int posix_memalign(void **memptr, size_t alignment, size_t size);

// Reserved initialization hook for the ZephyrSystem runtime support. Currently
// empty (zephyr-sys/src/init.swift).
void zephyr_sys_init(void);

// Raises a fatal kernel panic through zephyr_panic(). Implemented in
// zephyr-sys/src/panic.swift.
void swift_panic_wrap(void);

// Logs `msg` to the `swift` log module at `level` (`LOG_LEVEL_ERR` through
// `LOG_LEVEL_DBG`; anything else logs at debug), like `LOG_ERR("%s", msg)` and
// the other `LOG_*` macros. Implemented in zephyr-sys/src/log.swift. Does
// nothing when `CONFIG_LOG` is off or `CONFIG_LOG_MODE_MINIMAL` is on. C code
// may call it too.
void zephyr_log(uint32_t level, const char *ZEPHYR_NULL_TERMINATED msg);

// The application's entry point, which every Swift application implements with
// `@c(entrypoint) func entrypoint()`. The C `main` in
// zephyr/src/Application.swift calls it through `Entrypoint.run()`. The
// application is a separate Swift module, so `main` reaches it through this
// declaration.
void entrypoint(void);

#ifdef __cplusplus
}
#endif
