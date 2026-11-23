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
| `TOOL-MATRIX.md` | canonical tool versions, command surface and preserved differences |
| `ADR-REGISTRY.md` | collision-free canonical ADR IDs across both repositories |
| `NDC-REGISTRY.md` | NDC version, producer/consumer and compatibility rules |
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
```

`make check-fieldbook-static` and `make check-nirnay-static` share one meaning: static
gates only, no tests, no e2e, no provider contact. Fieldbook's fixture inventory is
under owner review and Nirnay deselects `market_shaped_fixture`; those policies are
preserved.

## Boundaries

No provider contact, market-data download, scraper, collector execution, experiment,
live order, synthetic market observation, shared crate, queue, database or transport
choice is authorised by this repository. Rights remain `UNKNOWN` and dataset acceptance
remains `BLOCKED` until written evidence and owner approval exist.
