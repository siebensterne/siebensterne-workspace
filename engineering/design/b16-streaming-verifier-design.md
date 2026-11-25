# B16 — Bounded streaming Nirnay release verifier design

<!-- SPDX-License-Identifier: Apache-2.0 -->

Date: 2026-11-25. Work package: WP-3 / B16, the Nirnay consumer half of the open
B15/B16 streaming finding. Status: **PROPOSED / AWAITING OWNER APPROVAL**. Branch
`docs/b16-streaming-verifier-design`, workspace base `95580f5`. This is a design
specification only. It grants no implementation authority, accepts no dataset,
changes no right and creates no admission receipt.

Ratification pointer (2026-11-25): `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md`
ratifies the B15/B16 architecture and interface contracts. All numeric resource maxima remain
DEFERRED; this design keeps its PROPOSED status.

### Current-status notice (2026-11-25, WS-DOC-001)

- **Ratified:** the architecture and interface contracts selected by `WS-STREAM-001` —
  A-01..A-12, covering both B15 and this verifier design — were **RATIFIED by owner direction on
  2026-11-25**, at contract level only. Decision digest (`shasum -a 256`):
  `f74153024c1d526fe5c9d49b22e541263581c52c0dbae19a67e8d2ea841a4fe1`. See
  `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md` §1. This notice does
  not claim an implemented, tested or verified state.
- **Proposal history:** this document remains **PROPOSED / AWAITING OWNER APPROVAL**. Its original
  §§1–12 are retained unchanged as proposal history; Appendix B identifies assumptions that the
  ratified decisions supersede. A pointer to a ratification does not convert a design package into
  an implementation, profile approval or qualification record; the ratified choices govern.
- **Deferred and not approved:** every numeric resource maximum, the stored/expanded chunk number,
  parser bounds, concurrency values and the codec identifier remain **DEFERRED**; no deferred item
  is a silent default. The normative `ResourceProfile` contract is role-specific (`PRODUCER`,
  `VERIFIER`, `RECOVERY`, `SNAPSHOT`), but **no profile value or profile digest is approved** by
  `WS-STREAM-001`; `STREAM_RESOURCE_PROFILE_RATIFIED` is PENDING. A verifier invocation without an
  approved `VERIFIER` profile selected by trusted local policy fails closed; its own local ceiling
  is always applied and a producer declaration cannot raise it.
