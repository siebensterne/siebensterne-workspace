# NDC v2 conformance vectors — index

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: workspace evidence package for WP-5 / WS-NDC-INT-001. These files are abstract,
non-market examples and described mutations. Nothing here is a release, a signed artifact, a
right, a dataset acceptance or an executed cross-repository verification. No signing secret is
included. The Ed25519 file carries a public key and a published signature only.

Source of truth: NDC v2 Release Serialization Profile 1 (ratified 2026-11-24, digest
`fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc`) and the approved D1
amendment (digest `a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894`).
Implementation authorities are the typed structs at Fieldbook `2ef88a955f74a7c88e4573683267446e331465e9` and Nirnay `2dad4962b584c557237d219c1c5356fc58bc4b69`.

## Vector inventory

| Vector file | SHA-256 | Purpose | Evidence references |
|---|---|---|---|
| `jcs-canonicalization.json` | `6c59d61de2abb529ec05f76dd0cc20e0d7e47bfbe6c550d42eb7ce659e9a9d49` | RFC 8785 number samples, UTF-16 member order and control escaping | `nirnay:crates/release-verifier/src/jcs.rs::rfc8785_number_vector`, `nirnay:crates/release-verifier/src/jcs.rs::member_order_is_utf16_not_utf8`, `fieldbook:src/distribution/ndc_release.rs::jcs_rfc8785_property_sorting_vector` |
| `ed25519-test-key-public.json` | `ff15f4cb724e9f657739c7e21ade2129dbf2fabcdf1b759800e2ddf4d170225a` | RFC 8032 section 7.1 first test case: public key, empty message and published signature | `nirnay:crates/release-verifier/tests/verifier.rs::signature_byte_mutation_is_refused`, `fieldbook:src/distribution/ndc_release.rs::injected_key_signature_verifies` |
| `manifest-example.json` | `b1748cb45715f45f493bb1be87c4841a680fd0de9c85ecf69b9255f48387fa67` | Canonical manifest example with arbitrary strings and digest placeholders; canonical member order and no trailing line feed | `fieldbook:src/distribution/ndc_release.rs::manifest_bytes_are_deterministic_and_self_digest_free`, `nirnay:crates/release-verifier/tests/verifier.rs::manifest_self_digest_field_is_refused` |
| `sidecar-example.json` | `d0d10c18b006a07bc487eaaa44544c01bab1e303948f9cc9af99ccc7ad410f6c` | Five-member sidecar shape; `manifest_sha256` binds the exact bytes of the manifest example; `signature_b64` is a zero-byte placeholder and not a valid signature | `fieldbook:src/distribution/ndc_release.rs::sidecar_has_exactly_five_fields`, `nirnay:crates/release-verifier/tests/verifier.rs::sidecar_extra_field_is_refused` |
| `adversarial-manifest-sidecar.json` | `4377e8b485e24a8cb89349d3f9f260720017dd554b48c3559d3c3519cb97127b` | Described manifest mutation, sidecar digest mutation and repeated JSON member | `fieldbook:src/distribution/ndc_release.rs::jcs_rejects_duplicate_property_names`, `nirnay:crates/release-verifier/tests/verifier.rs::manifest_mutation_after_signing_is_refused` |
| `adversarial-paths-artifacts.json` | `62b05e4f42adc75e6f4327ec2900f57e4f33de1f0dd558e7b29fb73d854925d8` | Described traversal string, symlink descriptor, missing artifact and repeated sequence position | `fieldbook:src/distribution/ndc_release.rs::traversal_path_is_rejected`, `nirnay:crates/release-verifier/tests/verifier.rs::symlink_escape_is_refused` |
| `adversarial-policy-cases.json` | `6c8c590e2f0ae5e92abf31afe75daf5da817fda55556304c090a283e542d98c9` | Described correction cycle, absent denominator and UNKNOWN injected rights decision | `fieldbook:src/distribution/ndc_release.rs::lineage_cycle_is_rejected`, `nirnay:crates/release-verifier/tests/verifier.rs::rights_unknown_is_refused` |

## Checker contract

`scripts/check_ndc_conformance_vectors.py` verifies each listed digest against the file bytes,
scans this index for secret material and rooted or upward path literals, and checks every
`fieldbook:` or `nirnay:` test token against the named source file in a local clone when that
clone is present at the recorded head. Absent clones produce an explicit skip, not a pass.

The manifest example is a hand-written canonical shape example, not output of the Fieldbook
producer. The sidecar example is a shape example with a placeholder signature. No producer
binary generated these files and no Nirnay verifier binary consumed them. Cross-execution is
recorded as NOT_STARTED in the acceptance matrix; this index does not claim it.
