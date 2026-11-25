# WP-B6A — evidence-led engineering audit of NDC v2 reviewer findings

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **DOCUMENTATION AUDIT, READ-ONLY SOURCE INSPECTION.** This record maps the reviewer's
twelve findings to the actual current source at the exact heads below. It ratifies no schema,
changes no source, schema, right, data, provider or India artefact, creates no release, key or
receipt, and grants no right. No milestone state is promoted by wording in this document.

## Authority and inspected heads

| Component | Head inspected | State |
|---|---|---|
| Fieldbook producer and wire mapping | `dd90899b896263314bfb2a588a0e41b094b8619f` | local clone `main`, clean; all inspected commits are ancestors |
| Nirnay verifier and wire mapping | `70716ebf66289a86335641847724fd92bf6bcce7` | local clone `main`, clean |
| Workspace orchestration (this worktree) | `5999ec5c257c62ea26ee65fc83e17ea713b76f64` | branch `docs/ndc-evidence-audit`, base `5999ec5` |

The reviewer's archive heads — Fieldbook `2ef88a9`, Nirnay `2dad496`, Workspace `14afdfd` — are
historical review inputs. Findings are re-tested against the current heads only; claims from
different commits are never combined. The recorded cross-execution at
`engineering/conformance/ndc-v2-cross-execution-2026-11-24.md:9-18` used producer commits
`c0acffc` and `5b66336` (both ancestors of Fieldbook `dd90899`), verifier `70716eb` (the current
Nirnay head) and schema package `f54759b` (an ancestor of Workspace `5999ec5`). Schema package
digest: `6e8c1e48e27289b8c3d3e959a06a805e736d0759b4fb244edbb074f65e107bab`.

Method: read-only inspection of `fieldbook/src/distribution/{ndc_wire.rs,ndc_release.rs}`,
`nirnay/crates/release-verifier/src/{schema.rs,verifier.rs,canonical_wire.rs,files.rs,receipt.rs}`,
the B8 canonical schema package under `engineering/conformance/ndc-v2-schema-profile-1/`,
the ratified decisions and the recorded cross-execution diagnostic. Line references are to those
exact files at those exact heads.

## Findings table

