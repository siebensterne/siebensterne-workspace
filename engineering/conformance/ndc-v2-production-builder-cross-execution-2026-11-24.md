# WS-NDC-INT-002 / FB-NDC-013 — production-builder cross-execution evidence baseline, 2026-11-24

> **CURRENT STATUS: HISTORICAL.** Superseded for current evidence by `phase-3a-acceptance-2026-11-25.md`.

Status: **EVIDENCE RECONCILIATION (docs only)**, dated `2026-11-24`,
verification timestamp `2026-11-24T15:06:04Z`. This dated record consolidates the
final production-builder cross-execution evidence at the exact commits below.
It does not re-run a binary in this reconciliation, does not change any source
repository, schema, right, data, provider or India artefact, and claims no new
capability. Rights remain `UNKNOWN` and dataset acceptance remains `BLOCKED`.

This record supersedes stale head wording and clarifies the two distinct
receipts in earlier records. It does not overwrite or delete those records: the
conformance-path cross-execution and the earlier FB-NDC-013 production-builder
parity section in `engineering/conformance/ndc-v2-cross-execution-2026-11-24.md`
are explicitly **HISTORICAL** and preserved unchanged there.

## Exact commits

| Repository / role | Commit | Evidence state at reconciliation |
|---|---|---|
| Fieldbook production builder and canonical wire mapping | `475dc34c8cc510ac8dfba158dfdedbd91950f219` | current, CI-verified, locally tested, cross-executed, reviewed; clean `main` worktree |
| Nirnay independent verifier and wire mapping | `70716ebf66289a86335641847724fd92bf6bcce7` | current, CI-verified, locally tested, cross-executed, reviewed; clean `main` worktree |
| Workspace orchestration repository and canonical schema package | `62b617c380ea97cd2a68f67c880a1f652ef14961` | current, locally tested by workspace `make audit`, reviewed; clean `main` worktree; **no CI run recorded** |

Hosted CI evidence: Fieldbook run `45406722498` (2/2 success) at
`475dc34c8cc510ac8dfba158dfdedbd91950f219`; Nirnay run `45357742748` (12/12
success) at `70716ebf66289a86335641847724fd92bf6bcce7`. Both conclusions are
recorded in `engineering/evidence/REVIEW-LOG.md`. No hosted CI run is recorded for the workspace
repository; its verification method is the workspace `make audit` gate, not CI.
CI executes static gates only; neither full test suite was run by CI and no test
count is combined across heads.

### Historical predecessors (preserved, not promoted)

