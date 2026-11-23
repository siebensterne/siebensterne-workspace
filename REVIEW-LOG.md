# Cross-repository review log

Read-only record of integration decisions. It does not replace either repository's own
evidence or review archive.

| Date | Revision | Decision | Evidence |
|---|---|---|---|
| 2026-11-22 | Fieldbook `aee91de` | Architecture baseline reviewed; ownership split sound; governance and distribution gaps open | Nirnay `engineering/architecture/reviews/FIELDBOOK-ARCHITECTURE-REVIEW-2026-11-22.md` |
| 2026-11-23 | Fieldbook `28eb877` baseline | Six intervening commits did not close the rights or release findings | Nirnay `engineering/architecture/reviews/FIELDBOOK-REVIEW-REFRESH-2026-11-23.md` |
| 2026-11-23 | Fieldbook `afc6f28`, Nirnay `b997d48` | W1 paired PRs merged: egress rights enforcement and dataset admission | Fieldbook PR #40, Nirnay PR #123 |
| 2026-11-23 | Nirnay `8c2a09a` | License metadata corrected in both repositories | Fieldbook PR #39, Nirnay PR #122 |
| 2026-11-23 | Workspace | Tooling standardised; workspace published as an independent repository | This repository |
| 2026-11-23 | Fieldbook `55027e0`, Nirnay `f250fee` | Paired standardisation PRs merged: Python 3.12, line length 100, canonical Make surface, canonical root docs, NDC producer doc, clippy filename, ADR index, quality-contract alignment | Fieldbook PR #41, Nirnay PR #125 |
| 2026-11-23 | CI | Fieldbook main CI `45062268375` 2/2 after rerun (stale remote branch cleared); Nirnay main CI `45062286601` 12/12 | Hosted CI |
| 2026-11-23 | Workspace `37665f7` | Three independent org repositories; workspace contains only orchestration files | This repository |

## Rules

- Record exact commit and PR for every cross-repository decision.
- Never describe a documentation review as verification of live or real-market data.
- Never record a claim of zero loss, nanosecond precision or profitability here.
- Rights remain `UNKNOWN` until written evidence and owner approval exist.
| 2026-11-23 | Fieldbook `340f829`, Nirnay `e975be9` | W1.1-B/C/D merged: test-policy enforcement, exact operation and mandatory audit, paired NDC rights and trust semantics | Fieldbook PRs #42/#43/#44, Nirnay PRs #126/#127 |
| 2026-11-23 | CI | Fieldbook `45084154089` 2/2, Nirnay `45084174149` 12/12 | Hosted CI |
| 2026-11-23 | W1.2-A | Test counts reconciled from exact output: Fieldbook 558/12 at `340f829`, Nirnay 251/199/2 at `e975be9`; 243 and 352 Nirnay figures tied to earlier commits | `CURRENT-STATE.json`, `W1.1-COMPLETION-RECORD.md` |
