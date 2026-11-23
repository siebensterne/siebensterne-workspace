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
- D11 supersedes the W1.1 preserve-source-while-disabled policy for synthetic market-data
  test assets. Historical W1.1/W1.2 test-policy records, counts and digests are preserved;
  a new dated test-retirement record is published when RRP-002 executes.
- An entry recording a status correction does not rewrite the original decision history;
  only the registry and governance records change.
| 2026-11-23 | Fieldbook `340f829`, Nirnay `e975be9` | W1.1-B/C/D merged: test-policy enforcement, exact operation and mandatory audit, paired NDC rights and trust semantics | Fieldbook PRs #42/#43/#44, Nirnay PRs #126/#127 |
| 2026-11-23 | CI | Fieldbook `45084154089` 2/2, Nirnay `45084174149` 12/12 | Hosted CI |
| 2026-11-23 | W1.2-A | Test counts reconciled from exact output: Fieldbook 558/12 at `340f829`, Nirnay 251/199/2 at `e975be9`; 243 and 352 Nirnay figures tied to earlier commits | `CURRENT-STATE.json`, `W1.1-COMPLETION-RECORD.md` |
| 2026-11-23 | W1.2-A | Reconciled counts from exact output: Fieldbook 558/12 at `340f829`; Nirnay 251/199/2 at `e975be9`; 243 tied to `ba21945`, 352 to `72bac0c` | `CURRENT-STATE.json`, Nirnay PR #128 |
| 2026-11-23 | W1.2-B | Nirnay Rust market-shaped tests gated; 73 + 1 doctest executed, 638 withdrawn, 711 preserved | Nirnay PR #129, `evidence/RUST-TEST-POLICY-NIRNAY-2026-11-23.md` |
| 2026-11-23 | CI | Nirnay main CI `45131112797` 12/12 at `d73e145` | Hosted CI |
| 2026-11-23 | W1.2-C0/C1/C2/C3/C4 | Semantic model approved; Fieldbook PRs #45/#46; Nirnay PR #130; paired NDC v2 PRs #47/#131 | Workspace, Fieldbook, Nirnay |
| 2026-11-23 | W1.2-D1 | India domain ownership crosswalk approved; Fieldbook owns canonical identity, Nirnay consumes | Workspace PR #2 |
| 2026-11-23 | CI | Fieldbook `45165997939` 2/2; Nirnay `45166038617` 12/12 | Hosted CI |

## W2.1-A and RRP-001 records

| Date | Revision | Decision | Evidence |
|---|---|---|---|
| 2026-11-23 | W2.1-A | Ratification/status reconciliation: ownership ADR `NR-ARCH-ADR-0001` Accepted 2026-11-23; NDC `v2` is the single active contract version and is Approved; v1 marked historical; full approved digests recorded (producer `215a5b55…`, consumer `22eaef7d…`, C0 `3dace660…`) without changing approved bytes | Workspace branch `docs/rrp-001` (uncommitted worktree); `NDC-REGISTRY.md`, `ADR-REGISTRY.md`, `ENGINEERING-DOC-DIGESTS.json`, `CURRENT-STATE.json`; `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md` |
| 2026-11-23 | W2.1-A | Separate consumer-use implementation proposal `ndc-consumer-use-v2-proposed.md` recorded as Proposed with digest `4b9d1fe7…`; not silently folded into ratified NDC v2 | Nirnay `f6842d2`; `NDC-REGISTRY.md`, `ENGINEERING-DOC-DIGESTS.json`, `CURRENT-STATE.json` |
| 2026-11-23 | W2.1-A | W2 India design foundation remains Proposed pending a separate design approval: Fieldbook `docs/india-reference-foundation-design.md`, Nirnay `engineering/ndc-reference-projection-design.md`, workspace `engineering/coverage/india-coverage-register.md` and `engineering/architecture/india-domain-ownership-crosswalk.md` | Original W1.2-D1/W2-A history above unchanged; no new approval record |
| 2026-11-23 | RRP-001 | Owner directive D11 recorded: retire synthetic market-data test assets; supersedes the W1.1 preserve-source-while-disabled policy. Six dispositions, 12-field record schema, P0/P1/P2, no history rewrite, no broad `git rm -r`, generic infrastructure kept, Nirnay ingestion frozen until replacements exist. Manifests built from `git ls-files` + `shasum -a 256` + `stat` at reviewed heads; no source file deleted | `engineering/retirement/RRP-001.md`, `FIELD-BOOK-RETIREMENT-MANIFEST.csv` (219 rows), `NIRNAY-RETIREMENT-MANIFEST.csv` (76 rows), `DEPENDENCY-CROSSWALK.csv` (45 rows), `RETIREMENT-ACCEPTANCE.md`; Fieldbook `3c3279b`, Nirnay `f6842d2` |
