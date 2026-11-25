# Phase 3A evidence acceptance — 2026-11-25

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **documentation and JSON evidence record only**. No source, schema, right, data, provider,
India, experiment, release, key, dataset, collection, live-execution or CI change is made here, and
no commit is created. Freeze unchanged: rights `UNKNOWN` (21), dataset acceptance `BLOCKED`,
incremental budget INR 0, collection `DISABLED`, experiments `BLOCKED`, M4 holdout `UNTOUCHED`,
D11 strict (synthetic market-shaped tests retired), live execution `DISABLED`,
`PUBLICATION_DURABILITY_VERIFIED` `false` and Workspace hosted CI `NOT_RUN`.

Worktree: branch `docs/phase3a-acceptance`, Workspace base
`d12b5b9880e23085c17f206dd48ec73e7fe13f61`. This is a follow-on to the Phase 3 acceptance record
`engineering/conformance/phase-3-acceptance-2026-11-25.md`, which is **preserved unchanged** as
HISTORICAL evidence at its own heads. This record updates the five separately evidenced
`CURRENT-STATE.json` head concepts to the Phase 3A final heads, adds the Phase 3A package ledger and
reconciles the derived summaries. The Workspace audited-subject / packaged-head distinction is
preserved and no committed Workspace file contains its own final commit hash.

## 1. Final heads and hosted CI

| Item | Exact value | Verification method / run |
|---|---|---|
| Fieldbook final head | `acbd9b683d86ba6fbb62f7170f8852b23876e3aa` | clean local clone on `main`, `git rev-parse HEAD` + `git status --short` (empty); hosted CI run `45621903705`, `success`, `2/2`, after deleting stale merged remote branches and rerunning; descendant of the lock pin |
| Nirnay final head | `c2c51757b0aeca94d2eacf651e8861e1937f74c8` | clean local clone on `main`, `git rev-parse HEAD` + `git status --short` (empty); hosted CI run `45612047715`, `success`, `12/12`; descendant of the lock pin |
| Workspace base for this PR | `d12b5b9880e23085c17f206dd48ec73e7fe13f61` | local docs/JSON-only worktree at this base; no commit is created here |
| Workspace audited subject | `6d45af29793485e5b3fce03840228f5d97a34cd9` | preserved from `workspace_audited_subject_head`; not the packaged head and not this PR's commit |
| Workspace packaged / evidence commit | `95580f5c92480c6965a4b72d54bf0b6af30f5dbd` | preserved from `workspace_evidence_commit` and external package-manifest attestation; not the audited subject |

Workspace hosted CI remains `NOT_RUN`; its static gates are reported in §8. The packaged snapshot
commit is attested by the external package manifest, not by an internal Workspace file. No internal
self-hash is claimed. Fieldbook DUR-002 `4e0f2f5` remains a D0 evidence commit only, and the Phase 3
heads `8216197` / `c1c2f0d` remain HISTORICAL Phase 3 evidence; neither replaces any of the five
head concepts.

## 2. Merged Phase 3A package ledger

