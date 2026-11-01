# Agent and Contributor Guide

This file is the engineering guide for `zephyr-lang-swift`, for people and for coding agents alike. `CLAUDE.md` is a symlink to it, so there is exactly one copy.
Change the rules here. Anything not stated here follows the owner's global guide (`~/.claude/AGENTS.md`).

## What this repository is

A Zephyr RTOS module that adds Embedded Swift support: C runtime stubs and thin kernel wrappers (`ZephyrSystem`), a high-level Swift library built on them (`Zephyr`),
and samples. It has no application or domain logic.

## Layout

| Path                        | Target / product | Purpose                                                                                                         |
| --------------------------- | ---------------- | --------------------------------------------------------------------------------------------------------------- |
| `zephyr-sys/src`            | `ZephyrSystem`   | Swift sources: `kernel.swift` (`Kernel`), `timeout.swift` (`k_timeout_t` helpers), `malloc.swift`, `init.swift` |
| `zephyr-sys/include`        | `ZephyrSystem`   | `BridgingHeader.h` (Zephyr C APIs and `@c @implementation` declarations) and `module.modulemap`                 |
| `zephyr/lib`                | `Zephyr`         | High-level library: `time/` (`Duration`, `Instant`, `Timeout`, `sleep`), `ZephyrError.swift`, `Check.swift`     |
| `zephyr/src`                | `Zephyr`         | `Application.swift`: the `@c(main)` entry point that calls the application's `entrypoint()`                     |
| `CMakeLists.txt`, `Kconfig` | —                | Target mapping, `swiftc` invocations, `CONFIG_SWIFT` and `CONFIG_SWIFT_DEBUG_INFO`                              |
| `zephyr/module.yml`         | —                | Zephyr module definition                                                                                        |
| `samples/{app,lib,app+lib}` | —                | Sample application, library and combined application with a library                                             |
| `tests/`                    | —                | Reserved for Ztest/Twister cases (empty today)                                                                  |
| `doc/`                      | —                | Documentation                                                                                                   |

`Zephyr` depends on `ZephyrSystem`, never the reverse. Code that only wraps a Zephyr C API or provides runtime support belongs in `ZephyrSystem`;
Swift-native abstractions over it belong in `Zephyr`.

## Build system

- Both libraries are compiled with a raw `swiftc` call inside `add_custom_command`, not by SwiftPM. Sources are globbed from `src/` and `lib/`, so a new file
  must live in one of those directories.
- `Zephyr` finds `ZephyrSystem.swiftmodule` through the `SWIFT_MODULE_DIR` property of the `ZephyrSystem` target and depends on `ZephyrSystem_swift_compile`.
  Keep that wiring when touching either `CMakeLists.txt`.
- The two `swiftc` flag lists (`zephyr-sys/CMakeLists.txt` and `zephyr/CMakeLists.txt`) must stay in step with each other.
- A `#if CONFIG_FOO` in Swift only works if CMake passes `-DCONFIG_FOO`. Today only `SWIFT_DEBUG_INFO` is passed, so `#if CONFIG_TIMEOUT_64BIT` code
  does not compile in until the define is added. Check before relying on a Kconfig symbol in an `#if`.
- Kconfig symbols are `CONFIG_SWIFT` (master switch) and `CONFIG_SWIFT_DEBUG_INFO`. Document new options in `Kconfig` and in `README.md`.

## Embedded Swift rules

Every Swift target is compiled with this flag set:

```text
-swift-version 6 -strict-memory-safety
-enable-upcoming-feature ExistentialAny
-enable-upcoming-feature InternalImportsByDefault
-enable-upcoming-feature MemberImportVisibility
-enable-experimental-feature Embedded
-enable-experimental-feature Extern
-enable-experimental-feature CImplementation
```

- Declare C interfaces in `BridgingHeader.h` and implement them in Swift with `@c @implementation`. Never use `@_cdecl`.
- No `async`/`await`, `Task` or actors. No `Codable` or runtime reflection. Avoid existentials and anything that allocates (`Array` growth, `String` building)
  in ISRs and tight loops.
