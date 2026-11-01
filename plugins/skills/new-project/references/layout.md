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
| `.gitignore`                 | the template's, appended               | Add `.west/`, `build/`, `.venv/`, `.env`, `modules/`, `zephyr/` checkouts       |

Do not copy `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` or `SECURITY.md`; they come from the organization's defaults. `.env`, keys and
certificates are never committed.

## west.yml

`self.path` is the repository name. The `zephyr` project imports Zephyr's own manifest restricted to the modules the board needs;
`zephyr-lang-swift` is imported through that allowlist (as in `zos/west.yml`) or declared as its own project when the Zephyr
source does not list it. Pin every `revision` to a tag or full commit SHA found by lookup, never to a branch.
