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

## W2.1 sequence and RRP records

| Date | Revision | Decision | Evidence |
|---|---|---|---|
| 2026-11-23 | W2.1-A | Ratification/status reconciliation: ownership ADR `NR-ARCH-ADR-0001` Accepted 2026-11-23; NDC `v2` is the single active contract version and is Approved; v1 marked historical; full approved digests recorded (producer `215a5b55…`, consumer `22eaef7d…`, C0 `3dace660…`) without changing approved bytes | Workspace PR #4 (merged, `c36d1d7`); `NDC-REGISTRY.md`, `ADR-REGISTRY.md`, `ENGINEERING-DOC-DIGESTS.json`, `CURRENT-STATE.json`; `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md` |
| 2026-11-23 | W2.1-A | Separate consumer-use implementation proposal `ndc-consumer-use-v2-proposed.md` recorded as Proposed with digest `4b9d1fe7…`; not silently folded into ratified NDC v2 | Nirnay reviewed head `f6842d2b6438c657c4d4eaec8edb3920193d2181`; `NDC-REGISTRY.md`, `ENGINEERING-DOC-DIGESTS.json`, `CURRENT-STATE.json` |
| 2026-11-23 | W2.1-A | W2 India design foundation remains Proposed pending a separate design approval: Fieldbook `docs/india-reference-foundation-design.md`, Nirnay `engineering/ndc-reference-projection-design.md`, workspace `engineering/coverage/india-coverage-register.md` and `engineering/architecture/india-domain-ownership-crosswalk.md` | Original W1.2-D1/W2-A history above unchanged; no new approval record |
| 2026-11-23 | RRP-001 | Owner directive D11 recorded: retire synthetic market-data test assets; supersedes the W1.1 preserve-source-while-disabled policy. Six dispositions, 12-field record schema, P0/P1/P2, no history rewrite, no broad `git rm -r`, generic infrastructure kept, Nirnay ingestion frozen until replacements exist. Manifests built from `git ls-files` + `shasum -a 256` + `stat` at reviewed heads; no source file deleted | Workspace PR #4 (merged, `c36d1d7`); `engineering/retirement/RRP-001.md`, `FIELD-BOOK-RETIREMENT-MANIFEST.csv` (219 rows), `NIRNAY-RETIREMENT-MANIFEST.csv` (76 rows), `DEPENDENCY-CROSSWALK.csv` (45 rows), `RETIREMENT-ACCEPTANCE.md`; reviewed heads Fieldbook `3c3279bdaa8df6aa44018184fefb662e98b5e0c1`, Nirnay `f6842d2b6438c657c4d4eaec8edb3920193d2181` |

### RRP-001..RRP-007 merged PRs