- **Blocked:** `PERF_001_QUALIFIED` and `OPERATIONALLY_QUALIFIED` remain **BLOCKED**;
  `PUBLICATION_DURABILITY_VERIFIED` remains `false`; rights `UNKNOWN`, dataset acceptance
  `BLOCKED`, budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`
  and D11 strict. The freeze is unchanged.
- **Evidence pointers:** the merged Phase 3 implementation and cross-execution evidence is
  `engineering/conformance/phase-3-acceptance-2026-11-25.md` (FB `8216197` / NZ `c1c2f0d`, finite
  explicitly marked `TEST_ONLY` profiles, `STREAMING_IMPLEMENTATION_COMPLETE`, not `Verified`).
  Phase 3A implementation/evidence records are tracked by their work-package identifiers listed in
  Appendix B and in the `engineering/evidence/REVIEW-LOG.md` entry dated 2026-11-25; this notice carries pointers only
  and claims no merge, commit, gate result or capability change for any work package that has not
  been recorded by the parent.
- **Receipts and CI:** `NDC-RECEIPT-001` remains explicitly **PROPOSED / AWAITING OWNER
  RATIFICATION**; the Fieldbook publication receipt and the Nirnay admission receipt remain
  separate objects (A-12), and neither is created from the other. Workspace hosted CI remains
  `NOT_RUN`.

## 1. Authority, scope and freeze

### 1.1 Governing documents

| Authority | Effect on this design |
|---|---|
| `engineering/conformance/ndc-v2-evidence-audit-2026-11-24.md`, finding 10 and §4.2 | B15 (Fieldbook producer) and B16 (Nirnay verifier) are separate P1 work packages. The current bounded in-memory implementation is not represented as streaming or as done. |
| `engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` §1, §3, §5, §11, §13 | Canonical bytes are the sole input to digesting, ordering and signing; byte-derived ordering is mandatory; the schema and vectors are shared, validator implementations are not; no shared runtime crate. |
| `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` §7, I-06, I-08, I-09, I-10 | No ignored cleanup failure; no unbounded buffering in the operational profile; no admission from publication success; no rights promotion. |
| `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md`, Decision D | The dataset digest is over uncompressed canonical record streams in canonical artifact order; compression changes stored bytes and stored digest only. |
| Nirnay `d3b66f52` `crates/release-verifier/CANONICAL-WIRE-2026-11-24.md` and `CLEANUP-CORRECTNESS-2026-11-24.md` | Dated implementation records for the canonical wire mapping and the NZ #144 snapshot cleanup contract that this design must preserve. |

### 1.2 Source facts read

Source was read at Nirnay commit `d3b66f52` (clean `main`, merge of PR #144), the
commit named by the owner. Line numbers below refer to that commit.

- `src/verifier.rs:486-598` `stage_five`: `read_bounded` returns a whole stored
  `Vec<u8>`; `decompress` returns a whole expanded `Vec<u8>`; both digests are
  computed over those vectors; `dataset_hasher.update(&expanded)` runs once per
  artifact; `verify_canonical_record_stream` or `verify_record_stream` returns
  `Vec<ReleaseRecord>`; `builder.add(&component, &stored)` copies full stored
  bytes into the snapshot; `all_records` accumulates one vector per artifact.
- `src/verifier.rs:1083-1087` `StageFive { bindings, data_digest, records:
  Vec<Vec<ReleaseRecord>> }`.
- `src/verifier.rs:1089-1151` `verify_canonical_record_stream`: splits the whole
  expanded buffer on LF, builds a `Vec<ReleaseRecord>` and a parallel
  `Vec<DerivedOrderKey>`, then calls `validate_order_sequence(&keys)` and checks
  `records.len() == descriptor.record_count` at the end.
- `src/verifier.rs:1198-1229` `decompress`: `GzDecoder::read_to_end` materializes
  the expanded stream, then compares `read` with the budget. The budget is
  checked after allocation, not while bytes are emitted.
- `src/verifier.rs:1231-1294` `verify_record_stream`: the same whole-buffer
  pattern for the internal record shape.
- `src/verifier.rs:829-851` `stage_nine` iterates `stage_five.records` to compare
  each `envelope_schema_version` with the manifest declaration.
- `src/verifier.rs:1153-1176` `verify_snapshot_binding` re-hashes every
  `SnapshotEntry.bytes` in memory.
- `src/files.rs:495-502` `SnapshotEntry { name, bytes: Vec<u8>, sha256 }`;
  `src/files.rs:698-740` `SnapshotBuilder::add` takes `bytes: &[u8]` and stores
  `bytes.to_vec()` in metadata; `src/files.rs:796-828` `verify_copy` re-reads the
  whole copy into a `Vec<u8>` and compares slices.
- `src/files.rs:466-491` and `:560-647` `CleanupReport` / `cleanup_directory`:
  `unlinkat` relative to the staging descriptor, post-removal `fsync`, final
  empty re-enumeration, typed `CleanupPending` with remaining names.
- `src/trust.rs:161-191` `VerifierResourcePolicy`: twelve caller-supplied maxima
  with no in-crate defaults.
- `src/error.rs:31-242` `VerifierError` variants and their stage/code mapping.

### 1.3 Non-goals and unchanged freeze

This document does not change source, schema, right, data, provider, India or
experiment artefacts. It does not change the twelve stage numbers, the stable
rejection codes, the trusted-root path rules, the injected trust/evaluation
boundaries, the manifest or sidecar formats, the canonical schema package, or any
approved digest. No compression codec profile is registered here; the codec
decision recorded as open in the evidence audit stays open. Rights stay
`UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection `DISABLED`,
experiments `BLOCKED`, live execution `DISABLED`, D11 strict. No commit is
created by this work package.

## 2. Problem

### 2.1 Peak memory scales with the artifact and the release

The current stage-five path holds, simultaneously, the stored bytes of one
artifact, its full expanded bytes, the parsed records of every artifact visited
so far, one ordering key per record in canonical mode, and a full in-memory copy
of every snapshot entry. `StageFive` retains the record vectors until stage 12
returns. The snapshot re-hash at stage six materializes the copies a second
time. Peak resident memory therefore grows with artifact size, expansion ratio
and record count, not with a fixed verification budget.

### 2.2 A policy ceiling is not a streaming bound

`max_stored_bytes`, `max_expanded_bytes`, `max_record_bytes`, `max_record_count`
and `max_artifact_count` cap how large those vectors may become before refusal.
They do not remove the vectors. A release at the ceiling still allocates one
full stored vector, one full expanded vector, one record object per record, one
ordering key per record and one byte vector per snapshot entry. Streaming means
peak memory is a function of fixed chunk sizes and one record buffer, independent
of artifact size and record count up to the caller's declared ceilings. The
current design is bounded in memory; it is not streaming, and the two states
must not be described interchangeably.

### 2.3 The expanded limit is enforced too late

`decompress` reads the whole decoded stream into `expanded` and only then checks
`read > budget`. A high-expansion input can force an allocation of up to the
budget before the refusal is raised. The limit must be applied to bytes as the
decoder emits them, before a larger buffer is grown.

