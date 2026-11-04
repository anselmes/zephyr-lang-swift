// swift-tools-version: 6.4
// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

// The Swift packages of zephyr-lang-swift. Dependencies flow ZephyrSystem (the
// Zephyr C APIs as a Clang module) <- ZephyrCore <- Zephyr <-
// ZephyrApplication <- the application.
//
// ZephyrSystem holds all C (headers and the declarations Swift implements);
// ZephyrCore is the only Swift that touches it. ZephyrSystem is not a product:
// other packages depend on ZephyrCore and never import ZephyrSystem.
//
// This manifest does not build on its own: the target triple, the Zephyr
// include paths, the Kconfig defines and -Osize differ per Zephyr build, so
// the module's CMakeLists.txt writes them to a SwiftPM toolset and runs
// `swift build` from `west build`. Keeping unsafe flags out of the manifest
// lets other packages depend on it by URL.

import PackageDescription

// The Embedded Swift settings of every target. Declared before `package`:
// top-level manifest code runs in order, so a later declaration would still
// be empty when `package` reads it.
let settings: [SwiftSetting] = [
  .strictMemorySafety(),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .enableExperimentalFeature("CImplementation"),
  .enableExperimentalFeature("Embedded"),
  .enableExperimentalFeature("Extern"),
]

let package = Package(
  name: "zephyr-lang-swift",
  products: [
    .library(name: "Zephyr", targets: ["Zephyr"]),
    .library(name: "ZephyrApplication", targets: ["ZephyrApplication"]),
    .library(name: "ZephyrCore", targets: ["ZephyrCore"]),
  ],
  targets: [
    .target(
      name: "Zephyr",
      dependencies: [
        .target(name: "ZephyrCore"),
        .target(name: "ZephyrSystem"),
      ],
      path: "zephyr/lib",
      swiftSettings: settings,
    ),
    .target(
      name: "ZephyrApplication",
      dependencies: [
        .target(name: "Zephyr"),
        .target(name: "ZephyrSystem"),
      ],
      path: "zephyr/src",
      swiftSettings: settings,
    ),
    .target(
      name: "ZephyrCore",
      dependencies: [
        .target(name: "ZephyrSystem")
      ],
      path: "zephyr-sys/src",
      swiftSettings: settings,
    ),
    .systemLibrary(name: "ZephyrSystem", path: "zephyr-sys/include"),
  ],
  swiftLanguageModes: [.v6],
)
