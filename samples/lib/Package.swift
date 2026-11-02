// swift-tools-version: 6.4
// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

// The standalone library sample: the Hello library as a package of its own.
// An application uses it by adding this package to its own manifest and
// depending on the `Hello` product; its `swift build` then compiles Hello
// with the application's toolset.

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
  name: "sample-lib",
  products: [
    .library(name: "Hello", targets: ["Hello"])
  ],
  dependencies: [
    .package(name: "zephyr-lang-swift", path: "../..")
  ],
  targets: [
    .target(
      name: "Hello",
      dependencies: [
        .product(name: "Zephyr", package: "zephyr-lang-swift")
      ],
      path: "hello",
      exclude: ["CMakeLists.txt", "Kconfig"],
      swiftSettings: settings,
    )
  ],
  swiftLanguageModes: [.v6],
)
