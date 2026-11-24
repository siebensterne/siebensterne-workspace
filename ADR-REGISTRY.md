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

Nirnay also carries `NR-ARCH-ADR-INDEX.md` under `engineering/architecture/decisions/`.
New ADRs must register here in the same commit that adds them, using the repository
prefix. Never renumber a historical ADR. `WS-NDC-2026-11-24-002` is a dated cross-repository
decision registered under its own identifier; no historical ADR is renumbered or replaced by
it, and no new numbered `ADR-0001` file is created in either repository.

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
