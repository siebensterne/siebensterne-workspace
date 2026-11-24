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
| `CURRENT-STATE.json` | current reviewed heads, CI runs, static/test separation and open owner decisions |
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
| `engineering/decisions/WS-SCOPE-2026-11-24-001-global-reference-core-india-first.md` | owner-ratified scope: global reference core with India first; ownership, model rules and work ordering |
| `engineering/design/india-national-domain-catalogue.md` | IN-CAT-001 **PROPOSED** domain work breakdown: 20 cohorts IN-01..IN-20 with per-cohort object, family, contract, relationship, identifier, term, lifecycle, venue, time, authority, denominator, capability and rights declarations; ontology non-conflation rules, population types and I1–I6 migration sequence; not a population or provider claim |
| `engineering/decisions/IN-COUNTRY-001-india-country-pack-design.md` | IN-COUNTRY-001 **PROPOSED** India country pack as a versioned extension of the global core: jurisdiction/IFSC, authorities, infrastructure, venues, segments, identifiers, currencies, calendars, settlement, instrument rules, actions, regulation, provenance, bitemporal policy, 20-cohort completeness policy and global-core crosswalk; no rights, collection, implementation or dataset acceptance |
| `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md` | owner-ratified NDC v2 Release Serialization Profile 1 (2026-11-24): Decisions A–I on manifest digest, ordering, artifacts, data digest, corrections, limits, publication, keys and independence; docs only |
| `engineering/conformance/NDC-D1-AMENDMENT-001.md` | approved 2026-11-24 amendment to D1 §5.8/§7.2 with its own digest; complete-manifest JCS and sidecar-only `manifest_sha256`; D1 approved bytes and historical digest unchanged |
| `engineering/conformance/ndc-v2-wire-contract-reconciliation.md` | WP-B6 PROPOSED field-level wire reconciliation: single 102-row matrix across D0/D1/D2/Profile 1 and both exact-head typed implementations, with semantic invariants, recommended canonical forms, decision authority and test vectors; 30 owner decision points; DP-01..DP-30 resolved by WS-NDC-2026-11-24-003; no Rust type normative, no cross-execution |
| `engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` | owner-ratified canonical NDC v2 Profile 1 wire schema (2026-11-24): one language-independent wire authority with independent per-repository internal representations and no shared crate; strict JCS/UTF-8, decimal-string instants, byte-derived tagged ordering, typed operations/evidence, source scope, rights, coverage, lineage, registered compression, versioned schema package with one digest; resolves DP-01..DP-30; docs only, B8 builds the package |
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
