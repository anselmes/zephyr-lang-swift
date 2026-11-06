// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

// Bounds annotations from clang's <ptrcheck.h>. Swift imports a pointer that
// carries `ZEPHYR_COUNTED_BY` or `ZEPHYR_SIZED_BY`, together with its length
// parameter, as a `Span` or `MutableRawSpan`. `ZEPHYR_NULL_TERMINATED` marks a
// C string: Swift keeps it a pointer, but the contract is declared and checked
// by compilers that enforce bounds. All of them expand to nothing where the
// header is missing.

#pragma once

#if __has_include(<ptrcheck.h>)
#include <ptrcheck.h>
#define ZEPHYR_COUNTED_BY(n) __counted_by(n)
#define ZEPHYR_SIZED_BY(n) __sized_by(n)
#define ZEPHYR_NULL_TERMINATED __null_terminated
#define ZEPHYR_NOESCAPE __attribute__((noescape))
#else
#define ZEPHYR_COUNTED_BY(n)
#define ZEPHYR_SIZED_BY(n)
#define ZEPHYR_NULL_TERMINATED
#define ZEPHYR_NOESCAPE
#endif
