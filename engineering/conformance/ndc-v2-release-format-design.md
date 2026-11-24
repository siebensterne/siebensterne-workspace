# NDC v2 release format design — W2.1 D

<!-- SPDX-License-Identifier: Apache-2.0 -->

**Status: DESIGN ONLY.** This document specifies an NDC v2 release format. It is not a
ratified schema, not an approved contract revision and not an implementation record. The
manifest serializer, canonicalization routine, artifact writer and full release verifier are
**not implemented** at Fieldbook e0472f7 or Nirnay f1f8a8a. No code, provider contact,
collection, dataset, release, admission receipt, experiment, live route or right is created
by this document.

**Authority.** Semantics come from the Approved documents D0 (C0 semantic model,
`3dace660c362e683790ba7e56a785ded8af836abda36f6eab06ed284de49eed2`), D1 (Fieldbook
producer requirements, `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c`)
and D2 (Nirnay consumer requirements, `22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957`),
and from Decision B of `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md`.
Sections D0 §5/§5.1/§8, D1 §5/§7/§9 and D2 §3/§4/§5/§6 bind the semantics. Field names
identified below as design additions require a separately approved schema revision before
any serializer or verifier is written; they are not silently added to the approved bytes.

**No technology choice.** No transport, broker, queue, database, shared crate, vendored
client, connector, collector or storage engine is selected. A release is a set of immutable
files in a filesystem namespace; how that namespace is reached is outside this design. Each
repository keeps its own validator. Fieldbook publishes; Nirnay verifies an immutable
release and keeps no competing raw archive.

## Approved amendment — NDC v2 Release Serialization Profile 1 (ratified 2026-11-24)

**This section is normative and governs over conflicting choices in the historical design
below.** Owner ratification
`engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md`
(status **RATIFIED 2026-11-24**, Decisions A–I) approved NDC v2 Release Serialization Profile 1.
The D1 circularity change is the separately approved revision
`engineering/conformance/NDC-D1-AMENDMENT-001.md` (approved 2026-11-24,
SHA-256 `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894`); D1's approved
bytes and historical digest are unchanged.

| Design section | Superseded design choice | Ratified Profile 1 rule |
|---|---|---|
| §2.1 | Remove `digests.manifest_sha256` before canonicalization; sign `JCS(M′)` | Decision A: `M` is the complete manifest, `M = JCS(manifest.json)`, `H_M = SHA256(M)`; no digest-exclusion rule; digest only in the sidecar |
| §2, §3 | Manifest `digests.manifest_sha256`, `digests.artifact_digests[]`, `limits` and `record_order`; sidecar `domain` member | Decisions A/C/B/F: digest only in sidecar with exactly five fields; `artifacts[]` sole inventory with fixed descriptors; per-artifact `record_order_profile`; no manifest `limits`; sign with `D = UTF8("NDC-V2-RELEASE-MANIFEST-SHA256-V1") || 0x00` |
| §4 | Event-time-first order key (`source_event_time_ns` first) and a single global deterministic order | Decision B: `K_sequence = (sequence_domain_id, sequence_epoch/session-reset identity, sequence_number)`; `K_reference = (object_id, revision, knowledge_time, assertion_id)`; no event-time fallback, no fabricated sequences, no cross-domain comparison, gaps stay visible |
| §5 | Numeric maxima table as design policy values | Decision F: no manifest `limits`; versioned normative consumer resource policy enforced independently by producer and verifier; numerical maxima set only after workload qualification; no numbers invented here |
| §7 | `lineage.corrections[]` array | Decision E: one canonical `lineage.supersedes` with one immediate predecessor and PROV `wasRevisionOf`; arrays only for genuine multi-predecessor releases |
| §8 step 3 | "lock plus a no-overwrite existence check" alternative | Decision G: atomic no-replace rename only, sibling staging on the same filesystem, file and directory sync, parent-directory sync, durable receipt, uncertain-publication recovery; no existence-check-then-rename |
| §10 | "No key issuance, rotation, custody or revocation channel is defined here" | Decision H: out-of-band trusted publisher registry with key states and revocation evidence; Batch B implements the trust interface and injected test keys only, no production key |
| §11 | Status table recorded at the design heads | Unchanged as history; the conformance matrix carries the Profile 1 decision references. Ratification promotes no implementation state to `Verified` |

