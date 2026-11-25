# India domain ownership crosswalk — W1.2-D1

> **CURRENT STATUS: PROPOSED crosswalk.** `NR-ARCH-ADR-0001` is Accepted; see `ADR-REGISTRY.md`.

- **Status:** Proposed documentation crosswalk. It records ownership and migration intent; it
  does not accept a contract, ratify an ADR, change rights, or authorise implementation.
  The ownership decision `NR-ARCH-ADR-0001` remains **Proposed** (see `ADR-REGISTRY.md`).
- **Task / branch / base:** W1.2-D1 · branch `docs/w12-d1-crosswalk` · workspace base `ddb379a`.
  No commit, push, paired PR or source-repository edit is part of this work.
- **Method:** read-only inspection of the two local clones at their pinned commits. All file
  paths and line numbers below refer to those commits; no type, schema or behaviour is inferred
  from a document alone where source was available.
- **Scope discipline:** no code transfer, shared crate, India implementation, rights change or
  data collection. No provider contact, collector or adapter execution, market-data download,
  synthetic reference history, schema publication or live action is authorised here.

## Source of truth inspected

| Repository | Commit | Files actually read |
|---|---|---|
| Fieldbook | `340f829` | `src/domain/identity.rs`, `src/domain/reference_data.rs`, `src/domain/event_model.rs`, `src/domain/taxonomy.rs`, `src/acquisition/exchange/mod.rs`, `src/governance/coverage_certification.rs`, `docs/adr/0001-instrument-and-venue-reference-model.md`, `docs/specifications/instrument-master.md`, `AGENTS.md` |
| Nirnay | `d73e145` | `crates/india-domain/src/{lib,instrument,provenance,reference_history,corporate_actions}.rs`, `crates/india-reference/src/{lib,identity,csv}.rs`, `schemas/india/instrument.v1.json`, `schemas/india/instrument.v2.json`, `schemas/research/dataset-{manifest,row,publication}.v1.schema.json`, `engineering/architecture/decisions/ADR-0001-data-ownership.md`, `engineering/architecture/reviews/FIELDBOOK-ARCHITECTURE-REVIEW-2026-11-22.md`, `engineering/architecture/reviews/FIELDBOOK-REVIEW-REFRESH-2026-11-23.md`, `AGENTS.md` |
| Workspace | `ddb379a` | `README.md`, `ADR-REGISTRY.md`, `NDC-REGISTRY.md`, `engineering/evidence/REVIEW-LOG.md`, `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md`, `AGENTS.md` |

## 1. Ownership rule (proposed; follows C0 and the registered ADR)

1. **Fieldbook owns canonical IDs and effective-dated assertions.** This includes instrument,
   venue, listing, segment, issuer/entity, provider/feed identity, their external identifiers
   with valid/known intervals, contracts and specifications, corporate-action revisions,
   calendars/sessions, raw bytes and digests, and the release that publishes them. Fieldbook's
   `FB-ADR-0001` is the in-repository authority for the identity invariant; Nirnay's
   `NR-ARCH-ADR-0001` assigns point-in-time reference ownership to the producer platform and is
   **Proposed, not ratified**.
2. **Nirnay consumes stable IDs and builds trading and research projections.** It may hold a
   derived, versioned projection of admitted release data (instrument/listing views, trading
   terms, tick assignments, adjusted-price views, research datasets). It declares the exact
   release and use profile on each experiment (C0 §4, §7).
3. **Nirnay must not allocate competing canonical identities or reconstruct authoritative
   reference history.** Local `InstrumentId` allocation in `india-reference/src/identity.rs`,
   symbol-keyed identity resolution, and any attempt to rebuild corrected history from vendor
   rows are producer responsibilities and are out of bounds for the consumer.
4. **`india-reference` is legacy frozen.** It is to be replaced by a read-only NDC reference
   projection fed by Fieldbook releases. It is not a second archive, not an identity authority,
   and not a source to extend.
5. **`india-domain` may remain as a trading projection** (typed values, effective-dated terms,
   bitemporal provider mappings, price adjustment) **only if it consumes Fieldbook IDs**. Its
   present local identity allocation and self-contained provenance helper do not satisfy that
   condition and are migration items, not capabilities to preserve.