| Package / PR | Repository | Merge commit on `main` | Contribution |
|---|---|---|---|
| NZ #146 — NZ-RES-001 trusted profile admission | Nirnay | `5f114e337342cf92f156cd8d033132640455c55d` | verifier-owned `ProfileResolver`; approved registry inside the verifier, locator-only streaming entry point, `TEST_ONLY` resolver, stricter-of effective limits |
| FB #76 — FB-STREAM-001 plan/source pairing | Fieldbook | `5f3321d11a268b4cd20332ce5cf3b710a7f1c7bf` | canonical sort binding `sources` to the publication plan so plan/source position cannot silently diverge |
| NZ #147 — NZ-REG-001 payload registry | Nirnay | `2f35e2a0fbcea6b7c5e690d4d139caa0b64176da` | per-event payload schema registry enforced at stage five with `REJECT_PAYLOAD_REGISTRY`; registry hit and miss cases |
| NZ #148 — NZ-LIMIT-001 parser bounds | Nirnay | `c24bc299e102c3f2f9ef46d5eb6eb477e5cd7d01` | exact member/field counts instead of comma counting; checked addition on externally influenced framer and parser counters |
| FB #77 — FB-LIMIT-001 expansion ratio | Fieldbook | `e0d065e0298da3a97a191eab08f69ae53bff0865` | producer expansion ratio measured against stored bytes with an explicit zero-stored-byte rule |
| FB #78 — FB-STREAM-002 durable quarantine | Fieldbook | `98d3c9511c8f99a1d92e237aa09f9c6bcc14163c` | typed pre-seal quarantine state and evidence surface for bounded streaming preparation |
| NZ #149 — NZ-LIMIT-002 artifact/concurrency | Nirnay | `7d4bd470af3a6b3b6556fa44ce343b0787a6cb2b` | separates total artifact inventory from concurrent-artifact concurrency dimensions |
| FB #79 — FB-SPOOL-001 multi-source spool | Fieldbook | `c8ac3f0c53efa2f3b4020252128bcaa38e0c9e6f` | multi-artifact non-replayable spool identity and durability rules with an explicit budget boundary |
| FB #80 — FB-SOURCE-001 core-owned record port | Fieldbook | `acbd9b683d86ba6fbb62f7170f8852b23876e3aa` | core-owned bounded record port; closes the caller-supplied source path without a production profile claim |
| NZ #150 — NZ-API-001 streaming cross-execution harness | Nirnay | `c2c51757b0aeca94d2eacf651e8861e1937f74c8` | `cfg(test)` harness plus driver for an owner-supplied Fieldbook B15 producer binary; explicit skip when none is supplied; buffers kept as `LEGACY_BUFFERED` with no fallback |
| WS #31 / #32 — Phase 3 acceptance and streaming doc sync | Workspace | merged before this base | Phase 3 acceptance record and WS-DOC-001 B15/B16 design synchronization; documentation only |

All packages above are **MERGED at the exact heads shown**. Each package record on its own repository
states `Implemented`; none promotes an `Implemented` state to `Verified`, approves a numeric maximum,
creates a production profile, grants a right, accepts a dataset or changes the freeze. The package
records in the source repositories (`docs/fb-*-2026-11-24.md` and
`crates/release-verifier/NZ-*-2026-11-24.md`) remain the authorities for their own gate results;
this record cites them by pointer and does not re-run their tests.

## 3. Stream contract conformance and the actual cross-execution gate

The B15/B16 stream-contract conformance items are closed by the merged packages in §2 **except the
actual B16 streaming cross-execution**:

- NZ-RES-001, FB-STREAM-001, NZ-REG-001, NZ-LIMIT-001, FB-LIMIT-001, FB-STREAM-002, NZ-LIMIT-002,
  FB-SPOOL-001 and FB-SOURCE-001 are merged and their defects/records are closed at the exact heads
  in §2. These are conformance corrections, not capability promotions.
