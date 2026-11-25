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
| `WS-STREAM-001` | Workspace (cross-repository) | `engineering/decisions/WS-STREAM-001-b15-b16-architecture-ratification.md` | B15/B16 bounded streaming architecture and interface contracts A-01..A-12; normative immutable versioned `ResourceProfile` contract with role-specific profiles and trusted local selection; OD-01..OD-10 and D1..D10 resolved individually | **Ratified 2026-11-25** by owner direction; implementation completed under finite `TEST_ONLY` profiles; Phase 3A conformance packages merged at FB `acbd9b683d86ba6fbb62f7170f8852b23876e3aa` / NZ `c2c51757b0aeca94d2eacf651e8861e1937f74c8`, not `Verified`, and actual B16 streaming cross-execution NOT_RUN (not evidence); all numeric resource maxima, codec identifier and operational qualification deferred; `STREAM_RESOURCE_PROFILE_RATIFIED` pending |

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
not a new numbered ADR, and changes no approved decision byte. This Phase 3 pointer is **HISTORICAL**;
current status is in the Phase 3A pointer below.

**Phase 3A evidence acceptance pointer (2026-11-25):** Phase 3A conformance packages merged at FB
`acbd9b683d86ba6fbb62f7170f8852b23876e3aa` and NZ `c2c51757b0aeca94d2eacf651e8861e1937f74c8` (NZ #146-#150, FB #76-#80, WS #31/#32); hosted CI `45621903705`
(2/2) and `45612047715` (12/12); Workspace hosted CI `NOT_RUN`. The evidence record is
`engineering/conformance/phase-3a-acceptance-2026-11-25.md` (digest `497df40aa13fa6d610e36f85f7f3d225ccc575232e9a09ecee219b304afc1866`). It is an acceptance record, not a new
numbered ADR, and changes no approved decision byte. The B15/B16 stream-contract conformance items
are closed except actual B16 streaming cross-execution, which is **NOT_RUN** (NZ-API-001 harness
skips with an explicit reason; no external B15 streaming producer binary; `cfg(test)`-only
`TEST_ONLY` helpers) and must not be counted as evidence. No production `ResourceProfile`, no
numeric maxima, no PERF-001 or PERF-BASE-001 result, no D1 qualification, no `Implemented`-to-`Verified`
promotion and no change to the freeze. `WS-STREAM-001` remains RATIFIED at contract level only.

**WS-DOC-001 design-document synchronization pointer (2026-11-25):** docs-only current-status
notices and conformance appendices were added to `engineering/design/b15-streaming-producer-design.md`
(Appendix A) and `engineering/design/b16-streaming-verifier-design.md` (Appendix B). They point to
the `WS-STREAM-001` decision digest `f74153024c1d526fe5c9d49b22e541263581c52c0dbae19a67e8d2ea841a4fe1`
and to the Phase 3 acceptance record; B16 names the ratified D2 dedicated `parser.max_string_bytes`
field and D3 stage-five refusal at detection as superseding the original proposal assumptions, and
both appendices list Phase 3A corrective work packages as pointers only at that time; their
subsequent merges are recorded in the Phase 3A acceptance record with actual B16 streaming
cross-execution NOT_RUN and not evidence. This synchronization
registers **no new canonical ADR**, changes no ADR status, approves no numeric maximum or profile
digest, promotes no `Implemented`/`Verified`/`PERF_001_QUALIFIED`/`OPERATIONALLY_QUALIFIED` state,
and does not ratify `NDC-RECEIPT-001` (still **PROPOSED**; publication and admission receipts stay
separate). Workspace hosted CI remains `NOT_RUN`. Exact commands, gate outcomes and the freeze
statement are in the `REVIEW-LOG.md` entry dated 2026-11-25.

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