6. **Nothing may be inferred across concepts.** A venue is not a broker; a ticker/token/ISIN is
   not an identity; a wire enum variant is not support; a signature is not a licence; a
   capability is not a permission (C0 §1–§3, §5).

## 2. Domain crosswalk

Classification vocabulary used below: **authoritative in Fieldbook**, **consumer projection in
Nirnay**, **legacy frozen**, **removed after replacement**, **not yet supported**. A row may
carry more than one label where an old Nirnay construct is frozen while its replacement is a
consumer projection.

| Domain | Fieldbook authority (file / type) | Existing Nirnay code (file / type / schema) | Future Nirnay role | Classification | Known defects | Migration decision | Deprecation condition |
|---|---|---|---|---|---|---|---|
| **venue** | `src/domain/identity.rs`: `VenueId`; `src/domain/reference_data.rs`: `Venue`, `VenueCategory`, `MicRole`, `StandardIdentifier`; `docs/adr/0001…md` §3, §7 (operator ≠ venue ≠ reporting source) | `crates/india-domain/src/instrument.rs`: `Venue { Nse, Bse }` (closed enum); `crates/india-reference/src/lib.rs`: source modules use that enum; `schemas/india/instrument.v2.json` `listing.venue` enum `NSE`/`BSE` | Consume Fieldbook venue IDs and MIC/category assertions from an admitted NDC release; retain only a projection of venue metadata used for execution routing | **authoritative in Fieldbook**; **consumer projection in Nirnay** (NSE/BSE only) | `Venue` is a closed two-value enum with no operator hierarchy, MIC role or effective interval; adding MCX or a segment MIC by editing this enum would silently widen the v2 contract; brokers are correctly excluded | Keep `Venue` as a closed projection for the current v2 release; any new venue enters first as a Fieldbook assertion plus a new versioned contract, then as a Nirnay projection | Deprecate the Nirnay enum-as-registry the first time a release supplies venue IDs that the enum cannot represent without a contract version change |
| **segment** | `docs/adr/0001…md` §3 (segment optional; do not invent one), `src/domain/identity.rs`: `MarketSegmentId` (`segment:` opaque ID), `VenueInstrumentMapping.segment: Option<MarketSegmentId>` | `crates/india-domain/src/instrument.rs`: `Segment { Cash }`, `Segment::v2_supported() -> [Cash; 1]`; `schemas/india/instrument.v2.json` `listing.segment` enum `["cash"]` | Consume Fieldbook segment identity and its rules with the listing; no local segment invention for venues that publish none | **authoritative in Fieldbook**; **consumer projection in Nirnay**; **not yet supported** beyond cash | Cash-only by contract; a future derivatives/commodity segment cannot be represented by widening v2 in place; `MarketSegmentId` from Fieldbook has no Nirnay wire carrier | Phase I1 consumes cash segment as-is; later phases require a new Fieldbook contract version before any Nirnay segment variant is added | Retire the single-value `Segment` when v2 is superseded by a versioned contract that consumes Fieldbook segment IDs |
| **issuer** | `src/domain/reference_data.rs`: `EntityId`, `InstrumentSpecification.issuer: Option<EntityId>`, `EdgeRelation::IssuedBy`; `docs/specifications/instrument-master.md` data model and GLEIF/LEI evidence rules | No India issuer/entity type in `crates/india-domain` or `crates/india-reference`; `schemas/india/instrument.v2.json` has no issuer field (only `isin`, `name`) | Consume Fieldbook legal-entity IDs and `issued_by` edges as read-only reference for research grouping; never infer an issuer from a name or ISIN | **authoritative in Fieldbook**; **not yet supported in Nirnay** | Absence of an issuer type means any Nirnay "company" grouping would be a locally invented identity; ISIN text cannot substitute for LEI/entity evidence | Add issuer only as a release-supplied ID consumed by research projections (needed for phases I5 and parts of I6); no Nirnay entity allocator | No deprecation of a Nirnay issuer type (none exists); reject any locally minted entity ID before phase I5 |
| **instrument ID** | `src/domain/identity.rs`: `OpaqueId::derive`, `InstrumentId` from (namespace, authority, immutable stable key); `docs/adr/0001…md` §5–§6 (opaque, never hash of mutable text) | `crates/india-domain/src/instrument.rs`: `InstrumentId` newtype (`InstrumentId::new`, string pattern); `crates/india-reference/src/identity.rs`: `IdentityRegistry::allocate` mints `{prefix}{sequence:08x}`; `schemas/india/instrument.v2.json.instrument_id` string pattern | Copy the Fieldbook canonical `instrument_id` from the admitted release into `Instrument`/`InstrumentWire`; remove producer-side allocation entirely | **authoritative in Fieldbook**; **removed after replacement** (local allocation) | Nirnay currently allocates its own opaque IDs from an operator prefix — a competing canonical identity; the prefix/sequence scheme is unrelated to Fieldbook's hash-of-assertion scheme, so cross-system reconciliation cannot be implicit | Fieldbook ID is the only accepted ingress value from phase I1 onward; local allocation is frozen immediately and deleted when all consumed releases carry canonical IDs | Remove `IdentityRegistry::allocate` when no code path can mint an ID for an admitted instrument; until then it is frozen and never used for new data |
| **listing** | `src/domain/identity.rs`: `ListingId`, `VenueInstrumentMapping`; `docs/adr/0001…md` §3 (admission with effective dates, one venue, optional segment) | `crates/india-domain/src/instrument.rs`: `Listing` (venue, segment, symbol, token, `effective_from/to`, status, settlement regime, z-category, settlement group, `terms: Vec<ListingTerms>`), `ListingWire`; `crates/india-reference/src/snapshot.rs`: `ListingStateRecord`; v2 schema `$defs/listing` | Build an effective-dated listing/terms projection from release assertions; resolve terms by decision date, never from a live master snapshot | **authoritative in Fieldbook**; **consumer projection in Nirnay** | Listing identity `(venue, segment, symbol)` and terms exist only in memory; they are not evidence of an authoritative assertion; local `ListingStateRecord` snapshots can drift from release revisions; the overlap check is a validator, not as-of lineage | Consume Fieldbook listing IDs, validity intervals and terms from v2 releases in I1; keep `Listing` as a derived view keyed by Fieldbook ID | Retire `ListingStateRecord` and any locally reconstructed listing history once the read-only NDC reference projection supplies listing state |
| **venue identifiers** | `src/domain/identity.rs`: `InstrumentIdentifier` (scheme, authority, value, scope, `valid_from/to`, `observed_at`, provenance), `VenueInstrumentMapping`, `SerializationSymbol`; `src/domain/reference_data.rs`: `IdentifierStandard`, `StandardIdentifier`, MIC roles; `docs/adr/0001…md` §6 | `crates/india-domain/src/instrument.rs`: `Listing.venue_symbol`, `Listing.token`; `crates/india-reference/src/identity.rs`: `symbol_owners: BTreeMap<(Venue, String), InstrumentId>`, `resolve(isin, venue, symbol)`; `crates/india-domain/src/reference_history.rs`: `ProviderListingMapping.venue_symbol` | Receive scoped, effective-dated venue identifiers from the release; store symbol/token as listing attributes for wire compatibility only, never as identity lookup keys | **authoritative in Fieldbook**; **legacy frozen** (`IdentityRegistry`); **removed after replacement** | Nirnay's identity registry is keyed by `(Venue, symbol)` with **no effective interval**, so symbol reuse/change cannot be represented; it also has no provider scope, no observed time and no provenance on the symbol mapping; Fieldbook's own `venue_mappings_from_markets()` uses zero timestamps and is an adapter convenience, not India identity policy (Finding F1) | Freeze `IdentityRegistry` now; consume Fieldbook `VenueInstrumentMapping` intervals via NDC from I1; treat `token` as a venue assertion with validity, not a key | Delete symbol→instrument resolution when all admitted releases carry effective-dated venue identifier assertions and no consumer path resolves by symbol text |
| **provider identifiers** | `src/domain/identity.rs`: `FeedInstrumentMapping`, `DataProviderId`, `FeedId`, `FeedSessionId`; `docs/adr/0001…md` §7 (provider symbol resolves directly to instrument; distinct from venue namespace) | `crates/india-domain/src/reference_history.rs`: `ProviderListingMapping` (provider, provider_instrument_id, venue_symbol, `valid_from/to`, `recorded_at`, provenance) and `ProviderListingHistory::resolve(valid_on, known_at)` | Keep the bitemporal provider-mapping shape as a consumer-side join from release-supplied canonical IDs to provider keys; do not mint the canonical side | **authoritative in Fieldbook**; **consumer projection in Nirnay** | The mapping is otherwise well formed but carries an `instrument_id` that is currently locally allocated; no provider/feed identity registry exists in `india-reference`; config example maps are not authoritative assertions | Retain `ProviderListingHistory` as a projection keyed by Fieldbook IDs from I1; provider/feed identities come from the release, not from Nirnay config or local allocation | Deprecate any locally allocated `instrument_id` inside provider mappings; keep the valid/known-time query surface |
| **contracts** | `src/domain/reference_data.rs`: `InstrumentSpecification` (multiplier, `expiry_us`, `strike_mantissa`, valid window), `EdgeRelation` (`UnderlyingOf`, `OptionOf`, `DeliverableOf`, `SuccessorOf`, `ConstituentOf`); `src/domain/event_model.rs`: `DomainPayload::{BondQuote, FxQuote, FutureQuote, OptionQuote, CommodityAssessment}`; `docs/specifications/instrument-master.md` | `crates/india-domain/src/instrument.rs`: `InstrumentType { … Future, Option, CurrencyPair, Bond }` plus `underlying_instrument_id`, `expiry_date`, `strike_price_paise`, `option_kind` in memory; `InstrumentWireType` is only `Equity/Etf`; no futures/options schema under `schemas/india/` | Consume contract specifications and expiry/strike/underlying assertions from new versioned Fieldbook contracts; variants in an enum do not grant support | **authoritative in Fieldbook**; **not yet supported in Nirnay v2** | `InstrumentType::Future/Option/CurrencyPair/Bond` exist in memory but `to_wire()` rejects everything except Equity/Etf and v2 `additionalProperties: false` blocks extension; no corresponding schema or ingested assertion exists (Finding F8) | Phase I3/I4/I5 each require a Fieldbook-owned versioned contract before any Nirnay contract projection is accepted; do not widen `instrument.v2.json` | Retire in-memory-only contract variants when a versioned contract either admits them with evidence or removes them |
| **corporate actions** | `src/domain/event_model.rs`: `DomainPayload::CorporateAction { action_type, effective_us }` (effective-dated typed event); `src/domain/taxonomy.rs`: `DataCategory::CorporateActions`; C0 §6 corporate-action coverage dimension; release owns corrections and supersession (NR-ARCH-ADR-0001 §2.1) | `crates/india-domain/src/instrument.rs`: embedded `CorporateAction` array + `CorporateActionWire`; `crates/india-domain/src/corporate_actions.rs`: `CorporateActionEvent`, `CorporateActionLedger` with announced/recorded time and provenance; v2 schema `corporate_actions` array | Consume Fieldbook action events with revision line and knowledge time; use the ledger only as an admitted-release projection for exact price adjustment | **authoritative in Fieldbook**; **consumer projection in Nirnay** (`CorporateActionLedger`); **legacy frozen** (embedded array) | Embedded array has no provenance, knowledge time or supersession and is explicitly a snapshot, not a point-in-time ledger; `CorporateActionLedger::append` rejects a second record with the same `(instrument, effective_date, kind)`, so a corrected action cannot replace its predecessor, and there is no `supersedes` chain (F4, F10) | Freeze the embedded array for v2 compatibility; consume Fieldbook action revisions in I1 and use the bitemporal ledger for adjustment only when the release carries the lineage | Remove the embedded `corporate_actions` array when a versioned release contract supplies action events; reject any locally corrected action that lacks a Fieldbook revision ID |
| **calendars** | `src/governance/coverage_certification.rs`: `CountryDossier.market_calendar: Option<String>` (declared calendar reference only); C0 §6 session/time coverage; NR-ARCH-ADR-0001 §2.1 assigns calendar and session reference to the producer | `crates/india-domain/src/lib.rs`: `SessionDay`, `CalendarDay { venue, date, session, note }`, `TradingCalendar { venue, days }`, `is_trading_day`, `covers_month`; no calendar JSON schema | Consume Fieldbook effective-dated session/calendar assertions; use `TradingCalendar` only as a date projection for admitted releases | **authoritative in Fieldbook** (declared; effective-dated assertion still required); **consumer projection in Nirnay**; **not yet supported** as a release artifact | Fieldbook declares a calendar reference but has no typed trading-calendar artifact in source; Nirnay's calendar is **date-only** (`jiff::civil::Date`), has no intraday session intervals, and `covers_month` requires an entry for every date (Finding F7) | Before I1 closes, require a Fieldbook session/calendar artifact in the release; Nirnay consumes dates from it and must not infer sessions from a sparse holiday file | Deprecate local `TradingCalendar` ingestion as soon as session coverage arrives through an admitted release; never extend it with fabricated session times |
| **raw source provenance** | `src/domain/identity.rs`: `InstrumentIdentifier.source_provenance`; `docs/specifications/instrument-master.md` evidence rules (source, retrieval time, edition, coverage flags, SHA-256, immutable files); NR-ARCH-ADR-0001 §2.1 raw storage/digest owner; C0 §8 PROV-O lineage | `crates/india-domain/src/provenance.rs`: `SourceProvenance` (schema 1, `source_id`, venue, segment, `retrieved_at`, lowercase SHA-256 of exact bytes, `record_count`, `declared_by`) and `provenance_for_source`; `crates/india-reference/src/csv.rs`: logical-record parser | Verify and carry release digests and archive references as lineage on admitted datasets; never re-derive authority or coverage from local bytes | **authoritative in Fieldbook**; **consumer projection in Nirnay**; **legacy frozen** (`provenance_for_source`) | `provenance_for_source()` sets `record_count` by counting physical `String::lines()` minus the header, while the parser accepts quoted fields containing CRLF/LF — the count can exceed the logical record count and is **not a valid coverage denominator** (Finding F5) | Freeze the local helper for test fixtures only; coverage denominators come from the release manifest per C0 §6, with a distinct denominator for each dimension | Delete `provenance_for_source` from production paths when releases provide digest, record count and coverage per dimension; it never becomes an authority |
| **research datasets** | Fieldbook publishes NDC releases; it owns no research dataset (no research/strategy code). See `NDC-REGISTRY.md` producer/consumer split and C0 §7 identity chain | `schemas/research/dataset-manifest.v1.schema.json`, `dataset-row.v1.schema.json`, `dataset-publication.v1.schema.json`, `dataset-signature.v1.schema.json`; `research/python/` quantlab; no admitted India dataset | Remain Nirnay-owned derived outputs with declared lineage to a specific release, admission receipt and use profile; never re-normalise raw Fieldbook payloads | **consumer projection in Nirnay**; **not yet supported** for India (no admitted release, rights `UNKNOWN`, acceptance `BLOCKED`) | A dataset row that cites local `india-reference` IDs or locally reconstructed history would break the C0 identity chain; signature proves integrity, not rights or truth | Only after an admitted release in I1+ may a research dataset cite Fieldbook release IDs; each dataset records the exact release, manifest digest and as-of basis | No India research dataset is admissible until source rights, acceptance and an admitted release exist; any dataset built from the frozen legacy path is deprecated on that path's removal |

