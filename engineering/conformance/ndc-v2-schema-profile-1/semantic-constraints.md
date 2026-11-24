# Canonical NDC v2 Profile 1 — semantic constraints

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: normative companion to the versioned canonical schema package for NDC v2 Release
Serialization Profile 1, published under work package B8 on 2026-11-24. Authority:
`engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` (RATIFIED by
owner direction 2026-11-24, digest
`417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119`), together with
`WS-NDC-2026-11-24-002` (Decisions A–I, digest
`fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc`) and the 102-row
WP-B6 reconciliation. This document adds no approval, creates no release, grants no right and
claims none of the five distinct status states listed in section 12.

## 0. Structural validation alone is insufficient

The JSON Schema files in this package enforce shape, closed member sets, tagged unions,
required fields and literal or enumerated values. They cannot enforce cross-field arithmetic,
digest equality, derivation from canonical bytes, registry trust, time ordering, lifecycle
rules or graph properties. A document that merely compiles against the schemas, and a vector
that merely parses, is **not** conformance. Every invariant below must be implemented and
exercised independently by the producer and the verifier against the same versioned schema and
vectors. Failure of any invariant fails the whole release closed at the first refusal. Schema
conformance is not cryptographic verification, cryptographic verification is not a right, and
a right is not dataset acceptance.

Encoding precondition for every canonical wire document: UTF-8 without BOM, RFC 8785 JCS
canonical byte sequence, strict parsing with duplicate property names rejected, no implicit
defaults, no inferred values, no silent coercions and no unversioned extensions. An explicit
schema version is required; an unknown or unregistered version fails closed. Numbers used as
counts, byte sizes, instants, revisions or exact decimals must not appear with a fractional or
exponent token in canonical bytes. A decimal-string instant matches `^(0|[1-9][0-9]*)$`, is
within the u64 range and is nanoseconds since the Unix epoch in UTC. A count or byte size is a
JSON integer below 2^53 or a decimal string for the full u64 range, selected by value. IEEE
754 binary floating point is never used for an exact quantity.

## 1. Manifest digest location and circularity

- `contract_version` appears exactly once, at the manifest root. A nested
  `schema_versions.contract_version` or a duplicate root member fails strict validation. This
  is a formal requirements amendment carried separately; no approved D1 or D2 byte was edited.
- The manifest contains no self-digest, no `manifest_sha256` member, no `limits` member and no
  redundant `digests.artifact_digests[]`. No property is excluded, removed, blanked or replaced
  by a placeholder before canonicalization.
- Let `M = JCS(manifest.json)` and `H_M = SHA256(M)`. `H_M` is computed over the complete
  canonical bytes. The manifest retains its publication identity, signing key id and signature
  reference; those members are inside the signed bytes.

## 2. Detached sidecar binding

- `signature.json` has exactly five members: `schema_version`, `algorithm`, `key_id`,
  `manifest_sha256`, `signature_b64`. A `domain` member, a sixth member, an embedded key or any
  private key material fails closed.
- `manifest_sha256` equals `H_M` from section 1. Sidecar `key_id` equals the manifest
  `publication_identity.signing_key_id` and resolves, through the out-of-band trusted registry,
  to the same publisher identity as `publication_identity.publisher_identity`.
- The signature is Ed25519 over `D || H_M` with `D = UTF8("NDC-V2-RELEASE-MANIFEST-SHA256-V1")
  || 0x00`. `algorithm` is the literal `Ed25519`; `signature_b64` is standard padded base64 of
  exactly 64 signature bytes.
- Verifier order: parse complete manifest; reject duplicate names; strict schema validation;
  canonicalize; SHA-256; compare sidecar digest; resolve trusted public key; verify Ed25519;
  bind sidecar key id to publisher; continue. Ambiguous or extra fields fail closed with no
  partial verification. Publisher integrity proves publisher-key control and integrity of the
  exact signed bytes only; it proves no right and no availability.

## 3. Byte-derived record ordering

