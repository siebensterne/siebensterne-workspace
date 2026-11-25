# RRP-006 — Analytics ownership and SBE rationalization decision

Status: **decision record issued under Gate RRP-006** (`RETIREMENT-ACCEPTANCE.md`). This
is a documentation change in the workspace worktree `docs/rrp-006` (base `c36d1d7`). It
deletes nothing, edits no source repository, contacts no provider, changes no right or
data state, and makes no commit. Recording a decision is not gate acceptance: the gate
still requires a reviewed PR with paths, commits and evidence in `engineering/evidence/REVIEW-LOG.md`.

## Source of truth inspected (read-only)

| Repository / record | Head or base | What was inspected |
|---|---|---|
| Fieldbook | `d686067486ebcbedecdf7c62e24d63d9aa7af435` (`main`, clean) | `analytics/q/`, `analytics/python/`, `scripts/analytics/`, `docs/analytics-data-contract.md`, `docs/documentation-consolidation-2026-11-23.md`, `docs/architecture.md`, `sbe_schemas/fieldbook/orderbook.yaml`, `sbe_schemas/includes/common-types.xml`, `src/generated/orderbook.rs`, `tools/sbe-gen/{Cargo.toml,src/main.rs}`, `src/util/{dtos.rs,orderbook_schema.rs,build.rs,aligned_sbe_writer.rs,aligned_sbe_reader.rs}`, `src/storage/analytics{,/export}.rs`, `src/distribution/inspect.rs`, `src/acquisition/{codec.rs,ws.rs}`, `scripts/{check_sbe_generated.py,check_generated_paths.py}`, `git-policy.json`, `xtask/src/main.rs`, `Makefile` |
| Nirnay | `371a7add585b4baee4a37205e71022ed9927461c` (`main`, clean) | `analytics/kdb/`, `apps/kdb-lab/{README.md,Cargo.toml}`, `crates/sbe-codec/{Cargo.toml,src/lib.rs,src/decode.rs,tests/differential.rs}`, `schemas/analytics/kdb-metrics-report.v1.schema.json`, `evidence/{KDB-ANALYTICS-2026-11-20.md,SBE-GAP-2-INVENTORY-2026-11-19.md}`, `Makefile`, `.github/workflows/ci.yml`, `engineering/q-kdb-style.md`, retirement manifests |
| Workspace | worktree base `c36d1d7`, branch `docs/rrp-006` | `RRP-001.md`, `RETIREMENT-ACCEPTANCE.md` (Gate RRP-006), both retirement manifests, `india-domain-ownership-crosswalk.md`, `OWNER-RATIFICATION-2026-11-23.md`, `NDC-REGISTRY.md`, `README.md`, `AGENTS.md` |

The reviewed heads used to build the RRP-001 manifests (`3c3279b` Fieldbook,
`f6842d2` Nirnay) are ancestors of the heads above; RRP-003/RRP-005 and RRP-004/RRP-005
have since executed in the two source repositories. All findings below come from the
current heads, are read-only, and change no approved byte or digest.

Gate run: `make consistency WORKSPACE_DIR=/Users/tourist/Documents/siebensterne-workspace`
printed `CONSISTENCY OK` (tool pins, canonical files, shared-file identity, lock-skew
`ancestor` for both repos, registries present). The override is needed because this
worktree contains no local `fieldbook/` or `nirnay/` clone by design.

## 1. Decisions

