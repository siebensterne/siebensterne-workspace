# WS-NDC-2026-11-24-002 — NDC v2 Release Serialization Profile 1

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **RATIFIED by owner, 2026-11-24.**

Authority: owner direction under `WS-SCOPE-2026-11-24-001` (execution order item 6,
"final NDC v2 serialization ratification"). This record approves release-serialization
semantics only. It is not a schema artifact, not a source implementation, not a data licence,
not a provider authorisation and not a dataset acceptance. No commit, release, key, provider
contact, collection, experiment or India implementation is authorised by it.

Scope: NDC v2 Release Serialization Profile 1 for the complete manifest, detached sidecar,
artifact inventory, record streams, data digest, corrections, resource policy, publication,
trusted keys and producer/consumer independence. Semantics already approved in D0/D1/D2 are
preserved except where an explicit amendment below changes them.

## Approved amendment to D1

Decision A is recorded as a formal amendment to D1 in a new revision document with its own
digest and date: `engineering/conformance/NDC-D1-AMENDMENT-001.md`, approved 2026-11-24,
SHA-256 `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894`.

D1's approved bytes are not edited and its historical digest remains
`215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c`. D0
(`3dace660c362e683790ba7e56a785ded8af836abda36f6eab06ed284de49eed2`) and D2
(`22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957`) are unchanged.
`ndc-consumer-use-v2-proposed.md` (`4b9d1fe7…`) remains **Proposed** and is not an authority.

## Decision A — Manifest digest and circularity

Ratified:

1. Keep the complete canonical manifest. Let `M` be the parsed `manifest.json` object;
   `M = JCS(manifest.json)` is its RFC 8785 canonical byte sequence and `H_M = SHA256(M)`.
2. The manifest does **not** contain its own digest. No property is excluded, removed,
   blanked or replaced by a placeholder before canonicalization. Any digest-exclusion rule,
   including the design's removal of `digests.manifest_sha256` from the signed object, is
   **removed**.
3. `manifest_sha256` lives **only** in the detached sidecar `signature.json`, which has
   exactly these fields: `schema_version`, `algorithm`, `key_id`, `manifest_sha256`,
   `signature_b64`. No `domain` field or other sidecar field is added.
4. The manifest retains `publication_identity.publisher_identity`,
   `publication_identity.signing_key_id` and `publication_identity.signature_reference`.
5. Signing: `S = Ed25519.Sign(K_private, D || H_M)` with
   `D = UTF8("NDC-V2-RELEASE-MANIFEST-SHA256-V1") || 0x00`.
6. Verifier steps, in this order: parse the complete manifest; reject duplicate JSON property
   names; strict schema validation; produce RFC 8785 canonical bytes; SHA-256; compare with
   the sidecar digest; resolve the trusted public key; verify Ed25519; bind the sidecar
   `key_id` to the manifest publisher and signing key; continue.
7. Ambiguous, unknown or extra fields fail closed. There is no partial verification. Publisher
   integrity proves publisher-key control and integrity of the exact signed bytes only.

## Decision B — Record ordering

Ratified:

1. Event-time-first sorting is **rejected**. Ordering is profile-specific per artifact, not a
   single global order derived from event time.
2. Sequenced streaming key: `K_sequence = (sequence_domain_id,
   sequence_epoch/session-reset identity, sequence_number)`.
3. Unsequenced reference key: `K_reference = (object_id, revision, knowledge_time,
   assertion_id)`, with the member definitions fixed by the record family.
4. No implicit fallback to event time. No fabricated sequence numbers. No comparison of
   sequence numbers across unrelated domains. Duplicate sequence positions with conflicting
   payloads are rejected. Known gaps stay visible; they are not filled or interpolated.
   Cross-domain ordering is a serialization convention only and carries no semantic claim.
5. Each artifact declares `record_order_profile`. Existing Fieldbook sequence-domain concepts
   are reused; no new sequence-domain implementation is introduced by this decision.

## Decision C — Artifacts

Ratified:

1. `artifacts[]` is the **sole** inventory of release artifacts. The redundant
   `digests.artifact_digests[]` is removed.
2. Each descriptor has exactly: `logical_partition_id`, `shard_ordinal`, `path`,
   `record_order_profile`, `encoding`, `compression`, `compression_version`, `stored_bytes`,
   `stored_sha256`, `uncompressed_bytes`, `uncompressed_sha256`, `record_count`.
3. `(logical_partition_id, shard_ordinal)` is unique across the release. Artifacts are sorted
   by that pair; this is the canonical artifact order.
4. Records are canonical JSONL: UTF-8, RFC 8785 canonical record representation, one LF after
   every record, no BOM, no CR, no blank line and no incomplete trailing record.
5. The path-safety rules of the design (NFC normalization, component alphabet, no traversal,
   no duplicate normalized paths) remain binding.

## Decision D — Dataset digest

Ratified:

1. `data_sha256 = SHA256(B1 || B2 || ... || Bn)`, where `Bi` is the exact **uncompressed**
   canonical record stream of artifact `i` in canonical artifact order.
2. The dataset digest is independent of compression. Compression changes `stored_bytes` and
   `stored_sha256`, not `data_sha256`.
3. No duplicate physical encodings of one logical shard are published as separate partitions.
   The same logical shard must not appear twice under different encodings or compression
   settings.

## Decision E — Corrections

Ratified:

1. One canonical `lineage.supersedes` relationship with exactly: `supersedes_release_id`,
   `supersedes_manifest_sha256`, `supersedes_data_sha256`, `revision`, `correction_reason`,
   `knowledge_time_ns`, `invalidated_at_time`.
