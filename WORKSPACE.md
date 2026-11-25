# siebensterne workspace

## Purpose

Coordinate two independent repositories:

- **Fieldbook** — authoritative source acquisition, raw archive, normalization,
  point-in-time reference data, quality, replay and versioned data releases.
- **Nirnay** — quantitative research, experiments, simulation, portfolio, risk
  and separately authorized execution.

This directory is an orchestration repository and a sibling of the two source
repositories, not their parent or a monorepo. It contains no source, no
submodules, no shared Cargo workspace and no cross-repository source paths.
The local `fieldbook/` and `nirnay/` clones are ignored.

Bootstrap baselines and registries live in `WORKSPACE.lock.json`; current
status, freezes and authorizations live in `CURRENT-STATE.json`. Historical
programme records live in `engineering/evidence/`.

## Ownership

| Responsibility | Fieldbook | Nirnay |
|---|---|---|
| Source rights and onboarding | Owns | Consumes release proof |
| Acquisition and source adapters | Owns | No duplicate collector |
| Raw bytes and raw-data lifecycle | Owns | No competing archive |
| Normalization and canonical source events | Owns | Consumes typed data |
| Instrument, listing and point-in-time references | Owns | Consumes versioned references |
| Coverage, quality, continuity and replay | Owns | Consumes certificates |
| Immutable dataset releases | Publishes | References by release ID |
| Research datasets and experiments | No | Owns |
| Backtests and paper simulation | No | Owns |
| Portfolio, account and risk authority | No | Owns |
| Broker OMS and eventual execution | No | Owns under separate authorization |

NDC is an interface contract, not a shared source tree. Fieldbook is the
producer and contract publisher; Nirnay is the consumer. Do not create a shared
crate, database, bus or transport without a measured need and an accepted ADR.

## Global mission

India is the first market programme; global expansion is venue-by-venue
qualification, not a fixed country count. Source and protocol facts that must
survive design changes are recorded in the owned design and decision documents:
`engineering/design/india-national-domain-catalogue.md`,
`engineering/decisions/IN-COUNTRY-001-india-country-pack-design.md` and
`engineering/decisions/WS-SCOPE-2026-11-24-001-global-reference-core-india-first.md`.
These are proposals unless an ADR records acceptance; do not infer approval
from their presence.

## Development principles

- One bounded change per PR, with tests for behavior and failure paths.
- Read only the contract, decision, source and tests that own the task.
- Add or identify the falsifier before implementation; smallest change that
  satisfies the invariant.
- Run the owning repository's required gates and report exact commands, exits,
  commits and CI head. Static gates, tests and deployment qualification remain
  separate claims.
- Get independent review for rights, persistence, concurrency, security,
  financial and execution changes.
- Preserve immutable evidence and approved bytes. Update current records with
  the code; never rewrite history to make it current.
- Do not add a Markdown file for routine work. Source, tests, the PR and CI are
  the default record; a new document must own a stable contract, decision,
  procedure or evidence artifact.

## Hard constraints

Current numeric and Boolean states are in `CURRENT-STATE.json`; this section
states the durable rules those values express.

- No data budget expansion without owner approval.
- No scraper, HTML harvesting, stealth automation, CAPTCHA bypass,
  proxy/VPN evasion, account rotation, rate-limit circumvention or
  undocumented endpoint.
- No provider contact, download, capture or experiment without written
  permission for the exact operation and scope.
- No synthetic market observation or synthetic performance as research
  evidence. Abstract protocol and pure mathematical tests remain separate.
- No duplicate raw archive in Nirnay.
- No absolute zero-loss, nanosecond, HFT or scale claim without measurement,
  clock evidence and a stated fault model.
- No live broker order submission.

## Historical record

W1.1 and W2.1 programme records are preserved in
`engineering/evidence/W1.1-COMPLETION-RECORD.md` and
`engineering/evidence/W2.1-READINESS-REPORT.md`. Owner decisions and cross-
repository issues are recorded in `engineering/evidence/REVIEW-LOG.md`. Phase
acceptance evidence is under `engineering/conformance/`. These are historical
records and are not current status.

## Done means

A milestone is done only when code, tests, rights evidence, source evidence,
consumer verification, documentation and exact commit/CI records agree. A green
CI result is not a data licence, a complete universe, a correct backtest or
permission to trade.