- Artifact-level `record_order_profile` is a tagged object with closed `kind` set: sequenced
  requires non-empty `sequence_domain_id` and `sequence_epoch`; reference carries neither. A
  bare string profile fails validation.
- Per-record `ordering` is a tagged object with exactly one mode. Sequenced carries
  `sequence_domain_id`, `sequence_epoch`, `sequence_number`; reference carries `object_id`,
  `revision`, `knowledge_time_ns`, `assertion_id`. A record carrying both key sets fails
  validation. A record's mode, domain and epoch must match the containing artifact profile.
- The producer must parse the canonical record bytes, extract the ordering fields from those
  parsed bytes, validate them against the artifact profile, derive the ordering key from the
  validated parsed values, sort by that derived key, and then serialize and emit the same
  validated canonical bytes. The verifier independently repeats the parse/extract/validate/
  derive/check sequence on the received canonical bytes. No caller-supplied order key,
  position, index or pre-sorted hint is trusted. A key that does not recompute from the record
  bytes is rejected on both sides.
- Event time is never a sort key; no fallback to event time exists. No sequence number is
  fabricated. Known gaps stay visible and are not filled or interpolated. Duplicate keys with
  conflicting payloads are rejected. Comparison across unrelated sequence domains is a
  serialization convention and carries no semantic claim.

## 4. Artifact set and digests

- `artifacts[]` is the sole inventory. `(logical_partition_id, shard_ordinal)` is unique across
  the release and defines canonical artifact order; the published file set must equal the set
  derived from this array. An extra file, a missing file, a duplicate normalized path or a
  duplicate pair fails closed.
- Each descriptor binds exactly twelve members. `stored_sha256` binds the exact stored bytes at
  the declared path; `uncompressed_sha256` binds the exact decoded canonical record stream.
  Declared sizes are checked before reading and against actual byte counts while reading.
- Paths are release-relative, NFC-normalized, restricted to the component alphabet, free of
  traversal and duplicate normalized forms. The verifier opens descriptors without following
  symbolic links and admits only regular files.
- Compression method, profile, registered string `compression_version` and decoding semantics
  are bound together by the descriptor. Only registered profiles are admitted; an unknown
  method, profile or version identifier fails closed. No inference from magic bytes or file
  extension is allowed. The same logical shard is not published twice under different
  encodings or compression settings.
- The registered string identifiers for schema version 1 are `none/1` and
  `gzip-deflate/flate2-1`. A change to the registry is an explicit versioned schema change with
  its own digest, not a silent addition.

## 5. Dataset digest

`data_sha256 = SHA256(B1 || B2 || ... || Bn)` where `Bi` is the exact uncompressed canonical
record stream of artifact `i` in canonical artifact order. The dataset digest is independent of
compression: compression changes `stored_bytes` and `stored_sha256` only. A mismatch between
the recomputed and declared dataset digest blocks use. No count of physical lines substitutes
for a logical record count or a coverage denominator.

## 6. Required source scope

`provider_id`, `source_product_id`, `venue_id`, `segment_id` and `dataset_id` are all required
non-empty valid identifiers. Empty strings, `UNKNOWN`, `ALL`, placeholders of any kind and
`null` are rejected in each field. No venue, segment, product, provider or dataset default
exists. Venue-less sources — documents, filings, economic data and any other source without a
named venue — are outside Profile 1 and require a future explicit owner decision defining a
separate profile with its own scope and coverage rules.

## 7. Performed operations and evidence separation

- `producer_activity` has exactly two members. `performed_operations` is an array of
  structured `{operation_ref, action, data_object:{kind,id,version}}` objects; `action` is a
  value from the 14-value producer `Operation` enum stored as its enum value. An opaque string
  reference is rejected.
- `operation_evidence` is a separate array of typed records carrying exactly `operation_ref`,
  `event_id`, `run_id`, `recorded_at_ns`, `decision_key` and `digest_sha256`.
- Every performed operation resolves exactly one evidence record by `operation_ref`. Duplicates
  reject, missing evidence rejects, reassignment to another operation rejects, and an evidence
  record with no matching performed operation rejects.
