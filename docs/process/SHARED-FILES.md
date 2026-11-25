# Shared and repository-local files

`quality-contract.json` originally described eight files as shared and byte-identical,
but several had drifted. This document is the authoritative classification. The tool
versions in `quality-contract.json` remain binding; file identity is recorded here.

## Byte-identical across both repositories

Verified by `make consistency` with `cmp`:

| File | Purpose |
|---|---|
| `LICENSE` | Apache-2.0 text |
| `NOTICE` | attribution |
| `ORIGIN.md` | provenance and originality policy |
| `quality-contract.json` | tool version pins |
| `scripts/check_prose_unified.py` | prose gate |
| `requirements-dev.txt` | pinned Python tooling |

## Same semantics, repository-local content

| File | Reason |
|---|---|
| `ruff.toml` | shared core rules are identical; local sections list each repo's source roots and test-path exceptions |
| `.editorconfig` | repo-specific file classes (captures, SBE, fixtures) |
| `.clang-format` | Nirnay has C++ sources; Fieldbook has none |
| `.gitignore` | Fieldbook ignores captures; Nirnay ignores data, keys and secrets |
| `.gitattributes` | per-repository binary and verbatim evidence rules |
| `git-policy.json` | different merge-history grandfathering |
| `pytest.ini`, `deny.toml`, `constraints/` | only Nirnay has the Python research suite and supply-chain gate |
| `.cargo/config.toml` | Fieldbook exposes extra gate aliases |
| `Makefile` | same canonical target names, different gate bodies by language and policy |

## Rule

Do not force byte identity where the table says repository-local. Do not let a file in
the byte-identical table drift without a paired PR in both repositories. `make
consistency` reports identity failures as informational for repo-local files; it fails
only on version pins, canonical file presence, lock skew and missing registries.
