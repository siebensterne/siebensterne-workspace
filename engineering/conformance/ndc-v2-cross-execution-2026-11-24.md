# WS-NDC-INT-002 — actual producer-to-verifier cross-execution

Status: **EXECUTED** at the exact commits below. This record reports wire and
cryptographic interoperability only. It does not grant rights, accept a dataset
or authorize use.

> **Reconciliation notice (2026-11-24, PR 0):** the conformance-path section below
> (Fieldbook `071da27ed6512fb38c29ada679d76dd0e30ddb6b`) and the FB-NDC-013
> production-builder parity section (Fieldbook PR head `001e2688…`, merged main
> `5703185d59b1ccfeaa310926f26e006abf8ac72c`) are explicitly **HISTORICAL** and
> are preserved unchanged. The current final cross-execution evidence at Fieldbook
> `475dc34c8cc510ac8dfba158dfdedbd91950f219` / Nirnay
> `70716ebf66289a86335641847724fd92bf6bcce7` / Workspace
> `62b617c380ea97cd2a68f67c880a1f652ef14961` is consolidated in
> `engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md`,
> which supersedes stale head wording and clarifies the two distinct receipts.
> Nothing in this record is rewritten by that notice.

## Exact commits

| Component | Commit |
|---|---|
| Fieldbook producer and wire mapping | `c0acffc323172f23f65dd2bf1b727478fde2b0a1` (PR #63) |
| Fieldbook abstract spec alignment | `5b66336d23c1c7663547b4f7afd9646279f345bb` (PR #64) |
| Fieldbook atomic publication correction | `071da27ed6512fb38c29ada679d76dd0e30ddb6b` (PR #65) |
| Nirnay verifier and wire mapping | `70716ebf66289a86335641847724fd92bf6bcce7` (PR #143) |
| Workspace canonical schema package | `f54759b853704be9f26777c15540a24502ff601f` |
| Canonical schema digest | `6e8c1e48e27289b8c3d3e959a06a805e736d0759b4fb244edbb074f65e107bab` |

No runtime model, serializer, validator or crate is shared between the two
repositories. The only connection is the filesystem release directory.

## Commands

```
fieldbook/target/debug/ndc-conformance-producer \
  --spec fieldbook/docs/specifications/ndc-conformance-producer-spec-example-2026-11-24.json \
  --out <root>/publisher-abstract/dataset-abstract/conformance-release-2

nirnay/target/debug/ndc-conformance-verifier \
  --release <root>/publisher-abstract/dataset-abstract/conformance-release-2 \
  --out <diagnostic.json>
```

Producer output: `manifest.json`, five-field `signature.json` and two artifacts
(`artifacts/sequenced-abstract.jsonl` and
`artifacts/reference-abstract.jsonl.gz`) with multiple abstract records. The
signing key is the fixed conformance seed `[0x11; 32]`, present in neither the
release package nor any production configuration.

## Result

| Check | Result |
|---|---|
| Producer exit | success |
| Manifest parses under canonical schema | PASS |
| Structural validation (stage 1) | PASS |
| Manifest digest (stage 2) | PASS |
| Signature (stage 3) | PASS |
| Publisher key validity (stage 4) | PASS |
| Artifact set and digests (stage 5) | PASS |
| Ordering validation | PASS |
| Ordering key derived from record bytes | PASS |
| Correction lineage | PASS |
| Rights admission (stage 6) | **REFUSED** — `REJECT_RIGHTS_EVIDENCE` |
| Admission receipt | not written |
| Private consumer snapshot | does not survive |
| Dataset acceptance | BLOCKED |

Verifier diagnostic outcome: `RIGHTS_ADMISSION_REFUSED`; refusal stage 6;
`rights_state: UNKNOWN`; `dataset_accepted: false`; `receipt_written: false`;
`private_snapshot_survives: false`.

This is the expected freeze result. Wire compatibility is proven; rights are
not granted by a passing signature or a passing artifact check.

## Mutation check

One byte of `manifest.json` was flipped after production and the same verifier
binary was run against the copy. Result: exit nonzero, outcome
`RIGHTS_ADMISSION_REFUSED`, refusal stage 2 `REJECT_SIGNATURE_INTEGRITY`
(`REJECT_SIGNATURE_INTEGRITY: stage 2 manifest digest mismatch`), no receipt and
no surviving snapshot. The verifier therefore detects post-publication mutation
before admission.

## Programme statuses

| Status | Result |
|---|---|
| `SCHEMA_CONFORMANT` | achieved for the abstract release at these commits |
| `CROSS_EXECUTED` | achieved — real producer output reached the real verifier |
| `CRYPTOGRAPHICALLY_VERIFIED` | achieved — manifest and artifacts verified |
| `RIGHTS_ADMITTED` | not achieved — rights UNKNOWN |
| `DATASET_ACCEPTED` | not achieved — BLOCKED |

## Non-claims

No real market observation, provider contact, right, collection, experiment,
live execution, India implementation or production signing key was involved.
No dataset was accepted. A future rights decision is required before any
admission receipt can be issued.

## Re-execution after the publication correction (B12)

After PR #65 replaced `create_dir`+`hard_link` with a genuine atomic no-replace
rename, the producer binary was rebuilt and the cross-execution was repeated at
Fieldbook `071da27` and Nirnay `70716eb`. Result unchanged: structural, manifest,
signature, publisher key, artifact and ordering stages PASS; stage 6
`REJECT_RIGHTS_EVIDENCE`; no receipt; no surviving snapshot; dataset BLOCKED.
In-process fault and recovery tests for every publication transition pass, but
`PUBLICATION_DURABILITY_VERIFIED` is not claimed: independent receipt exchange
and filesystem durability evidence remain a separate gate.

## Production builder parity cross-execution (FB-NDC-013)

This section records a second binary cross-execution at the unified production
builder. It is separate from, and does not replace, the conformance-path record
above. Fieldbook PR #66 unified the production builder with the canonical wire
mapping: the production builder writes `artifacts/` under the declared paths,
and the conformance producer calls `ndc_release::build_release`. No
post-publication modification of release contents was made.

### Exact commits

| Component | Commit |
|---|---|
| Fieldbook PR #66 head (production builder parity) | `001e2688ed4863919e2eb8d35c47ee05615e755a` |
| Fieldbook merged main (PR #66) | `5703185d59b1ccfeaa310926f26e006abf8ac72c` |
| Nirnay verifier and wire mapping (unchanged) | `70716ebf66289a86335641847724fd92bf6bcce7` |

### Commands

The conformance producer binary was rebuilt from the production-builder head, then:

```
target/debug/ndc-conformance-producer \
  --spec docs/specifications/ndc-conformance-producer-spec-example-2026-11-24.json \
  --out <root>/publisher-abstract/dataset-abstract

nirnay/target/debug/ndc-conformance-verifier \
  --release <root>/publisher-abstract/dataset-abstract/conformance-release-2 \
  --out <diagnostic.json>
```

The `--out` argument is the dataset root. The builder writes the final immutable
release into `conformance-release-2` beneath that root and its ledger beside it.

### Exact release layout

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
`artifacts/` directory. Ledger stage files, the publication receipt and the
`.available` marker are written beside the release directory, not inside it.

### Result

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
| `receipt_written` | `false` |
| `private_snapshot_survives` | `false` |
| `dataset_accepted` | `false` |
| Post-publication modification | none |

Verifier refusal detail: `REJECT_RIGHTS_EVIDENCE: stage 6 rights decision is not
PERMIT`; `rights_state: UNKNOWN`; stages 7-12 `NOT_RUN`. Production builder parity
and wire compatibility are proven; rights are not granted by a passing signature
or a passing artifact check.

### Capability states

| State | Result |
|---|---|
| `BINARY_CROSS_EXECUTED` | achieved for the production path at these commits |
| `CRYPTOGRAPHICALLY_VERIFIED` | achieved for the production path |
| `PUBLICATION_DURABILITY_VERIFIED` | not achieved — independent receipt exchange and filesystem durability remain a separate gate |
| `RIGHTS_ADMITTED` | not achieved — rights `UNKNOWN` |
| `DATASET_ACCEPTED` | not achieved — `dataset_accepted: false` |
| `OPERATIONALLY_QUALIFIED` | not achieved — no provider, rights decision, accepted dataset, India implementation or live route |

## Reconciliation 2026-11-24 — current evidence baseline (PR 0)

This section is the canonical pointer for the current baseline. It does not
re-run any binary, alter any source repository or claim any new capability.

### Exact commits at this reconciliation

| Repository | Commit | State |
|---|---|---|
| Fieldbook | `475dc34c8cc510ac8dfba158dfdedbd91950f219` | current, CI-verified, local-tested, cross-executed, reviewed; clean `main` |
| Nirnay | `70716ebf66289a86335641847724fd92bf6bcce7` | current, CI-verified, local-tested, cross-executed, reviewed; clean `main` |
| Workspace | `62b617c380ea97cd2a68f67c880a1f652ef14961` | current, local-tested (workspace `make audit`), reviewed; clean `main`; **no CI run recorded** |

Fieldbook CI run `45406722498` (2/2 success) and Nirnay CI run `45357742748`
(12/12 success) are recorded in `engineering/evidence/REVIEW-LOG.md`. No hosted CI run is recorded
for the workspace orchestration repository; its verification method is the
workspace `make audit` gate, not CI.

### Historical entries preserved

- Conformance-path cross-execution at Fieldbook `071da27` (PR #65) and Nirnay
  `70716eb`, including its re-execution after the B12 atomic-publication
  correction — **HISTORICAL**, sections above unchanged.
- FB-NDC-013 production-builder parity at Fieldbook PR head `001e2688…`, merged
  main `5703185`, Nirnay `70716eb` — **HISTORICAL**, section above unchanged.
- Older conformance-path heads `c0acffc`, `5b66336` and the reviewed/tested
  heads tied to RRP-001 and earlier programmes remain in the dated records that
  first reported them; they are not promoted to current status here.

### Current final cross-execution outcome

The final production-builder cross-execution at Fieldbook `475dc34f` / Nirnay
`70716eb` is recorded in `engineering/evidence/REVIEW-LOG.md` (2026-11-24 final release-correctness
baseline entry): structural, manifest, signature, publisher, artifact and
ordering stages PASS; stage 6 returns `REJECT_RIGHTS_EVIDENCE` under
`rights_state: UNKNOWN`; outcome `RIGHTS_ADMISSION_REFUSED`; stages 7-12
`NOT_RUN`; `dataset_accepted: false`; `private_snapshot_survives: false`.
Exact commands, release layout, stage results and the two-receipt distinction
are in `engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md`.

**Two receipts are distinct.** The Fieldbook production builder writes its
publication receipt (`conformance-release-2.receipt.json`) into the ledger
beside the release as part of the publication state machine. The Nirnay
verifier diagnostic field `receipt_written: false` means that **no Nirnay
admission receipt was written**; it does **not** mean that Fieldbook wrote no
publication receipt. Earlier wording such as "no receipt" in the historical
sections above is superseded by this clarification; the historical text is
preserved, not rewritten.

### Evidence digest

The evidence digest recorded for `cross_execution_source_head` in
`CURRENT-STATE.json` is the SHA-256 of this canonical record, computed with:

```
shasum -a 256 engineering/conformance/ndc-v2-cross-execution-2026-11-24.md
```

No separate SHA-256 is published inside the historical production-builder
section, so this canonical file digest is used as required.
