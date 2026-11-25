# IN-COUNTRY-001 — India country pack design

- **Status:** PROPOSED. Awaiting owner ratification. This document defines the intended shape of
  the India country pack. It ratifies no contract version, grants no data right, qualifies no
  source or provider, accepts no dataset, authorises no India implementation and opens no gate.
- **Task / branch / base:** IN-COUNTRY-001 created this decision; amended in place under
  IN-COUNTRY-002 · branch `docs/india-catalogue-amendments` · workspace base `7b0eb2e`.
  Documentation only in the Workspace worktree: this decision and its companion catalogue are
  amended in place, with no competing decision. No source repository, schema, contract, release,
  dataset, experiment or CI change is part of this work.
- **Amendment record (2026-11-24, PROPOSED):** mandatory nine-field evidence on every pack
  component, immutable pack versions, explicit mainland/IFSC partition semantics submitted for
  owner approval, alignment of the cohort completeness policy with the catalogue's split
  subpopulations and independent object contracts, and an explicit not-approved section. Status
  remains PROPOSED pending owner ratification.
- **Authority read:** `engineering/decisions/WS-SCOPE-2026-11-24-001-global-reference-core-india-first.md`
  (ratified: one global core, India first; opaque platform identities; external identifiers as
  assertions; bitemporal assertions; per-dimension denominators), `engineering/coverage/india-coverage-register.md`
  (I1–I6 sequence and nine coverage dimensions), `engineering/design/india-national-domain-catalogue.md`
  (IN-01..IN-20 cohorts and ontology rules).
- **Implemented core alignment:** `fieldbook/src/domain/reference_core.rs` (`ObjectClass`,
  `ObjectId`, `ObjectRef`, `IdentifierAssertion`, `BitemporalAssertion`, `CoverageCell`),
  `market_registry.rs` (`JurisdictionCode`, `AuthorityAssertion`, `VenueAssertion`,
  `SegmentAssertion`, `MarketProductAssertion`, `CountryPack`, `MarketRegistry`),
  `instrument_terms.rs` (`Unit`, `ExactMeasure`, term families, `ContractFamily`,
  `ContractInstance`), `capability_registry.rs` (`CapabilityAssertion`, `EvidenceRef`,
  `RightsState`, `CapabilityCoverageRegistry`) and `src/domain/taxonomy.rs` (`InstrumentKind`,
  `DataCategory`). The implemented types are the vocabulary authority; no second identity system
  or competing class tree is introduced.

## 1. Decision requested

Ratify the India country pack as a **versioned extension of the global reference core**. India is
a jurisdiction whose rules are declared as versioned records; it is not a set of fixed enum
variants, venues, products or rights. The pack binds jurisdiction-scoped assertions to the same
opaque identities, identifier assertions, bitemporal ledgers and coverage dimensions used by
every other jurisdiction. No India-only identity namespace, symbol key, master table or coverage
percentage is created.

Ratification of this design is a documentation decision only. A separate owner decision remains
required for any contract version, source qualification, data right, dataset acceptance or
implementation.

## 2. Extension form

The implemented `CountryPack` is a jurisdiction code, a positive version, a timezone label and
four versioned record sets: settlement conventions, calendar rules, identifier schemes,
regulatory sources and corporate-action types. The India pack uses that form without changing the
core types:

| Pack component | Declared form | Binding rule |
|---|---|---|
| Jurisdiction | `JurisdictionCode` for India, plus a distinct jurisdiction-scoped partition for the IFSC where the regulatory regime differs | Every authority, venue, segment and product assertion declares its jurisdiction; a cross-jurisdiction reference fails closed. |
| Version | Positive `version` increased on every admitted change | No in-place silent widening; a superseded rule stays addressable with its effective interval and revision. |
| Timezone | IANA label plus a declared rule version | India venue dates normalise in `Asia/Kolkata` under that rule; UTC is used only where the source declares UTC. |
| Settlement conventions | Named rules keyed by declared rule name | Each rule names its effective interval, source and calendar; no platform-wide settlement default. |
| Calendar rules | Named rules keyed by declared rule name | Sessions, holidays, exceptional closures and overrides are asserted objects, not date booleans. |
| Identifier schemes | Named declared schemes | ISIN, LEI, MIC and domestic schemes are scoped assertions; a generic `Other` label is not a completeness device. |
| Regulatory sources | Named declared sources with version and effective dates | A regulation is cited by source, publication and effective interval, never by an undated label. |
| Corporate-action types | Named declared action types | Actions are events with revision lineage; they are not replacement securities. |
| Every pack component | The nine evidence fields in §2.1 on each jurisdiction, authority, operator, venue, segment, identifier scheme, instrument spec, calendar, settlement convention, action rule, regulatory source and bitemporal revision. | No component is admitted without identity, version, source, source digest, valid interval, knowledge time, revision, predecessor and verification state. |

