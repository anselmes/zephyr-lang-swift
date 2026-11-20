---
name: add-library
description: >
  This skill should be used when the user wants to add a library, component or reusable Swift module to an existing Zephyr
  Swift project built on zephyr-lang-swift, for example "add a library", "new Swift module" or "add a ledstrip component".
  It adds a Kconfig-gated target under lib/<module>/ to the project's root Package.swift, with its CMake, Kconfig and
  zephyr/module.yml wiring and a Swift source file, and can enable it in an existing app. Not for applications (use add-app)
  or new repositories (use new-project).
license: GPL-3.0
metadata:
  author: Schubert Anselme
  version: 0.1.1
---

# Add a library

Adds one library under `lib/<module>/` to an existing Zephyr Swift project. It follows `samples/lib` and `samples/app+lib/lib`
in zephyr-lang-swift.

## 1. Read the references

[Conventions](../../references/conventions.md) and [Library](references/library.md). If either is missing or unreadable,
stop and name the missing file instead of guessing.

## 2. Gather the inputs

Infer what you can, then ask the user one combined question listing every missing input (see conventions):

- **Name**: one input, such as `sensor-hub`, from which you derive `__Module__` (Swift module, `UpperCamelCase`: `SensorHub`), `__module__` (directory, `sensor_hub`)
  and `__MODULE__` (Kconfig symbol, `SENSOR_HUB`).
  Stop if `lib/__module__/` exists or the symbol is already declared in the project. Also search Zephyr and its west modules for `config __MODULE__`
  (for example `grep -rn "^config __MODULE__$" "$ZEPHYR_BASE" <west module directories>`): a symbol Zephyr already defines, such as `SENSOR`, would enable
  this library whenever that Zephyr feature is on, so ask for another name. Also refuse a module name that matches `Zephyr`, `ZephyrCore`, `ZephyrSystem`,
  `ZephyrApplication` or a standard library module.
- **Description**: one sentence for the Kconfig help and the DocC comment.
- **Apps**: which existing apps enable it (see "Enable it in an app" in the Library reference); none is fine.
- **License, author, year**: from `hack/copyright.txt` or an existing source file.
- **Project name** (`__name__`): from `west.yml` or the Git remote, for `zephyr/module.yml` and the root `Package.swift` when they do not exist yet;
  otherwise the `name` already in the root `Package.swift`. Derive `__NAME__` from it (uppercase, `_` for `-`).
- **zephyr-lang-swift revision** (`__swift-rev__`): from the `zephyr-lang-swift` project in `west.yml`, else
  `gh api repos/anselmes/zephyr-lang-swift/commits/main --jq .sha`. Never guess it. `__lang-swift-path__` is `../modules/lang/swift` for the root `Package.swift`.

## 3. Write it

Follow `references/library.md`, honoring the project's `.editorconfig` (see conventions). Replace every `__token__`; the output must contain none.
Create the module wiring only if it is missing; never overwrite an existing `Package.swift`, `lib/CMakeLists.txt`, `lib/Kconfig`, `Kconfig`
or `zephyr/module.yml`, add to them.

## 4. Verify

Format first, then lint: `swift format format --in-place --recursive` on `Package.swift` and the new sources, then `swift format lint --recursive --strict` on the new sources and `Package.swift`.
Run `ZEPHYR_LANG_SWIFT_PATH=<workspace>/modules/lang/swift swift package describe` at the project root.
Build an app that enables the library (`west build -p -d .build -b <board> <app>`), as the conventions describe. If no app enables it, report the build as skipped,
print the command, and say that the library's own code was not compiled. Do not commit; tell the user what was created and how to enable it
(`/zephyr-swift:add-app` for a new app that imports it).