| Date | Revision | Decision | Evidence |
|---|---|---|---|
| 2026-11-23 | RRP-001 | Workspace: D11, six dispositions and the measured retirement manifests published (no source file deleted here) | Workspace PR #4 (merged, `c36d1d7`); `engineering/retirement/RRP-001.md` |
| 2026-11-23 | RRP-002 | Fieldbook and Nirnay synthetic market-data assets retired: 75 Fieldbook and 61 Nirnay assets removed individually; blobs retained, no history rewrite | Fieldbook PR #49 (merged, `b0cbf4d`), Nirnay PR #134 (merged, `9c29a0e`); `docs/synthetic-asset-retirement-2026-11-23.md`, `evidence/TEST-RETIREMENT-NIRNAY-2026-11-23.md` |
| 2026-11-23 | RRP-003 | Fieldbook: seven non-target venue adapters and obsolete measurements removed; per-repository test count 553 passed / 12 ignored + 1 doc test, not combined with Nirnay | Fieldbook PR #50 (merged, `37cc7ce`); `docs/product-scope-retirement-2026-11-23.md` §7 |
| 2026-11-23 | RRP-004 | Nirnay: nine source-ingestion paths frozen under ADR-0001 and `engineering/source-ingestion-freeze.v1.json`; no decoder or recorder removed | Nirnay PR #135 (merged, `2c4f457`); `evidence/SOURCE-INGESTION-FREEZE-2026-11-23.md` |
| 2026-11-23 | RRP-005 | Fieldbook and Nirnay: documentation authorities consolidated; approved NDC and ADR bytes unchanged; Nirnay Python count 288 passed / 199 deselected / 2 subtests at the retirement record, not combined with Fieldbook | Fieldbook PR #51 (merged, `d686067`), Nirnay PR #136 (merged, `371a7ad`); `docs/documentation-consolidation-2026-11-23.md` and `evidence/RRP-005-CONSOLIDATION-2026-11-23.md` §6 |
| 2026-11-23 | RRP-006 | Workspace: research analytics, KDB/q and experiments assigned to Nirnay; custom SBE format and generated/decoder codecs CONDITIONAL on first accepted NDC v2 release | Workspace PR #5 (merged, `b425829b1b4c670fcafaf96935360432088592d1`); `engineering/retirement/RRP-006-analytics-sbe-decision.md` |
| 2026-11-23 | RRP-007 | Repository state verified: final heads, CI and review bundle recorded; no new PR | Workspace `b425829b1b4c670fcafaf96935360432088592d1`; external `REVIEW-PACKAGE-QA.md` (RRP-001..007 complete) |
| 2026-11-23 | CI | RRP final heads: Fieldbook `45220169720` 2/2 at `d686067486ebcbedecdf7c62e24d63d9aa7af435`; Nirnay `45220222082` 12/12 at `371a7add585b4baee4a37205e71022ed9927461c`. Static gates only; neither full test suite was run by CI | Hosted CI; `CURRENT-STATE.json` `ci` and `tested_source_heads` |
| 2026-11-23 | Review package | `siebensterne-review-bundle-2026-11-23-RRP.zip` digest `87cba777609736025f9988320a7089f7e2d5c863838f9a3cf6415abc53b99217` supersedes W12; four sidecars, manifests 252/252, 648/648, 34/34, three bundles and deterministic rebuild verified | External `REVIEW-PACKAGE-QA.md`; `CURRENT-STATE.json` `review_package_manifest` |
| 2026-11-23 | Residual item | `configs/research/jobs.v1.json` `code_digest` does not recompute from its declared `code_paths`; no gate consumes it. Recorded for correction before any research job is admitted; no experiment run or reinterpreted | External `REVIEW-PACKAGE-QA.md` Residual item; `CURRENT-STATE.json` `residual_items` |

### W2.1 sequence entry

| Date | Revision | Decision | Evidence |
|---|---|---|---|
| 2026-11-23 | W2.1 state reconciliation | W2.1-A ratification and RRP-001 establishment landed as Workspace PR #4 (merged); RRP-002..RRP-007 landed as merged Fieldbook/Nirnay/Workspace PRs above. This record replaces the stale `docs/rrp-001` uncommitted-worktree framing, sets the preceding workspace state to `b425829b1b4c670fcafaf96935360432088592d1` and the current/tested heads to Fieldbook `d686067486ebcbedecdf7c62e24d63d9aa7af435` and Nirnay `371a7add585b4baee4a37205e71022ed9927461c`. Bootstrap pins `28eb877`/`437179a`, RRP-001 reviewed heads `3c3279b`/`f6842d2` and final tested heads remain distinct; per-repository counts stay tied to their own heads and are not merged. W2.1-B/C runtime conformance remains a separate future work package | Workspace branch `docs/w21-state` (docs-only; no commit in this worktree); `CURRENT-STATE.json`, `REVIEW-LOG.md`; `REVIEW-PACKAGE-QA.md` |
| 2026-11-24 | W2.1 D/E paired conformance and readiness (docs only) | Paired 15-area matrix and release-format design recorded at Fieldbook `e0472f7610ee062fe1a9b8aea8d7a6234a6e3b77` and Nirnay `f1f8a8a35b510aa4b6676147f049eae2c63a16b2` on workspace base `d19ab7cd843a18a650e0d90cb38b01fc54e2f060`. Recorded PR outcomes: Workspace #6 merged (no workspace CI); Fieldbook #52/#53/#54/#55 and Nirnay #137/#138/#139/#140 merged, with exact-head CI `45241753176` pass, `45249320899` fail (git-policy remote-tracking branch), `45257941485` pass, `45267263906` fail (git-policy remote-tracking branch), and `45241706560` fail (macOS job cancelled), `45246391564`/`45275289527`/`45281493580` pass; no GitHub approving review recorded, dated evidence and static gates are the review basis. Release format is DESIGN only; serializer and full verifier NOT_STARTED. Static-only `make consistency` and `make audit` passed; no tests re-run, no counts combined across heads. Rights remain `UNKNOWN`, dataset `BLOCKED`, India design still Proposed pending a separate decision | Workspace branch `docs/w21-de` (docs-only; no commit in this worktree); `engineering/conformance/ndc-v2-conformance-matrix.md`, `engineering/conformance/ndc-v2-release-format-design.md`, `W2.1-READINESS-REPORT.md` |

