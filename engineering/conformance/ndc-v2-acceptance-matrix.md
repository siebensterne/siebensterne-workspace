# NDC v2 WP-5 acceptance matrix — producer and verifier evidence

<!-- SPDX-License-Identifier: Apache-2.0 -->

**Status:** documentation and workspace evidence only. This matrix records independent
producer and verifier implementations at exact heads. It does not execute them together,
promote an implementation state, create a release, verify a signature, grant a right or accept
a dataset. All test evidence below uses abstract scalars, arbitrary temporary bytes and
injected test keys.

**Exact heads.** Fieldbook `2ef88a955f74a7c88e4573683267446e331465e9` (PR #62 producer merged),
Nirnay `2dad4962b584c557237d219c1c5356fc58bc4b69` (PR #142 verifier merged), Workspace
`959143e8996960bfaee233e03cf40d063c47316e` (WP-2 ratified). Worktree branch
`docs/ndc-v2-conformance`. Profile ratification digest
`fb8a4992d63aabb41f02286317d1d69aeaec9a0e35836bd8ce6eff2754cb01fc`; D1 amendment digest
`a2087aff7bcadb5aae90eea3f7893ac3147e2e8cbecce9fcb9357481e7e49894`. Approved D0/D1/D2
digests and the separate consumer-use **Proposed** status are preserved in
`ndc-v2-schema-digest.json`.

**State vocabulary.** `TESTED_WITH_ABSTRACT_VALUES` means source evidence and abstract tests
were inspected at the exact head; it does not mean externally reviewed, real-data verified or
cross-executed. `IMPLEMENTED` means code is present without the named test evidence.
`NOT_STARTED` means the named capability has no implementation or no executed evidence at this
head. No `VERIFIED`, `INTEGRATED` or `PRODUCTION_READY` state is claimed anywhere in this
matrix.

**Implementation authorities at the recorded heads.** At these heads there was no standalone
published NDC v2 schema artifact; the typed structs in
`fieldbook:src/distribution/ndc_release.rs` and `nirnay:crates/release-verifier/src/schema.rs`
were the implementation authorities. See `ndc-v2-schema-digest.json`. No shared validator,
serializer, digest or rights crate exists. These heads and their evidence remain historical and
unchanged.

**Canonical wire authority (WP-B8, 2026-11-24).** The normative wire representation for the
checks below is now the versioned canonical schema package at
`engineering/conformance/ndc-v2-schema-profile-1/`, ratified by
`WS-NDC-2026-11-24-003` (digest
`417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119`) and published as 26 files
(8 JSON Schemas, 16 canonical vectors, 2 normative documents) with
`SCHEMA-PACKAGE-DIGEST 6e8c1e48e27289b8c3d3e959a06a805e736d0759b4fb244edbb074f65e107bab`.
Index: `engineering/conformance/ndc-v2-schema-profile-1/VECTORS.md`. Checker:
`scripts/check_ndc_schema_package.py`. The typed structs cited in the rows below are producer
and verifier implementation evidence at the recorded heads, not the normative wire format; the
representation differences in section 3 are resolved by the ratified decision and the B8
package. Structural validation alone is insufficient — apply
`ndc-v2-schema-profile-1/semantic-constraints.md`. No implementation state is promoted and
cross-execution remains NOT_STARTED. See also `ndc-v2-conformance-vectors/VECTORS.md` for the
original WP-5 evidence package.

## 1. Acceptance rows

| # | WP-5 check | Ratified rule | Producer implementation and test evidence | Verifier implementation and test evidence | Producer state | Verifier state | Typed rejection codes | Vectors |
|---|---|---|---|---|---|---|---|---|
| 1 | canonical manifest | Profile A; D1 amendment §2.1–§2.2: complete-manifest RFC 8785 JCS, no self-digest, duplicate members fail closed | `fieldbook:src/distribution/ndc_release.rs::manifest_bytes_are_deterministic_and_self_digest_free`; `fieldbook:src/distribution/ndc_release.rs::jcs_rfc8785_property_sorting_vector`; `fieldbook:src/distribution/ndc_release.rs::jcs_rfc8785_string_escaping_vector`; `fieldbook:src/distribution/ndc_release.rs::jcs_rfc8785_number_samples`; `fieldbook:src/distribution/ndc_release.rs::jcs_rejects_duplicate_property_names`; `fieldbook:src/distribution/ndc_release.rs::jcs_rejects_floats_on_strict_manifest_path`; `fieldbook:src/distribution/ndc_release.rs::descriptor_has_the_exact_field_set` | `nirnay:crates/release-verifier/src/jcs.rs::rfc8785_number_vector`; `nirnay:crates/release-verifier/src/jcs.rs::member_order_is_utf16_not_utf8`; `nirnay:crates/release-verifier/tests/verifier.rs::duplicate_json_member_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::manifest_self_digest_field_is_refused` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::InvalidJson`, `DuplicateProperty`, `AmbiguousNumber`; `REJECT_SCHEMA_ENVELOPE` | `jcs-canonicalization.json`, `manifest-example.json`, `adversarial-manifest-sidecar.json` |
| 2 | signature | Profile A/H; five-member sidecar only, domain-separated Ed25519 over the manifest digest, out-of-band key registry | `fieldbook:src/distribution/ndc_release.rs::injected_key_signature_verifies`; `fieldbook:src/distribution/ndc_release.rs::sidecar_has_exactly_five_fields`; `fieldbook:src/distribution/ndc_release.rs::wrong_verifying_key_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::manifest_digest_tampering_is_detected`; `fieldbook:src/distribution/ndc_release.rs::no_private_key_bytes_are_written_to_the_release` | `nirnay:crates/release-verifier/tests/verifier.rs::manifest_mutation_after_signing_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::sidecar_digest_mutation_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::signature_byte_mutation_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::wrong_sidecar_key_id_breaks_publisher_binding`; `nirnay:crates/release-verifier/tests/verifier.rs::unknown_key_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::revoked_key_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::compromised_key_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::sidecar_extra_field_is_refused` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::InvalidSignatureConfig`; `REJECT_SIGNATURE_INTEGRITY`, `REJECT_PUBLISHER_IDENTITY` | `ed25519-test-key-public.json`, `sidecar-example.json`, `adversarial-manifest-sidecar.json` |
| 3 | artifact digests | Profile C; `artifacts[]` is the sole inventory, stored and uncompressed digests in each descriptor, exact published file set | `fieldbook:src/distribution/ndc_release.rs::descriptor_has_the_exact_field_set`; `fieldbook:src/distribution/ndc_release.rs::non_canonical_record_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::overlength_record_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::missing_artifact_is_detected`; `fieldbook:src/distribution/ndc_release.rs::duplicate_artifact_path_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::gzip_stored_bytes_are_deterministic` | `nirnay:crates/release-verifier/tests/verifier.rs::missing_artifact_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::extra_file_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::duplicate_artifact_path_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::non_canonical_record_line_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::happy_path_gzip_release_is_admitted`; `nirnay:crates/release-verifier/tests/verifier.rs::private_snapshot_contains_verified_bytes` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::InvalidRecord`, `MissingArtifact`, `DuplicateArtifactPath`, `ArtifactSetMismatch`, `PolicyExceeded`; `REJECT_ARTIFACT_DIGESTS`, `REJECT_TRUSTED_PATH` | `manifest-example.json`, `adversarial-paths-artifacts.json` |
| 4 | dataset digest | Profile D; SHA-256 over concatenated uncompressed canonical streams in artifact order, independent of compression | `fieldbook:src/distribution/ndc_release.rs::dataset_digest_is_reproducible`; `fieldbook:src/distribution/ndc_release.rs::compression_does_not_change_dataset_digest` | `nirnay:crates/release-verifier/tests/verifier.rs::happy_path_gzip_release_is_admitted` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::PolicyExceeded`; `REJECT_ARTIFACT_DIGESTS` | `manifest-example.json` |
| 5 | ordering | Profile B; sequenced and reference order profiles, no event-time fallback, gaps retained only where declared | `fieldbook:src/distribution/ndc_release.rs::sequenced_ordering_is_deterministic`; `fieldbook:src/distribution/ndc_release.rs::reference_ordering_is_deterministic`; `fieldbook:src/distribution/ndc_release.rs::duplicate_sequence_position_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::sequence_gaps_remain_visible` | `nirnay:crates/release-verifier/tests/verifier.rs::reordered_records_are_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::duplicate_sequence_position_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::declared_gap_policy_admits_visible_gaps`; `nirnay:crates/release-verifier/tests/verifier.rs::strict_gap_policy_refuses_gaps` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::InvalidRecordOrder`; `REJECT_ARTIFACT_DIGESTS` | `adversarial-paths-artifacts.json` |
| 6 | corrections | Profile E; one `lineage.supersedes`, one immediate predecessor, cycle and revision regression fail closed | `fieldbook:src/distribution/ndc_release.rs::lineage_self_reference_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::lineage_missing_predecessor_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::lineage_cycle_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::lineage_revision_regression_is_rejected` | `nirnay:crates/release-verifier/tests/verifier.rs::correction_cycle_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::correction_self_reference_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::missing_predecessor_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::future_knowledge_time_is_refused` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::InvalidLineage`; `REJECT_SOURCE_LINEAGE`, `REJECT_PIT_CONSISTENCY` | `adversarial-policy-cases.json` |
| 7 | paths | Profile C/I; restricted component alphabet, no traversal, no symlink or hard-link descent in the consumer | `fieldbook:src/distribution/ndc_release.rs::traversal_path_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::non_ascii_path_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::duplicate_artifact_path_is_rejected` | `nirnay:crates/release-verifier/tests/verifier.rs::path_traversal_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::symlink_escape_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::hard_linked_published_file_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::special_file_is_refused` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::InvalidArtifactPath`, `DuplicateArtifactPath`; `REJECT_TRUSTED_PATH`, `REJECT_ARTIFACT_DIGESTS` | `adversarial-paths-artifacts.json` |
| 8 | limits | Profile F; no manifest `limits`, caller-supplied numeric maxima enforced independently | `fieldbook:src/distribution/ndc_release.rs::jcs_policy_bounds_are_enforced`; `fieldbook:src/distribution/ndc_release.rs::overlength_record_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::manifest_with_limits_member_fails_strict_parsing` | `nirnay:crates/release-verifier/tests/verifier.rs::resource_limit_is_enforced`; `nirnay:crates/release-verifier/src/jcs.rs::json_depth_counts_nested_containers`; `nirnay:crates/release-verifier/tests/verifier.rs::manifest_limits_field_is_refused` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `ProducerError::PolicyExceeded`; `REJECT_RESOURCE_LIMIT`, `REJECT_SCHEMA_ENVELOPE` | `manifest-example.json`, `adversarial-manifest-sidecar.json` |
| 9 | publication | Profile G; staged synced release, no-replace finalization, durable receipt, evidence-based recovery | `fieldbook:src/distribution/ndc_release.rs::publication_collision_is_rejected`; `fieldbook:src/distribution/ndc_release.rs::receipt_is_bound_to_release_and_digests`; `fieldbook:src/distribution/ndc_release.rs::recovery_without_evidence_is_empty`; `fieldbook:src/distribution/ndc_release.rs::recovery_after_completed_publication_is_already_available`; `fieldbook:src/distribution/ndc_release.rs::recovery_from_final_directory_writes_receipt`; `fieldbook:src/distribution/ndc_release.rs::recovery_from_staging_completes_publication`; `fieldbook:src/distribution/ndc_release.rs::receipt_binding_mismatch_fails_closed` | `nirnay:crates/release-verifier/tests/verifier.rs::missing_artifact_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::extra_file_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::private_snapshot_contains_verified_bytes`; `nirnay:crates/release-verifier/tests/verifier.rs::mutation_of_published_path_after_seal_is_ignored`; `nirnay:crates/release-verifier/tests/verifier.rs::refusal_leaves_no_private_snapshot` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES for published file set and sealed snapshot; NOT_STARTED for consuming the producer receipt or ledger | `ProducerError::PublicationCollision`, `PublicationEvidence`, `UncertainPublication`, `ArtifactSetMismatch`; `REJECT_ARTIFACT_DIGESTS`, `REJECT_TRUSTED_PATH` | `adversarial-paths-artifacts.json`, `manifest-example.json` |
| 10 | admission | Profile H/I and D2 stages 6–12; first refusal stops processing, rights and coverage fail closed, receipt binds request and release | `fieldbook:src/distribution/ndc_release.rs::missing_artifact_is_detected` (producer self-validation before publication only; no admission stage exists) | `nirnay:crates/release-verifier/tests/verifier.rs::happy_path_uncompressed_receipt_is_bound`; `nirnay:crates/release-verifier/tests/verifier.rs::rights_unknown_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::absent_denominator_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::implicit_all_coverage_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::receipt_digest_binds_request_and_release`; `nirnay:crates/release-verifier/tests/verifier.rs::manifest_limits_field_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::sidecar_extra_field_is_refused`; `nirnay:crates/release-verifier/tests/verifier.rs::non_canonical_record_line_is_refused` | NOT_STARTED for admission; producer self-validation TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES | `REJECT_RIGHTS_EVIDENCE`, `REJECT_COVERAGE`, `REJECT_USE_SCOPE`, `REJECT_RETENTION`, `REJECT_AMBIGUOUS_GRANTS`, `REJECT_RECEIPT`, `REJECT_PIT_CONSISTENCY`, `REJECT_SOURCE_LINEAGE` | `adversarial-policy-cases.json` |

## 2. Cross-execution capability

| Capability | State | Evidence or reason |
|---|---|---|
| Producer-generated release verified by a Nirnay verifier binary | **NOT_STARTED** | No shared invocation boundary and no authorized connector between the separate repositories. No cross-execution was run in this environment. The workspace checker is evidence tooling only and is not a producer or verifier. |
| Wire compatibility between the two typed manifest representations at the exact heads | **NOT_STARTED** | No compatibility adaptation or paired decision was executed. Concrete representation differences were observed in read-only source inspection and are listed in section 3. No compatibility claim is made. |
| Standalone published NDC v2 schema artifact | **PUBLISHED (WP-B8, 2026-11-24)** | No such artifact existed at the recorded heads; typed structs in both repositories were the implementation authorities there (`ndc-v2-schema-digest.json`). The canonical schema package is now published in Workspace at `engineering/conformance/ndc-v2-schema-profile-1/` (26 files, digest `6e8c1e48…`). It is documentation and canonical abstract evidence only, not a producer or verifier implementation and not cross-execution. |
| Verification promotion of either implementation | **NOT_STARTED** | Abstract test evidence at an exact head is not independent verification, integration or real-data evidence. |

## 3. Observed representation differences at the exact heads

These are read-only observations, not a decision, a defect gate or a change to either
implementation. Any adaptation requires a paired, reviewed change under the NDC change
procedure.

| Manifest field | Fieldbook typed form | Nirnay typed form |
|---|---|---|
| `release_identity.as_of_ns`, `created_at_utc_ns` | exact decimal `String` | `u64` |
| `producer_activity.performed_operations[]` | `Vec<String>` | `Vec<PerformedOperation>` with four named members |
| `source_scope.segment_id` | `Option<String>` | `String` |
| `coverage.dimensions[]` | `dimension_id`, `universe_id`, `numerator`, `denominator`, `verdict`, `evidence_reference` | adds `universe_name`, `denominator_identity`, `optional denominator`, `missing_count`, `rejected_count`, `gaps`, `as_of_ns` |
| `lineage.knowledge_time_ns` | exact decimal `String` | `u64`; typed lineage also carries `was_derived_from`, `had_primary_source`, `invalidated_at_time_ns` |
| `artifacts[].record_order_profile` | object with `kind` and domain/epoch members | single string identifier |
| `artifacts[].compression_version` | string such as `none/1` | `u32` |

## 4. Boundaries and non-claims

- No shared validator, serializer, digest, rights crate, connector, transport, queue, broker
  or database was introduced. Fieldbook and Nirnay keep separate validators and separate
  failure vocabularies.
- No provider was contacted, no collection or market-data command ran, and no market
  observation, price, order, trade, universe or strategy return was created as evidence.
- No release, dataset, admission receipt, signing key, right or experiment was created.
  Rights remain `UNKNOWN`, dataset acceptance stays `BLOCKED`, collection stays `DISABLED`,
  experiments stay `BLOCKED`, live execution stays `DISABLED`, budget stays INR 0 and D11
  remains strict.
- Approved D0, D1 and D2 bytes and digests are unchanged. The separate consumer-use proposal
  remains **Proposed** and is not part of the ratified set.
- The vector package contains abstract examples and described mutations. The manifest example
  is hand-written, not producer output; the sidecar example carries a placeholder signature.
  Neither was executed by a producer or verifier binary.

## 8. WS-NDC-INT-002 cross-execution outcome

Actual producer and verifier executables were run over the filesystem at the exact
commits recorded in `ndc-v2-cross-execution-2026-11-24.md`. The canonical wire
representation, manifest digest, detached signature, artifact set, dataset digest
and both ordering profiles passed. Rights admission refused at stage 6 with
`REJECT_RIGHTS_EVIDENCE`; no admission receipt was issued and no dataset was
accepted. Wire compatibility is now demonstrated for the abstract release; the
statuses `RIGHTS_ADMITTED` and `DATASET_ACCEPTED` remain unachieved.