### 2.1 Component evidence model

Every pack component carries the same nine fields. The field names are a documentation contract,
not new Rust types or new `ObjectClass` variants; the implemented core remains the vocabulary
authority.

| Field | Required content | Failure condition |
|---|---|---|
| Identity | Opaque platform-assigned identity for the component; external refs are assertions. | Identity derived from a name, code, venue symbol or currency label. |
| Version | Positive monotonic version within that component identity. | Silent in-place widening or a version that does not advance on change. |
| Source | Named source object and assigning authority with jurisdiction scope. | Undated label, unnamed source or source inferred from the component name. |
| Source digest | Digest of the exact source bytes cited by the assertion. | Missing digest or a digest that cannot be tied to the cited source. |
| Valid interval | Half-open `[valid_from, valid_to)` effective interval. | Inclusive end silently coerced or a rule applied outside its interval. |
| Knowledge time | `recorded_at_us` with publication and receive instants held separate. | Arrival order used as a substitute for knowledge time. |
| Revision | Nonzero revision on each admitted change; append-only. | Overwrite of a prior revision or a zero/absent revision. |
| Predecessor | Link to the immediate predecessor revision where one exists. | Broken, self-closing or fabricated chain. |
| Verification state | Declared verification state distinct from rights and from capability. | A verified state inferred from a source declaration or used as permission. |

### 2.2 Immutability after admission

A pack version is immutable after admission. A new venue, rule, scheme, calendar, settlement
convention, action type, regulator citation or partition reference creates a new component
revision or a new pack version; it never overwrites an admitted record. Superseded components stay
addressable with their original valid interval, knowledge time, revision and predecessor. A
corrected pack version receives a new version identity and digest, and the earlier pack version
remains in lineage. No rule is applied retroactively by rewriting a predecessor.

The pack is data, not Rust source. A new venue, segment, product family, identifier scheme or
action type requires a new versioned assertion and, where a payload shape is missing, a **NEW
typed extension** in a versioned contract. It does not require an enum edit and must not be
implemented by widening a frozen wire surface.

## 3. Pack contents

### 3.1 Jurisdiction and IFSC distinctions

India is one jurisdiction in the global core. The International Financial Services Centres
Authority (IFSCA) regime is represented as a distinct jurisdiction-scoped partition for rules,
authorities, venues and products that are declared under it. The partition shares all identity,
identifier, temporal and coverage machinery with the rest of the core. A product is not assigned
to the IFSC partition by name, currency or participant; assignment requires an asserted
jurisdiction reference and a source. Mainland and IFSC venues remain separate venue objects, and
no cross-partition venue, segment or product identity is merged.

The definitions below are submitted to the owner for approval. None is admitted by this PROPOSED
design; each becomes binding only in an owner-approved pack version with all nine evidence fields
of §2.1.

