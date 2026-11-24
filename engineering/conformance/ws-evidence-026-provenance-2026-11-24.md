# WS-EVIDENCE-026 — Workspace head provenance and D0 evidence scope (2026-11-24)

Status: documentation and JSON reconciliation only. No source, schema, right, data, provider,
India, experiment, release, key or dataset change. No commit is created. Freeze unchanged: rights
`UNKNOWN` (21), dataset acceptance `BLOCKED`, budget INR 0, collection `DISABLED`, experiments
`BLOCKED`, live execution `DISABLED`, M4 holdout untouched, D11 strict.

This record reconciles Workspace head terminology and the D0 evidence scope after the
publication-integrity sprint. It adds no new claim about Fieldbook or Nirnay code, tests, CI,
rights or data.

Supersession notice (2026-11-24, added later without rewriting the historical sections): Fieldbook
PR #74 merged DUR-002 at `4e0f2f5c9ad9ea239b73fdedb3405c5a55f7abd6`, extending D0 fresh-process
evidence to 28 exit points over all 24 owner boundary names. §3 below remains an accurate
**HISTORICAL** record of the three-case scope at the earlier commit; it is superseded for current
D0 evidence by §6 and by `engineering/conformance/d0-full-matrix-evidence-2026-11-24.md`.

## 1. Confirmed Workspace provenance facts

| Item | Value | Basis |
|---|---|---|
| Audited subject head | `6d45af29793485e5b3fce03840228f5d97a34cd9` | PR #23 DUR-001 merge; the exact revision whose documents, gates, reviews and cross-execution evidence were audited. This is **not** the packaged head. |
| Evidence commit / packaged head | `95580f5c92480c6965a4b72d54bf0b6af30f5dbd` | Workspace Git bundle `main` head; the commit that added the PR #24 acceptance records. This is the exact packaged snapshot commit. |
| Hosted CI | `NOT_RUN` | No hosted CI run exists for the Workspace orchestration repository. `ci_verified_source_head.workspace` keeps run_id `NONE_WORKSPACE_NO_CI`; its verification method is `make audit` (static gates), not hosted CI. |
| Static gates | `PASS` | `make consistency` and `make audit` in the docs-only worktree based on tested commit `95580f5c92480c6965a4b72d54bf0b6af30f5dbd` (uncommitted documentation-only changes; no commit created); temporary local clone symlinks were used for the run and removed afterwards. |

No committed file contains its own final commit hash. The exact packaged snapshot commit is
attested by the **external package manifest** (`REVIEW-PACKAGE-QA.md` / package sidecar), not by
an internal workspace file. `CURRENT-STATE.json` records this as
`workspace_package_head_attestation`; no internal document is promoted to package-head authority.

## 2. Terminology note — the five head concepts

The five `CURRENT-STATE.json` head concepts are separately evidenced and are not interchangeable.
The `head_role` value on each Workspace entry states which revision the field denotes.

