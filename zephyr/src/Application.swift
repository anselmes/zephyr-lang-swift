// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

@_cdecl("main")
public func main() {
  #if SWIFT_DEBUG_INFO
    print("Debug info enabled")
  #endif
  entrypoint()
}
