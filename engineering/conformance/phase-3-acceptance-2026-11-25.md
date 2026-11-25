# Phase 3 evidence acceptance — 2026-11-25

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **documentation and JSON evidence record only**. No source, schema, right, data, provider,
India, experiment, release, key, dataset, collection, live-execution or CI change is made here, and
no commit is created. Freeze unchanged: rights `UNKNOWN` (21), dataset acceptance `BLOCKED`,
incremental budget INR 0, collection `DISABLED`, experiments `BLOCKED`, M4 holdout `UNTOUCHED`,
D11 strict (synthetic market-shaped tests retired), live execution `DISABLED`. The five separately
evidenced `CURRENT-STATE.json` head concepts are updated to the Phase 3 final heads below; the
Workspace audited-subject / evidence-commit distinction is preserved and no committed file
contains its own final commit hash.

Worktree: `docs/phase3-acceptance`, Workspace base `6dcca8b`. The earlier dated records, including
the publication-integrity sprint acceptance record, the WS-EVIDENCE-026 provenance record and the
D0 full-matrix record, are preserved unchanged; this record adds a current pointer and does not
rewrite their evidence.

## 1. Final heads and hosted CI

| Item | Exact value | Verification method / run |
|---|---|---|
| Fieldbook final head (B15) | `8216197124d33466fbe651e417b7c19505e4155e` | PR #75 merged on `main`; local clean-worktree `git rev-parse HEAD` plus hosted CI run `45491963354`, `success`, `2/2` after stale-branch rerun |
| Nirnay final head (B16) | `c1c2f0d984bee11a63eb1df98833ee8723cd8629` | PR #145 merged on `main`; local clean-worktree `git rev-parse HEAD` plus hosted CI run `45491893837`, `success`, `12/12` |
| Workspace base for this PR | `6dcca8b` | local worktree at the merge of WS #30; this PR adds the acceptance record only |
| Workspace audited subject | `6d45af2` | preserved from `workspace_audited_subject_head`; not the packaged head and not this PR's commit |
| Workspace packaged / evidence commit | `95580f5` | preserved from `workspace_evidence_commit` and external package-manifest attestation; not the audited subject |

Workspace hosted CI remains `NOT_RUN`; its static gates are reported in §8. The packaged snapshot
commit is attested by the external package manifest, not by an internal workspace file. No internal
self-hash is claimed. Fieldbook DUR-002 `4e0f2f5` remains a D0 evidence commit only; it is not a
replacement for any of the five head concepts.

## 2. Merged Phase 3 packages and PRs

| Package / PR | Repository | Contribution | Status |
|---|---|---|---|
| WS #25 — WP0 provenance | Workspace | `ws-evidence-026-provenance-2026-11-24.md`: five head concepts, audited-subject vs packaged-head terminology, external attestation | MERGED; historical scope pointers preserved |
| FB #73 — FB-REC-022 bounded recovery | Fieldbook | bounded `visit_observations` / bounded reader primitive cited by B16 D8 | MERGED |
| WS #26 — B15 design | Workspace | `b15-streaming-producer-design.md`, PROPOSED / AWAITING OWNER APPROVAL | MERGED as design; no implementation claim by the design |
| WS #27 — B16 design | Workspace | `b16-streaming-verifier-design.md`, PROPOSED / AWAITING OWNER APPROVAL | MERGED as design; no implementation claim by the design |
| WS #28 — receipt contract design | Workspace | `NDC-RECEIPT-001-publication-receipt-consumer-contract.md`, PROPOSED | MERGED as design; no ratified schema or receipt created |
| FB #74 — DUR-002 full subprocess matrix | Fieldbook | 28 exit points over 24 owner boundary names, idempotent second recovery; merged at `4e0f2f5` | MERGED; D0 evidence commit only |
| WS #29 — D0 full matrix evidence | Workspace | `d0-full-matrix-evidence-2026-11-24.md` reconciles the D0 evidence and preserves the three-case scope as HISTORICAL | MERGED |
| WS #30 — WS-STREAM-001 architecture ratification | Workspace | owner ratification of A-01..A-12 and OD-01..OD-10 / D1..D10; numeric maxima deferred | MERGED; contract-level only |
| FB #75 — B15 streaming producer implementation | Fieldbook | `src/distribution/ndc_stream.rs`, `src/distribution/stream_profile.rs`; finite `TEST_ONLY` profiles; `docs/fb-b15-streaming-producer-2026-11-24.md` | MERGED at `8216197`; `Implemented`, not `Verified` |
| NZ #145 — B16 streaming verifier implementation | Nirnay | `crates/release-verifier/src/streaming.rs`, `resource_profile.rs`, metadata-only snapshot; `crates/release-verifier/B16-STREAMING-IMPLEMENTATION-2026-11-24.md` | MERGED at `c1c2f0d`; `Implemented`, not `Verified` |

