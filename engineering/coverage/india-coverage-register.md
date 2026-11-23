# India coverage register — W2-A

- **Status:** Proposed documentation register. It defines how India coverage will be measured
  and the order in which coverage work may be qualified. It is not a data licence, does not
  assert that any data exists or is available, and does not accept, reject or qualify a dataset.
- **Task / branch / base:** W2-A · branch `docs/w2-coverage` · workspace base `90be2f6`.
  No commit, push, paired PR, source-repository edit, provider contact or collection is part of
  this work.
- **Method:** read-only inspection of workspace documents at the base above. No source
  repository was inspected or modified, no schema was published and no provider, exchange or
  public source was contacted. Findings about code or contracts are cited from the crosswalk's
  verified findings (F1–F12) and are not re-derived here.
- **Authority read:** `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md` (ratified
  ownership roles and NDC v2 semantics; coverage has per-dimension denominators; not a data
  licence), `engineering/architecture/india-domain-ownership-crosswalk.md` (domain crosswalk,
  findings I1–I6 migration register) and `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md`
  (C0; §1 six separable concepts, §2 scope containment, §5 three independent proofs, §6
  coverage dimensions, §8 lineage).

## 1. What "measurable coverage" means

A coverage statement is measurable only when it is a ratio of the form **qualifying objects /
declared denominator**, where both sides are evaluated at a declared as-of time, under a named
source authority, over a declared venue, segment, product, instrument type, listing status and
historical period, with declared reference fields and declared effective-date semantics. If any
of those axes is missing, the number is not a coverage measurement and must not be recorded as
one. Annex: this register records no measured number at all; it defines the axes only.

| Axis | Measurable definition | Evidence required before a number is meaningful | Current state |
|---|---|---|---|
| Venue | Coverage is asserted per venue identity (for example NSE, BSE, MCX) with operator and MIC role where declared. "India" is not a venue and is not a denominator. | A Fieldbook venue assertion in an admitted release; a declared venue set. | No admitted venue assertion. Nirnay's two-value `Venue` enum is a closed projection, not a venue registry (crosswalk §2, F1). |
| Segment | Coverage is asserted per market-segment identity attached to a listing. A segment is optional and is never invented where a venue publishes none. | A Fieldbook segment identity and its rules in a versioned release. | Cash only in the v2 surface; no admitted segment assertion. New segments require a versioned contract, not an enum edit (F9, F11). |
| Product | Coverage is asserted per declared product family (cash equity, ETF, index, derivative, commodity, currency, debt, other) with a declared family universe. | A declared product-family set in the release; an admitted typed payload. | Families are listed as priorities below, not adopted. An enum variant is not a supported product (F8). |
| Instrument type | Coverage is asserted per canonical instrument type carried by an admitted contract. | The instrument-type universe of that contract version, with each object resolving to a Fieldbook ID. | v2 carries `Equity`/`Etf` only; `Future`, `Option`, `CurrencyPair` and `Bond` are in-memory variants rejected by `to_wire()` (F8). |
| Listing status | Active, suspended and delisted objects are counted against effective-dated listing assertions carrying status and `valid_from`/`valid_to`. Symbol and token are attributes, not identity keys. | Effective-dated listing assertions with status and revision lineage; point-in-time resolution, never a live master snapshot. | Unavailable. Local `(venue, symbol)` resolution has no validity interval, so status and symbol reuse cannot be represented (F2, F12). |
| Historical period | A `[from, to]` data-time interval plus an independent operational-time interval; an unbounded request requires an unbounded grant. A period is covered only when every in-scope interval in its denominator has evidence. | Declared intervals in the release manifest, rights scope that contains them, and correction lineage. No synthetic or reconstructed reference history. | No period is declared or claimed. Bounded rights cannot cover unbounded history (C0 §2.3). |
| Reference fields | Coverage is field-level: each field has an original field name, unit, domain, source authority and validity/knowledge interval. Exact decimals and large integers are strings, not IEEE 754 numbers. ISIN and name are identifiers/attributes, not identity. | A field list per contract version with unit and domain declared; effective-dated assertions from the release. | No admitted field set. Paise and lots are India cash units and must not be promoted globally (F6). |
| Corporate-action coverage | Declared action universe per instrument and per period, with announcement/knowledge time, revision identity and supersession. | Fieldbook action events with revision lineage in the admitted release. | Unavailable. The embedded array is a snapshot without provenance or revision chain, and the local ledger rejects a corrected action in the same slot (F4, F10). |
| Contract coverage | Declared derivative or commodity contract set, with product family, expiry, strike, option kind, underlying canonical ID, multiplier/unit and effective terms. | A versioned Fieldbook contract and an admitted release resolving every contract to canonical IDs. | No ingested contract and no contract schema in the current v2 surface; variants do not establish support (F8, F9). |
| Source authority | Every coverage number names the release identity, manifest digest, raw digest and authoritative producer assertions it was derived from. | Fieldbook as producer and authority; Nirnay consumes a derived projection only. | No admitted release or digest. A signature proves publisher-key control and manifest integrity, not source authenticity, coverage or rights (C0 §5, ratification Decision B). |
| Effective-date coverage | Each assertion carries valid-time and knowledge-time intervals (`valid_from`, `valid_to`, `observed_at`, `recorded_at`); validity and knowledge are independent. Measured as the fraction of denominator assertions with complete, declared intervals. | Bitemporal assertions in the release; an explicit gap policy. | Unavailable. Adapter convenience mappings stamps zero timestamps and are not India assertions (F1). |

