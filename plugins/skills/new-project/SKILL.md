---
name: new-project
description: >
  This skill should be used when the user wants to start a new standalone Zephyr Swift firmware repository from nothing, for
  example "new project", "new Zephyr Swift repository", "bootstrap firmware" or "start an Embedded Swift app". It scaffolds the
  anselmes/repository template with a west.yml pinning Zephyr and zephyr-lang-swift, a first app, AGENTS.md and CLAUDE.md, and a CI
  workflow that builds with west, and can create the GitHub repository. Not for adding an app or a library to an existing project
  (use add-app or add-library).
license: GPL-3.0
metadata:
  author: Schubert Anselme
  version: 0.1.1
---

# New project

Creates a repository-shaped Zephyr project that builds an Embedded Swift application on `zephyr-lang-swift`. It starts from the
`anselmes/repository` template, fetched from GitHub so it is always current, with this kit's tooling layered on top. The result is
a west manifest repository whose root is also a Zephyr module, with `app/` (from `add-app`) and room for `lib/` (from `add-library`).

## 1. Read the references

- [Conventions](../../references/conventions.md): inputs, lookups, tokens, Swift and Zephyr rules.
- [Layout](references/layout.md): the repository structure, `west.yml` and what this kit adds to the template.
- The [add-app](../add-app/references/app.md) reference, which this skill applies for the first application.

If any is missing or unreadable, stop and name the missing file.

## 2. Gather the inputs

Infer what you can, then ask the user one combined question listing every missing input (see conventions):

- **Name** (`__name__`; derive `__NAME__`) and **directory** (`__dir__`; default `./__name__` beside the current directory). An existing empty directory is fine; stop if it is not empty.
  West treats the parent of `__dir__` as the workspace: `west update` clones Zephyr and its modules there, outside the repository. Stop if `__dir__` or an ancestor already
  holds a `.west` directory (`west topdir` succeeds), and tell the user where the workspace will be created.
- **Owner** (`__owner__`; default `anselmes`), whether to create the GitHub repository (confirm first: it creates a remote) and, if so, its visibility (default private).
- **Board** (`__board__`) and the **HAL modules** it needs in the manifest's allowlist (for example `hal_espressif` for ESP32; a board that needs none, such as QEMU, leaves only `picolibc`).
  Choose the toolchain from the board: `zephyr/llvm` with `--no-gnu-toolchains --llvm` by default, but `zephyr` with `--gnu-toolchains riscv64-zephyr-elf` for Espressif boards,
  whose HAL the LLVM toolchain cannot build (`__toolchain__`, `__sdk-args__`).
- **First app**: `__app__` (default `app`), `__project__`, **title** (`__Title__`, with `__Title-yaml__` and `__Title-swift__`); **license** (`GPL-3.0` default), **author**, **year**, one-line **description**.
  Hand these to `add-app` so it does not ask again.
- **Zephyr source**: the project that provides Zephyr and its `revision` source (default: `anselmes/zephyr`).
  Its owner and repository name are `__zephyr-owner__` and `__zephyr-repo__`, independent of `__owner__`. Look up, never recall:
  - `__zephyr-rev__`: `gh release list -R __zephyr-owner__/__zephyr-repo__ --exclude-pre-releases --limit 5`, else a commit SHA.
  - `__swift-rev__`: the latest `zephyr-lang-swift` release tag (`gh release list -R anselmes/zephyr-lang-swift --limit 1`) or, with none, the SHA from
    `gh api repos/anselmes/zephyr-lang-swift/commits/main --jq .sha`.
  - `__swift-version__`: the latest stable Swift toolchain (6.4 or later) for CI.

  The Zephyr revision must be new enough for the CI workflow's `west sdk install`: check that its `scripts/west_commands/sdk.py` defines the options in `__sdk-args__`
  (`gh api "repos/__zephyr-owner__/__zephyr-repo__/contents/scripts/west_commands/sdk.py?ref=__zephyr-rev__" --jq .content | base64 -d | grep -e --llvm -e --gnu-toolchains`).
  If the newest tag lacks them, resolve a commit SHA that has them, or stop and ask. If a lookup fails, stop and report it; never guess a revision.

## 3. Start from the repository template

- On GitHub, when asked (after confirming):

  ```bash
  gh repo create __owner__/__name__ --template anselmes/repository --<visibility> --clone
  ```

  Honor the chosen directory: clone straight into `__dir__` (`gh repo create ... --clone` clones into `./__name__`, so move it when they differ).

- Locally otherwise, the template's files without its history:

  ```bash
  mkdir -p __dir__
  gh api repos/anselmes/repository/tarball | tar -xz -C __dir__ --strip-components=1
  git -C __dir__ init -b main
  ```

If a fetch fails, stop and report it; never substitute guessed or placeholder values.

## 4. Layer this kit's tooling on top

Apply `references/layout.md`: keep the template's `.editorconfig` and copy `templates/` over the template without replacing files it already ships (except where the reference says),
fill every `__token__`, write `.swift-format` from `templates/.swift-format` (mirrors this repository's own `.swift-format`: 2-space indent, 180 columns, trailing commas;
replacing any the template ships), and replace the template's `.trunk` with zephyr-lang-swift's at `__swift-rev__`
(`gh api repos/anselmes/zephyr-lang-swift/tarball/__swift-rev__ | tar -xz --strip-components=1 -C <tmp> '*/.trunk'`, then copy `<tmp>/.trunk` over the repository's). Then:

- `LICENSE`: keep the template's for `GPL-3.0`; for another license, stop and ask for the text.
- `.github/workflows/west.yml`: after filling tokens, run `gh actions-lock` to update `.github/workflows/actions.lock`; never edit the lock by hand.
- Run steps 2 and 3 of `add-app` for the first application (`__app__`) with the inputs above, skipping its verification step: the workspace does not exist until step 5 below, which verifies the app. Then write `AGENTS.md` from `templates/AGENTS.md` with `CLAUDE.md` as a symlink to it:
  `ln -s AGENTS.md CLAUDE.md`.

## 5. Verify

Check that no `__token__` remains in the files you wrote, then follow the conventions' verification. When `west` and the SDK are present (otherwise report them skipped and print the commands),
run `west init -l .`, `west update` (it writes outside `__dir__`, into the workspace you confirmed), source `__app__/example.env` as `.env`, and
`west build -p -d .build -b __board__ __app__`. Also run `swift format lint --recursive --strict __app__` and `trunk check`. Fix failures your change caused; after two failed attempts, stop and report
the exact output. Do not commit; tell the user what was created, which values were inferred or looked up, and to run `/zephyr-swift:add-library` next.