## 3. Verified findings (each tied to source at the pinned commits)

**F1 — `venue_mappings_from_markets()` is an adapter migration convenience, not India identity policy.**
`src/domain/identity.rs:202-255` derives instrument/venue/listing IDs from `market.native_symbol`
(lines 217-219, 244) and stamps both `valid_from` and `observed_at` with
`ADAPTER_ASSERTION_TIME = 0` (lines 202-204, 246-248). It is the default `identity_assertions()`
implementation in `src/acquisition/exchange/mod.rs:136-144`, and its tests use Kalshi, Polymarket
and Coinbase markets (`identity.rs:528-615`). Its own doc calls the symbol a "wire key" and the
time a deterministic adapter assertion placeholder. Fieldbook ADR-0001 §6 and
`docs/specifications/instrument-master.md` require venue mappings to be scoped and effective-dated;
none of this constructs India identity or India effective dates. Do not reuse it as an India
identity policy or as evidence of a timestamped venue assertion.

**F2 — Nirnay `IdentityRegistry` is `(Venue, symbol)`-keyed with no effective interval.**
`crates/india-reference/src/identity.rs:29-36` stores `symbol_owners: BTreeMap<(Venue, String),
InstrumentId>`; `resolve(isin, venue, symbol)` (lines 67-123) has valid-time parameters nowhere,
so a changed or reused symbol cannot be represented as a separate interval. `allocate()` (lines
51-61) mints a prefix+sequence ID, and there is no provider/feed scope or `recorded_at` on a
symbol assertion. This is both a temporal defect and a competing canonical identity source.
Contrast Fieldbook's `InstrumentIdentifier` with `valid_from/valid_to/observed_at/source_provenance`
(`src/domain/identity.rs:125-144`).