### 1.1 "All Indian securities" is not yet a testable requirement

The phrase is rejected as a scope statement and as a denominator. Reasons:

1. No admitted release declares an authoritative universe of Indian securities. There is nothing
   to enumerate and nothing to divide by.
2. Rights are `UNKNOWN` and the incremental data budget is INR 0. No provider master, exchange
   master, vendor list or public listing can be downloaded, scraped or enumerated to build such
   a universe.
3. Dataset acceptance is `BLOCKED` and no India research dataset is admitted, so there is no
   object against which a coverage measurement could be made.
4. "India" spans multiple venues, segments, instrument types, listing statuses and historical
   periods. A single label cannot supply any one of the denominators in §3, and a security is not
   a single kind of object across those axes.
5. Effective-dated identity, listing status, delisting and identifier reuse require asserted
   intervals. Public availability, a ticker list, an ISIN or a successful connection is not
   authority or permission (C0 §1; `AGENTS.md` rule 10).
6. An index constituent, a derivative contract, a commodity contract and a debt instrument are
   different objects with different denominators; they cannot be folded into one "securities"
   set.

No coverage percentage — including 0% — is asserted here as a measured value. Every phase status
in §2 is **not yet qualified — rights UNKNOWN**.

## 2. Priority register I1–I6

Ordering is a development sequence, not a claim that any of these datasets exists, is attainable,
or is licensed. Each phase may begin only when the Fieldbook assertions named in the crosswalk's
phase table are published in an admitted NDC release and the owner gates are satisfied. Nirnay
work in every phase is consumption plus a derived projection only.

