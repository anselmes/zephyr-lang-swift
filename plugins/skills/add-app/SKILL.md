---
name: add-app
description: >
  Add a Swift application to a Zephyr project built on zephyr-lang-swift: a CMake project with
  zephyr_swift_application(), prj.conf, sample.yml, .env.example and a src/Entrypoint.swift with the
  @c(entrypoint) function. Use when the user wants a new app, application, firmware image or board target
  in a Zephyr Swift project, or says "add an app".
license: GPL-3.0
metadata:
  author: Schubert Anselme
  version: 0.1.0
---

# Add an application

Adds one application directory (default `app/`) to an existing Zephyr Swift project. It mirrors `samples/app` and `samples/app+lib`
in zephyr-lang-swift.

## 1. Read the references

[Conventions](../../references/conventions.md) and [Application](references/app.md). If either is missing or unreadable,
stop and name the missing file instead of guessing.

## 2. Gather the inputs

Infer what you can, then ask the user one combined question listing every missing input (see conventions):

- **Directory and name**: `__app__` (default `app`; the CMake project name). Stop if the directory exists and is not empty.
- **Title**: a human-readable name for `sample.yml` and the greeting (`__Title__`).
- **Board**: `__board__`, from `.env`/`.env.example` if present; otherwise ask.
- **Libraries**: which of the project's `lib/` modules the app enables (their `CONFIG___MODULE__` symbols and `import` names);
  list them from `lib/Kconfig`. None is fine.
- **License, author, year**: from `hack/copyright.txt` or an existing source file.

## 3. Write it

Fill the templates in `templates/` as `references/app.md` describes, honoring the project's `.editorconfig` (see conventions). Replace every `__token__`; the output must contain none.
Do not overwrite `.env`; only create `.env.example` when missing and tell the user to copy it.

## 4. Verify

Follow the verification rules in the conventions: `west build -p -b __board__ __app__` when `west` is present,
`swift format lint --strict` on `src/`. Do not commit; tell the user what was created and what to run next
(`/zephyr-swift:add-library` for a library the app can import).