**F3 — `ProviderListingHistory` has the correct bitemporal shape but is not an authority.**
`crates/india-domain/src/reference_history.rs:11-25` defines `ProviderListingMapping` with
`valid_from`, `valid_to`, `recorded_at` and `SourceProvenance`; `validate()` requires
`recorded_at >= provenance.retrieved_at` (lines 43-47) and matching venue/segment; `resolve()`
(lines 95-117) queries on both `valid_on` and `known_at` and rejects ambiguity. Keep this query
surface, but the `instrument_id` it carries must come from Fieldbook, and provider/feed identity
must not be reconstructed from Nirnay config or local allocation.

**F4 — `CorporateActionLedger` rejects a corrected action in the same slot and has no supersedes chain.**
`crates/india-domain/src/corporate_actions.rs:13-27` defines `CorporateActionEvent` with
`action_id`, `effective_date`, `announced_at`, `recorded_at` and provenance, but no revision,
`supersedes`, or `invalidated_at` field. `append()` (lines 62-75) rejects any new record whose
`action_id` matches, or whose `(instrument_id, effective_date, kind)` matches an existing record.
A corrected action for the same slot therefore cannot be appended, and `known_as_of` (lines
98-113) cannot express invalidation. Authoritative revisions and supersession belong to
Fieldbook in the release (NR-ARCH-ADR-0001 §2.1 contract fields 9-10; C0 §8).