### 2.4 Rights refusal arrives after full materialization

With UNKNOWN rights, stages one through five still materialize and snapshot
every artifact before stage six refuses. That ordering is required by the
twelve-stage contract, but the materialization is not. A streaming stage five
keeps the same first-refusal point while removing the storage of the bytes that
are no longer needed after verification.

## 3. Required pipeline

### 3.1 Ordered stages

The artifact path is a single pass with one reusable chunk buffer and one
reusable record line buffer:

1. **Release directory descriptor.** `ReleaseRoot::open` and
   `release_dir` keep descriptor-relative `openat` with `O_NOFOLLOW`;
   `enumerate_names` and the exact expected top-level set are unchanged.
2. **Artifact descriptor.** `check_artifact_declarations` sorts by
   `(logical_partition_id, shard_ordinal)`, validates the path alphabet,
   uniqueness, canonical ascending order, encoding, order profile, declared
   compression, declared sizes and record count, and digest shape. The exact
   `artifacts/` file set check is unchanged.
3. **Bounded stored reader.** The published file is opened with
   `O_NOFOLLOW`, rejected as a non-regular file or hard link, and read in fixed
   chunks. Each chunk updates the incremental stored SHA-256 and is written to
   the snapshot entry. Declared `stored_bytes`, `max_stored_bytes` and
   `max_temp_disk_bytes` are enforced while reading; the pre-read and post-read
   `fstat` identity comparison is retained.
4. **Streaming decompressor.** The same stored chunk sequence feeds the decoder
   input. For `compression == "none"` the chunk sequence is the expanded stream
   itself; for the registered gzip profile `flate2` emits expanded chunks. Each
   emitted chunk updates the incremental expanded SHA-256 and expanded byte
   count and is handed to the framer. The effective emission cap is
   `min(max_decompression_budget, max_expanded_bytes, declared uncompressed_bytes)`.
   The decoder is refused at the first chunk that would exceed the cap, not
   after the stream is collected. Clean termination, including gzip trailer and
   CRC validation, is required at EOF.
5. **Bounded record framer.** A reusable line buffer accumulates bytes up to
   `max_record_bytes` and emits exactly one LF-terminated line at a time. BOM,
   CR bytes, blank lines and a missing trailing LF are refused as today. The
   observed record count is incremented per emitted line and checked against
   `max_record_count` and the declared `record_count`; the increment happens
   before the next line is parsed, so many tiny records cannot accumulate state.
6. **One-record parser.** For each line: strict JCS parse of that line only,
   depth check against `max_json_nesting`, canonical-byte identity check,
   typed canonical record or internal record parse, required-field and
   envelope-version check, event-registry membership, byte-derived ordering key
   recomputed from the received line, and incremental strict comparison with the
   single previous key. No parsed record, key vector or line text is retained
   after the check. The expanded SHA-256, the dataset SHA-256 and the byte and
   record counters continue over the same chunks.
7. **Constant-size per-artifact verification state.** After EOF the only
   retained per-artifact values are fixed-size fields: stored digest, expanded
   digest, stored byte count, expanded byte count, observed record count, one
   previous ordering key, the envelope-version agreement flag, and the
   metadata-only `ArtifactBinding` used by the receipt. Dataset hashing uses one
   accumulator for the whole release.
8. **Stages nine through twelve consume aggregates.** `stage_nine` reads the
   envelope-version agreement flag instead of iterating records. Stages seven,
   eight, ten and eleven already read the manifest, the injected evaluators and
   the request; stage twelve binds the bindings, the two digests, the rights
   decision and the coverage decision. No stage after five needs a record body,
   a record vector or an artifact byte vector.

### 3.2 Incremental digest semantics

Three digests are maintained by fixed-size accumulators:

- **Stored SHA-256** over the exact bytes read from the published descriptor.
  Its final value is compared with `descriptor.stored_sha256` and with the digest
  produced by `finalize_entry` from the private copy.
- **Expanded SHA-256** over the exact bytes emitted by the decoder in canonical
  artifact order. Its final value is compared with
  `descriptor.uncompressed_sha256`.
- **Dataset SHA-256** over the concatenation of uncompressed canonical record
  streams in canonical artifact order, updated once per emitted expanded chunk.
  Its final value is compared with `manifest.digests.data_sha256`.

Ordering keys are derived from the received canonical line bytes exactly as
`derive_key_from_bytes` does today: strict parse, JCS identity, mode and
domain/epoch validation against the artifact profile, recomputation from raw
parsed members, and comparison with the typed envelope. Only the predecessor
key is kept. Strict mode keeps its visible-gap rule; no event-time fallback is
introduced.

### 3.3 Invariants preserved from the current verifier

