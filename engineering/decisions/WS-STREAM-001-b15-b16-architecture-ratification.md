# WS-STREAM-001 — B15/B16 streaming architecture and contract ratification

Status: **RATIFIED by owner direction, 2026-11-25**.
Authority: programme owner. Scope: Workspace documentation only. This record ratifies
architecture and interface contracts. It approves no numeric resource maximum, no schema
version, no codec identifier, no right, no dataset, no release, no key and no capability
promotion.

Worktree: `docs/stream-architecture-ratification`, workspace base `1db1095`. No source file,
schema file, right record, data file, provider record, India record, experiment, release, key,
dataset or CI configuration is changed by this decision. No commit is created. The freeze is
unchanged: rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection `DISABLED`,
experiments `BLOCKED`, live execution `DISABLED`, D11 strict. `PUBLICATION_DURABILITY_VERIFIED`
remains `false`.

Source records resolved here: `engineering/design/b15-streaming-producer-design.md` §10.2
(OD-01..OD-10) and `engineering/design/b16-streaming-verifier-design.md` §10 (D1..D10). Both
design documents keep their `PROPOSED / AWAITING OWNER APPROVAL` status; a pointer to this
ratification does not convert a design package into an implementation or qualification record.

## 1. Approved exactly

The owner approves exactly the following twelve architecture and interface-contract items, at
contract level only. Each item is a required property of a future implementation; none is a
claim that the property is present today.

| ID | Ratified architecture or contract item | Governing design material |
|---|---|---|
| A-01 | Bounded record-source interfaces: one canonical record at a time, an explicit end-of-stream signal, a bounded framer, no whole-artifact slice and no caller-supplied order key | B15 §2.1–§2.3 |
| A-02 | Streaming producer and verifier pipelines: per-record consumption, fixed-size accumulator state and no buffer sized from total artifact or release bytes | B15 §3, B16 §3.1 |
| A-03 | `PreparationIntent` written and synced before source consumption and `SealedPublicationIntent` written and synced as the publication seal; no receipt, marker or final rename before the seal | B15 §4.1–§4.4 |
| A-04 | Canonical byte-derived ordering: order key recomputed from received canonical bytes, strictly compared with one predecessor, no caller key and no buffering sort to repair order | B15 §2.4, B16 §3.2, WS-NDC-2026-11-24-003 §5.4 |
| A-05 | NDC v2 Profile 1 digest compatibility: dataset digest over concatenated uncompressed canonical record streams in canonical artifact order; manifest, sidecar, expected receipt and artifact bytes unchanged | B15 §5, Profile 1 Decision D |
| A-06 | Deterministic streaming compression using the registered method and settings, with byte identity to the current encoder for accepted input and no byte-pattern classification | B15 §3.2 |
| A-07 | Incremental stored and expanded digests, plus the dataset accumulator, updated over exact bytes as they are emitted | B15 §3.1, B16 §3.2 |
| A-08 | Bounded decompression and parsing: emission caps checked before buffer growth, one reusable record line buffer, strict one-line parse, and depth, string and token bounds from a profile | B16 §3.1 steps 4–6, §5 |
| A-09 | Cancellation, backpressure and failure semantics: typed outcomes, first-refusal rule, stable codes, fixed-capacity queues and no unearned availability stage | B15 §7, B16 §9 |
| A-10 | Descriptor-relative private snapshot writing and cleanup: no-follow entries under an owned staging descriptor, metadata-only entries, name tracking at create, complete `CleanupReport` or typed `CleanupPending`, no deletion error discarded | B16 §4 |
| A-11 | Independent producer and verifier implementations: no shared runtime crate, validator, serializer, digest routine or connector; only the canonical schema package and vectors are shared | B15 §9.4, B16 §6, Profile 1 Decision I |
| A-12 | Separate publication and admission receipts: the Fieldbook publication receipt and the Nirnay admission receipt remain distinct objects; neither is created from the other | B15 §4.2, B16 §6; NDC-RECEIPT-001 remains PROPOSED |

