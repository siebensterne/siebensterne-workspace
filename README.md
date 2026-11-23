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
