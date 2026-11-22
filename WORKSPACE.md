# siebensterne workspace

## Purpose

Coordinate the development of:

- **Fieldbook** — authoritative source acquisition, raw archive, normalization,
  point-in-time reference data, quality, replay and versioned data releases.
- **Nirnay** — quantitative research, experiments, simulation, portfolio,
  risk, paper trading and separately authorized execution.

The repositories remain independent. This directory is an orchestration repository
and a sibling of the two source repositories, not their parent and not a monorepo.
It contains no source, no submodules, no shared Cargo workspace and no cross-repository
source paths. The local `fieldbook/` and `nirnay/` clones are ignored by this repository.

## Pinned review baseline

| Project | Repository | Baseline |
|---|---|---|
| Fieldbook | https://github.com/siebensterne/fieldbook | `28eb8779ea2aab67ce471d9d3e9f222faf8f7327` |
| Nirnay | https://github.com/siebensterne/nirnay | `437179a8fdd0b1935420d1467f9a5c8a60da824d` |

Both commits were the public `main` heads and matched the uploaded source
archives when this workspace was prepared on 2026-11-22. If `main` moves,
bootstrap refuses to reset an existing checkout. Update the lock only after
reviewing the intervening commits and their evidence.

## Ownership

| Responsibility | Fieldbook | Nirnay |
|---|---|---|
| Source rights and source onboarding | Owns | Consumes release proof |
| Acquisition and source protocol adapters | Owns | No duplicate collector |
| Raw bytes and raw-data lifecycle | Owns | No competing archive |
| Normalization and canonical source events | Owns | Consumes typed data |
| Instrument, listing and point-in-time reference data | Owns | Consumes versioned references |
| Coverage, quality, continuity and replay of raw records | Owns | Consumes certificates |
| Immutable dataset releases | Publishes | References by immutable release ID |
| Research datasets and experiments | No | Owns |
| Backtests and paper simulation | No | Owns |
| Portfolio, account and risk authority | No | Owns |
| Broker OMS and eventual execution | No | Owns under separate authorization |

The proposed Nirnay Data Contract (NDC) is an interface, not a shared source
tree. Fieldbook is the producer and contract publisher; Nirnay is the
consumer. Do not implement a shared crate until a measured need and a separate
architecture decision justify one.

## India-first target

India is the first market programme. Global expansion is a later venue-by-venue
qualification programme, not a claim that a fixed number of countries is
covered.

### India capability families

1. **Reference data:** exchanges, segments, products, issuers, instruments,
   listings, provider mappings, exchange tokens, ISINs, MICs, effective dates,
   suspensions, delistings and contract masters.
2. **Cash securities:** NSE and BSE listed equity, ETFs, SME listings and
   additional listed product families only when their source and terms are
   qualified.
3. **Derivatives:** equity and index futures/options, currency products and
   other exchange segments. Model expiry, strike, option type, lot size,
   tick size, multiplier, settlement and underlying as typed contract data.
4. **Commodities:** MCX commodity contracts first; add another commodity venue
   only after its product, source and rights are qualified.
5. **Market observations:** trades, BBO, MBP, MBO/order lifecycle, instrument
   state, auction/session events, halts and recovery snapshots. The source
   decides which modalities exist. Never infer MBO from MBP, or a trade print
   from an LTP snapshot.
6. **Corporate actions:** dividends, splits, bonus, consolidation, rights,
   mergers, demergers, buybacks, delistings, symbol/name/face-value changes,
   cancellations and corrections. Preserve announcement time, effective
   dates, record/pay dates where applicable, source lineage and revision
   knowledge time. Do not overwrite raw prices with adjusted prices.
7. **Issuer information:** financial statements, filings and announcements
   remain a separate source/document domain. A market-data feed does not
   provide complete fundamental facts.

"All Indian securities" must mean a defined, effective-dated universe across
named venues, segments and products, including delisted and inactive history.
A current instrument master is not a historical universe and cannot prove
survivorship completeness.

## India source and protocol facts to preserve

The following are source-document leads, not acquisition permission:

- NSE describes Level 1, Level 2 (up to five bid/ask levels), Level 3 (up to
  twenty levels) and tick-by-tick full-order-book products. Its real-time feed
  is multicast, supplied over an exchange POP leased circuit or an authorized
  data vendor. Product access is subscription-based.
- NSE's terms of use prohibit systematic or automated data collection on or
  in relation to its website/mobile application. Do not build an HTML scraper,
  disguise automation, rotate identities, evade rate limits or use undocumented
  endpoints.
- NSE's all-reports page lists CM-UDiFF Common Bhavcopy Final and reference
  reports. Availability on a public page does not by itself grant local
  retention, replay, analytics or trading rights.
- BSE's Equity Segment Master Circular identifies EOBI as its order-by-order
  market-data stream. BSE EMDI and MDI are separate price-level aggregated
  interfaces; EMDI and MDI must not be conflated with EOBI.