Approval of A-01..A-12 does not approve the numeric proposals in B15 §6.2, does not register a
profile digest, does not accept the separate NDC-RECEIPT-001 wire contract and does not promote
any `Implemented` or `Verified` state.

## 2. Deferred explicitly

| ID | Deferred item | Gate for a later decision |
|---|---|---|
| DEF-01 | All `STREAM-RES-1` numeric maxima in B15 §6.2, including the 65,536-byte record, 536,870,912-byte (512 MiB) stored artifact, 1,073,741,824-byte (1 GiB) expanded artifact, 128-artifact and 268,435,456-byte (256 MiB) RSS proposals, and all totals, window, parser, queue, disk, descriptor, intent and decompression numbers | Owner acceptance or replacement of every number and approval of a profile digest; no workload measurement is claimed here |
| DEF-02 | Production memory budgets, including any role-specific RSS ceiling and the PERF-001 256 MiB proposal | PERF-001 evidence at an approved profile, platform, filesystem and device |
| DEF-03 | Concurrency settings: worker count, concurrent artifacts and queue capacity values | Approved role profile and measured evidence |
| DEF-04 | Throughput, latency and CPU targets | Measured and independently reviewed evidence package |
| DEF-05 | Operational qualification and `OPERATIONALLY_QUALIFIED` | Separate owner decision after evidence review |
| DEF-06 | The exact registered gzip codec profile identifier, still open from the evidence audit and B16 D7 / B15 OD-07 | Owner registration of a codec identifier; unknown identifiers fail closed until then |
| DEF-07 | PERF-001 platform, filesystem and device assignment (B15 OD-09) | Owner assignment with a qualified device tier |
| DEF-08 | Any deprecation date for the batch compatibility adapter (B15 OD-10) | Separate owner decision after M3 equivalence |

A deferred item is not a silent default. No implementation may infer a number, identifier or
qualification from a deferred row.

## 3. Normative `ResourceProfile` contract

### 3.1 Types and immutability

The following contract is normative. It defines a form, not an approved instance; no digest
for any profile is registered by this decision.

```rust
pub struct ResourceProfileId { name: String, version: u32 }
pub enum ProcessingRole { PRODUCER, VERIFIER, RECOVERY, SNAPSHOT }
pub struct ResourceProfile { id: ResourceProfileId, digest: [u8; 32],
                             role: ProcessingRole, limits: ProfileLimits }
```

- Every field of `ResourceProfile` and `ProfileLimits` is private and populated only by a
  validating constructor. There is no public setter, no caller-supplied raw limit and no
  in-place mutation.
- Validation rejects non-finite, zero where a positive value is required, overflow, and
  inconsistent relations (per-artifact above per-release, chunk above record bound, string or
  token above record bound, queue above record bound, descriptor count below the required
  parallel set, or a role/profile mismatch). All enforcement uses checked arithmetic on
  bytes and records actually observed.
- `digest` is over the canonical serialization of `id.name`, `id.version`, `role` and the
  complete `limits` set with a domain-separated SHA-256 construction. A change to any field
  requires a new version and a new digest. An existing profile is never rewritten.
- A profile is bound by identifier and digest in the `PreparationIntent`, the
  `SealedPublicationIntent`, verifier evidence and dated implementation evidence records.
  A mismatched digest fails closed.

### 3.2 Required limit fields

Every field below is a required part of the contract. All values are **DEFERRED**; this table
defines names and meaning only.

