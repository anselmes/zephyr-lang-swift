# Zephyr Swift Claude Code plugin

Skills that scaffold Embedded Swift projects on Zephyr RTOS using the `zephyr-lang-swift` module and its conventions:
typed throws, one type per file, `zephyr_swift_application()` and `zephyr_swift_library()`, a `west.yml` manifest, signed commits,
and the `anselmes/repository` template fetched from GitHub with this kit's tooling layered on top.

## Features

| Skill         | Scaffolds                                                                                                 |
| ------------- | --------------------------------------------------------------------------------------------------------- |
| `new-project` | A standalone Swift application repository: `west.yml`, `app/`, `AGENTS.md`, CI that builds with `west`    |
| `add-app`     | An application in an existing project: `CMakeLists.txt`, `prj.conf`, `sample.yaml`, `.env.example`, `src/` |
| `add-library` | A library module: its `Kconfig` symbol, `CMakeLists.txt`, `zephyr/module.yml` entry and Swift sources     |

Each skill infers what it can from the project it runs in (`west.yml`, the Git remote, `hack/copyright.txt`) and asks once for the rest.
Generated code is built with `west build` when `west` and the SDK are present; nothing is committed.

## Prerequisites

- Claude Code
- Swift 6.4 or later with Embedded Swift support
- `gh`, to fetch the `anselmes/repository` template and look up release tags, with the `actions-lock` extension for CI lockfiles
- `west` and the Zephyr SDK, to build the result (optional; the skills report the build as skipped without them)

## Installation

```text
/plugin marketplace add anselmes/zephyr-lang-swift
/plugin install zephyr-swift@zephyr-lang-swift
```

## Usage

Ask for what you want, such as "create a new Zephyr Swift project called blinky" or "add a sensor library", or invoke a skill directly,
such as `/zephyr-swift:add-app`.

## Development

This directory is the plugin root. Each skill is `skills/<name>/SKILL.md` with its own `references/` and `templates/`; `references/` at
the plugin root holds what every skill shares. Templates use `__token__` placeholders, listed in `references/conventions.md`.
Check a change by following the skill into a scratch directory and running `west build` on the result against this checkout.

## License

GPL-3.0. See [LICENSE](../LICENSE).
