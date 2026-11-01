// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr

/// The application's entry point: prints a greeting, then sleeps forever.
///
/// The C `main` in `Application.swift` calls this function through the
/// `entrypoint` symbol, which `@c(entrypoint)` provides. Every Swift
/// application defines one; the function never returns.
@c(entrypoint)
func entrypoint() {
  print("Hello from Swift!!!")
  while true {
    sleep(Duration.milliseconds(1000))
  }
}
