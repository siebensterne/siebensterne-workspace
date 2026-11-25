# B15 — Bounded streaming Fieldbook producer lifecycle (design)

> **CURRENT STATUS: DESIGN HISTORY.** Architecture ratified by WS-STREAM-001; implementation closed in Phase 3A. Numeric maxima remain deferred.

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **PROPOSED / AWAITING OWNER APPROVAL**. This is a design package, not a ratification.
No implementation, schema, resource maximum, profile identifier, right, dataset, release,
key, provider authority, India artefact or experiment is approved by this document. No
implementation state is promoted.

Ratification pointer (2026-11-25): `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md`
ratifies the B15/B16 architecture and interface contracts. All numeric resource maxima remain
DEFERRED; this design keeps its PROPOSED status.

### Current-status notice (2026-11-25, WS-DOC-001)

- **Ratified:** the architecture and interface contracts selected by `WS-STREAM-001` —
  A-01..A-12, covering both this producer design and B16 — were **RATIFIED by owner direction on
  2026-11-25**, at contract level only. Decision digest (`shasum -a 256`):
  `f74153024c1d526fe5c9d49b22e541263581c52c0dbae19a67e8d2ea841a4fe1`. See
  `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md` §1. This notice does
  not claim an implemented, tested or verified state.
- **Proposal history:** this document remains **PROPOSED / AWAITING OWNER APPROVAL**. Its original
  §§1–10 are retained unchanged as proposal history; a pointer to a ratification does not convert
  a design package into an implementation, profile approval or qualification record. Where a
  proposal differs from a ratified decision, the ratified decision governs (Appendix A).
- **Deferred and not approved:** every numeric resource maximum in §6.2, the codec identifier and
  all concurrency, throughput and CPU numbers remain **DEFERRED**; no deferred item is a silent
  default. The normative `ResourceProfile` contract is role-specific (`PRODUCER`, `VERIFIER`,
  `RECOVERY`, `SNAPSHOT`), but **no profile value or profile digest is approved** by
  `WS-STREAM-001`; `STREAM_RESOURCE_PROFILE_RATIFIED` is PENDING. A production invocation without
  an approved role profile selected by trusted local policy fails closed.