| Field | Meaning |
|---|---|
| `max_record_bytes` | One framed canonical record line, excluding the appended LF |
| `max_records_per_artifact`, `max_records_per_release` | Observed record counts at artifact and release scope |
| `max_stored_bytes_per_artifact`, `max_stored_bytes_per_release` | Compressed or uncompressed-as-stored byte counts |
| `max_expanded_bytes_per_artifact`, `max_expanded_bytes_per_release` | Expanded canonical byte counts |
| `max_decompression_budget_bytes` | Consumer-side emission cap applied before buffer growth |
| `max_expansion_ratio` | Expanded-to-stored ratio bound for one artifact |
| `storage_codec.window_bytes` | Codec window for the registered compression method |
| `io_chunk_bytes` | Fixed stored/decoder chunk size; no internal default independent of the profile |
| `parser.max_nesting_depth`, `parser.max_string_bytes`, `parser.max_token_bytes` | Bounds inside the one-line strict parse |
| `parser.max_object_members`, `parser.max_array_elements` | Per-record collection bounds inside the same parse |
| `max_concurrent_artifacts`, `worker_count`, `queue_capacity_records` | Fixed concurrency and backpressure bounds |
| `temp_disk_bytes` | Spool and staging disk bound for one operation |
| `max_processing_duration` | Wall-clock processing budget for one operation |
| `max_journal_record_bytes`, `max_preparation_intent_bytes`, `max_sealed_intent_bytes` | Durable intent and journal record size bounds |
| `max_open_file_descriptors` | Parallel descriptor bound, sufficient for the artifact descriptor, staging writer and verify descriptor together with the owned directory descriptors |
| `memory_budget_bytes` | Role-specific resident-memory budget; one value per `ProcessingRole` |

### 3.3 Selection, roles and effective limits

- The `ProcessingRole` of the executing component must equal the role of the selected
  profile. A verifier does not execute under a `PRODUCER` profile; a recovery or snapshot
  task does not inherit a producer or verifier budget. Each role gets its own profile with
  its own `memory_budget_bytes`.
- A **trusted local policy** selects the profile by name and version in each process. The
  producer selects its `PRODUCER` profile locally; the verifier selects its `VERIFIER` profile
  locally. Policy is local configuration, not a remote declaration, a manifest field or a
  caller hint.
- A producer may declare its profile identifier and digest in the `PreparationIntent` as
  evidence of how the bytes were produced. That declaration never increases the consumer's
  allowance. The verifier enforces its own role profile and its own local ceiling.
- The effective limit for any checked quantity is the stricter value:
  `effective = min(consumer_local_ceiling, consumer_role_profile_limit, producer_declaration_if_present)`.
  A missing or weaker producer declaration cannot relax the consumer's limit.
- No production invocation starts without an approved profile of the correct role selected by
  trusted local policy. Absence, digest mismatch, role mismatch or an unapproved profile is a
  fail-closed refusal before any source is opened. There is no fallback to caller-supplied
  raw maxima and no default number.
- A test-only profile is finite, fully populated and explicitly marked `TEST_ONLY` in
  `id.name`. It is accepted only by a test harness, never by a production invocation, and it
  does not satisfy `STREAM_RESOURCE_PROFILE_RATIFIED`. Test-only values are not evidence for
  PERF-001, RSS plateaus, throughput or operational qualification.

## 4. Individual decision resolutions

Each source decision is resolved on its own. The decision text quoted in each first column
cell is the exact text from the cited design section; no group approval is implied.

### 4.1 B15 OD-01..OD-10 (source: §10.2)

