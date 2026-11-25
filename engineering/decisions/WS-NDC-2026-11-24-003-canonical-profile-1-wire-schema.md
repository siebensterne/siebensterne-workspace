# WS-NDC-2026-11-24-003 — Canonical NDC v2 Profile 1 Wire Schema

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **RATIFIED by owner direction dated 2026-11-24.**

Authority: owner direction under `WS-SCOPE-2026-11-24-001` and the owner disposition of the
WP-B6 field-level wire reconciliation
`engineering/conformance/ndc-v2-wire-contract-reconciliation.md` (DP-01..DP-30). The owner has
already decided: there is **one third, canonical, language-independent wire schema** for NDC v2
Release Serialization Profile 1. Neither Fieldbook's current Rust representation nor Nirnay's
current Rust representation is normative; both are internal representations behind explicit
mappings.

This record ratifies the canonical wire authority and its semantic invariants. It is **not** a
schema artifact, not a serializer, not a verifier, not a shared runtime crate, not a source
implementation and not a cross-execution. The schema package itself is work package B8; this
decision defines what that package must contain and ratifies its rules in advance. No commit,
release, key, provider contact, collection, rights grant, dataset acceptance, admission receipt,
India implementation or experiment is authorised here.

## 1. Headline owner decision

1. The canonical NDC v2 Profile 1 wire schema is a **language-independent normative wire
   authority**. It is not either repository's Rust type set.
2. Fieldbook and Nirnay each keep their **own independent internal representation**. Each side
   supplies explicit **serialization** (internal value -> canonical wire bytes) and
   **deserialization** (canonical wire bytes -> internal value) mappings to and from the canonical
   schema. Representation differences that do not change canonical bytes are implementation
   details; they are not wire differences.
3. **No shared runtime crate.** No shared validator, serializer, deserializer, digest routine,
   rights engine or ordering crate is introduced. The schema and the canonical test vectors are
   shared; validator implementations are not.
4. This decision resolves **DP-01..DP-30** of the reconciliation record. Section 11 gives the
   disposition of each point.

## 2. Authorities and preservation

| Label | Authority | Digest | Effect |
|---|---|---|---|
| D0 | `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` | `3dace660c362e683790ba7e56a785ded8af836abda36f6eab06ed284de49eed2` | unchanged |
| D1 | `fieldbook:engineering/ndc-producer-requirements-v2-proposed.md` | `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c` | unchanged bytes; formally amended as in §8 |
| D1-am | `engineering/conformance/NDC-D1-AMENDMENT-001.md` | `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894` | unchanged |
| D2 | `nirnay:engineering/ndc-consumer-requirements-v2-proposed.md` | `22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957` | unchanged |
| Profile 1 | `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md` | `fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc` | unchanged; Decisions A-I preserved |

The separate Nirnay consumer-use proposal
`nirnay:engineering/ndc-consumer-use-v2-proposed.md`
(`4b9d1fe7190de08151989fc8895f42e1daa737021e8dae019ddc3325f9603a2c`) remains **Proposed** and
is not an authority and not an approved rights contract. The WP-B6 reconciliation remains a
PROPOSED review record; this decision does not alter its bytes beyond the pointer recorded in
its decision-summary section. No approved byte is edited or re-digested by this decision. The
v1 historical digests and every other registered historical digest remain as recorded.

## 3. Canonical encoding and strict parsing

Ratified for every canonical wire document (manifest, sidecar, record envelope and payload,
and every typed substructure):

1. **UTF-8** byte encoding; no BOM.
2. **RFC 8785 JSON Canonicalization Scheme (JCS)** is the canonical serialization. Property
   ordering, string escaping and number serialization follow RFC 8785 exactly.
3. **Strict parsing.** Duplicate property names are rejected. Unknown properties are rejected.
   Missing required properties are rejected. Incorrect JSON types are rejected. There are
   **no implicit defaults**, no inferred values, no silent coercions and no unversioned
   extensions.
4. An **explicit schema version** is required on each versioned wire document; an unknown or
   unregistered version fails closed.