| ID | Decision | Owner (accountable role, ratification Decision A) | Disposition / condition |
|---|---|---|---|
| D1 | **One quantitative analytics owner: Nirnay.** Research analytics, KDB/q queries and scripts, experiment registry, backtesting, simulation, portfolio/risk analysis and research datasets belong to the Nirnay consumer owner. Fieldbook may produce **only** the NDC release format required by the contract (release manifest, event envelope and release artifacts/verification under NDC v2); it does not own research analytics or experiments. | Nirnay consumer owner (Kartik Jangid); Fieldbook producer owner (Kartik Jangid) only for release production | Binding decision; Fieldbook does not become a quantitative application (ratification Decision A) |
| D2 | Fieldbook's offline analytics pipeline is **legacy, not an analytics authority**: `analytics/q/` (`common.q`, `create-hdb.q`, `hdb-queries.q`, `parquet-preflight.q`, `query-capture.q`, `query-instruments.q`, `query-journal.q`, `query-orderbook.q`, `verify-hdb.q`), `scripts/analytics/` (`export_parquet.py`, `verify_export.py`, `verify_hdb.py`, `verify_q_queries.py`, tests and `__init__.py`), `analytics/python/` pins, `docs/analytics-data-contract.md` (already marked deprecated by RRP-005), plus the staging/verification code `src/storage/analytics/export.rs` and `src/storage/analytics.rs` that feed that offline export. | Fieldbook producer owner | **CONDITIONAL / DEPRECATE after first accepted NDC v2 release publication** (D7). Retain until then; no new analytics feature in these paths |
| D3 | **KDB tooling stays in Nirnay only**: `analytics/kdb/mbp*.q`, `apps/kdb-lab/`, `schemas/analytics/kdb-metrics-report.v1.schema.json`, `engineering/q-kdb-style.md` and the q-style gate. Defined research responsibility: deterministic, one-source-at-a-time spread/imbalance/gap/depth metrics over a dataset admitted from an **accepted NDC release**, with report schema, input/output digests and no cross-source book merge. | Nirnay consumer owner | KEEP as Nirnay research tooling. Current input path (`.local/perf/kdb/book.csv` via `upstox-decode-export`, `KDB_INPUT ?= .local/perf/kdb/book.csv`) is frozen legacy under RRP-004, is a migration item, and must not be extended or cited as an NDC-sourced input |
| D4 | **NDC v2 is the only cross-repository semantic contract.** The custom internal SBE export/capture format is **not** an interchange contract, release format, transport, shared crate or database. No NDC field is an SBE field; approved NDC digests are unchanged. | NDC contract owner (Kartik Jangid) | Binding decision; no schema or digest change here |
| D5 | The custom SBE format has **no actual consumer outside its producer**. Status **CONDITIONAL / DEPRECATE after first accepted NDC v2 release publication** (evidence in §2). | Fieldbook producer owner for the capture/export format; Nirnay consumer owner for the `sbe-codec` protocol obligation | D7 conditions apply. A future native SBE source is handled by the branch in §2.3, not by keeping the internal export |
| D6 | **Generated code:** Fieldbook `src/generated/orderbook.rs` is derived from `sbe_schemas/fieldbook/orderbook.yaml` + `sbe_schemas/includes/common-types.xml` by `tools/sbe-gen`; that schema/generator pair is its single source of truth. Nirnay `crates/sbe-codec` is a **hand-maintained** decoder for the same frozen challenge wire constants, with no generator in Nirnay. Retention and reproducibility rules in §3. | Fieldbook producer owner (generated artifact and generator); Nirnay consumer owner (`sbe-codec`) | CONDITIONAL with D5; never keep a hand-maintained and a generated copy of the same artifact |
| D7 | Migration is gated and ordered: (1) an accepted NDC v2 release is published and verified; (2) Nirnay admits it and the research dataset manifest cites the exact release identity/digest; (3) KDB research consumes that admitted dataset; (4) Fieldbook's legacy offline export is superseded for every contract-required output; (5) only then are per-path deprecations/removals reviewed with crosswalk updates. | Programme owner; NDC contract owner; both repository owners | No deletion before replacement; no history purge; no new synthetic data (RRP-001 §6 and RRP-004) |
| D8 | This decision does **not** authorise the items in §5. | Programme owner | Explicit non-goals recorded |

Named-role ratification is unchanged: one person may hold several roles, and a repository
name is not an accountable owner (`OWNER-RATIFICATION-2026-11-23.md`, Decision A).

## 2. Cross-repository release contract and the SBE consumer question

### 2.1 The two formats must not be conflated

| | NDC v2 (release contract) | Custom internal SBE format (legacy) |
|---|---|---|
| Authority | Approved semantic requirements, producer digest `215a5b55…`, consumer digest `22eaef7d…`, C0 `3dace660…`; ratification 2026-11-23 | Fieldbook `sbe_schemas/fieldbook/orderbook.yaml` (`id: 1`, `version: 2`, templates 1/2), `common-types.xml`, aligned zero-padded `orderbook.sbe` capture, `docs/analytics-data-contract.md` offline export schema; Nirnay's identically shaped challenge decoder is a separate obligation |
| Role | Only semantic contract between Fieldbook (producer) and Nirnay (consumer) | Producer-side capture/analytics encoding and an independent protocol exercise; no release semantics, no rights, no admission rule |
| Consumer | Nirnay verifier/consumer of an immutable release | None outside the producer (§2.2) |
| Change rule | Paired producer/consumer PRs, lockstep validators, new approved digest for a semantic change | Frozen; no widening, no in-place template edit, no interchange claim |

`NDC-REGISTRY.md` names no transport, queue, shared crate or database; SBE is absent from
the release layers and approval table. The offline export document itself states that no
field of it is an NDC v2 release field and that it grants no right or release acceptance.

### 2.2 Read-only consumer inspection — result: none