| Role | Commit | Status |
|---|---|---|
| Fieldbook conformance-path atomic publication correction (B12, PR #65) | `071da27ed6512fb38c29ada679d76dd0e30ddb6b` | **HISTORICAL** cross-execution head; conformance-path record preserved |
| Fieldbook FB-NDC-013 PR #66 head | `001e2688ed4863919e2eb8d35c47ee05615e755a` | **HISTORICAL** production-builder parity PR head |
| Fieldbook FB-NDC-013 merged main (PR #66) | `5703185d59b1ccfeaa310926f26e006abf8ac72c` | **HISTORICAL** merged production-builder parity head |
| Nirnay verifier (unchanged across all above) | `70716ebf66289a86335641847724fd92bf6bcce7` | also the current reviewed verifier head |
| Fieldbook / Nirnay RRP-001 reviewed measurement heads | `3c3279bdaa8df6aa44018184fefb662e98b5e0c1` / `f6842d2b6438c657c4d4eaec8edb3920193d2181` | **HISTORICAL**; manifest measurement only |
| Fieldbook / Nirnay bootstrap pins | `28eb8779ea2aab67ce471d9d3e9f222faf8f7327` / `437179a8fdd0b1935420d1467f9a5c8a60da824d` | **HISTORICAL** bootstrap pins in `WORKSPACE.lock.json`, unchanged |

## Commands

Head observations for this reconciliation (read-only, clean worktrees):

```
git -C /Users/tourist/Documents/siebensterne-workspace/fieldbook rev-parse HEAD
git -C /Users/tourist/Documents/siebensterne-workspace/fieldbook status --short
git -C /Users/tourist/Documents/siebensterne-workspace/nirnay rev-parse HEAD
git -C /Users/tourist/Documents/siebensterne-workspace/nirnay status --short
git -C /Users/tourist/Documents/siebensterne-workspace rev-parse HEAD
git -C /Users/tourist/Documents/siebensterne-workspace status --short
```

The producer and verifier command surface of the recorded final cross-execution
(at Fieldbook `475dc34f` / Nirnay `70716eb`) is the same as the historical
FB-NDC-013 production-builder run, reproduced here verbatim from the canonical
record:

```
target/debug/ndc-conformance-producer \
  --spec docs/specifications/ndc-conformance-producer-spec-example-2026-11-24.json \
  --out <root>/publisher-abstract/dataset-abstract

nirnay/target/debug/ndc-conformance-verifier \
  --release <root>/publisher-abstract/dataset-abstract/conformance-release-2 \
  --out <diagnostic.json>
```

The `--out` argument is the dataset root. The production builder writes the
final immutable release into `conformance-release-2` beneath that root and its
ledger beside it. The signing key is the fixed conformance seed `[0x11; 32]`,
present in neither the release package nor any production configuration.

Evidence and gate commands used by this reconciliation:

```
make consistency
make audit
python3 scripts/check_ndc_schema_package.py
shasum -a 256 WORKSPACE.lock.json
shasum -a 256 engineering/evidence/REVIEW-LOG.md
shasum -a 256 engineering/conformance/ndc-v2-cross-execution-2026-11-24.md
shasum -a 256 engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md
```

The canonical cross-execution record digest is
`82bc253760ada2e932931877092d93e7238f95a33709844a956870140dea1f0b`
(`shasum -a 256 engineering/conformance/ndc-v2-cross-execution-2026-11-24.md`).
No separate self-digest is published in the historical production-builder
section, so this canonical file digest is the cross-execution evidence digest
recorded in `CURRENT-STATE.json`.

## Exact release layout

```
<root>/publisher-abstract/dataset-abstract/conformance-release-2/
  manifest.json
  signature.json
  artifacts/sequenced-abstract.jsonl
  artifacts/reference-abstract.jsonl.gz

<root>/publisher-abstract/dataset-abstract.ledger/     (beside, NOT inside the release)
  conformance-conformance-release-2-<pid>.stage.0000.json
  ...
  conformance-conformance-release-2-<pid>.stage.0007.json
  conformance-release-2.receipt.json
  conformance-release-2.available
```

The release root contains only `manifest.json`, `signature.json` and the
`artifacts/` directory. Ledger stage files, the Fieldbook publication receipt
and the `.available` marker are written beside the release directory, not
inside it. No post-publication modification of release contents occurred.

## Stage results at the current evidence baseline

| Check | Result |
|---|---|
| Producer build | success (unified production builder via `ndc_release::build_release`) |
| Structural stage 1 | PASS |
| Manifest digest stage 2 | PASS |
| Signature stage 3 | PASS |
| Publisher identity stage 4 | PASS |
| Artifacts and ordering stage 5 | PASS |
| Ordering validation | PASS |
| Rights admission stage 6 | **REFUSED** — `REJECT_RIGHTS_EVIDENCE` |
| Outcome | `RIGHTS_ADMISSION_REFUSED` |
| `rights_state` | `UNKNOWN` |
| Stages 7-12 | `NOT_RUN` |
| `dataset_accepted` | `false` |
| `private_snapshot_survives` | `false` |
| Post-publication modification | none |

The verifier refusal detail is `REJECT_RIGHTS_EVIDENCE: stage 6 rights decision
is not PERMIT`. Wire compatibility and production-builder parity are proven at
the recorded commits; rights are not granted by a passing signature or a
passing artifact check.

## The two receipts — explicit distinction

Earlier records use the short phrase "no receipt" when reporting the Nirnay
verifier diagnostic. That phrasing is ambiguous and is superseded by this
record as follows:

1. **Fieldbook publication receipt — written.** The Fieldbook production
   builder writes `conformance-release-2.receipt.json` into the ledger directory
   beside the release as part of its publication state machine (stage records,
   receipt commit and `.available` marker). This is a producer-side publication
   fact.
2. **Nirnay admission receipt — not written.** The Nirnay verifier diagnostic
   field `receipt_written: false` means **no Nirnay admission receipt was
   written**. It does **not** mean that Fieldbook wrote no publication receipt,
   and it does not convert the producer-side receipt into a consumer-side
   admission or dataset acceptance.

The two receipts are separate artefacts owned by separate repositories, with
no shared runtime or connector. `PUBLICATION_DURABILITY_VERIFIED` is not
achieved merely because a producer-side receipt file exists: independent
receipt exchange and filesystem durability evidence remain a separate gate.

## Capability states (unchanged)

| State | Result |
|---|---|
| `SCHEMA_CONFORMANT` | achieved for the abstract release at the recorded canonical commits |
| `CROSS_EXECUTED` | achieved — real producer output reached the real verifier |
| `BINARY_CROSS_EXECUTED` | achieved for the production path at these commits |
| `CRYPTOGRAPHICALLY_VERIFIED` | achieved for the production path |
| `PUBLICATION_DURABILITY_VERIFIED` | not achieved — separate gate |
| `RIGHTS_ADMITTED` | not achieved — rights `UNKNOWN` |
| `DATASET_ACCEPTED` | not achieved — `dataset_accepted: false` |
| `OPERATIONALLY_QUALIFIED` | not achieved — no provider, rights decision, accepted dataset, India implementation or live route |

## Non-claims and freeze

No real market observation, provider contact, right, collection, experiment,
live execution, India implementation or production signing key is involved.
No dataset was accepted and no Nirnay admission receipt was issued. This is a
documentation-only reconciliation: no source file, schema, right, data,
provider, India implementation or experiment was changed, no gate was weakened,
no full test suite or CI run was re-run, and no commit was created. Freeze
unchanged: rights `UNKNOWN`, dataset acceptance `BLOCKED`, incremental data
budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution
`DISABLED`, D11 strict.