- Twelve stages, their numbers, their completion observer callbacks and the
  first-refusal rule are unchanged. Cross-cutting stage-five refusals keep their
  current stage and code through `VerifierError::stage()`.
- An envelope-version mismatch is detected during the one-record parse but the
  refusal is **deferred to stage nine** with `VerifierError::Envelope` and code
  `REJECT_SCHEMA_ENVELOPE`. This preserves the current first-refusal point and
  code; a stage-five failure encountered later still wins as the first refusal.
- Rights are evaluated only after stage five seals. Stage six keeps
  `Decision::Permit`, the single matching grant requirement, and
  `REJECT_RIGHTS_EVIDENCE` for UNKNOWN or DENY. No admission receipt is created
  under UNKNOWN rights; `receipt_written` stays false.
- No published path is reopened after sealing. Later stages read only the
  private snapshot descriptor.

## 4. Snapshot redesign

### 4.1 API

The `SnapshotBuilder::add(name, bytes)` method is replaced by an explicit
entry lifecycle. Names follow the existing component alphabet and are resolved
relative to the owned staging descriptor.

| Method | Contract |
|---|---|
| `begin_entry(name)` | Validate the component, check the disk budget for a new entry, open `O_WRONLY \| O_CREATE \| O_EXCL \| O_NOFOLLOW \| O_CLOEXEC` under the staging descriptor, and **track the name immediately after create**, before any write, sync or verification. A failure after create leaves a tracked name for cleanup. |
| `write_chunk(chunk)` | Require an active entry. Write one chunk, increment the per-entry stored byte count, and enforce `max_stored_bytes` and `max_temp_disk_bytes` before writing a chunk that would exceed either bound. No chunk larger than the fixed reader chunk size is accepted. |
| `finalize_entry(expected_digest, expected_bytes)` | Require an active entry. Sync and close the file, reopen it with `O_RDONLY \| O_NOFOLLOW` relative to the staging descriptor, stream the copy through an incremental SHA-256 and byte counter, compare with the caller's stored digest and count, mark the entry verified, and return its metadata. The entry stays tracked and unverified on any failure. |
| `verify_entry(name)` | On `PrivateSnapshot`, reopen the named entry with `O_RDONLY \| O_NOFOLLOW` relative to the sealed staging descriptor, re-stream digest and count, require the recorded verified state, and return a proof value. No bytes are materialized. |

`sync_directory` and `seal` keep their current meaning. `verify_snapshot_binding`
uses `verify_entry` for each of the `bindings.len() + 2` entries and compares the
metadata digest and byte count with each binding; the entry-count and exact-name
checks remain.

### 4.2 Metadata-only entry

`SnapshotEntry` becomes metadata only:

| Field | Type | Meaning |
|---|---|---|
| `name` | `String` | Private staging file name. |
| `stored_bytes` | `u64` | Count of bytes written to the staging file. |
| `stored_sha256` | `[u8; 32]` | SHA-256 of the staged bytes, proven by `finalize_entry`. |
| `verified` | `bool` | Copy verification completed; required by `verify_entry`. |

The `bytes: Vec<u8>` field is removed. The file on disk holds the bytes; all
reads of those bytes are descriptor-relative, no-follow and streaming. No full
artifact byte vector exists in snapshot metadata, in the builder or in the
sealed snapshot.

### 4.3 Cleanup contract retained from NZ #144

The cleanup contract recorded for NZ #144 is reused without weakening:

- Names are tracked at create time; `discard_partial` and `discard` return
  `Result<CleanupReport, CleanupPending>`.
- Removal uses `unlinkat` relative to the owned staging descriptor with
  no-follow `statat` before removal. No deletion error is discarded.
- A successful report requires every tracked entry removed or already absent, a
  directory `fsync` after removals, and a final re-enumeration with no entries.
  `CleanupReport::is_complete` encodes that conjunction.
- `CleanupPending` carries the exact staging path, the tracked names not
  confirmed absent or removed, and the failing operation. It maps to
  `CLEANUP_PENDING` and is reported through `RefusalDiagnostic::cleanup` beside
  the original first refusal.
- No `Drop` implementation is the proof signal; callers invoke cleanup on every
  refusal path after staging starts.
- A rights refusal keeps stage 6 and `REJECT_RIGHTS_EVIDENCE` and ends with a
  completed `CleanupReport` or `CLEANUP_PENDING`. It never yields an admission
  receipt.

## 5. Bounded parsing, framing and resource limits

### 5.1 Limits actually enforced

All maxima come from the caller-supplied `VerifierResourcePolicy`; this design
invents no numeric default. Limits are enforced at the point bytes or records
arrive, not after a collection is built.

