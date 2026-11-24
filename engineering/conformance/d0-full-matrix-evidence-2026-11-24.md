# D0 full-matrix evidence — FB-DUR-002 subprocess boundary matrix (2026-11-24)

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: documentation and JSON evidence record only. No source, schema, right, data, provider,
India, experiment, release, key, dataset, collection, live-execution or CI change is made here, and
no commit is created. Freeze unchanged: rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget
INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict. The
programme freeze and the five separately evidenced `CURRENT-STATE.json` head concepts are not
reopened by this record.

Evidence date: 2026-11-24 (Fieldbook PR #74 merged at 2026-11-25 01:12:43 IST, equivalent to
2026-11-24 19:42:43 UTC). This is a new dated record; the earlier three-case reconciliation and
the sprint acceptance record are preserved as HISTORICAL evidence and are not rewritten.

## 1. Authority and exact evidence commit

| Item | Record |
|---|---|
| Source package | Fieldbook **DUR-002**, PR #74, branch `test/dur-002-subprocess-matrix`, merged at Fieldbook `4e0f2f5c9ad9ea239b73fdedb3405c5a55f7abd6` (parents `cabf1be3c9df0f267601282ed739e2973afb2931` and `b64caa1fb40b6cb6c4758b8afbfd78bf0950a2ec`) |
| Gate record | Fieldbook `docs/fb-dur-002-subprocess-matrix-2026-11-24.md` at that exact merged commit |
| Gate-record digest | `d8273f87dc9cc392f30edcfcb91d0817723060f84f5d47ea2bef8b8e84091e62` — `shasum -a 256` of the record read from `git show HEAD:docs/fb-dur-002-subprocess-matrix-2026-11-24.md` at Fieldbook `4e0f2f5c9ad9ea239b73fdedb3405c5a55f7abd6`. This is a gate-record digest, not an independent durability certificate and not a `Verified` promotion. |
| Extends | Fieldbook FB-PUB-020 fresh-process recovery evidence, itself extending FB-PUB-019 bottom-up directory durability |
| Governing decision | `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` (tier predicates, acknowledgement contract, invariants I-01..I-15); the amended decision digest is recorded in the registries and `CURRENT-STATE.json` |
| Superseded historical scope | `engineering/conformance/ws-evidence-026-provenance-2026-11-24.md` §3 recorded exactly three subprocess cases; it remains accurate for its own commit and is HISTORICAL, superseded for current D0 evidence by this matrix |

Fieldbook `4e0f2f5` is a **D0 evidence commit only**. It does not change the separately evidenced
five head concepts in `CURRENT-STATE.json` (`current_source_head`, `ci_verified_source_head`,
`local_tested_source_head`, `cross_execution_source_head`, `reviewed_source_head`), any packaged
head attestation, any hosted CI record or any cross-execution head. No source head is re-labelled
by this documentation work.

## 2. Failure model — D0 process termination only

The Fieldbook harness ends one publisher child process with `process::exit` at a chosen durable
boundary; destructors do not run. A second child process reconciles the operation from the release
root, ledger, operation id and resource profile id alone. No evidence object, receipt object or
other in-memory value crosses a process boundary. For `RECOVERED_*` rows a third child runs the
same recovery a second time and the result must be `ALREADY_AVAILABLE`.

This is **D0 process termination only**. The OS, filesystem and storage device remain functional.
It is not a D1 OS/filesystem crash test, not a D1b physical power-loss test, and not a storage
controller, write-cache, rename-under-power-loss or filesystem-recovery qualification. No global
durability claim follows from it.

## 3. Concrete exit points and expected outcomes

The matrix has **28 concrete exit points covering all 24 owner boundary names** (the numbered
per-artifact write and sync exit points share one owner boundary name per group). The expected
outcome table was fixed before the tests ran. `1` = `manifest.json`, `2` = `signature.json`,
`3` = `artifacts/a.jsonl`.

