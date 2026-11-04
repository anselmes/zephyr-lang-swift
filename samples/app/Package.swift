// swift-tools-version: 6.4
// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

// The Swift application sample. `west build` runs `swift build --product app`
// through zephyr_swift_application() and links the static `app` library into
// the Zephyr image; the target triple, Zephyr include paths and Kconfig
// defines come from the toolset that CMake writes for the build.

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
  name: "sample-app",
  products: [
    .library(name: "app", type: .static, targets: ["App"])
  ],
  dependencies: [
    .package(name: "zephyr-lang-swift", path: "../..")
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .product(name: "Zephyr", package: "zephyr-lang-swift"),
        .product(name: "ZephyrApplication", package: "zephyr-lang-swift"),
      ],
      path: "src",
      swiftSettings: settings,
    )
  ],
  swiftLanguageModes: [.v6],
)