- **Fieldbook producer side.** The SBE schema is consumed only by Fieldbook's own
  writer/reader/DTO chain (`src/storage/writer.rs`, `src/util/aligned_sbe_{reader,writer}.rs`,
  `src/util/dtos.rs`, `src/util/orderbook_schema.rs`), its inspect/verify commands
  (`src/distribution/inspect.rs`, `src/storage/analytics.rs`) and its offline export
  (`src/storage/analytics/export.rs`, `scripts/analytics/`, `analytics/q/`). `docs/architecture.md`
  calls it the *supplied SBE capture format* and states that `src/storage/writer.rs` is the
  only SBE writer. All of these are inside the producer.
- **Nirnay side.** `crates/sbe-codec/Cargo.toml` describes a "Self-contained decoder for
  the challenge SBE order-book schema" (id 1, version 2, templates 1/2), retained under
  the `.local/extras/cpp` protocol obligation. Read-only inspection found **no** other
  crate declaring `sbe-codec` as a dependency and no use of `sbe_codec` outside the
  crate's own test target. Its `tests/differential.rs` was rewritten after D11 to build
  arbitrary bytes from an empty-book message; the market-shaped golden corpus
  (`sample_replay.sbe`, `cpp_canonical_dump.txt`, `.meta`/`.sha256` rows) is retired in
  the RRP-001 Nirnay manifest and absent at the inspected head. The decoder therefore
  consumes no Fieldbook-produced SBE artifact and is not a consumer of the producer's
  internal export.
- **Named internal envelope.** The only "internal" SBE file named in the inspected
  records is `schemas/internal/v1.yaml` in Nirnay's dated
  `SBE-GAP-2-INVENTORY-2026-11-19.md`: a Rust-to-C++ envelope explicitly described as
  *not* the challenge SBE schema and *not* decoded by the SBE decoder. It belongs to the
  excluded `.local/extras/` audit, is not a tracked active artifact at the inspected
  head, and records no consumer. It is not an interchange contract.
- **No release path.** The RRP-001 manifests, `NDC-REGISTRY.md` and the ratification
  record contain no SBE-to-release mapping, consumer reference or admission rule.

Conclusion: **no actual consumer exists outside the producer.** The custom SBE format,
its Fieldbook schema/generator/generated codec chain and the Nirnay standalone
`sbe-codec` obligation are **CONDITIONAL** and are deprecated after the first accepted
NDC v2 release publication (D5/D7). `crates/sbe-codec` is retained only as a pure,
arbitrary-byte protocol-obligation decoder while that condition is open; it must never
be presented as the NDC consumer or as evidence of a release.

### 2.3 Branch if a native source uses SBE

At the inspected heads **no native source uses SBE**: venue sessions are websocket
frames decoded by `src/acquisition/{codec.rs,ws.rs}` into normalized events, and SBE is
the supplied capture/analysis encoding written by the single writer. If a future venue
feed is genuinely SBE-on-the-wire, only the **native source-wire decoder** stays in
Fieldbook under acquisition/source-protocol ownership (ratification Decision A); it is
not the internal export. The internal legacy SBE export, its HDB/Parquet analytics and
the duplicate challenge decoder remain subject to D2/D5 deprecation. A native decoder
does not create a cross-repo interchange contract and does not authorise Nirnay to
acquire or archive raw provider data.

## 3. Generated code, source of truth and retention

| Artifact | Source of truth | Reproducibility evidence at inspected head | Retention condition |
|---|---|---|---|
| Fieldbook `src/generated/orderbook.rs` | `sbe_schemas/fieldbook/orderbook.yaml` + `sbe_schemas/includes/common-types.xml`, processed by `tools/sbe-gen` (own `Cargo.toml`/`Cargo.lock` pin, `ergo_sbe`) | `scripts/check_sbe_generated.py` regenerates into a repo-local `.local/sbe-generated-check` scratch directory and fails closed on byte drift; wired through `xtask/src/main.rs` verify. Generation is deliberately outside the build graph; `src/util/build.rs` only refreshes commit env vars. The generated file is included once via `include!` in `src/util/dtos.rs` | KEEP only while the SBE capture/export format is kept. On D5 deprecation, remove generated file, schemas, generator and byte-drift gate in the same reviewed change; never convert it to a hand-maintained codec |
| Fieldbook `tools/sbe-gen` | The schema pair above is the data input; the tool is the generator. One generator, one output module (`orderbook`) | Documented on-demand command `cargo run --locked --manifest-path tools/sbe-gen/Cargo.toml -- --schema-root . --output src/generated`; drift gate above | Same CONDITIONAL condition as the generated file; no second generator and no checked-in hand-edited copy |
| Nirnay `crates/sbe-codec` | Frozen wire constants declared in `src/decode.rs` (`SCHEMA_ID = 1`, `SCHEMA_VERSION = 2`, templates 1 and 2). **No generator and no schema source file exist in Nirnay** | Hand-written fail-closed decoder/encoder with arbitrary-byte round-trip and malformed-input tests in `tests/differential.rs`; `market-shaped-tests` feature is opt-in and never enabled by a default or gate command | CONDITIONAL protocol obligation; deprecate with D5. Must not vendor, copy or import Fieldbook's generated `orderbook.rs`; must not add a generator or a second schema authority. If the obligation is retired, remove the crate and its tests together |