| Phase | Scope | Venue / segment | Denominator dimensions that gate the phase | Fieldbook prerequisite (crosswalk §4) | Status |
|---|---|---|---|---|---|
| I1 | NSE/BSE cash equities and ETFs | NSE, BSE / cash | instrument, listing/identity, corporate action, session/time (plus trade, quote/depth, MBO, sequence only for a separately admitted observation release) | Canonical IDs, effective-dated venue identifiers, listing terms and ticks, action revisions, calendar/session coverage, raw digest in one release | Not yet qualified — rights UNKNOWN |
| I2 | Indices and point-in-time constituents | NSE, BSE (other venues only with a new assertion) / index family, not a cash segment | instrument (index IDs), listing/identity (membership intervals); observation dimensions only if an index series is admitted | Index identities and effective-dated `constituent_of` edges; index family distinct from any tracked instrument | Not yet qualified — rights UNKNOWN |
| I3 | NSE/BSE equity and index derivatives | NSE, BSE / new versioned derivative segment | contract (primary), instrument, listing/identity; observation dimensions separately | New versioned contract with family, expiry, strike, option kind, underlying canonical ID and effective terms | Not yet qualified — rights UNKNOWN |
| I4 | MCX commodity contracts | MCX / new venue-operator and segment assertions | contract (primary), instrument, listing/identity, session/time (MCX calendar) | New MCX venue/operator assertion, commodity product identities, contract specs, units/grades and effective terms in a versioned release | Not yet qualified — rights UNKNOWN |
| I5 | Currency and debt products | In-scope venues / per versioned release | instrument, listing/identity, corporate action, contract where the product has a contract object | Entity/issuer IDs, ISO 4217 currency assertions, debt specifications (issuer, coupon, maturity, seniority) in a versioned release | Not yet qualified — rights UNKNOWN |
| I6 | Other Indian products and venues | Per domain / per versioned contract | Per-domain denominator declared in that domain's contract; no reuse and no roll-up | Per-domain versioned contract, typed payload, unit declarations, rights scope and coverage denominator | Not yet qualified — rights UNKNOWN |

### I1 — NSE/BSE cash equities and ETFs

- **Product families:** NSE and BSE cash equities and ETFs; cash segment only, matching the
  current `instrument.v2.json` surface. No other family is in scope here.
- **Instrument types:** `Equity` and `Etf` only — the two types the v2 wire contract admits.
  `Future`, `Option`, `CurrencyPair` and `Bond` must be rejected under v2 (F8, F11).
- **Active / suspended / delisted coverage:** all three statuses must be effective-dated listing
  assertions with `valid_from`/`valid_to` and resolution as of a decision date. Symbol and token
  are attributes of the assertion, never identity lookup keys. No status count is available;
  the `(venue, symbol)` registry cannot represent status history (F2).
- **Historical period:** declared `[from, to]` in the release manifest, contained by the rights
  scope; no synthetic or reconstructed reference history. No period is claimed.
- **Reference fields:** canonical instrument, venue and listing IDs; effective-dated venue
  identifiers (symbol, token, ISIN, name); listing terms such as settlement regime, z-category
  and settlement group; tick assignments. Each field must name its original field, unit and
  domain from the release.
- **Corporate actions:** Fieldbook action events with revision identity, announcement and
  knowledge time and supersession. The embedded snapshot array and the local ledger are frozen
  legacy, not action evidence (F4, F10).
- **Contract coverage:** cash instrument terms only, where the release declares them; no
  derivative or commodity contract. If no contract object is declared for a family, that is
  recorded explicitly as *not applicable*, not as a pass or a zero.
- **Source authority:** one admitted Fieldbook NDC release with release identity, manifest
  digest, data digest, raw digest and rights evidence; Nirnay binds `InstrumentId`/`ListingId`
  from it and freezes local allocation for production.
- **Completeness denominator:** the instrument, listing/identity, corporate-action and
  session/time denominators of that same release. Trade, quote/depth, MBO and sequence
  denominators are declared only if a separate observation release is admitted, and then
  separately.
- **Current status:** **not yet qualified — rights UNKNOWN.** No admitted I1 release exists and
  the crosswalk's I1 assertions are not yet published.

### I2 — Indices and point-in-time constituents

- **Product families:** index identities and index families on already-qualified venues; an
  index family is distinct from any instrument it tracks. Other venues enter only with a new
  venue assertion.
- **Instrument types:** index reference objects and constituent membership edges. Membership is
  not a tradable instrument and must not inherit an equity type without a separate admission.
