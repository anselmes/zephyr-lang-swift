# Agent and Contributor Guide

This file is the engineering guide for `__name__`, for people and for coding agents alike. `CLAUDE.md` is a symlink to it, so there is exactly
one copy. Change the rules here. Anything not stated here follows the owner's global guide (`~/.claude/AGENTS.md`).

## What this repository is

__description__ It is an Embedded Swift application on Zephyr RTOS, built on the `zephyr-lang-swift` module.

## Layout

| Path                | Purpose                                                                                |
| ------------------- | -------------------------------------------------------------------------------------- |
| `west.yml`          | West manifest: Zephyr and `zephyr-lang-swift`                                          |
| `app/`              | The application: `Package.swift`, `CMakeLists.txt`, `prj.conf`, `src/Entrypoint.swift` |
| `lib/`              | Library modules, each gated by a Kconfig symbol                                        |
| `Package.swift`     | The libraries' Swift package: one target and product per `lib/` module                 |
| `zephyr/module.yml` | Makes the repository root a Zephyr module                                              |
| `tests/`            | Ztest/Twister cases                                                                    |

## Conventions

- **License**: `__license__`. Start every new source file with:

  ```swift
  // SPDX-License-Identifier: __license__
  // Copyright (c) __year__ __author__
  ```

- **Commits**: conventional commits (`feature`, not `feat`), `!` for breaking changes. Every commit is GPG-signed (`git commit -S`); never bypass
  signing. Commits Claude wrote carry `Co-authored-by: Claude <81847+claude@users.noreply.github.com>`.
- **Swift**: 6.4, Embedded Swift: no `async`/`await`, actors, `Codable` or existentials; no heap in ISRs. One type per file. Typed throws
  (`throws(E)`), never `Result`; wrap `-errno` returns with `try check(_:)`. Implicit member syntax where the type is inferable.
  Annotate unsafe pointer use with `// SAFETY:`. Format with `swift format` and `trunk fmt`.
- **Configuration**: board and toolchain come from `.env` (copy `app/.env.example`); never commit `.env`, keys or certificates.
- **Swift packages**: `west build` builds the Swift code with SwiftPM. Manifests hold only the Embedded Swift `settings`, declared before
  `package`; never add `unsafeFlags`, `platforms` or include paths, which zephyr-lang-swift's CMake writes to the build's toolset. Commit
  `Package.resolved` when a manifest uses a package by URL. To iterate on Swift alone: `west build -t swift_build`, then
  `.build/swift/swift-build.sh`.

## Build and test

```bash
west init -l .
west update
west build -p -b __board__ app
west twister -T tests
```

The build must succeed, and the tests pass, without new warnings before a PR merges.

## Pull requests

Multi-part work goes up as a `gh stack` of PRs, one concern per layer. Use `gh stack view --json`, `gh stack submit --auto` and
`gh stack rebase --upstack`; re-verify signatures after every rebase.

## Dependencies

No third-party Swift packages: only the Embedded Swift standard library and the Zephyr C APIs. Ask before adding anything else.
