// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

import Zephyr

let TIMEOUT_INTERVAL: Double = 1000
let SLEEP_DURATION = Duration.milliseconds(TIMEOUT_INTERVAL)

public func entrypoint() {
  print("Hello from Swift!!!")

  while true {
    sleep(SLEEP_DURATION)
    print("still running...")
  }
}