The path rules in §1, the RFC 8785 JCS rules in §3, the byte-level rules in §5 and the
verification/use race policy in §9 are **preserved** under Decision I, except where the
table above records an amendment. Nothing in the historical sections below is rewritten; where
they conflict with Profile 1, Profile 1 governs. No serializer, verifier, key, release,
dataset, right, provider contact or experiment is created by this section.

## 1. Release directory and artifact paths

A release is one directory containing exactly one manifest, one detached signature sidecar
and the declared artifact files. The directory name is the `release_id`.

```text
<release_root>/<publisher_id>/<dataset_id>/<release_id>/
├── manifest.json
├── signature.json
└── artifacts/
    ├── events.jsonl
    └── events.jsonl.zst
```

Path rules (all mandatory and checked before opening any file):

1. `publisher_id`, `dataset_id` and `release_id` each match `^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$`
   and are case-sensitive. `release_id` is new for every correction.
2. Artifact paths are repository-relative POSIX strings beginning `artifacts/`. Each
   component matches `^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$`. No other directory depth is
   declared. `manifest.json` and `signature.json` are reserved names at the release root.
3. Normalization is Unicode NFC over UTF-8 with `/` separators. A path containing `\`, NUL,
   an absolute prefix (including a drive letter), a `.` or `..` component, a trailing `/`,
   a duplicate separator or any character outside the component alphabet is malformed.
4. Two declared artifact paths that are equal after NFC normalization are duplicates. The
   manifest MUST declare each artifact at most once; the verifier MUST reject duplicate
   normalized paths even if the raw strings differ.
5. No artifact path may resolve outside the release root. Symlink components and symlink
   targets are rejected (§9).
6. The exact expected file set is `manifest.json`, `signature.json` plus each declared
   artifact path. No extra, missing or undeclared file is permitted (§9).

The example layout shows one artifact in two encodings; a real release declares exactly the
files it publishes. The artifact set is never inferred from directory contents.

## 2. Exact manifest content

`manifest.json` is one UTF-8 JSON object. Property names are unique. Exact financial
decimals and arbitrary-precision integers are JSON strings, never IEEE 754 numbers. NaN,
Infinity, lone surrogates and comments are not permitted. The object has these members:

| Member | Required content |
|---|---|
| `schema_version` | positive integer `1` for this design; a schema-version change follows §7 |
| `contract_version` | exact contract major/minor, for example `v2` |
| `contract_revision` | reviewed contract revision string bound to the approved D1/D2 digests |
| `release_identity` | `release_id`, `release_version`, `as_of_ns` (positive epoch ns), `publication_state`, `created_at_utc_ns` |
| `source_scope` | `provider_id`, `source_product_id`, `venue_id`, `segment_id`, `dataset_id`; an absent venue is a denial |
| `producer_activity` | exactly `performed_operations[]` (action enum value plus object kind, id and version) and `operation_evidence[]` (event id, run id, UTC instant, decision key, digest); no permission, grant, purpose, licensee, recipient, coverage verdict or signature |
| `rights` | `permission_grants[]` (grant id, enum action, object class, `PERMIT`/`DENY`, actor, licensee, recipient class and identity, scope, validity, delivery, typed retention), `document_references[]` (reference, clause, lowercase hex document digest, contract revision, review date, authority), `reviewed_attestations[]` (exact purpose string, usage right, usage mode, territory, scope assertions, reviewer, authority) |
| `coverage` | `dimensions[]` with exactly nine reports (instrument, listing/identity, contract, corporate action, calendar/session, trades, quotes/depth, MBO, sequence continuity), each with named universe, denominator identity and value, count basis, `as_of_ns`, numerator, missing and rejected counts, gaps, verdict and evidence reference |
| `lineage` | raw archive reference and SHA-256, transformation record, `wasDerivedFrom`/`wasRevisionOf`/`hadPrimarySource`/`generatedAtTime`/`invalidatedAtTime` relations, qualified attribution, `revision`, `knowledge_time_ns`, `corrections[]` (§8) |
| `schema_versions` | `contract_version`, `normalizer_version`, `payload_schema_version`, `envelope_version` |
| `digests` | `manifest_sha256`, `data_sha256`, `digest_algorithm` (`sha256`), `artifact_digests[]` (one entry per declared artifact with path, `stored_sha256`, `uncompressed_sha256`, `stored_bytes`, `uncompressed_bytes`, `record_count`) |
| `publication_identity` | `publisher_identity`, `signing_key_id`, `signature_reference` (`signature.json`), `archive_reference` |
| `artifacts` | one entry per artifact: `path`, `encoding`, `compression`, `compression_version`, `stored_bytes`, `uncompressed_bytes`, `stored_sha256`, `uncompressed_sha256`, `record_count` (**design addition, approval required**) |
| `limits` | declared maxima reproduced from §5, so the verifier can reject a manifest whose own claims exceed the policy (**design addition, approval required**) |
| `record_order` | declared `boundary` (`LF`) and `order_key` (§4) (**design addition, approval required**) |

`corrections[]`, `artifacts[]`, `limits` and `record_order` are design additions to the
section list in D1 §5. They are needed to make a release byte-verifiable but are not part of
the approved D1/D2 requirement bytes. A separate owner-approved schema revision is required
before they may be emitted or consumed.

Dataset-wide facts appear once in the manifest. Event-envelope facts (source and instrument
identity, typed payload, source and receive times with clock domain, sequence and
continuity, raw digest, lineage reference, revision and as-of information) stay in the event
envelope and are not duplicated into the manifest.

### 2.1 Self-referential manifest digest

D1 §5.8 declares `digests.manifest_sha256` inside the manifest as the SHA-256 over canonical
manifest bytes. A literal self-inclusive digest is not computable. This design resolves it
as follows:

- Let `M` be the parsed manifest object.
- Let `M′` be `M` with the single property `digests.manifest_sha256` removed. No other
  property is removed; the signature is already outside `M`.
- `signed_bytes = JCS(M′)`; `manifest_sha256 = SHA-256(signed_bytes)`.
- The signed message is `DOMAIN || manifest_sha256` where
  `DOMAIN = b"NDC-V2-RELEASE-MANIFEST-SHA256-V1\x00"` (§3).

The removal is of the self-referential digest member only, not of a signature property, and
does not change the ratified rule that the sidecar is outside the canonicalized bytes. The
alternative (keep D1's field list untouched and carry `manifest_sha256` only in the
sidecar, as Nirnay's own-dataset publication does) is recorded here as an option; adopting
it needs an approved revision, not an implementation choice made by a serializer author.

## 3. Signed bytes and detached sidecar

Canonicalization is RFC 8785 JSON Canonicalization Scheme applied to `M′` from §2.1:

- I-JSON subset; no duplicate property names; Unicode strings preserved as-is;
- no whitespace between tokens; recursive property-name sorting by UTF-16 code units;
- array order preserved, so every semantically unordered set (rights grants, coverage
  dimensions, artifact entries, correction links) has the deterministic order declared in
  this design before canonicalization;
- UTF-8 output; exact decimals and large integers are JSON strings;
- NaN, Infinity and lone surrogates terminate the operation;
- the sidecar is never part of `signed_bytes` and never enters `manifest_sha256`.

Signing and verification:

- Algorithm: Ed25519; key resolved from `signing_key_id` in the trusted publisher registry.
- Message: `DOMAIN || manifest_sha256` (32-byte digest, domain prefix above), so a signer
  with a 4096-byte raw-message limit can sign a large manifest.
- Verifier: recompute `JCS(M′)`, recompute the digest, compare with the sidecar
  `manifest_sha256` and the manifest `digests.manifest_sha256`, then verify the signature
  with the public key bound to `publisher_identity`. Unknown, malformed, expired or revoked
  key fails closed. There is no partial verification.
- Non-claim: this proves publisher-key control and integrity of the exact signed bytes. It
  does not prove source authenticity, coverage, a right, a dataset entitlement or the truth
  of any observation.

`signature.json` is a detached UTF-8 JSON object with exactly these members:

| Member | Rule |
|---|---|
| `schema_version` | integer `1` |
| `algorithm` | literal `Ed25519` |
| `key_id` | non-empty string equal to `publication_identity.signing_key_id` |
| `manifest_sha256` | lowercase 64-hex digest of `signed_bytes` |
| `signature_b64` | standard base64 with padding of the 64-byte Ed25519 signature (88 characters ending `==`) |
| `domain` | literal `NDC-V2-RELEASE-MANIFEST-SHA256-V1` (**design addition, approval required**) |

The sidecar is written with one trailing LF; its own canonical form is not part of the
signed bytes. Unknown fields in the sidecar are rejected. A base64 decode failure, a wrong
key id, a digest mismatch or a failed signature terminates verification.

## 4. Record boundary and deterministic order

An artifact is a newline-delimited JSON stream: one canonical JSON object per line,
UTF-8 without BOM, no CR, no blank line, and one LF (`0x0A`) after every record including
the last. A record boundary is that LF byte; a truncated final line is incomplete.

Data digest: `data_sha256 = SHA-256( concat( JCS(record) || 0x0A for every record in the
declared order ) )`. The record count is declared per artifact and must equal the number of
boundaries read.

Deterministic order key, ascending by unsigned byte comparison of each component:

1. `source_event_time_ns` as 16-byte big-endian unsigned (resolution and unit preserved);
2. `source_id` as UTF-8 bytes;
3. `sequence_number` as 16-byte big-endian unsigned;
4. SHA-256 of `JCS(record)` as lowercase hex UTF-8 bytes (final tie-break).

Arrival order is never the deterministic order. A duplicate order key with differing record
bytes is a publication error; the producer MUST refuse to publish and the verifier MUST
reject. Sets inside a record (instruments, fields, modalities, grants, dimensions) are
sorted by their canonical UTF-8 bytes before JCS.

## 5. Encoding, compression, digests and sizes

Each artifact entry declares:

- `encoding`: `application/x-ndjson; charset=utf-8` for event streams. Other encodings need
  a new schema version; a magic-byte sniff is not a declaration.
- `compression`: `none` or `zstd`, plus `compression_version` and the exact decoder settings
  needed for deterministic decode. No implicit decompression and no format inference.
- `stored_bytes` / `stored_sha256`: SHA-256 over the exact bytes at the artifact path.
- `uncompressed_bytes` / `uncompressed_sha256`: SHA-256 over the decoded record stream bytes
  in declared order; this is the byte sequence hashed into `data_sha256`.

Artifact digest algorithm is SHA-256 everywhere. A digest algorithm change requires a new
major contract version and a migration record (D1 §9.2).

Declared and actual maxima (design values; they are policy proposals, not measurements or
owner-approved limits):

| Quantity | Maximum |
|---|---|
| `schema_version`, sidecar size | schema version 1, `signature.json` <= 4 096 bytes |
| Manifest file size | 16 777 216 bytes (16 MiB) |
| Artifact count | 512 per release |
| Single artifact uncompressed size | 8 589 934 592 bytes (8 GiB) |
| Single artifact stored (compressed) size | 8 589 934 592 bytes (8 GiB) |
| Total declared uncompressed size | 68 719 476 736 bytes (64 GiB) |
| Total declared stored size | 68 719 476 736 bytes (64 GiB) |
| Single record (uncompressed line) | 1 048 576 bytes (1 MiB) |
| Path component length | 128 bytes after NFC |

A producer MUST refuse to publish when any *declared* value exceeds a maximum. A verifier
MUST refuse when a declared value exceeds a maximum, when `limits` in the manifest differs
from the verifier's own maxima, or when an *actual* byte count from `fstat` or the read loop
exceeds its declared value or the maximum. Exceeding a maximum is
`REJECT_ARTIFACT_DIGESTS` / `REJECT_INCOMPLETE`, never a warning. No memory is allocated from
an untrusted declared size without a prior bound check.

## 6. Schema versioning

- `schema_version` is the positive integer version of this manifest layout; `1` is this
  design. The sidecar has its own `schema_version` `1`.
- `contract_version` carries the approved NDC major version (`v2`). An unknown major
  version is rejected and requires a reviewed migration record; a new optional field does
  not change the major version.
- A renamed, removed or retyped required field, a changed verdict vocabulary, a changed
  digest algorithm, a changed canonicalization domain, a changed record boundary or a
  changed deterministic order requires a new major version and a migration record.
- An additive, optional, versioned field requires a minor revision and a published schema
  artifact with its own digest. Reporters MUST NOT silently reinterpret an unknown field
  as absent; strict parsing rejects it until the schema is revised.
- No approved D0/D1/D2 digest is edited to make a version table consistent. The design
  additions in §2 need their own approval before they become a schema artifact.

## 7. Corrections and correction links

A correction never mutates an AVAILABLE release. It produces a new `release_id` and, where
the content changed, a new identity chain:

- `lineage.corrections[]` is ordered by `revision` ascending and each link carries
  `supersedes_release_id`, `supersedes_manifest_sha256`, `supersedes_data_sha256`,
  `correction_reason`, `knowledge_time_ns`, `invalidated_at_time` and `revision`.
- `wasRevisionOf` points to the immediate prior release; `wasDerivedFrom` and
  `hadPrimarySource` keep the original raw archive reference and digest.
- The prior release stays immutable and available in lineage with its knowledge time; the
  corrected release references it rather than overwriting it.
- View selection uses one `as_of_ns` instant and `knowledge_time_ns`, never arrival order.
  A link naming a release not present in the trusted archive, a revision that does not
  strictly increase, a knowledge time after the as-of instant, or a missing digest fails
  closed as `REJECT_CORRECTION_LINEAGE` / `REJECT_PIT_CONSISTENCY`.
- A change to the release or to its rights evidence requires a new Nirnay admission
  decision; the derived research dataset chain keeps the exact release identity and digests
  of the release it consumed.

## 8. Release availability and immutability

Publication sequence (design):

1. Write manifest, sidecar and artifacts into a sibling staging directory named
   `.<release_id>.staging-<random>`, with exclusive creation, no overwrite and no
   symlink components.
2. `fsync` each file, then `fsync` the staging directory.
3. Atomically rename the staging directory to the final `<release_id>` directory with a
   no-overwrite primitive (or a lock plus a no-overwrite existence check; if neither is
   available, fail closed). The rename is the only transition from STAGING to AVAILABLE.
4. `publication_state = AVAILABLE` is declared in the manifest before publication; a
   release found in a staging directory is never available and is rejected.
5. After AVAILABLE, no file is created, modified, renamed or deleted under that release
   directory. Any correction uses a new `release_id`. A second publication attempt for an
   existing identity is rejected, not treated as an update.

Availability does not grant a right. Rights remain `UNKNOWN` and dataset acceptance remains
`BLOCKED`; an AVAILABLE release is only an immutable object that may be verified.

## 9. Verification/use race policy

The verifier treats the published tree as untrusted until every check below succeeds. It
never trusts a path string as proof of what was opened.

1. **Trusted base and path traversal.** Start from a configured trusted release root. Reject
   any declared path with NFC normalization differences from the manifest string, absolute
   prefix, drive prefix, `\`, NUL, `.`/`..` component or component outside the §1 alphabet.
2. **Symlink escape.** Walk each path component with directory-file descriptors opened with
   `O_NOFOLLOW` (or the platform equivalent). Reject any symlink component before
   resolution, any final symlink, any target that is not a regular file, and any resolved
   target outside the release root. Verify that the final descriptor's identity matches the
   component path; do not rely on a separate `realpath` that could be raced.
3. **Duplicate normalized paths.** Reject duplicate normalized artifact paths in the
   manifest, and reject two directory entries that normalize to the same path. The expected
   set is built from the manifest only.
4. **Open without following untrusted symlinks.** Open `manifest.json`, `signature.json` and
   every artifact with `O_RDONLY | O_NOFOLLOW | O_CLOEXEC` relative to the verified directory
   descriptor. Never reopen by string path after the first verification read.
5. **Hash from the opened handle.** Take `fstat` size, then stream bytes to EOF from that
   same descriptor into the SHA-256 computation. Confirm bytes read equals `fstat` size and
   equals the declared size. Compare `stored_sha256`; decode from the same verified bytes,
   compare `uncompressed_sha256`, `data_sha256`, record count and record order. A size or
   digest change between `fstat`, read and use is detected because no second path-based
   open occurs.
6. **Use the verified handle or an immutable snapshot.** All downstream reads use the
   verified descriptor. If the consumer cannot retain it, copy the exact bytes from that
   descriptor into a private staging area, re-hash the copy, and use only the private
   immutable snapshot. If neither is possible, fail closed. No downstream stage may read
   the published path again.
7. **Missing, extra or incomplete publication.** Enumerate the release directory from the
   verified directory descriptor. Reject if `manifest.json`, `signature.json` or any declared
   artifact is absent; if any extra file, staging marker, lock file or undeclared directory
   is present; if any entry is a symlink, directory where a file is required, or special
   file; or if any declared size, digest, record count or publication state is incomplete.
   There is no partial verification and no partial consumption.
8. **Ordered failure.** Stop at the first refusal and emit a typed code from D2 §3.1;
   a later check never softens an earlier failure. Close every opened descriptor on
   failure and retain no bytes from a rejected release. A rejected identity is not retried
   under the same identity; a corrected release receives a new `release_id`.

These rules are a design contract only. The presence of the path-safe research code-manifest
checker at Nirnay f1f8a8a
(`research/python/src/quantlab/experiments/reproducibility.py`, PR #138) is a partial
precedent for path validation and handle-consistent byte checks, but it verifies research
source code, not an NDC release. The NDC release serializer and verifier do not exist.

## 10. Explicit non-goals

- No transport, broker, queue, database, storage engine, shared crate or client library is
  chosen or forbidden beyond the requirement that producer and consumer keep separate
  validators and no shared runtime package.
- No key issuance, rotation, custody procedure, registry implementation or revocation
  channel is defined here; the signing-key custodian role is ratified, the mechanism is not.
- No rights evidence, source qualification, dataset acceptance, experiment registration,
  performance claim or live-readiness claim is made.
- No final NDC JSON schema artifact or digest is registered. This document is not that
  artifact and does not amend `NDC-REGISTRY.md`.

## 11. Implementation status

| Component | Status at the recorded heads |
|---|---|
| Approved semantic requirements (D0/D1/D2) | APPROVED 2026-11-23 |
| Manifest field layout in §2, including design additions | DESIGNED, approval required |
| JCS signing/sidecar rule in §2.1–§3 | DESIGNED, not implemented |
| Release serializer and artifact writer | NOT_STARTED |
| Full release verifier (signature, key, digest, envelope, race policy) | NOT_STARTED |
| Fieldbook authorization/admission runtime (separate from release format) | IMPLEMENTED / TESTED_WITH_ABSTRACT_VALUES (see conformance matrix) |
| Nirnay declaration-level preflight (separate from release verification) | IMPLEMENTED / TESTED_WITH_ABSTRACT_VALUES (see conformance matrix) |

No statement in this document promotes DESIGNED or IMPLEMENTED to VERIFIED, and no
declaration-level rejection code is evidence that a cryptographic or byte-level check ran.
