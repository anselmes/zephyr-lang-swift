// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr

public struct Hello {
  public static func run(timeout: Int = 1000) {
    #if SWIFT_DEBUG_INFO
      print("Module Hello compiled with debug info")
    #endif
    hello(timeout: timeout)
  }
}

public func hello(timeout: Int = 1000) {
  print("Hello from Swift!!!")

  let duration = Duration.milliseconds(timeout)

  while true {
    sleep(duration)
    print("still running...")
  }
}