| Exit point | Owner boundary | Expected outcome |
|---|---|---|
| `before_intent_creation` | before intent creation | `NO_EVIDENCE` |
| `intent_file_written` | after intent file write | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `intent_file_synced` | after intent file sync | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `intent_ledger_synced` | after intent ledger-dir sync | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `staging_mkdir` | after staging mkdir | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `release_root_synced` | after release-root sync | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `staging_entry_durable` | after `STAGING_ENTRY_DURABLE` | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_dir_created` | after artifact-dir creation | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_write_1` | after every artifact write (1) | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_write_2` | after every artifact write (2) | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_write_3` | after every artifact write (3) | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_sync_1` | after every artifact file sync (1) | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_sync_2` | after every artifact file sync (2) | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_sync_3` | after every artifact file sync (3) | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `artifact_dir_synced` | after artifact-dir sync | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `staging_dir_synced` | after staging-dir sync | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `staging_tree_durable` | after `STAGING_TREE_DURABLE` | `RECOVERED_STAGED` |
| `staging_validated` | after staging validation | `RECOVERED_STAGED` |
| `rename_committed` | after rename before rename journal commit | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `rename_root_synced` | after release-root sync | `UNCERTAIN_PUBLICATION_QUARANTINED` |
| `rename_durable` | after `RENAME_DURABLE` | `RECOVERED_PUBLISHED` |
| `receipt_written` | after receipt write | `RECOVERED_PUBLISHED` |
| `receipt_synced` | after receipt sync | `RECOVERED_PUBLISHED` |
| `receipt_ledger_synced` | after ledger sync for receipt | `RECOVERED_PUBLISHED` |
| `marker_written` | after marker write | `RECOVERED_PUBLISHED` |
| `marker_synced` | after marker sync | `RECOVERED_PUBLISHED` |
| `marker_ledger_synced` | after final ledger sync | `RECOVERED_PUBLISHED` |
| `available` | after `AVAILABLE` | `ALREADY_AVAILABLE` |

### Outcome distribution

| Outcome | Count |
|---|---|
| `NO_EVIDENCE` | 1 |
| `UNCERTAIN_PUBLICATION_QUARANTINED` | 17 |
| `RECOVERED_STAGED` | 2 |
| `RECOVERED_PUBLISHED` | 7 |
| `ALREADY_AVAILABLE` | 1 |
| **Total** | **28** |

Each row represents one fresh publisher child and one fresh recovery child. The three earlier
FB-PUB-020 modes (`publish_before`, `publish_staging`, `publish_rename`) remain as aliases of
matrix exit points with their original marker strings; their three-case record is preserved as
HISTORICAL evidence and is no longer the whole D0 scope.

### Idempotent second recovery

For each `RECOVERED_STAGED` and `RECOVERED_PUBLISHED` row, recovery is run a second time and must
return `ALREADY_AVAILABLE`. The receipt bytes and journal chain are byte-identical; the receipt
keeps the original operation id, commit position, release identity and absent predecessor; the
final stage stays `AVAILABLE`; the final release directory exists; and the ledger holds one marker
file bound to the original operation id. Quarantine and no-evidence rows check one outcome and
leave durable evidence untouched. No boundary collapses into a generic error.

## 4. In-process fault injection remains separate

In-process fault-injection tests are **not** fresh-process/subprocess D0 evidence and are not
counted in the 28 exit points. They include journal directory sync failure withholding
acknowledgement, staging mkdir, root sync, artifacts mkdir, each file write/sync, both directory
syncs, rename, rename root sync, receipt write/sync/ledger sync, marker write/sync/ledger sync,
recovery from staging and final directory, v1-record readability and mixed-version refusal, and
the FB-DUR-002 named tests such as `staging_mkdir_crash_withholds_the_entry_claim`,
`receipt_write_crash_preserves_receipt_fidelity` and
`marker_ledger_sync_crash_preserves_receipt_fidelity`. They remain separate offline injected-error
evidence at their own heads.

## 5. Claim discipline

1. `D0_PROCESS_RECOVERY_VERIFIED` is a profile-scoped predicate for the D0 process-termination
   profile. The current evidence scope is the 28-exit-point matrix at Fieldbook `4e0f2f5`; the
   earlier three-case statement is HISTORICAL and superseded for current evidence.
2. D1 OS/filesystem crash and D1b physical power loss remain **unqualified**:
   `D1_APFS_QUALIFIED=false`, `D1_EXT4_QUALIFIED=false`; VM reset is not a power-loss test;
   `F_FULLFSYNC` is not used or qualified. D2 local device failure, D3 host failure and D4 disaster
   recovery also remain `false`.
3. There is **no global durability Boolean**. `PUBLICATION_DURABILITY_VERIFIED` remains `false`
   in both `ndc_profile_status.statuses` and `production_builder_parity.capability_states`, and is
   **NOT ACHIEVED** until D1 evidence exists for a declared APFS or ext4 profile. D1–D4 are not
   promoted, and this record does not promote `Implemented` to `Verified`.
4. A local publication receipt is a local acknowledgement only: it grants no source authenticity,
   coverage, right, dataset entitlement, Nirnay admission or global durability claim.

## 6. Derived summaries reconciled

`engineering/decisions/WS-DUR-001-publication-durability-failure-model.md`,
`engineering/conformance/ws-evidence-026-provenance-2026-11-24.md` (HISTORICAL scope with a
supersession note), `engineering/conformance/publication-integrity-sprint-acceptance-2026-11-24.md`
(historical sprint scope with a dated post-sprint note), `CURRENT-STATE.json` (durability profile
booleans, digests, evidence head and journal/package note), `NDC-REGISTRY.md`, `ADR-REGISTRY.md`,
`README.md` and `REVIEW-LOG.md` agree on this scope. No external-facing QA summary is present in
this workspace and none is edited here.

## 7. Gate evidence

Commands are read-only and were run in the docs-only worktree with clean local clones symlinked in
only for the runs; the symlinks were removed afterwards. No Fieldbook fixture/e2e suite, Nirnay
full suite, CI run, hosted CI job, test count or cross-execution was re-run or combined across
heads. Exact commands, exits and observed heads are recorded in `REVIEW-LOG.md`.

- `make consistency` — exit 0, `CONSISTENCY OK`.
- `make audit` — exit 0 (read-only status, consistency, Fieldbook `make check-static` and Nirnay
  `make check-static`).
- Observed heads: Fieldbook `4e0f2f5c9ad9ea239b73fdedb3405c5a55f7abd6` and Nirnay
  `d3b66f52d500757701f37a21834fde39b89731f4`, both clean on `main` and descendants of the
  historical lock pins; symlinks were removed after the runs. No commit was created.
