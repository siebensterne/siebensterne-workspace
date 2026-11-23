# Retirement acceptance gates — RRP-002 to RRP-007

Status: **gates defined, none claimed passed**. RRP-001 is documentation only; executing a
gate requires a reviewed PR with exact commits and evidence recorded in `REVIEW-LOG.md`.
No file may be deleted from a source repository in this workspace PR.

## 0. No-deletion-before-replacement rules (binding)

1. A `DELETE` row may be executed only when every `DEPENDENCY-CROSSWALK.csv` entry for that
   path has been updated and reviewed in the same or an earlier PR.
2. Nirnay source-ingestion, raw-archive and provider-decoder paths stay **frozen** until a
   Fieldbook equivalent and an accepted NDC projection exist. Ownership metadata may be
   updated first; deletion is not permitted under RRP-004.
3. No replacement synthetic data may be created. A `TEST_ONLY` amendment needs a separate
   versioned owner decision before any market-shaped fixture is reintroduced.
4. Retain `synthetic` as a provenance and rejection value so historical synthetic records
   can still be detected. Removing a generator must not remove the detector.
5. Never delete a production crate, engine, risk engine, decoder or generic transport
   module because its tests contain market-shaped data. Remove the offending cases only.
6. `research/python/fixtures/` and `measurements/live/*` provider-origin material may not be
   history-purged without a separate data-rights decision, reissued bundles and invalidation
   of old review packages.
7. Historical W1.1/W1.2 test counts and approved document digests are immutable; publish a
   new dated test-retirement record instead of rewriting them.
8. `make audit` here is **static only**. A static gate pass is not a test pass, a compiled
   type is not a validated market implementation, and a preserved test source is not
   executed coverage.

## Gate RRP-002 — Synthetic asset removal (paired Fieldbook/Nirnay PRs)

**May start:** after RRP-001 approval.

**Must be removed:** generators; market-shaped fixtures; golden market data; mock exchange
market data; synthetic benchmarks; synthetic strategy outputs; regeneration/verification
commands; tests that construct invented market observations.

**Must be retained:** pure scalar and exact-numeric tests; abstract timestamp tests; rights
and authorization tests; arbitrary-byte storage tests; hashing/signature tests; type-level
and schema-boundary checks that construct no market observations.

**Evidence required:**

- Per-row `path`, `sha256`, `size` and new commit in a dated test-retirement record.
- Updated module registrations, `Cargo.toml` targets, `xtask` commands, `Makefile` targets
  (`kdb-golden`, `fundamental-fixture-check`, `cpp-test`) and CI workflows from the crosswalk.
- Static gates pass (`make check-all` here); code tests reported with their own commits and
  policy, not merged into a single headline count.
- W1.1/W1.2 counts and digests unchanged; `CURRENT-STATE.json` points at new heads only
  after the paired PRs merge.

**Fail conditions:** any remaining regeneration command; any `include_str!` of a deleted
golden; any broken module registration; any new synthetic artifact.

## Gate RRP-003 — Fieldbook product-scope retirement

**May start:** after RRP-002 acceptance.

**Must be removed:** the seven crypto/prediction-market adapter families, their configs,
tests, scripts, fixtures, docs, measurements, obsolete performance claims and capacity
assumptions (Fieldbook manifest groups D11-D/D11-E/D11-F).

**Must be retained:** `src/acquisition/{session,transport,egress,arbiter,supervisor,codec}.rs`,
`src/integrity/{journal,replay}.rs`, `src/governance/` and other generic acquisition and
transport infrastructure.

**Evidence required:** `ExchangeKind`, `Settings::for_exchange`, `capabilities_for` and
`build_exchange` call sites audited; README rewritten for securities scope; no stale venue
credentials or secrets reference in CI.

## Gate RRP-004 — Nirnay source-ingestion consolidation

**May start:** immediately as a metadata-only freeze; **deletion only after replacements**.

**Must be done:** freeze old Nirnay acquisition and raw-archive paths; record ownership as
Fieldbook in metadata; prohibit new features in legacy paths; register the migration to
Fieldbook and NDC projections.

**Must not be done:** delete a legacy ingestion or archive module before its Fieldbook
equivalent and NDC projection are accepted. The Upstox decoder source is preserved for
migration even though its synthetic fixture is retired in RRP-002.

**Evidence required:** updated ownership crosswalk, migration register, and an explicit
replacement commit ID for each path proposed for deletion.

## Gate RRP-005 — Documentation consolidation

**May start:** after RRP-003 and the RRP-004 freeze record.

**Must be done:** rewrite READMEs; replace stale architecture, status and matrix documents;
consolidate duplicate style, claims and capability inventories (Fieldbook D11-F
`CONSOLIDATE` rows).

**Must not be done:** edit approved NDC v2 or ADR bytes casually. If a name or status is
wrong, correct the registry or publish an approved revision with a new digest. W2 India
design documents stay **Proposed pending a separate design approval**; ratification of
ownership did not ratify the India domain model.

**Evidence required:** one canonical document per decision, registry/digest agreement,
document-link audit.

## Gate RRP-006 — Analytics and SBE rationalization

**May start:** after consumer-reference and build-target review.

**Must decide:** one quantitative analytics owner; one cross-repository release contract;
whether custom SBE output still has a consumer; which generated code remains necessary;
one reproducible source of truth per generated file.

**Evidence required:** consumer references, build targets, golden-corpus provenance and the
C++ oracle boundary reviewed. Pure numeric oracle code and `verification/corpus/numeric/`
remain; market-shaped book corpus and market-state oracle leave the active tree only under
RRP-002 with this decision recorded.

## Gate RRP-007 — Final dependency and repository audit

**May start:** after RRP-002..RRP-006 are accepted.

**Must run:** tracked-file inventory; dependency audit; code-reference audit; CI and Make
target audit; documentation link audit; license/provenance audit; architecture boundary
check; workspace consistency audit; full permitted test suites.

**Must publish:** a new deterministic review package with manifest and bundles; updated
`CURRENT-STATE.json`, `REVIEW-LOG.md` and test-retirement record. Test counts stay tied to
their exact commits and repositories (Fieldbook, Nirnay Python, Nirnay Rust separately).

**Fail conditions:** any orphaned dependency, dead Make/CI target, stale capability claim,
untracked data import, or registry/digest disagreement.

## Status summary

| Gate | Scope | Status |
|---|---|---|
| RRP-001 | Policy and manifests | Published for owner approval (this PR); no deletions |
| RRP-002 | Synthetic asset removal | Pending |
| RRP-003 | Fieldbook crypto/prediction scope retirement | Pending |
| RRP-004 | Nirnay source-ingestion freeze and migration | Pending (metadata freeze first) |
| RRP-005 | Documentation consolidation | Pending |
| RRP-006 | Analytics/SBE ownership decision | Pending review |
| RRP-007 | Dependency and repository validation | Pending |

No gate is marked PASS until its evidence is recorded with exact commits in `REVIEW-LOG.md`.
After all gates pass, and only after separate India design ratification, W2.3 implementation
may begin.