| Dimension | Mainland India definition submitted for approval | IFSC definition submitted for approval | Prohibited inference |
|---|---|---|---|
| Jurisdiction identity | Distinct opaque jurisdiction identity asserted for the domestic regime, with its legal basis and effective interval. | Distinct opaque jurisdiction identity asserted for the IFSC regime, with its legal basis and effective interval; never the mainland identity under a second label. | Treating a jurisdiction as a name, a country code, a venue or a data right. |
| Regulatory authority | Authority role asserted under the mainland jurisdiction with source, scope and effective interval. | Authority role asserted under the IFSC jurisdiction with source, scope and effective interval; no authority is inherited from the mainland regime. | Inferring an authority from an entity name, licence reference, website or venue code. |
| Venue ownership | Operator identity asserted in the mainland jurisdiction; venue identity distinct from operator, provider and feed. | Operator identity asserted in the IFSC jurisdiction; venue identity distinct from any mainland venue even where the operator name matches. | Merging venues or operators across partitions by name, code or shared operator text. |
| Product applicability | Product assertion names its admitting jurisdiction, venue, segment and terms version. | Product assertion names the IFSC admitting facility and its own terms version; a mainland family is not transferred by label. | Assigning a product to a partition from its name, symbol, contract code or currency. |
| Settlement | Settlement convention asserted with jurisdiction, settlement calendar and effective interval. | Settlement convention asserted with IFSC jurisdiction and its own calendar; no mainland convention inherited. | Assuming a settlement cycle or business-day rule from an asset class or another partition. |
| Currency and instrument rules | Currency identity asserted separately; INR and foreign currencies are distinct objects with asserted convertibility and settlement rules. | Offshore currency and instrument rules asserted under the IFSC jurisdiction; no implied convertibility, route or settlement eligibility from membership. | Inferring IFSC membership or settlement eligibility from a currency code, an INR/USD label or a product name. |
| Cross-partition references | Explicit asserted edge to an IFSC object, jurisdiction-checked and bitemporal. | Explicit asserted edge to a mainland object, jurisdiction-checked and bitemporal. | Silent cross-partition identity merge or a reference inferred from a shared participant, feed or code. |

IFSC membership is established only by an asserted jurisdiction reference plus a named source,
verification state and effective interval. It is never inferred from a name, a venue code, a
currency, a participant domicile, a provider feed label or a shared product description.

### 3.2 Authorities

Authority assertions use the implemented authority roles: regulator, exchange operator, clearing
corporation, depository, benchmark administrator and a named source-declared role. Candidate
authorities for scoping are SEBI, RBI, IFSCA, stock exchanges in their self-regulatory capacity,
clearing corporations, depositories, mutual-fund and scheme-registration bodies, and benchmark
administrators. None is admitted by this document. Each assertion carries jurisdiction, role,
optional parent authority, source, bitemporal interval and nonzero revision. An authority is not
inferred from an entity name, a website, a licence reference or a venue identifier.

### 3.3 Market infrastructure

Exchanges, clearing corporations and depositories are market-infrastructure authorities and
market operators. The operator is distinct from the venue it operates: a venue assertion names
one operator registered in the same jurisdiction. Clearing and depository relationships are
asserted edges, not properties inferred from a trade or an ISIN. A provider that redistributes
infrastructure data does not become the operator, venue, clearing corporation or depository.

### 3.4 Venues and facilities

Venue assertions carry jurisdiction, operator, optional MIC with a declared role, category,
declared segments, source, bitemporal interval and revision. Candidate venues and facilities
include the principal equity and derivative exchanges, the commodity exchange, debt and
money-market trading or reporting facilities, clearing and settlement facilities, and IFSC
exchanges. MIC roles — listing, trading, reporting and operational — stay distinct. A facility
that does not publish a MIC does not receive an invented one. A venue identity is never derived
from a symbol, token, feed name or provider code.

### 3.5 Segments

Segments are asserted objects owned by a venue; they are optional on a listing. The pack declares
named segments for cash, derivatives, debt, commodities and any further segment a venue
publishes. Segment admission states the instrument kinds it admits and the product assertions it
carries. A segment that a venue does not publish is not invented, and a closed cash-only segment
surface is not reused for derivatives, debt or commodities without a new contract version. A
segment is not a coverage denominator by itself.

### 3.6 Identifier schemes

Identifier assertions carry scheme, value, assigning authority, subject, source, valid interval,
knowledge time, nonzero revision and verification status. The pack declares:

- ISIN for securities where assigned, scoped by the assigning authority.
- LEI for legal entities, including issuers and counterparties.
- MIC for venues and facilities, with the role stated on the assertion.
- Domestic schemes such as exchange symbols, tokens, scheme codes, contract codes, series and
  registration numbers, each with an explicit assigning authority, jurisdiction and scope.
- Source-scoped deal and programme references for OTC objects, never promoted to global keys.

Domestic scheme text is not a primary key. Scheme reuse or change over time produces separate
effective intervals. A scheme not covered by a declared type needs a versioned typed extension;
the generic string escape hatch in `IdentifierScheme` is not used to claim completeness.

### 3.7 Currency identities and monetary rules