5. **Exact numeric semantics.** Numbers are parsed and emitted without loss. IEEE 754 binary
   floating point is never used for a count, byte size, instant, financial quantity or exact
   decimal; numbers with exponents or fractional parts that cannot be represented exactly under
   the canonical numeric rules are rejected rather than rounded.
6. The canonical bytes are the sole input to digesting, ordering and signing. A digest is over
   complete canonical bytes; no property is removed, blanked or withheld before canonicalization
   (Profile 1 Decisions A and D).

## 4. Instants, counts and numeric ranges

1. Every nanosecond instant on the wire (`as_of_ns`, `created_at_utc_ns`, `knowledge_time_ns`,
   `recorded_at_ns`, request `as_of`, and every other time axis) is a **decimal string** matching
   `^(0|[1-9][0-9]*)$`, validated to be within the `u64` range. The unit is nanoseconds since
   the Unix epoch in UTC; no unit change is silently applied and no integer form is coerced from
   a string or vice versa. Field-level positivity and ordering invariants already approved remain
   semantic checks on the parsed value.
2. Counts and byte sizes (`record_count`, `stored_bytes`, `uncompressed_bytes`, `numerator`,
   `denominator`, `missing_count`, `rejected_count`, `sequence_number`, `revision`, and all other
   counts and sizes) are written as a **JSON integer when the value is below 2^53**, or as a
   **decimal string** matching `^(0|[1-9][0-9]*)$` within the `u64` range when the full `u64`
   range is needed. The representation is selected by value, never by caller preference.
3. **No float for a financial quantity**, exact decimal, count or byte size. A JSON number with
   a fractional part or exponent in such a field is rejected; it is not rounded or coerced.
4. `invalidated_at_time` is the one named exception in §10: it is a canonical UTC string with
   the explicit grammar and precision given there.

## 5. Record ordering

Ratified (supersedes the representation choices in DP-18, DP-20 and DP-21):

1. **Artifact-level `record_order_profile` is a tagged object**, never a bare string:

   - sequenced: `{"kind":"sequenced","sequence_domain_id":...,"sequence_epoch":...}`
   - reference: `{"kind":"reference"}`

   The `kind` values are a closed set. A sequenced profile requires a non-empty
   `sequence_domain_id` and a non-empty `sequence_epoch`; a reference profile carries neither.
2. **Per-record ordering is a tagged object** in the record envelope:

   - sequence mode: `sequence_domain_id`, `sequence_epoch`, `sequence_number`;
   - reference mode: `object_id`, `revision`, `knowledge_time_ns`, `assertion_id`.

   A record carries exactly one mode. **Both modes are not required simultaneously**, and a
   record carrying both key sets fails strict validation. The record's mode and domain/epoch must
   match the artifact profile that contains it.
3. Event time is never a sort key and there is no fallback to event time. No sequence number is
   fabricated; known gaps stay visible. Duplicate keys with conflicting payloads are rejected;
   comparison across unrelated domains is not a semantic claim.
4. **Byte-derived key (critical invariant).** The producer must **parse the canonical record
   bytes**, extract the ordering fields from those parsed bytes, **validate them against the
   artifact profile**, **derive** the ordering key from the validated parsed values, sort by that
   derived key, and then **serialize and emit the same validated canonical bytes**. The verifier
   independently repeats this parse/extract/validate/derive/check sequence from the received
   canonical bytes. **No caller-supplied order key, position, index or pre-sorted hint is trusted
   independently.** A key that does not recompute from the record bytes is rejected on both sides.

## 6. Performed operations and operation evidence

Ratified (DP-02, DP-03, DP-19, DP-25):

1. `performed_operations` is an array of **structured objects**:
   `{operation_ref, action, data_object:{kind,id,version}}`.
   `operation_ref` is a non-empty identifier; `action` is a value from the **approved Fieldbook
   producer action vocabulary** (the 14-value producer `Operation` enum stored as its enum
   value, not a display label); `data_object` names the object `kind`, `id` and `version`. Opaque
   string references are not sufficient and are rejected.
