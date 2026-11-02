// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

// ZephyrCore C Interface Declarations
//
// Functions declared here are implemented in Swift with `@c @implementation`,
// which makes the compiler check each Swift signature against this C
// declaration.

#ifdef __cplusplus
extern "C" {
#endif

// `k_panic()` is a function-like macro, which Swift cannot import. This inline
// wrapper gives Swift a real function to call.
static inline void zephyr_panic(void) { k_panic(); }

// POSIX aligned allocation, implemented in zephyr-sys/src/malloc.swift. The
// Embedded Swift runtime calls it for every heap allocation. It is built on
// `aligned_alloc` from Zephyr's common libc malloc.
int posix_memalign(void **memptr, size_t alignment, size_t size);

// Reserved initialization hook for the ZephyrCore runtime support. Currently
// empty (zephyr-sys/src/init.swift).
void zephyr_sys_init(void);

// Logs `msg` to the `swift` log module at `level` (`LOG_LEVEL_ERR` through
// `LOG_LEVEL_DBG`; anything else logs at debug), like `LOG_ERR("%s", msg)` and
// the other `LOG_*` macros. Implemented in zephyr-sys/src/log.swift. Does
// nothing when `CONFIG_LOG` is off. C code may call it too.
void zephyr_log(uint32_t level, const char *msg);

#ifdef __cplusplus
}
#endif