Currency identities are asserted reference objects with ISO 4217 codes and declared authorities.
INR and each foreign currency are distinct objects; convertibility, convertibility route or
settlement eligibility is a separately asserted rule. Monetary values use `ExactMeasure` with an
integer coefficient, explicit decimal scale and declared `Unit`; exact decimals and large
integers are strings at serialization boundaries. Currency context is carried by the assertion,
not by the number. Paise, lots, ticks and other India cash units stay scoped to the product or
release that declares them and are never promoted to global defaults.

### 3.8 Calendars

A calendar is a set of scoped, effective-dated session and event assertions. For each venue or
segment the pack declares: timezone and rule version; session, auction and break intervals as
half-open intervals in that timezone; scheduled holidays; exceptional closures with reason; and
early-close or special-session overrides with their own source and effective interval. A sparse
holiday date list is not session coverage. A calendar assertion carries source reference, digest,
revision and effective interval. Calendar changes append revisions; a date-only local calendar is
not extended with inferred session times.

### 3.9 Settlement conventions and calendars

Settlement conventions are named rules declaring the settlement cycle, settlement calendar,
business-day convention, market and settlement date relationship, and any exceptional settlement
session. Each convention is versioned with an effective interval and source. The convention used
for a listing or contract is bound by its own assertion; no convention is inherited from a venue
name, asset class or another jurisdiction. Settlement calendar coverage is a declared part of the
session/time dimension, not a count of calendar files.

### 3.10 Instrument rules

Per product, the pack declares tick schedules as ordered non-overlapping price bands, quantity
steps, lot sizes, contract multipliers, strike representation, expiry, settlement mode and
deliverable terms. Derivative and commodity rules reuse `DerivativeTerms` and `CommodityTerms`
with `ExactMeasure` values; a family is a template and an instance adds its own expiry and
multiplier. An option is distinct by underlying, expiry, strike, right and specification. Tick,
lot, multiplier, expiry and delivery rules are versioned with effective intervals and sources; a
change does not rewrite the prior rule. A missing typed payload requires a new versioned extension
rather than forcing the product into an equity terms shape.

### 3.11 Corporate-action classifications

The pack declares named action types: dividend, split, bonus, rights, buyback, merger, demerger,
consolidation, symbol change, delisting, cancellation and correction. Each action is an event with
announcement, ex, record, effective and payment times held apart; a correction is a new revision
with `supersedes` and its own knowledge time. A successor instrument is a separate object joined
by an effective-dated edge. The embedded snapshot array and the local action ledger are frozen
legacy shapes and are not action evidence.

### 3.12 Versioned regulation

Regulatory sources are named, versioned records with publication and effective dates. A rule
change is a new assertion with its own effective interval and supersession link. No rule is
applied retroactively by rewriting an earlier assertion, and no undated label is a citation.
Versioned regulation governs the values declared in sections 3.1 through 3.11; it does not itself
confer a data right.

### 3.13 Provenance

Every assertion names its source object, publication time, correction or supersession link and
effective interval. Lineage follows PROV-O entities, activities and agents with
`wasDerivedFrom`, `wasRevisionOf`, `hadPrimarySource`, `generatedAtTime` and
`invalidatedAtTime`. Raw bytes, digests, transformation records and release identity are carried
on the release, not reconstructed from a local file. Provenance describes derivation; it confers
no permission and proves no truth of an observation.

## 4. Effective time, knowledge time and revision policy

| Rule | Required behaviour |
|---|---|
| Effective time | Validity is half-open `[valid_from, valid_to)`; the lower bound is inclusive and the upper bound exclusive. An absent upper bound is open. A source with an inclusive end date is normalised by a declared rule recorded with the assertion; no silent coercion. |
| Knowledge time | `recorded_at_us` records when the platform learned the assertion. Source event time, source publication time, network receive time and application receive time are separate fields; none substitutes for another. |
| Market dates | Date-domain values normalise in `Asia/Kolkata` under the declared rule version. Microsecond precision records storage granularity, not accuracy; an accuracy claim requires a declared synchronisation and a mandatory receive timestamp. |
| Resolution | Queries resolve on `(valid_on, known_at)`. Outcomes are `Resolved`, `Ambiguous`, `Unresolved` and `Conflict`; candidates are retained on ambiguity and no first match is selected. |
| Revision | Assertions are append-only. A correction adds a new record with a nonzero revision and a predecessor link; the earlier record stays addressable with its original interval and knowledge time. |
| Supersession | A predecessor must exist, a chain may not close on itself, and selection uses release as-of instant and knowledge time rather than arrival order. |
| Corrections across releases | A corrected release receives a new release identity and digest; the prior release and its knowledge time remain in lineage. No overwrite, no synthetic reconstruction and no partial release. |
| Pack version immutability | An admitted pack version is immutable. A new rule creates a new component revision or a new pack version with a new version identity and digest; no admitted component is overwritten. |
| Component evidence completeness | Every pack component carries the nine fields of §2.1. A component missing identity, version, source, source digest, valid interval, knowledge time, revision, predecessor or verification state is not admitted. |
| Verification state | Verification state is declared with its verifier and evidence; it is distinct from capability and rights. A name, a code, a source declaration or a successful connection never raises it to verified. |
| Capability and rights state | Capability evidence and rights state stay separate: a verified capability with rights `UNKNOWN` grants nothing, and a source declaration alone raises no capability to verified. |