## 3. Final binary cross-execution (FB `8216197` / NZ `c1c2f0d`)

| Check | Result |
|---|---|
| Streaming producer (Fieldbook B15 binary) | PASS |
| Structural stage | PASS |
| Manifest stage | PASS |
| Signature stage | PASS |
| Publisher stage | PASS |
| Artifact stage | PASS |
| Ordering stage | PASS |
| Rights stage (stage 6) | `REJECT_RIGHTS_EVIDENCE` under rights `UNKNOWN` |
| Overall verifier outcome | `RIGHTS_ADMISSION_REFUSED` |
| Nirnay admission receipt | NOT WRITTEN (`receipt_written:false` in the verifier diagnostic) |
| Surviving private snapshot | NONE |
| Dataset | `BLOCKED` |

`receipt_written:false` denotes the absence of a **Nirnay admission receipt**. It is not a claim
that Fieldbook wrote no publication receipt; the Fieldbook publication receipt is a separate local
acknowledgement under the ratified publication contract. Neither receipt grants a right or accepts
a dataset. No stage 7–12 qualification, no rights admission and no dataset acceptance follows from
the passing stages.

## 4. Owner decision at acceptance

- B15/B16 **architecture and interface contracts are RATIFIED** (WS-STREAM-001, A-01..A-12; all
  twenty source decisions resolved individually).
- **All numeric maxima are DEFERRED**, including every `STREAM-RES-1` proposal in B15 §6.2 and the
  PERF-001 256 MiB RSS proposal. No number is a default and no profile digest is registered.
- An **immutable, versioned, role-specific `ResourceProfile` contract is MANDATED**: private
  validated fields, domain-separated digest, `PRODUCER` / `VERIFIER` / `RECOVERY` / `SNAPSHOT`
  roles, and trusted local policy selection.
- The **verifier local ceiling is always applied**; the effective limit is the stricter of the
  consumer local ceiling, the consumer role profile and any producer declaration. Weaker or
  missing producer declarations cannot raise it.
- **Only finite, explicitly marked `TEST_ONLY` profiles** may be used, by a test harness only.
- **No production invocation without an approved role profile** of the correct role; absence,
  role mismatch or digest mismatch fails closed before a source is opened.
- `PERF_001_QUALIFIED` and `OPERATIONALLY_QUALIFIED` remain **BLOCKED**.

## 5. Capability states at acceptance