- MCX lists real-time, delayed, historical and end-of-day products. Its
  published feed process requires a data-feed request and agreement; the
  policy states that subscribers sign an agreement and pay applicable
  charges. Historical order/trade products and selected tick-by-tick history
  must be qualified separately.
- "ITCH" is not a generic Indian exchange protocol. Treat ITCH/PITCH, FAST,
  FIX/SBE, MoldUDP64 and exchange-native feeds as distinct protocol contracts.
  Use the official version for each venue/product. A generic MBO domain event
  does not imply that a venue publishes MBO to this account.

Official references (reviewed 2026-11-22):

- NSE real-time data products:
  https://www.nseindia.com/static/market-data/real-time-data-subscription
- NSE data sharing and usage policy:
  https://www.nseindia.com/static/market-data/nse-data-policy
- NSE website terms of use:
  https://www.nseindia.in/static/nse-terms-of-use
- NSE all reports:
  https://www.nseindia.com/all-reports
- NSE MTBT protocol reference (verify latest version before implementation):
  https://nsearchives.nseindia.com/web/sites/default/files/inline-files/MTBT_FO_NNF_PROTOCOL_6.1_0.pdf
- BSE Equity Segment Master Circular:
  https://www.bseindia.com/markets/MarketInfo/DownloadAttach.aspx?attachedId=8a7fec3a-95bc-4bd2-82de-76e2a84e2915&id=20250429-51
- BSE Market Data Interfaces Manual:
  https://www.bseindia.com/downloads1/BSE_market%20data_manual_v%20136.pdf
- BSE Self Data Feed:
  https://marketdata.bseindia.com/
- MCX data feed:
  https://www.mcxindia.com/technology/datafeed
- SEBI retail algorithmic-trading circular:
  https://www.sebi.gov.in/legal/circulars/feb-2025/safer-participation-of-retail-investors-in-algorithmic-trading_91614.html
- NSE circular 58/2026 dated 2026-11-20:
  https://archives.nseindia.com/content/circulars/INSP77559.pdf

No source document listed here grants rights to this project. Every source/product,
operation, instrument scope, field, territory, purpose, recipient and retention
period must be covered by written permission and owner approval before use.

## Delivery programme

### W0 — Workspace and baseline control

- Bootstrap both repositories at their reviewed commits.
- Record both heads, branch names, dirty state and CI evidence before each task.
- Keep one active, coherent PR per repository; cross-repository changes are
  coordinated as paired PRs.
- Never update one repository silently while the other consumes an unreviewed
  contract.

Exit: both clones verify against the lock; both owners and boundaries are named.

### W1 — Cross-repository contract and governance

- Reconcile Nirnay ADR-0001 with Fieldbook's actual architecture and ratify
  role ownership.
- Approve NDC semantic definitions before schema code.
- Separate a dataset release manifest from per-event envelopes.
- Bind rights, territory, purpose, recipient, retention, coverage, lineage and
  correction status to every release.
- Establish a fail-closed prohibition on all provider access paths until
  written rights and owner approval exist.
- Remove Fieldbook's no-argument live-collect default and ensure every
  provider-contacting command is gated inside the binary, not only in a shell
  wrapper.

Exit: approved architecture and semantic contract; no collection.

### W2 — Fieldbook data-domain foundation for India

- Repair lossy or ambiguous domain semantics identified by the review:
  missing is not zero; scale and unit are explicit; timestamp offset is not
  assumed; identity resolution is observation-time aware.
- Define typed source, venue, segment, product, instrument, listing and
  contract identity.
- Define distinct typed payloads for Trade, BBO, MBP, MBO/order events,
  status/auction, commodity contracts, corporate actions and issuer facts.
- Define source-specific sequence, retransmission, snapshot and recovery
  semantics.
- Connect bitemporal reference data to the accepted event/release path.

Exit: schema and unit tests establish semantics without synthetic market
observations or claims of venue support.

### W3 — Fieldbook durability and release lifecycle

- Close the current local-journal audit findings before reliance.
- Define commit acknowledgement levels and their exact crash semantics.
- Prove partial-write detection, segment rotation, manifest/index publication
  and failure propagation.
- Keep cross-host replication, backup and restore as a separately tested
  durability tier. Do not claim zero loss without a named fault model.
- Make rights and coverage certification mandatory at publication.
- Publish immutable release manifests and a consumer-verifiable release index.

Exit: release verification and recovery tests pass for the declared local fault
model; cross-failure-domain guarantees remain separately labelled.

### W4 — India source qualification and connector onboarding

For each proposed provider/product, record:

- legal entity and venue;
- segment, product, instrument universe and fields;
- protocol/version and distribution path;
- authentication and account eligibility;
- explicit retrieval, storage, backup, replay, internal analytics, derived-data,
  display and redistribution rights;
- retention, termination and deletion requirements;
- sequence, recovery, snapshots, time semantics and corrections;
- sample/reference docs and test permission;
- coverage gaps and certification scope.

No connector may be enabled merely because a public URL or a login exists.