| Limit | Enforcement point | Refusal |
|---|---|---|
| `max_stored_bytes`, declared `stored_bytes` | During stored chunk reads and `write_chunk` | `ResourceLimit`, `ByteCount` |
| `max_decompression_budget`, `max_expanded_bytes`, declared `uncompressed_bytes` | Per emitted decoder chunk, before buffer growth | `ResourceLimit` |
| `max_total_expanded_bytes` | Running expanded byte total across artifacts | `ResourceLimit` |
| `max_record_bytes` | While accumulating the reusable line buffer, before appending a chunk that would exceed it | `ResourceLimit` |
| `max_record_count` | Per emitted line, before parsing the next line | `ResourceLimit`, `RecordCount` |
| `max_json_nesting` | During strict parse of one line | `ResourceLimit` |
| `max_temp_disk_bytes` | Before each staged chunk write | `ResourceLimit` |
| `max_artifact_count`, `max_open_file_descriptors` | Descriptor validation and every open | `ResourceLimit` |
| String length | Derived from `max_record_bytes`: no single string can exceed the one-line bound. A dedicated `max_string_bytes` field is **not** introduced without owner approval. | `ResourceLimit` |

The chunk size is an internal fixed constant, independent of untrusted
declarations; it is not a caller policy number. The reusable line buffer grows
only up to `max_record_bytes` and is cleared for reuse after each parsed line.

### 5.2 Required abstract tests

All tests use structured, non-market scalars from the ratified conformance
vectors or synthetic byte patterns; no provider data, collection or experiment
is involved.

| Test case | Expected result |
|---|---|
| High-expansion gzip input whose declared `uncompressed_bytes` is within policy but whose emitted bytes exceed the cap | `ResourceLimit` raised while decoding, with no expanded vector and no allocation beyond the fixed chunk plus the reusable line buffer. |
| Truncated gzip stream and truncated final record without trailing LF | `Decompression` for decoder failure; `RecordStream` for the missing LF boundary. No record is emitted for the partial line. |
| Invalid gzip CRC or trailer | `Decompression` at EOF; no expanded digest or dataset digest is finalized. No cleanup is left untracked. |
| One record longer than `max_record_bytes` | `ResourceLimit` at accumulation time; the line buffer never exceeds the bound. |
| JSON nesting deeper than `max_json_nesting` | `ResourceLimit` from the one-line parse; parser recursion is bounded. |
| Single string longer than the derived string cap | `ResourceLimit`; accepted and rejected forms are both exercised. |
| Many tiny well-formed records up to and beyond `max_record_count` | Refusal before parsing a record beyond the bound; no `Vec<ReleaseRecord>` or `Vec<DerivedOrderKey>` is retained; per-record allocations are released for reuse. |
| Ordered, gapped and duplicate byte-derived keys, including mode and domain mismatches | `RecordOrder` with the same code as today; only the predecessor key is retained. |
| Snapshot write, sync, reopen, copy-digest and removal fault injection | Tracked entry remains for cleanup; `CleanupReport` complete or typed `CleanupPending` with exact remaining names; rights refusal keeps stage 6 and `REJECT_RIGHTS_EVIDENCE`. |

Each test asserts the absence of whole-stream vectors by construction of the
pipeline types, not by a memory-count claim. Measured bounds and exact counts
belong to a separate implementation evidence record; this document promotes no
state from `Implemented` to `Verified`.

### 5.3 Expanded limit before materialization

The decoder is driven by a counting `Read` adapter over fixed chunks. The cap
check runs on each decoded chunk before the chunk is appended to the framer, and
the decoder is dropped on refusal. The current `read_to_end`-then-compare shape
is removed. Compression `"none"` passes stored chunks through the same counting
adapter so both profiles share one bound path. Unknown method, profile or
version identifiers still fail closed at declaration validation.

## 6. Independence, stage order and rights

- The verifier implementation stays inside Nirnay's `release-verifier` crate.
  No Fieldbook crate, module, binary, macro or runtime type is imported. The
  canonical schema package in this workspace and its conformance vectors are
  the only shared authority, as ratified in WS-NDC-2026-11-24-003 §1 and §13.
  No shared validator, serializer, digest routine, parser or ordering crate is
  introduced, and no provider or market-data path is added.
- The twelve-stage order and first-refusal semantics are preserved exactly as
  specified in §3.3. Stages one through five complete before any rights
  evaluation; the stage observer records the same stage numbers.
- Stage six rights refusal is unchanged: UNKNOWN or DENY produces
  `REJECT_RIGHTS_EVIDENCE` at stage 6, `receipt_written` remains false, and no
  admission receipt is created. A public availability marker, a publisher
  receipt or a successful checksum never promotes rights.
- Snapshot cleanup after a rights refusal yields a complete `CleanupReport` or
  `CLEANUP_PENDING`; neither outcome grants rights or changes the refusal code.

## 7. Owner acceptance list

