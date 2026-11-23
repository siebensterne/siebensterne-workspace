# NDC v2 paired conformance matrix — W2.1 D/E

<!-- SPDX-License-Identifier: Apache-2.0 -->

**Status:** conformance record and design input. Documentation only. This matrix does not
approve a contract, create a release, verify a signature, grant a right or change a test
policy. The NDC v2 semantic requirements are Approved 2026-11-23; the paired runtime work
recorded here is Implemented/Tested with abstract values only.

**Scope:** the 15 areas named in the W2.1 work order, paired across Fieldbook e0472f7 and
Nirnay f1f8a8a. No shared crate, transport, broker, queue, database or vendored source is
created or assumed. Producer and consumer remain separate repositories with separate
validators; there is no parent build.

**Read-only sources:** Fieldbook clone at `e0472f7610ee062fe1a9b8aea8d7a6234a6e3b77`,
Nirnay clone at `f1f8a8a35b510aa4b6676147f049eae2c63a16b2`. Files under `fieldbook:` and
`nirnay:` below are actual paths inspected at those heads. The workspace sources were not
edited to make this matrix consistent.

## 1. Digests and labels used in this matrix

| Label | Source document (exact repository path) | SHA-256 | State |
|---|---|---|---|
| D0 | `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` (workspace) | `3dace660c362e683790ba7e56a785ded8af836abda36f6eab06ed284de49eed2` | Approved 2026-11-23; filename keeps its historical PROPOSED suffix |
| D1 | `fieldbook:engineering/ndc-producer-requirements-v2-proposed.md` | `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c` | Approved 2026-11-23 |
| D2 | `nirnay:engineering/ndc-consumer-requirements-v2-proposed.md` | `22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957` | Approved 2026-11-23 |
| E-FB-B1 | `fieldbook:docs/authorization-identity-2026-11-23.md` | `b6f7cab8cd86be3a1d53b2a08c1b80e412750d02dcdb1bc62552ec1291fa5cf5` | Implementation record, PR #52 |
| E-FB-B2 | `fieldbook:docs/universe-containment-2026-11-24.md` | `5d6dc97449a7f0502e593ff75771a677242b61f63a632664466b2cb43e3b0f2f` | Implementation record, PR #53 |
| E-FB-B3 | `fieldbook:docs/operation-plan-authorization-2026-11-24.md` | `9be6638b8896db140fc53072f7ba25d430301f6ddb1785264d824f4d84a62413` | Implementation record, PR #54 |
| E-FB-B4 | `fieldbook:docs/authorization-lifecycle-checkpoint-2026-11-24.md` | `3a14b9e0ea58f8d7125df7f5fc157999cc589355859d8800bb9a54c2c0707039` | Implementation record, PR #55 |
| E-NZ-C13 | `nirnay:evidence/W2-1-C1-C3-CONSUMER-ADMISSION-2026-11-24.md` | `0cb6853eedee791ab459892e1614c1ac34ff61c89b70c36356423cb7675d32e9` | Implementation record, PR #139 |
| E-NZ-C46 | `nirnay:evidence/W2-1-C4-C6-CONSUMER-ADMISSION-2026-11-24.md` | `c1bf6e3d94b363a4e33806df88f3950ac857d2ef019508f094dca1ebc94b288b` | Implementation record, PR #140 |
| E-NZ-MI | `nirnay:evidence/CODE-MANIFEST-INTEGRITY-NIRNAY-2026-11-24.md` | `d4ae5f1e48367f9afea088720b2112e2089f82f97e594157ba7b16f9c267f917` | Implementation record, PR #138 |
| E-NZ-D11 | `nirnay:evidence/D11-RESIDUAL-CLOSURE-NIRNAY-2026-11-23.md` | `8935dc40fb9302821b760aee2abf132152402e2bf7e8126b035584c357873e4b` | D11 closure record, PR #137 |

Separate consumer-use proposal `nirnay:engineering/ndc-consumer-use-v2-proposed.md`, digest
`4b9d1fe7190de08151989fc8895f42e1daa737021e8dae019ddc3325f9603a2c`, remains **Proposed**
and is not part of the ratified D0/D1/D2 set.