| ID | Selected alternative | Rationale | Compatibility impact | Invariants | Test |
|---|---|---|---|---|---|
| OD-01 | Decision text (§10.2): "Approve or replace every numeric maximum in §6.2 and register the `STREAM-RES-1` profile digest." **Selected: DEFER every numeric maximum; register the normative `ResourceProfile` contract in §3 instead. No `STREAM-RES-1` digest is approved.** | The proposals derive from no workload measurement; Profile 1 Decision F forbids unmeasured normative maxima. A contract can be ratified without values. | No wire field, manifest byte, schema version or batch API change. The caller `ResourcePolicy` surface stays as-is but is not an authority for approved limits. | No production invocation without an approved profile of the correct role; all limits finite and checked; test-only profiles finite and marked; stricter-of rule in §3.3. | Contract test asserts no registered production digest, no numeric maximum in this decision, and fail-closed refusal when no approved profile is selected; test-only profiles enforce checked arithmetic. |
| OD-02 | Decision text (§10.2): "Approve the exact source-snapshot identity and revision representation, including how an immutable snapshot is attested without granting a right." **Selected: opaque, versioned, immutable source-snapshot identity with digest and revision attested in the `PreparationIntent`; no right, truth or completeness claim.** | Replay needs a stable identity, while rights remain a separate evidence structure. An opaque identity cannot be read as permission. | No wire field or schema change; the attestation is ledger-local to the `PreparationIntent`. Source rights stay `UNKNOWN`. | `source_identity()` must equal the plan; a mutable path is not a replayable snapshot; identity match grants no right and accepts no dataset. | Source-identity mismatch yields a typed refusal before consumption; matching digest and revision are required for replay; rights assertions remain absent. |
| OD-03 | Decision text (§10.2): "Approve the replay-proof member set (`source_content_digest`, counts, first and last keys) and the `SourceReplayMismatch` outcome." **Selected: APPROVE the set and the typed `SourceReplayMismatch` outcome.** | Replay must be proven against committed bytes and order, not assumed from a path or a count. | Ledger-local evidence only; no receipt, marker, release byte or operation-id reuse changes. | All five commitments, monotonic derived keys and stored/expanded digests must match; any difference quarantines before availability. | Replay-success case and one mismatch case per member; assert quarantine, no receipt, no marker and no `AVAILABLE`. |
| OD-04 | Decision text (§10.2): "Approve spool location, filesystem, temp-disk bound, retention and purge rule for non-replayable sources." **Selected: caller-configured trusted spool location with the profile `temp_disk_bytes` bound; explicit retention and purge remain a separate owner decision; no production spool location before profile approval.** | A spool is a bounded local implementation detail, not a rights or data decision; neither an unapproved path nor an unchecked disk bound is admissible. | No release layout, wire field or digest change; spool files stay operation-scoped and descriptor-relative. No purge is authorised by this decision. | Spool plan bound in `PreparationIntent`; `temp_disk_bytes` enforced on write; every spool byte digest and count is sealed; no partial spool adoption. | Spool success, truncated spool, digest mismatch and temp-bound refusal; assert quarantined spool retained with evidence and no purge. |
| OD-05 | Decision text (§10.2): "Approve the recovery treatment of `SPOOL_SEALED` and the proposed stage literals, and confirm compatibility with the ratified v2 journal schema." **Selected: APPROVE `SPOOL_SEALED` as a v2-compatible evidence stage; if the ratified journal schema rejects the literal, open a new schema version with an explicit migration. No silent byte rewrite.** | The record is evidence, not a third intent; compatibility is a checkable property, not a wording choice. | Compatible literal: no schema change. Incompatible literal: new version with migration and unchanged historical bytes. No approved digest is edited in place. | Ledger-directory sync at seal; exactly one spool-evidence record; recovery only from a spool whose bytes recompute the sealed digests. | Journal-schema validation of the literal; recovery with and without `SPOOL_SEALED`; schema-version gate records the outcome without rewriting history. |
| OD-06 | Decision text (§10.2): "Confirm strict duplicate-key rejection or amend the profile to permit equal keys with a stable tie-break rule." **Selected: STRICT duplicate-key rejection. No equal-key allowance and no tie-break rule.** | Profile 1 and the batch path already reject equal and decreasing keys; a tie-break would change accepted input bytes and require a profile amendment. | Accepted inputs and their bytes are unchanged; no schema or digest change. | Duplicate or decreasing derived key yields `InvalidRecordOrder` with the named reason; no caller key and no buffering sort. | Ordered, duplicate and decreasing vectors; a caller order hint is supplied and shown to have no effect. |
| OD-07 | Decision text (§10.2): "Approve the gzip streaming profile equivalence proof and any registered compression-version change; none is made here." **Selected: REQUIRE the equivalence proof; make no registered version change; the codec identifier remains DEFERRED (DEF-06).** | Byte identity with the existing encoder is the compatibility condition; no identifier is available to register. | Existing registered identifiers and artifact bytes unchanged; no new version literal is created by this decision. | Streaming gzip output byte-identical to `compress_stream` for every accepted input; bytes never classified by pattern or extension; unknown identifiers fail closed. | Gzip determinism test and B8/conformance vector byte comparison; assertion that no codec identifier was registered here. |
| OD-08 | Decision text (§10.2): "Approve new typed error and recovery variants (`PublicationCancelled`, `CancellationAfterSeal`, `SourceIdentityMismatch`, `SourceReplayMismatch`, `SpoolEvidenceMismatch`) and their stable codes." **Selected: APPROVE the typed variants with stable codes.** | Typed refusals keep recovery deterministic and prevent silent availability. | Ledger-local and error-surface addition only; no wire, receipt shape or published-state change. | One first refusal, stable stage/code mapping across restarts, no receipt or marker on any refusal row. | Fault injection at every §7 trigger; assert exact typed outcome, stable code and absence of unearned availability. |
| OD-09 | Decision text (§10.2): "Assign the PERF-001 measurement package and its platform, filesystem and device profile." **Selected: DEFER the assignment; PERF-001 remains a separate package with no platform, filesystem or device approved.** | No qualification evidence exists; assignment would imply an unearned tier. | No capability state or registry digest changes. | `PERF_001_QUALIFIED` stays blocked; no RSS plateau or performance number is claimed. | Gate assertion that the blocked state is unchanged and no device tier is recorded as approved. |
| OD-10 | Decision text (§10.2): "Decide whether the batch API remains indefinitely as an adapter or receives a deprecation date after M3 equivalence." **Selected: the batch API remains a compatibility adapter; deprecation is DEFERRED (DEF-08).** | Existing callers keep a stable entry point; the adapter can feed the streaming path without a second producer. | Batch signatures unchanged; wire bytes, digests and receipt shape unchanged. | No second producer implementation; caller-owned records enter only at the adapter; no memory-independence claim for the batch path. | Batch vectors rebuild to byte-identical output; type audit shows one producer pipeline behind the adapter. |