| Concept | Meaning | Workspace value and role |
|---|---|---|
| `current_source_head` | The currently packaged snapshot head of a repository. | `95580f5` — **PACKAGED_HEAD** (Git bundle `main`). It does not claim the audited subject is the packaged head. The historical sprint final head `6d45af2` is preserved separately. |
| `ci_verified_source_head` | Hosted CI evidence at an exact head. | `6d45af2` — **AUDITED_SUBJECT**. Hosted CI was **not run** for Workspace (`NONE_WORKSPACE_NO_CI`); the recorded verification is `make audit`, a static gate, not hosted CI. |
| `local_tested_source_head` | Local gates and tests at an exact head. | `6d45af2` — **AUDITED_SUBJECT**. Workspace local evidence is `make consistency` and `make audit` only; no full Fieldbook fixture/e2e suite or Nirnay test suite runs in this repository. |
| `cross_execution_source_head` | Binary-to-binary exact-head evidence recorded in the sprint acceptance record. | `6d45af2` — **AUDITED_SUBJECT**. Workspace is the orchestration record for that run, not a producer or verifier binary. |
| `reviewed_source_head` | Independent review at an exact head. | `6d45af2` — **AUDITED_SUBJECT** (PR #22/#23 and paired source reviews). PR #24 added acceptance records; it is the evidence commit, not a new audited subject. |

`workspace_audited_subject_head` (`6d45af2`) and `workspace_evidence_commit` (`95580f5`) are
explicit top-level fields. `publication_integrity_sprint.final_heads.workspace` and the sprint
acceptance record keep `6d45af2` as historical sprint evidence; they are not rewritten to the
packaged head. Legacy mixed head keys (`current_source_heads`, `tested_source_heads`,
`reviewed_source_heads`, `bootstrap_baselines`) remain explicitly HISTORICAL/legacy and are not
promoted by a later commit or CI result.

## 3. D0 evidence scope — HISTORICAL three-case reconciliation (superseded by FB-DUR-002)

At the earlier evidence commit the fresh-process harness covered **exactly three** D0 subprocess cases:

| Case | Process-restart boundary |
|---|---|
| `publish_before` | After the rename syscall, before the rename journal commit. |
| `publish_staging` | After the durable staging-tree journal commit. |
| `publish_rename` | After the durable rename journal commit. |

These three cases are the D0 subprocess evidence. All other boundaries — journal directory sync
failure withholding acknowledgement; staging mkdir, root sync, artifacts mkdir, each file
write/sync, both directory syncs, rename root sync, receipt write/sync/ledger sync, marker
write/sync/ledger sync; recovery from staging and final directory; v1-record readability and
mixed-version refusal — are **in-process fault injection only**. No process restart is claimed as
verified at every committed journal stage. `D0_PROCESS_RECOVERY_VERIFIED` remains **ACHIEVED** for
the stated three-case scope: the scope is neither narrowed to false nor broadened.
`PUBLICATION_DURABILITY_VERIFIED` remains **NOT ACHIEVED** (D1 unqualified). Authority:
`engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` §2.1, §5 and §7, and
`engineering/conformance/publication-integrity-sprint-acceptance-2026-11-24.md`.

## 4. Derived summaries reconciled

`CURRENT-STATE.json` (explicit provenance fields, five Workspace head entries, `durability_profiles`
and both amended document digests), `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md`,
`engineering/conformance/publication-integrity-sprint-acceptance-2026-11-24.md`, `README.md`
document map, `REVIEW-LOG.md`, `NDC-REGISTRY.md` and `ADR-REGISTRY.md` all state the same head
roles, D0 scope, gate result and hosted-CI status. No derived summary is left stale. No
external-facing QA summary is present inside this workspace; the external
`REVIEW-PACKAGE-QA.md` remains the package-head attestation authority and is not edited here.
This paragraph describes the state at the earlier evidence commit; the later DUR-002 reconciliation
is in §6 and in the new dated record, with all derived summaries updated there.

## 5. Gate evidence

- `make consistency` — exit 0, `CONSISTENCY OK`.
- `make audit` — exit 0 (read-only status, consistency, Fieldbook `make check-static` and
  Nirnay `make check-static`).
- Tested workspace commit: `95580f5c92480c6965a4b72d54bf0b6af30f5dbd`; source clones at
  Fieldbook `fd4b542c2df9b775c138a50d068734adedad985e` and Nirnay
  `d3b66f52d500757701f37a21834fde39b89731f4`, both clean on `main`, symlinked into the worktree
  only for the runs and removed afterwards. No gate was weakened; no Fieldbook fixture/e2e suite,
  Nirnay full suite, CI run, hosted CI job, test count or cross-execution was re-run or combined
  across heads. No commit was created.

## 6. FB-DUR-002 supersession of the three-case D0 scope (2026-11-24, added later)

The historical §3 scope was accurate at its own commit and is preserved, not deleted. Fieldbook
PR #74 merged DUR-002 at exact head `4e0f2f5c9ad9ea239b73fdedb3405c5a55f7abd6`, with gate record
`docs/fb-dur-002-subprocess-matrix-2026-11-24.md` (SHA-256
`d8273f87dc9cc392f30edcfcb91d0817723060f84f5d47ea2bef8b8e84091e62` at that commit). The
fresh-process D0 harness now covers **28 concrete exit points covering all 24 owner boundary
names**, with expected outcomes `NO_EVIDENCE` 1, `UNCERTAIN_PUBLICATION_QUARANTINED` 17,
`RECOVERED_STAGED` 2, `RECOVERED_PUBLISHED` 7 and `ALREADY_AVAILABLE` 1. Every `RECOVERED_*` row
also runs an idempotent second recovery returning `ALREADY_AVAILABLE` with byte-identical receipt
and journal. The original `publish_before`, `publish_staging` and `publish_rename` modes stay as
aliases and remain HISTORICAL evidence. In-process fault injection is a separate evidence class
and is not counted among the 28 subprocess exit points.

`D0_PROCESS_RECOVERY_VERIFIED` is a profile-scoped predicate for D0 process termination; the new
scope neither promotes D1–D4 nor makes a global durability claim. D1 OS/filesystem crash and D1b
physical power loss remain unqualified, and `PUBLICATION_DURABILITY_VERIFIED` remains `false` /
NOT ACHIEVED. The five head concepts and packaged-head attestation in §1–§2 are unchanged:
`4e0f2f5` is a D0 evidence commit only, not a new packaged or audited-subject head.

Full row-level table, digests, claim discipline and gate pointers are in
`engineering/conformance/d0-full-matrix-evidence-2026-11-24.md`; `WS-DUR-001` §2.1, §5, §6 and §7,
both registries, `README.md`, `REVIEW-LOG.md` and `CURRENT-STATE.json` were reconciled to agree.
The amended WS-DUR-001 digest is recorded there; the WS-EVIDENCE-026-era digest `d3a18e62…` and
the original ratification digest `2b04f9b…` remain historical.