- Annotate every unsafe pointer operation with a `// SAFETY:` comment stating the invariant.
- Use access-level imports: `public import ZephyrSystem` only when a public signature mentions a type from it (for example `k_timeout_t`).
- Prefer value types. Keep the Swift layer a thin bridge over the Zephyr C API.

## Conventions

- **License**: GPL-3.0. Start every new source file with:

  ```swift
  // SPDX-License-Identifier: GPL-3.0
  // Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>
  ```

  Code derived from Linaro's Zephyr Swift work keeps its Apache-2.0 header.

- **Commits**: conventional commits using the types in `.commitlintrc` (`feature`, not `feat`; also `build`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, …),
  sentence-case subject, `!` for breaking changes. Every commit is GPG-signed (`git commit -S`); never bypass signing. Commits Claude wrote carry
  `Co-authored-by: Claude <81847+claude@users.noreply.github.com>`. Check with `git log --format='%h %G? %s'`; every line must show `G`.
- **Swift**: 6.4+. Formatting follows `.swift-format` (2-space indent, 180 columns, trailing commas); run `trunk check` and `trunk fmt`.
- **Files**: one type per file, named after the type; no `+` in file names.
- **Style**: use implicit member syntax (`.noWait`, `.init(ticks:)`) wherever the type is inferable. It does not apply to namespaces such as `Kernel`
  or to arguments of generic parameters such as `sleep(_:)`.
- **Documentation**: every public symbol has a DocC comment. Keep `README.md` and `doc/` in step with the code in the same PR.
- **Secrets**: never commit keys, certificates or `.env` files; samples ship `.env.example` only.

## Errors and time

- Use typed throws, `throws(E)`. Never return `Result`, never throw a bare `Error` from public API, never conform to `LocalizedError`,
  and do not alias `Error` (it would shadow `Swift.Error`).
- `ZephyrError` is an enum (`Error`, `Sendable`, `Equatable`; no `Codable` in Embedded). Wrap Zephyr calls that return `-errno` with `try check(_:)`,
  which throws `ZephyrError`. New fallible wrappers use `throws(ZephyrError)`. Consume with a single `do` and one `catch` per case.
- Time: build on `k_timeout_t` (`.noWait`, `.forever`, `.init(_: Duration)`, `.absolute(ticks:)`) and `Kernel` from `ZephyrSystem` instead of re-implementing them.
  Tick conversion uses integer math; no `Double`. Two policies, kept separate:
  timeouts (`k_timeout_t.init(_: Duration)`, `Duration.kernelTicks`) round up, so a positive duration never becomes `K_NO_WAIT` (zero and negative durations do);
  instant arithmetic (`Duration.ticks`, `Instant.advance(by:)`) rounds to the nearest tick (`nearestKernelTicks`), so tick counts round-trip through `Duration`.
  Do not apply the round-up rule to instant arithmetic.

## Testing and verification

Today the check is a clean build of the samples; CI does not build or test yet (`.github/workflows/cicd.yml` runs only the bot, Trivy and Scorecard workflows).

```bash
west build -p -b <board> samples/app
west build -p -b <board> samples/app+lib
```

Both must compile without new warnings. New logic should come with Ztest/Twister cases under `tests/`, including negative and edge cases
(tick rounding, `check(_:)` mapping). Run them with `west twister -T tests`. No PR merges with failing builds or tests.

## Pull requests

Multi-part work goes up as a stack of PRs made with `gh stack`, one reviewable concern per layer, foundational work at the bottom.

```bash
git config remote.pushDefault anselmes   # the remote is not named origin
gh stack add feat/<topic>                # next layer, based on the current one
gh stack rebase --upstack                # after committing to a lower layer
gh stack view --json                     # never bare `gh stack view`
gh stack submit --auto
```

Edit a layer by checking it out, committing there and rebasing upstack; do not commit a lower layer's change on the top branch. Re-verify signatures
after every rebase. Request a review from the owner listed in `CODEOWNERS`.

## Dependencies

There are no third-party packages. Code uses the Embedded Swift standard library and the Zephyr C APIs exposed through `BridgingHeader.h`.
Ask before adding anything else.
