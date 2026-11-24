# Canonical NDC v2 Profile 1 schema package — index and digests

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: version 1 of the language-independent canonical NDC v2 Release Serialization Profile 1
schema package, published by work package B8 on 2026-11-24. Authority:
`engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` (RATIFIED by
owner direction 2026-11-24, digest
`417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119`), together with
`WS-NDC-2026-11-24-002` (Decisions A–I) and the 102-row WP-B6 field-level reconciliation.

This package is documentation and canonical abstract evidence only. It is not a serializer, a
verifier, a shared validator, a runtime crate, a release, a dataset, a right or an executed
cross-repository check. No signing secret, no external observation and no private key material
is present. The Ed25519 vector carries a public key and a published signature only. The
manifest example is a hand-written canonical wire shape, not producer output; the sidecar
example carries a placeholder signature. Structural validation alone is insufficient: see
`semantic-constraints.md`.

The single package identity is the `SCHEMA-PACKAGE-DIGEST` printed by
`scripts/check_ndc_schema_package.py` over the sorted `(path, sha256)` list of the 26 files
below, with the explicit domain prefix `NDC-V2-PROFILE-1-SCHEMA-PACKAGE-DIGEST-V1`. The index
itself is not listed, so the digest is not circular.

## File inventory and SHA-256

| File | SHA-256 | Kind | Purpose |
|---|---|---|---|
| `compatibility-and-evolution.md` | `401c7bedd388c56f200e6b3c609669b862898b910389a7b27a526ae37e3f827f` | doc | strictness baseline, version bumps, breaking semantic changes, preservation |
| `coverage.schema.json` | `52869fa41e57665311d390f3e3eacba7dd76d3f456070f2b3bf3e693b399c12d` | schema | typed nine-dimension coverage evidence, required denominator, typed gaps |
| `lineage.schema.json` | `00638d9ad8408a2707aba20e891240e24a640bc95bde30219b6910a884565a92` | schema | complete PROV lineage, seven-member immediate-predecessor supersedes, UTC invalidation grammar |
| `manifest.schema.json` | `1f7edaa7b4f332cb26291e5807d4ae8a61654c44ce7a61a5cb5d78b099302119` | schema | complete canonical manifest; one root `contract_version`; strict objects; sole `artifacts[]` inventory |
| `ordering-profiles.schema.json` | `438cb040a1429c6b255c70620963f93233223bbe39a3e1af8407e43de07aff00` | schema | artifact-level tagged profile and per-record tagged ordering union |
| `payload-schema-registry.schema.json` | `690710109fd2f0031811d1b3761ff9e5bf874c8e8498ecfe016c8071120d523f` | schema | versioned per-event-type registry with explicit identity, version and digest |
| `record-envelope.schema.json` | `736baec9be427a87c7985fa0e0cfbd512107df00d28a88fb0ca2b75480970ab8` | schema | canonical record envelope; exactly one ordering mode; byte-derived key rule |
| `rights-evidence.schema.json` | `51e9fc8259b9f9be0f212fd6b19e5763bed93d1f9e2fc5c1941595fe3b039f57` | schema | full typed source-rights evidence, separate from consumer authorization |
| `semantic-constraints.md` | `a6a5fcd61f0778a95fa2afbfba53581abf547468101288eb6cbc171e639ba01c` | doc | cross-field rules the JSON Schema cannot express; five distinct status states |
| `signature-sidecar.schema.json` | `91b3dde913ea65665d576ac09b19521a2e94fc733e2b8257b90cad46a5eb7aab` | schema | exactly five sidecar fields; no manifest self-digest |
| `vectors/adversarial-manifest-sidecar.json` | `f8ec5033ddf27e78cc996f07efcc3eb3ca9487cfcee70a5d160fc4688e63cc2d` | vector | adapted manifest mutation, sidecar mutation, duplicate member, self-digest, limits, key binding |
| `vectors/adversarial-paths-artifacts.json` | `c41886803fd9af92d983fbde76801a1b27d59c2e17f1607474b01909a0dc5698` | vector | adapted traversal, symlink, missing and extra artifact, duplicate pair, codec, dataset digest |
| `vectors/adversarial-policy-cases.json` | `e99deade048b2f85f1ef461e3c18abd541769c6603a40d86cb5d778fc840b6fa` | vector | adapted cycle, absent denominator, unresolved rights, time and correction cases |
| `vectors/byte-derived-ordering-key.json` | `d7f76473b285470b3ba8fd8d84fd82e5e654a01f9d8c07db37f7171bb6e9f937` | vector | key recomputation and caller-supplied key mismatch rejection |
| `vectors/complete-lineage.json` | `012eb608094afd05a5a46064a80cff5aced3c92eaeddebbfbbef57b4958cf94c` | vector | full PROV relations, immediate-predecessor revision, cycle and grammar rejections |
| `vectors/coverage-denominator.json` | `9c944c34eeadef743b1e0b0fdde21c6551b33ece9185a6281d972cac417cc2b7` | vector | disjoint exhaustive arithmetic, no PASS without denominator, nine-dimension rule |
| `vectors/duplicate-contract-version.json` | `54cf3eb3d4a43c436655e640859a7d6f4c4ffbe111b14eef43e89ba84a7b42b4` | vector | single root contract version; nested and duplicate member rejection |
| `vectors/ed25519-test-key-public.json` | `df1926a11e0f6b0c736b5c6c59935ed477a69a69c689566f0c8f9ecb9b987683` | vector | adapted RFC 8032 public test case and trusted-key lifecycle cases |
| `vectors/jcs-canonicalization.json` | `8291569888b1b3a61568f164e0771befb2d56aacb63e77c3667916d62b63adba` | vector | adapted RFC 8785 number, ordering, escaping and numeric-bound cases |
| `vectors/manifest-example.json` | `b9605b0efa175eed7a7babb798b7ea57793d08ce723d818816d76cd850b7f3a0` | vector | canonical manifest example; arbitrary strings and digest placeholders |
| `vectors/payload-schema-registry.json` | `41ac2e29a7e998d604800d3843785089ce31c6465d4fc9347506242eeaee23f8` | vector | per-event-type registry accept, scalar and silent-array reject, digest binding |
| `vectors/required-venue-segment.json` | `5f6b551807b36a6281b323c73c5999d4dcda63d31971e7eea7d3c848512f1b68` | vector | required venue, segment and other scope identifiers; placeholder rejection |
| `vectors/sidecar-example.json` | `de8365c4024e489f59dc88bc98bdcbc1cdfd6d7ac28b7d1f60e12bcc099f453d` | vector | five-member sidecar; digest binds the exact bytes of the manifest example |
| `vectors/tagged-ordering.json` | `6addddcb6cdc3268e53bbbb59d6274edf127d76155c2b135cb5163ce8fdee43a` | vector | both profiles, mutual exclusivity, mode match, visible gaps, no event-time fallback |
| `vectors/typed-operation-evidence.json` | `3ac4977fbedca60e26e1ec4beba45852f2c1e28fe8ff071d85ae13c5cd8287a1` | vector | structured operations; duplicate, missing, reassigned and unbound evidence |
| `vectors/typed-rights-evidence.json` | `27ad9e40531d159da6f166bc50f663a46e5178c24d0178966aa488d63c39059e` | vector | typed grants, DENY, granting authority separation, attestation is not permission |