2. `operation_evidence` is a **separate array of typed records** bound by `operation_ref`. Each
   record carries exactly:
   `operation_ref`, `event_id`, `run_id`, `recorded_at_ns` (decimal string per §4),
   `decision_key`, `digest_sha256` (lowercase hex SHA-256).
3. Every performed operation **must resolve exactly one evidence record** by `operation_ref`;
   **duplicates reject**, **missing evidence rejects**, and evidence **cannot be reassigned** to
   a different operation. An evidence record with no matching performed operation rejects.
4. The producer action vocabulary and the consumer action vocabulary remain **separately owned**.
   The Fieldbook 14-value producer enum, the Nirnay five-value consumer enum and the separate
   `create_derived` value are not merged and no producer-to-consumer mapping is implied by a
   wire value. Explicit mapping tables, if any, remain documentation.
5. `producer_activity` keeps its two-member shape (performed operations and operation evidence).
   Purpose, grant, licensee, recipient, verdict and signature are not members of this section.

## 7. Source scope for Profile 1

Ratified (DP-04, DP-05):

1. For NDC v2 Release Serialization Profile 1, `provider_id`, `source_product_id`, `venue_id`,
   `segment_id` and `dataset_id` are **all REQUIRED non-empty valid identifiers**.
2. Empty strings, the literals `UNKNOWN` and `ALL`, placeholders of any kind and `null` are
   rejected in every one of those fields. Each value is validated against the ratified identifier
   grammar; there is no venue, segment, product, provider or dataset default.
3. **Venue-less sources are OUTSIDE Profile 1.** Documents, filings, economic data and any other
   source without a named venue are not admitted under Profile 1. They require a future explicit
   owner decision defining a separate profile with its own scope and coverage rules; nothing in
   this decision weakens venue, rights or coverage rules inside Profile 1.

## 8. Rights evidence (producer) is separate from consumer authorization

Ratified (DP-06, DP-07, DP-08, DP-09):

1. The wire carries **full typed source-rights evidence**, not opaque reference strings. A grant
   record carries at least: immutable **grant identity** (with revision), **granting authority**
   (identity plus evidence reference, distinct from the publisher/signing key and from the
   reviewer), **action**, **object class**, **decision** (`PERMIT` or `DENY` as exact uppercase
   enum values), **actor**, **licensee**, **recipient class and recipient identity**, **purpose
   and scope**, **validity** (named interval with clock domain), **delivery** (method plus
   approved endpoint identities), **retention** (bounded maximum plus purge rule), **supporting
   document references with digests**, **contract revision**, **review authority and review
   date**, and **reviewed attestation** (verbatim purpose, usage right, usage mode, territory,
   scope assertions, reviewer and authority).
2. Document references are typed with clause, lowercase hex document digest, contract revision,
   review authority and review date. Attestations are typed and record review; an attestation is
   not permission for an action absent from a grant.
3. **Producer rights evidence is separate from consumer authorization.** A consumer admission
   request, capability claim, signature, receipt, publication state or lineage chain grants no
   right and cannot substitute for source-rights evidence. Rights evidence remains an independent
   signed section and fails closed when absent.
4. The Proposed consumer-use document is **not** imported as an approved rights contract and is
   not an authority for any grant, purpose, licensee, recipient or retention value.

## 9. Coverage

Ratified (DP-10, DP-11, DP-12, DP-13):

1. Each coverage dimension is one **typed record** carrying:
   `dimension_id`, `universe_id`, `denominator_identity`, `count_basis`, `numerator`,
   `denominator`, `missing_count`, `rejected_count`, `as_of_ns`, `verdict`, `evidence_reference`
   and **typed gaps** (structured gap records, not free strings).
2. `denominator` is **REQUIRED** and non-zero under the ratified numeric rule (§4). There is
   **no PASS without a declared denominator**, declared universe, denominator identity, count
   basis, as-of instant and evidence reference.
3. Counts are **disjoint parts of one denominator**. The default exhaustive arithmetic is
   `accepted (numerator) + missing_count + rejected_count = denominator`. If a dimension uses
   different arithmetic, the **actual arithmetic must be declared and documented** with the
   meaning of every component; an undeclared or overlapping decomposition is rejected. Gaps are
   typed descriptions of the missing/rejected components and are never silently filled,
   interpolated or implied as `ALL`.