- **Blocked:** `PERF_001_QUALIFIED` and `OPERATIONALLY_QUALIFIED` remain **BLOCKED**;
  `PUBLICATION_DURABILITY_VERIFIED` remains `false`; rights `UNKNOWN`, dataset acceptance
  `BLOCKED`, budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`
  and D11 strict. The freeze is unchanged.
- **Evidence pointers:** the merged Phase 3 implementation and cross-execution evidence is
  `engineering/conformance/phase-3-acceptance-2026-11-25.md` (FB `8216197` / NZ `c1c2f0d`, finite
  explicitly marked `TEST_ONLY` profiles, `STREAMING_IMPLEMENTATION_COMPLETE`, not `Verified`).
  Phase 3A implementation/evidence records are tracked by their work-package identifiers listed in
  Appendix A and in the `engineering/evidence/REVIEW-LOG.md` entry dated 2026-11-25; this notice carries pointers only
  and claims no merge, commit, gate result or capability change for any work package that has not
  been recorded by the parent.
- **Receipts and CI:** `NDC-RECEIPT-001` remains explicitly **PROPOSED / AWAITING OWNER
  RATIFICATION**; the Fieldbook publication receipt and the Nirnay admission receipt remain
  separate objects (A-12), and neither is created from the other. Workspace hosted CI remains
  `NOT_RUN`.

Scope: documentation only. The worktree is `docs/b15-streaming-producer-design` on workspace
base `95580f5`. No source file, schema file, right record, data file, provider record, India
record, experiment, release, key, dataset or CI configuration was changed. No commit was
created.

Source baseline inspected read-only: Fieldbook `fd4b542`, specifically
`src/distribution/ndc_release.rs` and `src/distribution/ndc_wire.rs`. Authorities read alongside
the source: ratified NDC v2 Release Serialization Profile 1
(`engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md`,
the nine ratified decisions), the canonical wire-schema ratification
(`engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md`), the B8
schema package and vectors (`engineering/conformance/ndc-v2-schema-profile-1/`), the profile-1
digest registration (`engineering/conformance/ndc-v2-schema-digest.json`) and the ratified
publication failure model (`engineering/decisions/WS-DUR-001-publication-durability-failure-model.md`).
B15 is the producer-side P1 work item recorded in
`engineering/conformance/ndc-v2-evidence-audit-2026-11-24.md`; B16 is the separate verifier-side
package and is not specified here. PERF-001 resource evidence is a separate package and is not
claimed by this design.

## 1. Problem: whole-artifact materialization

### 1.1 Source facts at Fieldbook `fd4b542`

| Source location | Observed contract | Consequence |
|---|---|---|
| `ndc_release.rs:748-765`, `ArtifactInput.records: Vec<CanonicalRecord>` | Caller supplies all records of one artifact in memory. | Input footprint grows with record count. |
| `ndc_release.rs:2284-2378`, `validate_record_order(&[CanonicalRecord])` | Parses every record and keeps scalar predecessor state; no record buffer is reused from a stream. | Validation can scan an artifact held in memory, but the artifact must already exist. |
| `ndc_release.rs:2471-2481` | `uncompressed.extend_from_slice(&record.bytes)` and one appended `b'\n'` build a whole artifact `Vec<u8>`. | A second full copy of the artifact is materialized. |
| `ndc_release.rs:2388-2404`, `compress_stream(&[u8], ArtifactCompression) -> Vec<u8>` | `GzEncoder::new(Vec::new(), GzipCompression::default())` writes the full uncompressed slice and returns a full `Vec<u8>`. | A third full copy (stored form) is materialized. |
| `ndc_release.rs:2406-2417`, `PreparedArtifact.stored: Vec<u8>` and `PreparedRelease.artifacts: Vec<(String, Vec<u8>)>` | Stored artifact bytes are retained per artifact and for the whole release. | Peak allocation includes input records, uncompressed bytes and stored bytes at the same time. |
| `ndc_wire.rs:1313-1352`, `sort_byte_derived` | Builds `Vec<(WireOrderKey, Vec<u8>, String)>` and sorts it in memory. | Byte-derived ordering currently requires a record-count-proportional collection. |
| `ndc_release.rs:624-641`, `ResourcePolicy` | All numeric maxima are caller-supplied. | Bounds exist, but a bounded in-memory implementation is not a streaming implementation. |
| `ndc_release.rs:2806-2816`, `resource_profile_id` | A digest over caller-supplied maxima identifies the selected policy. | A digest does not qualify the maxima or prove a workload measurement. |

The audit finding at `ndc-v2-evidence-audit-2026-11-24.md` finding 10 remains accurate at this
commit: artifacts are processed wholly in memory, and the bounded maxima do not convert the
path into a streaming path.

### 1.2 Bounded memory is not streaming

- **Bounded memory** is a property of allocation: every allocation is limited by an enforced
  profile maximum. The current path has caller-supplied maxima, so its worst case is bounded
  for a fixed policy. Repetition of an artifact increases time, not that bound.
- **Streaming** is a property of data flow: records are consumed one at a time, transformed and
  emitted incrementally, and no buffer is sized by the total record count or total artifact
  byte count of the release.
- A design qualifies for the streaming claim only when both properties hold. A caller who sets
  a high `max_records_per_artifact` still obtains bounded memory, but a non-streaming
  implementation keeps all records of one artifact resident. That state is recorded as
  `BOUNDED_IN_MEMORY`, never as `STREAMING`.

### 1.3 Goal and non-goals

Goal: a producer path whose resident memory is independent of total artifact size and record
count for a fixed resource profile and fixed artifact count, with an immutable two-intent
publication lifecycle and byte-identical output for the existing Profile 1 conformance vectors.

Non-goals: no verifier change (B16), no dataset acceptance, no rights decision, no provider
contact, no market observation, no new wire field, no new digest framing, no shared runtime
crate with Nirnay, and no promotion of `OPERATIONALLY_QUALIFIED`.

## 2. Bounded record-source API (proposed)

### 2.1 `ArtifactPlan`

One `ArtifactPlan` describes one artifact before any source is opened. The plan is fixed for
one operation and is bound into the PreparationIntent.

| Field (proposed) | Meaning |
|---|---|
| `logical_partition_id`, `shard_ordinal` | Canonical artifact-order key; unique within the operation. |
| `path` | Release-relative artifact path, validated by the existing path rules. |
| `record_order_profile` | Declared Profile 1 tagged profile: sequenced domain/epoch or reference. |
| `encoding` | `ndjson` only under Profile 1. |
| `compression`, `compression_profile_id` | Declared registered compression method and version literal. |
| `source_snapshot_id`, `source_revision` | Opaque identity of the source snapshot; no rights or truth claim. |
| `replayability` | `REPLAYABLE` or `NON_REPLAYABLE`. |
| `source_content_digest` | Digest commitment over canonical bytes in declared emission order, used for replay proof. |
| `expected_record_count`, `first_order_key`, `last_order_key` | Additional replay-proof commitments; gaps remain visible. |

Artifact plans are ordered by `(logical_partition_id, shard_ordinal)` before emission. That is a
collection of bounded size (artifact count is a resource-profile maximum). No record collection
is built.

### 2.2 `ArtifactRecordSource` contract

The following signatures are documentation of a proposed Rust API contract; no source file is
created or changed by this design.

```rust
/// One canonical record byte line without a line terminator.
pub struct CanonicalRecord {
    pub bytes: Vec<u8>,
}

/// Declaration of whether identical input can be reproduced after a restart.
pub enum Replayability {
    REPLAYABLE,
    NON_REPLAYABLE,
}