## 5. Population-completeness policy per cohort

A completeness statement is admitted only when it names a cohort, a population type, a source
authority, an as-of instant, a declared denominator dimension and a count basis. The as-of instant
is an explicit instant or a market date resolved under the declared calendar rule; "current",
"today" and "latest" are not as-of instants. Where a complete public population cannot be
established, the verdict is `UNKNOWN` (axis declared, count absent) or `UNMEASURABLE` (no
commensurable denominator). No count, ticker list, ISIN list or public page is a denominator.

| Cohort | Population type | Authoritative source requirement | As-of rule for any completeness claim | Denominator dimension(s) | Current verdict |
|---|---|---|---|---|---|
| IN-01 | Authority-bounded | SEBI and admitting-exchange assertions | Declared venue trading date resolved to an instant under the session rule | Instrument; listing/identity | `UNKNOWN` |
| IN-02 | Authority-bounded | Regulator and admitting-exchange or depositary assertions | Declared venue trading date under the session rule | Instrument; listing/identity | `UNKNOWN` |
| IN-03 | Authority-bounded | Regulator and scheme-registration or scheme-code assertions | Scheme-record as-of instant under the declared rule | Instrument; listing/identity where exchange-traded | `UNKNOWN` |
| IN-04 | Authority-bounded | Regulator and admitting-exchange assertions | Declared venue trading date under the session rule | Instrument; listing/identity; corporate action | `UNKNOWN` |
| IN-05 | Officially enumerable | Issuing government or debt-management enumeration | Enumeration publication instant and declared as-of instant | Instrument; listing/identity where listed | `UNKNOWN` |
| IN-06 | Authority-bounded | Regulator, issuer filings and admitting facility assertions | Filing or admission as-of instant under the declared calendar | Instrument; listing/identity; corporate action | `UNKNOWN` |
| IN-07 | Provider-bounded | Named source product only after rights qualification | Source master cut-off instant declared by that source | Instrument; listing/identity if asserted | `UNKNOWN` |
| IN-08 | OTC-private | Bounded declared source scope and counterparty assertions | Reporting cut-off instant of the bounded scope | None at cohort level; per-scope only | `UNMEASURABLE` |
| IN-09 | OTC-private | Bounded declared source scope and party assertions | Reporting cut-off instant of the bounded scope | None at cohort level; per-scope only | `UNMEASURABLE` |
| IN-10 | Authority-bounded | Exchange contract-specification assertions | Contract-specification effective instant and expiry under the venue calendar | Contract; instrument; listing/identity | `UNKNOWN` |
| IN-11 | Authority-bounded | Exchange venue/operator assertion and contract specifications | Contract effective instant and expiry under the MCX calendar rule | Contract; session/time | `UNKNOWN` |
| IN-12 | Listed: Authority-bounded; OTC: OTC-private | Admitting-exchange assertions for listed products; counterparty assertions and a bounded source scope for OTC products | Declared venue trading date for listed; deal cut-off instant for OTC | Contract and listing/identity for listed; per-scope only for OTC; no combined denominator | Listed `UNKNOWN`; OTC `UNMEASURABLE` |
| IN-13 | Listed: Authority-bounded; bilateral: OTC-private; benchmark-linked: Provider-bounded; other: unclassified | Exchange specifications for listed; counterparty assertions for bilateral; named qualified source product plus administrator index identity for benchmark-linked | Contract-specification effective instant for listed; fixing or confirmation cut-off for the other subpopulations | Contract and listing/identity for listed; per-scope only for bilateral and benchmark-linked; none for other | Listed `UNKNOWN`; others `UNMEASURABLE` |
| IN-14 | Officially enumerable for identities; Derived membership | Benchmark administrator assertions | Index-method or membership effective instant with revision | Instrument (index IDs); listing/identity (membership intervals) | `UNKNOWN` |
| IN-15 | OTC-private | Versioned per-family contract and bounded source scope | Confirmation or reporting cut-off instant of that family's scope | Per-family denominator from its contract only | `UNMEASURABLE` |
| IN-16 | OTC-private | Company registry and issuer assertions under a bounded scope | Registry or filing as-of instant under a declared rule | None at cohort level; per-scope only | `UNMEASURABLE` |
| IN-17 | Authority-bounded | IFSC regulator and admitting-facility assertions | Jurisdiction rule effective instant and venue trading date | Per-product denominator from its versioned contract | `UNKNOWN` |
| IN-18 | Authority-bounded | Issuer filings and venue assertions | Announcement and effective market dates under the calendar rule | Corporate action per instrument and period | `UNKNOWN` |
| IN-19 | Statement: Authority-bounded; rating: Provider-bounded; credit event: authority-bounded where filed, OTC-private where privately declared | Regulator filing systems for statements; qualified publisher for ratings; filing authority or bounded declaring scope for credit events | Filing instant for statements; publication instant for ratings; occurrence and disclosure instants for credit events | Per-issuer or per-instrument observation denominator on each independent object contract; no roll-up | `UNKNOWN` for filings; `UNMEASURABLE` where no qualified source or bounded scope |
| IN-20 | (a) Authority-bounded releases; (b) Provider-bounded reference objects and specifications; (c) Derived | Publishing authority for releases; named publisher for specifications; declared transformation version and input universe for indicators | Release vintage for (a); specification effective instant for (b); transformation run instant for (c) | Declared release universe for (a); specification universe for (b); transformation input universe for (c); no cross-subdomain denominator | `UNKNOWN` or `UNMEASURABLE` per subdomain |