**F5 — `provenance_for_source()` is not a valid coverage denominator.**
`crates/india-domain/src/provenance.rs:61-88` computes `record_count` from
`String::from_utf8_lossy(raw_bytes).lines().skip(1).filter(non-empty).count()` (lines 70-75).
The consumer parser `crates/india-reference/src/csv.rs:1-6` explicitly parses *logical records*,
and lines 95-111 increment the line counter for newlines inside a quoted field. A single quoted
multiline record is therefore counted as several physical lines. C0 §6 requires a distinct,
declared denominator per coverage dimension; this helper supplies none of them. Its use is
limited to test fixtures and must not be read as coverage evidence.

**F6 — Paise and Lots are not global units.**
`crates/india-domain/src/instrument.rs:200-206` defines `Paise(pub i64)` and `Lots(pub i64)` for the
India cash contract (module header lines 1-9); tick schedules, strikes and dividends use the
`_paise` suffix throughout (lines 276-283, 384-422, 570-579). C0 §5.1 keeps exact financial
decimals and large integers as JSON strings rather than IEEE 754 numbers, and
`NR-ARCH-ADR-0001` §3.1 requires each release to state the original field, unit and domain;
Fieldbook's numeric model uses explicit scales (`src/domain/fixed.rs`). Do not promote paise/lots
to a platform-wide unit, and do not assume lot semantics for other asset classes; any release must
name the unit and domain of each field.