### 4.2 B16 D1..D10 (source: §10)

| ID | Selected alternative | Rationale | Compatibility impact | Invariants | Test |
|---|---|---|---|---|---|
| D1 | Decision text (§10): "Approve the fixed stored/expanded chunk size constant, or supply a policy field for it. No numeric default is introduced by this document." **Selected: take the stored/expanded chunk size from the role profile (`io_chunk_bytes`); no built-in default and no approved number.** | A fixed internal chunk is required for a streaming bound; an unapproved constant would be a silent numeric decision. | No public API change; the profile supplies the value through trusted local policy. | Chunk size finite, positive, no larger than the record bound, independent of untrusted declared sizes. | Assert the value comes from the selected role profile; vary declared sizes and confirm the chunk bound is unchanged. |
| D2 | Decision text (§10): "Approve a dedicated `max_string_bytes` policy field, or confirm the derived `max_record_bytes` string cap as sufficient." **Selected: add a dedicated `parser.max_string_bytes` field to the profile; a record-bound-derived cap alone is not sufficient.** | A single long string inside an otherwise small record needs its own bound; the derived cap hides that case. | New profile field only; no wire field, rejection code change or public signature change; value deferred. | String bound finite and not above `max_record_bytes`; enforced during the one-line strict parse. | Long string inside the record bound refused; accepted and rejected string forms both exercised. |
| D3 | Decision text (§10): "Confirm that deferring the envelope-version refusal to stage nine, while detecting it during stage-five parsing, preserves the required first-refusal semantics." **Selected: REFUSE at stage five at the point of detection; no deferral to stage nine. The first refusal is the detection itself.** | A detected mismatch has no later use; deferral retains state and postpones a known refusal. Refusing at detection is the first refusal. | The observable stage for this case becomes 5; the stable typed code `REJECT_SCHEMA_ENVELOPE` is retained. The other eleven stage numbers and all other codes are unchanged; no wire byte, digest or public signature changes. The deferral assumption in B16 §3.3 and §9 is superseded by this owner selection without a schema amendment. | One refusal only; deterministic stage/code mapping; a later stage-five failure cannot override the earlier mismatch; no admission receipt; cleanup complete or pending. | Inject an envelope mismatch during stage-five parsing; assert refusal at detection with the stable code, no stage-nine path, no later failure winning and no receipt. |
| D4 | Decision text (§10): "Approve `verify_entry` timing: immediately in `finalize_entry`, again at snapshot binding, or both. The design assumes both, with no byte vectors." **Selected: BOTH — verify in `finalize_entry` and again at snapshot binding. No byte vectors.** | Write-time verification proves the copy; binding-time verification proves the entry actually used. Neither requires materialization. | Internal snapshot API change only; public `verify_release` and `verify_release_with_diagnostics` unchanged; no wire change. | Metadata-only entries; a verified state is required for `verify_entry`; all reads are descriptor-relative and no-follow; no full artifact vector exists. | Fault injection at finalize and at binding; digest and byte-count equality; struct audit shows no `bytes` field. |
| D5 | Decision text (§10): "Confirm that removing `SnapshotEntry.bytes` is an acceptable breaking internal API change for the final migration step, with the public `verify_release` and `verify_release_with_diagnostics` signatures unchanged throughout." **Selected: APPROVE the internal breaking change; the two public signatures remain stable throughout.** | The byte vector is an internal storage choice; removing it is the mechanism for bounded memory. | Breaking only for internal snapshot users at the final migration step; no public signature, wire byte or rejection-code change. | No byte vector in snapshot metadata, builder or sealed snapshot; twelve-stage order and cleanup contract intact; no shared crate. | Compile public callers against unchanged signatures; type audit for absence of `bytes`; fault injection for NZ #144 cleanup outcomes. |
| D6 | Decision text (§10): "Approve enforcement of the ratified per-event payload schema registry with its registered digest, beyond today's event-type membership check, and identify the exact stage and code for a registry miss." **Selected: ENFORCE the registry at stage five with typed registry-miss code `REJECT_PAYLOAD_REGISTRY`.** | Member-type checks alone do not enforce the ratified payload contract; the registered digest must be applied. | No registry digest or schema change; one typed code added at stage five; first refusal and public API unchanged. | Registry digest must match the ratified package; unknown or mismatched payload fails closed at stage five; no admission receipt on a miss. | Abstract registry hit and miss vectors; assert stage 5, code `REJECT_PAYLOAD_REGISTRY`, no receipt and unchanged registry digest. |
| D7 | Decision text (§10): "Confirm the exact registered gzip profile identifier; the compression codec decision remains open from the evidence audit." **Selected: DEFER the identifier (DEF-06); no codec version is registered by this decision.** | The evidence audit leaves this open; inventing an identifier would be an unapproved registration. | Existing registered identifiers and artifact bytes unchanged; unknown identifiers continue to fail closed. | No new version literal; verifier admits only registered profiles; no byte-pattern inference. | Gate assertion that the identifier remains deferred and that an unregistered declaration is refused. |
| D8 | Decision text (§10): "Confirm that FB-REC-022 denotes the bounded reader and `visit_observations` path at Fieldbook `fd4b542` cited in §8." **Selected: CONFIRM FB-REC-022 as that bounded reader and `visit_observations` path at Fieldbook `4e0f2f5`, the current completion head for that primitive.** | The owner label maps to a read-only inspected primitive; equivalent primitives do not imply shared code. | No Fieldbook source change, no shared crate and no journal framing change. | One reusable record buffer, one per-record limit, framed checksum over journal bytes; NDC digests remain over canonical artifact bytes and are not conflated with the journal checksum. | Read-only source audit at `4e0f2f5`; paired cross-execution against B8 vectors for digest and ordering agreement. |
| D9 | Decision text (§10): "Confirm whether `max_open_file_descriptors` needs a higher minimum for one artifact descriptor plus one staging writer plus one verify fd in parallel; no change is made here." **Selected: source the limit from the role profile; require a minimum sufficient for the artifact descriptor, staging writer and verify descriptor in parallel. No numeric value is approved.** | The parallel set defines a structural minimum; the number belongs in the approved profile. | No public signature or rejection-code change; validation rejects a profile below the required minimum. | Every open checked against the effective limit; stricter-of rule applies; a below-minimum profile fails closed before opening a source. | Exhaustion test with the required parallel descriptors open; below-minimum profile rejected; no fd leak on refusal. |
| D10 | Decision text (§10): "Approve the staged migration plan in §11 and the evidence record format for measured bounded memory, without promoting any state to `Verified`." **Selected: APPROVE the four-stage migration and the dated evidence record format; no state promotion.** | Staged migration preserves stage order, first refusal and cleanup while the whole-vector path is removed. | Public API, twelve stages, stable codes, digests and schema unchanged; internal whole-buffer helpers removed at the final stage. | Stages 1–4 keep the contract intact; whole-vector path absent in the final state; evidence records exact commit, profile id and digest, platform, command, measured bounds and gates; `Implemented` is never promoted to `Verified` by wording. | Migration-stage gate checks; evidence record schema check; capability-state assertions after each stage. |

