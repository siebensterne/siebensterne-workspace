# Engineering status authority map

<!-- SPDX-License-Identifier: Apache-2.0 -->

This file resolves competing status claims. It does not replace `CURRENT-STATE.json`,
approved contract bytes or dated evidence. Where a historical file still says
"current" or "open", this map and `DIGEST-RECONCILIATION-2026-11-26.json` govern.

## Machine authority

| Topic | Authority |
|---|---|
| Current source heads, CI, capability states, freeze | `CURRENT-STATE.json` |
| Bootstrap pins and tool policy | `WORKSPACE.lock.json` |
| Ownership and programme boundaries | `WORKSPACE.md` |
| Active decision/review ledger | `engineering/evidence/REVIEW-LOG.md` |
| ADR identities | `ADR-REGISTRY.md` |
| NDC versions, digests and contract status | `NDC-REGISTRY.md` |
| Document digests and their historical/current roles | `ENGINEERING-DOC-DIGESTS.json`, `engineering/DIGEST-RECONCILIATION-2026-11-26.json` |

## Effective requirements

| Topic | Current authority | Status |
|---|---|---|
| Ownership ADR and NDC v2 semantics | `decisions/OWNER-RATIFICATION-2026-11-23.md` | Accepted/Approved; no data rights |
| Release serialization profile | `decisions/WS-NDC-2026-11-24-002-...md` | Ratified; original digest historical, current file digest reconciled |
| Canonical wire schema | `decisions/WS-NDC-2026-11-24-003-...md` and `conformance/ndc-v2-schema-profile-1/` | Ratified; sole normative wire authority |
| Streaming architecture | `decisions/WS-STREAM-001-...md` | Architecture ratified; numeric maxima deferred |
| Durability failure model | `decisions/WS-DUR-001-...md` | Ratified; D0 achieved, D1+ unverified |
| India scope and catalogue | `decisions/WS-SCOPE-2026-11-24-001-...md`, `design/india-national-domain-catalogue.md` | Scope ratified; design documents still Proposed |
| Publication-receipt consumer contract | `decisions/NDC-RECEIPT-001-...md` | Proposed; not implemented |
| NDC v2 semantic model | `design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` | Approved bytes; historical filename suffix |

## Current evidence

| Topic | Authority |
|---|---|
| Phase 3A acceptance | `conformance/phase-3a-acceptance-2026-11-25.md` |
| D0 full subprocess matrix | `conformance/d0-full-matrix-evidence-2026-11-24.md` |
| Schema package and vectors | `conformance/ndc-v2-schema-profile-1/VECTORS.md` |
| Conformance checker | `scripts/check_ndc_schema_package.py` |

## Historical records

The following remain immutable evidence and are not current status: `phase-3-acceptance`,
`publication-integrity-sprint-acceptance`, `ws-evidence-026-provenance`, both dated
cross-execution records, `ndc-v2-evidence-audit`, WP-5 matrices and vectors,
`W1.1-COMPLETION-RECORD.md`, `W2.1-READINESS-REPORT.md`, retirement manifests and the
India ownership crosswalk. Each now carries a short current-status header where it could
be mistaken for a live claim.

## Freeze

Rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection `DISABLED`,
experiments `BLOCKED`, M4 holdout untouched, synthetic market-shaped tests retired under
D11, live execution `DISABLED`. No document here grants rights or authorizes operation.