**F7 — Nirnay `TradingCalendar` is date-only.**
`crates/india-domain/src/lib.rs:34-51` stores `CalendarDay.date: jiff::civil::Date` and
`SessionDay { Trading, Closed, Special }`; `is_trading_day`, `next_trading_day` and `covers_month`
(lines 53-96) operate on whole dates. There is no session start/end, timezone-aware interval, or
intraday holiday boundary. Session/time coverage for research must come from Fieldbook's
effective-dated calendar artifact; `covers_month` only proves that date entries exist.

**F8 — `InstrumentType::Future`/`Option` variants do not establish support.**
`crates/india-domain/src/instrument.rs:41-51` lists `Future`, `Option`, `CurrencyPair` and `Bond`,
and `Instrument` has derivative fields (lines 601-611), but `InstrumentWireType` is only
`Equity | Etf` (lines 877-882), `TryFrom<InstrumentWire>` maps only those two (lines 1128-1134),
and `to_wire()` rejects every other type (lines 1165-1176). `schemas/india/` contains only
`instrument.v1.json` and `instrument.v2.json`, whose description says other families require
separate versioned contracts. An enum variant is not a supported, ingested, evidenced instrument.

**F9 — `Segment` is cash-only.**
`crates/india-domain/src/instrument.rs:22-37` defines `Segment { Cash }` and
`v2_supported() -> [Self::Cash; 1]`; `schemas/india/instrument.v2.json:81-87` permits only
`"cash"` and states the contract covers cash equities. Any derivatives, MCX commodity,
currency or debt segment requires a new versioned Fieldbook contract, not an in-place enum edit.

