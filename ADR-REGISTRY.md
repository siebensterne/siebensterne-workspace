# ADR registry — cross-repository identity

Both repositories contain an ADR numbered 0001. They are different decisions. This
registry gives each a canonical ID without renaming historical files.

| Canonical ID | Repository | File | Subject | Status |
|---|---|---|---|---|
| `NR-ARCH-ADR-0001` | Nirnay | `engineering/architecture/decisions/ADR-0001-data-ownership.md` | Fieldbook owns acquisition; Nirnay owns research | **Accepted 2026-11-23** by owner ratification |
| `NR-ADR-0001` | Nirnay | `engineering/decisions/ADR-0001-modular-monolith.md` | modular monolith boundary | Historical |
| `FB-ADR-0001` | Fieldbook | `docs/adr/0001-instrument-and-venue-reference-model.md` | instrument and venue reference identity | design; code migration deferred |
| `FB-ADR-0002` | Fieldbook | `docs/adr/0002-persist-transport-observations-without-changing-receive-order.md` | journal observation identity | implemented |

Nirnay also carries `NR-ARCH-ADR-INDEX.md` under `engineering/architecture/decisions/`.
New ADRs must register here in the same commit that adds them, using the repository
prefix. Never renumber a historical ADR.

The ownership decision `NR-ARCH-ADR-0001` was **Accepted 2026-11-23** by owner
ratification (`engineering/decisions/OWNER-RATIFICATION-2026-11-23.md`, Decision A), which
also named responsible roles. Acceptance grants no data rights.

Status cross-check (W2.1-A): this registry, `NDC-REGISTRY.md`,
`ENGINEERING-DOC-DIGESTS.json`, `CURRENT-STATE.json` and `REVIEW-LOG.md` all express the
same decision state — ownership ADR Accepted, NDC v2 semantics Approved, v1 historical.
Ratification of ownership does **not** ratify the W2 India domain design; the India
ownership crosswalk, coverage register, Fieldbook India reference design and Nirnay
reference-projection design remain **Proposed pending a separate design approval**. D11
(owner directive, `engineering/retirement/RRP-001.md`) changes test-asset retirement policy,
not an ADR status, and supersedes the earlier preserve-source-while-disabled policy for
synthetic market-data test assets.