Roles (ratified in `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md`): **FPO** =
Fieldbook producer owner; **NCO** = Nirnay consumer owner; **NDC** = NDC contract owner;
**DRS** = data-rights steward; **SKC** = signing-key custodian; **OWN** = programme owner.

State vocabulary for the two per-side state columns: **NOT_STARTED** (no enforcement code
at this head), **DESIGNED** (rule fixed in an approved/design document only),
**IMPLEMENTED** (code present), **TESTED_WITH_ABSTRACT_VALUES** (abstract scalar tests run),
**BLOCKED** (cannot be exercised without written rights, a real observation, an accepted
dataset or a separate approval). `VERIFIED_AGAINST_OFFICIAL_REFERENCE_DATA`,
`VERIFIED_AGAINST_PERMITTED_REAL_OBSERVATIONS` and real-market verification states are
**not claimed for any area**.

Permitted test category is uniform and is repeated in the table so it cannot be read as a
broader claim: **abstract scalar values only** (scalar identifiers, abstract instants,
temporary directories, injected transports and clocks). Under owner directive D11 no
market-shaped observation, price bar, order book, trade, universe, strategy return or
provider response may be created, enabled or consumed as evidence. No official reference
vector suite and no permitted real observation was run for this work package.

## 2. Matrix

| # | Area | Normative requirement (source / digest / section) | Contract field | Producer file (Fieldbook) | Consumer file (Nirnay) | Responsible role | Validation rule | Failure code | Permitted test category | Evidence | Producer state | Consumer state |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | publisher identity | Publication key bound to one named publisher; unknown, malformed, expired or revoked key fails closed; integrity is not authenticity (D0 §5; D1 §5.9, §7.1; D2 §3 stages 2–4) | `publication_identity.publisher_identity`, `.signing_key_id`, `.signature_reference` | `fieldbook:engineering/ndc-producer-requirements-v2-proposed.md`; `fieldbook:src/governance/rights.rs` (`Actor::SigningAuthority`) | `nirnay:research/python/src/quantlab/consumer_use.py` (`_check_declarations` publisher equality); `nirnay:research/python/src/quantlab/dataset_admission.py` (`release.publication_identity`) | SKC, NDC, NCO | Declared publisher equals the trusted registry entry; key validity and revocation checked at verification instant. Current consumer code checks name equality only; no key registry check exists | `REJECT_PUBLISHER_IDENTITY`, `REJECT_SIGNATURE_INTEGRITY` | abstract scalar only | E-NZ-C13; E-NZ-C46; NDC-REGISTRY.md trust model | NOT_STARTED | TESTED_WITH_ABSTRACT_VALUES |
| 2 | release identity | One immutable `release_id` and exact contract version; a correction receives a new identity; no revision chosen by arrival order (D0 §4.1, §7; D1 §5.1, §9.2; D2 §2.1) | `release_identity.release_id`, `.contract_version`, `.release_version`, `.as_of_ns`, `.publication_state` | `fieldbook:engineering/ndc-producer-requirements-v2-proposed.md`; `fieldbook:src/storage/report.rs` (`RunReport`, rotation manifest) — no NDC release emitter at this head | `nirnay:research/python/src/quantlab/dataset_admission.py` (`_validate_release`); `nirnay:research/python/src/quantlab/consumer_use.py` (`ReleaseIdentity`) | FPO, NCO, NDC | Require non-empty identity, supported contract version, `immutable=true`; compare identity and both digests with the dataset record; reject on any mismatch | `REJECT_RELEASE_IDENTITY`, `REJECT_CONTRACT_VERSION`, `REJECT_AMBIGUOUS_RELEASE` | abstract scalar only | E-NZ-C46; `research/python/tests/test_dataset_admission.py` | NOT_STARTED | TESTED_WITH_ABSTRACT_VALUES |
| 3 | source identity | Source scope and data-object identity declared explicitly; a kind is not an identity; object id and version are required (D0 §2, §2.1; D1 §2, §5.2; D2 §2.1) | `source_scope.provider_id`, `.source_product_id`, `.venue_id`, `.segment_id`, `.dataset_id`; `object.identity`, `.version` | `fieldbook:src/governance/rights.rs` (`ScopeSet`, `DataObject`, `ObjectIdentity`, `ObjectVersion`); `fieldbook:src/domain/identity.rs`; `fieldbook:src/governance/egress_intent.rs` | `nirnay:research/python/src/quantlab/consumer_use.py` (`IdentityScope`, `RequestedUse`); `nirnay:research/python/src/quantlab/dataset_admission.py` (`_scope`) | FPO, NCO | Exact equality on all source dimensions; grant object kind, id and version must all match; blank id/version/recipient identity denied | `REJECT_SCOPE`, `REJECT_SOURCE_BINDING`, `REJECT_DATASET_BINDING`, `REJECT_OBJECT_IDENTITY` | abstract scalar only | E-FB-B1; E-FB-B2; E-NZ-C13; tests `object_kind_alone_is_not_an_object_identity`, `different_object_version_is_denied` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES |
| 4 | actor / action / object | Full request tuple bound; no inference from a command, proof or another action; 14-value producer enum and five-value consumer enum stay distinct (D0 §1, §2, §2.1, §4; D1 §3, §9.1; D2 §1, §2.2) | `actor`, `performed_operations[].operation`, `requested_actions[]`, `requested_objects[]`, `object.kind` | `fieldbook:src/governance/rights.rs` (`Actor`, `Operation`, `ObjectKind`, `validate_applicability`); `fieldbook:src/governance/operation_plan.rs` | `nirnay:research/python/src/quantlab/consumer_use.py` (`RequestedUse`, `CONSUMER_OPERATIONS` import); `nirnay:research/python/src/quantlab/dataset_admission.py` (`CONSUMER_OPERATIONS`) | FPO, NCO, DRS | Restricted applicability matrix over 14 x 8 pairs; one valid plan step does not authorize another; each required `(action, object-kind)` pair needs one unique applicable `PERMIT` | `REJECT_OPERATION_ENUM`, `REJECT_MISSING_PAIR`, `REJECT_ACTOR_IDENTITY`, `REJECT_AMBIGUOUS_GRANTS` | abstract scalar only | E-FB-B1, E-FB-B2, E-FB-B3; E-NZ-C13; 12 B1 tests, 12 B2 tests, 13 B3 tests, 36 C1–C3 tests | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES |
| 5 | rights | One decision and one written evidence reference per grant; ambiguity denies; no right is created by a signature or receipt (D0 §1, §2, §5; D1 §5.4, §9; D2 §3, §4) | `rights.permission_grants[]`, `.document_references[]`, `.reviewed_attestations[]`, `rights.record_reference` | `fieldbook:src/governance/rights.rs` (`LicensingRegistry`, `RightDecision`, `DecisionAuditEvent`, `RightsError`); `fieldbook:rights.example.toml` | `nirnay:research/python/src/quantlab/consumer_use.py` (`PermissionGrant`, `_check_grants`); `nirnay:research/python/src/quantlab/dataset_admission.py` (`_validate_rights`); `nirnay:research/python/src/quantlab/data_rights.py` | DRS, FPO, NCO | Decision must be `PERMIT`; no duplicate/conflicting/overlapping grant; actor, licensee, recipient, purpose, scope and evidence all equal; ambiguous denies; audit commit before egress | `REJECT_RIGHTS_EVIDENCE`, `REJECT_DENIED_GRANT`, `REJECT_AMBIGUOUS_GRANTS`, `REJECT_EGRESS_INTENT` | abstract scalar only; **no real right may be exercised** | E-FB-B1, E-FB-B3; E-NZ-C13, E-NZ-C46; all source rights remain `UNKNOWN` | TESTED_WITH_ABSTRACT_VALUES (enforcement only) | TESTED_WITH_ABSTRACT_VALUES (enforcement only) |
| 6 | data-time | Source event, receive, valid, knowledge and availability times are separate axes; one as-of instant and knowledge-time basis; `from <= to` (D0 §2.3, §4.1 stage 10, §6; D1 §5.1, §8; D2 §6) | `release_identity.as_of_ns`, `lineage.knowledge_time_ns`, `TimeAxes.source_data_time`, `.data_as_of`, `.knowledge_time` | `fieldbook:src/governance/rights.rs` (`TimeWindow`); `fieldbook:src/integrity/time.rs`; `fieldbook:src/domain/information.rs` (valid and transaction time) | `nirnay:research/python/src/quantlab/consumer_use.py` (`TimeAxes`, `_check_time_axes`); `nirnay:research/python/src/quantlab/dataset_admission.py` (`_validate_lineage`) | FPO, NCO, NDC | Knowledge time after as-of instant refused; data time and operational time compared independently; unbounded request requires an unbounded grant | `REJECT_TIME_AXES`, `REJECT_DATA_TIME`, `REJECT_PIT_CONSISTENCY` | abstract scalar only | E-FB-B2; E-NZ-C13; E-NZ-C46; test `lease_expiry_stops_receive_and_does_not_follow_the_wall_clock` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES |
| 7 | operational validity | Grant validity evaluated at the decision instant; monotonic lease deadlines; revision/snapshot revocation; fail closed on refresh failure (D0 §2.3, §2.5; D1 §6, §9; D2 §2.1, §3) | `validity.effective_from`, `.effective_until`, `lease_id`, `lease_epoch`, `decision_at`, `monotonic_deadline_us` | `fieldbook:src/governance/egress_intent.rs` (`DecisionTime`, `MAX_LEASE_DURATION`, `revocation_propagation_bound`); `fieldbook:src/governance/rights.rs`; `fieldbook:src/governance/operation_plan.rs` (`checkpoint`) | `nirnay:research/python/src/quantlab/consumer_use.py` (`_effective`, `GRANT_EXPIRED_AT_DECISION`, `GRANT_NOT_EFFECTIVE_AT_DECISION`); `nirnay:research/python/src/quantlab/dataset_admission.py` (`_validity_date`) | FPO, NCO, DRS | 15-minute ceiling and 30-second renewal margin; checkpoint at loop top and before frame emission; a 2024 selection cannot revive a 2025-expired grant for a 2026 decision | `REJECT_GRANT_EXPIRED_AT_DECISION`, `REJECT_GRANT_NOT_EFFECTIVE_AT_DECISION`, `REJECT_AUTHORITY_REFRESH` | abstract scalar only | E-FB-B4 (abstract 600 ms stop, bound 2 s); E-NZ-C13; 12 B4 session tests | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES |
| 8 | coverage | Nine named dimensions with independent denominators, as-of instants, count bases and verdicts; one count implies nothing (D0 §6; D1 §5.5, §8; D2 §5) | `coverage.dimensions[]` (instrument, listing/identity, contract, corporate action, calendar, trades, quotes/depth, MBO, sequence continuity) | `fieldbook:src/governance/coverage_certification.rs`; `fieldbook:src/integrity/coverage.rs` (`CoverageSummary`, `expected_set_sha256`) | `nirnay:research/python/src/quantlab/dataset_admission.py` (`check_dimension_coverage`, `CoverageDimensionReport`, `CoverageCertificate`); `nirnay:research/python/src/quantlab/consumer_use.py` (`_coverage_failure`) | FPO, NCO, NDC | An absent or inconsistent denominator yields REJECT or UNKNOWN, never PASS; N/A needs a reason; no aggregate percentage accepted | `REJECT_COVERAGE`, `REJECT_INCOMPLETE_COVERAGE` | abstract scalar only; real denominators BLOCKED without a dataset | E-FB-B2; E-NZ-C46; `research/python/tests/test_dataset_admission.py` | TESTED_WITH_ABSTRACT_VALUES (shape only) | TESTED_WITH_ABSTRACT_VALUES (shape only) |
| 9 | provenance | PROV-O Entity/Activity/Agent with derivation, revision and attribution; raw archive reference, exact digests and transformation record (D0 §8, §4.1 stage 10; D1 §5.6, §7.3; D2 §6) | `lineage.raw_archive_reference`, `.transformation_record`, `wasDerivedFrom`, `wasRevisionOf`, `hadPrimarySource`, `source_lineage_reference` | `fieldbook:src/integrity/journal.rs` (journal header, `config_sha256`, source ranges); `fieldbook:src/integrity/replay.rs`; `fieldbook:src/domain/information.rs` (`revision_lineage`) | `nirnay:research/python/src/quantlab/dataset_admission.py` (`_validate_lineage`); `nirnay:research/python/src/quantlab/consumer_use.py` (`correction_lineage_reference`); `nirnay:crates/india-reference/src/provenance.rs` | FPO, NCO | Require named source lineage and revision chain; reject later knowledge time and missing source/identity references; PROV semantics establish no permission or truth | `REJECT_SOURCE_LINEAGE`, `REJECT_PIT_CONSISTENCY`, `REJECT_CORRECTION_LINEAGE` | abstract scalar only | E-FB-B1; E-NZ-C13; E-NZ-C46; `test_dataset_admission.py` lineage cases | IMPLEMENTED (journal-level) | TESTED_WITH_ABSTRACT_VALUES |
| 10 | digests | SHA-256 over RFC 8785 canonical manifest bytes and deterministic data records; mismatch blocks use (D0 §5.1; D1 §5.8, §7.2, §9.2; D2 §3 stage 5, §4.1) | `digests.manifest_sha256`, `.data_sha256`, `.digest_algorithm`, `.artifact_digests[]` | `fieldbook:src/util/mod.rs` (`sha256_hex`); `fieldbook:src/integrity/journal.rs`; no NDC manifest serializer at this head | `nirnay:research/python/src/quantlab/experiments/reproducibility.py` (`code_manifest_digest`, `_safe_path`, `_validated_source`, `verify_code_manifest`); `nirnay:research/python/src/quantlab/point_in_time.py` (`write_dataset`); `nirnay:research/python/src/quantlab/dataset_admission.py` | FPO, NCO, NDC | File digest compared with exact bytes; code manifest uses 64-bit length framing, domain prefix and sorted POSIX paths; a changed byte, moved path or duplicate normalized path refuses | `REJECT_DIGEST`, `REJECT_ARTIFACT_DIGESTS`, `REJECT_DIGEST_MISMATCH` | abstract scalar and arbitrary temporary bytes only | E-NZ-MI (14 abstract tests); `research/python/tests/test_code_manifest_integrity.py` | IMPLEMENTED (primitive only) | TESTED_WITH_ABSTRACT_VALUES |
| 11 | signature | Detached Ed25519 sidecar outside the manifest; domain-separated digest of JCS bytes; proves publisher-key control and manifest integrity only (D0 §5, §5.1; D1 §5.9, §7.1; D2 §3 stages 2–5, §4.1) | `publication_identity.signature_reference`; sidecar `algorithm`, `key_id`, `manifest_sha256`, `signature_b64` | `fieldbook:engineering/ndc-producer-requirements-v2-proposed.md`; `fieldbook:src/governance/rights.rs` (`Actor::SigningAuthority`) — no Fieldbook release signer | `nirnay:schemas/research/dataset-signature.v1.schema.json`; `nirnay:research/python/src/quantlab/point_in_time.py` (own-dataset sidecar); `nirnay:research/python/src/quantlab/kms_signing.py`; `nirnay:research/python/src/quantlab/consumer_use.py` (declaration codes) | SKC, NDC, NCO | No signature property inside the signed manifest; verify key bound to publisher, unrevoked at verification instant, and recomputed digest equal; no partial verification | `REJECT_SIGNATURE`, `REJECT_SIGNATURE_INTEGRITY`, `REJECT_INVALID_SIGNATURE` | abstract scalar only; real-key and full verifier checks NOT STARTED | NDC-REGISTRY.md ratified trust model; `engineering/conformance/ndc-v2-release-format-design.md` (DESIGN); own-dataset sidecar writer at `point_in_time.py` is separate | NOT_STARTED | DESIGNED |
| 12 | capabilities | Capability is not permission; four capability facts stay separate; a non-empty verified-capability fact is refused at a stage that performs no verification (D0 §1; D1 §2, §5.3; D2 §1, §2.1, §3) | `declared_capabilities`, `producer_declared_capabilities`, `release_available_capabilities`, `verified_capabilities` | `fieldbook:src/governance/adapter.rs` (`SourceCapabilityManifest`, `SourceRegistry`); `fieldbook:src/governance/modality.rs` | `nirnay:research/python/src/quantlab/consumer_use.py` (`CapabilityFacts`, `_preflight_capability_check`); `nirnay:engineering/capabilities.json` | FPO, NCO, NDC | Profile capability requirements equal declared capabilities; producer and release facts come only from release evidence; consumer cannot self-assert a verified capability | `REJECT_REQUIRED_CAPABILITY`, `REJECT_PRODUCER_CAPABILITY`, `REJECT_RELEASE_CAPABILITY`, `REJECT_VERIFIED_CAPABILITY`, `REJECT_CAPABILITY_ASSERTION` | abstract scalar only | E-FB-B1; E-NZ-C13; `evidence/C3-CONSUMER-USE-PERMISSIONS-2026-11-23.md` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES |
| 13 | corrections | A correction creates a new revision and release identity; earlier view and knowledge time retained; selection by as-of instant and knowledge time, not arrival order (D0 §4.1, §7, §8; D1 §5.1, §5.6; D2 §6) | `release_identity.release_id`, `lineage.revision`, `correction_lineage_reference`, `invalidation_time` | `fieldbook:src/domain/information.rs` (`revision_lineage`, correction status); `fieldbook:src/integrity/replay.rs` | `nirnay:research/python/src/quantlab/consumer_use.py` (`CORRECTION_LINEAGE`); `nirnay:research/python/src/quantlab/dataset_admission.py` (`lineage.revision`, `knowledge_time_ns`) | FPO, NCO, NDC | Named correction lineage required; as-of selection uses knowledge time; a changed release or rights evidence requires a new admission decision | `REJECT_CORRECTION_LINEAGE`, `REJECT_PIT_CONSISTENCY`, `REJECT_AMBIGUOUS_RELEASE` | abstract scalar only | E-NZ-C13; E-NZ-C46; design in `engineering/conformance/ndc-v2-release-format-design.md` | IMPLEMENTED (revision model) | TESTED_WITH_ABSTRACT_VALUES |
| 14 | retention | Typed bounded maximum and purge rule; purge duty must not be weaker than the grant; indefinite request cannot exceed a bounded grant (D0 §2.3; D1 §2, §5.4, §9.2; D2 §2.1, §3) | `retention_request`, `permission_grants[].retention`, `RetentionPolicy`, `purge_rule` | `fieldbook:src/governance/rights.rs` (`RetentionLimit`, `Retention`, `RightsError::LeaseTooLong` path); `fieldbook:src/governance/egress_intent.rs` | `nirnay:research/python/src/quantlab/dataset_admission.py` (`NoRetention`, `Bounded`, `Indefinite`, `DeleteOnExpiry`, `PurgeAfter`, `LegalHold`, `retention_covered`); `nirnay:research/python/src/quantlab/consumer_use.py` (`_retention_failure`) | DRS, FPO, NCO | Duration containment **and** purge rank containment (`DeleteOnExpiry > PurgeAfter > LegalHold`); `None` is never absent or unlimited | `REJECT_RETENTION`, `REJECT_WEAKER_PURGE` | abstract scalar only | E-FB-B2; E-NZ-C46; 38 C4–C6 abstract tests | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES |
| 15 | rejection / failure | Ordered validation stops at first refusal; whole-release admit or reject; typed code and named field on every refusal (D0 §4.1; D1 §9.1, §9.2; D2 §3, §3.1, §7) | `PreflightDecision.kind`, `rejection_code`, `DecisionAuditEvent.reason`, `RightsError`, `ConformanceError` | `fieldbook:src/governance/rights.rs` (`RightsError`, `DecisionAuditEvent`); `fieldbook:src/governance/operation_plan.rs` (`PlanError`); `fieldbook:src/integrity/conformance.rs` (`ConformanceError`) | `nirnay:research/python/src/quantlab/consumer_use.py` (`PreflightRejectionCode`, 40 codes, `PreflightDecision`); `nirnay:research/python/src/quantlab/dataset_admission.py` (`DatasetAdmissionError`) | FPO, NCO, NDC | `is_admission_receipt=False` and `release_verified=False` on preflight; research job refuses a preflight verdict; no partial publication or partial consumption | `REJECT_*` typed codes (both vocabularies in §3 below) | abstract scalar only | E-FB-B3, E-FB-B4; E-NZ-C13, E-NZ-C46; `research/python/tests/test_research_jobs.py` | TESTED_WITH_ABSTRACT_VALUES | TESTED_WITH_ABSTRACT_VALUES |