**F10 — The embedded corporate-action array is not a point-in-time ledger.**
`crates/india-domain/src/instrument.rs:565-567` says so verbatim; the v2 schema repeats it at
`schemas/india/instrument.v2.json:50-56`. The array carries `action`, `effective_date`, ratio,
optional paise amount and a note (lines 568-579) — no announcement/knowledge time, provenance or
revision chain. The bitemporal ledger is the separate `CorporateActionEvent` contract
(`corporate_actions.rs`), which is still subject to F4. Research adjustments must cite a
Fieldbook release and revision, not the embedded snapshot.

**F11 — The v2 schema must not be silently widened.**
`schemas/india/instrument.v2.json` sets `additionalProperties: false` at the root (line 15) and in
every `$defs` object (lines 71, 159, 199, 251, 264, 296); line 5 of v2 states "v1 is frozen; do not
edit it to match". The Rust ingress `InstrumentWire` also uses
`#[serde(deny_unknown_fields)]` (`instrument.rs:862-875`). Adding venues, segments, instrument
types, units or corporate-action fields requires a new versioned contract, an owner decision and
paired producer/consumer validator changes (`NDC-REGISTRY.md` §Change procedure; C0 §9 step 4).
Documentation-only work such as this crosswalk changes no schema.

**F12 — Nirnay must not reconstruct authoritative reference history.**
`NR-ARCH-ADR-0001` §2.1 assigns acquisition, raw storage, normalization, point-in-time reference
data and the raw-data lifecycle to the producer; Nirnay owns derived research datasets. The
Nirnay review at `d73e145` records Fieldbook's cross-venue/PIT authority as *declared, not yet
implemented* and forbids a duplicate archive, shared crate or domain-model copy
(`FIELDBOOK-ARCHITECTURE-REVIEW-2026-11-22.md` §1; `FIELDBOOK-REVIEW-REFRESH-2026-11-23.md` §4).
Therefore `india-reference` ingestion snapshots and locally allocated IDs are frozen legacy, not
a history source to complete.

## 4. Migration register — phases I1–I6

No phase below authorises a collector, adapter, provider contact, download, scraper, experiment,
schema publication or live routing. Each phase begins only when Fieldbook publishes the required
assertions in an admitted NDC release and the owner gates in `NDC-REGISTRY.md` / `CURRENT-STATE.json`
are satisfied. Nirnay work in every phase is consumption plus a derived projection only.

