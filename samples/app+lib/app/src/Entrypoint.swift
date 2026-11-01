// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Hello
import Zephyr

/// The application's entry point: prints a greeting, then hands over to the
/// Hello library.
///
/// The C `main` in `Application.swift` calls this function through the
/// `entrypoint` symbol, which `@c(entrypoint)` provides.
///
/// `hello()` never returns: it prints its own greeting and then
/// `still running...` every second. The `while true` loop after it is
/// therefore never reached; it shows the shape an application takes when
/// `hello()` is not called.
@c(entrypoint)
func entrypoint() {
  print("Hello from Swift app+lib!!!")
  hello()
  while true {
    sleep(Duration.milliseconds(2000))
  }
}