## 3. Failure-code crosswalk

Producer-side codes are declared in D1 §9.2; consumer-side codes are declared in D2 §3.1 and
implemented as `PreflightRejectionCode` in `nirnay:research/python/src/quantlab/consumer_use.py`.
A code is a classification of a failed check, not proof that a cryptographic check ran.

| Area | Producer code (declared) | Consumer code (implemented at declaration level) |
|---|---|---|
| publisher identity / signature | `REJECT_SIGNATURE` | `REJECT_PUBLISHER_IDENTITY`, `REJECT_SIGNATURE_INTEGRITY`, `REJECT_INVALID_SIGNATURE` |
| release identity / contract | `REJECT_RELEASE_IDENTITY`, `REJECT_AMBIGUOUS_RELEASE` | `REJECT_CONTRACT_VERSION`, `REJECT_SCHEMA_ENVELOPE` |
| digests | `REJECT_DIGEST` | `REJECT_ARTIFACT_DIGESTS`, `REJECT_DIGEST_MISMATCH` |
| rights / grants | `REJECT_RIGHTS_EVIDENCE`, `REJECT_AMBIGUOUS_GRANTS`, `REJECT_PURPOSE`, `REJECT_LICENSEE` | `REJECT_RIGHTS_EVIDENCE`, `REJECT_AMBIGUOUS_GRANTS`, `REJECT_DENIED_GRANT`, `REJECT_PURPOSE`, `REJECT_LICENSEE_IDENTITY`, `REJECT_RECIPIENT_IDENTITY` |
| scope / source / object | `REJECT_SCOPE`, `REJECT_EGRESS_INTENT`, `REJECT_CONSUMER_USE_MAPPING` | `REJECT_USE_SCOPE`, `REJECT_SOURCE_BINDING`, `REJECT_DATASET_BINDING`, `REJECT_OBJECT_IDENTITY`, `REJECT_OUT_OF_SCOPE_FIELD`, `REJECT_OUT_OF_SCOPE_MODALITY` |
| data-time / PIT | `REJECT_INCOMPLETE` | `REJECT_TIME_AXES`, `REJECT_DATA_TIME`, `REJECT_PIT_CONSISTENCY` |
| operational validity | `REJECT_RIGHTS_EVIDENCE` | `REJECT_GRANT_NOT_EFFECTIVE_AT_DECISION`, `REJECT_GRANT_EXPIRED_AT_DECISION` |
| coverage | `REJECT_COVERAGE_DENOMINATOR` | `REJECT_COVERAGE`, `REJECT_INCOMPLETE_COVERAGE` |
| provenance / corrections | `REJECT_SOURCE_LINEAGE` | `REJECT_SOURCE_LINEAGE`, `REJECT_CORRECTION_LINEAGE` |
| capabilities | `REJECT_CONCEPT_CONFLATION` | `REJECT_REQUIRED_CAPABILITY`, `REJECT_PRODUCER_CAPABILITY`, `REJECT_RELEASE_CAPABILITY`, `REJECT_VERIFIED_CAPABILITY`, `REJECT_CAPABILITY_ASSERTION` |
| retention | `REJECT_RETENTION` | `REJECT_RETENTION`, `REJECT_WEAKER_PURGE` |
| generic incomplete / operation | `REJECT_INCOMPLETE`, `REJECT_OPERATION_ENUM`, `REJECT_PRODUCER_ACTIVITY` | `REJECT_MISSING_PAIR`, `REJECT_ACTOR_IDENTITY` |