The following is the owner's acceptance list for B16. Each item is a required
property of the future implementation, not a claim that it is present now.

| # | Acceptance item | Design provision | Evidence to be produced at implementation |
|---|---|---|---|
| 1 | No whole-artifact stored vector | Chunked stored reader writes each chunk directly to stored SHA-256 and snapshot writer | Type and test audit of the stored path |
| 2 | No whole-artifact expanded vector | Counting decoder adapter emits fixed chunks to digests and framer | Type and test audit of the decoder path |
| 3 | No all-record vectors | One-record parser and predecessor key only; `StageFive.records` removed | Type audit of `StageFive` and stages nine through twelve |
| 4 | No full artifact bytes in snapshot metadata | Metadata-only `SnapshotEntry`; bytes live on disk | Struct audit and fault-injection tests |
| 5 | Bounded parser and decompressor | Reusable line buffer, `max_record_bytes`, `max_record_count`, depth and string caps; emission cap during decode | Adversarial abstract tests in §5.2 |
| 6 | Incremental digests | Stored, expanded and dataset SHA-256 accumulators updated per chunk | Digest equality against conformance vectors |
| 7 | Exact inventory and ordering | Exact file-set enumeration, byte-derived predecessor key, strict gap rule, exact record count | Ordering and file-set tests |
| 8 | Cleanup complete or pending | NZ #144 cleanup contract reused on every refusal path | Cleanup fault injection and rights-refusal tests |

## 8. Interaction with FB-REC-022 bounded recovery

- The Fieldbook bounded-recovery package's checked-in primitive is the reusable
  bounded record reader in Fieldbook `src/integrity/journal.rs` at completion
  head `fd4b542`: four-byte framing, one reusable buffer resized for one record,
  a per-record byte limit, header and payload length consistency, and a checksum
  computed over the framed bytes. `visit_observations` streams one record at a
  time with that reusable buffer and bounded per-record limit, while the older
  `read_records` and `read_observations` entry points still load a full run. The
  mapping of the owner label FB-REC-022 to that primitive is recorded here for
  owner confirmation (open decision D8).
- The verifier and the producer use **equivalent bounded primitives**: one
  record held at a time, a reusable buffer, a per-record limit, streaming
  digests, and no whole-stream vectors. They remain **independent
  implementations**. This design does not import the Fieldbook reader, does not
  make it a shared crate, and does not change the Fieldbook journal framing.
- Digest semantics must agree on the **same canonical bytes**. For NDC artifacts
  the dataset digest is SHA-256 over the concatenation of uncompressed canonical
  record streams in canonical artifact order (Profile 1 Decision D), the stored
  digest is over compressed bytes, the expanded digest is over uncompressed
  canonical bytes, and RFC 8785 JCS bytes are the sole input to digesting,
  ordering and signing (WS-NDC-2026-11-24-003 §3.6). The Fieldbook journal
  checksum covers that journal's own framed bytes and is an integrity check, not
  the NDC dataset digest; the two must not be conflated. Agreement is established
  by paired cross-execution against the B8 vectors, not by sharing digest code.

## 9. Failure matrix

First refusal only; the cleanup column applies once staging has started. A stage
number and code are the current `VerifierError` values and are preserved.

| Case | Detect point | Stage / code | Cleanup | Retained state |
|---|---|---|---|---|
| Unsafe path, symlink, hard link, special file | Artifact descriptor or open | 5 `REJECT_TRUSTED_PATH` | Complete report or pending | None |
| File set differs from `artifacts[]` | Exact enumeration | 5 `REJECT_ARTIFACT_DIGESTS` | Complete report or pending | None |
| Declared size or count above policy | Declaration validation | 5 `REJECT_RESOURCE_LIMIT` | Complete report or pending | None |
| `fstat` or read byte count mismatch | Stored reader | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | Fixed counters only |
| Stored digest mismatch | Stored-stream EOF | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | Fixed counters only |
| Unknown compression declaration | Declaration validation | 5 `REJECT_ARTIFACT_DIGESTS` | Complete report or pending | None |
| Truncated gzip, invalid CRC/trailer | Decoder EOF or read | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | Fixed counters only |
| Expansion beyond effective cap | Per emitted chunk | 5 `REJECT_RESOURCE_LIMIT` | Tracked entry then cleanup | Fixed counters only |
| Expanded count or digest mismatch | Expanded-stream EOF | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | Fixed counters only |
| BOM, CR, blank line, missing trailing LF, non-UTF-8 line | Framer | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | One line buffer |
| Oversized record, deep nesting, long string | Framer or one-record parser | 5 `REJECT_RESOURCE_LIMIT` | Tracked entry then cleanup | One line buffer |
| Duplicate/unknown/missing field, wrong type, non-JCS bytes, unregistered event type | One-record parser | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | One record only |
| Ordering violation, duplicate key, disallowed gap, mode/domain mismatch | Predecessor comparison | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | One predecessor key |
| Observed count differs from declared | Framer EOF | 5 `REJECT_ARTIFACT_DIGESTS` | Tracked entry then cleanup | Fixed counter only |
| Snapshot copy digest or count mismatch | `finalize_entry` / `verify_entry` | 5 `REJECT_TRUSTED_PATH` | Tracked entry then cleanup | Metadata only |
| Envelope version differs from manifest | Deferred flag read | 9 `REJECT_SCHEMA_ENVELOPE` | Snapshot discard | One boolean |
| Rights UNKNOWN or DENY, or ambiguous grants | Stage-six evaluation | 6 `REJECT_RIGHTS_EVIDENCE` / `REJECT_AMBIGUOUS_GRANTS` | Complete report or pending | No receipt |
| Filesystem I/O failure | Any open, write, sync, unlink | Owning stage, `REJECT_IO` | Complete report or pending | Status at failure |
| Cleanup did not reach an empty synced directory | Cleanup result | `CLEANUP_PENDING` beside first refusal | Pending with path and names | No claim of removal |

