# Layout

The repository is a west manifest repository and a Zephyr module at once:

```text
__name__/
├── west.yml                 # manifest: Zephyr + zephyr-lang-swift
├── zephyr/module.yml        # created by add-library; the root is a module
├── Kconfig                  # created by add-library
├── app/                     # from add-app
│   ├── CMakeLists.txt
│   ├── prj.conf
│   ├── sample.yml
│   ├── .env.example
│   └── src/Entrypoint.swift
├── lib/                     # from add-library (empty until the first library)
├── tests/                   # Ztest/Twister cases
├── .swift-format            # swift format settings
├── AGENTS.md  CLAUDE.md -> AGENTS.md
└── ...                      # the anselmes/repository template files
```

## What this kit adds to the template

| File                         | Source                                 | Notes                                                                           |
| ---------------------------- | -------------------------------------- | ------------------------------------------------------------------------------- |
| `west.yml`                   | `templates/west.yml`                   | Fill the revisions and HAL allowlist                                            |
| `AGENTS.md`, `CLAUDE.md`     | `templates/AGENTS.md`                  | `CLAUDE.md` is a symlink                                                        |
| `.github/workflows/west.yml` | `templates/.github/workflows/west.yml` | Builds the app with `west`; lock actions with `gh actions-lock`                 |
| `.swift-format`              | `templates/.swift-format`              | Always written, replacing any the template ships; read from the repository root |
| `.trunk/`                    | zephyr-lang-swift on GitHub            | Copy; do not edit                                                               |
| `README.md`                  | the template's, edited                 | Keep its sections; describe the project, board and `west` steps                 |
| `.gitignore`                 | the template's, appended               | Add `.west/`, `build/`, `.venv/`, `.env`; never ignore `zephyr/` (it holds `module.yml`) |

Do not copy `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` or `SECURITY.md`; they come from the organization's defaults. `.env`, keys and
certificates are never committed.

## west.yml

`self.path` is the repository name. The `zephyr` project imports Zephyr's own manifest restricted to the modules the board needs;
`zephyr-lang-swift` is declared as its own project (see below). Pin every `revision` to a tag or full commit SHA found by lookup, never to a branch.

The Zephyr source has its own remote (`zephyr-source`, from `__zephyr-owner__`), separate from the repository owner, so creating
`acme/blinky` against the default `anselmes/zephyr` still fetches `anselmes/zephyr`. The Zephyr fork lists Swift in its disabled
`optional` group, which an allowlist neither enables nor pins, so `zephyr-lang-swift` is declared as its own top-level project at
`__swift-rev__`; a project declared in the manifest repository overrides an imported one of the same name. West checks Zephyr out
beside the manifest repository (`west init -l .`), not inside it.
