// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

// `swift` Log Source
//
// The data that LOG_MODULE_REGISTER(swift) would create, for zephyr_log(),
// which zephyr-sys/src/log.swift implements in Swift.

// The LOG_* macros are variadic and cannot be imported, and Swift can neither
// put a string pointer in a `@section` constant nor take the address of a C
// global without copying it. So the source structs are defined here, in the
// sections Zephyr's logger enumerates, with a one-line accessor for their
// address.
//
// These are statics, so every Swift module that referenced them would get its
// own copy (and the logger would see several `swift` sources). Only the
// zephyr_log() implementation uses them, and other modules call it through
// the C declaration above, so ZephyrCore holds the only copy.
#if defined(CONFIG_LOG)
static const STRUCT_SECTION_ITERABLE_ALTERNATE(log_const, log_source_const_data,
                                               log_const_swift) = {
    .name = "swift",
    .level = CONFIG_LOG_DEFAULT_LEVEL,
};

#if defined(CONFIG_LOG_RUNTIME_FILTERING)
// Runtime filter state; Zephyr's logger initializes it at boot. The explicit
// initializer matters: Swift does not emit a tentative definition.
static STRUCT_SECTION_ITERABLE_ALTERNATE(log_dynamic, log_source_dynamic_data,
                                         log_dynamic_swift) = {0};
#endif

// The `swift` log source that z_log_msg_static_create() expects: the dynamic
// data with runtime filtering, otherwise the constant data.
static inline const void *zephyr_swift_log_source(void) {
  return COND_CODE_1(CONFIG_LOG_RUNTIME_FILTERING, (&log_dynamic_swift),
                     (&log_const_swift));
}

// The highest level the `swift` module logs at, as the LOG_* macros work it
// out: CONFIG_LOG_OVERRIDE_LEVEL when set, otherwise the module level
// (CONFIG_LOG_DEFAULT_LEVEL) capped at CONFIG_LOG_MAX_LEVEL.
enum {
  ZEPHYR_SWIFT_LOG_LEVEL =
      CONFIG_LOG_OVERRIDE_LEVEL
          ? CONFIG_LOG_OVERRIDE_LEVEL
          : MIN(CONFIG_LOG_DEFAULT_LEVEL, CONFIG_LOG_MAX_LEVEL),
};
#endif
