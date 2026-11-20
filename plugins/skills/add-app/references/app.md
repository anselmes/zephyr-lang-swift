# Application

## Files

| Template                                  | Written to                     | Notes                                                                                |
| ----------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------ |
| `templates/CMakeLists.txt`                | `__app__/CMakeLists.txt`       | Fill `__extra-modules__` (below)                                                     |
| `templates/prj.conf`                      | `__app__/prj.conf`             | Fill `__library-configs__`                                                           |
| `templates/sample.yaml`                   | `__app__/sample.yaml`          | Twister metadata (it only finds `sample.yaml`); `build_only` until Ztest cases exist |
| `templates/example.env`                   | `__app__/example.env`          | Copy to `.env`; skip if the project root already has an `example.env`                |
| `templates/src/Entrypoint.swift.template` | `__app__/src/Entrypoint.swift` | Fill `__library-imports__`                                                           |
| `templates/Package.swift.template`        | `__app__/Package.swift`        | Fill `__library-package__` and `__library-products__`                                |

## Tokens specific to this skill

- `__extra-modules__`: when the project root is itself a Zephyr module (it has `zephyr/module.yml`, as created by `new-project`),
  the line `list(APPEND ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_LIST_DIR}/<up>)` (append, so modules passed with `-D` survive) so the app sees the project's libraries, where `<up>` is the relative path from
  the app directory to the directory holding `zephyr/module.yml` (`..` for `app/`, `../..` for `apps/blinky`). Detect that directory by walking up from the app. Otherwise remove the token's line.
- `__lang-swift-path__`: where the zephyr-lang-swift checkout is, relative to the app directory, for the manifest's fallback when CMake does not set
  `ZEPHYR_LANG_SWIFT_PATH` (an IDE or SourceKit-LSP). It is `<up>/../modules/lang/swift` with `<up>` as above (`..` for `app/` gives `../../modules/lang/swift`); a
  west workspace keeps `modules/lang/swift` beside the manifest repository.
- `__toolchain__` and `__toolchain-note__` (in `example.env`): `zephyr/llvm` and "Zephyr SDK LLVM toolchain" by default; `zephyr` and "esp32 HAL needs the GNU toolchain: west sdk install --gnu-toolchains <arch>" for `esp32*` boards.
- `__swift-rev__`: the pinned `zephyr-lang-swift` revision for the remote fallback, never a branch.
- `__library-configs__`: one `CONFIG___MODULE__=y` line per library the app enables; remove the token's line when there are none.
- `__library-imports__`: one `import __Module__` line per enabled library, placed after `import Zephyr`; remove the token's line when none.
- The filled `Package.swift` follows the manifest layout in the conventions. Keep `dependencies` and the `App` target's `dependencies` in
  alphabetical order: the library entries go before or after the zephyr-lang-swift ones according to the package name.
- `__library-package__`: when the app enables a library, `.package(name: "__name__", path: "<up>"),` for the project's root `Package.swift` (the
  package that `add-library` writes, named `__name__` there), with the same `<up>` as `__extra-modules__`. Remove the token's line when there are none.
- `__library-products__`: one `.product(name: "__Module__", package: "__name__"),` line per enabled library; remove the token's line when none.

## Rules

- The app is a Swift package: `zephyr_swift_application()` runs `swift build --product app` for the nearest `Package.swift` at or above the app
  directory and links the static `app` library. The `App` target's `path` is `src`, so every Swift file belongs there, not beside `CMakeLists.txt`.
- The manifest holds only the Embedded Swift `settings`, declared before `package`. Never add `unsafeFlags`, a `platforms` entry, `-target` or include
  paths: CMake writes those to the build's toolset. `localOrRemotePackage` resolves zephyr-lang-swift through `ZEPHYR_LANG_SWIFT_PATH`, which CMake sets
  to the checkout `west build` uses; keep it.
- Another SwiftPM package may be added to `dependencies` if it builds with Embedded Swift for a bare-metal target; commit the `Package.resolved` the
  first build writes (zephyr-lang-swift itself is a path dependency under `west build`, so only remote packages appear in it).
- `entrypoint()` is `@c(entrypoint)` and never returns; the `main()` that calls it is in the Zephyr module's `Application.swift`.
  Do not define another `main`.
- Sleep with `sleep(Duration.milliseconds(...))` from `Zephyr`; never busy-wait.
- Apps may define a `Kconfig` only to add application options; keep `CONFIG_SWIFT=y`, `CONFIG_MINIMAL_LIBC=y` and the nonzero malloc arena in `prj.conf`.
- The generated `CMakeLists.txt` is deliberately terser than `samples/app/CMakeLists.txt`: it keeps the same environment handling and drops the explanatory header.
- `example.env` sets `ZEPHYR_TOOLCHAIN_VARIANT="zephyr/llvm"`, except for `esp32*` boards, which need `"zephyr"` and the GNU toolchain.
- Boards, toolchain and paths come from the environment (`ZEPHYR_BOARD`, `ZEPHYR_TOOLCHAIN_VARIANT`, `CROSS_COMPILE`, `SYSROOT_DIR`);
  never hard-code them in `CMakeLists.txt`.
