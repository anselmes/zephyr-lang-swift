# Application

## Files

| Template                                  | Written to                     | Notes                                                                                |
| ----------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------ |
| `templates/CMakeLists.txt`                | `__app__/CMakeLists.txt`       | Fill `__extra-modules__` (below)                                                     |
| `templates/prj.conf`                      | `__app__/prj.conf`             | Fill `__library-configs__`                                                           |
| `templates/sample.yml`                    | `__app__/sample.yaml`          | Twister metadata (it only finds `sample.yaml`); `build_only` until Ztest cases exist |
| `templates/env.example`                   | `__app__/.env.example`         | Copy as `.env.example`; skip if a project-level one exists                           |
| `templates/src/Entrypoint.swift.template` | `__app__/src/Entrypoint.swift` | Fill `__library-imports__`                                                           |
| `templates/Package.swift.template`        | `__app__/Package.swift`        | Fill `__library-package__` and `__library-products__`                                |

## Tokens specific to this skill

- `__extra-modules__`: when the project root is itself a Zephyr module (it has `zephyr/module.yml`, as created by `new-project`),
  the line `list(APPEND ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_LIST_DIR}/<up>)` (append, so modules passed with `-D` survive) so the app sees the project's libraries, where `<up>` is the relative path from
  the app directory to the directory holding `zephyr/module.yml` (`..` for `app/`, `../..` for `apps/blinky`). Detect that directory by walking up from the app. Otherwise remove the token's line.
- `__library-configs__`: one `CONFIG___MODULE__=y` line per library the app enables; remove the token's line when there are none.
- `__library-imports__`: one `import __Module__` line per enabled library, placed after `import Zephyr`; remove the token's line when none.
- `__library-package__`: when the app enables a library, `.package(name: "__name__", path: "<up>"),` for the project's root `Package.swift` (the
  package that `add-library` writes, named `__name__` there), with the same `<up>` as `__extra-modules__`. Remove the token's line when there are none.
- `__library-products__`: one `.product(name: "__Module__", package: "__name__"),` line per enabled library; remove the token's line when none.

## Rules

- The app is a Swift package: `zephyr_swift_application()` runs `swift build --product App` for the nearest `Package.swift` at or above the app
  directory and links the static `App` library. The `App` target's `path` is `src`, so every Swift file belongs there, not beside `CMakeLists.txt`.
- The manifest holds only the Embedded Swift `settings`, declared before `package`. Never add `unsafeFlags`, a `platforms` entry, `-target` or include
  paths: CMake writes those to the build's toolset. `zephyrLangSwift()` resolves zephyr-lang-swift through `ZEPHYR_LANG_SWIFT_PATH`, which CMake sets
  to the checkout `west build` uses; keep it.
- Another SwiftPM package may be added to `dependencies` if it builds with Embedded Swift for a bare-metal target; commit the `Package.resolved` the
  first build writes.
- `entrypoint()` is `@c(entrypoint)` and never returns; the `main()` that calls it is in the Zephyr module's `Application.swift`.
  Do not define another `main`.
- Sleep with `sleep(Duration.milliseconds(...))` from `Zephyr`; never busy-wait.
- Apps may define a `Kconfig` only to add application options; keep `CONFIG_SWIFT=y`, `CONFIG_MINIMAL_LIBC=y` and the nonzero malloc arena in `prj.conf`.
- Boards, toolchain and paths come from the environment (`ZEPHYR_BOARD`, `ZEPHYR_TOOLCHAIN_VARIANT`, `CROSS_COMPILE`, `SYSROOT_DIR`);
  never hard-code them in `CMakeLists.txt`.
