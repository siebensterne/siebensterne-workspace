# siebensterne development workspace

Orchestration repository for two independent repositories:

- `fieldbook/` — acquisition, preservation, reference facts, NDC publication.
- `nirnay/` — independent verification, research, portfolio, risk and OMS.

This repository has no product source, parent Git repository, shared crate,
submodule or monorepo. The two directories are local clones ignored by Git.

## Current state

Machine-readable authority: `CURRENT-STATE.json`. It holds the five separately
evidenced source-head concepts, CI results, capability states, open decisions
and the freeze. Do not copy mutable status into prose documents.

Bootstrap pins and tool policy: `WORKSPACE.lock.json`. The pins are historical
bootstrap baselines, not current heads.

Ownership and programme boundaries: `WORKSPACE.md`. The current status map is
`engineering/STATUS.md`; `engineering/evidence/REVIEW-LOG.md` is the active decision
ledger. Historical phase records are evidence, not current status.

## Authority map

| Topic | Owning document |
|---|---|
| Agent workflow | `AGENTS.md` |
| Current status authority map | `engineering/STATUS.md` |
| Digest reconciliation | `engineering/DIGEST-RECONCILIATION-2026-11-26.json` |
| Ownership and boundaries | `WORKSPACE.md` |
| Cross-repository ADR identities | `ADR-REGISTRY.md` |
| NDC versions, digests and contract status | `NDC-REGISTRY.md` |
| Engineering document digests | `ENGINEERING-DOC-DIGESTS.json` |
| Ownership, contracts and decisions | `engineering/decisions/` |
| Architecture, design, coverage and style | `engineering/architecture/`, `engineering/design/`, `engineering/coverage/`, `engineering/style/` |
| NDC conformance, schema packages and phase evidence | `engineering/conformance/` |
| Retirement decisions and manifests | `engineering/retirement/` |
| Active ledger and historical phase records | `engineering/evidence/REVIEW-LOG.md` (active), `engineering/evidence/` and `engineering/conformance/` (historical) |
| Pairing, tool commands and shared-file policy | `docs/process/` |
| Shared C++ and hook configs | `.clang-format`, `.clang-tidy`, `CMakeLists.txt`, `CMakePresets.json`, `.pre-commit-config.yaml` (identical in all three repositories) |
| q / kdb+ style contract | `q-style.json` and `scripts/check_q_style.py` (identical in all three repositories) |

Read the owning document for a task. Older records answer historical questions;
they do not override the current authority.

## Freeze

Rights remain `UNKNOWN`, dataset acceptance `BLOCKED`, budget `INR 0`, provider
collection `DISABLED`, experiments `BLOCKED`, M4 holdout untouched, synthetic
market-shaped tests retired under D11 and live execution `DISABLED`. No
document in this repository grants data rights or operational authority.

## Commands

```
make bootstrap        verify pinned local clones
make status           heads, dirt, remotes and CI
make consistency      tool, canonical-file and lock audit
make check-all        both repository static gate surfaces
make check-nirnay     Nirnay full local suite
make audit            status + consistency + static gates
make ci-report        latest hosted CI conclusions
make package-review   deterministic source/history ZIPs
```

See `docs/process/TOOL-MATRIX.md` for pinned versions and repository-specific
commands, and `docs/process/PAIRED-PR-CHECKLIST.md` for coordinated changes.