Twenty decisions are resolved in total: ten OD rows and ten D rows. None is approved by a
blanket clause; each row carries its selected alternative, rationale, compatibility impact,
invariants and test.

## 5. Capability states

| State | Value now | Gate or meaning |
|---|---|---|
| Design ratified | **YES, 2026-11-25** | B15/B16 architecture and interface contracts A-01..A-12 by this decision |
| Implementation with test-only profiles | **MAY PROCEED** | Finite, explicitly marked `TEST_ONLY` profiles only; no production invocation and no capability claim from test profiles |
| `STREAM_RESOURCE_PROFILE_RATIFIED` | **PENDING** | Requires owner approval of every numeric limit and one profile digest per role; no profile is registered here |
| `PERF_001_QUALIFIED` | **BLOCKED** | Needs measured evidence under an approved profile and qualified platform |
| `OPERATIONALLY_QUALIFIED` | **BLOCKED** | Needs independent review of the full evidence package |
| `PUBLICATION_DURABILITY_VERIFIED` | **false** | Unchanged; D1, D1b and D2–D4 remain unqualified under WS-DUR-001 |

These three capability states — design ratified now, implementation permitted with test-only
profiles, resource-profile ratification pending — are the only stream-related state changes.
No schema-conformance, cross-execution, rights-admitted, dataset-accepted, durable or live
state is claimed.

## 6. Compatibility, registries and non-claims

- Approved digests, schema versions, rejection codes, canonical vectors and historical records
  are preserved. `NDC-REGISTRY.md`, `ADR-REGISTRY.md`, the README document map and
  `REVIEW-LOG.md` record this decision without editing an approved byte.
- Both design documents remain `PROPOSED / AWAITING OWNER APPROVAL`; a ratification pointer
  states that the architecture is ratified and the resource numbers remain deferred.
- This decision creates no source file, schema artifact, right, dataset, release, key, receipt,
  provider contact, collection, India artefact, experiment, live route or shared runtime crate.
  The batch API remains a compatibility adapter with no deprecation date.
- No number from B15 §6.2 is normative. `STREAM-RES-1` is a proposed identifier only; no digest
  is approved. A future profile ratification requires a separate owner decision and a new
  dated record.

## 7. Gates

Gate results and exact commands are recorded in `REVIEW-LOG.md` under 2026-11-25. Temporary
local clone symlinks used for the gate runs are removed afterwards. No gate was weakened and
no Fieldbook fixture/e2e suite, Nirnay full suite, hosted CI run or cross-execution was run by
this documentation decision.
