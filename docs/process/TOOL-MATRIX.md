# Tool matrix — canonical developer surface

This document is binding for both repositories. A divergence is allowed only when it
is listed here with a reason. `make consistency` checks the machine-verifiable rows.

## Shared version pins

| Tool | Canonical version | Fieldbook | Nirnay |
|---|---|---|---|
| Rust | 1.99.1 (minimal, rustfmt, clippy) | same | same |
| Python (CI and lint target) | 3.12 | same | same |
| Ruff | 0.17.5 | same | same |
| Pyink | 26.5.1 | same | same |
| shellcheck-py | 0.11.0.1 | same | same |
| clang-format | 21.1.8 | same | same |
| clang-tidy | 21.1.8 | same | same |
| CMake / Ninja | 3.25 / 1.11 | same | same |
| pre-commit / hooks | 4.0.0 / v6.0.0 | same | same |

## Shared tooling configs

`.clang-format`, `.clang-tidy`, `CMakeLists.txt`, `CMakePresets.json`,
`q-style.json`, `cmake/strict-flags.cmake` and `.pre-commit-config.yaml` are byte-identical in all three
repositories. The C++ baseline uses C++20, strict warnings-as-errors and the
same two-compiler preset workflow everywhere, including repositories without
C++ sources. The q/kdb+ contract is machine-readable and loaded by
`scripts/check_q_style.py`; no waivers are permitted.

## Canonical command surface

Both repositories expose these targets with the same meaning:

| Target | Meaning |
|---|---|
| `make check` | full local gate, including the repository's test policy |
| `make check-static` | static gates only; no tests, no e2e, no collection |
| `make ci` | `cargo xtask ci` |
| `make assure` | `cargo xtask assure` (polish/assurance scripts) |
| `make lint` | `cargo xtask lint` |
| `make test` | `cargo xtask test` under the repository's own policy |
| `make fmt` | non-mutating format check |
| `make format-fix` | mutating formatter; never used by CI |

Workspace commands: `make status`, `make ci-report`, `make consistency`, `make audit`,
`make check-all`, `make check-fieldbook-static`, `make check-nirnay-static`,
`make check-nirnay`.

## Policy differences that are preserved

| Area | Fieldbook | Nirnay | Reason |
|---|---|---|---|
| Full test suite in static gate | excluded | excluded via `check-static` | Fieldbook fixture inventory is under owner review; Nirnay deselects `market_shaped_fixture` |
| Python line length | 100 | 100 | aligned across Ruff, Pyink, EditorConfig, Pylint |
| Clippy config filename | `clippy.toml` | `clippy.toml` | single canonical name |
| `pytest.ini` | absent | present | Nirnay alone has the Python research suite and deselect marker |
| `deny.toml` | absent | present | Nirnay alone builds the supply-chain gate |
| `constraints/` | absent | present | Nirnay pins three resolved research environments |
| `.gitignore`, `.gitattributes` | repo-specific | repo-specific | captures and secrets in Fieldbook; data and keys in Nirnay |
| `git-policy.json` | root | `engineering/` | both are binding locally; paths differ by repo history |

Every row above is intentional. Do not remove a tool or a gate to make the matrix look
uniform. Do not add a shared Rust crate, submodule, parent repository, queue or database
to achieve uniformity.

## Verification

Run `make consistency` before paired work. It checks version pins, canonical root files,
byte-identical shared files, lock/head skew and the presence of the two registries. It is
read-only and contacts no provider.
