// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// Reserved initialization hook for the ZephyrCore runtime support.
///
/// Implements `zephyr_sys_init`, declared in `ZephyrSystem.h`, with
/// `@c @implementation`, so the compiler checks the signature against the C
/// declaration. The hook is empty because the runtime support in this module
/// (`posix_memalign`) is stateless, and nothing calls it yet.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c @implementation
public func zephyr_sys_init() {}
