---
name: new-project
description: >
  Scaffold a new standalone Zephyr Swift application repository from the anselmes/repository template, with a west.yml
  manifest pinning Zephyr and zephyr-lang-swift, an app, AGENTS.md and CLAUDE.md, and a CI workflow that builds with west.
  Use when the user wants to start a new Zephyr Swift project, firmware repository or Embedded Swift app, or says
  "new project", "new repository" or "bootstrap firmware" for Zephyr.
license: GPL-3.0
metadata:
  author: Schubert Anselme
  version: 0.1.0
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

- **Name** (`__name__`) and **directory** (`__dir__`; default `./__name__` beside the current directory). An existing empty directory is fine; stop if it is not empty.
- **Owner** (`__owner__`; default `anselmes`) and whether to create the GitHub repository (confirm first: it creates a remote).
- **Board** (`__board__`) and the **HAL modules** it needs in the manifest's allowlist (for example `hal_espressif` for ESP32).
- **Title** of the first app; **license** (`GPL-3.0` default), **author**, **year**, one-line **description**.
- **Zephyr source**: the project that provides Zephyr and its `revision` source (default: `anselmes/zephyr`).
  Its owner and repository name are `__zephyr-owner__` and `__zephyr-repo__`, independent of `__owner__`.
  Look up the latest release tag, and the latest `zephyr-lang-swift` tag or commit, with `gh` (`__zephyr-rev__`, `__swift-rev__`), and the latest stable Swift toolchain (6.4 or later) for CI (`__swift-version__`).
  The tag must be new enough for the CI workflow's `west sdk install --no-gnu-toolchains --llvm`: check that the revision's
  `scripts/west_commands/sdk.py` defines both options (the default source's newest stable tag, v4.2.0, does not). If the newest
  tag lacks them, resolve a commit SHA that has them, or stop and ask. If a lookup fails, stop and report it; never guess a revision.

## 3. Start from the repository template

- On GitHub, when asked (after confirming):

  ```bash
  gh repo create __owner__/__name__ --template anselmes/repository --private --clone
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
replacing any the template ships), and copy the `.trunk` settings from zephyr-lang-swift
(`gh api repos/anselmes/zephyr-lang-swift/contents/.trunk`). Then:

- `LICENSE`: keep the template's for `GPL-3.0`; for another license, stop and ask for the text.
- `.github/workflows/west.yml`: after filling tokens, run `gh actions-lock` to update `.github/workflows/actions.lock`; never edit the lock by hand.
- Run steps 1 to 3 of `add-app` for the first application (`app/`), skipping its verification step: the workspace does not exist until step 5 below, which verifies the app. Then write `AGENTS.md` from `templates/AGENTS.md` with `CLAUDE.md` as a symlink to it:
  `ln -s AGENTS.md CLAUDE.md`.

## 5. Verify

Check that no `__token__` remains, then follow the conventions' verification: `west init -l .`, `west update` and
`west build -p -b __board__ app` when `west` and the SDK are present (otherwise report them skipped and print the commands),
`swift format lint --recursive --strict app`, and `trunk check`. Fix failures your change caused; after two failed attempts, stop and report
the exact output. Do not commit; tell the user what was created, which values were inferred or looked up, and to run `/zephyr-swift:add-library` next.
