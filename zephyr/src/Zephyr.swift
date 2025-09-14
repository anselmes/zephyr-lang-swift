// SPDX-Licence-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

@_silgen_name("msleep")
func msleep(_ ms: Int32) -> Int32

public func sleep(_ milliseconds: Int32) {
  _ = msleep(milliseconds)
}