/// Bounded, one-record-at-a-time source for one planned artifact.
pub trait ArtifactRecordSource {
    /// Opaque snapshot identity and revision; must equal the plan values.
    fn source_identity(&self) -> SourceIdentity;
    /// Declaration checked against the plan; a weaker declaration fails closed.
    fn replayability(&self) -> Replayability;
    /// Next validated canonical record, or `None` at end of stream.
    fn next_record(&mut self) -> Result<Option<CanonicalRecord>, ProducerError>;
    /// Profile maximum used by the bounded framer; never a caller hint.
    fn max_record_bytes(&self) -> u64;
}
```

Semantics of `next_record`:

1. The method returns one owned record buffer. The caller drops that buffer before requesting
   the next record, so resident record memory is one record per active artifact source.
2. `Ok(None)` is the explicit end-of-stream signal. After `Ok(None)`, any further call fails
   with a typed state error; a record is not silently skipped after end-of-stream.
3. A source must not expose a whole-artifact slice, an iterator requiring a collected vector,
   or a caller-supplied order key. `CanonicalRecord` carries bytes only, as at Fieldbook
   `fd4b542`.
4. `source_identity()` reports the snapshot opened for the operation. A mismatch against the
   plan is a typed source mismatch before any record is consumed.
5. A source that declares `REPLAYABLE` must be backed by an immutable snapshot; reopening a
   mutable path is not a replayable declaration. The proof rule is in §4.5.

### 2.3 Bounded framer

A source backed by bytes uses a bounded framer, not an unbounded line read.

- Read through a `Read::take(max_record_bytes + 1)` view or a fixed-size buffer with an explicit
  remaining-byte counter. An LF terminator ends the record; reaching the byte bound first is a
  typed `PolicyExceeded`. A bare `read_until(b'\n', &mut Vec::new())` with no bound is prohibited.
- Reject an empty record, a UTF-8 BOM, an embedded LF or CR, a NUL byte, invalid UTF-8 and bytes
  that differ from RFC 8785 canonical form, using the same rules as `validate_record` at
  `fd4b542`.
- Reject a trailing incomplete record at end-of-stream. The producer appends exactly one LF
  after each accepted record; the source bytes do not contain that LF.
- Reuse one record buffer per source where the API permits; no buffer is sized from a declared
  total artifact size.

### 2.4 Ordering: derived from bytes, checked incrementally

Profile 1 Decision B and WS-NDC-2026-11-24-003 §5.4 require a key derived from parsed canonical
record bytes. The streaming path preserves that rule without calling `sort_byte_derived`:

1. Call `parse_canonical_record` on the record buffer and `derive_order_key` with the artifact's
   mapped wire profile, as in `ndc_wire.rs:1009` and `:1270`.
2. Compare the derived key with the artifact's declared domain and epoch. A mismatch is typed
   `InvalidRecordOrder` with reason `sequence domain or epoch mismatch`.
3. Compare with the previous derived key. A duplicate or a decrease is typed
   `InvalidRecordOrder` with reason `duplicate sequence position` or
   `sequence position moved backwards`. Reference-profile artifacts use the corresponding
   reference-key comparison.
4. Emit the same validated canonical bytes. No re-serialization, event-time fallback,
   fabricated sequence number, cross-domain comparison or caller-supplied position is used.
5. Under Profile 1 an unordered source is rejected; the producer does not buffer and sort
   records to repair the order. The only permitted sort is the bounded artifact-plan sort.

The existing batch API already rejects decreasing and duplicate sequenced positions in
`validate_record_order`. The streaming path keeps that strictness so that accepted inputs and
their bytes do not change. Allowing equal keys would require a profile amendment and a declared
stable tie-break rule.

## 3. Producer pipeline

The pipeline operates on one artifact at a time. Artifact count is bounded by the resource
profile; per-artifact state is fixed-size.

```text
ArtifactPlan (bounded list)
  -> PreparationIntent durable in ledger
  -> per-artifact: bounded source -> parse/validate -> byte-derived order check
       -> incremental stream state -> staging file -> file sync
  -> manifest + sidecar creation -> SealedPublicationIntent durable in ledger
  -> staging tree validation -> atomic no-replace rename -> parent sync
  -> receipt durable -> availability marker durable -> AVAILABLE