## 2026-11-24 — W2.1 style standard adoption (paired PRs #8 / #56 / #141)

- Workspace PR #8: adopted `engineering/style/DOCUMENTATION-STANDARD.md` (Markdown, rustdoc `///`/`//!`, `//`, `// SAFETY:`, ADR, optional mdBook/ROFF/Typst; five canonical language links; sweep-before-gates rule). APPROVE; make consistency/audit exit 0.
- Fieldbook PR #56: official language links in STYLES.md; standard in docs/style-standards.md and D9-D13 in docs/coding-standard.md; dated evidence. Full-tree sweeps clean; fmt/lint/docs/style/test/verify exit 0. CI 45292175118 success (head 90114f2). APPROVE.
- Nirnay PR #141: official language links; standard in engineering/style-policy.md; 2 editable rustdoc links fixed; paper-engine bin collision renamed; frozen journal.rs private-link blocker recorded as dated exception (no lint weakened, no freeze bypass). Rejected at b361702 for stale code_commit; corrected in docs-only follow-up 94365be. CI 45292758536 success. APPROVE.
- Merged heads: Fieldbook f27f4a4, Nirnay 7324925, Workspace 32a46db. Main CI: Fieldbook 45293427722 2/2 (rerun after stale merged tracking ref), Nirnay 45293438172 12/12.

## 2026-11-24 — WS-SCOPE-2026-11-24-001 (owner direction)

- Owner ratified "Global Reference Core, India First". India is the first national implementation of a global, jurisdiction-aware reference platform; not the centre of the model.
- Fieldbook owns authoritative identity, reference assertions, revisions and publication; Nirnay consumes; Workspace owns contracts and governance.
- First code-bearing work package: FB-REF-001 canonical object and identity core in Fieldbook.
- India design ratification, provider rights and dataset acceptance remain separate owner gates. Freeze unchanged: rights UNKNOWN, dataset BLOCKED, budget INR 0, collection DISABLED, experiments BLOCKED, live execution DISABLED, D11 strict.

## 2026-11-24 — Global reference core programme start

- Workspace PR #9: WS-SCOPE-2026-11-24-001 "Global Reference Core, India First" ratified by owner direction. One scope decision, not 16 ADRs; India design/rights/dataset remain separate gates. APPROVE. Workspace main 773f21f.
- Fieldbook PR #57: FB-REF-001 canonical financial object and identity core. 21 object classes, opaque derived IDs, identifier assertions, four-way resolution, bitemporal ledger, denominator-bearing coverage. 20 abstract tests; 624 passed; full sweeps before gates. CI 45309465082 success. APPROVE. Fieldbook main 4c82802; main CI 45310771854 2/2 after stale-branch rerun.

