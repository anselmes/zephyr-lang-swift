// swift-tools-version: 6.4
// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

// The application-with-library sample: the Hello library (lib/hello) and the
// application that uses it (app/src), in one package. `west build` in app/
// runs `swift build --product App` through zephyr_swift_application(), which
// finds this manifest in the parent directory, and links the static `App`
// library (application, Hello and the zephyr-lang-swift modules) into the
// Zephyr image.

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
  name: "sample-app-lib",
  products: [
    .library(name: "App", type: .static, targets: ["App"]),
    .library(name: "Hello", targets: ["Hello"]),
  ],
  dependencies: [
    .package(name: "zephyr-lang-swift", path: "../..")
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .target(name: "Hello"),
        .product(name: "Zephyr", package: "zephyr-lang-swift"),
        .product(name: "ZephyrApplication", package: "zephyr-lang-swift"),
      ],
      path: "app/src",
      swiftSettings: settings,
    ),
    .target(
      name: "Hello",
      dependencies: [
        .product(name: "Zephyr", package: "zephyr-lang-swift")
      ],
      path: "lib/hello",
      exclude: ["CMakeLists.txt", "Kconfig"],
      swiftSettings: settings,
    ),
  ],
  swiftLanguageModes: [.v6],
)