For IN-12, IN-13, IN-19 and IN-20 the verdicts are per subpopulation or per object contract; no
cohort-level verdict is formed by merging them. The mandatory twenty-question cross-domain set
with per-cohort answers is maintained once in `engineering/design/india-national-domain-catalogue.md`
§6; this table answers Q05 and Q14 for pack purposes and does not duplicate the full set.

The nine NDC coverage dimensions retain separate denominators. No pass in one dimension implies a
pass in another, no "all Indian instruments" percentage is declared, and no I6 or cohort roll-up
is formed. A dimension that does not apply to a cohort is recorded as *not applicable* for that
cohort; that is neither a pass nor a zero.

## 6. Crosswalk to global core object classes

### 6.1 Cohort to core class

| Cohort | Core classes used | NEW typed extension required |
|---|---|---|
| IN-01 | Security, FinancialInstrument, Listing, IdentifierAssertion, InstrumentTermsRevision, LegalEntity, CorporateAction | No for declared share families; yes for India-specific class attributes beyond `EquityTerms`. |
| IN-02 | Security, FinancialInstrument, LegalEntity, Listing, IdentifierAssertion, CorporateAction | No for declared receipt/right/warrant families; yes for warrant-specific exercise terms. |
| IN-03 | FinancialInstrument, Security, MarketProduct, InstrumentTermsRevision, Index | Yes for scheme-level identity, plan/option and NAV reporting beyond `FundTerms`. |
| IN-04 | Security, FinancialInstrument, LegalEntity, Listing, InstrumentTermsRevision | Yes for InvIT; `RealEstateInvestmentTrust` must not be stretched to cover it. |
| IN-05 | Security, FinancialInstrument, LegalEntity, InstrumentTermsRevision | No for declared government bond, bill and inflation-linked families; yes for other sovereign instruments. |
| IN-06 | Security, FinancialInstrument, LegalEntity, InstrumentTermsRevision, CorporateAction | Yes for securitisation and municipal-specific structure attributes. |
| IN-07 | Security, FinancialInstrument, LegalEntity, IdentifierAssertion, InstrumentTermsRevision | Yes for programme and discount-paper terms. |
| IN-08 | FinancialInstrument, LegalEntity, ContractInstance, MarketProduct, Security as collateral | Yes; repo must not be forced into a debt-security class. |
| IN-09 | FinancialInstrument, LegalEntity, ContractInstance, IdentifierAssertion, Security as loaned asset | Yes; no core class covers a securities-lending object. |
| IN-10 | ContractFamily, ContractInstance, FinancialInstrument, Security, Index, Listing, InstrumentTermsRevision | No for declared future/option families; yes for any unlisted payout shape. |
| IN-11 | MarketProduct, ContractFamily, ContractInstance, MarketCalendar, Source | Yes for commodity contract specifications with grade, unit and delivery. |
| IN-12 | FinancialInstrument, ContractFamily, ContractInstance, MarketProduct, LegalEntity, Listing for the listed subpopulation | Yes for listed currency-contract terms and for OTC tenor and settlement; listed and OTC subpopulations keep separate authorities and denominators. |
| IN-13 | ContractFamily, ContractInstance, FinancialInstrument, Index, LegalEntity, Listing for the listed subpopulation | Yes per separated subpopulation (listed, bilateral, benchmark-linked, other) for OIS and reset/fixing schedules; no forced single population model. |
| IN-14 | Index, LegalEntity, Source, Capability, Security as constituent | No for index identity; membership is an edge, not a class. |
| IN-15 | FinancialInstrument, ContractFamily, ContractInstance, LegalEntity, Source | Yes per named OTC family; no generic `Other` family. |
| IN-16 | Security, FinancialInstrument, LegalEntity, IdentifierAssertion, InstrumentTermsRevision | Yes for unlisted/private security families without a taxonomy variant. |
| IN-17 | Jurisdiction, Authority, MarketOperator, Venue, Segment, MarketProduct, plus product classes | Yes per IFSC product lacking a declared family; no automatic mainland reuse. |
| IN-18 | CorporateAction, LegalEntity, Security, Source | Yes for action types not in the declared set; never a replacement security class. |
| IN-19 | LegalEntity, Source, Capability; no core class for the three object contracts | Yes: three independent typed extensions for statement, rating and credit event with their own lifecycle, revision and provenance; a rating is not a statement and an event is not an issuer observation. |
| IN-20 | Source, DataProduct, Feed, Capability, MarketCalendar | Yes: separate typed payloads for published observations and releases, commodity reference objects and specifications, and derived indicators and transformations; a published observation is not a derived object. |