India onboarding order:

1. NSE cash reference and permitted end-of-day source qualification.
2. NSE cash market-data capability qualification.
3. BSE cash reference and permitted end-of-day source qualification.
4. BSE EOBI/EMDI/MDI capability qualification as separate products.
5. NSE/BSE derivatives contract reference and market-data qualification.
6. MCX commodity contract reference and market-data qualification.
7. Other Indian venues/segments after the above have evidence.

Exit: each source has a rights decision and source-specific conformance plan.

### W5 — Nirnay consumer integration

- Consume only immutable Fieldbook releases by release ID and digest.
- Verify schema, source rights proof, release signature/trust, coverage, lineage,
  corrections and point-in-time semantics before dataset admission.
- Preserve separate account-currency money and instrument price/quantity units.
- Extend research and simulation only to products whose accepted data and
  execution semantics exist.
- Do not let a strategy access broker SDK, OMS internals, risk permits, cash or
  positions.

Exit: one accepted release is consumed and independently verified, without
copying or mutating the raw archive.

### W6 — Research and paper evidence

- Require accepted real data before registering an experiment.
- Require a point-in-time universe, delisted securities, corporate actions,
  benchmark history, calendar, trading costs and correction lineage.
- Preserve the frozen M4 holdout.
- Register one strategy hypothesis and falsifier before any parameter search.
- Separate EOD research, intraday MBP research and order-level MBO research.
- No profitability claim without out-of-sample evidence after realistic costs.

Exit: one research result with complete data, code, experiment and validation
lineage. A failed result is an acceptable outcome.

### W7 — Execution readiness

- Keep live order submission disabled.
- Qualify each broker separately and reconcile order states, partial fills,
  rejects, cancels and unknown outcomes.
- Recheck the applicable SEBI and exchange framework, broker requirements,
  static-IP and strategy registration requirements, audit logs and risk controls.
- Paper operation and operational certification precede any separate live
  authorization.

Exit: explicit owner authorization and independently verified compliance and
operational evidence. No milestone in this workspace grants that authorization.

### W8 — Global venue expansion

Do not define global scope as "top 100 countries" yet. A country can contain
multiple exchanges, segments and regulatory regimes. Prioritize venues using
documented market relevance, source availability, lawful rights, protocol
quality, historical coverage and operational cost. Reuse the capability model,
not an assumed universal feed or protocol.

## Hard constraints

- Incremental data budget remains INR 0 until the owner changes it.
- No scraper, HTML harvesting, stealth automation, CAPTCHA bypass, proxy/VPN
  evasion, account rotation, rate-limit circumvention or undocumented endpoint.
- No API call, provider contact, market-data download, capture or experiment
  without written permission and owner approval for the exact operation.
- No synthetic market observations or synthetic performance used as research
  evidence. Historical synthetic assets remain archived. Pure mathematical
  tests are allowed; proposed protocol vectors must not masquerade as market
  observations or enter research datasets.
- No duplicate raw archive in Nirnay.
- No absolute zero-loss, nanosecond, HFT or horizontal-scale claim without
  measurements, clock evidence and a stated fault model.
- No shared crate, database, message bus, cluster or transport selection until
  the contract and workload justify it.
- No live broker order submission.

## Current blockers identified in the supplied source snapshots

1. Fieldbook's governance types and coverage certification are not yet wired
   into all provider-contact and export paths. Its default CLI command is
   `Collect`; remove that default and gate provider contact inside the binary
   before any future source onboarding.
2. Fieldbook's distribution audit identified a verified-export verifier defect,
   run identity mismatch, incomplete export identity, missing release index,
   rights/retention proof and incomplete NDC fields. Do not expose its current
   exports as an accepted NDC release.
3. Fieldbook's durability is local-host only. The audit identified segment,
   acknowledgement, sync-policy, metadata/catalog and failure-propagation
   issues. Backup/restore across failure domains is not implemented.
4. Fieldbook's live event path remains a limited order-book collector; its V2
   domain types are not a connected NSE/BSE/MCX implementation.
5. Nirnay's supplied snapshot is `437179a`, not the earlier `e66a49c` state
   mentioned in conversation. Treat this lock as the reviewed baseline; do not
   combine claims from different commits.
6. Both root Cargo manifests declare `license = "MIT"` while the checked-in
   LICENSE files, ORIGIN.md and SPDX headers declare Apache-2.0. Correct the
   package metadata in separate reviewed PRs before making package/license
   claims or publishing artifacts.
7. The earlier Fieldbook architecture audits in Nirnay target Fieldbook
   `aee91de`; refresh affected audit findings against `28eb877` before treating
   them as an acceptance record. The six intervening commits do not modify the
   rights-gate or analytics-export paths implicated by the principal A4/A5
   findings.

## Done means

A milestone is done only when code, tests, rights evidence, source evidence,
consumer verification, documentation and exact commit/CI records agree.
A green CI result is not a data licence, a complete universe, a correct
backtest or permission to trade.