4. The nine dimensions are **separate**, each with its own universe, denominator and as-of
   instant. Passing one dimension implies nothing about another; no aggregate percentage
   substitutes for a dimension. `as_of_ns` uses the instant grammar of §4 and is consistent with
   the release as-of.
5. `verdict` uses a closed vocabulary. A producer-supplied `PASS` **does not promote the
   verdict**: it is admitted only when all required evidence is present and the independent
   semantic evaluation agrees. Otherwise the dimension fails closed.

## 10. Lineage and corrections

Ratified (DP-14, DP-15, DP-16, DP-17):

1. Lineage is a **single typed structure** carrying: raw archive reference plus digest,
   transformation identity plus version, knowledge time, current revision, `wasDerivedFrom`,
   `wasRevisionOf`, `hadPrimarySource`, `generatedAtTime`, `invalidatedAtTime` (canonical UTC
   string, below) and qualified attribution. PROV relations are typed, not opaque strings, and
   name sources and activities; they establish neither permission nor truth.
2. **`lineage.revision` is the current release revision.
   `lineage.supersedes.revision` is the IMMEDIATE PREDECESSOR revision**, strictly less than the
   current revision; chain traversal decrements by one. An initial release has no predecessor; a
   corrected release has one immediate predecessor in Profile 1. The relation maps to PROV
   `wasRevisionOf`. Event-level correction lineage remains separate and is not merged into the
   release-level `supersedes`.
3. `supersedes` is one seven-member relation (`supersedes_release_id`,
   `supersedes_manifest_sha256`, `supersedes_data_sha256`, `revision`, `correction_reason`,
   `knowledge_time_ns`, `invalidated_at_time`). An array form is permitted only for a genuine
   multi-predecessor release, which Profile 1 does not model.
4. **`invalidated_at_time` is a canonical UTC string**, not an opaque string and not an integer
   nanosecond value. Explicit grammar and precision: RFC 3339 profile restricted to the UTC
   designator `Z`, form `YYYY-MM-DDTHH:MM:SS.fffffffffZ` with **exactly nine fractional digits**
   (nanosecond precision), proleptic Gregorian calendar, no offset form and no leap second;
   the decoded value must be a valid calendar instant. Neither Rust string type is normative.
5. Reject **cycles, missing predecessors, revision regression**, self-reference, mismatched
   release identity, future knowledge time and a release supplying its own predecessor. Both
   producer and verifier perform the validation independently and fail on first breach.

## 11. Compression version

Ratified (DP-19):

1. `compression_version` is a **REGISTERED STRING identifier**, not a bare integer and not a
   free-form string. It names the exact codec family, codec version and decoding semantics and
   is registered with a digest in the versioned schema package (§12).
2. Each artifact descriptor binds the compression **method**, the applicable **profile**, the
   registered **codec version identifier** and the **decoding semantics** together. A registered
   combination is decoded only by its declared semantics; no inference from magic bytes or file
   extension is allowed.
3. The verifier admits **only registered profiles**, and rejects an unknown method, profile or
   version identifier. Compression changes stored bytes and stored digest only; the dataset
   digest remains over the uncompressed canonical record streams in canonical artifact order
   (Profile 1 Decision D).

## 12. Five additional owner decisions

Ratified explicitly, resolving the remaining directed points:

1. **One authoritative `contract_version` location (formal requirements amendment).**
   `contract_version` appears exactly once, at the manifest root. The nested duplicate
   `schema_versions.contract_version` is removed from the canonical wire schema; a release
   carrying it fails strict validation. This is a **formal amendment to the requirements**, to be
   carried into a separate dated revision document with its own digest before implementation;
   no approved D1 or D2 byte is edited or re-digested by this decision. (DP-23)
