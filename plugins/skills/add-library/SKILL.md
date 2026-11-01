---
name: add-library
description: >
  Add a Swift library module to a Zephyr project built on zephyr-lang-swift: a Kconfig symbol, a CMake
  zephyr_swift_library() directory, wiring in lib/CMakeLists.txt, lib/Kconfig and zephyr/module.yml, and a Swift
  source file, optionally enabled by an app. Use when the user wants a new library, module, component or reusable
  Swift package in a Zephyr Swift project, or says "add a library".
license: GPL-3.0
metadata:
  author: Schubert Anselme
  version: 0.1.0
---

# Add a library

Adds one library under `lib/<module>/` to an existing Zephyr Swift project. It mirrors `samples/lib` and `samples/app+lib`
in zephyr-lang-swift.

## 1. Read the references

[Conventions](../../references/conventions.md) and [Library](references/library.md). If either is missing or unreadable,
stop and name the missing file instead of guessing.

## 2. Gather the inputs

Infer what you can, then ask the user one combined question listing every missing input (see conventions):

- **Name**: `__Module__` (Swift module, `UpperCamelCase`), `__module__` (directory) and `__MODULE__` (Kconfig symbol).
  Stop if `lib/__module__/` exists or the symbol is already declared.
- **Description**: one sentence for the Kconfig help and the DocC comment.
- **Apps**: which existing apps enable it (adds `CONFIG___MODULE__=y` and `import __Module__`); none is fine.
- **License, author, year**: from `hack/copyright.txt` or an existing source file.
- **Project name** (`__name__`): from `west.yml` or the Git remote, for `zephyr/module.yml` when it does not exist yet.

## 3. Write it

Follow `references/library.md`, honoring the project's `.editorconfig` (see conventions). Replace every `__token__`; the output must contain none.
Create the module wiring only if it is missing; never overwrite an existing `lib/CMakeLists.txt`, `lib/Kconfig`, `Kconfig`
or `zephyr/module.yml`, add to them.

## 4. Verify

Build an app that enables the library (`west build -p -b <board> <app>`), as the conventions describe, and run
`swift format lint --strict` on the new sources. Do not commit; tell the user what was created and how to enable it.