- NZ-API-001 (NZ #150) merged a **harness**, not a cross-execution result. The harness invokes a
  Fieldbook B15 streaming producer binary only when one is supplied; with no binary it emits an
  explicit skip and writes no release. No producer bytes are simulated and the buffered verifiers
  are not substituted.

**Actual B16 streaming cross-execution remains `NOT_RUN` and must not be counted as evidence.** The
driver and producer-dependent tests skip with the explicit reason that `NIRNAY_B15_PRODUCER_BIN` is
unset or does not name an executable Fieldbook B15 streaming producer. No external B15 streaming
producer binary exists in either local clone: Fieldbook's `InvocationContext::TestHarness` and
`ResourceProfile::new_test_only` are `cfg(test)`-only and cannot be selected from the published
library by a separate executable. The public conformance producer uses the buffered `build_release`
path and is not a B15 streaming source. The Nirnay-local `TEST_ONLY` tests that did run (mutation,
legacy-classification, stage-observer and payload-registry cases) are local fixtures and are **not**
producer output or cross-execution evidence. See
`crates/release-verifier/NZ-API-001-STREAMING-CROSS-EXECUTION-2026-11-24.md` in Nirnay.

The Phase 3 non-streaming binary cross-execution at FB `8216197` / NZ `c1c2f0d` (structural stages
PASS, stage 6 `REJECT_RIGHTS_EVIDENCE`, no admission receipt, dataset `BLOCKED`) remains HISTORICAL
evidence in its own dated record. It is not a B15/B16 streaming cross-execution and is not promoted
to one by this acceptance.

## 4. Owner decision and claim discipline

1. **Architecture and interface contracts remain RATIFIED** at the contract level under
   `WS-STREAM-001` (A-01..A-12; all twenty source decisions resolved individually). Phase 3A merges
   conformance corrections; it does not reopen or re-ratify a contract.
2. **All numeric maxima remain DEFERRED.** No `STREAM-RES-1` number, chunk, parser, queue, disk,
   descriptor, memory-budget, duration, concurrency or throughput maximum is approved. No number is
   a default and no production profile digest is registered. Finite `TEST_ONLY` values are harness
   inputs, not production maxima.
3. **No production `ResourceProfile` exists.** Only finite, explicitly marked `TEST_ONLY` profiles
   may be used, by a test harness only. No production invocation is permitted without an approved
   role-specific profile of the correct role (`PRODUCER`, `VERIFIER`, `RECOVERY`, `SNAPSHOT`);
   absence, role mismatch or digest mismatch fails closed before a source is opened. The verifier's
   local ceiling is always applied and cannot be raised by a producer declaration.
4. **PERF-001 is not run.** No platform, filesystem, device assignment, RSS plateau, throughput,
   latency or CPU result is claimed. **PERF-BASE-001 serial performance baseline is not run.** No
   performance profile, device tier or platform assignment is approved. `PERF_001_QUALIFIED` is
   BLOCKED.
5. **D1 is not run.** OS/filesystem crash, physical power loss (D1b) and D2–D4 remain unqualified;
   `PUBLICATION_DURABILITY_VERIFIED` is `false` / NOT ACHIEVED and no global durability Boolean is
   claimed. The D0 28-boundary matrix at `4e0f2f5` is profile-scoped D0 evidence only.
6. **Freeze unchanged:** INR 0, 21 rights `UNKNOWN`, dataset `BLOCKED`, collection `DISABLED`,
   experiments `BLOCKED`, M4 `UNTOUCHED`, D11 retired synthetic tests strict, live execution
   `DISABLED`.
7. **No `Implemented`-to-`Verified` promotion** by wording. No right, dataset, release, key, schema
   byte, provider contact, collection, India artefact, experiment or live route is created here.
8. **No internal self-hash:** no committed Workspace file contains its own final commit hash, and
   Workspace hosted CI remains `NOT_RUN`.

## 5. Capability states at Phase 3A acceptance

| State | Value | Gate / meaning |
|---|---|---|
| `STREAMING_IMPLEMENTATION_COMPLETE` | **ACHIEVED** | B15 producer and B16 verifier implemented under finite `TEST_ONLY` profiles; Phase 3A conformance items in §2 merged; `Implemented`, not `Verified` |
| B15/B16 stream-contract conformance items | **CLOSED except actual B16 streaming cross-execution** | NZ-RES-001, FB-STREAM-001, NZ-REG-001, NZ-LIMIT-001, FB-LIMIT-001, FB-STREAM-002, NZ-LIMIT-002, FB-SPOOL-001, FB-SOURCE-001 merged; NZ-API-001 harness merged |
| `B16_STREAMING_CROSS_EXECUTION` | **NOT_RUN** | NZ-API-001 harness skips with explicit reason; no external B15 streaming producer binary (`cfg(test)`-only); not counted as evidence |
| `STREAM_RESOURCE_PROFILE_RATIFIED` | **PENDING** | requires owner approval of every numeric limit and one digest per `ProcessingRole`; none registered |
| `PERF_001_QUALIFIED` | **BLOCKED** | PERF-001 and PERF-BASE-001 not run; no RSS plateau, throughput, latency or CPU result |
| `PUBLICATION_DURABILITY_VERIFIED` | **false / NOT ACHIEVED** | D1 not run; D1b and D2–D4 unqualified; no global durability Boolean |
| `OPERATIONALLY_QUALIFIED` | **BLOCKED** | needs independent review of a full evidence package |
| `RIGHTS_ADMITTED` | **false** | no streaming admission; rights `UNKNOWN` (21) |
| `DATASET_ACCEPTED` | **false** | dataset `BLOCKED` under `UNKNOWN` rights |
| `D0_PROCESS_RECOVERY_VERIFIED` | **ACHIEVED (D0 only)** | 28-boundary matrix at FB `4e0f2f5` (PR #74), unchanged and profile-scoped |
| `D1_APFS_QUALIFIED`, `D1_EXT4_QUALIFIED`, `D1b_PHYSICAL_POWER_LOSS_QUALIFIED`, `D2_LOCAL_DEVICE_FAILURE_QUALIFIED`, `D3_HOST_FAILURE_QUALIFIED`, `D4_DISASTER_RECOVERY_QUALIFIED` | **false** | all unqualified; unchanged under WS-DUR-001 |

## 6. Outstanding gates

- `NZ-API-001` actual B15-producer-to-B16-verifier streaming cross-execution: **NOT_RUN**, harness
  skip with explicit reason; not evidence. Supplying a paired external B15 streaming producer is a
  separate future work item.
- `PERF-BASE-001` serial performance baseline: **NOT_RUN**. `PERF-001` qualification: **BLOCKED**.
- `STREAM_RESOURCE_PROFILE_RATIFIED`: **PENDING** — no approved numeric maxima and no production
  role profile digest.
- `PUBLICATION_DURABILITY_VERIFIED`: **false** — D1 (APFS/ext4) and D1b physical power loss, plus
  D2–D4, unqualified.
- `OPERATIONALLY_QUALIFIED`: **BLOCKED** — no full evidence package reviewed.
- `RIGHTS_ADMITTED` and `DATASET_ACCEPTED`: **false** — rights `UNKNOWN`, dataset `BLOCKED`.
- `NDC-RECEIPT-001` publication-receipt consumer contract: **PROPOSED**, not ratified; Fieldbook
  publication receipt and Nirnay admission receipt remain separate objects.

## 7. Derived summaries reconciled

`CURRENT-STATE.json` is updated as follows: the five head concepts (`current_source_head`,
`ci_verified_source_head`, `local_tested_source_head`, `cross_execution_source_head`,
`reviewed_source_head`) and the legacy `current_source_heads` carry the Phase 3A final heads with
their run IDs and methods; `phase3a_acceptance` (record, digest, heads, CI, ledger, capability
states, claim discipline) and `phase3a_capability_states` are added; `ci` and `historical CI` carry
the new run IDs and preserve the Phase 3 runs as HISTORICAL; `evidence_manifest`,
`static_gate_results`, `journal_and_packages`, durability profiles, `evidence_audit_status`,
`release_correctness`, `implementation_component_status`, `reviewed_commit_ids`,
`workspace_static_gates`, `workspace_head_terminology`, `production_builder_parity` and
`publication_integrity_sprint` pointers are reconciled to Phase 3A current status. Phase 3 evidence
is retained by pointer and its record files are unchanged. `NDC-REGISTRY.md`, `ADR-REGISTRY.md`,
`ENGINEERING-DOC-DIGESTS.json`, the `README.md` document map and `engineering/evidence/REVIEW-LOG.md` carry matching
dated entries. No summary claims an actual streaming cross-execution, a production profile, a
numeric maximum, PERF-001, a new durability tier or a capability promotion.

## 8. Gate evidence

Read-only gates were run in this docs/JSON-only worktree with clean local clones of the two exact
final heads symlinked in only for the runs; the symlinks were removed afterwards. A fresh
`CARGO_TARGET_DIR` was used so Nirnay's `cargo xtask` rebuilt from the exact clone in use rather
than a stale cached binary from another worktree. No gate was weakened, and no Fieldbook
fixture/e2e suite, Nirnay full suite, hosted CI job, test count or streaming cross-execution was
re-run or combined across heads here.

- `make consistency` — exit 0, `CONSISTENCY OK`, at FB `acbd9b683d86ba6fbb62f7170f8852b23876e3aa`
  and NZ `c2c51757b0aeca94d2eacf651e8861e1937f74c8`, both clean on `main` and descendants of the
  lock pins.
- `make audit` — exit 0 (`status` + `consistency` + Fieldbook `make check-static` + Nirnay
  `make check-static`, 47 PASS lines) at the same heads.

Exact commands, exits and observed heads are recorded in `engineering/evidence/REVIEW-LOG.md` under 2026-11-25.
No commit was created.