### 6.2 Core class to pack role

Every class below is an existing `ObjectClass`; none is redefined by the India pack.

| Core class | Role in the India pack | Prohibited conflation |
|---|---|---|
| Jurisdiction | India and the distinct IFSC jurisdiction-scoped partition. | Treating jurisdiction as a venue, product or rights grant. |
| Authority | SEBI, RBI, IFSCA, operators and administrators as role-bearing assertions. | Inferring an authority from a name or a venue. |
| MarketOperator | Operator of an exchange or facility, distinct from the venue. | Merging operator, venue and provider identities. |
| Venue | Exchange, reporting or settlement facility with MIC role. | Using a symbol, token or feed as a venue identity. |
| Segment | Venue-published cash, derivative, debt, commodity or other segment. | Inventing an absent segment or using one as a coverage denominator. |
| MarketProduct | Admitted product kind bound to a segment and terms class. | Treating an enum variant as an ingested product. |
| LegalEntity | Issuer, counterparty, sponsor, administrator and operator entities. | Inferring identity from a name or ISIN. |
| Security | A security object with registered or issued rights. | Merging with issuer, listing, index or repo object. |
| FinancialInstrument | Family-typed instrument object carrying terms. | Treating a reference observation as an instrument. |
| ContractFamily | Reusable product template with terms. | Counting a family as one contract. |
| ContractInstance | Dated contract with expiry and multiplier. | Merging instances that differ in expiry, strike or right. |
| Listing | Admission of one instrument to one venue. | Treating a listing as an instrument or a primary key. |
| IdentifierAssertion | ISIN, LEI, MIC and domestic scheme assertions. | Using an identifier as an identity or a completeness device. |
| InstrumentTermsRevision | Append-only bitemporal terms payload. | Overwriting a prior term revision. |
| CorporateAction | Typed action event with revision lineage. | Treating an action as a replacement security. |
| Index | Reference object with membership edges. | Assigning a security class to an index. |
| MarketCalendar | Session, closure and override assertions for a scope. | Treating a holiday list as session coverage. |
| Source | Named producer of an assertion or observation. | Treating a source as an authority, venue or right. |
| DataProduct | Named product surface declared by a source. | Treating a product name as a population. |
| Feed | Delivery-scoped identity distinct from source and venue. | Treating a feed as a venue or as permission. |
| Capability | Evidence-bound capability claim with separate rights state. | Treating a capability claim as a right or a coverage pass. |