| Phase | Scope | Fieldbook assertion required before the phase | Nirnay action after admission | Exit condition |
|---|---|---|---|---|
| **I1** | Cash equities and ETFs (NSE/BSE; the current `instrument.v2.json` surface) | Canonical instrument/venue/listing IDs, effective-dated venue identifiers, listing terms and tick assignments, corporate-action events with revision lineage, calendar/session coverage and raw digest in one release | Bind `InstrumentId`/`ListingId` from the release; rebuild `Listing`, `TradingCalendar` and `CorporateActionLedger` projections from release data; freeze `IdentityRegistry`, local ID allocation and `provenance_for_source` for production | No admitted object carries a locally allocated ID; `india-reference` is read-only and unused for new data; coverage denominators come from the release manifest |
| **I2** | Indices and constituents | Index identities and effective-dated `constituent_of` edges; index family identity distinct from any tracked instrument | Consume index IDs and membership intervals as an admitted reference projection; no local index identity or hand-built constituent list; preserve as-of membership in research datasets | All membership queries resolve release-supplied IDs; survivorship checks use the declared point-in-time universe (C0 §6) |
| **I3** | Derivatives (futures/options) | New versioned contract with product family, expiry, strike, option kind, underlying canonical ID and effective terms; versioned by contract, not by enum edit | Add a versioned ingestion path for that contract; consume derivative IDs and underlying links; reject any Future/Option variant presented under `instrument.v2.json` | A derivative assertion round-trips with Fieldbook IDs and no widening of v2; `to_wire()` still rejects out-of-contract types |
| **I4** | MCX commodities | New venue/operator assertion for MCX, commodity product identities, contract specs, units/grades and effective terms in a versioned release | Consume only from that release; do not add MCX to the closed `Venue` enum or a segment to `v2_supported()` without the new contract | MCX data resolves through Fieldbook venue IDs; the legacy enum-as-registry is unused for new venues |
| **I5** | Currency and debt | Entity/issuer IDs, ISO 4217 currency assertions, debt specifications (issuer, coupon, maturity/seniority) in a versioned release | Consume issuer and currency IDs; extend research projections only; no local entity allocation and no inference from ISIN or name | Issuer/currency grouping in Nirnay cites release IDs; no locally minted entity identity remains |
| **I6** | Other domains (news, economic observations, commodity assessments and any later data category) | Per-domain versioned contract, typed payload, unit declarations, rights scope and coverage denominator | Case-by-case consumer projection under a new use profile; each dataset records release identity, admission receipt and as-of basis | Domain enters only through an admitted release; any dataset sourced from the frozen legacy path is retired |

**Authorization boundary:** this register is a sequence of *decisions and conditions*, not work
orders. It grants no collector or adapter authorization and does not change the `UNKNOWN` rights
state or the `BLOCKED` dataset-acceptance state.

## 5. Non-goals and connections

- **No code transfer, shared crate, India implementation, rights change or data collection** is
  part of W1.2-D1. Neither source repository was modified; no commit or push was made in any
  repository. No provider was contacted and no market-data operation was executed.
- **C0 semantic model:** `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` — especially §1
  (six separable concepts), §4 (consumer use profiles), §6 (per-dimension coverage denominators),
  §7 (release → admitted dataset → research dataset identity chain), §8 (PROV-O lineage) and §10
  (open owner decisions). This crosswalk is a consumer/reference application of that model, not a
  new contract version.
- **Ownership ADR:** `ADR-REGISTRY.md` canonical ID `NR-ARCH-ADR-0001`, file
  `engineering/architecture/decisions/ADR-0001-data-ownership.md` in the Nirnay clone (read-only).
  It is **Proposed, not ratified**, and this document does not ratify it. Fieldbook's `FB-ADR-0001`
  governs instrument/venue identity inside the producer.
- **Related registries:** `NDC-REGISTRY.md` (producer Fieldbook, consumer Nirnay, version-change
  procedure) and `engineering/evidence/REVIEW-LOG.md` (exact commits for cross-repository decisions).