- **Active / suspended / delisted coverage:** indices do not have a security listing status in
  this phase. Membership state (member as of a date / former member) is derived from
  effective-dated `constituent_of` edges; a hand-built or live constituent list is not evidence.
- **Historical period:** declared membership intervals with as-of queries and revision/knowledge
  time. No membership history is claimed.
- **Reference fields:** index ID, index-family ID, constituent canonical instrument ID,
  `effective_from`/`effective_to`, and any declared weight with its unit and domain. No local
  index identity; no inference from index name or symbol.
- **Corporate actions:** index revisions are consumed as reference corrections with revision and
  supersession lineage. Corporate actions affecting constituents come from the I1 release only
  and are never locally reconstructed.
- **Contract coverage:** none in this phase. Index derivatives belong to I3 under a new versioned
  contract; declared here as *not applicable*, not as covered.
- **Source authority:** Fieldbook index identity and constituent edges in an admitted release;
  Nirnay holds a read-only membership projection. No local index ID or constituent authority.
- **Completeness denominator:** instrument (index IDs) and listing/identity (membership
  intervals). Where an index level or return series is admitted, an observation denominator is
  declared for it separately. The declared point-in-time universe is the survivorship
  denominator (C0 §6).
- **Current status:** **not yet qualified — rights UNKNOWN.** No index identity or constituent
  edge assertion has been admitted.

### I3 — NSE/BSE equity and index derivatives

- **Product families:** NSE/BSE equity futures and options and index futures and options, each
  under a new versioned Fieldbook contract. The existing v2 surface must not be widened (F9,
  F11).
- **Instrument types:** `Future` and `Option` only when carried by that contract version with
  evidence. The in-memory variants do not establish support, and `to_wire()` must continue to
  reject them under v2 (F8).
- **Active / suspended / delisted coverage:** active, expired, suspended and delisted contract
  states must come from effective-dated contract assertions. A derivative's status is not
  inherited from its underlying's status.
- **Historical period:** declared contract history with expiry and effective terms, contained by
  rights scope; no inferred or synthetic series.
- **Reference fields:** product family, expiry, strike as an exact decimal string with unit and
  domain, option kind, underlying canonical ID, multiplier/lot with unit and domain, and
  effective term intervals. No global paise/lot assumption (F6).
- **Corporate actions:** term adjustments arising from Fieldbook action revisions with lineage;
  no locally corrected action and no embedded snapshot as adjustment evidence.
- **Contract coverage:** the primary dimension of this phase — the declared derivative contract
  set (product family × expiry × strike × option kind × underlying) in the admitted versioned
  release, with every contract resolving to Fieldbook IDs.
- **Source authority:** the Fieldbook-owned versioned contract and its admitted release; Nirnay
  adds an ingestion path for that contract version only and rejects derivative variants presented
  under v2.
- **Completeness denominator:** contract coverage plus instrument and listing/identity from the
  same release. Quote/depth, trade, MBO and sequence continuity require a separately admitted
  observation release and their own denominators.
- **Current status:** **not yet qualified — rights UNKNOWN.** The required versioned contract has
  not been published.

### I4 — MCX commodity contracts

- **Product families:** MCX commodity futures, options and other MCX commodity contracts, each
  under a versioned contract. No MCX family is assumed from the current cash taxonomy.
- **Instrument types:** commodity contract types declared by that contract, with units and grades
  named; no reuse of the closed cash `Venue`/`Segment` enums without a versioned change (F9,
  F11).
- **Active / suspended / delisted coverage:** active, expired, suspended and delisted commodity
  contract states from effective-dated assertions; no status inferred from a commodity name or a
  continuous series.
- **Historical period:** declared contract-history interval with session and timezone semantics
  from the release; no period claimed.
- **Reference fields:** commodity product identity, contract specification, unit, grade, expiry,
  underlying where applicable, and MCX venue/operator identity with MIC role. Units and domains
  are declared per field (F6).