- The producer 14-value enum, the consumer five-value enum and the separate `create_derived`
  value remain separately owned. No producer-to-consumer mapping is implied by a wire value;
  explicit mapping tables, if any, remain documentation.

## 8. Rights evidence separation

- The wire carries full typed source-rights evidence, not opaque reference strings. A grant
  carries immutable grant identity with revision, typed granting authority with evidence
  reference (distinct from the signing key and the reviewer), action, object class, exact
  uppercase `PERMIT` or `DENY` decision, actor, licensee, recipient class and identity, purpose
  and scope, named validity interval with clock domain, delivery method with approved endpoint
  identities, bounded retention with purge rule, supporting document references with digests,
  contract revision, review authority and review date, and a reviewed attestation.
- Document references are typed with clause, lowercase hex document digest, contract revision,
  review authority and review date. Attestations are typed, record review and are not permission
  for an action absent from a grant. The grant's embedded attestation and the registered
  attestation for the same `grant_id` must be identical; a mismatch rejects.
- Producer rights evidence is separate from consumer authorization. A consumer admission
  request, capability claim, signature, receipt, publication state or lineage chain grants no
  right and cannot substitute for source-rights evidence. Rights evidence is an independent
  signed section and fails closed when absent. The separate consumer-use proposal is not an
  approved rights contract and supplies no grant, purpose, licensee, recipient or retention
  value. Rights remain `UNKNOWN` until written evidence and owner approval exist.

## 9. Coverage arithmetic and verdict gating

- Each coverage dimension carries `dimension_id`, `universe_id`, `denominator_identity`,
  `count_basis`, `numerator`, `denominator`, `missing_count`, `rejected_count`, `as_of_ns`,
  `verdict`, `evidence_reference` and typed `gaps`.
- `denominator` is required and non-zero. There is no PASS without a declared denominator,
  declared universe, denominator identity, count basis, as-of instant and evidence reference.
  `as_of_ns` uses the ratified instant grammar and is consistent with the release as-of.
- Counts are disjoint parts of one denominator. The default exhaustive arithmetic is
  `accepted (numerator) + missing_count + rejected_count = denominator`. A dimension using
  different arithmetic must declare the actual arithmetic and the meaning of every component;
  an undeclared or overlapping decomposition rejects. Gaps are typed descriptions of missing
  or rejected components and are never silently filled, interpolated or implied as `ALL`.
- The nine dimensions are separate, each with its own universe, denominator and as-of instant.
  Passing one dimension implies nothing about another and no aggregate percentage substitutes
  for a dimension. `verdict` uses the closed vocabulary `PASS`, `FAIL`, `UNKNOWN`. A
  producer-supplied PASS does not promote the verdict: it is admitted only when all required
  evidence is present and the independent semantic evaluation agrees; otherwise the dimension
  fails closed.

## 10. Lineage cycles, regression and revision semantics

- `lineage` is one typed structure with raw archive reference plus digest, transformation
  identity plus version, knowledge time, current revision, typed `was_derived_from`,
  `was_revision_of`, `had_primary_source`, `generated_at_time`, `invalidated_at_time`, qualified
  attribution and an optional `supersedes`. PROV relations name sources and activities; they
  establish neither permission nor truth.
- `lineage.revision` is the current release revision. `lineage.supersedes.revision` is the
  immediate predecessor revision, strictly less than the current revision; chain traversal
  decrements by one. An initial release has no predecessor (supersedes is null); a corrected
  release has exactly one immediate predecessor in Profile 1. A multi-predecessor array is not
  modelled here.
- `supersedes` is one seven-member relation: `supersedes_release_id`,
  `supersedes_manifest_sha256`, `supersedes_data_sha256`, `revision`, `correction_reason`,
  `knowledge_time_ns`, `invalidated_at_time`. Event-level correction lineage remains separate
  and is not merged into the release-level relation.
- `invalidated_at_time` is a canonical UTC string, not an opaque string and not an integer
  nanosecond value: RFC 3339 profile restricted to `Z`, form
  `YYYY-MM-DDTHH:MM:SS.fffffffffZ` with exactly nine fractional digits, proleptic Gregorian
  calendar, no offset form and no leap second. The decoded value must be a valid calendar
  instant.
