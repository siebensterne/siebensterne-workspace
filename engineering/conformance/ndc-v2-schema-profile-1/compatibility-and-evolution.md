# Canonical NDC v2 Profile 1 — compatibility and evolution

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: normative companion to the B8 canonical schema package, 2026-11-24. Authority:
`engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` sections 3, 13
and 14 (digest
`417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119`). This record changes no
approved byte and claims no implementation state.

## 1. Strictness baseline

For this schema version the following are rejected, not repaired:

- **Unknown fields.** Any member not declared in the relevant object schema fails. There are no
  unversioned extensions, no `x-` escape hatch on the wire and no unknown PROV or payload member.
- **Missing required fields.** Every object level has an explicit `required` array. No field is
  optional by omission; nothing is defaulted, inferred or back-filled from another section.
- **Wrong JSON types.** A decimal-string instant is not replaced by a JSON integer and a JSON
  integer is not coerced to a string. A tagged ordering object with the wrong `kind` value, a
  bare-string ordering profile, a string where a typed operation or grant is required, and a
  numeric `compression_version` all fail.
- **Implicit coercions.** No silent unit change, no float for a count, byte size, instant or
  exact decimal, no rounding of a fractional or exponent token, no widening of an enum, and no
  acceptance of a placeholder such as `UNKNOWN`, `ALL`, `NONE`, `null` or an empty string where a
  required identifier is declared.
- **Duplicate properties.** Repeated JSON member names fail at parse time, including a duplicate
  root `contract_version` and a nested `schema_versions.contract_version`.

A schema version that merely compiles is not a verified release. Structural validation must be
paired with the semantic constraints and the canonical vectors on both sides.

## 2. Versioning model

- This package is version 1 of the canonical NDC v2 Profile 1 wire schema. Its identity is the
  single `SCHEMA-PACKAGE-DIGEST` printed by `scripts/check_ndc_schema_package.py` over the sorted
  `(path, sha256)` list of every file indexed in `VECTORS.md`, with an explicit domain prefix.
- Evolution is by an explicit new registered schema version with its own digest and its own
  dated record. An unregistered version fails closed; no consumer may guess a mapping from an
  unknown version.
- The exact schema version is carried on each versioned wire document: `schema_version` on the
  manifest and on the sidecar, `envelope_schema_version` on each record envelope. A mismatch
  between a record envelope and the manifest's declared envelope version fails the release.
- Per-event-type payload versions are declared in the versioned payload schema registry with an
  explicit schema id, schema version and registered digest. A manifest-wide scalar or a silent
  positional array is not a valid substitute. Adding a new event type requires a new registered
  entry; an event type with no entry fails closed.
- Registered compression identifiers, resource-policy versions and trusted-key registry
  revisions are versioned outside the release bytes and are referenced, not supplied, by a
  release. The out-of-band trust root is not part of this package.

## 3. Version bump rules

1. **Patch of documentation only** (wording, added cross-reference, clarified constraint text
   with no wire effect): new dated document revision and re-digest of the package; the wire
   schema version stays 1. Structural checks and vectors are re-run unchanged.
2. **Wire-compatible addition** (a new registered event-type payload entry, a new registered
   compression identifier, a new registered key purpose): new registry revision and its own
   digest, plus a package re-digest if any indexed file changes. No existing member changes
   meaning, type or position, and old documents still validate and carry the same semantics.
3. **Breaking change** (section 4): new major schema version with a new package digest, a new
   dated ratification record, updated vectors and a paired producer/verifier adaptation. The
   old version remains registered as historical; no approved or historical digest is rewritten.

In every case producer and verifier move in lockstep against the same versioned schema and
vectors. No wire-compatibility claim may be made before paired cross-execution against the
new package.

## 4. What is a breaking semantic change

A change is breaking when it can alter canonical bytes, validation outcomes or the meaning of a
valid document. The following are breaking and require a new major schema version:

- renaming, removing or adding a required member at any object level, or changing a `required`
  array so that a previously rejected document is accepted;
- changing an identifier grammar, an instant grammar, the u64 or 2^53 numeric rule, the
  `invalidated_at_time` UTC grammar, the SHA-256 literal, the signing-domain literal or the
  RFC 8785/JCS canonicalization rule;
- changing a tagged-union discriminator, its closed `kind` set, the member set of any ordering
  mode, or the byte-derived ordering-key derivation rule;
- changing how the manifest digest or dataset digest is computed, or where the manifest digest
  is carried (the digest must remain in the detached five-member sidecar only);
- widening or changing a closed enum: producer action vocabulary, `PERMIT`/`DENY`, coverage
  verdict, coverage dimension id, publication state, compression method or key state;
- changing a structured grant, attestation, operation, operation-evidence or coverage member
  set, or accepting an opaque string where typed evidence is required;
- changing rights separation, key trust, resource-policy enforcement or receipt semantics, or
  making a previously fail-closed condition permissive;
- changing lineage revision semantics, predecessor representation, time-axis rules or cycle and
  regression rejection;
- relaxing strictness in any way: adding a default, permitting an unknown field, allowing a
  coercion, allowing a duplicate member or permitting an unversioned extension.

Wording clarifications that do not change validation, canonical bytes or meaning are not
breaking; they still receive a new dated revision and package digest.

## 5. Preservation and non-claims

Approved D0, D1, D1-amendment, D2 and Profile 1 digests and all v1 historical digests remain as
registered. The separate consumer-use proposal remains **Proposed** and is not an authority.
Freeze unchanged: rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection
`DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11 strict. This package creates no
release, dataset, admission receipt, key, right, provider contact, collection, India
implementation or experiment. It claims none of `SCHEMA_CONFORMANT`, `CROSS_EXECUTED`,
`CRYPTOGRAPHICALLY_VERIFIED`, `RIGHTS_ADMITTED` or `DATASET_ACCEPTED`.
