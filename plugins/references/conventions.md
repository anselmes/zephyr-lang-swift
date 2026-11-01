# Conventions for generated code

Every zephyr-swift skill generates code that follows these rules. Read this file before writing any file, and check the result against it before finishing.

## Contents

- [Inputs](#inputs)
- [Lookups](#lookups)
- [Tokens](#tokens)
- [Swift files](#swift-files)
- [Zephyr rules](#zephyr-rules)
- [Formatting](#formatting)
- [Verifying](#verifying)
- [Finishing](#finishing)

## Inputs

Infer every input before asking. Read, in order:

1. `west.yml` (or the manifest repository's): project name, the `zephyr-lang-swift` project and its revision.
2. `git remote get-url origin`: the owner and repository name (`github.com/<owner>/<name>`).
3. `hack/copyright.txt`, or else the SPDX header of an existing source file: the license and the copyright line. With neither, use `GPL-3.0`
   and the Git `user.name` and `user.email`.
4. Existing sources: the application and library directories, Kconfig symbols and module names already used.
5. `.env` or `.env.example`: the board (`ZEPHYR_BOARD`).

Ask only for what is still missing, in a single `AskUserQuestion` round, offering the inferred value as the first, recommended option.
Never ask follow-up questions one at a time. If something an input depends on cannot be found locally or with `gh repo view`, ask for its path
or URL in that same round.

## Lookups

Release tags, commit SHAs, digests and checksums are looked up when the skill runs (`gh api`, `gh release list`), never recalled. If a lookup fails
(no network, unexpected response, `gh` missing or unauthenticated), stop and report the command and its output; never substitute a guessed,
remembered or placeholder value.

## Tokens

Templates use `__token__` placeholders. Replace every one; none may remain in the output (`grep -rn '__[a-zA-Z-]*__' . | grep -v '"__copyright__"'` must find nothing; the `.swift-format` key `__copyright__` is a real key, not a token).

| Token             | Meaning                                                     | Example                                 |
| ----------------- | ----------------------------------------------------------- | --------------------------------------- |
| `__name__`        | Repository name                                             | `blinky`                                |
| `__owner__`       | GitHub owner                                                | `anselmes`                              |
| `__app__`         | Application directory and CMake project name                | `app`                                   |
| `__Module__`      | Swift module name of a library, `UpperCamelCase`            | `Sensor`                                |
| `__module__`      | Directory name of a library, lowercase                      | `sensor`                                |
| `__MODULE__`      | Kconfig symbol, uppercase, no `CONFIG_` prefix              | `SENSOR`                                |
| `__board__`       | Zephyr board identifier                                     | `esp32c6_devkitc`                       |
| `__year__`        | Copyright year                                              | `2026`                                  |
| `__author__`      | Author name and email                                       | `Schubert Anselme <schubert@anselm.es>` |
| `__license__`     | SPDX license identifier                                     | `GPL-3.0`                               |
| `__zephyr-rev__`  | Zephyr revision, looked up                                  | a release tag                           |
| `__zephyr-owner__` | GitHub owner of the Zephyr source (default `anselmes`)     | `anselmes`                              |
| `__zephyr-repo__` | Repository name of the Zephyr source (default `zephyr`)     | `zephyr`                                |
| `__swift-rev__`   | `zephyr-lang-swift` revision, looked up                     | a tag or commit SHA                     |
| `__Title__`       | Human-readable application name                             | `Blinky`                                |
| `__description__` | One-sentence description of the project or library          | `Blinks an LED.`                        |
| `__hal-module__`  | A HAL module the board needs; one allowlist line per module | `hal_espressif`                         |

## Swift files

- Start every file with the SPDX header for `__license__`:

  ```swift
  // SPDX-License-Identifier: __license__
  // Copyright (c) __year__ __author__
  ```

- Swift 6.4, Embedded Swift: no `async`/`await`, `Task`, actors, `Codable` or existentials; no heap in ISRs or tight loops.
- One type per file, named after the type; no `+` in file names.
- Typed throws, `throws(E)`; never `Result`, never `LocalizedError`. Error enums conform to `Error` and `Sendable` (no `Codable` in Embedded).
  Wrap Zephyr calls that return `-errno` with `try check(_:)`.
- Use `Kernel` and `k_timeout_t` from `ZephyrSystem` and `sleep(_:)` from `Zephyr`; do not re-implement them.
- Implicit member syntax (`.noWait`, `.init(...)`) wherever the type is inferable.
- Annotate every unsafe pointer operation with a `// SAFETY:` comment.
- `public` only for what other modules import; document every public symbol with a DocC comment.
- Format with `swift format` using the repository's `.swift-format` (2 spaces, 180 columns, trailing commas).

## Zephyr rules

- An application is a CMake project: `find_package(Zephyr ...)`, `project(__app__)`, then `zephyr_swift_application()`. Its Swift sources live in `src/`.
- A library is a Zephyr module: a `zephyr/module.yml` naming it and pointing `build.cmake` and `build.kconfig` at it, a `Kconfig` symbol that gates it,
  and a `CMakeLists.txt` calling `zephyr_swift_library(MODULE_NAME __Module__)` under `add_subdirectory_ifdef`. Apps enable it with `CONFIG___MODULE__=y`
  in `prj.conf` and see it through `ZEPHYR_EXTRA_MODULES`.
- `prj.conf` always has `CONFIG_SWIFT=y` and `CONFIG_MINIMAL_LIBC=y`.
- Board, toolchain and paths come from environment variables in `.env` (copied from `.env.example`, git-ignored); never hard-code them.
- `.env`, keys and certificates are never committed.

## Formatting

Every generated file honors the target project's `.editorconfig`: 2-space indentation (tabs only in a `Makefile`), LF line endings, UTF-8,
trailing whitespace trimmed (except in `.md`) and exactly one final newline. `new-project` keeps the `.editorconfig` that the
`anselmes/repository` template ships; `add-app` and `add-library` read the project's before writing and follow it if it differs.
Templates in this plugin already conform; when filling tokens, do not change the indentation or add lines that break these rules
(for example multi-line token values must be indented to match).

## Verifying

When `west` and the Zephyr SDK are present, build with the board from `.env` (or the one the user gave):

```bash
west build -p -b __board__ __app__
```

Fix failures your change caused and rebuild. If a failure persists after two attempts or comes from the environment, stop and report the exact command
output. When `west` is missing, say the build was skipped and print the command. Also run `swift format lint --recursive --strict` on the new
sources and `trunk check` when available.

## Finishing

Do not commit. Tell the user what was created, which `__token__` values were inferred, and what to run next. When they commit: signed (`git commit -S`),
a conventional-commit subject (`feature`, not `feat`), and a `Co-authored-by: Claude <81847+claude@users.noreply.github.com>` trailer.

Swift templates end in `.template` so linters skip their tokens; write the result without that suffix.