- Reject cycles, missing predecessors, revision regression, self-reference, mismatched release
  identity, future knowledge time and a release supplying its own predecessor. Trusted
  predecessor evidence resolves outside the release. Both producer and verifier perform the
  validation independently and fail on the first breach.

## 11. Trusted key lifecycle, resource policy, availability and receipt

**Trusted keys.** An out-of-band registry is authoritative; each entry carries publisher id,
immutable key id, Ed25519 public key, purpose, validity begin and end, state
`ACTIVE`/`RETIRED`/`REVOKED`/`COMPROMISED`, registry revision and revocation evidence. Key ids
are never reused. No private key is stored in Git or in a release package. A release cannot
supply its own trusted key. `ACTIVE` signs and verifies; `RETIRED` cannot sign new releases and
historical verification requires trusted evidence of publication before retirement;
`REVOKED` and `COMPROMISED` fail closed. A compromise exception requires a separately approved
policy with an independently trusted pre-compromise time. A publisher-supplied timestamp is
insufficient for key validity or revocation. Batch B uses an injected test key only; no
production key is generated or activated. The rights-review authority is separate from the
signing authority.

**Resource policy.** The manifest has no `limits` member. A versioned normative consumer
resource policy is enforced independently by producer and verifier; the consumer never adopts
producer-declared maxima as authoritative. The policy covers manifest bytes, artifact count,
stored bytes, expanded bytes, record length, record count, JSON nesting depth, array and object
sizes, compression window, decompression budget, temporary disk and file descriptors.
Processing is bounded streaming: no buffer or allocation is sized from an untrusted declared
size without a prior bound check and an actual-byte-count check while reading. Numerical maxima
are set only after workload qualification; this package invents no unmeasured number.

**Availability and receipt.** Publication is the state machine `STAGING_CREATED ->
FILES_WRITTEN -> FILES_SYNCED -> STAGING_DIR_FSYNCED -> ATOMIC_NO_REPLACE_RENAME ->
PARENT_DIR_FSYNCED -> DURABLE_PUBLICATION_RECEIPT -> AVAILABLE`. Staging is an exclusive sibling
directory on the same filesystem; every file and the staging directory are synced; the final
move is an atomic no-overwrite rename followed by a parent-directory sync. A durable receipt in
the producer journal or catalog binds release identity, manifest digest, dataset digest,
publication operation identity, commit position and result. The receipt, not directory presence,
is durability evidence. A crash after rename but before parent-directory sync is an
uncertain-publication recovery case, not an acknowledgement. No existence-check-then-rename, no
overwrite and no second publication of an existing identity. A declared `AVAILABLE` state in the
manifest is not proof of durable publication. The producer publication receipt and the consumer
admission receipt are different objects; neither grants a right. First refusal stops the whole
release; no partial admission exists.

## 12. Distinct status vocabulary

For later cross-execution reporting these states are distinct and must not be collapsed:

- `SCHEMA_CONFORMANT` — the canonical schema and vectors exist and a representation passes them.
- `CROSS_EXECUTED` — a producer-generated release has been processed by the independent
  verifier across the agreed boundary.
- `CRYPTOGRAPHICALLY_VERIFIED` — signature and digests verified with an out-of-band trusted key.
- `RIGHTS_ADMITTED` — source-rights evidence and consumer authorization independently admitted.
- `DATASET_ACCEPTED` — the dataset has passed the separate owner acceptance gate.

This package publishes a schema artifact and vectors. It claims none of these five states.
Cross-execution and wire compatibility remain NOT_STARTED until paired work exists.

## 13. Frozen boundaries

Freeze unchanged: rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection
`DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict. No approved byte,
historical digest, key, release, dataset, provider contact, collection, right or experiment is
created or changed by this package. No Rust source implementation, shared runtime crate, shared
validator, shared serializer or shared digest routine is introduced. The schema and vectors are
shared; validator implementations are not.