## 10. Open decisions requiring owner approval

| ID | Decision |
|---|---|
| D1 | Approve the fixed stored/expanded chunk size constant, or supply a policy field for it. No numeric default is introduced by this document. |
| D2 | Approve a dedicated `max_string_bytes` policy field, or confirm the derived `max_record_bytes` string cap as sufficient. |
| D3 | Confirm that deferring the envelope-version refusal to stage nine, while detecting it during stage-five parsing, preserves the required first-refusal semantics. |
| D4 | Approve `verify_entry` timing: immediately in `finalize_entry`, again at snapshot binding, or both. The design assumes both, with no byte vectors. |
| D5 | Confirm that removing `SnapshotEntry.bytes` is an acceptable breaking internal API change for the final migration step, with the public `verify_release` and `verify_release_with_diagnostics` signatures unchanged throughout. |
| D6 | Approve enforcement of the ratified per-event payload schema registry with its registered digest, beyond today's event-type membership check, and identify the exact stage and code for a registry miss. |
| D7 | Confirm the exact registered gzip profile identifier; the compression codec decision remains open from the evidence audit. |
| D8 | Confirm that FB-REC-022 denotes the bounded reader and `visit_observations` path at Fieldbook `fd4b542` cited in §8. |
| D9 | Confirm whether `max_open_file_descriptors` needs a higher minimum for one artifact descriptor plus one staging writer plus one verify fd in parallel; no change is made here. |
| D10 | Approve the staged migration plan in §11 and the evidence record format for measured bounded memory, without promoting any state to `Verified`. |

## 11. Compatibility and staged migration

The public API is kept stable: `ReleaseVerifier::verify_release`,
`verify_release_with_diagnostics`, `ReleaseLocator`, `VerifierConfig`,
`VerifierResourcePolicy`, `RefusalDiagnostic`, `AdmissionReceipt`, and all
`VerifierError` variants, codes and stage numbers remain usable by existing
callers and conformance binaries. Migration proceeds in four stages, each
leaving the twelve-stage order, first-refusal behavior and cleanup contract
intact:

1. **Add primitives.** Introduce the chunked stored reader, counting decoder
   adapter, bounded framer and one-record parser beside the existing paths, with
   the §5.2 abstract tests. No stage wiring changes.
2. **Switch the artifact path.** Route stage five through the streaming
   pipeline and remove `all_records`, `keys`, `Vec<ReleaseRecord>` returns and
   the whole-buffer `decompress`. `StageFive` retains bindings and digest only;
   the envelope flag is consumed at stage nine.
3. **Switch the snapshot.** Replace `add` with `begin_entry` / `write_chunk` /
   `finalize_entry`, remove `SnapshotEntry.bytes`, and change
   `verify_snapshot_binding` to `verify_entry`. Fault-injection tests keep the
   NZ #144 cleanup outcomes.
4. **Remove legacy code.** Delete the retired whole-buffer helpers and record
   the measured bounds in a dated implementation evidence record. No approved
   digest, schema byte or rejection code is rewritten.

Stages 1 through 3 keep both paths available only if owner-approved; the
acceptance list requires the whole-vector path to be absent in the final state.
No Fieldbook change, schema change, cross-repository crate, data file, right,
India artefact or experiment is part of this migration. Cross-execution against
the B8 vectors remains the agreement gate for digest and ordering semantics.

## 12. Effect

This document adds a PROPOSED design to the workspace document map and a review
log entry. It changes no capability state, no approved digest, no registered
schema version, no source repository and no freeze term. Approval of this design
is a separate owner gate from implementation authority and from any later
`Implemented` or `Verified` claim.

