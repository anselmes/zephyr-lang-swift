// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

/// Raises a fatal kernel panic through Zephyr's `k_panic()`.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c @implementation
public func swift_panic_wrap() {
  zephyr_panic()
}
