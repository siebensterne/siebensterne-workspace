# Publication Integrity Sprint — acceptance record (2026-11-24)

Status: **EXECUTED** at the exact heads below. This is a release-correctness
milestone. It does not establish production readiness, power-loss durability or
operational qualification.

## Baseline and final heads

| Repository | Sprint baseline | Final head |
|---|---|---|
| Fieldbook | `475dc34c8cc510ac8dfba158dfdedbd91950f219` | `fd4b542c2df9b775c138a50d068734adedad985e` |
| Nirnay | `70716ebf66289a86335641847724fd92bf6bcce7` | `d3b66f52d500757701f37a21834fde39b89731f4` |
| Workspace | `62b617c380ea97cd2a68f67c880a1f652ef14961` | `6d45af29793485e5b3fce03840228f5d97a34cd9` |

Baseline remote was reconciled by pushing two local Workspace commits before
the first package: `3a3369e` and `62b617c`.

## Packages

| PR | Package | Outcome |
|---|---|---|
| WS #22 | PR0 evidence baseline reconciliation | Five distinct head concepts with per-head evidence; historical evidence preserved; two receipts distinguished |
| FB #69 | PUB-019 bottom-up directory durability | Journal schema v2 (`OperationIntentDurable`, `StagingEntryDurable`, `StagingTreeDurable`, `RenameDurable`); root/artifact/staging dir syncs; v1 immutable |
| NZ #144 | NZ-SNAP-001 provable cleanup | Typed `CleanupReport`, `CLEANUP_PENDING`, descriptor-relative no-follow removal, directory sync and re-enumeration |
| WS #23 | DUR-001 failure model | D0–D4 profile-scoped tiers, acknowledgement contract, invariants I-01..I-15 |
| FB #70 | PUB-020 restart-independent recovery | Operation-id recovery API, immutable `PublicationIntentV2`, journal intent binding, quarantine, fresh-process harness |
| FB #71 | PUB-021 artifact tree validation | Descriptor-relative no-follow validation, regular-file and hard-link policy, manifest/sidecar/artifact digest binding |
| FB #72 | FB-API-001 byte-derived ordering | `CanonicalRecord` bytes-only; keys derived from canonical record bytes at the public API |

All packages were independently reviewed and approved at exact heads. Each was
CI-green at its PR head. Main CI after merge: Fieldbook `45454563981` 2/2
(after stale-branch rerun), Nirnay `45434824649` 12/12 (after macOS job rerun).

## Final cross-execution

Commands:

```
fieldbook/target/debug/ndc-conformance-producer \
  --spec docs/specifications/ndc-conformance-producer-spec-example-2026-11-24.json \
  --out <root>/publisher-abstract/dataset-abstract

nirnay/target/debug/ndc-conformance-verifier \
  --release <root>/publisher-abstract/dataset-abstract/conformance-release-2 \
  --out <diagnostic.json>
```

Result at Fieldbook `fd4b542c` / Nirnay `d3b66f52`: structural, manifest,
signature, publisher, artifact and ordering stages PASS; stage 6
`REJECT_RIGHTS_EVIDENCE`; outcome `RIGHTS_ADMISSION_REFUSED`; no Nirnay
admission receipt; no surviving private snapshot; dataset BLOCKED.

The Nirnay diagnostic's `receipt_written: false` refers only to the absence of
a **Nirnay admission receipt**. Fieldbook writes its own **publication receipt**
and availability marker when its local publication transaction succeeds. These
are separate objects with separate lifecycles.

## Capability states

Achieved: `CONTRACT_RATIFIED`, `SCHEMA_CONFORMANT`, `BINARY_CROSS_EXECUTED`,
`CRYPTOGRAPHICALLY_VERIFIED`, `RELEASE_CORRECTNESS` (P0 corrections merged),
`D0_PROCESS_RECOVERY_VERIFIED` (exactly three fresh-process cases; see scope below).

Not achieved: `PUBLICATION_DURABILITY_VERIFIED` (D1 unqualified),
`OPERATIONALLY_QUALIFIED` (B15/B16 streaming and PERF-001 measurements absent),
`RIGHTS_ADMITTED`, `DATASET_ACCEPTED`, `COUNTRY_PACK_RATIFIED`.

### D0 subprocess evidence scope (WS-EVIDENCE-026)

The D0 fresh-process harness covers exactly three subprocess cases: `publish_before` (process
restart after the rename syscall but before the rename journal commit), `publish_staging` (process
restart after the durable staging-tree journal commit), and `publish_rename` (process restart after
the durable rename journal commit). These three cases are the D0 subprocess evidence. All other
journal/filesystem boundaries — journal directory sync failure, staging mkdir, root sync,
artifacts mkdir, each file write/sync, both directory syncs, rename root sync, receipt and marker
write/sync/ledger sync, recovery from staging and final directory, v1-record readability and
mixed-version refusal — were exercised by in-process fault injection only.
`D0_PROCESS_RECOVERY_VERIFIED` is ACHIEVED for this stated three-case scope only;
`PUBLICATION_DURABILITY_VERIFIED` remains NOT ACHIEVED (D1 unqualified). See
`engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` §2.1 and
`engineering/conformance/ws-evidence-026-provenance-2026-11-24.md`.

## Remaining gates

DUR-002 subprocess harness extension, DUR-003 filesystem qualification,
B15 bounded producer, B16 bounded verifier, PERF-001 resource evidence,
NDC-RECEIPT-001 consumer receipt port, India CountryPack ratification and
implementation. No provider integration, collection, experiment or execution
is authorized.

## Freeze

Rights UNKNOWN (21), dataset BLOCKED, budget INR 0, collection DISABLED,
experiments BLOCKED, M4 holdout untouched, synthetic market-shaped tests
retired under D11, live execution DISABLED. No India implementation or real
data was introduced.
