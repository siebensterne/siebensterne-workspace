# ADR registry — cross-repository identity

Both repositories contain an ADR numbered 0001. They are different decisions. This
registry gives each a canonical ID without renaming historical files.

| Canonical ID | Repository | File | Subject | Status |
|---|---|---|---|---|
| `NR-ARCH-ADR-0001` | Nirnay | `engineering/architecture/decisions/ADR-0001-data-ownership.md` | Fieldbook owns acquisition; Nirnay owns research | **Accepted 2026-11-23** by owner ratification |
| `NR-ADR-0001` | Nirnay | `engineering/decisions/ADR-0001-modular-monolith.md` | modular monolith boundary | Historical |
| `FB-ADR-0001` | Fieldbook | `docs/adr/0001-instrument-and-venue-reference-model.md` | instrument and venue reference identity | design; code migration deferred |
| `FB-ADR-0002` | Fieldbook | `docs/adr/0002-persist-transport-observations-without-changing-receive-order.md` | journal observation identity | implemented |
| `WS-NDC-2026-11-24-002` | Workspace (cross-repository) | `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md` | NDC v2 Release Serialization Profile 1: manifest digest, ordering, artifacts, data digest, corrections, limits, publication, keys, independence | **Ratified 2026-11-24** by owner |
| `WS-NDC-2026-11-24-003` | Workspace (cross-repository) | `engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` | Canonical NDC v2 Profile 1 wire schema: language-independent wire authority, strict canonical encoding, instants/numbers, byte-derived tagged record ordering, typed operations/evidence, source scope, rights, coverage, lineage, registered compression, versioned schema package; resolves DP-01..DP-30 | **Ratified 2026-11-24** by owner direction; digest `417bd4e5e9904d21d2da5905b3ac68905d677f800526eeedcf25fab897ce2119` |
| `WS-DUR-001` | Workspace (cross-repository) | `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` | Publication durability as a failure model: tiers D0–D4, profile-scoped booleans, error-only sync acknowledgement contract, per-platform primitive qualification, permissible claim language, journal and pending-package relationship, invariants I-01..I-15 | **Ratified 2026-11-24** by owner direction; current digest `931e7477faa7752248a2392d7b79f34c317ab95a838a88ee491f448eac6dbcfb` (FB-DUR-002 full-matrix evidence extension; prior WS-EVIDENCE-026 digest `d3a18e62bd31d6e9492078edf6d3cfb80ae2e69fa977a497780b54ef00aea8b6` and original ratification digest `2b04f9b40fd395973f0f0ab99bc47a73f1e82a8b375e2ec4c5de211e85095b71` preserved as historical in `REVIEW-LOG.md`) |
| `WS-STREAM-001` | Workspace (cross-repository) | `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md` | B15/B16 bounded streaming architecture and interface contracts A-01..A-12; normative immutable versioned `ResourceProfile` contract with role-specific profiles and trusted local selection; OD-01..OD-10 and D1..D10 resolved individually | **Ratified 2026-11-25** by owner direction; implementation completed under finite `TEST_ONLY` profiles at FB `8216197` (PR #75) / NZ `c1c2f0d` (PR #145) per Phase 3 acceptance, not `Verified`; all numeric resource maxima, codec identifier and operational qualification deferred; `STREAM_RESOURCE_PROFILE_RATIFIED` pending |

Nirnay also carries `NR-ARCH-ADR-INDEX.md` under `engineering/architecture/decisions/`.
New ADRs must register here in the same commit that adds them, using the repository
prefix. Never renumber a historical ADR. `WS-NDC-2026-11-24-002` and `WS-NDC-2026-11-24-003`
are dated cross-repository decisions registered under their own identifiers; no historical ADR
is renumbered or replaced by either, and no new numbered `ADR-0001` file is created in either
repository. `WS-NDC-2026-11-24-003` ratifies the canonical wire authority and resolves
DP-01..DP-30 of the WP-B6 reconciliation; it supersedes neither approved semantics nor the
freeze, and creates no schema artifact, right, dataset or cross-execution claim. `WS-DUR-001`
ratifies the failure-model scope of durability claims and registers no new numbered ADR in either
source repository; it supersedes neither approved semantics nor the freeze, and it is not a D1
qualification, a capability-state promotion or a global durability claim. The WS-EVIDENCE-026
terminology correction recorded exactly three fresh-process D0 cases (`publish_before`,
`publish_staging`, `publish_rename`) with all other boundaries in-process fault injection only;
that record is **HISTORICAL** and superseded for current evidence by Fieldbook DUR-002 (PR #74,
merged at `4e0f2f5`), whose 28 exit points cover all 24 owner boundary names with outcomes
`NO_EVIDENCE` 1, `UNCERTAIN_PUBLICATION_QUARANTINED` 17, `RECOVERED_STAGED` 2,
`RECOVERED_PUBLISHED` 7 and `ALREADY_AVAILABLE` 1 plus idempotent second recovery. In-process fault
injection remains separate. See `engineering/conformance/d0-full-matrix-evidence-2026-11-24.md`
and the supersession note in `engineering/conformance/ws-evidence-026-provenance-2026-11-24.md`.

`WS-STREAM-001` ratifies the B15/B16 architecture and interface contracts only. It registers
no new numbered ADR in either source repository, approves no numeric resource maximum, codec
identifier or schema version, and promotes no `Implemented`, `Verified`, `PERF_001_QUALIFIED`
or `OPERATIONALLY_QUALIFIED` state. `PUBLICATION_DURABILITY_VERIFIED` remains `false`. Both
design documents keep their PROPOSED status; a pointer records the architecture ratification
and the deferred numbers. `STREAM_RESOURCE_PROFILE_RATIFIED` stays pending.

**Phase 3 evidence acceptance pointer (2026-11-25):** `WS-STREAM-001` contracts are implemented
at FB `8216197124d33466fbe651e417b7c19505e4155e` (B15, PR #75) and NZ
`c1c2f0d984bee11a63eb1df98833ee8723cd8629` (B16, PR #145) with finite `TEST_ONLY` profiles; this
`Implemented` state is not a `Verified` promotion. Numeric maxima remain DEFERRED; no production
invocation without an approved role profile; PERF-001 and D1 are not run. The evidence record is
`engineering/conformance/phase-3-acceptance-2026-11-25.md` (digest
`3a823688f59bca1fd78ba8f02231b97f8d40d98647430551fbc2e805a0cb2ee4`). It is an acceptance record,
not a new numbered ADR, and changes no approved decision byte.

The ownership decision `NR-ARCH-ADR-0001` was **Accepted 2026-11-23** by owner
ratification (`engineering/decisions/OWNER-RATIFICATION-2026-11-23.md`, Decision A), which
also named responsible roles. Acceptance grants no data rights.

Status cross-check (W2.1-A): this registry, `NDC-REGISTRY.md`,
`ENGINEERING-DOC-DIGESTS.json`, `CURRENT-STATE.json` and `REVIEW-LOG.md` all express the
same decision state — ownership ADR Accepted, NDC v2 semantics Approved, v1 historical.
Ratification of ownership does **not** ratify the W2 India domain design; the India
ownership crosswalk, coverage register, Fieldbook India reference design and Nirnay
reference-projection design remain **Proposed pending a separate design approval**.
`WS-NDC-2026-11-24-002` ratifies NDC v2 Release Serialization Profile 1 only; its approved D1
amendment is `engineering/conformance/NDC-D1-AMENDMENT-001.md` (new revision with its own
digest), and no D0/D1/D2 historical digest changes. D11
(owner directive, `engineering/retirement/RRP-001.md`) changes test-asset retirement policy,
not an ADR status, and supersedes the earlier preserve-source-while-disabled policy for
synthetic market-data test assets.
