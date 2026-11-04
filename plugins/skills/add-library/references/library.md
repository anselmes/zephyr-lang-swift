# Library

## Files

| Template                                 | Written to                        | Notes                                                                              |
| ---------------------------------------- | --------------------------------- | ---------------------------------------------------------------------------------- |
| `templates/module/CMakeLists.txt`        | `lib/__module__/CMakeLists.txt`   | Calls `zephyr_swift_library(MODULE_NAME __Module__)`                               |
| `templates/module/Kconfig`               | `lib/__module__/Kconfig`          | Declares `__MODULE__`                                                              |
| `templates/module/Module.swift.template` | `lib/__module__/__Module__.swift` | Public API of the module                                                           |
| `templates/Package.swift.template`       | `Package.swift`                   | Only when missing; otherwise add the library's product and target (below)          |
| `templates/lib-CMakeLists.txt`           | `lib/CMakeLists.txt`              | Only when missing; otherwise append the `add_subdirectory_ifdef` line              |
| `templates/lib-Kconfig`                  | `lib/Kconfig`                     | Only when missing; otherwise add `rsource "__module__/Kconfig"` inside the menu    |
| `templates/Kconfig`                      | `Kconfig`                         | When missing; if one exists, add `rsource "lib/Kconfig"` once and keep its options |
| `templates/zephyr/module.yml`            | `zephyr/module.yml`               | Only when missing                                                                  |

An existing module may already build from other entry points. Keep its `zephyr/module.yml` `build.cmake` and `build.kconfig` paths and its other
`build.depends` entries, and extend the files they name:

- Add `lang-swift` to `build.depends` (create the list if missing). Without it Zephyr may load the module before `lang-swift`, and
  `zephyr_swift_library()` is an unknown command.
- Resolve each entry point relative to the module root: `build.cmake: zephyr` means `zephyr/CMakeLists.txt`, `build.kconfig: zephyr/Kconfig` means
  `zephyr/Kconfig`. Write paths relative to that file, not to the repository root, so with `build.cmake: zephyr` the line is
  `add_subdirectory_ifdef(CONFIG___MODULE__ ../lib/__module__ ${CMAKE_CURRENT_BINARY_DIR}/lib/__module__)`. A source directory outside the
  current one needs an explicit binary directory, or CMake fails at configuration.
- If the entry point already pulls in a `lib` tree (an existing `add_subdirectory(lib)` or `rsource "lib/Kconfig"`), extend that tree's
  `lib/CMakeLists.txt` and `lib/Kconfig` and add nothing to the entry point. Otherwise add the `add_subdirectory_ifdef` and `rsource` lines to the entry
  points themselves, and do not create a `lib/CMakeLists.txt` that nothing includes.

The project root is the Zephyr module: `zephyr/module.yml` points `build.cmake` at `lib` and `build.kconfig` at the root `Kconfig`.

## Rules

- A library is gated by its Kconfig symbol: `lib/CMakeLists.txt` adds its directory with `add_subdirectory_ifdef(CONFIG___MODULE__ __module__)`,
  so an app that does not enable it pays nothing.
- Follow the manifest layout in the conventions. In an existing root `Package.swift`, insert the product and the target at their alphabetical
  positions among the others, before any `.systemLibrary` target.
- The library is a target of the project's root `Package.swift`: `.library(name: "__Module__", targets: ["__Module__"])` in `products`, and a
  `.target(name: "__Module__", ...)` with `path: "lib/__module__"` and `exclude: ["CMakeLists.txt", "Kconfig"]` in `targets`, as in the template. SwiftPM
  compiles every `*.swift` under that directory as part of each app that depends on the product. Put sources there, with an `include/` directory only
  for C headers.
- `zephyr_swift_library()` compiles nothing. It exposes the library's `include/` to Zephyr and defines `CONFIG___MODULE__` for Swift code when the
  symbol is on.
- Only `public` declarations are visible to apps. Keep the API small, value types first, no heap and no `async` (Embedded Swift).
- A library imports `Zephyr` (and `ZephyrCore` for the kernel wrappers; never `ZephyrSystem`, the C module) and other libraries by module name. A library that uses another lists it in
  its target's `dependencies` (`.target(name: "Other")`); enable both and add `depends on`/`select` in the Kconfig for the other library's symbol.
- Fallible calls use `throws(E)` with an enum error type; never `Result`.
- Enabling: `CONFIG___MODULE__=y` in the app's `prj.conf`, `import __Module__` in its sources, and in the app's `Package.swift` the project package
  (`.package(name: "__name__", path: "<up>")`) and `.product(name: "__Module__", package: "__name__")`. The app's `CMakeLists.txt` must set
  `ZEPHYR_EXTRA_MODULES` to the module root so Zephyr finds the library's Kconfig option.
- Add a Ztest/Twister case under `tests/` for new logic when the project has a `tests/` directory.