## Vector provenance

The seven vector files carried over from `engineering/conformance/ndc-v2-conformance-vectors/`
are `jcs-canonicalization.json`, `ed25519-test-key-public.json`, `manifest-example.json`,
`sidecar-example.json`, `adversarial-manifest-sidecar.json`,
`adversarial-paths-artifacts.json` and `adversarial-policy-cases.json`. Each was copied and
adapted to the ratified canonical wire representation; the originals in the WP-5 directory are
unchanged. Nine further vectors cover the additional field-level discrepancies: required venue
and segment, typed rights, typed operation evidence, coverage denominator arithmetic and
no-PASS-without-denominator, complete PROV lineage and predecessor revision, tagged ordering,
byte-derived key mismatch rejection, duplicate `contract_version` rejection and the payload
schema registry.

## Checker contract

`scripts/check_ndc_schema_package.py` verifies every digest in this index against file bytes,
parses every JSON file, checks every schema for `additionalProperties: false` at object levels
and explicit `required` arrays, scans vector files for secret and external-observation patterns,
and prints one reproducible `SCHEMA-PACKAGE-DIGEST` over the sorted `(path, sha256)` list with
the domain prefix stated above. Absence of a listed file, a digest mismatch, a parse failure or
a pattern hit fails the checker. No producer or verifier binary consumes these files here;
cross-execution remains NOT_STARTED.
