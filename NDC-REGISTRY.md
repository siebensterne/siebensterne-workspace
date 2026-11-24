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
| Canonical wire authority | One third, language-independent canonical NDC v2 Profile 1 wire schema; neither Rust representation is normative; both repositories keep independent internal representations with explicit serialization/deserialization mappings; no shared runtime crate; B8 creates the schema package |
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
| Canonical wire schema authority | **Ratified 2026-11-24**: one language-independent canonical wire schema for Profile 1; B8 package and cross-execution still NOT_STARTED | `WS-NDC-2026-11-24-003` (`417bd4e5…`): strict UTF-8/RFC 8785 JCS, decimal-string nanosecond instants, byte-derived tagged record ordering, typed operations/evidence, source scope, rights, coverage, lineage, registered compression versions, versioned schema package with one digest; DP-01..DP-30 resolved; no shared runtime crate |
| Final NDC serialization schema | **Profile 1 version and digests registered; standalone published schema artifact NOT_STARTED** | `engineering/conformance/ndc-v2-schema-digest.json` registers the exact version, profile and D1 amendment digests, strict unknown-field policy and the source of truth; no standalone schema file exists at the recorded heads, so the typed structs in both repositories are the implementation authorities |
| Resource policy | **Ratified rule**: versioned normative consumer resource policy, no manifest `limits`, producer and verifier enforce independently; numerical maxima pending workload qualification | `WS-NDC-2026-11-24-002` Decision F |
| Publication durability | **Ratified rule**: staged, synced, atomic no-replace rename with parent-directory sync and durable receipt; uncertain-publication recovery after rename before parent sync | `WS-NDC-2026-11-24-002` Decision G |
| Trusted publisher registry | **Ratified rule**: out-of-band registry with key states and revocation evidence; Batch B trust interface with injected test keys only | `WS-NDC-2026-11-24-002` Decision H |
| Runtime implementation | Producer and independent verifier implemented at the exact PR heads; **cross-execution NOT_STARTED** | WP-5 acceptance matrix records exact test evidence at Fieldbook `2ef88a9` and Nirnay `2dad496`; no shared invocation boundary or connector, no verification promotion |
| Consumer verification capability | Independent `release-verifier` crate implemented at Nirnay `2dad496`; **Proposed consumer-use proposal unchanged** | Twelve-stage verifier with abstract tests; no shared crate; the separate consumer-use document below is not approved and is not an authority for this capability |

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

The canonical schema package is work package B8 and does **not** exist yet. This decision
supersedes neither approved semantics nor the freeze; it claims none of
`SCHEMA_CONFORMANT`, `CROSS_EXECUTED`, `CRYPTOGRAPHICALLY_VERIFIED`, `RIGHTS_ADMITTED` or
`DATASET_ACCEPTED`.

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
| States | Producer and verifier: `TESTED_WITH_ABSTRACT_VALUES` at the exact heads. Cross-execution, wire compatibility and a standalone published schema artifact: **NOT_STARTED**. No implementation state promoted. The canonical wire requirements are now ratified by `WS-NDC-2026-11-24-003`; no conformance or cross-execution status is claimed by that decision. |

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