```

### 3.1 Incremental stream state

For each artifact the producer keeps, in fixed-size state:

- one expanded SHA-256 hasher over every canonical record byte and its single appended LF;
- one stored SHA-256 hasher over compressed bytes as they are emitted, or over the same bytes
  for `compression = none`;
- one `record_count`, one `uncompressed_bytes` counter and one `stored_bytes` counter, each
  checked against the profile maximum on every update using checked arithmetic;
- one byte-derived order-key predecessor, first key and last key for the replay proof;
- one set of observed event-type identifiers, bounded by a profile maximum;
- one compressor instance with a fixed window; no whole-artifact output vector.

The dataset SHA-256 hasher is updated with each expanded record and LF in canonical artifact
order. Its state is one digest accumulator, independent of release size.

### 3.2 Streaming compression and deterministic gzip profile

- `compression = none/1` writes the expanded stream unchanged.
- `compression = gzip-deflate/flate2-1` uses the same `flate2::write::GzEncoder` and
  `GzipCompression::default()` settings as `compress_stream` at `fd4b542`. Records are written
  incrementally with `write_all`; `finish()` is called once at end-of-stream. No intermediate
  flush changes the deflate block boundaries.
- The gzip header carries no timestamp, file name or comment that varies between runs; the
  trailer carries CRC-32 and ISIZE from the emitted bytes. The registered version literal
  binds method, profile and decoding semantics; bytes are never classified by byte patterns or
  file extension.
- For any record sequence accepted by the current path, the streaming compressor output MUST
  be byte-identical to `compress_stream`. The existing gzip determinism test at
  `ndc_release.rs:6549` and the conformance vectors are the acceptance set.

### 3.3 Staging writes, sync and descriptor creation

- Artifact bytes are written to release-relative paths under an exclusive sibling staging
  directory on the same filesystem as the final release directory, as required by Profile 1
  Decision G and WS-DUR-001 §3.
- Every regular file is synced after its final byte; the `artifacts/` child directory and the
  staging directory are synced after all files. A failed sync is a typed error, never a warning.
- An `ArtifactDescriptor` is created from the incremental state after end-of-stream: path,
  declared profiles, `stored_bytes`, `stored_sha256`, `uncompressed_bytes`,
  `uncompressed_sha256` and `record_count`. Manifest bytes and the detached sidecar are then
  built from the ordered descriptor list.
- Memory for descriptors is proportional to artifact count, not to record count or artifact
  bytes. For a fixed profile and artifact count, resident memory does not grow when record
  count or artifact size increases.

## 4. Critical lifecycle: two intents

### 4.1 PreparationIntent — written before source consumption

The PreparationIntent is an immutable, canonical, self-digested ledger record committed with a
ledger-directory sync before any staging tree or release-root mutation. It declares the
operation's inputs and the rules by which those inputs may be reproduced.

| Field (proposed) | Meaning |
|---|---|
| `schema_version`, `operation_id` | Intent layout version and unique operation identity. |
| `source_plan` | Complete ordered `ArtifactPlan` list with planned staging and final paths. |
| `source_snapshot_id`, `source_revision` per plan item | Identity of the input snapshot opened for the operation. |
| `replayability` per plan item | `REPLAYABLE` or `NON_REPLAYABLE` declaration. |
| `resource_profile_id`, `resource_profile_digest`, `caller_policy_digest` | Selected versioned profile plus the caller-supplied policy identity. |
| `wire_profile_id`, `ordering_profile_id`, `compression_profile_id` | Registered Profile 1 wire, ordering and compression literals. |
| `planned_paths` | Exact planned release-relative file set; no undeclared file is written. |
| `source_content_digest`, `expected_record_count`, `first_order_key`, `last_order_key` per plan item | Commitment used to prove identical input on replay. |
| `spool_plan` | For non-replayable sources: planned spool paths and digest rule. |
| `intent_sha256` | SHA-256 of canonical bytes with this member excluded. |

A PreparationIntent alone grants no publication right. It is recovery evidence for what the
operation intended to read, not evidence that a release is complete.

### 4.2 SealedPublicationIntent — written after all artifacts are complete

The SealedPublicationIntent is an immutable, canonical, self-digested ledger record committed
with a ledger-directory sync after every artifact stream has reached end-of-stream, every
staged file is synced and the manifest and sidecar bytes exist. It is the seal that authorises
the publication transition.

| Field (proposed) | Meaning |
|---|---|
| `schema_version`, `operation_id` | Intent layout version and the same operation identity as the PreparationIntent. |
| `preparation_intent_sha256` | Chain to the exact preparation record. |
| `manifest_sha256` | Digest of the complete canonical manifest bytes. |
| `sidecar_sha256` | Digest of the exact detached sidecar bytes. |
| `data_sha256` | Dataset digest over ordered uncompressed artifact streams. |
| `artifact_inventory` | Full ordered descriptor list with stored and expanded digests. |
| `stored_counts`, `expanded_counts` | Per-artifact and total byte counts and record counts. |
| `expected_receipt`, `expected_receipt_sha256` | Complete expected publication receipt and its digest. |
| `wire_profile_id`, `resource_profile_id` | Final registered profile identifiers. |
| `intent_sha256` | SHA-256 of canonical bytes with this member excluded. |

The seal boundary is the ledger sync of the SealedPublicationIntent. No receipt, availability
marker or final release name exists before that boundary.

### 4.3 State sequence and crash rule

```text
OPERATION_INTENT_DURABLE (PreparationIntent)
  -> SOURCE_SEALED / streaming consumption
  -> STAGING_ENTRY_DURABLE
  -> STAGING_TREE_DURABLE
  -> SEALED_PUBLICATION_INTENT_DURABLE (SealedPublicationIntent)
  -> RENAME_DURABLE
  -> PUBLICATION_RECEIPT_DURABLE
  -> AVAILABLE