## 4. Per-area state notes

1. **Publisher identity.** Fieldbook has the `SigningAuthority` actor and the publication
   requirements but no trusted-key registry, signer or publication binding. Nirnay checks
   that a declared publisher name equals the request identity (`consumer_use.py`) and that
   `release.publication_identity` is named (`dataset_admission.py`). No key validity or
   revocation check exists. No real key was exercised.
2. **Release identity.** Nirnay has declaration-level identity and digest equality tests;
   Fieldbook has run/journal manifests but no NDC release emitter. The release serializer is
   designed in `ndc-v2-release-format-design.md` and is explicitly not implemented.
3. **Source identity.** Both sides enforce exact source dimensions and full object
   identity; Fieldbook's `UniverseRef` requires exact id/version/digest/time/revision and
   recorded membership. All tests use scalar strings and abstract instants.
4. **Actor/action/object.** Fieldbook's 14-value enum, eight object kinds, 26 permitted
   pairs of 112 and atomic plan authorization are tested. Nirnay's exact action-object pair
   coverage uses the unchanged five-value `CONSUMER_OPERATIONS` plus a separate
   `create_derived` request; no producer-operation mapping is used.
5. **Rights.** Enforcement logic is implemented and abstract-tested on both sides; the
   rights evidence itself is absent. All 21 provider rights remain `UNKNOWN`, no right was
   reviewed, granted or exercised, and dataset acceptance stays `BLOCKED`. Declaration-level
   enforcement MUST NOT be reported as rights verification.