## 2026-11-24 — FB-REF-002 typed instrument terms

- Fieldbook PR #58 at 399718d: Unit/ExactMeasure checked arithmetic, seven family-typed terms, ContractFamily/ContractInstance, InstrumentTermsRevision/TermsRegistry reusing BitemporalLedger. Rejected at 8447873 for a competing DerivativeKind classification; fixed as a validated newtype over taxonomy::InstrumentKind. 23 tests, 647 passed. CI 45314314973 success. APPROVE. Fieldbook main e747051; main CI 45315060744 2/2 after stale-branch rerun.

## 2026-11-24 — FB-REF-004 jurisdiction venue product registry

- Fieldbook PR #59 at 1a110b0: validated non-enum JurisdictionCode, bitemporal authority/venue/segment/product assertions with fail-closed reference checks, versioned data-extensible CountryPack, four-outcome resolution with no first match. 26 abstract tests with fictional jurisdictions; 673 passed. CI 45316505194 success. APPROVE. Fieldbook main c4bb2d9; main CI 45317373966 2/2.

## 2026-11-24 — FB-REF-005 and Batch A completion

- Fieldbook PR #60 at 49c8a0d: retained-proof EvidenceRef, separate CapabilityState/RightsState, evidence-bound capability verification, four-outcome resolution, explicit 12-state coverage promotion allow-list blocking stage skips and rights-Unknown qualification, denominator requirement. 37 abstract tests; 710 all-targets passed. CI 45319156070 success. APPROVE.
- Batch A (universal reference core) complete at Fieldbook main 78b9d51; main CI 45320046580 2/2 after stale-branch rerun. Components: canonical object identity and bitemporal ledger, typed instrument terms and contract objects, versioned jurisdiction/venue/product registry, evidence-bound capability and coverage registry.
- Next gate: NDC v2 serialization profile ratification (owner decision) before Batch B producer/verifier implementation. India design, rights and dataset acceptance remain separate gates.

## 2026-11-24 — WS-NDC-2026-11-24-002 (NDC v2 Release Serialization Profile 1)

- Owner ratified NDC v2 Release Serialization Profile 1 as a documentation-only cross-repository decision: `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md` (status RATIFIED 2026-11-24, digest `fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc`). Exactly Decisions A–I were approved: complete-manifest JCS with sidecar-only digest, per-artifact record ordering, `artifacts[]` sole inventory, compression-independent dataset digest, single `lineage.supersedes`, no manifest `limits`, durable publication state machine, out-of-band trusted key registry, and independent producer/verifier implementations.
- The D1 circularity change is an approved new revision document, `engineering/conformance/NDC-D1-AMENDMENT-001.md` (approved 2026-11-24, digest `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894`). D1's approved bytes and historical digest `215a5b55…` are unchanged; D0 `3dace660…` and D2 `22eaef7d…` are unchanged; v1 digests and the separate consumer-use `4b9d1fe7…` **Proposed** status are preserved.
- Registries updated in the same worktree: `NDC-REGISTRY.md`, `ADR-REGISTRY.md` (new cross-repository identifier, no historical ADR renumbered), `ENGINEERING-DOC-DIGESTS.json`, the conformance design (prominent approved-amendment section, historical design retained), the conformance matrix (decision references; no implementation state promoted), `README.md` doc map and this log.
- Gates: workspace `make consistency` exit 0 (`CONSISTENCY OK`) and `make audit` exit 0 (status, consistency and both static gate surfaces); local clones were symlinked into the worktree only for the gate run and the symlinks were removed afterwards. No gate was weakened. No Fieldbook fixture/e2e suite, Nirnay full suite, test count or CI run was re-run or combined across heads.
- No commits were created. No source implementation, schema artifact, release, dataset, admission receipt, key (no production key generated or activated), provider contact, collection, rights grant, experiment, live route or India implementation was created. Freeze unchanged: rights `UNKNOWN`, dataset `BLOCKED`, budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict. Batch B is limited to the trust interface with injected test keys plus the paired schema/vector and independent implementation work.

