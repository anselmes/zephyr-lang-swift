// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

public import ZephyrSystem

/// The application's `@c(entrypoint) func entrypoint()`, declared in `sys.h`.
///
/// ```swift
/// @c(main)
/// public func main() { Entrypoint.run() }
/// ```
public enum Entrypoint {
  /// Calls the application's `entrypoint()`.
  ///
  /// The body is emitted into the caller only, so a program that never calls
  /// it (one with its own `main`) has no reference to `entrypoint`.
  @export(implementation)
  public static func run() {
    entrypoint()
  }
}
