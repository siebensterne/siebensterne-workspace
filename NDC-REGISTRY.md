# NDC registry — version and ownership

The Nirnay Data Contract is a set of semantic requirements, not a frozen schema. It has
one producer and one consumer. No transport, queue, shared crate or database is chosen.

## Active contract

| Field | Value |
|---|---|
| Active contract version | **`v2`** (approved semantic requirements) |
| Producer | Fieldbook |
| Producer document | `engineering/ndc-producer-requirements-v2-proposed.md` in Fieldbook |
| Producer document digest (approved) | `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c` |
| Consumer | Nirnay |
| Consumer document | `engineering/ndc-consumer-requirements-v2-proposed.md` in Nirnay |
| Consumer document digest (approved) | `22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957` |
| C0 semantic model | `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` in Workspace |
| C0 semantic model digest (approved) | `3dace660c362e683790ba7e56a785ded8af836abda36f6eab06ed284de49eed2` |
| Ownership decision | `NR-ARCH-ADR-0001` — **Accepted 2026-11-23** by owner ratification |
| Ratification reference | `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md` — Decision A (ownership) and Decision B (NDC v1/v2 semantics); roles named there |
| Release serialization profile | **NDC v2 Release Serialization Profile 1 — Ratified 2026-11-24** |
| Profile ratification | `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md` — Decisions A–I; digest `fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc` |
| Approved D1 amendment | `engineering/conformance/NDC-D1-AMENDMENT-001.md` — approved 2026-11-24; digest `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894`; D1 approved bytes and digest unchanged |
| Canonical wire schema ratification | `engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` — **RATIFIED 2026-11-24** by owner direction; digest `417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119`; resolves DP-01..DP-30 |
| Canonical wire authority | One third, language-independent canonical NDC v2 Profile 1 wire schema; neither Rust representation is normative; both repositories keep independent internal representations with explicit serialization/deserialization mappings; no shared runtime crate; B8 published the schema package |
| Canonical schema package | `engineering/conformance/ndc-v2-schema-profile-1/` — version 1, published 2026-11-24; **26 files** (8 JSON Schemas, 16 canonical vectors, 2 normative documents); index `VECTORS.md`; checker `scripts/check_ndc_schema_package.py` |
| Schema package digest | `SCHEMA-PACKAGE-DIGEST 6e8c1e48e27289b8c3d3e959a06a805e736d0759b4fb244edbb074f65e107bab` — one reproducible digest over the sorted (path, sha256) list with domain prefix `NDC-V2-PROFILE-1-SCHEMA-PACKAGE-DIGEST-V1` |
| Contract status | NDC v2 **Approved 2026-11-23**; NDC v1 **historical**, superseded by v2 |
| NDC v1 producer document (historical) | `engineering/ndc-producer-requirements-v1.md`, digest `592a1c9043ed2756a3f9d938dbe6e2ee80007166b440cf6f2709d5de11424c33` |
| NDC v1 consumer document (historical) | `engineering/ndc-consumer-requirements-v1.md`, digest `25315c57de753bde33b0f8044e70646f24b19c8af7ca9fdbdd2e53682a53b8bd` |
| Operation sets | producer (8) / consumer (5), distinct; extra grants imply nothing |
| Trust model | detached Ed25519 with `manifest_sha256` only in `signature.json`; out-of-band trusted publisher registry; integrity is not authenticity |
| Rights state | all provider rights `UNKNOWN` |
| Release state | no accepted dataset release |

The approved bytes were not modified to make this table consistent. The v1 documents and
the v2 requirement documents keep their original SHA-256 values; only this registry and the
other workspace governance records changed.

## What approval does and does not cover

Approval of NDC v2 semantics is one decision. It does not imply that every implementation
component exists. These layers are recorded separately:

| Layer | Status | Evidence / note |
|---|---|---|
| Approved semantic requirements | **Approved 2026-11-23** | v2 producer requirements, v2 consumer requirements and the C0 model above; six separable concepts (capability, permission, operation, data object, purpose, evidence) |
| Approved implementation-conformance rules | **Approved as requirements** under W1.2 C1/C2 paired PRs #45/#46/#130; enforcement still to be proven | `CURRENT-STATE.json` `reviewed_commit_ids`; W2.1-B/C exists to close runtime gaps, not to reopen the approved semantics |
| JSON schemas | Present as versioned repository artifacts (for example `schemas/research/dataset-manifest.v1.schema.json`), not part of the approved NDC v2 requirement bytes | A schema that compiles is not a verified release |
| Canonical serialization rules | **Ratified as semantics**: 2026-11-23 Decision B, refined by Profile 1 Decision A — RFC 8785 JCS over the complete manifest, SHA-256 digest only in the detached sidecar, Ed25519 domain-separated signature; proves publisher-key control and manifest integrity only | `OWNER-RATIFICATION-2026-11-23.md` Decision B; `WS-NDC-2026-11-24-002` Decision A; `NDC-D1-AMENDMENT-001.md` |
| Canonical wire schema authority | **Ratified 2026-11-24**: one language-independent canonical wire schema for Profile 1; B8 package published, with binary cross-execution now recorded at the Phase 3 final heads | `WS-NDC-2026-11-24-003` (`417bd4e5…`): strict UTF-8/RFC 8785 JCS, decimal-string nanosecond instants, byte-derived tagged record ordering, typed operations/evidence, source scope, rights, coverage, lineage, registered compression versions, versioned schema package with one digest; DP-01..DP-30 resolved; no shared runtime crate |
| Final NDC serialization schema | **Profile 1 version and digests registered; canonical schema package published by WP-B8 (2026-11-24)** | `engineering/conformance/ndc-v2-schema-digest.json` registers the exact version, profile and D1 amendment digests, strict unknown-field policy and the source of truth. The B8 canonical schema package at `engineering/conformance/ndc-v2-schema-profile-1/` is the standalone published wire artifact (digest `6e8c1e48…`, 26 files). At the WP-5 recorded heads no such file existed and the typed structs in both repositories were the implementation authorities; those heads are historical evidence, not the normative wire representation. Cross-execution was NOT_STARTED at the WP-5 heads; current binary cross-execution is recorded in the Phase 3 acceptance record |
| Resource policy | **Ratified rule**: versioned normative consumer resource policy, no manifest `limits`, producer and verifier enforce independently; numerical maxima pending workload qualification | `WS-NDC-2026-11-24-002` Decision F; `WS-STREAM-001` (2026-11-25) adds the normative immutable versioned `ResourceProfile` contract with role-specific profiles, trusted local selection, consumer local ceiling and stricter-of effective limits, but approves no number or profile digest |
| Publication durability | **Ratified rule**: staged, synced, atomic no-replace rename with parent-directory sync and durable receipt; uncertain-publication recovery after rename before parent sync | `WS-NDC-2026-11-24-002` Decision G |
| Publication durability failure model | **Ratified rule (WS-DUR-001)**: five tiers D0–D4 with profile-scoped booleans, an error-only sync acknowledgement contract, per-platform primitive qualification and no global durability Boolean; not a D1 claim | `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` — **RATIFIED 2026-11-24** by owner direction; current digest `931e7477faa7752248a2392d7b79f34c317ab95a838a88ee491f448eac6dbcfb` (FB-DUR-002 full-matrix evidence extension; prior WS-EVIDENCE-026 digest `d3a18e62bd31d6e9492078edf6d3cfb80ae2e69fa977a497780b54ef00aea8b6` and original ratification digest `2b04f9b40fd395973f0f0ab99bc47a73f1e82a8b375e2ec4c5de211e85095b71` preserved as historical in `REVIEW-LOG.md`) |
| Trusted publisher registry | **Ratified rule**: out-of-band registry with key states and revocation evidence; Batch B trust interface with injected test keys only | `WS-NDC-2026-11-24-002` Decision H |
| Runtime implementation | Producer and independent verifier implemented; bounded streaming implementation complete at the Phase 3 final heads; binary cross-execution recorded at FB `8216197` / NZ `c1c2f0d` with stage-6 rights refusal | WP-5 acceptance matrix records exact test evidence at Fieldbook `2ef88a9` and Nirnay `2dad496` (historical package heads where cross-execution was NOT_STARTED); Phase 3 evidence in `engineering/conformance/phase-3-acceptance-2026-11-25.md`; no shared invocation boundary or connector, no verification promotion |
| Consumer verification capability | Independent `release-verifier` crate implemented at Nirnay `2dad496`; **Proposed consumer-use proposal unchanged** | Twelve-stage verifier with abstract tests; no shared crate; the separate consumer-use document below is not approved and is not an authority for this capability |
| B15/B16 streaming architecture | **RATIFIED 2026-11-25** by owner direction (`WS-STREAM-001`): bounded interfaces and pipelines, two-intent lifecycle, byte-derived ordering, Profile 1 digests, incremental digests, bounded parsing and decompression, typed failure semantics, descriptor-relative snapshots, independent implementations and separate receipts | Contract only; numeric resource maxima and codec identifier deferred; `STREAM_RESOURCE_PROFILE_RATIFIED` pending; both design documents remain PROPOSED |
| Phase 3 evidence acceptance | **ACCEPTED 2026-11-25** at FB `8216197` (PR #75) / NZ `c1c2f0d` (PR #145), CI `45491963354` 2/2 and `45491893837` 12/12; `STREAMING_IMPLEMENTATION_COMPLETE` achieved under finite `TEST_ONLY` profiles | `engineering/conformance/phase-3-acceptance-2026-11-25.md` (digest `3a823688f59bca1fd78ba8f02231b97f8d40d98647430551fbc2e805a0cb2ee4`); stage 6 `REJECT_RIGHTS_EVIDENCE`, `RIGHTS_ADMISSION_REFUSED`, no admission receipt, no surviving snapshot; no capability or durability promotion |

## NDC v2 Release Serialization Profile 1 (ratified 2026-11-24)

Ratification: `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md`
(status RATIFIED by owner 2026-11-24, digest
`fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc`). It approves exactly
these nine decisions; no other profile is registered.

| Decision | Subject | Ratified rule (summary) |
|---|---|---|
| A | Manifest digest / circularity | Complete manifest JCS, `H_M = SHA256(M)`; digest only in detached sidecar; domain-separated Ed25519; D1 amended by `NDC-D1-AMENDMENT-001.md` |
| B | Record ordering | Per-artifact `record_order_profile`; sequence and reference keys; no event-time-first sorting or fallback |
| C | Artifacts | `artifacts[]` sole inventory; fixed descriptor field set; canonical artifact order by `(logical_partition_id, shard_ordinal)`; canonical JSONL |
| D | Dataset digest | SHA-256 over concatenated uncompressed canonical record streams in canonical artifact order; compression-independent |
| E | Corrections | One `lineage.supersedes`, one immediate predecessor, PROV `wasRevisionOf`, traversable chain |
| F | Limits | No manifest `limits`; versioned normative consumer resource policy; no unmeasured numeric maxima |
| G | Publication | Eight-state publication machine with durable receipt and uncertain-publication recovery |
| H | Keys | Out-of-band publisher registry, key-state rules; Batch B interface and injected test keys only |
| I | Independence | Separate producer and verifier implementations; no shared validator/serializer/digest/rights crate; shared schema and vectors only |

The design file `engineering/conformance/ndc-v2-release-format-design.md` remains a historical
design record with a prominent approved-amendment section. Its superseded choices (excluded
digest field, sidecar `domain` field, event-time-first order key, `record_order` and
`limits` manifest fields, `digests.artifact_digests[]`, `lineage.corrections[]`, design numeric
limits and the existence-check-then-rename alternative) are not adopted under Profile 1.

## Canonical NDC v2 Profile 1 wire schema (ratified 2026-11-24)

Ratification: `engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md`
(status RATIFIED by owner direction 2026-11-24, digest
`417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119`). The owner chose a **third,
language-independent canonical wire schema**; neither Fieldbook's nor Nirnay's current Rust
representation is normative. Each repository keeps independent internal representations with
explicit serialization/deserialization mappings, and no shared runtime crate is introduced.
This decision resolves **DP-01..DP-30** of the WP-B6 reconciliation
(`engineering/conformance/ndc-v2-wire-contract-reconciliation.md`), which remains a PROPOSED
review record.

| Area | Ratified rule (summary) |
|---|---|
| Encoding | UTF-8, RFC 8785 JCS, strict parsing, duplicate/unknown/missing/type reject, no defaults or coercions, explicit schema version, exact numeric semantics |
| Instants / numbers | Nanosecond instants as decimal strings `^(0\|[1-9][0-9]*)$` within `u64`; counts and byte sizes as integers below 2^53 or decimal strings for full u64; no float for financial quantities |
| Record ordering | Artifact-level tagged object (`kind` sequenced with domain/epoch, or reference); per-record tagged union (sequence key set or reference key set), never both; producer parses canonical bytes, validates against artifact profile, derives key, sorts and emits the same validated bytes; verifier repeats; no trusted caller-supplied key |
| Operations / evidence | Structured `{operation_ref, action, data_object{kind,id,version}}` using the Fieldbook producer action vocabulary; separate typed operation evidence bound by `operation_ref`; duplicate/missing/reassigned evidence rejects; vocabularies stay separate |
| Source scope | `provider_id`, `source_product_id`, `venue_id`, `segment_id`, `dataset_id` all required non-empty valid identifiers; no empty/`UNKNOWN`/`ALL`/placeholder/`null`; venue-less sources outside Profile 1 pending a future profile |
| Rights | Full typed source-rights evidence (grant identity, granting authority, action, object class, PERMIT/DENY, actor, licensee, recipient, purpose/scope, validity, delivery, retention, document refs + digests, contract revision, review authority/date, attestation); separate from consumer authorization; signature grants no right; consumer-use proposal is not an approved rights contract |
| Coverage | Typed dimension with named universe, denominator identity, count basis, required denominator, counts, as-of, verdict, evidence reference and typed gaps; no PASS without denominator; disjoint/exhaustive arithmetic or documented actual arithmetic; nine dimensions separate; producer PASS does not promote verdict |
| Lineage | One typed structure with raw archive ref+digest, transformation identity+version, knowledge time, revision, full PROV relations and qualified attribution; current vs immediate-predecessor revision; canonical UTC `invalidated_at_time` (nine fractional digits, `Z`); reject cycles, missing predecessors and regression |
| Compression | Registered string identifier; descriptor binds method, profile, codec version and decoding semantics; verifier admits only registered profiles |
| Schema package | Versioned package: manifest/sidecar/record-envelope/payload schemas, ordering profiles, typed rights/coverage/lineage schemas, semantic constraints, canonical vectors and ONE package digest; strict schemas, explicit required arrays, tagged unions; structural validation insufficient; schema shared, validators not |
| Five added decisions | One authoritative root `contract_version` (formal requirements amendment); versioned per-event-type payload schema registry; supersedes revision = immediate predecessor; consumer rights separate from producer rights evidence; venue-less sources outside Profile 1 |

The canonical schema package was published by work package B8 as the version 1 package recorded
below. This decision supersedes neither approved semantics nor the freeze; it claims none of
`SCHEMA_CONFORMANT`, `CROSS_EXECUTED`, `CRYPTOGRAPHICALLY_VERIFIED`, `RIGHTS_ADMITTED` or
`DATASET_ACCEPTED`.

## Publication durability failure model (ratified 2026-11-24)

Ratification: `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md`
(status **RATIFIED by owner direction 2026-11-24**, current digest
`931e7477faa7752248a2392d7b79f34c317ab95a838a88ee491f448eac6dbcfb` after the FB-DUR-002
full-matrix D0 evidence extension; prior WS-EVIDENCE-026 digest `d3a18e62bd31d6e9492078edf6d3cfb80ae2e69fa977a497780b54ef00aea8b6` and original
ratification digest `2b04f9b40fd395973f0f0ab99bc47a73f1e82a8b375e2ec4c5de211e85095b71` are preserved as historical in `REVIEW-LOG.md`).
The owner directed that
durability be scoped to a failure model rather than a test count. This is the governing programme
contract for durability claims; it is not a new claim that D1 is achieved and it promotes no
implementation state.

| Tier | Failure model | Ratified profile predicate |
|---|---|---|
| D0 | Process termination; OS, filesystem and device remain functional | `D0_PROCESS_RECOVERY_VERIFIED=true` (PUB-020 and DUR-002 evidenced at exact commits; 28-exit-point matrix at `4e0f2f5`) |
| D1 | OS crash / filesystem crash, including qualified physical power loss | `D1_APFS_QUALIFIED=false`; `D1_EXT4_QUALIFIED=false` |
| D2 | Local device failure | `D2_LOCAL_DEVICE_FAILURE_QUALIFIED=false` |
| D3 | Host failure | `D3_HOST_FAILURE_QUALIFIED=false` |
| D4 | Disaster recovery | `D4_DISASTER_RECOVERY_QUALIFIED=false` |

There is no single global durability Boolean. `PUBLICATION_DURABILITY_VERIFIED` is an aggregate
programme status gate and remains `false` until D1 evidence exists. Linux
`renameat2(RENAME_NOREPLACE)` and macOS `renamex_np(RENAME_EXCL)` with `fsync` are the ratified
no-replace primitives; macOS `F_FULLFSYNC` may be required for drive-cache flush and is not yet
used or qualified. VM reset is not a physical power-loss test; D1b physical power loss remains
unqualified. Declaration is governed by Decision G; the Fieldbook v2 publication journal, the
PUB-019/020/021 work packages and DUR-002, and the cross-cutting invariants I-01..I-15 are recorded
in WS-DUR-001. Current D0 subprocess evidence is the FB-DUR-002 matrix at Fieldbook `4e0f2f5`
(PR #74): **28 concrete exit points covering all 24 owner boundary names**, with expected outcomes
`NO_EVIDENCE` 1, `UNCERTAIN_PUBLICATION_QUARANTINED` 17, `RECOVERED_STAGED` 2,
`RECOVERED_PUBLISHED` 7 and `ALREADY_AVAILABLE` 1, plus idempotent second recovery for every
`RECOVERED_*` row. The earlier three-case scope (`publish_before`, `publish_staging`,
`publish_rename`) is preserved as HISTORICAL evidence and superseded for current evidence;
in-process fault injection remains a separate evidence class.
`D0_PROCESS_RECOVERY_VERIFIED` is ACHIEVED for the D0 process-termination profile only, and
`PUBLICATION_DURABILITY_VERIFIED` remains NOT ACHIEVED. D1 OS/filesystem crash, D1b power loss and
D2–D4 are unqualified; no global durability claim is made. See
`engineering/conformance/d0-full-matrix-evidence-2026-11-24.md`. No approved capability state,
right, dataset or freeze term is changed by this rule.

## B15/B16 streaming architecture ratification (2026-11-25)

Ratification: `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md`
(status **RATIFIED by owner direction 2026-11-25**). It approves exactly twelve architecture
and interface-contract items (A-01..A-12) and resolves all twenty open decisions individually:
OD-01..OD-10 from B15 §10.2 and D1..D10 from B16 §10. No numeric maximum from B15 §6.2,
production memory budget, concurrency setting, throughput or CPU target, codec identifier,
PERF-001 assignment or operational qualification is approved.

| Item | Registered state |
|---|---|
| Architecture and contracts | **RATIFIED NOW** for bounded record-source interfaces, streaming producer/verifier pipelines, the two-intent lifecycle, byte-derived ordering, Profile 1 digest compatibility, deterministic streaming compression, incremental stored/expanded digests, bounded decompression and parsing, cancellation/backpressure/failure semantics, descriptor-relative private snapshot writing and cleanup, independent implementations and separate publication/admission receipts |
| Implementation | **IMPLEMENTED at Phase 3 final heads** FB `8216197124d33466fbe651e417b7c19505e4155e` (B15, PR #75) and NZ `c1c2f0d984bee11a63eb1df98833ee8723cd8629` (B16, PR #145) with finite, explicitly marked `TEST_ONLY` profiles; `STREAMING_IMPLEMENTATION_COMPLETE` ACHIEVED, not `Verified`. No production invocation without an approved role profile selected by trusted local policy; producer declarations never raise the consumer ceiling |
| `STREAM_RESOURCE_PROFILE_RATIFIED` | **PENDING**: requires owner approval of every numeric limit and one profile digest per `ProcessingRole` (`PRODUCER`, `VERIFIER`, `RECOVERY`, `SNAPSHOT`) |
| `PERF_001_QUALIFIED`, `OPERATIONALLY_QUALIFIED` | **BLOCKED** |
| `PUBLICATION_DURABILITY_VERIFIED` | **false**, unchanged under WS-DUR-001 |
| Design documents | Both remain **PROPOSED / AWAITING OWNER APPROVAL**; a pointer records the architecture ratification and the deferred numbers |

The `ResourceProfile` contract is immutable and versioned: `ResourceProfileId {name, version}`
and `ResourceProfile {id, digest, role, limits}` with private validated fields, a digest over
canonical fields, and role-specific budgets. Trusted local policy selects the profile; the
effective limit is the stricter of consumer local ceiling, consumer role profile and any
producer declaration. Caller-supplied raw limits are not normative. No approved digest, schema
version, rejection code or historical record was edited by this decision.

**Implementation status (Phase 3, 2026-11-25):** the ratified contracts are implemented at
FB `8216197` / NZ `c1c2f0d` under finite `TEST_ONLY` profiles; this is an `Implemented` state only.
Numeric maxima, the codec identifier, `STREAM_RESOURCE_PROFILE_RATIFIED` and PERF-001 remain
deferred or blocked. See `engineering/conformance/phase-3-acceptance-2026-11-25.md`.

## Phase 3 evidence acceptance (2026-11-25)

| Item | Record |
|---|---|
| Acceptance record | `engineering/conformance/phase-3-acceptance-2026-11-25.md` — digest `3a823688f59bca1fd78ba8f02231b97f8d40d98647430551fbc2e805a0cb2ee4` (`shasum -a 256`), docs/JSON only, no commit |
| Final heads | Fieldbook `8216197124d33466fbe651e417b7c19505e4155e` (PR #75), Nirnay `c1c2f0d984bee11a63eb1df98833ee8723cd8629` (PR #145); Workspace base `6dcca8b`; audited subject `6d45af2` and packaged head / evidence commit `95580f5` unchanged |
| Hosted CI | FB `45491963354` success 2/2 after stale-branch rerun; NZ `45491893837` success 12/12; Workspace hosted CI `NOT_RUN` |
| Cross-execution | producer PASS; structural, manifest, signature, publisher, artifact and ordering PASS; stage 6 `REJECT_RIGHTS_EVIDENCE`; `RIGHTS_ADMISSION_REFUSED`; no Nirnay admission receipt; no surviving snapshot; dataset `BLOCKED` |
| Capability states | `STREAMING_IMPLEMENTATION_COMPLETE` ACHIEVED, `STREAM_RESOURCE_PROFILE_RATIFIED` PENDING, `PERF_001_QUALIFIED` BLOCKED, `PUBLICATION_DURABILITY_VERIFIED` false, `OPERATIONALLY_QUALIFIED` BLOCKED, `RIGHTS_ADMITTED` and `DATASET_ACCEPTED` false; D0 achieved at `4e0f2f5`, D1/D1b/D2–D4 false |
| Non-claims | No numeric maximum approved; no production invocation without an approved role-specific `ResourceProfile`; verifier local ceiling always stricter; PERF-001 and D1 not run; freeze unchanged |

The acceptance record updates the five separately evidenced `CURRENT-STATE.json` head concepts and
adds pointers to the historical sprint, provenance, evidence-manifest and D0 records. Those
records are preserved unchanged and are not rewritten by this registry entry.

## B8 canonical schema package (published 2026-11-24)

| Item | Record |
|---|---|
| Package | `engineering/conformance/ndc-v2-schema-profile-1/` — version 1 of the language-independent canonical NDC v2 Profile 1 wire schema |
| Authority | `WS-NDC-2026-11-24-003` (`417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119`); Profile 1 Decisions A–I (`fb8a4992…`) and the 102-row WP-B6 reconciliation |
| Files | **26** indexed files: 8 JSON Schemas, 16 canonical abstract vectors and 2 normative documents |
| Schemas | `manifest.schema.json`, `signature-sidecar.schema.json`, `record-envelope.schema.json`, `ordering-profiles.schema.json`, `rights-evidence.schema.json`, `coverage.schema.json`, `lineage.schema.json`, `payload-schema-registry.schema.json` — draft 2020-12, strict object levels, explicit `required` arrays, tagged unions, no defaults or coercions |
| Normative documents | `semantic-constraints.md` (cross-field rules, five distinct status states, structural validation insufficient); `compatibility-and-evolution.md` (reject unknown/missing/wrong-type/coercion, version bumps, breaking semantic changes) |
| Vectors | 16 files; seven WP-5 vectors copied and adapted to the canonical wire representation, plus nine new vectors for required venue/segment, typed rights, typed operation evidence, coverage denominator arithmetic and no-PASS, complete PROV lineage and predecessor revision, tagged ordering, byte-derived key mismatch, duplicate `contract_version` and payload registry. The originals in `ndc-v2-conformance-vectors/` are unchanged |
| Index and digest | `VECTORS.md` lists the SHA-256 of every indexed file; `scripts/check_ndc_schema_package.py` prints one `SCHEMA-PACKAGE-DIGEST 6e8c1e48e27289b8c3d3e959a06a805e736d0759b4fb244edbb074f65e107bab` over the sorted (path, sha256) list with domain prefix `NDC-V2-PROFILE-1-SCHEMA-PACKAGE-DIGEST-V1` |
| Checker scope | Verifies every indexed digest, JSON parseability and no duplicate JSON members, `additionalProperties:false` and explicit `required` at object levels in every schema, vector no-secret/no-external-observation patterns, and prints the package identity |
| Non-claims | Documentation and abstract evidence only. No Rust source, shared runtime crate, release, dataset, receipt, key, right, provider contact, collection, India implementation or experiment. Cross-execution, wire compatibility and the five status states remain NOT_STARTED / unclaimed |

## Separate consumer-use proposal (not approved)

| Document | Digest | Status |
|---|---|---|
| Nirnay `engineering/ndc-consumer-use-v2-proposed.md` | `4b9d1fe7190de08151989fc8895f42e1daa737021e8dae019ddc3325f9603a2c` | **Proposed** — no separate approval record |

The 2026-11-23 ratification explicitly names the C0 model and the v2 producer/consumer
requirements. It does not ratify every separate consumer-use implementation proposal. This
document's semantics are not silently included in the ratified NDC v2 set, and its status is
not changed by approval of the requirement documents or by NDC v2 Release Serialization
Profile 1.

## WP-5 conformance package (2026-11-24)

| Item | Record |
|---|---|
| Package | WS-NDC-INT-001 / WP-5 cross-repository NDC v2 conformance package |
| Exact heads | Fieldbook `2ef88a955f74a7c88e4573683267446e331465e9` (PR #62 producer merged); Nirnay `2dad4962b584c557237d219c1c5356fc58bc4b69` (PR #142 verifier merged); Workspace `959143e8996960bfaee233e03cf40d063c47316e` (WP-2 ratified) |
| Schema registration | `engineering/conformance/ndc-v2-schema-digest.json` — Profile 1 ratification digest `fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc`; D1 amendment digest `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894` |
| Acceptance matrix | `engineering/conformance/ndc-v2-acceptance-matrix.md` — ten WP-5 checks with exact producer and verifier test evidence, both sides' states and typed rejection codes |
| Vectors | `engineering/conformance/ndc-v2-conformance-vectors/VECTORS.md` — seven abstract non-market vector files with SHA-256 values |
| Evidence checker | `scripts/check_ndc_conformance_vectors.py` — workspace evidence tool; not a producer, verifier, connector or shared runtime crate |
| States | Producer and verifier: `TESTED_WITH_ABSTRACT_VALUES` at the exact heads. Cross-execution and wire compatibility: **NOT_STARTED**. A standalone published canonical schema artifact now exists in Workspace as the B8 package above (it is not present in either source repository at the recorded heads). No implementation state promoted. The canonical wire requirements are ratified by `WS-NDC-2026-11-24-003`; the B8 package registers their schema form and claims no conformance or cross-execution status. |

The WP-5 package does not change any approved digest. D0 `3dace660…`, D1 `215a5b55…`,
D2 `22eaef7d…`, v1 digests and the separate consumer-use `4b9d1fe7…` **Proposed** status stay
as recorded above. The consumer-use document is not an authority for the independent release
verifier.

## Structural rule

Two levels are kept distinct. Dataset-wide facts appear once in the release manifest;
per-observation facts appear in the event envelope.

**Release manifest:** dataset identity and source scope, coverage and completeness,
rights and retention, schema versions, release digest, publication identity.

**Event envelope:** source and instrument identity, event type and typed payload,
source and receive times with clock domain, sequence and continuity, raw digest and
lineage reference, revision and as-of information.

## Compatibility rule

A consumer must reject a release when any required manifest field is absent, denied,
expired, or inconsistent with the event envelope. A producer must not publish a release
that fails its own validator. Version changes follow the semantic rules in each
repository's NDC document. Compatibility is decided by those rules, not by a transport.

## Change procedure

1. Open paired PRs, one per repository, referring to the same NDC version.
2. Keep producer and consumer validators in lockstep; neither may drift ahead.
3. Run `make check-static` in both repositories and `make consistency` here.
4. Obtain independent review for each PR and record CI runs.
5. Register the resulting commits in `REVIEW-LOG.md`.
6. Change an approved digest only through a separately approved revision; never edit the
   approved bytes silently. An amendment is a new dated revision document with its own digest
   (as `NDC-D1-AMENDMENT-001.md` does for D1); the historical digest and approved bytes stay
   unchanged.