```

New stage literals above are proposed ledger evidence labels; the durable stages shared with
WS-DUR-001 keep their ratified acknowledgement semantics. A crash or cancellation before the
seal leaves no SealedPublicationIntent. In that case the operation is **never AVAILABLE**:
recovery writes no receipt and no availability marker, does not rename a staging directory to
a final release name, and reports quarantine or no evidence. A PreparationIntent is not a
substitute for a seal. A crash between rename and parent-directory sync remains the ratified
uncertain-publication case; the final directory is reconciled or quarantined from durable
evidence, never adopted from caller memory or directory presence.

### 4.4 Sealed-intent recovery

After the seal, recovery requires a SealedPublicationIntent whose `preparation_intent_sha256`
matches the stored PreparationIntent and whose digests match the staged bytes:

1. If a final directory exists, verify its exact file set and every byte digest against the
   sealed inventory and receipt before completing receipt or marker stages.
2. If only a staging tree exists, verify the tree against the sealed inventory, then continue
   the ratified publication stages. A partial tree is not completed by rewriting files.
3. If no verified tree exists but the source is replayable and reproduces the PreparationIntent
   commitments, the artifact streams may be rebuilt into a new staging tree for the same
   operation; the rebuilt streams must match the sealed digests on recomputation.
4. If no verified tree and no replay proof exist, quarantine. No receipt or marker is written.

### 4.5 Replay rules for replayable sources

Reopening a mutable source path is not proof of identical input. A replayable source is
accepted only when all of the following match the PreparationIntent:

1. `source_snapshot_id` and `source_revision` reported by the reopened source;
2. `source_content_digest` recomputed incrementally over canonical bytes in emitted order;
3. `expected_record_count`, `first_order_key` and `last_order_key`, with monotonic derived keys
   rechecked record by record;
4. per-artifact and total stored and expanded digests after the replayed stream is compressed
   with the sealed compression profile;
5. `resource_profile_id` and the wire, ordering and compression profile literals.

Any difference is typed `SourceReplayMismatch`, stops the operation before any availability
stage, and leaves the operation quarantined with no receipt and no marker. A source whose
identity matches but whose bytes differ is a mismatch; a source whose snapshot identity cannot
be checked is not replayable for this operation.

### 4.6 Quarantine and spool rules for non-replayable sources

A non-replayable source is admitted only through a durable spool:

1. Before the first artifact is consumed, the spool plan is bound in the PreparationIntent.
2. Records are framed, validated and written once to operation-scoped spool files under the
   resource-profile temp-disk bound. The spool writer uses the same incremental expanded digest
   and order-key checks as the staging writer.
3. On spool end-of-stream, a `SPOOL_SEALED` ledger record carrying spool byte digests, counts and
   order keys is committed with a ledger-directory sync. This record is evidence, not a third
   intent. The spool then becomes the immutable source for the pipeline.
4. A crash or cancellation before `SPOOL_SEALED` leaves no usable spool. Recovery quarantines;
   it does not adopt a partial spool.
5. After `SPOOL_SEALED`, recovery may re-drive the pipeline only from a spool whose bytes
   recompute the sealed digests. A truncated or differing spool is quarantined.
6. Spool retention and purge require an owner decision under the rights policy. Until then a
   quarantined spool is retained with its evidence and is not replayed into a new release.

## 5. Digest compatibility

1. `data_sha256 = SHA256(B1 || B2 || ... || Bn)` remains unchanged, where `Bi` is the exact
   uncompressed canonical record stream of artifact `i` in canonical artifact order and each
   record contributes its bytes plus one LF. The digest is independent of compression, as in
   Profile 1 Decision D and the test at `ndc_release.rs:6502`.
2. `stored_sha256` is over stored bytes; `uncompressed_sha256` is over expanded bytes. Both are
   computed incrementally over the same bytes as the current path.
3. Manifest JCS bytes, the complete-manifest signing domain
   `NDC-V2-RELEASE-MANIFEST-SHA256-V1 || 0x00 || SHA256(manifest)`, the five-member sidecar and
   the expected receipt are unchanged. No new framing, domain separator, record prefix,
   artifact prefix or digest input is introduced without a profile amendment.
4. `sort_byte_derived` at `ndc_wire.rs:1313` remains a batch compatibility helper. The streaming
   path does not call it and does not alter its output.
5. Existing conformance vectors in `engineering/conformance/ndc-v2-conformance-vectors/` and the
   B8 package must produce byte-identical manifest, sidecar, stored artifact and receipt bytes
   for the same accepted input. A change in any of those bytes is a compatibility failure, not a
   new profile version.

## 6. Versioned resource profile

### 6.1 Approval rule

A versioned resource profile is proposed with identifier `STREAM-RES-1` and a digest to be
registered after owner approval. Concrete numeric maxima MUST be approved by the owner in that
profile before any streaming qualification run, RSS plateau measurement or `STREAMING`
capability claim. The caller-supplied `ResourcePolicy` digest at `ndc_release.rs:2806`
identifies the selected policy; it does not qualify the maxima, prove workload measurement or
turn a proposal into an approved limit. Profile 1 Decision F remains in force: unapproved
numbers are not normative limits.

### 6.2 Required limits

The numbers below are **proposals for owner review, NOT APPROVED and NOT normative**. They are
stated concretely so that approval can be recorded as an explicit accept or replace decision.
They derive from no market workload measurement and carry no performance claim.

| Limit | Proposed numeric value | Proposal note |
|---|---|---|
| `max_record_bytes` | 65,536 bytes | One framed record buffer; replaces no existing caller bound. |
| `max_records_per_artifact` | 1,000,000 records | Checked per record; no collection of this size is allocated. |
| `max_artifact_count` | 128 artifacts | Bounds plan, descriptor and file-set collections. |
| `max_stored_bytes_per_artifact` | 536,870,912 bytes (512 MiB) | Checked while stored bytes are emitted. |
| `max_expanded_bytes_per_artifact` | 1,073,741,824 bytes (1 GiB) | Checked while expanded bytes are emitted. |
| `max_total_stored_bytes` | 4,294,967,296 bytes (4 GiB) | Checked across artifacts. |
| `max_total_expanded_bytes` | 8,589,934,592 bytes (8 GiB) | Checked across artifacts. |
| `compression_window_bytes` | 32,768 bytes | Matches the registered flate2 default window; verify at implementation. |
| `parser_memory_bytes` | 4,194,304 bytes per parser | Bounds canonical JSON working state for one record. |
| `queue_capacity_records` | 64 records | Fixed queue; no queue sized from record count. |
| `concurrent_writers` | 1 per operation | One staged artifact stream active at a time. |
| `temp_disk_bytes` | 17,179,869,184 bytes (16 GiB) | Includes spool and staging for one operation. |
| `process_memory_bytes` | 268,435,456 bytes (256 MiB) | RSS ceiling for the PERF-001 qualification harness. |
| `max_manifest_bytes` | 1,048,576 bytes | Retained from the caller policy surface. |
| `max_sidecar_bytes` | 4,096 bytes | Retained from the caller policy surface. |
| `max_path_component_bytes` | 255 bytes | Retained from the existing path validation. |
| `max_nesting_depth` | 32 | Retained from the caller policy surface. |
| `max_object_members` | 256 | Retained from the caller policy surface. |
| `max_array_elements` | 10,000 | Retained from the caller policy surface. |
| `max_file_descriptors` | 32 per operation | Aligns with the consumer-side policy surface. |
| `decompression_budget_bytes` | 8,589,934,592 bytes | Consumer-side counterpart; B16 owns enforcement. |

### 6.3 Qualification sequence

1. Owner accepts or replaces every number and approves the profile digest.
2. The approved profile is registered with a version and digest before implementation claims.
3. Implementation enforces each maximum with checked arithmetic on actual bytes read or
   written, never from an untrusted declared size alone.
4. PERF-001 measures RSS under the approved profile; B16 applies its own maxima independently
   and does not adopt producer-declared maxima.

## 7. Failure matrix

All outcomes are typed. No row writes an availability marker or a receipt unless its
receipt/availability column states otherwise.

| Trigger | Typed outcome | Durable evidence | Receipt / availability |
|---|---|---|---|
| Malformed record (BOM, LF/CR, NUL, invalid UTF-8, non-JCS bytes, empty record) | `InvalidRecord(index, reason)` from the framer or `validate_record` equivalent | PreparationIntent only; staged prefix may exist | No receipt, no marker, no `AVAILABLE`; quarantine partial staging |
| Oversize record | `PolicyExceeded` from the bounded framer at `max_record_bytes + 1` | PreparationIntent only | No receipt, no marker; quarantine partial staging |
| Wrong domain or epoch | `InvalidRecordOrder(path, "sequence domain or epoch mismatch")` from `derive_order_key` | PreparationIntent only | No receipt, no marker; quarantine |
| Duplicate or decreasing sequence (or reference-order regression) | `InvalidRecordOrder(path, "duplicate sequence position" / "sequence position moved backwards")` | PreparationIntent only | No receipt, no marker; quarantine |
| Other profile bound exceeded (count, artifact bytes, totals, queue, disk) | `PolicyExceeded` with the named bound | PreparationIntent only; spool record when applicable | No receipt, no marker; quarantine |
| Compression finalization failure | `Io("finalize gzip stream", source)` before seal | PreparationIntent; incomplete staged artifact | No receipt, no marker; incomplete artifact not adopted |
| Cancellation before seal | `PublicationCancelled` (proposed typed variant) | PreparationIntent; optional spool evidence | No receipt, no marker; staging cleaned or quarantined |
| Cancellation after seal | `CancellationAfterSeal` (proposed typed variant) | SealedPublicationIntent | Sealed operation must complete or be reconciled; no cancellation short circuit to `AVAILABLE` |
| Crash before seal, including before `SPOOL_SEALED` | Recovery outcome `NoEvidence` or `UncertainPublicationQuarantined` | PreparationIntent; no sealed record | Never `AVAILABLE`; no receipt, no marker, no rename adoption |
| Crash after seal, before staged tree verified | Recovery continues from verified tree or replay proof; otherwise `UncertainPublicationQuarantined` | SealedPublicationIntent plus verified tree or replay proof | Receipt and marker only after all ratified barriers |
| Crash after rename, before parent-directory sync | `UncertainPublication` / `UncertainPublicationQuarantined` per WS-DUR-001 §3.6 | Sealed intent and staged/final evidence | Final directory not adopted; no receipt or marker from uncertain state |
| Source identity mismatch on open | `SourceIdentityMismatch` (proposed typed variant) | PreparationIntent | No receipt, no marker; quarantine |
| Source replay mismatch on restart | `SourceReplayMismatch` (proposed typed variant) | PreparationIntent and mismatching replay evidence | No receipt, no marker; quarantine; no new operation id reuse |
| Spool digest mismatch or truncated spool | `SpoolEvidenceMismatch` (proposed typed variant) | `SPOOL_SEALED` record and spool bytes | No receipt, no marker; quarantine spool |
| I/O error on write or sync | `Io(operation, std::io::Error)` | Last durable journal stage only | No successor state, no receipt, no marker; failed sync is never a warning |
| Atomic no-replace rename collision | `PublicationCollision(release_id)` | Sealed intent; final directory owned by another operation | No receipt, no marker for this operation |
| Exact file-set or byte-digest mismatch in recovery | `ArtifactSetMismatch` or `PublicationEvidence` | Sealed inventory and observed tree | No receipt, no marker; quarantine |

## 8. Test plan

No test count, pass state or measurement is claimed before implementation. The plan is binding
for the future B15 implementation package.

1. **No whole-artifact vector.** A source-level structural check and review assert that the
   streaming path contains no `Vec<CanonicalRecord>` input, no whole-artifact `uncompressed`
   or `stored` `Vec<u8>`, no `PreparedRelease.artifacts: Vec<(String, Vec<u8>)>` on the streaming
   path, and no call to `sort_byte_derived` from that path. The batch adapter is the only
   permitted place where caller-owned vectors enter.
2. **No record-count-proportional collection.** A source-level check asserts that per-artifact
   state is scalar or fixed-capacity: hashers, counters, one predecessor key, a bounded queue
   and observed event-type identifiers with a declared bound. Tests with 1, 10 and 10,000
   abstract records exercise the same state shape.
3. **Ordering derived from bytes.** Vectors cover ordered and rejected sequenced streams,
   domain and epoch mismatch, duplicate and decreasing sequence numbers, reference-order
   regression, and both-mode or neither-mode record envelopes. A test supplies a caller order
   hint and confirms it has no effect; the key is recomputed from canonical bytes.
4. **Bounded framer.** Tests cover an oversize record, a record ending exactly at the bound,
   an LF at the bound, a missing LF at end-of-stream, embedded CR or NUL, BOM, non-UTF-8 and
   non-canonical JCS. A reader that returns one byte per call verifies no unbounded line read.
5. **Deterministic output.** Rebuild the existing conformance vectors through the streaming
   path and compare manifest, sidecar, stored artifacts, receipt and dataset digest bytes with
   the current outputs. Include gzip and no-compression artifacts and check gzip byte identity
   across repeated runs.
6. **Two-intent lifecycle.** Tests assert PreparationIntent sync precedes consumption,
   SealedPublicationIntent sync precedes staging-tree validation and rename, a PreparationIntent
   without a seal never yields a receipt or marker, and an invalid `preparation_intent_sha256`
   chain quarantines.
7. **Fault and cancellation.** Inject failure at each durable stage, at gzip finalize, at each
   file sync, at directory sync, at rename, at receipt sync and at marker sync. Restart in a
   fresh process and check the typed outcome from §7, exact file set and absence of unearned
   availability. Include replayable success, replayable mismatch, non-replayable spool success,
   truncated spool and cancellation before and after seal.
8. **RSS plateau (PERF-001 package).** With an approved resource profile, measure process RSS at
   1x, 2x, 4x and 8x record and byte volume using abstract non-market records. Record exact
   commit, profile digest, platform, filesystem, command, peak RSS and the plateau result. No
   number is claimed by this design; a rising trend invalidates the streaming claim and is
   reported as evidence, not converted into a limit change.
9. **Evidence discipline.** Tests use the abstract Profile 1 vectors only. Under D11 no
   synthetic market observation, price bar, order book, trade, provider contact, collection
   command or India data is created. Local static gates are available; the fixture/e2e suite
   stays excluded until its market-shaped inventory is reviewed against owner policy.

## 9. Compatibility

1. The batch API (`ArtifactInput.records: Vec<CanonicalRecord>` and the existing
   `build_release` request shape) is retained only as a compatibility adapter. The adapter
   wraps caller-owned records in an in-memory replayable source and feeds the streaming
   implementation. No second producer implementation is created.
2. No claim is made that the batch API is memory-independent. Its caller already materialized
   the records; the adapter reduces duplication but cannot remove that input footprint.
3. Wire bytes, digests, sidecar shape, receipt shape, artifact layout and publication state
   machine remain Profile 1 compatible. No manifest field is added for streaming, replay or
   resource limits.
4. Fieldbook and Nirnay remain separate implementations. No shared runtime crate, validator,
   serializer, digest routine, connector or ordering library is introduced. The only shared
   artefacts are the ratified schema and canonical vectors.
5. This design does not change rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0,
   collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict,
   `PUBLICATION_DURABILITY_VERIFIED` or `OPERATIONALLY_QUALIFIED`.

## 10. Migration and open decisions

### 10.1 Migration sequence

1. **M0 — design approval.** Owner approves this package and the numeric profile in §6.
   Until then no implementation starts from this document as an authority.
2. **M1 — API addition.** Introduce `ArtifactPlan`, `ArtifactRecordSource`, the bounded framer
   and the two intent records behind the existing module surface, with the batch adapter
   unchanged for callers.
3. **M2 — equivalence.** Run §8 tests 1–5 and confirm byte identity with the conformance
   vectors and current batch outputs.
4. **M3 — producer switch.** Route the producer through the streaming pipeline with the
   two-intent lifecycle and §7 typed outcomes.
5. **M4 — qualification.** After approval of concrete maxima, run fault, cancellation and
   RSS plateau evidence. Record results in a separate dated package. No status is promoted by
   migration steps alone.

### 10.2 Open decisions requiring owner approval

| ID | Decision |
|---|---|
| OD-01 | Approve or replace every numeric maximum in §6.2 and register the `STREAM-RES-1` profile digest. |
| OD-02 | Approve the exact source-snapshot identity and revision representation, including how an immutable snapshot is attested without granting a right. |
| OD-03 | Approve the replay-proof member set (`source_content_digest`, counts, first and last keys) and the `SourceReplayMismatch` outcome. |
| OD-04 | Approve spool location, filesystem, temp-disk bound, retention and purge rule for non-replayable sources. |
| OD-05 | Approve the recovery treatment of `SPOOL_SEALED` and the proposed stage literals, and confirm compatibility with the ratified v2 journal schema. |
| OD-06 | Confirm strict duplicate-key rejection or amend the profile to permit equal keys with a stable tie-break rule. |
| OD-07 | Approve the gzip streaming profile equivalence proof and any registered compression-version change; none is made here. |
| OD-08 | Approve new typed error and recovery variants (`PublicationCancelled`, `CancellationAfterSeal`, `SourceIdentityMismatch`, `SourceReplayMismatch`, `SpoolEvidenceMismatch`) and their stable codes. |
| OD-09 | Assign the PERF-001 measurement package and its platform, filesystem and device profile. |
| OD-10 | Decide whether the batch API remains indefinitely as an adapter or receives a deprecation date after M3 equivalence. |

### 10.3 Non-claims

This package specifies a lifecycle. It does not implement it, does not qualify a filesystem or
device tier, does not ratify a resource number, does not grant a source right, does not accept a
dataset and does not establish a cross-execution result with Nirnay. Status remains **PROPOSED
/ AWAITING OWNER APPROVAL**.

## Appendix A — Ratified-decision conformance and Phase 3A corrective work (2026-11-25, WS-DOC-001)

Status: **additive conformance appendix only**. The original §§1–10 text above is retained
unchanged as PROPOSED proposal history. `WS-STREAM-001` (2026-11-25, decision digest
`f74153024c1d526fe5c9d49b22e541263581c52c0dbae19a67e8d2ea841a4fe1`) governs where a ratified
choice differs from a proposal. Nothing in this appendix approves a number, a profile digest, a
schema version, an implementation state or a capability promotion.

### A.1 Ratified architecture and interface contracts A-01..A-12

The following twelve items were **ratified at contract level** by `WS-STREAM-001` §1; the cited
design sections remain the governing proposal material, and the decision record carries the exact
selected alternatives, rationales, invariants and tests.

| Ratified item | Contract subject | Governing proposal material |
|---|---|---|
| A-01 | Bounded record-source interfaces: one canonical record at a time, explicit end-of-stream, bounded framer, no whole-artifact slice or caller order key | §2.1–§2.3 |
| A-02 | Streaming producer pipeline with per-record consumption and fixed-size accumulator state | §3 |
| A-03 | `PreparationIntent` written and synced before consumption; `SealedPublicationIntent` as the publication seal; no earlier receipt, marker or rename | §4.1–§4.4 |
| A-04 | Canonical byte-derived ordering recomputed from received bytes and strictly compared with one predecessor | §2.4 |
| A-05 | NDC v2 Profile 1 dataset digest over concatenated uncompressed canonical record streams | §5 |
| A-06 | Deterministic streaming compression with registered method and settings, byte-identical for accepted input | §3.2 |
| A-07 | Incremental stored and expanded digests plus dataset accumulator over exact emitted bytes | §3.1 |
| A-08 | Bounded decompression and parsing: emission caps before buffer growth, one reusable line buffer, strict one-line parse, profile depth/string/token bounds | §3.1, §5 (B16) |
| A-09 | Cancellation, backpressure and typed first-refusal semantics with stable codes | §7 |
| A-10 | Descriptor-relative private snapshot writing and cleanup; complete `CleanupReport` or typed `CleanupPending` | §4 (B16) |
| A-11 | Independent producer and verifier implementations; only schema and vectors shared | §9.4 |
| A-12 | Separate Fieldbook publication receipt and Nirnay admission receipt; neither created from the other | §4.2 |

All numeric maxima in §6.2 remain **DEFERRED** under `WS-STREAM-001` DEF-01; resource profiles are
role-specific and **not approved**; `STREAM_RESOURCE_PROFILE_RATIFIED` is PENDING;
`PERF_001_QUALIFIED` and `OPERATIONALLY_QUALIFIED` are BLOCKED. `NDC-RECEIPT-001` remains
**PROPOSED** and is not ratified by A-12 or by this appendix.

### A.2 Phase 3A corrective work packages — pointers only

| Package | Corrective scope | Ratified anchor |
|---|---|---|
| `FB-STREAM-001` | Plan/source pairing: the fixed `ArtifactPlan` and the opened `ArtifactRecordSource` must agree on snapshot identity, revision and replayability before consumption | §2.1–§2.2; A-01, OD-02, OD-03 |
| `FB-STREAM-002` | Preparation quarantine: no availability, receipt, marker or final rename before the sealed intent; refusal and restart leave quarantined, sealed evidence | §4.1–§4.4; A-03, OD-08 |
| `FB-SPOOL-001` | Multi-source spool for non-replayable sources: operation-scoped bounded spool, exact digests/counts and `SPOOL_SEALED` evidence before adoption | §4.6; OD-04, OD-05 |
| `FB-LIMIT-001` | Expansion ratio: per-artifact expanded-to-stored bound with emission caps checked before buffer growth; no inferred numeric value | §3.1; A-07, A-08, DEF-01; `WS-STREAM-001` §3.2 `max_expansion_ratio` |
| `FB-SOURCE-001` | Core-owned bounded record port: one canonical record at a time from a core-owned source, no caller-supplied order key and no whole-artifact slice | §2.2; A-01 |

These identifiers are **pointers to Phase 3A corrective work**. This documentation work records no
merge, commit, exact head, CI run, gate result, test count or capability claim for any of them; the
parent's dated implementation/evidence records govern if and when a package is recorded. Phase 3
evidence already recorded is `engineering/conformance/phase-3-acceptance-2026-11-25.md`; it does
not by itself record any Phase 3A corrective package above.

### A.3 Unchanged non-claims

No source, schema, right, data, provider, India or experiment artefact is changed. Rights stay
`UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection `DISABLED`, experiments
`BLOCKED`, live execution `DISABLED`, D11 strict, `PUBLICATION_DURABILITY_VERIFIED` `false`, and
Workspace hosted CI `NOT_RUN`. Publication and admission receipts stay separate. No approved
digest, historical record or capability state was rewritten to make this appendix consistent.