## Appendix B — Ratified-decision conformance and superseded assumptions (2026-11-25, WS-DOC-001)

Status: **additive conformance appendix only**. The original §§1–12 text above is retained
unchanged as PROPOSED proposal history; no original line was rewritten. `WS-STREAM-001`
(2026-11-25, decision digest
`f74153024c1d526fe5c9d49b22e541263581c52c0dbae19a67e8d2ea841a4fe1`) governs wherever a ratified
choice differs from a proposal. Nothing here approves a number, a profile digest, a schema byte, a
rejection-code change beyond the recorded selections, an implementation state or a capability
promotion.

### B.1 Proposal assumptions visibly superseded by the ratified decisions

| Original proposal assumption (retained as history) | Superseded by | Ratified choice that governs |
|---|---|---|
| §5.1 string-length row: "Derived from `max_record_bytes` ... A dedicated `max_string_bytes` field is **not** introduced without owner approval"; §5.2 test row "Single string longer than the derived string cap" | **D2** | A **dedicated `parser.max_string_bytes` profile field is selected**; a cap derived from `max_record_bytes` alone is **not** sufficient. The bound is finite, not above `max_record_bytes`, enforced during the strict one-line parse; its value is DEFERRED. |
| §3.3 invariant: envelope mismatch "**deferred to stage nine**" with a later stage-five failure winning as first refusal; §9 failure-matrix row "Deferred flag read / stage 9 `REJECT_SCHEMA_ENVELOPE`"; §11 migration step 2 "the envelope flag is consumed at stage nine" | **D3** | **Refusal occurs at stage five at the point of detection, with no deferral to stage nine; the first refusal is the detection itself.** Stable code `REJECT_SCHEMA_ENVELOPE` is retained, the observable stage becomes 5, the other eleven stage numbers and all other codes are unchanged, and no schema amendment is made. |
| §5.1 closing paragraph: "The chunk size is an internal fixed constant ... not a caller policy number" | **D1** | The stored/expanded chunk size comes from the role profile `io_chunk_bytes`; no built-in default and no approved number. |
| §3.1 step 6: "event-registry membership" as the per-event check | **D6** | The ratified per-event payload schema registry is enforced at stage five with typed registry-miss code `REJECT_PAYLOAD_REGISTRY`; registry digest unchanged and no admission receipt on a miss. |

"Superseded" means the quoted wording is preserved verbatim as proposal history and must not be
read as the governing rule. The original text above was not edited, and the ratified choices in the
right-hand column govern conformance.

### B.2 Phase 3A implementation pointers — no merge claim

| Package | Implementation pointer | Ratified anchor |
|---|---|---|
| `NZ-REG-001` | Per-event payload registry implementation, including the stage-five `REJECT_PAYLOAD_REGISTRY` miss path | D6; `WS-STREAM-001` §4.2 |
| `NZ-RES-001` | Profile resolver: trusted local selection by name and version, role match, consumer ceiling and stricter-of effective limits | `WS-STREAM-001` §3.3, A-08, D9 |
| `NZ-LIMIT-001` | Exact parser bounds in the one-line strict parse, including the dedicated `parser.max_string_bytes` field | D2, D5, A-08; `WS-STREAM-001` §3.2 |
| `NZ-LIMIT-002` | Artifact/concurrency separation, including the parallel artifact/staging/verify descriptor minimum and finite queue bounds | D9, A-09, A-10 |

These identifiers are **pointers to Phase 3A corrective work**. This documentation work records no
merge, commit, exact head, CI run, gate result, test count or capability claim for any of them; the
parent's dated implementation/evidence records govern if and when a package is recorded. Phase 3
evidence already recorded is `engineering/conformance/phase-3-acceptance-2026-11-25.md`; it does
not by itself record any Phase 3A corrective package above.

### B.3 Unchanged status and non-claims

Architecture and interface contracts A-01..A-12 are **RATIFIED**; this design is still **PROPOSED /
AWAITING OWNER APPROVAL** as proposal history. All numeric maxima remain **DEFERRED**, role-specific
profiles are **not approved**, `STREAM_RESOURCE_PROFILE_RATIFIED` is PENDING, and `PERF_001_QUALIFIED`
and `OPERATIONALLY_QUALIFIED` are BLOCKED. `NDC-RECEIPT-001` remains explicitly **PROPOSED**, not
ratified; the Fieldbook publication receipt and the Nirnay admission receipt remain separate.
Workspace hosted CI remains `NOT_RUN`. No source, schema, right, data, provider, India or experiment
artefact is changed; rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection
`DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict and
`PUBLICATION_DURABILITY_VERIFIED` `false`. No approved digest, historical record or capability
state was rewritten to make this appendix consistent.
