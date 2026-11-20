---
name: add-app
description: >
  This skill should be used when the user wants to add an application to an existing Zephyr Swift project built on
  zephyr-lang-swift, for example "add an app", "add another application", "new firmware image", "add a board target" or
  "create an app for esp32c6". It creates the app's Package.swift, CMakeLists.txt with zephyr_swift_application(), prj.conf,
  sample.yaml, example.env and src/Entrypoint.swift. Not for starting a new repository (use new-project) or for adding a
  library (use add-library).
license: GPL-3.0
metadata:
  author: Schubert Anselme
  version: 0.1.1
---

# Add an application

Adds one application directory (default `app/`) to an existing Zephyr Swift project. It mirrors `samples/app` and `samples/app+lib`
in zephyr-lang-swift.

## 1. Read the references

[Conventions](../../references/conventions.md) and [Application](references/app.md). If either is missing or unreadable,
stop and name the missing file instead of guessing.

## 2. Gather the inputs

Infer what you can, then ask the user one combined question listing every missing input (see conventions). When `new-project` calls
this skill, reuse the inputs it already gathered and do not ask again:

- **Directory and name**: `__app__` (default `app`; may be nested, such as `apps/blinky`) and `__project__`, its basename with any character outside `[A-Za-z0-9_]` replaced by `_`. CMake derives target names from the project name, so it must not contain a slash. Stop if the directory exists and is not empty.
- **Project name**: `__name__` from the root `Package.swift` `name` (the package `add-library` writes), else from `west.yml` or the Git remote. Derive `__NAME__` from it (uppercase, `_` for `-`).
- **Title**: a human-readable name for `sample.yaml` and the greeting (`__Title__`). Any text is allowed, so never insert it raw: `sample.yaml` takes `__Title-yaml__` and the greeting takes `__Title-swift__`, each escaping backslashes and double quotes for its own syntax and refusing newlines.
- **Board**: `__board__`, from `.env`/`example.env` if present; otherwise ask. For an `esp32*` board the LLVM toolchain cannot build the HAL: write `ZEPHYR_TOOLCHAIN_VARIANT="zephyr"` in `example.env` and tell the user to install the GNU toolchain (`west sdk install --gnu-toolchains <arch>`).
- **Libraries**: which of the project's `lib/` modules the app enables. List their `CONFIG___MODULE__` symbols from `lib/Kconfig` and their Swift module names (`__Module__`) from the product names in the root `Package.swift`. None is fine.
- **zephyr-lang-swift revision**: `__swift-rev__` from the project's `west.yml` (the `zephyr-lang-swift` project's `revision`), else look up the latest commit with `gh api repos/anselmes/zephyr-lang-swift/commits/main --jq .sha`. Never guess it. `__lang-swift-path__` is the relative path from the app directory to the checkout: the `<up>` prefix plus `../modules/lang/swift` (see the Application reference).
- **License, author, year**: from `hack/copyright.txt` or an existing source file.

## 3. Write it

Fill the templates in `templates/` as `references/app.md` describes, honoring the project's `.editorconfig` (see conventions). Replace every `__token__`; the output must contain none.
Do not overwrite `.env`; only create `example.env` when missing and tell the user to copy it to `.env`.

## 4. Verify

Follow the verification rules in the conventions: `west build -p -d .build -b __board__ __app__` when `west` is present.
Format first, then lint: `swift format format --in-place --recursive` on `Package.swift` and `src/`, then `swift format lint --recursive --strict` on `src/` and `Package.swift`.
Run `ZEPHYR_LANG_SWIFT_PATH=<workspace>/modules/lang/swift swift package describe --package-path __app__`, so SwiftPM uses the local checkout instead of fetching it.
Do not commit; tell the user what was created and what to run next (`/zephyr-swift:add-library` for a library the app can import).