2. **`payload_schema_version` — versioned payload schema registry.** Profile 1 uses a
   **VERSIONED PAYLOAD SCHEMA REGISTRY** that declares an explicit identity and version (and
   registered digest) **per event type**. A single manifest-wide scalar and a silent positional
   array are both rejected; an event type with no registered payload schema entry fails closed.
   (DP-24)
3. **Supersedes revision = immediate predecessor.** As recorded in §10.2. (DP-15/DP-16)
4. **Consumer rights are separate from producer rights evidence.** As recorded in §8.3–§8.4.
5. **Venue-less sources are outside Profile 1.** As recorded in §7.3.

## 13. Canonical schema package

Ratified scope of the B8 package (this decision does not create it):

1. A **versioned canonical schema package** containing: the manifest JSON Schema; the detached
   sidecar schema; the record-envelope schema; per-event-type payload schemas; ordering-profile
   definitions; the typed rights, coverage and lineage schemas; explicit **semantic constraints**;
   the **canonical test vectors**; and exactly **ONE package digest** over the complete package.
2. Schemas are **strict**: `additionalProperties:false`, explicit `required` arrays and tagged
   unions for every discriminated structure (ordering mode, verdict/decision enums, PROV
   relations, operation/evidence records). No optional-by-omission field and no implicit default.
3. **Structural validation alone is NOT sufficient.** Every semantic invariant in §§3–12 is
   validated explicitly by an independent implementation and is covered by a canonical test
   vector that exercises both acceptance and rejection. A schema that merely compiles, or a
   vector that merely parses, is not conformance.
4. The **schema is shared; validator implementations are not**. Both repositories map to the
   same canonical schema and vectors but keep independent parsers, validators, serializers and
   digest code. No shared runtime crate is introduced.

## 14. Compatibility and evolution

Ratified:

1. Unknown fields reject; missing required fields reject; incorrect JSON types reject; no
   implicit coercions; no unversioned extensions. Evolution is by explicit new registered schema
   version with its own digest; an unregistered version fails closed.
2. All D0, D1, D1-amendment and D2 approved digests and the separate consumer-use **Proposed**
   status are preserved exactly (§2).
3. This decision **supersedes neither approved semantics nor the freeze**. Where a ratified
   Profile 1 rule already exists, it remains in force; this decision supplies the canonical wire
   representation and the additional resolutions above, not a replacement for approved meaning.
4. Producer and verifier must remain independent and in lockstep against the same versioned
   schema and vectors. No wire-compatibility claim may be made before paired cross-execution
   against the B8 package.

## 15. Disposition of DP-01..DP-30

All thirty owner decision points of the reconciliation record are resolved by this decision as
follows; the reconciliation's PROPOSED status and historical text are unchanged.

