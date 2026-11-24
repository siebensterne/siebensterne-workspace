# WS-NDC-INT-002 — actual producer-to-verifier cross-execution

Status: **EXECUTED** at the exact commits below. This record reports wire and
cryptographic interoperability only. It does not grant rights, accept a dataset
or authorize use.

## Exact commits

| Component | Commit |
|---|---|
| Fieldbook producer and wire mapping | `c0acffc323172f23f65dd2bf1b727478fde2b0a1` (PR #63) |
| Fieldbook abstract spec alignment | `5b66336d23c1c7663547b4f7afd9646279f345bb` (PR #64) |
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