| Finding | Reviewer claim | Actual evidence at current heads | Status | Next action |
|---|---|---|---|---|
| 1. Release directory layout | Producer writes artifacts at the release root while the verifier expects `artifacts/`. | Producer `fieldbook/src/distribution/ndc_wire.rs:943-960` `validate_artifact_path` requires the `artifacts/` prefix and rejects any other path; it is called by `map_artifact` at `:2263` and `prepare_artifact` at `:2582`. The conformance spec declares `artifacts/sequenced-abstract.jsonl` and `artifacts/reference-abstract.jsonl.gz` (`fieldbook/docs/specifications/ndc-conformance-producer-spec-example-2026-11-24.json:486,518`), and the recorded produced release lists exactly those two paths under `artifacts/` (`ndc-v2-cross-execution-2026-11-24.md:32-34`). Verifier `nirnay/crates/release-verifier/src/files.rs:139-159` requires the same prefix; `verifier.rs:404-428` opens the `artifacts` directory and compares its exact file set with `artifacts[]`. | **RESOLVED** | No fix. Keep both mappings byte-aligned; any future path-alphabet change requires a paired representation change. |
| 2. Publication atomicity | `finalize_publication` used `create_dir` plus `hard_link` with a mislabelled `AtomicNoReplaceRename` stage in the Batch B baseline. | **RESOLVED at Fieldbook `071da27` (PR #65).** `ndc_release.rs` now calls a platform-specific `atomic_no_replace_rename` (Linux `renameat2(RENAME_NOREPLACE)`, macOS `renamex_np(RENAME_EXCL)`, other targets fail closed) once, before the `AtomicNoReplaceRename` stage label; parent-directory sync, receipt commit and `AVAILABLE` follow in order. Stage-order, fault-injection and recovery tests pass (50 module tests, 822 all-targets); CI 45363967573. | **RESOLVED** | Independent receipt exchange and filesystem durability evidence remain a separate gate; `PUBLICATION_DURABILITY_VERIFIED` is not claimed. |
| 3. Record ordering key trust | Producer trusts an independent caller-supplied ordering key. | Producer `derive_order_key` (`ndc_wire.rs:1297-1333`) takes the key from `record.derived_key` produced by parsing canonical bytes (`:1353-1355`), validates domain/epoch and profile, and never reads the caller's `order_key` member (doc `:1335-1340`; claimed key marked untrusted at `:2600`). Duplicate keys with differing payloads fail closed (`:1359-1363`) and sorting is byte-deterministic (`:1366`). Verifier `derive_key_from_bytes` (`canonical_wire.rs:2031-2069`) re-parses the received bytes, requires `canonical_bytes(&value) == bytes` at `:2048`, and derives the key from the raw `ordering` member (`:2054-2069`). Cross-execution: "Ordering key derived from record bytes — PASS" (`ndc-v2-cross-execution-2026-11-24.md:50`). | **RESOLVED** | No fix. Retain byte-derived keys and the canonical-byte equality check on both sides. |
| 4. Operation evidence matching | Verifier matches action strings to `operation_ref`. | Verifier stage 8 (`verifier.rs:715-742`) builds a `HashSet` of `performed_operations[].operation_ref` and rejects evidence whose `operation_ref` is absent (`:722-738`), also checking event/run/decision-key presence, recording instant against `as_of`, and digest hex. Both sides carry typed records: `schema.rs:87-115` (`PerformedOperation` and `OperationEvidence` each with `operation_ref`); `canonical_wire.rs:1468-1497` rejects duplicate, unbound and missing evidence references with one-to-one cardinality. Schema: `manifest.schema.json` `$defs/PerformedOperation` and `$defs/OperationEvidence`. The cross-execution refused at stage 6, so stage 8 was **not** exercised there; conformance rests on source and the Nirnay PR #143 test evidence, not on a cross-execution PASS. | **RESOLVED** | No fix. A later acceptance run after rights admission should exercise stage 8 end to end. |
| 5. Coverage cardinality/duplicates | `HashSet` collapses duplicate coverage dimensions. | `canonical_wire.rs:1536-1568` requires `dimensions.len() >= 9` (`:1536-1540`), then inserts each `dimension_id` into a `HashSet` and fails on duplicate (`:1541-1545`); non-zero denominator (`:1546-1551`), overflow-safe `numerator + missing_count + rejected_count == denominator` (`:1552-1562`), and per-dimension `as_of` equality with release `as_of` (`:1563-1567`). Closed vocabulary: `CoverageDimensionId` with exactly nine values at `:687-698`; schema enum at `coverage.schema.json:84-97` and required members at `:70-81`. No `HashSet` is used as the cardinality proof. Coverage stage 7 did not run in the recorded cross-execution because of the first refusal at stage 6. | **RESOLVED** | No fix. Preserve the len/duplicate/arithmetic checks; cover stage 7 in a post-rights acceptance run. |
| 6. Rights grant-document binding | Grant document references were opaque or unbound. | `canonical_wire.rs:1512-1520` resolves every `grant.supporting_document_references` entry against `manifest.rights.document_references`, requiring both equal `reference` and equal `document_sha256`/`digest_sha256`; an unresolved pair fails with `grant document reference is unresolved`. Schema `rights-evidence.schema.json:224-238` defines `DigestReference` with required `reference` and `digest_sha256`; `:376-380` binds `supporting_document_references`, and `:402-413` declares `document_references`. This is structural binding only: the cross-execution still refuses rights at stage 6 with `REJECT_RIGHTS_EVIDENCE` and `rights_state: UNKNOWN` (`ndc-v2-cross-execution-2026-11-24.md:52-59`). | **RESOLVED (binding only)** | No code fix. Keep rights `UNKNOWN`; a right is not created by a resolved digest. Rights admission remains a separate owner gate. |
| 7. PROV lineage completeness | Missing `generatedAtTime`, qualified attribution, `wasDerivedFrom`/`wasRevisionOf`/`hadPrimarySource`, invalidated time, predecessor revision semantics. | All listed items are **present** at current heads. Ratification `WS-NDC-2026-11-24-003:214-238` (DP-14..DP-17) names the full typed relation set, canonical nine-digit UTC `invalidated_at_time`, and current versus immediate-predecessor revision. Schema `lineage.schema.json:171-233` requires `was_derived_from`, `was_revision_of`, `had_primary_source`, `generated_at_time`, `invalidated_at_time`, `qualified_attribution`, `supersedes` plus knowledge time and current revision; `supersedes` is the seven-member immediate-predecessor relation (`:138-169`). Producer `ndc_wire.rs:584-592` (`ProvSpec`), `:310`, `:2077-2092` and `:2171-2192` validate and map them; verifier `canonical_wire.rs:1011-1103` parses typed PROV structs and `:1570-1600` checks invalidation/knowledge ordering, predecessor revision strictly below current, self-reference and predecessor time ordering. Cross-execution records "Correction lineage — PASS" (`ndc-v2-cross-execution-2026-11-24.md:51`). **Separate owner/ratification item:** none remains for these fields — DP-14..DP-17 are already ratified; a future change to the UTC grammar, PROV set or multi-predecessor policy would require a new owner decision, not an implementation edit. | **RESOLVED** | No fix. Any future PROV grammar change is a dated owner decision with a new schema version. |
| 8. Contract version duplication and payload schema version | Nested/root `contract_version` duplication and a manifest-wide scalar `payload_schema_version`. | `manifest.schema.json:1148-1215` has one root `contract_version` (`:1171-1174`, `const: "v2"`, description rejects a nested or duplicate member); `$defs/SchemaVersions` at `:943-966` requires `normalizer_version`, `envelope_version` and `payload_schemas`, and states `contract_version` is deliberately absent (`:966`). Per-event-type registry: `payload-schema-registry.schema.json:5,23-43` (event type, schema identity, version, registered digest); decision §12.1-2 (`WS-NDC-2026-11-24-003:260-270`, DP-23/DP-24). Code: `ndc_wire.rs:66-67` single literal and `:2212-2244` `payload_schemas` map; `canonical_wire.rs:1602-1613` rejects duplicate event types and schema identities. Vector `duplicate-contract-version.json` is indexed in the B8 package. | **RESOLVED** | No fix. Keep the root-only version and per-event registry. |
| 9. Compression profile | Exact codec profile not ratified; no codec should be mandatory. | Registered strings exist in both schema and code: `ndc_wire.rs:72-76` (`none/1`, `gzip-deflate/flate2-1`) with pair validation at `:2248-2259` and mapping at `:2590-2595`; `manifest.schema.json:1047-1061` enumerates both strings and states the identifier binds codec family, version and decoding semantics with no magic-byte or extension inference, and only registered identifiers are admitted. Ratification DP-19 (`WS-NDC-2026-11-24-003:240-254`) registers the string form. The reviewer's request to ratify the exact codec profile and retain none as mandatory is not discharged by registration alone: the schema permits both and mandates neither. | **OWNER-DECISION** | Owner decision: ratify the exact codec/profile set and confirm no mandatory codec for Profile 1; any new or removed identifier requires a versioned schema entry and paired mapping change. No unilateral mandate. |
| 10. Processing memory/streaming | Artifacts are processed wholly in memory rather than streamed. | Producer `ndc_wire.rs:2596-2632` accumulates `records`, `uncompressed` and `stored` `Vec`s; ordering builds a full `Vec` of entries at `:1346-1367`; bounds are policy maxima, not streaming. Verifier `verifier.rs:430-453` reads the bounded artifact into a `stored` vector and decompresses into `expanded`, accumulates all records, and `verifier.rs:1071-1093` holds every copied byte in the private snapshot. Confirmed in both repositories at current heads. | **REMAINING** | B15/B16, two separate **P1** work packages (one per repository): introduce bounded streaming/incremental digest paths with tests and measured bounds. Do not describe the current bounded-in-memory implementation as streaming or as done. |
| 11. Publication receipt consumer integration | Verifier does not consume the producer's publication receipt. | Confirmed. Verifier stage 1 accepts only `manifest.json`, `signature.json` and `artifacts` at the release root (`verifier.rs:193-204`); an extra receipt file there is refused. No verifier code reads a producer receipt: `receipt.rs:2` is the consumer's own admission receipt constructed after all twelve stages. The producer writes its receipt to the journal ledger outside the release (`ndc_release.rs:2349-2351`) with an `.available` marker at `:2355-2357`. Cross-execution: admission receipt not written, `receipt_written: false` (`ndc-v2-cross-execution-2026-11-24.md:53-59`). Ratified separation: DP-29 (`WS-NDC-2026-11-24-003:345`) and `semantic-constraints.md:239-240`. | **SEPARATE GATE** | Owner recommendation: a **read-only port** of the producer publication receipt into the consumer, carried by a **separate signed receipt/registry**, with **no unapproved durability claim in the manifest**. No port, registry entry or claim is created by this audit; `PUBLICATION_DURABILITY_VERIFIED` stays unachieved. |
| 12. Seven original wire mismatches | Seven typed/wire representation differences blocked producer-to-verifier compatibility (engineering/evidence/REVIEW-LOG.md:129): decimal-string vs `u64` instants; structured vs string operations; `Option` vs required segment; coverage dimension fields; lineage fields; object vs string `record_order_profile`; string vs `u32` `compression_version`. | Each mismatch maps to the ratified canonical package and current mappings: (1) `manifest.schema.json:30-32` `$defs/DecimalStringU64`, producer `parse_decimal` and verifier `raw_decimal`; (2) typed `PerformedOperation`/`OperationEvidence` (`schema.rs:87-115`; `verifier.rs:715-742`); (3) required non-empty identifiers with no null in `manifest.schema.json:1145-1146` and DP-04 (`WS-NDC-2026-11-24-003:320`); (4) `coverage.schema.json:70-97` plus `canonical_wire.rs:1536-1568`; (5) `lineage.schema.json:171-233` plus `canonical_wire.rs:1011-1103`; (6) tagged object with closed `kind` set (`ordering-profiles.schema.json:57-65`; `manifest.schema.json:1040-1042`; producer `ndc_wire.rs:2272-2280`); (7) registered string enum (`manifest.schema.json:1054-1061`; producer `ndc_wire.rs:2248-2259`; verifier `canonical_wire.rs:1443-1453`). Recorded cross-execution: manifest parses under the canonical schema and stages 1-5 PASS, with ordering, byte-derived key and correction lineage PASS (`ndc-v2-cross-execution-2026-11-24.md:43-51`). | **RESOLVED** (all seven) | No fix. Preserve the canonical representation on both sides; do not reintroduce the historical typed/wire divergence. |

## Finding status counts

The original read-only audit baseline is Fieldbook `dd90899`; finding 2 was
re-evaluated at Fieldbook `071da27` after the B12 publication correction. Counts
below reflect the current state.

| Status | Count | Findings |
|---|---|---|
| RESOLVED | 9 | 1, 2, 3, 4, 5, 6, 7, 8, 12 |
| REMAINING | 1 | 10 |
| OWNER-DECISION | 1 | 9 |
| SEPARATE GATE | 1 | 11 |
| **Total** | **12** | all reviewer findings mapped |

Finding 6 is counted RESOLVED for structural digest/reference binding only; it does not imply
`RIGHTS_ADMITTED`. Finding 12 is counted RESOLVED for wire representation parity at the recorded
abstract cross-execution, not for a real dataset.

## Milestone states

Evaluated with the reviewer's nine-state vocabulary. Achieved entries cite the exact evidence;
unachieved entries are not promoted by the wording above.

| State | Result | Evidence or reason |
|---|---|---|
| `CONTRACT_RATIFIED` | **ACHIEVED** | Profile 1 Decisions A–I (`fb8a4992…`) and canonical wire decision `WS-NDC-2026-11-24-003` (`417bd4e5…`, RATIFIED 2026-11-24, DP-01..DP-30), registered in `NDC-REGISTRY.md:22-27,51`. |
| `PRODUCER_CONFORMANT` | **ACHIEVED (abstract wire scope)** | Fieldbook `dd90899` maps to the canonical schema (`ndc_wire.rs` evidence in findings 1, 3, 8, 12); the recorded producer output parses under the canonical schema and passes stages 1-5 (`ndc-v2-cross-execution-2026-11-24.md:43-49`). No real-dataset or rights conformance is implied. |
| `VERIFIER_CONFORMANT` | **ACHIEVED (abstract wire scope)** | Nirnay `70716eb` independently parses and validates the canonical wire form (`schema.rs`, `canonical_wire.rs`, `verifier.rs` evidence in findings 3-6, 8, 12); the recorded verifier produced the dated diagnostic and detected the byte mutation (`ndc-v2-cross-execution-2026-11-24.md:38-71`). |
| `BINARY_CROSS_EXECUTED` | **ACHIEVED** | Real `ndc-conformance-producer` output was processed by the real `ndc-conformance-verifier` through a filesystem release; no shared runtime, serializer or validator (`ndc-v2-cross-execution-2026-11-24.md:7-30,38-42`). |
| `CRYPTOGRAPHICALLY_VERIFIED` | **ACHIEVED** | Manifest digest, signature and publisher key validity PASS (stages 2-4); one-byte manifest mutation rejected at stage 2 (`ndc-v2-cross-execution-2026-11-24.md:45-47,64-71`). |
| `PUBLICATION_DURABILITY_VERIFIED` | **NOT ACHIEVED** | Finding 2 implementation is resolved at `071da27` (atomic no-replace rename, stage/fault/recovery tests). Independent receipt exchange and filesystem durability evidence remain a separate gate; the verifier consumes no producer receipt (finding 11). |
| `RIGHTS_ADMITTED` | **NOT ACHIEVED** | Stage 6 `REJECT_RIGHTS_EVIDENCE`, `rights_state: UNKNOWN` (`ndc-v2-cross-execution-2026-11-24.md:52-59`). |
| `DATASET_ACCEPTED` | **NOT ACHIEVED** | `dataset_accepted: false`, dataset BLOCKED; no receipt and no surviving snapshot (`ndc-v2-cross-execution-2026-11-24.md:53-59,80-81`). |
| `OPERATIONALLY_QUALIFIED` | **NOT ACHIEVED** | No provider contact, market observation, rights decision, India implementation, accepted dataset, streaming qualification or live route; freeze unchanged (rights `UNKNOWN`, dataset `BLOCKED`, budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict). |

Five of nine states are achieved at the abstract wire and recorded cross-execution scope; four
are not. This document changes none of those determinations.

## Production-builder parity note

The production-builder path was previously a separate concern: the recorded binary
cross-execution covered the conformance producer helper only. That path is now
covered at Fieldbook `5703185d59b1ccfeaa310926f26e006abf8ac72c` (PR #66 merged main;
PR head `001e2688ed4863919e2eb8d35c47ee05615e755a`) with the unchanged Nirnay verifier
`70716ebf66289a86335641847724fd92bf6bcce7`. The production builder writes `artifacts/`
under the declared paths and the conformance producer calls `ndc_release::build_release`.
The second binary cross-execution, its exact release layout and its result are recorded in
`engineering/conformance/ndc-v2-cross-execution-2026-11-24.md` under "Production builder
parity cross-execution (FB-NDC-013)". `BINARY_CROSS_EXECUTED` and `CRYPTOGRAPHICALLY_VERIFIED`
now also hold for the production path; `PUBLICATION_DURABILITY_VERIFIED`,
`RIGHTS_ADMITTED`, `DATASET_ACCEPTED` and `OPERATIONALLY_QUALIFIED` remain unachieved.
The twelve-finding status counts above are unchanged; this note adds coverage, not a new
finding or a state promotion.

## Sequenced remaining work

1. **B12 — P0, merged.** Publication atomicity corrected at Fieldbook `071da27`
   (PR #65) with a platform-specific atomic no-replace rename, correct stage
   ordering, fault injection and recovery tests. Independent receipt exchange and
   filesystem durability evidence remain a separate gate; no durability state is
   claimed from the in-process tests alone.
2. **B15 / B16 — P1, separate work packages.** Streaming and bounded memory, one package per
   repository: Fieldbook producer path (`ndc_wire.rs:1346-1367,2596-2632`) and Nirnay verifier
   path (`verifier.rs:430-453,1071-1093`). Both stay open; the current bounded in-memory design is
   not represented as streaming.
3. **Publication receipt consumer integration — separate gate.** Owner recommendation: read-only
   port of the producer publication receipt into the consumer, separate signed receipt/registry,
   and no unapproved durability claim in the manifest. DP-29 and the exact-root-file-set check
   constrain this gate. No port or claim without the owner decision.
4. **India catalogue ratification — P1.** `engineering/design/india-national-domain-catalogue.md`
   (IN-CAT-001, 20 cohorts) and `engineering/decisions/IN-COUNTRY-001-india-country-pack-design.md`
   remain **PROPOSED**. Separate owner ratification is required before any implementation,
   connector, population or dataset acceptance; none is created here.

## Audit inputs, gates and non-claims

- Inspected heads were recorded before reading source: Fieldbook `dd90899` and Nirnay `70716eb`,
  both on `main` with a clean working tree and both descendants of the `WORKSPACE.lock.json`
  baseline pins. Cross-execution commits are ancestors of the current heads; no commit is mixed
  with another in any claim above.
- Gates: `make consistency` and `make audit` were run in this worktree with the two local clones
  temporarily symlinked in; the symlinks were removed afterwards. `make audit` covers read-only
  status, consistency and both static gate surfaces only. No Fieldbook fixture/e2e suite, Nirnay
  full suite, CI run or new cross-execution was run by this audit; no gate was weakened.
- No commit was created. No source file, schema, right, data set, provider configuration, India
  artefact, release, signing key, receipt, experiment or live route was created or changed. No
  approval, promotion or durability claim is inferred from the RESOLVED entries.
