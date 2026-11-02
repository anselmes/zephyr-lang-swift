# Agent and Contributor Guide

This file is the engineering guide for `zephyr-lang-swift`, for people and for coding agents alike. `CLAUDE.md` is a symlink to it, so there is exactly one copy.
Change the rules here. Anything not stated here follows the owner's global guide (`~/.claude/AGENTS.md`).

## What this repository is

A Zephyr RTOS module that adds Embedded Swift support as a SwiftPM package: the Zephyr C APIs as a Clang module (`ZephyrCore`), C runtime stubs and thin
kernel wrappers (`ZephyrSystem`), a high-level Swift library built on them (`Zephyr`), the C `main` (`ZephyrApplication`), the CMake that builds an
application's package from `west build`, and samples. It has no application or domain logic.

## Layout

| Path                          | Target / product    | Purpose                                                                                                                           |
| ----------------------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `Package.swift`               | all four            | The root package: targets, products and the Embedded Swift `settings`; no per-build or unsafe flags                               |
| `zephyr-sys/include`          | `ZephyrCore`        | `BridgingHeader.h` (umbrella: Zephyr C APIs, `core.h` declarations for `@c @implementation`, `log.h`) and `module.modulemap`      |
| `zephyr-sys/src`              | `ZephyrSystem`      | Swift sources: `kernel.swift` (`Kernel`), `timeout.swift` (`k_timeout_t` helpers), `log.swift`, `malloc.swift`, `init.swift`      |
| `zephyr/lib`                  | `Zephyr`            | High-level library: `time/` (`Duration`, `Instant`, `Timeout`, `sleep`), `Log.swift`, `ZephyrError.swift`, `Check.swift`          |
| `zephyr/src`                  | `ZephyrApplication` | `Application.swift`: the `@c(main)` entry point that calls the application's `entrypoint()`                                       |
| `CMakeLists.txt`, `Kconfig`   | —                   | Target mapping, toolset generation, the `swift build` command and linking; `CONFIG_SWIFT` and `CONFIG_SWIFT_DEBUG_INFO`           |
| `zephyr/module.yml`           | —                   | Zephyr module definition                                                                                                          |
| `samples/{app,lib,app+lib}`   | —                   | Sample application, standalone library module, and a module with the library plus the application using it (`app+lib/app`)        |
| `tests/`                      | —                   | Reserved for Ztest/Twister cases (empty today)                                                                                    |
| `doc/`                        | —                   | Documentation                                                                                                                     |
| `plugins/`, `.claude-plugin/` | `zephyr-swift`      | Claude Code plugin (`new-project`, `add-app`, `add-library`) and its marketplace manifest; templates use `__token__` placeholders |

Dependencies flow `ZephyrCore` ← `ZephyrSystem` ← `Zephyr` ← `ZephyrApplication` ← the application, never the reverse. C declarations belong in
`ZephyrCore`'s headers. Code that only wraps a Zephyr C API or provides runtime support belongs in `ZephyrSystem`; Swift-native abstractions over it
belong in `Zephyr`. Only the C `main` belongs in `ZephyrApplication`.

## Build system

- Swift is built by SwiftPM, driven by CMake. `zephyr_swift_application()` runs one `swift build --product App` for the application's package (the nearest
  `Package.swift` at or above the application, or `PACKAGE_DIR`) and links `build/swift/<triple>/release/libApp.a` into `app`. Every Swift module the
  application uses, this module's included, is in that archive. There is no other Swift compile step.
- Per-build options live in the toolset that `_swift_write_toolset()` writes to `build/swift/toolset.json`: `-Osize`, `-Xfrontend -function-sections`, the
  Kconfig defines from `_swift_defines()`, the Zephyr include paths and the C library headers (`_swift_sysroot_flags()`). Never put them, or any
  `unsafeFlags`, in a `Package.swift`: they differ per build, and unsafe flags stop other packages from depending on the root package by URL.
- Language settings live in the `settings` array of each manifest. Declare it before `package`; a later declaration is still empty when `package` reads it.
- The archive is linked with `--whole-archive`, as one `-Wl,` item, because the kernel's weak `main` would otherwise win over Swift's. `swift_orphans.ld`
  discards `.swift_modhash` and `.swift1_autolink_entries`.
- `--build-system native` is used because swiftbuild archives with the host's libtool, which cannot write ELF archives. The deprecation warning it prints is
  expected.