2. An initial release has no predecessor. A corrected release has **one** immediate
   predecessor. The chain is traversable from each corrected release back to its origin.
3. The relationship maps to PROV `wasRevisionOf`. Event-level correction lineage stays a
   separate structure and is not merged into the release-level relationship.
4. Reject cycles, missing predecessors, revision regression, self-reference, mismatched
   release identity and future knowledge time.
5. An array of supersedes relationships is permitted only if one release genuinely supersedes
   multiple independently published releases. That is **not** the current model.

## Decision F — Limits

Ratified:

1. The manifest `limits` field is removed. A manifest carrying it fails strict validation.
2. A versioned normative consumer resource policy is maintained. It is enforced independently
   by the producer and the verifier; the consumer always applies its own maxima and never
   adopts producer-declared maxima as authoritative.
3. The policy covers manifest bytes, artifact count, stored bytes, expanded bytes, record
   length, record count, JSON nesting depth, array and object sizes, compression window,
   decompression budget, temporary disk and file descriptors.
4. Processing is bounded streaming. No buffer or allocation is sized from an untrusted
   declared size without a prior bound check and an actual-byte-count check while reading.
5. Numerical maxima are set only after workload qualification. This record invents no
   unmeasured numbers; the numeric table in the design is a proposal and is not adopted as a
   normative limit.

## Decision G — Publication

Ratified:

1. Publication is the state machine
   `STAGING_CREATED -> FILES_WRITTEN -> FILES_FSYNCED -> STAGING_DIR_FSYNCED ->
   ATOMIC_NO_REPLACE_RENAME -> PARENT_DIR_FSYNCED -> DURABLE_PUBLICATION_RECEIPT -> AVAILABLE`.
2. Staging is a sibling directory on the same filesystem, created exclusively. Every file and
   the staging directory are synced. The final move is an atomic no-overwrite rename, followed
   by a parent-directory sync.
3. A durable receipt is written in the producer journal or catalog binding the release
   identity, manifest digest, dataset digest, publication operation identity, commit position
   and result. The receipt, not directory presence, is the durability evidence.
4. A crash after the rename but before the parent-directory sync is an **uncertain-publication
   recovery** case, not a durability acknowledgement. Interrupted publications are reconciled
   from durable evidence.
5. No existence-check-then-rename. No overwrite. No second publication of an existing
   identity. The design's alternative of a lock plus a no-overwrite existence check is
   rejected.
6. Fail closed if the filesystem cannot provide these guarantees. Directory existence or an
   `AVAILABLE` declaration in the manifest is not proof of durable publication.

## Decision H — Keys

Ratified:

1. An out-of-band trusted publisher registry is authoritative. Each entry carries publisher
   id, immutable key id, Ed25519 public key, purpose, validity begin and end, state
   `ACTIVE`/`RETIRED`/`REVOKED`/`COMPROMISED`, registry revision and revocation evidence.
2. Key ids are never reused. A private key is never stored in Git or in a release package. A
   release cannot supply its own trusted key; the trust root is configured outside the
   release. Registry updates are versioned and auditable. The rights-review authority is
   separate from the signing authority.
3. `ACTIVE` signs and verifies. `RETIRED` cannot sign new releases; historical verification
   requires trusted evidence of publication before retirement. `REVOKED` and `COMPROMISED`
   fail closed. A compromise exception exists only under a separately approved policy with an
   independently trusted pre-compromise time.
4. A publisher-supplied timestamp is insufficient for key validity or revocation.
5. For Batch B, implement the trust interface and injected test keys only. No production key
   is generated, installed or activated by this work package.

## Decision I — Independence

Ratified:

1. The Fieldbook producer and the Nirnay verifier are separate implementations. No shared
   validator, serializer, digest or rights crate is used; the only shared artifacts are the
   schema and the conformance vectors.
2. The final schema must carry an exact version, a registered digest, strict unknown-field
   handling and conformance vectors. A schema that merely compiles is not a verified release.
3. The design's path-traversal rejection, symlink protection, exact-file-set verification and
   first-refusal admission rules are preserved unchanged.

## Implementation and gate consequences

- This record ratifies semantics. It does not implement a serializer, a verifier, a registry,
  a publication journal or a schema artifact. No state is promoted to `Verified` by this
  record.
- Batch B is limited to the trust interface with injected test keys, the schema/vector work
  needed for strict validation and the independent producer and verifier implementations
  required by paired work orders. No production key and no live release are created.
- The design document records these decisions in a prominent approved-amendment section; its
  historical design text is retained as history. The conformance matrix records the decision
  references without promoting implementation states.

## Preserved approvals and freeze

- D0/D1/D2 approved digests, all v1 historical digests and the separate consumer-use
  **Proposed** status are preserved exactly.
- Rights remain `UNKNOWN`, dataset acceptance stays `BLOCKED`, budget stays INR 0, collection
  stays `DISABLED`, experiments stay `BLOCKED`, live execution stays `DISABLED` and D11 stays
  strict.
- No provider contact, market-data download, scraper, collector execution, synthetic market
  observation, adapter, rights grant, dataset, release, India implementation or experiment is
  authorised here.

## Effect on registries

`NDC-REGISTRY.md`, `ADR-REGISTRY.md`, `ENGINEERING-DOC-DIGESTS.json`, the conformance design,
the conformance matrix, `engineering/evidence/REVIEW-LOG.md` and the workspace README are updated to register this
decision and its amendment. Historical ADRs are not renumbered and no approved byte is
rewritten.