| State | Value | Gate / meaning |
|---|---|---|
| `STREAMING_IMPLEMENTATION_COMPLETE` | **ACHIEVED** | B15 at FB `8216197` (PR #75) and B16 at NZ `c1c2f0d` (PR #145); bounded streaming paths implemented under finite `TEST_ONLY` profiles; `Implemented` not promoted to `Verified` |
| `STREAM_RESOURCE_PROFILE_RATIFIED` | **PENDING** | Requires owner approval of every numeric limit and one digest per `ProcessingRole`; none registered |
| `PERF_001_QUALIFIED` | **BLOCKED** | PERF-001 not run; no platform, filesystem, device assignment or RSS plateau measurement |
| `PUBLICATION_DURABILITY_VERIFIED` | **false / NOT ACHIEVED** | D1 is not run; D1b and D2–D4 unqualified; no global durability Boolean |
| `OPERATIONALLY_QUALIFIED` | **BLOCKED** | Needs independent review of a full evidence package |
| `RIGHTS_ADMITTED` | **false** | stage 6 `REJECT_RIGHTS_EVIDENCE`; no admission receipt |
| `DATASET_ACCEPTED` | **false** | dataset `BLOCKED` under UNKNOWN rights |
| `D0_PROCESS_RECOVERY_VERIFIED` | **ACHIEVED (D0 only)** | 28-boundary matrix at FB `4e0f2f5` (PR #74), 24 owner boundary names, outcomes 1/17/2/7/1, idempotent second recovery |
| `D1_APFS_QUALIFIED`, `D1_EXT4_QUALIFIED`, `D1b_PHYSICAL_POWER_LOSS_QUALIFIED`, `D2_LOCAL_DEVICE_FAILURE_QUALIFIED`, `D3_HOST_FAILURE_QUALIFIED`, `D4_DISASTER_RECOVERY_QUALIFIED` | **false** | all unqualified; unchanged under WS-DUR-001 |

## 6. Claim discipline and explicit non-claims

1. **Numeric maxima are DEFERRED.** No `STREAM-RES-1` number, no chunk, parser, queue, disk,
   descriptor, memory-budget or duration maximum is approved by this record. Test-only finite
   values are harness inputs, not production maxima and not PERF-001 evidence.
2. **No production invocation without an approved `ResourceProfile`.** The verifier applies its own
   local ceiling, which cannot be relaxed by a producer declaration; digest and role mismatch fail
   closed.
3. **PERF-001 is not run.** No measured RSS plateau, throughput, latency or CPU result is claimed;
   no performance profile, device tier or platform assignment is approved.
4. **D1 is not run.** OS/filesystem crash, physical power loss (D1b) and D2–D4 have no evidence
   here; a rising memory trend or a bounded in-memory test is not a streaming or durability
   qualification.
5. **Freeze unchanged:** INR 0, 21 rights `UNKNOWN`, dataset `BLOCKED`, collection `DISABLED`,
   experiments `BLOCKED`, M4 `UNTOUCHED`, D11 retired synthetic tests strict, live execution
   `DISABLED`.
6. No `Implemented` state is promoted to `Verified` by wording. No right, dataset, release, key,
   schema byte, provider contact, collection, India artefact, experiment or live route is created
   by this record.
7. No internal self-hash: no committed Workspace file contains its own final commit hash, and
   Workspace hosted CI remains `NOT_RUN`.

## 7. Derived summaries reconciled

`CURRENT-STATE.json` (five head concepts, CI runs, legacy `current_source_heads`, capability flags,
`phase3_acceptance` record, journal/package and sprint pointers, evidence-manifest pointer,
durability profiles), `NDC-REGISTRY.md`, `ADR-REGISTRY.md`, `ENGINEERING-DOC-DIGESTS.json`, the
`README.md` document map and `engineering/evidence/REVIEW-LOG.md` all point to this acceptance record for Phase 3
current status. Historical records — the sprint acceptance record, WS-EVIDENCE-026, the D0
full-matrix record, the dated cross-execution and evidence-manifest records, and the earlier head
and CI observations — are preserved unchanged and referenced by pointer, not rewritten.

## 8. Gate evidence

Read-only gates were run in this docs/JSON-only worktree with clean local clones symlinked in only
for the runs; the symlinks were removed afterwards. No Fieldbook fixture/e2e suite, Nirnay full
suite, hosted CI job, test count or cross-execution was re-run or combined across heads here.

- `make consistency` — exit 0, `CONSISTENCY OK`, at FB `8216197` / NZ `c1c2f0d`.
- `make audit` — exit 0 (read-only status, consistency, Fieldbook `make check-static` and Nirnay
  `make check-static`, 47 PASS lines) at the same heads. A fresh `CARGO_TARGET_DIR` was used for
  the Nirnay gate so that `cargo xtask` rebuilt from the exact clone in use rather than reusing a
  stale locally cached binary from another worktree; this changed no source or gate definition.
- Exact commands, exits and observed heads are recorded in `engineering/evidence/REVIEW-LOG.md` under 2026-11-25.
  No commit was created.