- A `#if CONFIG_FOO` in Swift only works if `_swift_defines()` passes `-DCONFIG_FOO`. Today `SWIFT_DEBUG_INFO`, `CONFIG_TIMEOUT_64BIT` (makes `Tick` `Int64`
  and compiles `Instant` and `now()`), `CONFIG_LOG`, `CONFIG_LOG_MODE_DEFERRED` and `CONFIG_<NAME>` for each registered library are passed. Check before
  relying on any other Kconfig symbol in an `#if`.
- `zephyr_swift_library()` compiles nothing: it exposes a library's `include/` to Zephyr and registers its name for the `CONFIG_<NAME>` define. A library
  reaches an application through the application's `Package.swift`.
- Kconfig symbols are `CONFIG_SWIFT` (master switch) and `CONFIG_SWIFT_DEBUG_INFO`. CMake cache options are `ZEPHYR_SWIFT_OFFLINE`,
  `ZEPHYR_SWIFT_LSP_CONFIG` and `ZEPHYR_SWIFT_BUILD_SYSTEM`. Document new options in `Kconfig` or `CMakeLists.txt`, and in `README.md`.

## Embedded Swift rules

Every Swift target is compiled with this flag set, from the manifest's `settings` and `swiftLanguageModes: [.v6]`:

```text
-swift-version 6 -strict-memory-safety
-enable-upcoming-feature ExistentialAny
-enable-upcoming-feature InternalImportsByDefault
-enable-upcoming-feature MemberImportVisibility
-enable-experimental-feature Embedded
-enable-experimental-feature Extern
-enable-experimental-feature CImplementation
```

- Declare C interfaces in `core.h` (included by `BridgingHeader.h`) and implement them in Swift with `@c @implementation`. Never use `@_cdecl`.
  A C function that one Swift module calls and another implements, such as `entrypoint`, is declared there too.
- No `async`/`await`, `Task` or actors. No `Codable` or runtime reflection. Avoid existentials and anything that allocates (`Array` growth, `String` building)
  in ISRs and tight loops.
- Annotate every unsafe pointer operation with a `// SAFETY:` comment stating the invariant.
- Use access-level imports: `public import ZephyrCore` or `public import ZephyrSystem` only when a public signature or an `@inlinable` body uses a declaration
  from it (for example `k_timeout_t`, or the errno constants in `ZephyrError`). Imports are not re-exported, so each file imports what it uses.
- Prefer value types. Keep the Swift layer a thin bridge over the Zephyr C API.

## Conventions

- **License**: GPL-3.0. Start every new source file with:

  ```swift
  // SPDX-License-Identifier: GPL-3.0
  // Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>
  ```

  Code derived from Linaro's Zephyr Swift work keeps its Apache-2.0 header.

- **DCO**: every commit must carry a `Signed-off-by: Name <email>` trailer certifying the [Developer Certificate of Origin](https://developercertificate.org/).
  Add it with `git commit -s` (together with `-S`, which signs cryptographically; the two are independent and both are required). Use the author's real
  name and the email of the git identity, never one invented for an agent. Keep the trailer when you amend, rebase or squash: `git rebase --signoff`
  adds a missing one. Check with `git log --format='%h %(trailers:key=Signed-off-by,valueonly)'`; no commit may be blank. A PR with a commit that lacks
  it must not be merged.
- **Commits**: conventional commits using the types in `.commitlintrc` (`feature`, not `feat`; also `build`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, …),
  sentence-case subject, `!` for breaking changes. Every commit is GPG-signed (`git commit -S`) and signed off (`git commit -s`, see DCO above); never bypass either. Commits Claude wrote carry
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
west build -p -b <board> samples/app+lib/app
```

Both must compile without new warnings. To iterate on Swift alone, generate the build directory and rebuild only the package:

```bash
west build -b <board> --cmake-only samples/app
west build -t swift_build          # Zephyr's generated headers, then the Swift package
build/swift/swift-build.sh -v      # the same swift build, again, with its command lines
```

Check every manifest with `swift package describe`; `swift build` on its own cannot work, because the Zephyr headers come from a build directory. New logic should come with Ztest/Twister cases under `tests/`, including negative and edge cases
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

There are no third-party packages. Code uses the Embedded Swift standard library and the Zephyr C APIs exposed through `ZephyrCore`.
Ask before adding anything else. Applications built on this module may add SwiftPM packages that build with Embedded Swift for a bare-metal target; they
commit `Package.resolved`, and CI builds them with `-DZEPHYR_SWIFT_OFFLINE=ON`.