- **Corporate actions:** not generally applicable to a physical commodity contract. Any applicable
  revision, roll or correction must carry revision/supersession lineage; if the release declares
  none, that is recorded explicitly as *not applicable*.
- **Contract coverage:** the declared commodity contract set and unit/grade set in the versioned
  release; this is the phase's primary denominator.
- **Source authority:** Fieldbook's MCX venue/operator assertion and commodity contract release.
  MCX must not be added to the closed Nirnay `Venue` enum or the v2 segment list without a new
  contract version.
- **Completeness denominator:** contract coverage, instrument/listing identity and MCX
  session/time from that release. Other dimensions are declared only from other admitted
  releases; no cross-release roll-up.
- **Current status:** **not yet qualified — rights UNKNOWN.** No MCX assertion or release exists.

### I5 — Currency and debt products

- **Product families:** currency pairs and debt instruments (for example bonds) on in-scope
  venues, with ISO 4217 currency assertions and entity/issuer identity.
- **Instrument types:** `CurrencyPair` and `Bond` only when carried by a versioned contract with
  evidence. Their presence as in-memory variants does not make them supported under v2 (F8).
- **Active / suspended / delisted coverage:** effective-dated listing assertions for the debt or
  currency instrument, including maturity/redemption state where declared. No issuer grouping or
  status is inferred from a name or ISIN.
- **Historical period:** declared coupon, maturity and seniority effective windows within a
  declared data-time interval; no synthetic reference history.
- **Reference fields:** Fieldbook issuer/entity IDs, currency IDs with ISO 4217 assertion,
  coupon, maturity, seniority and exact decimal values as strings. ISIN is an identifier, not an
  identity, and no local entity allocator is used (crosswalk §2).
- **Corporate actions:** coupon changes, redemptions and restructurings where declared, with
  revision and supersession lineage; no locally corrected action and no embedded snapshot.
- **Contract coverage:** the declared debt/currency contract set where a contract object exists.
  For products with no contract object, this is declared explicitly as *not applicable*.
- **Source authority:** Fieldbook entity/issuer and currency assertions in a versioned admitted
  release; no locally minted entity or currency identity.
- **Completeness denominator:** instrument, listing/identity and corporate-action denominators
  from the release, plus contract coverage where applicable; quote/depth separately for any
  admitted observation release.
- **Current status:** **not yet qualified — rights UNKNOWN.** No issuer, currency or debt
  assertion has been admitted.

### I6 — Other Indian products and venues

- **Product families:** news, economic observations, commodity assessments, additional Indian
  venues and any later data category, each admitted case by case.
- **Instrument types:** the typed payload of that domain's versioned contract; there is no
  default type and no automatic reuse of an I1–I5 type.
- **Active / suspended / delisted coverage:** per-domain object identity and validity where the
  domain has a listing concept; otherwise *not applicable* is declared explicitly. Nothing is
  inferred from text or a vendor label.
- **Historical period:** declared per-domain interval with unit and timezone semantics; no
  synthetic observations or reference history.
- **Reference fields:** typed fields with declared units, domains, source authority, validity and
  knowledge intervals, plus a declared rights scope for each domain.
- **Corporate actions:** per-domain revision and invalidation lineage where applicable; otherwise
  explicitly *not applicable*. No universal action shape is assumed.
- **Contract coverage:** the declared object set of that domain's contract. A derivative contract
  shape is not assumed for news, economic observations or assessments.
- **Source authority:** a per-domain versioned contract and an admitted release with rights
  evidence; a case-by-case consumer use profile and admission receipt for each dataset.
- **Completeness denominator:** declared in that domain's contract. No dimension from another
  phase is reused and no aggregate across domains is formed.
- **Current status:** **not yet qualified — rights UNKNOWN.** No additional domain has been
  admitted.

## 3. Per-dimension denominators (C0 §6)

C0 §6 requires a distinct universe and denominator for every coverage dimension. The ratification
record makes the same rule binding: coverage has per-dimension denominators and one successful
dimension never implies another. The nine dimensions are:

| Dimension | Denominator (C0 §6) | What it does not establish | Current state in this register |
|---|---|---|---|
| Instrument coverage | declared point-in-time instrument universe | listings, contracts, actions or any observation | No universe declared; not measured |
| Listing / identity coverage | declared listing and identifier assertions | identity correctness from a symbol, ISIN or token | No assertions admitted; not measured |
| Contract coverage | declared derivative or commodity contract set | that an enum variant is an ingested contract | No contract set admitted; not measured |
| Corporate-action coverage | declared action universe per instrument and period | adjustment correctness or revision lineage from a snapshot | No action universe admitted; not measured |
| Session / time coverage | declared venue calendar and session intervals | intraday sessions from a date-only holiday list | No calendar artifact admitted; not measured |
| Trade-event coverage | declared trades in scope | quote, depth or MBO coverage | No trades admitted; not measured |
| Quote / depth coverage | declared BBO or MBP levels and snapshots | trade or order-lifecycle coverage | No levels or snapshots admitted; not measured |
| MBO coverage | declared order lifecycle events | quote or depth coverage | No order events admitted; not measured |
| Sequence continuity | declared sequence ranges and gap policy | that any other dimension is complete | No ranges or gap policy admitted; not measured |

**One aggregate coverage count is explicitly rejected.** The nine denominators are not
commensurable, are not additive, and must not be combined into a single coverage percentage,
score, roll-up or "fully covered" statement in any register, manifest, admission receipt, release
note or experiment. Passing one dimension never implies passing another. A dimension that does
not apply to a phase must be declared explicitly as *not applicable* for that phase; it is neither
a pass nor a zero and does not enter any other dimension's denominator. Physical line counts,
such as the `provenance_for_source()` `record_count` described in crosswalk finding F5, are not a
denominator for any dimension: they count physical lines, not logical records, and are not a
declared universe.

## 4. Boundaries and current state

This document is a **development sequence**, not a claim of data availability. Every phase above
is a set of conditions to be met before work may qualify; none records that data exists, has been
sourced, has been acquired or can be licensed.

- No provider download, reference-data retrieval, historical retrieval, real-time capture,
  source contact, scraper, collector, adapter execution, market-data API call or website harvest
  is authorised by this register.
- No code, schema, contract version, transport, storage choice or dataset publication is
  authorised here. The v2 schema must not be widened to represent new venues, segments,
  instrument types, units or action fields (F11).
- Incremental data budget: **INR 0**.
- Provider/source rights: **`UNKNOWN`** (21 `UNKNOWN` in `CURRENT-STATE.json`). Public
  availability or a successful connection grants nothing.
- Dataset acceptance: **`BLOCKED`**. No India dataset is admitted or qualified.
- Experiment registration: **blocked**. Research may not use an unadmitted release.
- Live execution and order submission: **disabled**.
- Synthetic market-shaped tests remain disabled; no synthetic price bar, order book, trade,
  universe, reference history or strategy return may be used as coverage evidence.
- The ratification document approves architecture and contract semantics only. It is not a data
  licence and does not accept a dataset. This register does not ratify any decision, change any
  rights state or open any gate.

## 5. Connections

- `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md` — ratified roles and NDC v2 semantics;
  Decision B requires per-dimension coverage denominators.
- `engineering/architecture/india-domain-ownership-crosswalk.md` — source of the phase scopes
  I1–I6, verified findings F1–F12 and the authorization boundary; this register applies its
  sequence to coverage measurement.
- `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` — C0 §6 denominators, §2 scope
  containment, §5 independent proofs and §7 release → admission → research dataset identity
  chain. This register is an application of that model, not a new contract version and not an
  admission receipt.
- `README.md` — doc map; `CURRENT-STATE.json` — budget, rights, acceptance, experiment and live
  state; `AGENTS.md` — binding collection and evidence rules.