## 2026-11-24 — WP-5 / WS-NDC-INT-001 conformance package

- Cross-repository NDC v2 conformance package created in the docs-only worktree on branch `docs/ndc-v2-conformance`, base `959143e8996960bfaee233e03cf40d063c47316e`. Exact recorded heads: Fieldbook `2ef88a955f74a7c88e4573683267446e331465e9` (PR #62 producer merged) and Nirnay `2dad4962b584c557237d219c1c5356fc58bc4b69` (PR #142 verifier merged). Both clones were clean at those heads; no source file in either repository was edited.
- Created `engineering/conformance/ndc-v2-schema-digest.json` (Profile 1 ratification digest `fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc`, D1 amendment digest `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894`, strict unknown-field policy, source of truth). No standalone published NDC v2 schema artifact exists at these heads; that capability stays **NOT_STARTED** and the typed structs in both repositories are named as implementation authorities.
- Created `engineering/conformance/ndc-v2-acceptance-matrix.md` (ten WP-5 checks with exact `src/...::test_name` and `crates/...::test_name` evidence, both sides' states and typed rejection codes) and `engineering/conformance/ndc-v2-conformance-vectors/` with `VECTORS.md` plus seven abstract non-market vector files: JCS canonicalization, RFC 8032 public test key, canonical manifest and sidecar examples, and three adversarial example files covering ten described mutations. No signing secret, market data, release or dataset is included.
- Created `scripts/check_ndc_conformance_vectors.py`, a workspace evidence checker. It is not a producer, verifier, shared validator or connector. With clones absent it reported 10 passed / 0 failed / 2 explicit skips, exit 0. With the exact-head clones temporarily symlinked it reported 88 passed / 0 failed / 0 skipped, exit 0, after verifying all cited test names in the named source files.
- **Cross-execution NOT_STARTED:** no producer-generated release was verified by a Nirnay binary. There is no shared invocation boundary between the separate repositories and no connector was authorized. Typed representation differences observed at the exact heads are recorded in the WP-5 acceptance matrix, section 3; no wire compatibility is claimed. No `Implemented` state was promoted to `Verified` or `Integrated`.
- Updated `engineering/conformance/ndc-v2-conformance-matrix.md` (WP-5 section 7), `NDC-REGISTRY.md`, this log and the README doc map. Approved D0/D1/D2 digests, v1 digests and the separate consumer-use `4b9d1fe7…` **Proposed** status are unchanged. No gate was weakened and no approved byte was edited.
- Gates: `make consistency` exit 0 (`CONSISTENCY OK`). An initial `make audit` attempt failed at Fieldbook `make check-static` because a prebuilt `xtask` binary retained a compile-time working-directory path that no longer exists; rebuilding that ignored build artifact with `cargo clean -p xtask` resolved the environment issue with no source change and no gate modification. `make audit` then exited 0 (status, consistency and both static gate surfaces). Local clones were symlinked into the worktree only for the gate and checker runs and the symlinks were removed afterwards. No Fieldbook fixture/e2e suite, Nirnay full suite, test count or CI run was re-run or combined across heads.
- No commits were created. Freeze unchanged: rights `UNKNOWN`, dataset `BLOCKED`, budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict. No provider contact, collection, right, key, experiment, India implementation or live route was created.

## 2026-11-24 — Batch B (WP-1 through WP-5) complete with one blocking defect

- WP-1 / Fieldbook PR #61: FB-REF-001A versioned length-framed identity derivation; v2 IDs, legacy derive untouched, 50 call sites inventoried. Rejected at 3e8da47 for a phase-label filename; fixed by renaming to framed_identity.rs. CI 45326087313 success. APPROVE.
- WP-2 / Workspace PR #10: WS-NDC-2026-11-24-002 ratified with D1 amendment; all historical digests and consumer-use Proposed status preserved. APPROVE.
- WP-3 / Fieldbook PR #62: FB-NDC-001 producer; typed manifest, JCS, sidecar-only digest, Ed25519 injected keys, artifact/dataset digests, ordering profiles, publication state machine and receipt. 40 tests, 770 all-targets. CI 45332513321 success. APPROVE.
- WP-4 / Nirnay PR #142: NZ-NDC-001 independent verifier; 12-stage pipeline, O_NOFOLLOW descriptor access, private snapshot, exact file set, receipt. Rejected at 958d4b7 for assertion context; fixed at d732a04 plus partial-snapshot cleanup. CI 45334441330 success. APPROVE.
- WP-5 / Workspace PR #11: conformance matrix, vectors and checker; cross-execution and wire compatibility recorded NOT_STARTED. APPROVE.
- Final heads: Fieldbook 2ef88a9, Nirnay 2dad496, Workspace 998c325. Main CI Fieldbook 45333516324 2/2 (after stale-branch rerun), Nirnay 45335149677 12/12.
- BLOCKING DEFECT: producer and verifier typed manifests differ in seven wire representations (decimal string vs u64 instants, structured vs string operations, Option vs required segment, coverage dimension fields, lineage fields, object vs string record_order_profile, string vs u32 compression_version). No producer-generated release has been verified by the Nirnay binary. Requires owner decision on canonical wire representation; no unilateral rewrite performed.

## 2026-11-24 — IN-CAT-001 and IN-COUNTRY-001 India domain and country-pack design (docs only)

- Docs-only worktree on branch `docs/india-domain-catalogue`, workspace base `14afdfd`. No commit was created and no source repository, schema, contract, release, dataset, experiment or CI file was edited.
- Created `engineering/design/india-national-domain-catalogue.md` (status PROPOSED, awaiting owner ratification): exactly 20 cohorts IN-01..IN-20 with the specified names, each carrying legal/economic object classes, instrument families, contract families and instances, entity relationships, identifier schemes, terms and units, lifecycle, venue and segment applicability, effective time, knowledge time, population authority, coverage denominator, data capabilities and rights dependencies. Includes binding ontology non-conflation rules (index, issuer, listing, repo, corporate action, derivative family), no generic `Other` family, population-type classes with `UNKNOWN`/`UNMEASURABLE` verdicts, the nine separate NDC coverage dimensions, and an I1–I6 migration map that does not make I6 a permanent catch-all.
- Created `engineering/decisions/IN-COUNTRY-001-india-country-pack-design.md` (status PROPOSED, awaiting owner ratification): India country pack as a versioned extension of the global core with IFSC jurisdiction distinction, authorities, market infrastructure, venues/facilities, segments, identifier schemes, currency and monetary rules, calendars, settlement conventions, instrument rules, action classifications, versioned regulation and provenance; effective-time/knowledge-time and bitemporal revision policy; 20-cohort population-completeness policy with as-of and authoritative-source requirements; crosswalk to all 21 implemented `ObjectClass` values with explicit NEW-typed-extension notes; explicit NOT-APPROVED section.
- Updated `README.md` document map with both documents and added this entry. No registry digest, approved byte or historical record was changed.
- Gates: workspace `make consistency` exit 0 (`CONSISTENCY OK`) and `make audit` exit 0 (status, consistency, Fieldbook `make check-static` and Nirnay `make check-static`). Local clones were symlinked into the worktree for the gate run only: Fieldbook `2ef88a955f74a7c88e4573683267446e331465e9`, Nirnay `2dad4962b584c557237d219c1c5356fc58bc4b69`, both clean and ancestors of the bootstrap pins. The symlinks were removed after the gate run. No Fieldbook fixture/e2e suite, Nirnay full suite, test count or CI run was re-run or combined across heads; no gate was weakened.
- Freeze unchanged: rights `UNKNOWN`, dataset `BLOCKED`, budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict. No provider contact, collection, right, dataset acceptance, India implementation or coverage percentage was created or approved.