There is no hand-maintained duplicate of the generated Fieldbook codec today:
`src/util/dtos.rs` and `src/util/orderbook_schema.rs` contain conversion wrappers and a
schema adapter, not a second codec implementation. The rule for RRP-007 is binary: one
source of truth per generated file, and never both a generated and a hand-maintained
copy of the same artifact.

The C++ numeric/book oracle boundary recorded for Gate RRP-006 stays as specified: pure
numeric oracle code and `verification/corpus/numeric/` remain; market-shaped book corpus
and market-state oracle leave the active tree only under RRP-002 with this decision
recorded. SBE conformance is a separate protocol obligation and is not evidence from
the numeric/book oracle.

## 4. Migration conditions and sequence

1. Fieldbook publishes the first accepted NDC v2 release: manifest and event envelope,
   declared coverage denominators, digests and verifier evidence per `NDC-REGISTRY.md`
   and the ratification record. Rights remain `UNKNOWN` and dataset acceptance stays
   `BLOCKED` until written evidence and owner approval exist.
2. Nirnay admits that release, records the exact release identity and digest in its
   research dataset manifest, and keeps producer/consumer validators in lockstep.
3. Nirnay's q/KDB research inputs come from that admitted dataset. The pre-existing
   `upstox-decode-export`/`.local` CSV input is frozen legacy under RRP-004; the
   `nirnay-kdb` contract (one source per run, input/output digests, report schema) is
   retained and reused, not reimplemented in Rust or moved to Fieldbook.
4. Fieldbook confirms that every output required by the contract is published in NDC v2
   form; only then do `docs/analytics-data-contract.md`, `analytics/q/`,
   `scripts/analytics/`, `analytics/python/` and the offline staging/verification code
   become removable legacy.
5. Removal executes per path, after `DEPENDENCY-CROSSWALK.csv` updates and a reviewed
   PR; record paths, hashes and exact commits in a dated record and `engineering/evidence/REVIEW-LOG.md`.
   Normal `git rm` preserves history; no history rewrite, no bulk removal and no new
   synthetic replacement (RRP-001 §6, `RETIREMENT-ACCEPTANCE.md` §0).
6. RRP-007 runs the final dependency, build-target, documentation-link and generated-path
   audits over the result.

Until step 4 completes, the legacy assets are retained but frozen: no new analytics
feature, no new SBE template, no new generator, no new experiment and no extension of the
legacy Nirnay CSV export path.

## 5. What is NOT authorised by this decision

- No shared crate, shared Cargo workspace, submodule, vendored source, domain-model copy
  or generated-code copy between Fieldbook and Nirnay.
- No transport, queue, broker connection, live routing, database or new store; no change
  to the `NDC-REGISTRY.md` "no transport chosen" position.
- No provider contact, collection, adapter execution, download, scrape, experiment,
  backtest run against provider data, or market-data operation of any kind.
- No rights change, dataset acceptance, signature-key action, provider-data retention or
  distribution; rights stay `UNKNOWN`, dataset acceptance `BLOCKED`, experiment
  registration blocked, live execution `DISABLED`.
- No NDC semantic change, schema widening, new version, or edit of an approved byte or
  digest; no silent change to the ratification record.
- No deletion in either source repository, no history rewrite, no replacement synthetic
  data, no marking of RRP-002..RRP-007 gates as passed and no commit in this worktree.
- No Fieldbook research analytics/KDB/q work and no Nirnay raw acquisition, raw archive
  or source decoder; no treating the SBE codec, the q metrics harness or the C++ oracle
  as an NDC release verifier.

## 6. Document map

The row for this record is added to the `README.md` "Start here" table. This document is
an RRP-006 decision record alongside `RRP-001.md` (policy), the two manifests,
`DEPENDENCY-CROSSWALK.csv` and `RETIREMENT-ACCEPTANCE.md` (gates); it does not replace
`NDC-REGISTRY.md` or the owner ratification as authorities for contract and ownership.