6. **Data-time.** The five time axes exist separately in Nirnay preflight; Fieldbook keeps
   wall-clock calendar facts separate from monotonic lease deadlines. Abstract clock tests
   only; no official reference calendar or real observation was used.
7. **Operational validity.** Grant validity is evaluated at `decision_at`, not at an
   earlier selection instant. Fieldbook's measured 600 ms abstract stop is inside the
   declared 2 s bound; `T_scheduler` and `T_cancel` remain declared policy assumptions, not
   measured production latencies.
8. **Coverage.** Both sides enforce the nine-dimension shape and per-dimension denominators
   on declarations. No real denominator, universe or count was measured; real coverage is
   BLOCKED until a dataset is accepted, which has not happened.
9. **Provenance.** Fieldbook journals durable source and receive records with config
   digests and revision lineage; Nirnay validates named source, universe, identity and
   corporate-action references plus knowledge time. A signature or lineage record is not
   evidence of truth or permission.
10. **Digests.** Fieldbook exposes the SHA-256 primitive and journal digests but no NDC
    manifest/data digest serializer. Nirnay's code-manifest integrity layer adds path-safe
    reads, length framing, sorted entries, size-while-reading checks and 14 abstract tests;
    this is research-code integrity, not an NDC release verifier.
11. **Signature.** RFC 8785 JCS plus a detached Ed25519 sidecar is a ratified semantic
    requirement and is fully specified as DESIGN in the companion document. Nirnay's
    `write_dataset` writes a detached sidecar for its *own* research dataset with an
    injected signer; that path is not a Fieldbook NDC release verifier and is not evidence
    that the NDC verifier exists.
