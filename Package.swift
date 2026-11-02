// swift-tools-version: 6.4
// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

// The Swift packages of zephyr-lang-swift. Dependencies flow ZephyrCore (the
// Zephyr C APIs as a Clang module) <- ZephyrSystem <- Zephyr <-
// ZephyrApplication <- the application.
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
  .enableExperimentalFeature("CImplementation"),
  .enableExperimentalFeature("Embedded"),
  .enableExperimentalFeature("Extern"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
  name: "zephyr-lang-swift",
  products: [
    .library(name: "ZephyrCore", targets: ["ZephyrCore"]),
    .library(name: "Zephyr", targets: ["Zephyr"]),
    .library(name: "ZephyrApplication", targets: ["ZephyrApplication"]),
    .library(name: "ZephyrSystem", targets: ["ZephyrSystem"]),
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
        .target(name: "Zephyr")
      ],
      path: "zephyr/src",
      swiftSettings: settings,
    ),
    .target(
      name: "ZephyrSystem",
      dependencies: [
        .target(name: "ZephyrCore")
      ],
      path: "zephyr-sys/src",
      swiftSettings: settings,
    ),
    .systemLibrary(name: "ZephyrCore", path: "zephyr-sys/include"),
  ],
  swiftLanguageModes: [.v6],
)
