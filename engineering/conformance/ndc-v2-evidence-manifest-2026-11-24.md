# Dated evidence manifest — PR 0 evidence baseline reconciliation, 2026-11-24

Date: `2026-11-24`. Verification timestamp: `2026-11-24T15:06:04Z`.
Scope: docs/JSON only. This manifest is the dated evidence entry for the PR 0
reconciliation. It records exact commits, evidence digests, the commands used
to compute those digests, and the gate results. It does not record its own
digest and does not digest `CURRENT-STATE.json`, so no circular evidence claim
is created; `CURRENT-STATE.json` records this file's SHA-256 as the
`local_tested_source_head` evidence digest and in its `evidence_manifest` entry.

## Exact commits observed

| Repository | Commit | Worktree | Method |
|---|---|---|---|
| fieldbook | `475dc34c8cc510ac8dfba158dfdedbd91950f219` | clean, branch `main` | `git rev-parse HEAD` + `git status --short` in the local clone |
| nirnay | `70716ebf66289a86335641847724fd92bf6bcce7` | clean, branch `main` | `git rev-parse HEAD` + `git status --short` in the local clone |
| workspace | `62b617c380ea97cd2a68f67c880a1f652ef14961` | clean, branch `main` | `git rev-parse HEAD` + `git status --short` in the worktree |

Local clone paths: `/Users/tourist/Documents/siebensterne-workspace/fieldbook`
and `/Users/tourist/Documents/siebensterne-workspace/nirnay`. Both heads are
descendants of the historical bootstrap pins in `WORKSPACE.lock.json`; the pins
themselves were not changed. The workspace head was pushed before this task.

## Evidence digests

| Evidence item | SHA-256 | Command | Supports |
|---|---|---|---|
| `WORKSPACE.lock.json` | `009c1f0c177ca41d4971ab1209ebbaf9f24ab632e037594b3a4cc1a15242d2b2` | `shasum -a 256 WORKSPACE.lock.json` | dated source-head reconciliation block; `current_source_head` |
| `REVIEW-LOG.md` | `9be4a1fdb7e6b2749846b43c885fd9ec003b3de7f77604b23fe90fa4140b562c` | `shasum -a 256 REVIEW-LOG.md` | hosted CI run IDs and outcomes; `ci_verified_source_head` and `reviewed_source_head` |
| `engineering/conformance/ndc-v2-cross-execution-2026-11-24.md` | `82bc253760ada2e932931877092d93e7238f95a33709844a956870140dea1f0b` | `shasum -a 256 engineering/conformance/ndc-v2-cross-execution-2026-11-24.md` | canonical cross-execution record; `cross_execution_source_head` |
| `engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md` | `a81b0f0256ac214db44a0843961f5c9a6c13db3d29fa9926558a588580e8fc58` | `shasum -a 256 engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md` | dated current baseline record; receipts distinction |

The historical production-builder section publishes no separate SHA-256, so
the canonical cross-execution record's SHA-256 is used as the cross-execution
evidence digest, as required. No SHA-256 of this manifest is written inside the
manifest itself.

## Gate results at this reconciliation

| Gate | Command | Exit | Result |
|---|---|---|---|
| Workspace consistency | `make consistency` | 0 | `CONSISTENCY OK` (tool pins, canonical root files, byte-identical shared files, lock skew `ancestor` for both repositories, registries present) |
| Workspace audit | `make audit` | 0 | status + consistency + `check-all`; Fieldbook `make check-static` passed (fmt, clippy, docs, style, prose, ruff, pyink, q-style, quality contract, license provenance, shellcheck, cross-pollution, rust style); Nirnay `make check-static` passed |

Local clones were symlinked into the worktree only for the gate runs; the
symlinks were removed afterwards and no clone's source was edited. An initial
`make audit` attempt failed before any edit because a prebuilt ignored `xtask`
binary retained a compile-time working-directory path that no longer exists;
rebuilding that ignored artifact with `cargo clean -p xtask` in the Fieldbook
clone resolved the environment issue with no source change and no gate change.
The successful rerun above is the recorded gate result. No gate was weakened;
no Fieldbook fixture/e2e suite, Nirnay full suite, CI run or cross-execution was
re-run by this documentation work, and no test count was combined across heads.

## Derived summaries reconciled

- `CURRENT-STATE.json`: `generated_utc_date` `2026-11-24`; five explicit
  source-head evidence concepts with separately evidenced `repository`,
  `commit_sha`, `clean_worktree`, `verification_method`, `workflow_or_command`,
  `run_id`, `result`, `verification_timestamp` and `evidence_digest` fields;
  legacy mixed head keys retained with explicit HISTORICAL notes; historical
  cross-execution and production-builder parity entries preserved; dated
  `evidence_manifest` entry pointing to this file.
- `engineering/conformance/ndc-v2-cross-execution-2026-11-24.md`: reconciliation
  notice and current pointer; historical sections unchanged.
- `engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md`:
  exact commits, commands, release layout, stage results and the two-receipt
  distinction.
- `README.md` document map and `REVIEW-LOG.md`: dated entries matching the
  heads, run IDs, digests and gate results above.
- `WORKSPACE.lock.json`: dated source-head reconciliation block; historical
  bootstrap `baseline_commit` pins unchanged.
- `ENGINEERING-DOC-DIGESTS.json`: dated digest entries for the two new records.

## Freeze

Rights `UNKNOWN`, dataset acceptance `BLOCKED`, incremental data budget INR 0,
collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`, D11
strict. No source, schema, right, data, provider, India implementation or
experiment change; no commit created.