12. **Capabilities.** Four separate facts are tested in Nirnay preflight; Fieldbook's
    source capability manifests are declarations of technical capability and grant no
    permission. No capability was derived from a connection or a successful check.
13. **Corrections.** Fieldbook models valid/transaction time and revision lineage; Nirnay
    requires named correction lineage and refuses a later knowledge time. The release-format
    design specifies a new release identity per correction; no serializer emits one.
14. **Retention.** Both sides require typed bounded duration and purge duty; a shorter
    duration with a weaker purge is refused. No retention right was granted or exercised.
15. **Rejection/failure.** Producer codes are declared in D1 and implemented as typed Rust
    errors; Nirnay has 40 typed consumer codes. `PreflightDecision` explicitly carries
    `is_admission_receipt=False` and `release_verified=False`, and research jobs refuse it.
    A declaration-level code never claims that a byte-level or cryptographic check ran.

## 5. Boundaries and non-claims

- No provider was contacted, no market-data API was called, no market observation was
  created and no collection command was run to produce this matrix.
- No dataset, release, research dataset, admission receipt, experiment, live order or
  synthetic market observation was created or accepted.
- No shared crate, transport, broker, queue or database was introduced. Fieldbook and Nirnay
  keep separate validators and separate failure vocabularies.
- No approved digest was edited. D0/D1/D2 and the separate consumer-use proposal keep their
  recorded SHA-256 values.
- The paired runtime records remain Proposed implementations of a ratified semantic model;
  Implemented with abstract values is not Verified, and nothing in this matrix promotes a
  state.