The nine component-evidence fields of §2.1 are metadata on every pack component, not additional
`ObjectClass` variants and not a second identity system. A jurisdiction-scoped partition is an
asserted identity, not a new class tree.

A cohort needing a NEW typed extension must receive that extension in a versioned contract before
any object is forced into an existing class. No cohort is admitted by crosswalk membership alone.

## 7. Pack governance

- Version changes are monotonic and carry a source, effective interval and revision. Superseded
  rules remain addressable.
- An admitted pack version is immutable. A new rule creates a new component revision or pack
  version; no admitted component is overwritten, and the predecessor stays addressable.
- Every component carries the nine §2.1 evidence fields. A component without all nine is not
  admitted, and a verification state is never inferred from a name, code or source declaration.
- Mainland and IFSC semantics stay separated under the §3.1 definitions submitted for owner
  approval. IFSC membership needs an asserted jurisdiction reference, source and verification
  state; it is not inferred from names, venue codes, currencies, participants or feed labels.
- New venues, segments, products, schemes, currencies, calendars, settlement rules and action
  types enter through new assertions; no frozen wire surface is widened in place.
- Each pack change is reviewed against the India domain catalogue, its mandatory Q01–Q20 set, the
  coverage register's I1–I6 order and the nine-dimension denominator rule.
- Ratification of this design does not approve the content of any future pack version; each
  version needs its own owner decision before use.

## 8. Not approved

- **No data rights.** All source rights remain `UNKNOWN`. No licence, retention, replay,
  redistribution or analytics permission is granted by this document.
- **No collection.** No provider contact, market-data API call, download, scrape, adapter run or
  source retrieval is authorised.
- **No reference ingestion.** No reference-data ingestion, source qualification, rights approval,
  admission receipt or dataset acceptance is performed or implied. Pack components are declared
  shapes, not ingested values.
- **No India implementation.** No code, crate, schema, wire field, enum, contract version,
  artifact, transport, storage engine, release or producer/verifier change is authorised. The
  global core freeze is unchanged.
- **No dataset acceptance.** Dataset acceptance stays `BLOCKED`; no admission receipt, research
  dataset or experiment is created or implied.
- **W2.3 remains gated.** W2.3 India implementation stays gated on separate owner ratification of
  the design and of each country-pack version. This amendment does not open that gate.
- **Design amendments are not authorization.** The evidence model, immutability rule and
  mainland/IFSC definitions are PROPOSED declarations; they grant no right and admit no source,
  pack version or coverage count.
- No second identity system, no symbol-as-identity rule, no catch-all `Other` family, no
  permanent I6 bucket, no single "all Indian instruments" coverage percentage and no synthetic
  market-shaped evidence.
- No experiment registration, no live order submission and no change to the D11 test policy.
  Budget remains INR 0; collection stays `DISABLED`; experiments stay `BLOCKED`; live execution
  stays `DISABLED`.

## 9. Connections

- `engineering/design/india-national-domain-catalogue.md` — IN-01..IN-20 work breakdown,
  ontology rules, population types, split subpopulations and the mandatory Q01–Q20 answer set.
- `engineering/decisions/WS-SCOPE-2026-11-24-001-global-reference-core-india-first.md` — ratified
  one-core ownership and model rules.
- `engineering/coverage/india-coverage-register.md` — I1–I6 migration sequence and nine
  coverage dimensions.
- `engineering/architecture/india-domain-ownership-crosswalk.md` — Fieldbook authority, Nirnay
  projections and frozen legacy findings F1–F12.
- `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` — C0 bitemporal, provenance and
  denominator semantics.
- `README.md` — document map; `CURRENT-STATE.json` — rights, budget and acceptance state;
  `engineering/evidence/REVIEW-LOG.md` — decision record.