| DP | Subject | Ratified resolution | Section |
|---|---|---|---|
| DP-01 | Instant representation | Decimal strings matching `^(0\|[1-9][0-9]*)$`, `u64` range, nanoseconds UTC; no coercion | §4.1 |
| DP-02 | Performed-operation representation | Structured `{operation_ref, action, data_object{kind,id,version}}` objects | §6.1 |
| DP-03 | Operation evidence binding | Separate typed evidence bound by `operation_ref`; duplicates/missing/reassignment reject | §6.2–§6.3 |
| DP-04 | Venue requirement | Required non-empty venue for Profile 1; `null`/placeholders reject | §7.1–§7.2 |
| DP-05 | Venue-less sources | Outside Profile 1; future explicit profile required | §7.3 |
| DP-06 | Structured rights evidence | Full typed source-rights evidence; opaque refs insufficient | §8.1 |
| DP-07 | Granting authority | Typed granting authority, distinct from signer and reviewer | §8.1 |
| DP-08 | Document references | Typed reference, clause, lowercase hex digest, contract revision, review authority/date | §8.2 |
| DP-09 | Attestations | Typed attestation with verbatim purpose, reviewer and authority | §8.2 |
| DP-10 | Coverage dimension structure | One typed dimension with all named members and typed gaps | §9.1 |
| DP-11 | Required denominator | Required, non-zero; no PASS without denominator | §9.2 |
| DP-12 | Coverage arithmetic | Disjoint/exhaustive `accepted+missing+rejected=denominator` or documented actual arithmetic | §9.3 |
| DP-13 | Verdict vocabulary | Closed vocabulary; producer PASS does not promote verdict | §9.5 |
| DP-14 | PROV lineage completeness | Single typed structure with the full PROV relation set | §10.1 |
| DP-15 | Revision semantics | Current vs immediate-predecessor revision | §10.2 |
| DP-16 | Supersedes member names | One seven-member relation; array only for genuine multi-predecessor | §10.3 |
| DP-17 | Invalidation time grammar | Canonical UTC string, exactly nine fractional digits, explicit `Z` grammar | §10.4 |
| DP-18 | Record-order profile representation | Tagged object at artifact level; closed `kind` set | §5.1 |
| DP-19 | Compression version representation | Registered string identifier binding method/profile/codec/decoding semantics | §11 |
| DP-20 | Byte-derived ordering key | Derive from parsed canonical bytes; no trusted caller-supplied key | §5.4 |
| DP-21 | Record mode exclusivity and gap policy | Tagged record union; no both-mode record; fixed gap policy | §5.2–§5.3 |
| DP-22 | Numeric range rule | Integer below 2^53 or decimal string for full u64; no float for financial quantities | §4.2–§4.3 |
| DP-23 | Duplicate contract version | One authoritative root location; formal requirements amendment | §12.1 |
| DP-24 | Payload schema version | Versioned per-event-type payload schema registry, not a silent array | §12.2 |
| DP-25 | Operation vocabulary separation | Producer 14-value enum and consumer five-value + `create_derived` remain separate | §6.4 |
| DP-26 | Strict schema and defaults | Strict parsing, explicit version, no unknown/default/coercion | §3 |
| DP-27 | Trusted key registry interface | Typed registry-entry schema in the versioned package; out-of-band trust; injected test keys only, no production key | §13, Profile 1 Decision H |
| DP-28 | Resource policy maxima | Profile 1 Decision F preserved; maxima deferred to workload qualification; no number adopted | §14.3 |
| DP-29 | Receipt wire form | Producer publication receipt and consumer admission receipt stay separate; any wire form requires an explicit versioned schema entry; none created here | §13, §16 |
| DP-30 | Schema artifact and cross-execution | Package requirements and one digest ratified; artifact is B8; cross-execution remains NOT_STARTED and unclaimed | §13, §16 |

## 16. Non-claims, freeze and status vocabulary

1. This decision creates **no** schema artifact, serializer, verifier, connector, registry entry
   instantiation, release, dataset, admission receipt, key (no production key generated or
   activated), right, provider contact, market observation, collection, India implementation or
   experiment. It edits no approved byte and changes no historical digest.
2. **Freeze unchanged:** rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection
   `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict. Wire compatibility,
   cross-execution and a standalone published schema artifact remain **NOT_STARTED** until the B8
   package and paired cross-execution work exist.
3. For later cross-execution reporting these statuses are **distinct and must not be collapsed**:

   - `SCHEMA_CONFORMANT` — canonical schema and vectors exist and a representation passes them;
   - `CROSS_EXECUTED` — a producer-generated release has been processed by the independent
     verifier across the agreed boundary;
   - `CRYPTOGRAPHICALLY_VERIFIED` — signature and digests verified with an out-of-band trusted
     key;
   - `RIGHTS_ADMITTED` — source-rights evidence and consumer authorization independently
     admitted;
   - `DATASET_ACCEPTED` — the dataset has passed the separate owner acceptance gate.

   **None of these statuses is claimed, promoted or implied by this decision.** In particular,
   schema conformance is not cryptographic verification, cryptographic verification is not a
   right, and a right is not dataset acceptance.

## 17. Registry effects

`NDC-REGISTRY.md`, `ADR-REGISTRY.md`, `engineering/evidence/REVIEW-LOG.md`, the README document map and a pointer in
`engineering/conformance/ndc-v2-wire-contract-reconciliation.md` are updated to register this
decision and the DP-01..DP-30 resolution. Historical ADRs are not renumbered, no approved byte is
rewritten, and no historical digest is changed.
