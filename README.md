# siebensterne development workspace

Orchestration repository for two independent source repositories:

- `siebensterne/fieldbook` — market-data acquisition, raw archive and release producer.
- `siebensterne/nirnay` — research, simulation, portfolio, risk and NDC consumer.

This repository contains **only** workspace instructions, scripts and registries. It is
not a monorepo, not a parent Git repository, and it has no submodules, shared Cargo
workspace or source copies. `fieldbook/` and `nirnay/` are local clones and are ignored
by this repository's `.gitignore`.

## Start here

| Document | Purpose |
|---|---|
| `WORKSPACE.md` | full programme, ownership and operating rules |
| `WORKSPACE.lock.json` | pinned bootstrap baselines and tool policy |
| `CURRENT-STATE.json` | current separately evidenced source-head concepts (`current_source_head`, `ci_verified_source_head`, `local_tested_source_head`, `cross_execution_source_head`, `reviewed_source_head`), explicit Workspace provenance (`workspace_audited_subject_head` `6d45af2`, `workspace_evidence_commit` / packaged bundle head `95580f5`, `workspace_hosted_ci` `NOT_RUN`, `workspace_static_gates` `PASS`, external package-head attestation), explicit HISTORICAL legacy heads, CI runs, static/test separation and open owner decisions; `generated_utc_date` 2026-11-24 |
| `W1.1-COMPLETION-RECORD.md` | W1.1 work packages, CI, test-policy outcome, contract digests and remaining owner gates |
| `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` | C0 normative rights/operation/data-object model; settles action, grant, purpose, time, revocation, trust and coverage semantics before implementation |
| `engineering/architecture/india-domain-ownership-crosswalk.md` | W1.2-D1 ownership map for every India domain type; Fieldbook authority, Nirnay projections, frozen legacy |
| `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md` | ratified ownership roles and NDC v2 semantics with approved document digests; not a data licence |
| `ENGINEERING-DOC-DIGESTS.json` | digests of workspace engineering documents |
| `engineering/architecture/india-domain-ownership-crosswalk.md` | W1.2-D1 domain-by-domain Fieldbook-authority vs Nirnay-code crosswalk, ownership rule, verified defect findings and migration phases I1–I6; documentation only; ownership ADR Accepted 2026-11-23 |
| `engineering/coverage/india-coverage-register.md` | W2-A measurable-coverage axes, I1–I6 India priority register and per-dimension denominators from C0 §6; development sequence only, no coverage figure claimed, rights UNKNOWN, dataset BLOCKED |
| `TOOL-MATRIX.md` | canonical tool versions, command surface and preserved differences |
| `ADR-REGISTRY.md` | collision-free canonical ADR IDs across both repositories |
| `NDC-REGISTRY.md` | NDC version, active `v2` contract, approved digests, consumer-use proposal status and compatibility rules |
| `engineering/conformance/ndc-v2-conformance-matrix.md` | W2.1 D paired 15-area NDC v2 matrix: normative source and digest, contract field, actual producer/consumer file, role, validation rule, failure code, abstract-only test category, evidence and per-side state; no shared crate |
| `engineering/conformance/ndc-v2-release-format-design.md` | W2.1 D **design only**: exact manifest content, RFC 8785 JCS signed bytes, detached Ed25519 sidecar, artifact paths, record order, schema versioning, digests, correction links, immutability, size maxima and verification/use race policy; serializer and verifier not implemented; no transport/broker/database |
| `engineering/conformance/ndc-v2-schema-digest.json` | WP-5 schema registration: final Profile 1 version, profile and D1 amendment digests, strict unknown-field policy and source of truth; no standalone published schema artifact exists; typed structs are the implementation authorities |
| `engineering/conformance/ndc-v2-acceptance-matrix.md` | WP-5 ten-check acceptance matrix: exact producer and verifier implementation/test evidence at the merged PR heads, both sides' states and typed rejection codes; cross-execution NOT_STARTED; no shared validator crate |
| `engineering/conformance/ndc-v2-conformance-vectors/VECTORS.md` | WP-5 abstract non-market vector index with SHA-256 for each vector: RFC 8785 JCS, RFC 8032 public test key, canonical manifest and sidecar examples, and described adversarial cases |
| `scripts/check_ndc_conformance_vectors.py` | WP-5 workspace evidence checker: verifies vector digests, index literal scans and cited test names at exact heads when clones are present; not a producer, verifier or connector |
| `W2.1-READINESS-REPORT.md` | W2.1 E readiness: exact heads, approved digests, PR #6/#137–#140 and Fieldbook #52–#55 review/CI record, head-tagged and D11 test disposition, abstract 600 ms lease measurement, one status per requirement, rights state, open defects, gates and India design status |
| `engineering/conformance/publication-integrity-sprint-acceptance-2026-11-24.md` | publication-integrity sprint acceptance: PUB-019/020/021, NZ-SNAP-001, FB-API-001, DUR-001, final heads and capability states; its three-case D0 scope and DUR-002 "remaining gate" are HISTORICAL as at sprint head `fd4b542` and superseded for current evidence by the D0 full-matrix record; preserved unchanged |
| `engineering/decisions/WS-SCOPE-2026-11-24-001-global-reference-core-india-first.md` | owner-ratified scope: global reference core with India first; ownership, model rules and work ordering |
| `engineering/design/india-national-domain-catalogue.md` | IN-CAT-001 **PROPOSED** domain work breakdown, amended in place under IN-CAT-002/003/004: 20 cohorts IN-01..IN-20 with per-cohort object, family, contract, relationship, identifier, term, lifecycle, venue, time, authority, denominator, capability and rights declarations; explicit listed/OTC and four-way interest-rate subpopulations, three IN-20 subdomains, three IN-19 object contracts, mandatory Q01–Q20 cross-domain answers per cohort, ontology non-conflation rules, population types and I1–I6 migration sequence; not a population or provider claim |
| `engineering/decisions/IN-COUNTRY-001-india-country-pack-design.md` | IN-COUNTRY-001 **PROPOSED** India country pack, amended in place under IN-COUNTRY-002: versioned extension of the global core with nine-field component evidence, immutable admitted pack versions, mainland/IFSC partition definitions submitted for owner approval, jurisdiction/authorities/infrastructure/venues/segments/identifiers/currencies/calendars/settlement/instrument rules/actions/regulation/provenance, bitemporal policy, 20-cohort completeness policy aligned to split subpopulations and global-core crosswalk; no rights, collection, reference ingestion, implementation or dataset acceptance |
| `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md` | owner-ratified NDC v2 Release Serialization Profile 1 (2026-11-24): Decisions A–I on manifest digest, ordering, artifacts, data digest, corrections, limits, publication, keys and independence; docs only |
| `engineering/conformance/NDC-D1-AMENDMENT-001.md` | approved 2026-11-24 amendment to D1 §5.8/§7.2 with its own digest; complete-manifest JCS and sidecar-only `manifest_sha256`; D1 approved bytes and historical digest unchanged |
| `engineering/conformance/ndc-v2-wire-contract-reconciliation.md` | WP-B6 PROPOSED field-level wire reconciliation: single 102-row matrix across D0/D1/D2/Profile 1 and both exact-head typed implementations, with semantic invariants, recommended canonical forms, decision authority and test vectors; 30 owner decision points; DP-01..DP-30 resolved by WS-NDC-2026-11-24-003; no Rust type normative, no cross-execution |
| `engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` | owner-ratified canonical NDC v2 Profile 1 wire schema (2026-11-24): one language-independent wire authority with independent per-repository internal representations and no shared crate; strict JCS/UTF-8, decimal-string instants, byte-derived tagged ordering, typed operations/evidence, source scope, rights, coverage, lineage, registered compression, versioned schema package with one digest; resolves DP-01..DP-30; docs only, B8 builds the package |
| `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` | owner-ratified publication durability as a failure model (2026-11-24; amended for FB-DUR-002 evidence): tiers D0 process termination through D4 disaster recovery with profile-scoped booleans and no global durability Boolean; error-only sync acknowledgement contract for five publication states; Linux `renameat2(RENAME_NOREPLACE)` and macOS `renamex_np(RENAME_EXCL)` with `fsync`, with macOS `F_FULLFSYNC` not yet used or qualified; VM reset distinguished from D1b physical power loss; Fieldbook v2 journal with PUB-019/020/021 and DUR-002 at exact commits; invariants I-01..I-15; current D0 evidence: 28 fresh-process exit points over 24 owner boundary names at Fieldbook `4e0f2f5` (outcomes 1/17/2/7/1, idempotent second recovery), in-process fault injection separate; the WS-EVIDENCE-026 three-case scope is preserved as HISTORICAL; D1 OS/filesystem crash, D1b power loss and D2–D4 unqualified; `PUBLICATION_DURABILITY_VERIFIED` remains NOT ACHIEVED; no global durability claim; docs only |
| `engineering/design/b15-streaming-producer-design.md` | WP-2 / B15 **PROPOSED / AWAITING OWNER APPROVAL** bounded streaming Fieldbook producer lifecycle at `fd4b542`: bounded record-source API and framer, byte-derived order checking without whole-dataset sort, incremental digests and deterministic gzip, two-intent PreparationIntent/SealedPublicationIntent lifecycle with replay and non-replayable spool rules, Profile 1 digest compatibility, unapproved numeric resource-profile proposals, failure matrix, test plan, batch compatibility adapter and open decisions; no implementation, ratification, resource-maximum approval or capability promotion |
| `engineering/conformance/ndc-v2-schema-profile-1/VECTORS.md` | WP-B8 canonical schema package index: SHA-256 of all 26 files (8 strict JSON Schemas, 16 canonical abstract vectors, 2 normative documents); package identity `6e8c1e48…`; no secret or external observation |
| `engineering/conformance/ndc-v2-cross-execution-2026-11-24.md` | WS-NDC-INT-002 canonical real producer-to-verifier cross-execution: exact commits, commands, stage results, rights refusal and mutation check. The conformance-path section at Fieldbook `071da27` and the FB-NDC-013 production-builder parity section at Fieldbook `5703185` (PR #66) / Nirnay `70716eb` are explicitly HISTORICAL and preserved unchanged; a 2026-11-24 reconciliation section points to the dated current record |
| `engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md` | Dated current evidence baseline at Fieldbook `475dc34` / Nirnay `70716eb` / Workspace `62b617c`: exact commits and commands, exact release layout, stage results and capability states; supersedes stale head wording and the ambiguous "no receipt" phrasing by distinguishing the Fieldbook publication receipt from the Nirnay admission receipt (`receipt_written:false` means no Nirnay admission receipt); historical records preserved |
| `engineering/conformance/ndc-v2-evidence-manifest-2026-11-24.md` | Dated PR 0 reconciliation evidence manifest: exact commits, evidence digests with `shasum -a 256` commands, `make consistency` / `make audit` gate results, derived summaries reconciled and freeze statement |
| `engineering/conformance/ws-evidence-026-provenance-2026-11-24.md` | WS-EVIDENCE-026 terminology note: Workspace audited subject `6d45af2` vs packaged bundle head / evidence commit `95580f5`; hosted CI `NOT_RUN`; static gates `PASS`; meaning of all five head concepts; **HISTORICAL** three-D0-subprocess-case scope with all other boundaries in-process only, superseded for current evidence by FB-DUR-002 §6; external package-manifest head attestation and no internal self-hash |
| `engineering/conformance/d0-full-matrix-evidence-2026-11-24.md` | Dated D0 evidence record for Fieldbook DUR-002 (PR #74, merged `4e0f2f5`): 28 fresh-process exit points over 24 owner boundary names, expected-outcome distribution (1 `NO_EVIDENCE`, 17 `UNCERTAIN_PUBLICATION_QUARANTINED`, 2 `RECOVERED_STAGED`, 7 `RECOVERED_PUBLISHED`, 1 `ALREADY_AVAILABLE`), idempotent second recovery, gate-record digest, in-process fault injection kept separate, historical three-case scope preserved, D1/D1b and D2–D4 unqualified, no global durability claim; docs only |
| `engineering/conformance/ndc-v2-evidence-audit-2026-11-24.md` | WP-B6A evidence-led audit mapping the reviewer's twelve findings to current WIRE-CROSS source at Fieldbook `dd90899` (finding 2 re-evaluated at `071da27`) and Nirnay `70716eb`: 9 RESOLVED, 1 REMAINING (B15/B16), 1 OWNER-DECISION, 1 SEPARATE GATE; nine-state milestone assessment; docs only, no state promotion |
| `engineering/design/b16-streaming-verifier-design.md` | WP-3 / B16 **PROPOSED / AWAITING OWNER APPROVAL** bounded streaming Nirnay release verifier design: chunked stored reader, streaming decompressor with a pre-materialization emission cap, reusable bounded framer and one-record parser, constant-size per-artifact state, metadata-only snapshot with the NZ #144 cleanup contract, eight-item owner acceptance list, failure matrix, open decisions and staged migration; docs only, no source or state change |
| `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md` | owner-ratified B15/B16 streaming architecture and interface contracts (2026-11-25): twelve approved contract items; normative immutable versioned role-specific `ResourceProfile` with trusted local selection and stricter-of effective limits; OD-01..OD-10 and D1..D10 resolved individually; all numeric maxima, codec identifier and operational qualification deferred; implementation may proceed with finite `TEST_ONLY` profiles; `STREAM_RESOURCE_PROFILE_RATIFIED` pending, `PERF_001_QUALIFIED` and `OPERATIONALLY_QUALIFIED` blocked, `PUBLICATION_DURABILITY_VERIFIED` false; docs only |
| `engineering/decisions/NDC-RECEIPT-001-publication-receipt-consumer-contract.md` | WP-9 / NDC-RECEIPT-001 **PROPOSED / AWAITING OWNER RATIFICATION** consumer-side publication receipt contract: Fieldbook local publication receipt kept separate from the Nirnay admission receipt; independently signed receipt with a dedicated `RECEIPT_SIGNING` key purpose and separate out-of-band registry; normative wire fields and JCS/decimal-string canonicalization; strict verification pipeline with typed refusals; no rights grant, UNKNOWN promotion, dataset acceptance, experiment or execution; no ratified schema change, no shared crate and no production key; docs only, no implementation or state change |
| `engineering/conformance/ndc-v2-schema-profile-1/manifest.schema.json` | WP-B8 canonical manifest JSON Schema (draft 2020-12): single root `contract_version`, required scope identifiers, typed operations/evidence, rights, coverage, lineage and payload registry, sole `artifacts[]`, `additionalProperties:false` throughout; sidecar, envelope, ordering, rights, coverage, lineage and registry schemas alongside it |
| `engineering/conformance/ndc-v2-schema-profile-1/semantic-constraints.md` | WP-B8 cross-field rules JSON Schema cannot express: manifest digest location, sidecar binding, byte-derived ordering, artifact and dataset digests, rights separation, coverage arithmetic, lineage cycles and revision, key lifecycle, resource policy, availability and receipt, five distinct status states; structural validation insufficient |
| `engineering/conformance/ndc-v2-schema-profile-1/compatibility-and-evolution.md` | WP-B8 strictness baseline and evolution rules: unknown/missing/wrong-type/coercion reject, no unversioned extensions, explicit version bump rules and breaking semantic changes |
| `scripts/check_ndc_schema_package.py` | WP-B8 workspace checker: verifies every indexed digest, JSON parseability, strict schema structure and vector patterns; prints the single reproducible `SCHEMA-PACKAGE-DIGEST`; not a producer, verifier, shared validator or connector |
| `engineering/style/DOCUMENTATION-STANDARD.md` | adopted documentation standard: Markdown, rustdoc, source comments, official language references and sweep-before-gates rule |
| `engineering/retirement/RRP-001.md` | owner directive D11, six dispositions, per-file record schema, P0/P1/P2 priorities and binding retirement rules |
| `engineering/retirement/FIELD-BOOK-RETIREMENT-MANIFEST.csv` | measured Fieldbook retirement candidates with path, commit, SHA-256, size, disposition and reason (219 rows) |
| `engineering/retirement/NIRNAY-RETIREMENT-MANIFEST.csv` | measured Nirnay retirement candidates with the same record schema (76 rows) |
| `engineering/retirement/DEPENDENCY-CROSSWALK.csv` | retired paths to the module registrations, commands, CI targets and docs that must be updated (45 rows) |
| `engineering/retirement/RETIREMENT-ACCEPTANCE.md` | RRP-002..RRP-007 acceptance gates and no-deletion-before-replacement rules |
| `engineering/retirement/RRP-006-analytics-sbe-decision.md` | RRP-006 decision: Nirnay owns research analytics, KDB/q and experiments; NDC v2 is the only cross-repo semantic contract; custom SBE format, Fieldbook offline analytics and the generated/decoder codecs are CONDITIONAL and deprecate after first accepted NDC v2 release publication |
| `REVIEW-LOG.md` | cross-repository decisions with exact commits |
| `PAIRED-PR-CHECKLIST.md` | required checks for any cross-repository change |
| `SHARED-FILES.md` | byte-identical versus repository-local file classification |
| `AGENTS.md` | binding rules for agents working in this workspace |

## Commands

```
make bootstrap        clone or verify both repositories at the pinned baselines
make status           read-only head, branch, dirt and lock-skew report
make ci-report        latest hosted CI conclusion per repository
make consistency      read-only tool, canonical-file and lock audit
make check-all        both static gate surfaces
make check-nirnay     Nirnay's full local gate
make audit            status + consistency + check-all
python3 scripts/check_ndc_conformance_vectors.py   verify the WP-5 vector package
python3 scripts/check_ndc_schema_package.py     verify the WP-B8 canonical schema package and print its digest
```

`make check-fieldbook-static` and `make check-nirnay-static` share one meaning: static
gates only, no tests, no e2e, no provider contact. Under owner directive D11 the Fieldbook
synthetic fixture inventory is being retired rather than merely disabled, and the Nirnay
`market_shaped_fixture` deselection is being replaced by removal. The W1.1/W1.2 test-policy
records, counts and digests remain historical and unchanged; see `engineering/retirement/`.

## Boundaries

No provider contact, market-data download, scraper, collector execution, experiment,
live order, synthetic market observation, shared crate, queue, database or transport
choice is authorised by this repository. Rights remain `UNKNOWN` and dataset acceptance
remains `BLOCKED` until written evidence and owner approval exist.
