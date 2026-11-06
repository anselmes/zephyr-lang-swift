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
// the C declaration above, so ZephyrSystem holds the only copy.
//
// CONFIG_LOG_MODE_MINIMAL builds no logging core: there are no message records,
// no sources and no z_log_msg_runtime_create(). There is nothing to log into,
// so in that mode the wrappers at the end of this file do nothing.

#pragma once

#if defined(CONFIG_LOG) && !defined(CONFIG_LOG_MODE_MINIMAL)
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
  if (level > ZEPHYR_SWIFT_LOG_LEVEL) {
    return false;
  }
#if defined(CONFIG_LOG_RUNTIME_FILTERING)
  // The filters live in kernel memory, which a user thread cannot read: it
  // would fault. As the LOG_* macros do, leave the filtering to the logging
  // core for those callers.
  if (IS_ENABLED(CONFIG_USERSPACE) && k_is_user_context()) {
    return true;
  }
  // The logger writes the filters when it starts and whenever they change,
  // which the compiler cannot see from this module. It would take the zero in
  // the initializer above for a constant, fold this check to false and drop
  // every message, so read the filters through a volatile access.
  const uint32_t filters =
      *(const volatile uint32_t *)&log_dynamic_swift.filters;
  return level <= Z_LOG_RUNTIME_FILTER(filters);
#else
  return true;
#endif
}

// Logs `msg` at `level` like LOG_ERR("%s", msg) and the other LOG_* macros do,
// through z_log_msg_runtime_create(). The logger builds the message in any log
// mode and packages the argument itself: it keeps a pointer to a string in
// read-only memory and copies every other string, so `msg` may be a buffer on
// the caller's stack. Callers check zephyr_swift_log_enabled() first.
//
// The format string and the arguments are made the way the LOG_* macros make
// them for a runtime message, so that CONFIG_LOG_USE_TAGGED_ARGUMENTS, which
// needs every argument preceded by its type tag, and CONFIG_LOG_FMT_SECTION,
// which keeps the format string in a dedicated section, work too.
static inline void
zephyr_swift_log_message(uint32_t level,
                         const char *ZEPHYR_NULL_TERMINATED msg) {
  Z_LOG_MSG_STR_VAR(_fmt, "%s", msg)
  z_log_msg_runtime_create(
      Z_LOG_LOCAL_DOMAIN_ID, zephyr_swift_log_source(), (uint8_t)level, NULL, 0,
      Z_LOG_MSG_CBPRINTF_FLAGS(0) | (IS_ENABLED(CONFIG_LOG_USE_TAGGED_ARGUMENTS)
                                         ? CBPRINTF_PACKAGE_ARGS_ARE_TAGGED
                                         : 0),
      Z_LOG_FMT_RUNTIME_ARGS(_fmt, "%s", msg));
}
#elif defined(CONFIG_LOG)
// CONFIG_LOG_MODE_MINIMAL: nothing to log into (see the top of this file).
static inline bool zephyr_swift_log_enabled(uint32_t level) {
  (void)level;
  return false;
}

static inline void
zephyr_swift_log_message(uint32_t level,
                         const char *ZEPHYR_NULL_TERMINATED msg) {
  (void)level;
  (void)msg;
}
#endif
