# NDC-D1-AMENDMENT-001 — Approved amendment to D1

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **Approved 2026-11-24** by owner ratification
`engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md`
(Decision A). This is a new revision document with its own digest and date. It does not edit,
reformat or re-digest the approved D1 bytes.

## 1. Target and preservation

| Item | Value |
|---|---|
| Amended document | D1, Fieldbook NDC v2 producer requirements |
| D1 approved path (unchanged) | `fieldbook:engineering/ndc-producer-requirements-v2-proposed.md` |
| D1 approved SHA-256 (unchanged) | `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c` |
| Amendment date | 2026-11-24 |
| Authority | WS-NDC-2026-11-24-002, Decision A |
| Sections amended | D1 §5.8 (`digests`) and D1 §7.2 (`Canonical bytes`) |

D0 (C0 semantic model, `3dace660c362e683790ba7e56a785ded8af836abda36f6eab06ed284de49eed2`)
and D2 (Nirnay NDC v2 consumer requirements,
`22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957`) keep their approved
bytes and digests. The separate consumer-use document
`nirnay:engineering/ndc-consumer-use-v2-proposed.md` (`4b9d1fe7…`) remains **Proposed** and is
not an authority for this amendment. No approved byte is edited to make this amendment
consistent.

## 2. Amendment text

### 2.1 Complete-manifest digest (amends D1 §5.8)

1. Let `M` be the complete parsed `manifest.json` object. Let `H_M = SHA256(JCS(M))` over the
   RFC 8785 canonical bytes of the complete manifest.
2. The manifest does **not** contain its own digest. No property is removed, excluded,
   blanked, replaced by a placeholder or otherwise withheld from canonicalization. Any rule
   that excludes `digests.manifest_sha256` or any other property from the signed bytes is
   removed.
3. `manifest_sha256` lives **only** in the detached sidecar `signature.json`. The sidecar has
   exactly these five members: `schema_version`, `algorithm`, `key_id`, `manifest_sha256`,
   `signature_b64`. No `domain` member and no other field is added to the sidecar.
4. The manifest retains `publication_identity.publisher_identity`,
   `publication_identity.signing_key_id` and `publication_identity.signature_reference`.
5. Signing: `S = Ed25519.Sign(K_private, D || H_M)` where
   `D = UTF8("NDC-V2-RELEASE-MANIFEST-SHA256-V1") || 0x00`.
6. Verifier order: parse the complete manifest; reject duplicate JSON property names; strict
   schema validation; produce RFC 8785 canonical bytes; SHA-256; compare with the sidecar
   digest; resolve the trusted public key; verify Ed25519; bind the sidecar `key_id` to the
   manifest publisher and signing key; continue. There is no partial verification.

### 2.2 Canonical bytes (amends D1 §7.2)

RFC 8785 JCS applies to the complete manifest object. No property-removal rule applies. The
detached sidecar is outside the canonicalized bytes and never enters `H_M`. Duplicate JSON
property names and unknown fields fail closed under strict schema validation.

### 2.3 Artifact digests (amends D1 §5.8)

`digests.artifact_digests[]` is removed. The `digests` section retains `data_sha256` and
`digest_algorithm`. Per-artifact stored and uncompressed digests live only in the `artifacts[]`
descriptors defined by Decision C of WS-NDC-2026-11-24-002. There is no second, redundant
artifact inventory.

## 3. Effect and non-effects

- This amendment is normative for NDC v2 Release Serialization Profile 1 only. It changes no
  semantic requirement outside the sections named above.
- It creates no schema artifact, no serializer, no verifier, no release, no dataset, no
  admission receipt, no key and no right. No production signing key is generated or activated.
- Publisher integrity still proves publisher-key control and integrity of the exact signed
  bytes only. It does not prove source authenticity, coverage, a right or a dataset
  entitlement.
- Rights remain `UNKNOWN`, dataset acceptance stays `BLOCKED`, collection stays `DISABLED`,
  experiments stay `BLOCKED`, live execution stays `DISABLED`, budget remains INR 0 and D11
  remains strict.
- No source implementation, provider contact, data collection, India implementation or
  experiment is authorised by this amendment.
