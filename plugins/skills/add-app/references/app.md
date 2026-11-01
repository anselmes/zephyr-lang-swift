# Application

## Files

| Template                                  | Written to                     | Notes                                                      |
| ----------------------------------------- | ------------------------------ | ---------------------------------------------------------- |
| `templates/CMakeLists.txt`                | `__app__/CMakeLists.txt`       | Fill `__extra-modules__` (below)                           |
| `templates/prj.conf`                      | `__app__/prj.conf`             | Fill `__library-configs__`                                 |
| `templates/sample.yml`                    | `__app__/sample.yaml`          | Twister metadata (it only finds `sample.yaml`); `build_only` until Ztest cases exist |
| `templates/env.example`                   | `__app__/.env.example`         | Copy as `.env.example`; skip if a project-level one exists |
| `templates/src/Entrypoint.swift.template` | `__app__/src/Entrypoint.swift` | Fill `__library-imports__`                                 |

## Tokens specific to this skill

- `__extra-modules__`: when the project root is itself a Zephyr module (it has `zephyr/module.yml`, as created by `new-project`),
  the line `list(APPEND ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_LIST_DIR}/<up>)` (append, so modules passed with `-D` survive) so the app sees the project's libraries, where `<up>` is the relative path from
  the app directory to the directory holding `zephyr/module.yml` (`..` for `app/`, `../..` for `apps/blinky`). Detect that directory by walking up from the app. Otherwise remove the token's line.
- `__library-configs__`: one `CONFIG___MODULE__=y` line per library the app enables; remove the token's line when there are none.
- `__library-imports__`: one `import __Module__` line per enabled library, placed after `import Zephyr`; remove the token's line when none.

## Rules

- `zephyr_swift_application()` globs `src/*.swift` of the app directory; every Swift file belongs there, not beside `CMakeLists.txt`.
- `entrypoint()` is `@c(entrypoint)` and never returns; the `main()` that calls it is in the Zephyr module's `Application.swift`.
  Do not define another `main`.
- Sleep with `sleep(Duration.milliseconds(...))` from `Zephyr`; never busy-wait.
- Apps may define a `Kconfig` only to add application options; keep `CONFIG_SWIFT=y`, `CONFIG_MINIMAL_LIBC=y` and the nonzero malloc arena in `prj.conf`.
- Boards, toolchain and paths come from the environment (`ZEPHYR_BOARD`, `ZEPHYR_TOOLCHAIN_VARIANT`, `CROSS_COMPILE`, `SYSROOT_DIR`);
  never hard-code them in `CMakeLists.txt`.
