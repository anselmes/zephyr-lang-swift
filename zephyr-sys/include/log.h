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
// address. The variadic z_log_msg_runtime_create() that the macros call cannot
// be imported either, so a small wrapper for it is defined here too.
//
// These are statics, so every Swift module that referenced them would get its
// own copy (and the logger would see several `swift` sources). Only the
// zephyr_log() implementation uses them, and other modules call it through
// the C declaration above, so ZephyrCore holds the only copy.

#pragma once

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

// The `swift` log source that the logger expects: the dynamic data with runtime
// filtering, otherwise the constant data.
//
// The logger pairs every dynamic source with the constant source at the same
// index, so with runtime filtering both must be in the image or the filter
// state of the `swift` source is never initialized. Swift emits only the C
// variables that the code it imports refers to, so the table below refers to
// both; the compiler may fold the lookup away, but the variables stay.
static inline const void *zephyr_swift_log_source(void) {
#if defined(CONFIG_LOG_RUNTIME_FILTERING)
  static const void *const sources[] = {&log_const_swift, &log_dynamic_swift};
  return sources[1];
#else
  return &log_const_swift;
#endif
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

// Whether a message at `level` passes the `swift` source's filters, the checks
// the LOG_* macros make before they build a message: the compile-time level
// above and, with CONFIG_LOG_RUNTIME_FILTERING, the aggregate runtime level of
// the enabled backends. A message that fails must not be created: it would take
// room in the log buffer that messages the backends do want could need.
static inline bool zephyr_swift_log_enabled(uint32_t level) {
  return level <= ZEPHYR_SWIFT_LOG_LEVEL &&
         Z_LOG_DYNAMIC_LEVEL_CHECK(level, zephyr_swift_log_source());
}

// Logs `msg` at `level` like LOG_ERR("%s", msg) and the other LOG_* macros do,
// through z_log_msg_runtime_create(). The logger builds the message in any log
// mode and packages the argument itself: it keeps a pointer to a string in
// read-only memory and copies every other string, so `msg` may be a buffer on
// the caller's stack. Callers check zephyr_swift_log_enabled() first.
static inline void zephyr_swift_log_message(uint32_t level, const char *msg) {
  z_log_msg_runtime_create(
      Z_LOG_LOCAL_DOMAIN_ID, zephyr_swift_log_source(), (uint8_t)level, NULL, 0,
      Z_LOG_MSG_CBPRINTF_FLAGS(0) | (IS_ENABLED(CONFIG_LOG_USE_TAGGED_ARGUMENTS)
                                         ? CBPRINTF_PACKAGE_ARGS_ARE_TAGGED
                                         : 0),
      "%s", msg);
}
#endif
