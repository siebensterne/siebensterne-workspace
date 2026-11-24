# India National Domain Catalogue — proposed

- **Status:** PROPOSED. Awaiting owner ratification. This document fixes the domain work
  breakdown and ontology rules only. It ratifies no contract, grants no right, qualifies no
  provider and accepts no dataset.
- **Task / branch / base:** IN-CAT-001 created this catalogue; amended in place under
  IN-CAT-002/003/004 · branch `docs/india-catalogue-amendments` · workspace base `7b0eb2e`.
  Documentation only: this catalogue and its companion decision are edited in place. No second
  catalogue or decision is created; no source repository, schema, contract version, release,
  dataset, experiment or gate policy is edited.
- **Amendment record (2026-11-24, PROPOSED):** explicit listed/OTC and four-way interest-rate
  subpopulations (IN-12, IN-13); three IN-20 subdomains with published observations kept distinct
  from derived indicators; independent statement, rating and credit-event object contracts
  (IN-19); a mandatory 20-question cross-domain set answered for every cohort (§6); and an
  explicit not-approved section (§9). Status remains PROPOSED pending owner ratification.
- **Authority read:** `engineering/decisions/WS-SCOPE-2026-11-24-001-global-reference-core-india-first.md`
  (ratified: global reference core, India first; one identity system; bitemporal assertions;
  declared denominators), `engineering/coverage/india-coverage-register.md` (I1–I6 migration
  sequence and nine coverage dimensions), `engineering/architecture/india-domain-ownership-crosswalk.md`
  (domain crosswalk and findings F1–F12), `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md`
  (C0 semantics).
- **Source alignment:** `fieldbook/src/domain/reference_core.rs` (`ObjectClass`, `ObjectId`,
  `IdentifierAssertion`, `BitemporalAssertion`, `CoverageCell`), `instrument_terms.rs`
  (`Unit`, `ExactMeasure`, seven term families, `ContractFamily`, `ContractInstance`),
  `market_registry.rs` (`JurisdictionCode`, authority/venue/segment/product assertions,
  `CountryPack`), `capability_registry.rs` (`CapabilityAssertion`, `EvidenceRef`,
  `CapabilityCoverageRegistry`), and `fieldbook/src/domain/taxonomy.rs` (`InstrumentKind`,
  `DataCategory`). Implemented types are the vocabulary authority; this document adds no
  competing class tree.
- **Companion decision:** `engineering/decisions/IN-COUNTRY-001-india-country-pack-design.md`.

## 1. Nature of this catalogue

This catalogue is a **domain work breakdown** of the Indian financial information space into
twenty cohorts. It is **not** a claim of enumerable population, **not** a claim that any provider
or source is qualified, and **not** a list of datasets that exist, are attainable or are
licensable. A cohort names objects, relationships, assertions and measurement conditions that a
later, separately ratified country pack and versioned contract may bind. It does not assert that
those bindings have been made. Stated plainly: this document is a domain work breakdown, not a
claim of enumerable population or qualified provider.

No coverage percentage is recorded here, including zero. Where a complete public population
cannot be established from a named authoritative source at a declared as-of instant, the
population measure is `UNKNOWN` (a denominator axis is declared but its count is not admitted) or
`UNMEASURABLE` (no commensurable denominator can be declared for the cohort at all). No count,
list, ticker set, ISIN set, public webpage or successful connection is promoted to a denominator.
An empty scope grants nothing.

The nine NDC coverage dimensions stay separate. They are instrument, listing/identity, contract,
corporate-action, session/time, trade-event, quote/depth, MBO and sequence continuity. Each has
its own universe, denominator, as-of instant and verdict. There is no "all Indian instruments"
percentage, no roll-up across cohorts and no combined coverage score in this catalogue.

## 2. Ontology rules

The following rules are binding for this catalogue and for any later country pack derived from
it. A violation is a concept conflation, not a naming preference.

| Rule | Required distinction | Prohibited treatment |
|---|---|---|
| Index is not a security | `ObjectClass::Index` is a reference object with its own identity and `IndexTerms`; `constituent_of` membership is an effective-dated edge. An index-linked or tracked product is a separate `Security` or `FinancialInstrument`. | Assigning a `Security` class to an index, inheriting an index's status from a constituent, or using index membership as a tradable instrument. |
| Issuer is not an instrument | A `LegalEntity` is bound through an `issued_by` edge; issuer identity requires entity evidence such as LEI and is never inferred from a name, symbol or ISIN text. | Treating an issuer, a company name or an ISIN prefix as an instrument identity or as one object with the security. |
| Listing is not an instrument | `Listing` is the admission of one instrument to one venue, with an effective interval and optional segment. One instrument may have many listings. | Merging same text on two venues into one identity, or using symbol or token as a primary key. |
| Repo transaction is not a debt-security subtype | A repo is a financing transaction with its own legal/economic object and terms. A debt security that is eligible collateral remains a separate object. | Recording `RepurchaseAgreement` as a subtype of `Bond` or inheriting debt seniority, coupon or maturity from the collateral. |
| Corporate action is not a replacement security | `CorporateAction` is an event with revision lineage, announcement, ex, record, effective and payment times. A successor instrument is a separate object joined by an effective-dated edge. | Replacing the original instrument with a "new" instrument for an action, or overwriting the prior action revision. |
| Derivative family is not an individual contract | `ContractFamily` is a reusable template; `ContractInstance` adds expiry and multiplier. An option is distinct by underlying, expiry, strike, right and specification. | Treating a product family as one contract with a mutable expiry, or counting a family as one contract instance. |
| No generic `Other` family | Every family is named and typed by a versioned contract. The `IdentifierScheme` string escape hatch is not a completeness device. | Introducing a generic `Other`, `Misc` or catch-all family to make a universe look complete. |
| I6 is a migration register, not a bucket | I1–I6 is an ordered qualification sequence. I6 names domains that must each receive a per-domain contract and denominator before entry. | Using I6 as a permanent resting place for unclassified products or as a substitute for a typed extension. |
| Listed and OTC subpopulations are distinct | A listed product is bounded by venue admission assertions and an exchange authority; an OTC product is bounded by counterparties and a declared source scope. Each subpopulation names its own authority, denominator and verdict inside one cohort. | Applying one `OTC-private` population model to a whole cohort, merging listed and OTC denominators, or inferring listed status from a fixing publication, a currency code or a rate name. |
| Published observation is not a derived object | A published economic observation carries its source, release, vintage and knowledge time; a derived indicator is a separate object computed under a declared transformation version over a declared input universe. | Recording a released observation as a `wasDerivedFrom` transformation output, or counting a release in a derived-indicator denominator. |
| Statement, rating and credit event are distinct objects | Each receives its own object contract with lifecycle, revision lineage and provenance: a statement is a reported period, a rating is an asserted opinion, a credit event is a typed occurrence. | Treating a rating as a financial statement, a credit event as merely an issuer observation, or collapsing all three into one `Source` record or one `CorporateAction` without a versioned contract. |
| Pack evidence is mandatory on every component | Every country-pack component carries identity, version, source, source digest, valid interval, knowledge time, revision, predecessor and verification state, as specified in `IN-COUNTRY-001`. | Admitting a jurisdiction, venue, scheme, calendar or rule from a name, a code, an undated label or an unverified assertion. |

These rules restate the ratified scope decision and existing crosswalk findings; they do not
create a new instrument hierarchy. The catalogue groups work by domain, not by a competing
classification of all objects.

## 3. Population-type classes

Each cohort is classified by the nature of its population boundary. The class describes how a
denominator would have to be established; it does not establish one.

| Class | Definition | What it permits |
|---|---|---|
| Officially enumerable | A complete public enumeration exists from an official authority and can be bound to an admitted assertion at a declared as-of instant. | A denominator may be proposed only after the enumeration and as-of instant are named in a release. |
| Authority-bounded | An authority defines admission or registration conditions, but no complete public enumeration is asserted here. | A denominator can be proposed only from the authority's effective-dated assertions; otherwise `UNKNOWN`. |
| Provider-bounded | The population boundary comes from a named source product or master, not from an official register. | Nothing until that source is rights-qualified; without a qualified source the measure is `UNKNOWN` or `UNMEASURABLE`. |
| OTC-private | Objects arise from bilateral or private agreements with no complete public register. | No population claim; the measure is `UNMEASURABLE` unless a bounded, declared private population is asserted. |
| Derived | The population is computed from other asserted objects or observations under a declared transformation. | A denominator only from the declared transformation version and its input universe; never from the output alone. |

Any cohort whose population authority, as-of instant or denominator axis is undeclared remains
`UNKNOWN` or `UNMEASURABLE`. Absent denominators grant nothing.

A cohort may declare several **subpopulations**. Each subpopulation names its own population
authority, denominator axis, as-of rule and verdict; the cohort keeps one identifier and one name,
but no cohort-level verdict is formed by merging subpopulations. The population type recorded for
a split cohort in §4 is the set of its subpopulation classes, not a single class. A subpopulation
boundary is a work-breakdown declaration, not an admission of any source or population count.

## 4. Cohort register

The exact identifiers and names below are fixed by this work package. The I-column is the
migration phase from the coverage register; it is a development order, not a coverage state.

| ID | Exact cohort name | Population type | Migration entry | Primary core classes |
|---|---|---|---|---|
| IN-01 | Equity and equity-linked securities | Authority-bounded | I1 | Security, FinancialInstrument, Listing, InstrumentTermsRevision, LegalEntity |
| IN-02 | Depositary receipts, rights and warrants | Authority-bounded | I1 | Security, FinancialInstrument, Listing, IdentifierAssertion, LegalEntity |
| IN-03 | ETFs, mutual funds and collective investment products | Authority-bounded | I1 | FinancialInstrument, Security, MarketProduct, InstrumentTermsRevision |
| IN-04 | REITs and InvITs | Authority-bounded | I1 (extension) | Security, FinancialInstrument, LegalEntity, InstrumentTermsRevision |
| IN-05 | Government securities | Officially enumerable | I5 | Security, FinancialInstrument, LegalEntity, InstrumentTermsRevision |
| IN-06 | Corporate and municipal debt | Authority-bounded | I5 | Security, FinancialInstrument, LegalEntity, InstrumentTermsRevision |
| IN-07 | Commercial paper and certificates of deposit | Provider-bounded | I5 | Security, FinancialInstrument, LegalEntity, IdentifierAssertion |
| IN-08 | Money markets and repo | OTC-private | I5 (extension) | FinancialInstrument, LegalEntity, ContractInstance, MarketProduct |
| IN-09 | Securities lending, borrowing and collateral | OTC-private | I5 (extension) | FinancialInstrument, LegalEntity, ContractInstance, IdentifierAssertion |
| IN-10 | Equity and index derivatives | Authority-bounded | I3 | ContractFamily, ContractInstance, FinancialInstrument, Index |
| IN-11 | Commodity markets and derivatives | Authority-bounded | I4 | MarketProduct, ContractFamily, ContractInstance, MarketCalendar |
| IN-12 | Currency markets and derivatives | Listed: Authority-bounded; OTC: OTC-private (§5, IN-12) | I5 | FinancialInstrument, ContractFamily, ContractInstance, MarketProduct, Listing for the listed subpopulation |
| IN-13 | Interest-rate markets and derivatives | Listed: Authority-bounded; bilateral: OTC-private; benchmark-linked: Provider-bounded; other: unclassified (§5, IN-13) | I5 (extension) | ContractFamily, ContractInstance, FinancialInstrument, Index, Listing for the listed subpopulation |
| IN-14 | Indices and benchmarks | Officially enumerable | I2 | Index, ObjectRef edges, Source, Capability |
| IN-15 | OTC and privately negotiated instruments | OTC-private | I6 | FinancialInstrument, ContractFamily, ContractInstance, LegalEntity |
| IN-16 | Unlisted and private securities | OTC-private | I6 | Security, FinancialInstrument, LegalEntity, IdentifierAssertion |
| IN-17 | IFSC products and facilities | Authority-bounded | I6 | Jurisdiction, Authority, Venue, Segment, MarketProduct |
| IN-18 | Corporate actions and issuer information | Authority-bounded | I1 (I5 extension) | CorporateAction, LegalEntity, Security, Source |
| IN-19 | Financial statements, ratings and credit events | Statement: Authority-bounded; rating: Provider-bounded; credit event: authority-bounded where filed, OTC-private where privately declared (§5, IN-19) | I6 | LegalEntity, Source, Capability; three independent object contracts under typed extensions (§5, IN-19) |
| IN-20 | Economic and commodity reference information | (a) Authority-bounded releases; (b) Provider-bounded reference objects and specifications; (c) Derived indicators (§5, IN-20) | I6 | Source, DataProduct, Capability, MarketCalendar; separate observation, specification and transformation payloads |

## 5. Cohort detail

Each row below is a work-breakdown declaration, not an enumerable-population or qualified-provider
claim. Every completeness measure stays `UNKNOWN` or `UNMEASURABLE` until an admitted release
names a source authority, an as-of instant and a denominator. Venue, authority and infrastructure
names in this section are scoping candidates only; none is admitted or qualified here.

### IN-01 Equity and equity-linked securities

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Security` and `FinancialInstrument` for the share; `LegalEntity` for the issuer; `Listing` for admission; `InstrumentTermsRevision` for effective terms; `CorporateAction` for issuer events. |
| Instrument families | Taxonomy families `CommonShare`, `PreferredShare`, `ConvertibleSecurity`, `SpecialPurposeAcquisitionCompany`. India-specific share classes require a named typed extension, not a new general family. |
| Contract families and instances | Not applicable to cash equity; declared as such. A convertible or linked instrument with a conversion term requires a typed terms payload, not a derivative `ContractInstance` unless a versioned contract declares one. |
| Entity relationships | `issued_by` to issuer; listing to one venue and optional segment; identifier assertions to the instrument; action events to the affected instrument; no relationship from a symbol to an identity. |
| Identifier schemes | ISIN, exchange symbol, token and name as scoped, effective-dated `IdentifierAssertion`; LEI on the issuer; every scheme names its assigning authority and scope. |
| Terms and units | `EquityTerms` voting, fractional and par value; par value as `ExactMeasure` with `Unit::Currency` and declared scale; face/par units are not promoted to platform-wide units. |
| Lifecycle | Issuance, admission, trading, suspension, delisting and cancellation as effective-dated assertions with status; no status inferred from a live snapshot. |
| Venue and segment applicability | Candidate NSE and BSE cash venues and their published cash segments; segment optional where a venue publishes none; venue identity distinct from operator, provider and feed. |
| Effective time | Half-open `[valid_from, valid_to)` on identity, listing, identifier and terms assertions; market dates normalised in `Asia/Kolkata` under a declared rule version. |
| Knowledge time | `recorded_at_us` on each assertion; publication, source and receive instants carried separately; revision selection by as-of and knowledge time, never arrival order. |
| Population authority | SEBI and the admitting exchange for listed securities; no complete public population asserted in this package. |
| Coverage denominator | Instrument and listing/identity dimensions from the same release; corporate-action and session/time declared separately. Counts `UNKNOWN`; no "all Indian equity" denominator. |
| Data capabilities | `ReferenceData`, `CorporateActions`, `MarketStatus`, trade and quote/depth capabilities only when separately admitted; capability is not permission. |
| Rights dependencies | All source rights `UNKNOWN`; provider qualification, retention, replay and analytics require separate written evidence and owner approval. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-02 Depositary receipts, rights and warrants

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Security`, `FinancialInstrument`, `LegalEntity` for issuer or depositary, `Listing`, `IdentifierAssertion`, `CorporateAction`. |
| Instrument families | Taxonomy families `DepositaryReceipt`, `Right`, `Warrant`. A convertible warrant term needs an explicit typed payload, not an inferred equity family. |
| Contract families and instances | Not applicable for cash-exercised rights and warrants unless a versioned contract declares an instance object; a warrant is not a call option by classification alone. |
| Entity relationships | `issued_by` to issuer; underlying link to the referenced security; depositary relationship held as a distinct legal-entity edge; listing to one venue. |
| Identifier schemes | ISIN, exchange symbol, token and domestic series identifier as scoped `IdentifierAssertion`; underlying identifier asserted independently, never derived from the receipt's text. |
| Terms and units | Ratio, subscription or conversion price, entitlement and exercise windows as `ExactMeasure` with declared unit, scale and currency context. |
| Lifecycle | Issuance, entitlement record date, exercise window, conversion or lapse, suspension and delisting, each effective dated. |
| Venue and segment applicability | Candidate listed venues and their published segments; no assumed reuse of the IN-01 cash segment where a venue publishes a separate segment. |
| Effective time | Half-open validity on the instrument, listing and terms; entitlement and exercise windows carry declared market dates under the venue rule. |
| Knowledge time | Announcement and publication times distinct from `recorded_at_us`; corrections append a revision with its own knowledge time. |
| Population authority | SEBI and the admitting exchange or depositary; no complete public population asserted. |
| Coverage denominator | Instrument and listing/identity, plus corporate-action where entitlements apply; counts `UNKNOWN`. No roll-up with IN-01. |
| Data capabilities | `ReferenceData`, `CorporateActions`, `MarketStatus`; trade and quote/depth only under a separate admitted release. |
| Rights dependencies | Rights `UNKNOWN`; no source is qualified and no dataset is accepted by this catalogue. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-03 ETFs, mutual funds and collective investment products

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `FinancialInstrument` and `Security` for the unit; `LegalEntity` for the scheme or trust and asset manager; `MarketProduct`; `InstrumentTermsRevision`; `Index` where the product tracks one. |
| Instrument families | Taxonomy families `ExchangeTradedFund`, `ExchangeTradedNote`, `Fund`. A scheme-level mutual-fund identity, plan and option require a named typed extension of `FundTerms`; scheme code is an identifier, not identity. |
| Contract families and instances | Not applicable to an open-ended scheme; an exchange-traded derivative on a fund belongs to IN-10 under its own contract version. |
| Entity relationships | Scheme or trust to manager `LegalEntity`; `constituent_of` or tracking link to an `Index` where declared; listing to venue; NAV observation to `Source`. |
| Identifier schemes | ISIN where assigned, exchange symbol, domestic scheme code, AMFI-style scheme identifier as scoped assertions; each names its assigning authority. |
| Terms and units | `FundTerms` NAV frequency and redemption mode; `ExactMeasure` for NAV with `Unit::Currency`, declared scale and currency context; ratios expressed in `Unit::Ratio`. |
| Lifecycle | Scheme launch, NAV publication, creation/redemption, merger, wind-up and delisting as effective-dated assertions. |
| Venue and segment applicability | Exchange-traded products use candidate cash venues and published segments; non-exchange schemes declare no venue and no invented segment. |
| Effective time | Half-open terms and listing intervals; NAV and portfolio observations carry their own data-time instants. |
| Knowledge time | NAV publication time distinct from `recorded_at_us`; corrected NAV or scheme terms append a new revision. |
| Population authority | SEBI and the scheme-registration or scheme-code authority; no complete public population asserted. |
| Coverage denominator | Instrument, listing/identity and session/time where exchange-traded; reference observations separately. Counts `UNKNOWN`. |
| Data capabilities | `ReferenceData`, `Fundamentals` where admitted; `MarketStatus` for listed products; no quote/depth or trade claim. |
| Rights dependencies | Rights `UNKNOWN`; scheme data qualification is a separate owner decision. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-04 REITs and InvITs

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Security`, `FinancialInstrument`, `LegalEntity` for the trust and sponsor, `Listing`, `InstrumentTermsRevision`, `CorporateAction`. |
| Instrument families | Taxonomy family `RealEstateInvestmentTrust`. An InvIT requires a **NEW typed extension**; it must not be forced into the REIT variant or a general fund family. |
| Contract families and instances | Not applicable; unit-level distributions are events, not contract instances. |
| Entity relationships | `issued_by` to trust; sponsor and manager as distinct legal-entity edges; asset or project holding represented by separate asserted entities; listing to venue. |
| Identifier schemes | ISIN, exchange symbol and token as scoped assertions; trust and sponsor LEI asserted separately. |
| Terms and units | Distribution frequency, unit face value and redemption mode in a typed payload; amounts as `ExactMeasure` with declared currency and scale. |
| Lifecycle | Registration, listing, distribution, unit change, sponsor change and delisting as effective-dated events. |
| Venue and segment applicability | Candidate listed venues and their published debt or cash segments as declared by the venue; no segment invented. |
| Effective time | Half-open validity on listing and terms; distribution events carry ex, record and payment market dates. |
| Knowledge time | `recorded_at_us` plus publication time per distribution or correction; corrections append revisions. |
| Population authority | SEBI and the admitting exchange; no complete public population asserted. |
| Coverage denominator | Instrument, listing/identity and corporate-action dimensions; counts `UNKNOWN`. No combined IN-01/IN-03 ratio. |
| Data capabilities | `ReferenceData`, `CorporateActions`; trade and quote/depth only under separate admission. |
| Rights dependencies | Rights `UNKNOWN`; no qualification of any trust or sponsor source. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-05 Government securities

- **Population type:** Officially enumerable.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Security`, `FinancialInstrument`, `LegalEntity` for the issuing sovereign or agency, `InstrumentTermsRevision`, `Listing` where listed. |
| Instrument families | Taxonomy families `GovernmentBond`, `TreasuryBill`, `InflationLinkedBond`. State development loans and agency paper require named typed extensions when their terms differ from these families. |
| Contract families and instances | Primary issuance is not a derivative contract; an auction is an issuance event with its own asserted terms, not a `ContractInstance`. |
| Entity relationships | `issued_by` to the sovereign or agency; coupon and maturity assertions to the security; listing to venue; identifier assertions to the security. |
| Identifier schemes | ISIN, domestic scrip code and exchange symbol as scoped `IdentifierAssertion`; sovereign `LegalEntity` identity asserted independently. |
| Terms and units | `DebtTerms` principal, coupon, maturity and `DebtSeniority`; `ExactMeasure` with `Unit::Currency` or `Unit::Percent`, declared scale, currency context and day-count rule. |
| Lifecycle | Auction announcement, issuance, listing, coupon payment, buyback, rollover, redemption and maturity, each effective dated. |
| Venue and segment applicability | Candidate exchanges and the wholesale debt segment where declared; an unlisted security has no invented venue or segment. |
| Effective time | Half-open validity on terms; auction and payment dates normalised under the declared calendar and timezone rule. |
| Knowledge time | Auction publication and result times carried separately from `recorded_at_us`; a re-auction or revised result appends a revision. |
| Population authority | The issuing government and its debt-management authority; enumerability is conditional on an admitted enumeration with a declared as-of instant. |
| Coverage denominator | Instrument and listing/identity where listed; session/time only from an admitted calendar. Current counts `UNKNOWN`; enumeration is not a count asserted here. |
| Data capabilities | `ReferenceData`, `MarketStatus`; quote/depth and trade only under a separate admitted release. |
| Rights dependencies | Rights `UNKNOWN`; public issuance information does not grant retention, replay or analytics rights. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-06 Corporate and municipal debt

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Security`, `FinancialInstrument`, `LegalEntity` for issuer and guarantor, `Listing`, `InstrumentTermsRevision`, `CorporateAction`. |
| Instrument families | Taxonomy families `CorporateBond`, `MunicipalBond`, `MortgageBackedSecurity`, `AssetBackedSecurity`, `CollateralizedLoanObligation`. Securitisation tranches need declared structure attributes. |
| Contract families and instances | Not applicable for straight debt; an interest-rate swap linked to the issuer belongs to IN-13 under its own contract version. |
| Entity relationships | `issued_by` to issuer; `SuccessorOf` for issuer reorganisation where asserted; guarantor and trustee edges; listing to venue. |
| Identifier schemes | ISIN, exchange symbol, domestic serial and CUSIP-style foreign identifiers where present, all as scoped effective-dated assertions; issuer LEI separate. |
| Terms and units | `DebtTerms` principal, coupon, maturity and seniority (`Senior`, `Subordinated`, `Secured`, `Unsecured`, `Perpetual`) with exact currency and percent measures. |
| Lifecycle | Private placement, listing, coupon, redemption, restructuring, default, delisting and maturity as asserted events. |
| Venue and segment applicability | Candidate exchange debt segments and private-placement reporting facilities; segment optional and never inferred from an ISIN. |
| Effective time | Half-open terms intervals; coupon and maturity dates under the declared business-day and day-count rules. |
| Knowledge time | Issuer filing or trustee notice publication time distinct from `recorded_at_us`; restructuring corrections append revisions. |
| Population authority | SEBI, the issuer and the admitting exchange or reporting facility; no complete public population asserted. |
| Coverage denominator | Instrument, listing/identity and corporate-action dimensions; counts `UNKNOWN` where no admitted assertion exists. |
| Data capabilities | `ReferenceData`, `CorporateActions`; `Fundamentals` only where an issuer filing is admitted. |
| Rights dependencies | Rights `UNKNOWN`; no provider is qualified by this work-breakdown entry. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-07 Commercial paper and certificates of deposit

- **Population type:** Provider-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Security`, `FinancialInstrument`, `LegalEntity` for issuer, `IdentifierAssertion`, `InstrumentTermsRevision`. |
| Instrument families | Taxonomy families `CommercialPaper`, `CertificateOfDeposit`. Programme-level or dealer-specific variants require a named typed extension, not an inferred family. |
| Contract families and instances | Not applicable; a CP/CD programme is an issuance arrangement, not a derivative family. Discount and yield terms are term assertions. |
| Entity relationships | `issued_by` to issuer; programme link to issuer; discount or coupon terms to the instrument; identifier assertions scoped by issuer and series. |
| Identifier schemes | ISIN where assigned, domestic serial number and programme reference as scoped assertions; issuer LEI asserted independently. |
| Terms and units | Principal, discount or coupon, issue and maturity dates and tenor as `ExactMeasure` with declared currency, scale and `Unit::TimeUnit` context. |
| Lifecycle | Programme establishment, issuance, rollover, redemption and maturity; a rolled instrument is a new assertion, not a rewritten predecessor. |
| Venue and segment applicability | Typically no listing venue; any exchange or reporting facility must be asserted. No segment invented for an unlisted programme. |
| Effective time | Half-open validity on instrument and terms; issue and maturity instants under the declared money-market calendar. |
| Knowledge time | Programme or issuance disclosure time distinct from `recorded_at_us`; revised programmes append revisions. |
| Population authority | The issuing entity and its programme disclosures under the applicable regulator; a named source product is required to bound any population. |
| Coverage denominator | Instrument and listing/identity only where an admitted source defines them; otherwise `UNMEASURABLE`. No count asserted. |
| Data capabilities | `ReferenceData`; quote/depth and trade only under a separately admitted source release. |
| Rights dependencies | Rights `UNKNOWN`; a source product must be rights-qualified before any population boundary from it is used. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-08 Money markets and repo

- **Population type:** OTC-private.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `FinancialInstrument` for repo and reverse repo, `LegalEntity` for counterparties, `ContractInstance` where a standard contract is declared, `MarketProduct`. A pledged debt security remains IN-05 or IN-06. |
| Instrument families | Taxonomy family `RepurchaseAgreement`; reverse repo, repo-index and tri-party facilities require named typed extensions. No repo family is a debt-security subtype. |
| Contract families and instances | A repo master agreement is a contract family with declared collateral eligibility, haircut and tenor terms; each trade is an effective-dated instance with collateral object references. |
| Entity relationships | Two counterparty `LegalEntity` edges with distinct roles; `collateral_of` edge to the separate security; cash and collateral legs as asserted terms, not an issuer relationship. |
| Identifier schemes | Deal and programme references from a named source, ISIN of collateral as a separate assertion, LEI of counterparties; deal references are source-scoped, not global identities. |
| Terms and units | Notional, repo rate, haircut and term as `ExactMeasure` with declared currency, percent, ratio and time units; settlement date under the declared money-market calendar. |
| Lifecycle | Trade initiation, collateral substitution, rate reset, margin call, close and failure as effective-dated events. |
| Venue and segment applicability | Primarily off-venue; any reported or platform-traded repo venue must be asserted with operator and MIC role. No venue inferred from a rate publication. |
| Effective time | Half-open validity on contract terms and collateral substitutions; trade and settlement instants under declared calendars. |
| Knowledge time | Trade confirmation, disclosure and correction times separate from `recorded_at_us`; corrections append revisions. |
| Population authority | Counterparties and the applicable regulator; no complete public register of bilateral repo trades exists here. |
| Coverage denominator | `UNMEASURABLE` for a complete repo population absent a declared bounded source scope; no denominator asserted. |
| Data capabilities | `ReferenceData` for contract specs; trade and quote capabilities only under a separately admitted and rights-qualified source. |
| Rights dependencies | Rights `UNKNOWN`; no bilateral trade or rate source is qualified. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-09 Securities lending, borrowing and collateral

- **Population type:** OTC-private.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `FinancialInstrument` for the lending arrangement, `LegalEntity` for lender, borrower and agent, `ContractInstance`, `Security` for the loaned asset. |
| Instrument families | No taxonomy family covers securities lending; a **NEW typed extension** is required. A loaned share remains the equity object of IN-01. |
| Contract families and instances | Lending agreement terms form a family; each loan is an instance with object, quantity, fee, collateral and recall terms. A family is not one loan. |
| Entity relationships | Lender, borrower and agent edges distinct from `issued_by`; collateral and loaned-security references to their own instruments; no issuer inferred from a borrower. |
| Identifier schemes | Loan and programme references from a named source, ISIN of loaned and collateral securities, LEI of parties; all scoped and effective dated. |
| Terms and units | Fee or rebate rate, quantity, collateral value and haircut as `ExactMeasure` with currency, percent, ratio and count units and declared scales. |
| Lifecycle | Loan opening, recall, return, collateral substitution, corporate-action pass-through, close and failure, each with effective and knowledge times. |
| Venue and segment applicability | Off-venue unless a clearing or platform facility is asserted; no segment inferred from the underlying security's segment. |
| Effective time | Half-open intervals for loan and collateral terms; recall and return instants under the declared calendar. |
| Knowledge time | Confirmation and amendment times separate from `recorded_at_us`; an amended loan appends a revision. |
| Population authority | Lending parties and any asserted reporting facility; no complete public population. |
| Coverage denominator | `UNMEASURABLE` without a declared bounded source scope; no dilution of instrument or listing denominators with loan counts. |
| Data capabilities | `ReferenceData`; trade and status capabilities only from an admitted source and never as a coverage substitute. |
| Rights dependencies | Rights `UNKNOWN`; no lending or collateral source is qualified. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-10 Equity and index derivatives

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `ContractFamily`, `ContractInstance`, `FinancialInstrument` for the derivative, `Security` or `Index` as underlying, `InstrumentTermsRevision`. |
| Instrument families | Taxonomy families `Future`, `Option` and, where declared, `Swap`. The derivative projection uses `DerivativeKind` over the shared `InstrumentKind`; no competing classification enum. |
| Contract families and instances | Family carries underlying, kind and terms template; each instance carries expiry and multiplier. Option identity also depends on strike, right and specification. A family is not a contract. |
| Entity relationships | `underlying_of` to security or index, `option_of` for option kind, `deliverable_of` for physical settlement, listing to a derivative segment; no identity merged with the underlying. |
| Identifier schemes | Exchange product code and contract symbol as scoped assertions, ISIN where assigned to the derivative, underlying canonical ID copied from the admitted release. |
| Terms and units | `DerivativeTerms` tick size, lot, multiplier, settlement mode, expiry; strike as an exact decimal string or `ExactMeasure`; tick and lot declared per product, never global defaults. |
| Lifecycle | Contract specification, listing, trading, expiry, exercise, assignment, settlement and withdrawal as effective-dated assertions; status not inherited from the underlying. |
| Venue and segment applicability | Candidate derivative segments on NSE/BSE under a **NEW versioned contract**; the cash-only v2 surface must not be widened; no contract variant presented under v2. |
| Effective time | Half-open terms validity and contract life; expiry and settlement instants under the declared calendar and timezone rule. |
| Knowledge time | Specification publication and correction times distinct from `recorded_at_us`; a revised contract spec appends a revision. |
| Population authority | The exchange publishing contract specifications and its regulator; no complete population asserted in this package. |
| Coverage denominator | Contract dimension is primary; instrument and listing/identity from the same release. Counts `UNKNOWN`; an enum variant is not an ingested contract. |
| Data capabilities | `ReferenceData`, `MarketStatus`; trade, quote/depth, MBO and sequence only under a separately admitted observation release with their own denominators. |
| Rights dependencies | Rights `UNKNOWN`; contract specification access, retention and replay require separate written evidence. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-11 Commodity markets and derivatives

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `MarketProduct`, `ContractFamily`, `ContractInstance`, `FinancialInstrument`, `MarketCalendar`, `Source`. |
| Instrument families | Taxonomy families `CommoditySpot` and `CommodityAssessment`; commodity futures and options need a **NEW typed extension** with product, grade, unit and delivery terms. Assessments belong to IN-20 when treated as reference information. |
| Contract families and instances | A commodity product specification is a family template; each expiry is a distinct instance. Grade and delivery location are declared attributes, not inferred from a continuous series. |
| Entity relationships | Product to venue and segment; contract instance to product; `deliverable_of` where physical delivery applies; assessment to `Source`; no identity from a commodity name. |
| Identifier schemes | Exchange product and contract codes as scoped assertions, MIC for venue role, source-specific assessment symbol; all scheme authorities declared. |
| Terms and units | `CommodityTerms` grade, delivery location and unit; `ExactMeasure` with `Unit::WeightGram`, `WeightKilogram`, `VolumeBarrel`, `VolumeCubicMeter` or `PricePerUnit` as declared; no global unit promotion. |
| Lifecycle | Contract listing, trading, expiry, delivery, settlement and withdrawal; roll and continuous series are derived projections, not identity merges. |
| Venue and segment applicability | Candidate MCX venue and operator assertions with MIC role and a versioned commodity segment; closed cash `Venue`/`Segment` enums must not be reused without a contract version. |
| Effective time | Half-open contract and session intervals; expiry and delivery instants under the venue calendar and declared timezone. |
| Knowledge time | Specification and assessment publication times separate from `recorded_at_us`; corrections append revisions. |
| Population authority | The exchange and its regulator for contracts; an assessment publisher only after qualification for reference values. |
| Coverage denominator | Contract dimension primary, plus session/time from the venue calendar; counts `UNKNOWN`. Assessment coverage is never mixed into contract coverage. |
| Data capabilities | `ReferenceData`, `MarketStatus`; trade and quote only under separate admission; a price assessment is not a trade quote. |
| Rights dependencies | Rights `UNKNOWN`; no exchange or assessment source is qualified. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-12 Currency markets and derivatives

- **Population type:** Two subpopulations inside one cohort: listed currency products and OTC
  currency products. No single `OTC-private` model covers the cohort as a whole.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `FinancialInstrument` for currency pair and FX derivatives, `ContractFamily`, `ContractInstance`, `LegalEntity` for counterparties, `Source` for rate assertions. |
| Instrument families | Taxonomy families `FxSpot`, `FxForward`, `FxSwap`, `NonDeliverableForward`; exchange-traded currency futures and options use `Future`/`Option` with currency underlyings under a declared contract. |
| Contract families and instances | Forward points, swap tenors and NDF fixing terms form families; each value date and counterparty trade is an instance. A currency pair is not one contract. |
| Entity relationships | Base and quote currency identities as asserted reference objects; `underlying_of` for FX derivatives; counterparty edges; no identity inferred from a currency pair label. |
| Identifier schemes | ISO 4217 currency codes as asserted identifiers, domestic contract codes from a named venue where listed, source deal references for OTC; each scoped and effective dated. |
| Terms and units | `FxTerms` base and quote units and pip scale; rates and points as `ExactMeasure` with declared scale and `Unit::PricePerUnit`; settlement date under dual-calendar rules. |
| Lifecycle | Quotation, dealing, fixing, settlement, roll and cancellation, each with effective and knowledge times. |
| Venue and segment applicability | Listed currency products require an asserted venue, operator and segment; OTC products declare no venue. No venue inferred from a fixing publication or a currency code. |
| Effective time | Half-open validity on currency and contract terms; fixing and value dates under the declared timezone and calendar rule. |
| Knowledge time | Fixing publication and deal confirmation times distinct from `recorded_at_us`; corrections append revisions. |
| Population authority | Listed products: the admitting exchange and its regulator under a venue assertion. OTC products: counterparties and the applicable regulator with a declared bounded source scope. No population authority covers the whole cohort. |
| Coverage denominator | Listed products: contract and listing/identity dimensions from exchange specifications and listing assertions at a declared venue date, currently `UNKNOWN`. OTC products: no cohort-level denominator; per-scope deal population only, `UNMEASURABLE` absent a declared scope. No combined listed-plus-OTC or FX-and-debt denominator. |
| Data capabilities | `ReferenceData` for currency identity; trade and quote only under a separately admitted source release. |
| Rights dependencies | Rights `UNKNOWN`; rate and deal sources require separate qualification. |

**Subpopulation boundaries (§5, IN-12).** One programme cohort, two explicit subpopulations:

| Subpopulation | Object boundary | Population authority | Denominator model | Current verdict |
|---|---|---|---|---|
| Listed currency products | Exchange-traded FX futures and options as `FinancialInstrument`, `ContractFamily`, `ContractInstance` plus a `Listing` to an asserted venue and segment. | Admitting exchange and its regulator; exchange contract-specification assertions. | Contract and listing/identity dimensions from those specifications and listing assertions at a declared venue trading date. | `UNKNOWN`; no count asserted. |
| OTC currency products | Spot, forward, swap and NDF trades as counterparty-bounded `ContractInstance` objects; collateral and currency identities remain separate objects. | Counterparties and applicable regulator with a declared bounded source scope. | No cohort-level denominator; a per-scope deal population only when that scope is admitted with an as-of instant. | `UNMEASURABLE` absent a declared scope. |

Listed status is never inferred from a fixing publication, a currency pair label or a venue code,
and an OTC deal reference is never promoted to a listed-product identifier.

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-13 Interest-rate markets and derivatives

- **Population type:** Four separated subpopulations inside one cohort: listed contracts,
  bilateral instruments, benchmark-linked agreements and other interest-rate products. No single
  population model is forced across them.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `ContractFamily`, `ContractInstance`, `FinancialInstrument`, `Index` for a referenced benchmark, `LegalEntity` for counterparties. |
| Instrument families | Taxonomy family `Swap` plus `Future` and `Option` on rates or benchmarks; an Indian overnight-index swap or OIS tenor requires a named typed extension of the swap terms. |
| Contract families and instances | A curve tenor or swap specification is a family; each trade, value date and fixing schedule is an instance. A benchmark index is not the swap. |
| Entity relationships | `underlying_of` to a rate index or debt instrument, counterparty edges, clearing house edge where cleared; no identity merged with the benchmark administrator. A benchmark-linked agreement points to the index through an asserted reference, not an identity merge. |
| Identifier schemes | Source deal and confirmation references, ISIN where assigned to a listed instrument, benchmark identifier as a separate asserted object; LEI for parties. |
| Terms and units | Fixed and floating legs, spread, notional, day-count and payment frequency as `ExactMeasure` with currency, percent, basis-points and time units; no global day-count assumption. |
| Lifecycle | Trade, confirmation, fixing, reset, payment, compression, novation and termination as effective-dated events. |
| Venue and segment applicability | Listed contracts require an asserted venue, operator and segment; bilateral and benchmark-linked instruments declare no venue unless a reporting or clearing facility is asserted. Cleared status is a separate assertion, not a property of the rate name. |
| Effective time | Half-open validity on terms and reset schedules; fixing and payment dates under the declared calendar and business-day convention. |
| Knowledge time | Fixing publication and confirmation times separate from `recorded_at_us`; a corrected fixing appends a revision. |
| Population authority | Listed contracts: the admitting exchange and its regulator. Bilateral instruments: counterparties under a bounded source scope. Benchmark-linked agreements: the named source product after qualification; the benchmark administrator supplies index identity only (IN-14). Other products have no declared authority until typed. |
| Coverage denominator | Listed contracts: contract and listing/identity dimensions from exchange specifications, currently `UNKNOWN`. Bilateral and benchmark-linked instruments: per-scope only, `UNMEASURABLE` absent a declared scope. Other products: no denominator. Benchmark identity coverage is a separate IN-14 claim; no cross-subpopulation roll-up. |
| Data capabilities | `ReferenceData` for curve and benchmark identity; trade and quote only under separate admission. |
| Rights dependencies | Rights `UNKNOWN`; no curve, fixing or dealer source is qualified. |

**Ontology separation and subpopulation boundaries (§5, IN-13).** One programme cohort, four explicit
subpopulations with distinct object contracts and population models:

| Subpopulation | Object boundary | Population authority | Denominator model | Current verdict |
|---|---|---|---|---|
| Listed contracts | Exchange-traded rate futures and options as `ContractFamily`, `ContractInstance` and `Listing` on an asserted venue and segment. | Admitting exchange and its regulator. | Contract and listing/identity from exchange specifications and listing assertions at a declared venue date. | `UNKNOWN`; no count asserted. |
| Bilateral instruments | Swaps and forwards as counterparty-bounded `ContractInstance` objects with their own confirmation and reset terms. | Counterparties and applicable regulator under a declared bounded source scope. | No cohort-level denominator; per-scope agreement population only when that scope is admitted. | `UNMEASURABLE` absent a declared scope. |
| Benchmark-linked agreements | An agreement referencing a benchmark index, with an asserted reference edge; the benchmark identity is the IN-14 `Index`, not the agreement. | Named source product for the agreement population after qualification; benchmark administrator for index identity only. | Agreement population bounded by the named source scope; benchmark identity and membership are a separate IN-14 denominator. | `UNMEASURABLE` absent a declared scope. |
| Other interest-rate products | No single model: each product requires a named typed extension and its own authority, terms and denominator declaration. | None declared until the typed extension is admitted; I6 is not an authority. | None until a per-product contract declares an axis and as-of instant. | `UNMEASURABLE`; no catch-all family or I6 roll-up. |

Cleared status, benchmark membership and listed admission are separate assertions; none is inferred
from a rate name, a tenor label or a currency code.

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-14 Indices and benchmarks

- **Population type:** Officially enumerable for index identities; constituent membership is
  Derived from effective-dated edges.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Index` as a distinct reference object, `Source` for index metadata, `Capability` for evidence-bound index claims, `LegalEntity` for the administrator; constituents are `Security` or `FinancialInstrument`. |
| Instrument families | Taxonomy families `EquityIndex` and `RateIndex`; `EconomicIndicator` belongs to IN-20. An index is never assigned a security family, and a tracked product is a separate instrument. |
| Contract families and instances | Not applicable; an index derivative belongs to IN-10 under its own contract version and is recorded as *not applicable* here, not as covered. |
| Entity relationships | `constituent_of` edges with effective intervals; index-family identity distinct from any tracked instrument; `wasDerivedFrom` for a tracked series; administrator as `LegalEntity`. |
| Identifier schemes | Index identifier from the administrator, index-family identifier, source symbol and optionally ISIN for an index-linked product; each scheme scoped and authority-bearing. |
| Terms and units | `IndexTerms` declared constituent count and rebalance frequency; weights as `ExactMeasure` with `Unit::Ratio` and declared scale; a level or return is an observation, not identity. |
| Lifecycle | Index launch, rebalance, constituent addition or removal, method change, discontinuation and successor index as effective-dated assertions. |
| Venue and segment applicability | An index is not a listing and has no venue or segment; a series derived from a listing states the source venue as provenance only. Membership is not a cash-segment claim. |
| Effective time | Half-open membership and method intervals with as-of resolution; membership state derives from edges, never from a live constituent file. |
| Knowledge time | Announcement and publication times separate from `recorded_at_us`; a restated membership or method appends a revision. |
| Population authority | The benchmark administrator; enumerability conditional on an admitted index-identity enumeration with a declared as-of instant. |
| Coverage denominator | Instrument coverage uses index identities; listing/identity uses membership intervals; a series requires its own observation denominator. Counts `UNKNOWN`. |
| Data capabilities | `ReferenceData` for identity and membership; level and return series only under separate admission and not as proof of identity coverage. |
| Rights dependencies | Rights `UNKNOWN`; administrator terms and index data rights require separate written evidence. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-15 OTC and privately negotiated instruments

- **Population type:** OTC-private.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `FinancialInstrument`, `ContractFamily`, `ContractInstance`, `LegalEntity`, `Source`; any security leg keeps its own `Security` object. |
| Instrument families | Named, typed families only: OTC options, swaps, structured notes and privately negotiated forwards as declared by versioned contracts. No generic `Other` family and no catch-all cohort entry. |
| Contract families and instances | Each product specification is a family; each trade is an instance with its own terms and counterparties. An instance is not a new family and a family is not a population. |
| Entity relationships | Counterparty and agent edges, underlying edge to a security, index or rate, and source attestation; no identity inferred from a term sheet name. |
| Identifier schemes | Source deal and confirmation references with named authority and scope; LEI for parties; ISIN for any issued security leg as a separate assertion. |
| Terms and units | Each typed payload declares payoff, notional, tenor and settlement with `ExactMeasure` units and scales; no universal payoff or unit assumption. |
| Lifecycle | Negotiation, confirmation, amendment, fixing, settlement, exercise, unwind and termination as effective-dated events. |
| Venue and segment applicability | No venue or segment by default; a reported or cleared facility enters only with an asserted venue, operator and facility identity. |
| Effective time | Half-open validity on terms; fixing and settlement instants under declared calendars and timezones. |
| Knowledge time | Confirmation and disclosure times distinct from `recorded_at_us`; amendments append revisions with supersession. |
| Population authority | Counterparties and the applicable regulator; no complete public population and no single source product bounds the cohort. |
| Coverage denominator | `UNMEASURABLE` at cohort level; per-family denominators only from that family's versioned contract. No I6 roll-up. |
| Data capabilities | `ReferenceData` for contract specs; trade or quote capability only where a bounded source is separately admitted. |
| Rights dependencies | Rights `UNKNOWN`; every family needs its own rights scope before any boundary claim. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-16 Unlisted and private securities

- **Population type:** OTC-private.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Security`, `FinancialInstrument`, `LegalEntity` for issuer, `IdentifierAssertion`, `InstrumentTermsRevision`. |
| Instrument families | Unlisted equity, private-company shares, alternative-investment-fund units and private placements as named typed families; each requires a **NEW typed extension** where the shared taxonomy has no variant. |
| Contract families and instances | Not applicable for a simple private security; a private derivatives position belongs to IN-15 under its own contract version. |
| Entity relationships | `issued_by` to issuer; holder and transfer records as source assertions; no relationship inferred from a share certificate number. |
| Identifier schemes | ISIN where assigned, domestic registration or certificate numbers as source-scoped assertions, issuer LEI; identifier reuse produces separate intervals. |
| Terms and units | Share class, face value, voting and transfer restrictions in a typed payload; amounts as `ExactMeasure` with declared currency and scale. |
| Lifecycle | Incorporation, allotment, transfer, issue, buyback, cancellation and dissolution as effective-dated assertions; no exchange status is assumed. |
| Venue and segment applicability | No venue and no segment; an unlisted segment of an exchange applies only where the venue publishes one and the security is admitted. |
| Effective time | Half-open validity on identity, identifiers and terms; corporate register dates normalised under a declared rule. |
| Knowledge time | Filing or registry publication time distinct from `recorded_at_us`; corrections append revisions. |
| Population authority | Company registry and issuer under the applicable law; no complete public population for the cohort as a whole. |
| Coverage denominator | `UNMEASURABLE` without a bounded declared source; an ISIN list is not a population authority. |
| Data capabilities | `ReferenceData` only; no market-status, trade or quote capability for a security with no asserted venue. |
| Rights dependencies | Rights `UNKNOWN`; registry or filing information grants no analytics or redistribution right. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-17 IFSC products and facilities

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Jurisdiction`, `Authority`, `MarketOperator`, `Venue`, `Segment`, `MarketProduct`, plus product classes from the cohort actually traded. |
| Instrument families | Product families are declared per admitted IFSC product; no family is inherited from mainland India cohorts solely by name. IFSC-specific variants require named typed extensions. |
| Contract families and instances | Declared by the product's versioned contract; a family in IN-10 or IN-11 does not automatically transfer across the jurisdiction distinction. |
| Entity relationships | Jurisdiction to authorities and operators; operator to venue; venue to segment; listing to instrument; each reference jurisdiction-checked and bitemporal. |
| Identifier schemes | ISIN, LEI and MIC as global schemes; IFSC venue codes and domestic identifiers as scoped assertions; scheme authority and jurisdiction declared on every assertion. |
| Terms and units | Product terms from the relevant typed payload; currency identities asserted separately, with INR and offshore currencies distinct and no implied convertibility. |
| Lifecycle | Product admission, listing, trading, settlement, expiry and withdrawal under the IFSC authority's asserted rules. |
| Venue and segment applicability | Candidate IFSC exchanges and facilities with operator, MIC role and published segments; venue identity distinct from mainland venues and from any provider or feed. |
| Effective time | Half-open validity for jurisdiction, authority, venue, segment and product assertions; regulation effective dates declared per version. |
| Knowledge time | Regulatory publication and venue notice times distinct from `recorded_at_us`; a rule change appends a revision. |
| Population authority | The IFSC regulator and admitting facilities under a distinct jurisdiction-scoped pack; no complete public population asserted. |
| Coverage denominator | Per-product denominators from that product's versioned contract; no combined mainland-plus-IFSC percentage. Counts `UNKNOWN`. |
| Data capabilities | `ReferenceData` for jurisdiction, venue and product; market capabilities only from an admitted IFSC source release. |
| Rights dependencies | Rights `UNKNOWN`; IFSC status of an entity or product is not evidence of data rights. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-18 Corporate actions and issuer information

- **Population type:** Authority-bounded.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `CorporateAction`, `LegalEntity`, `Security`, `Source`; a successor instrument is a separate object, never a replacement of the original. |
| Instrument families | Action types are typed events, not instrument families: dividend, split, bonus, rights, buyback, merger, demerger, consolidation, symbol change, delisting, cancellation and correction. |
| Contract families and instances | Not applicable; an action has revision lineage rather than a contract family. A rights issue creates an IN-02 instrument as a separate object. |
| Entity relationships | Action to affected instrument and issuer; `SuccessorOf` edge where a reorganisation creates a successor; supersession to a predecessor action revision. |
| Identifier schemes | Issuer LEI, security ISIN and venue symbol as scoped assertions; action identity is platform-assigned and never inferred from the announcement text. |
| Terms and units | Ratio, amount per unit, currency, tax basis and dates as `ExactMeasure` with declared scale; ex, record, effective and payment dates kept separate. |
| Lifecycle | Announcement, ex date, record date, effective date, payment date, correction and invalidation, each with effective and knowledge times. |
| Venue and segment applicability | Actions on listed instruments inherit venue as provenance from the listing assertion; unlisted issuer actions declare no venue. |
| Effective time | Half-open validity on action assertions; market dates normalised under the declared venue calendar rule. |
| Knowledge time | Announcement and publication times separate from `recorded_at_us`; a correction is a new revision and the earlier revision stays addressable. |
| Population authority | Issuer filings and the admitting venue under the applicable regulator; no complete public action population asserted. |
| Coverage denominator | Corporate-action dimension per instrument and period; counts `UNKNOWN`. Embedded snapshots and local ledgers are frozen legacy, not action evidence. |
| Data capabilities | `CorporateActions` with revision lineage; `ReferenceData` for issuer and security identity. |
| Rights dependencies | Rights `UNKNOWN`; filing access does not grant redistribution or derived-dataset rights. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-19 Financial statements, ratings and credit events

- **Population type:** Three independent object contracts with separate population models:
  statements are authority-bounded from filing systems; ratings are provider-bounded on a qualified
  publisher; credit events are authority-bounded where filed and OTC-private where privately
  declared. A rating is not a statement and a credit event is not merely an issuer observation.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `LegalEntity` for issuer, `Source` for the filing or rating publisher, `Capability` for evidence-bound claims. Three independent object contracts — financial statement, rating and credit event — each with its own lifecycle, revision lineage and provenance; no class is forced into `CorporateAction` without a versioned contract. |
| Instrument families | Not applicable: statements, ratings and credit events describe issuers or instruments; they are not securities. Any related debt instrument belongs to IN-05 or IN-06. |
| Contract families and instances | Not applicable; no derivative contract shape is assumed for a statement, rating or credit event. |
| Entity relationships | Statement to issuer and reported period; rating to issuer or rated instrument and publisher; credit event to issuer or instrument and its declaring source; `hadPrimarySource` on each object; no entity identity from a company name. |
| Identifier schemes | LEI for the entity, ISIN for the rated instrument where present, source document identifier and publication reference as scoped effective-dated assertions. |
| Terms and units | Statement figures and rating scales as `ExactMeasure` with declared unit, scale, currency and accounting or rating standard; ratios never inherit a cross-cohort unit. |
| Lifecycle | Each object contract has its own transitions: statement filing, publication, restatement and withdrawal; rating initiation, review, action, watch and withdrawal; credit-event occurrence, announcement, verification and resolution. |
| Venue and segment applicability | Filing venues are reporting facilities, not trading venues; only an asserted reporting facility identity may be recorded, and no trading segment is inferred. |
| Effective time | Half-open validity on reported period, rating and event interval; reported period, event occurrence and publication instant declared separately. |
| Knowledge time | Publication, disclosure and restatement times distinct from `recorded_at_us` on each object contract; a restatement, rating correction or event correction appends a revision. |
| Population authority | Statements: regulator filing systems. Ratings: a qualified publisher, so `Provider-bounded`. Credit events: the filing authority where filed, counterparties and a bounded source scope where privately declared. |
| Coverage denominator | Instrument coverage is not a denominator here; each object contract declares a per-issuer or per-instrument observation denominator. Counts `UNKNOWN` or `UNMEASURABLE` per object contract; no statement-plus-rating roll-up. |
| Data capabilities | `Fundamentals` for filings and `ReferenceData` for ratings identity only where separately admitted; capability is not permission. |
| Rights dependencies | Rights `UNKNOWN`; filing, rating and credit-event data each require separate written evidence before any qualification. |

**Independent object contracts (§5, IN-19).** A rating is not a statement and a credit event is not
merely an issuer observation. Each contract below needs a versioned typed payload; none is an
implemented core class and none may be collapsed into another without a separate contract.

| Object contract | Identity and lifecycle | Revision and correction | Provenance and population |
|---|---|---|---|
| Financial statement | Platform-assigned identity; reported period, filing, publication, restatement, withdrawal as distinct states; issuer LEI and source document id as assertions. | Restatement or correction appends a new revision with predecessor link; the prior reported value stays addressable at its original knowledge time. | `hadPrimarySource` to the filing, publication time and source digest; authority-bounded from regulator filing systems; per-issuer observation denominator. |
| Rating | Platform-assigned identity distinct from the issuer and the statement; initiation, review, rating action, watch placement and withdrawal as distinct states; issuer LEI and rated-instrument ISIN as assertions. | Rating action or correction appends a revision with supersession; prior rating and its methodology version remain addressable. | `hadPrimarySource` to the publisher, methodology version, publication time and source digest; provider-bounded on a qualified publisher; no statement population is reused. |
| Credit event | Platform-assigned identity for a typed occurrence (default, recovery, restructuring); occurrence, announcement, verification and resolution as distinct states; issuer or instrument reference only. | Correction appends a new revision with predecessor link; earlier verification state stays addressable. | `hadPrimarySource` to the filing or declaring source, occurrence and disclosure times, source digest; authority-bounded where filed, OTC-private where privately declared; no issuer-observation denominator substituted. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

### IN-20 Economic and commodity reference information

- **Population type:** Three subdomains inside one cohort: (a) economic observations and releases
  are authority-bounded by the publishing authority; (b) commodity reference objects and
  specifications are authority- or provider-bounded by a named publisher; (c) derived indicators
  and transformations are Derived under a declared transformation version. A published economic
  observation is not a derived object.

| Attribute | Declaration |
|---|---|
| Legal/economic object classes | `Source`, `DataProduct`, `Capability`, `MarketCalendar` where release timing is asserted. Three separate object contracts: published economic observation, commodity reference object or specification, and derived indicator; all are reference information, not securities. |
| Instrument families | Taxonomy families `EconomicIndicator` and `CommodityAssessment` as scoping labels only; an assessment is not a trade, quote or security even where it names a commodity contract. A published observation is not a derived object. |
| Contract families and instances | Not applicable; no derivative contract shape is assumed for an observation, specification or assessment. |
| Entity relationships | Published observation to `Source`, `DataProduct` and a release event; specification to its publisher and methodology; derived indicator to declared inputs by `wasDerivedFrom` under a transformation version; no identity from a series name. |
| Identifier schemes | Source series code, release identifier, specification code and assessment code as scoped assertions with named authority and effective intervals; domestic codes are not global keys. |
| Terms and units | Value, unit, scale, frequency, vintage and revision as `ExactMeasure` with declared unit and timezone; assessment methodology, grade and location declared with the specification, not inferred from a contract. |
| Lifecycle | Separate transitions by subdomain: scheduled release, publication, revision and discontinuation for observations; specification publication, supersession and withdrawal for reference objects; transformation run, output publication and correction for derived indicators. |
| Venue and segment applicability | No venue or segment; an exchange is provenance only when a reference value is explicitly sourced from it. |
| Effective time | Observation and reference periods declared separately from publication; half-open validity on series and specification definitions, revision intervals and transformation versions. |
| Knowledge time | Release, specification and correction publication times distinct from `recorded_at_us`; a revised vintage appends a revision and preserves the prior value. |
| Population authority | (a) the publishing authority for releases; (b) the named specification publisher or assessment source; (c) no authority for a derived population except a declared transformation version and input universe. |
| Coverage denominator | (a) observation/release universe from the publishing authority; (b) specification universe from the named publisher; (c) transformation input universe under the declared version. No cross-subdomain denominator; never counted as instrument or trade coverage. Counts `UNKNOWN` or `UNMEASURABLE` by subdomain. |
| Data capabilities | `EconomicRelease` and `ReferenceData` where admitted; an assessment or derived indicator is not `Trades`, BBO or MBP evidence. |
| Rights dependencies | Rights `UNKNOWN`; publication or public display grants no retention, replay or redistribution right. |

**Three subdomains (§5, IN-20).** One cohort name and identifier; three non-conflated object contracts:

| Subdomain | Object contract | Population model and denominator | Non-conflation rule |
|---|---|---|---|
| (a) Economic observations and releases | A published observation with source, series code, release event, reference period, vintage and knowledge time. | Authority-bounded from the publishing authority; denominator is the declared release/observation universe at a stated vintage. | A published economic observation is not a derived object and is never counted in a derived-indicator denominator. |
| (b) Commodity reference objects and specifications | A reference object or specification with grade, unit, location, methodology and publisher. | Authority-bounded for official specifications, provider-bounded for assessments; denominator is the named publisher's specification universe. | Not a contract instance, trade, quote or security even where it names a commodity contract; no roll into IN-11 contract coverage. |
| (c) Derived indicators and transformations | A computed indicator carrying `wasDerivedFrom`, a declared transformation version and a declared input universe. | Derived; denominator exists only from that transformation version and its inputs, never from the output alone. | A transformation cannot convert a published observation into an observation of a different authority; no release is treated as a transformation output without an asserted mapping. |

Not a population or provider claim; measure `UNKNOWN`/`UNMEASURABLE` absent an admitted source,
as-of instant and denominator.

## 6. Mandatory cross-domain question set

Every cohort answers Q01–Q20 below. The answers are compact and point to the declarations in §5;
they add no source, count, right or admission. *Not applicable* is an answer only when a reason is
given. A split cohort answers per subpopulation (§5, IN-12, §5, IN-13, §5, IN-19, §5, IN-20).

### 6.1 The twenty questions

The user directive names nineteen items with identifier schemes and assigning authorities as one
item; they are separated here so that the mandatory set has exactly twenty questions (Q03, Q04).

| ID | Mandatory question | Required answer shape |
|---|---|---|
| Q01 | What is the legal/economic object? | Named object class or declared object contract, not a label. |
| Q02 | What is the identity authority? | Opaque platform identity plus external identity evidence; no name-derived identity. |
| Q03 | Which external identifier schemes appear? | Named schemes only; no generic `Other` escape hatch. |
| Q04 | Which assigning authorities issue them? | Authority, scope and jurisdiction on each scheme assertion. |
| Q05 | What defines the population? | Population class, authority, as-of rule and subpopulations, or `UNMEASURABLE`. |
| Q06 | How are revisions represented? | Append-only, nonzero revision, predecessor link, addressable prior state. |
| Q07 | What is effective time? | Half-open interval and declared market-date rule. |
| Q08 | What is knowledge time? | `recorded_at_us` with publication and receive instants held apart. |
| Q09 | What lifecycle transitions apply? | Named, effective-dated states and events. |
| Q10 | What relationships apply? | Typed edges; no identity merge or symbol-as-key. |
| Q11 | What instrument terms apply? | Typed terms payload or explicit not-applicable with reason. |
| Q12 | What units and currencies apply? | Exact measures, scale and currency context; no global defaults. |
| Q13 | What market-calendar dependencies apply? | Venue, timezone, rule version and asserted calendar sessions. |
| Q14 | What is the coverage denominator? | Dimension, source, as-of instant and verdict; no count without one. |
| Q15 | What source capabilities are claimed? | Evidence-bound capability claims; capability is not permission. |
| Q16 | What is the rights state? | `UNKNOWN` plus the qualification dependency. |
| Q17 | What retention is granted? | None by this design; separate written evidence and owner approval. |
| Q18 | What is the correction mechanism? | New revision with supersession; no overwrite. |
| Q19 | What is the canonical payload schema? | Named typed payload or a required NEW typed extension. |
| Q20 | How may future country packs reuse it? | Only through the global core and a jurisdiction-scoped pack version. |

### 6.2 Per-cohort answers

#### IN-01 Equity and equity-linked securities

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Security`, `FinancialInstrument`, `LegalEntity` issuer, `Listing`; opaque platform identity, issuer identity by LEI evidence. |
| Q03 / Q04 | ISIN, exchange symbol, token and name; each names its assigning authority and scope. |
| Q05 / Q06 | Authority-bounded listed equity; append-only revisions with nonzero revision and predecessor. |
| Q07 / Q08 | Half-open `[valid_from, valid_to)` under `Asia/Kolkata`; `recorded_at_us` apart from publication and receive times. |
| Q09 / Q10 | Issue, admit, trade, suspend, delist, cancel; `issued_by`, listing, identifier and action edges. |
| Q11 / Q12 | `EquityTerms` voting, fractional and par value; exact currency measure with declared scale. |
| Q13 / Q14 | Declared venue session rule; instrument and listing/identity, counts `UNKNOWN`. |
| Q15 / Q16 | `ReferenceData`, `CorporateActions`, `MarketStatus` on admission; rights `UNKNOWN`. |
| Q17 / Q18 | Retention and replay not granted; correction appends a revision with supersession. |
| Q19 / Q20 | `EquityTerms` or named typed extension; reuse only via the core and a scoped pack version. |

#### IN-02 Depositary receipts, rights and warrants

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Security`, `FinancialInstrument`, issuer or depositary `LegalEntity`, `Listing`; opaque identity, no name key. |
| Q03 / Q04 | ISIN, exchange symbol, token, domestic series id; each names its assigning authority. |
| Q05 / Q06 | Authority-bounded on regulator and admitting exchange or depositary; append-only revisions. |
| Q07 / Q08 | Half-open validity on instrument, listing and terms; announcement time apart from `recorded_at_us`. |
| Q09 / Q10 | Issue, entitlement record date, exercise, conversion or lapse, delist; issuer, underlying and depositary edges. |
| Q11 / Q12 | Ratio, subscription or conversion price, exercise window as exact measures with declared units. |
| Q13 / Q14 | Venue rule for entitlement and exercise dates; instrument and listing/identity, plus action where applicable. |
| Q15 / Q16 | `ReferenceData`, `CorporateActions`, `MarketStatus`; rights `UNKNOWN`. |
| Q17 / Q18 | No retention or replay grant; corrections append revisions with their own knowledge time. |
| Q19 / Q20 | Named receipt, right or warrant payload; cross-pack reuse requires a jurisdiction-scoped assertion. |

#### IN-03 ETFs, mutual funds and collective investment products

| IDs | Answers |
|---|---|
| Q01 / Q02 | `FinancialInstrument`, `Security`, `MarketProduct`, scheme `LegalEntity`; scheme code is an identifier, not identity. |
| Q03 / Q04 | ISIN where assigned, exchange symbol, scheme code, AMFI-style id; each names its assigning authority. |
| Q05 / Q06 | Authority-bounded on scheme registration; corrections append revisions. |
| Q07 / Q08 | Half-open terms and listing intervals; NAV publication time apart from `recorded_at_us`. |
| Q09 / Q10 | Launch, NAV publication, creation or redemption, merger, wind-up; scheme, manager, index and listing edges. |
| Q11 / Q12 | `FundTerms` NAV frequency and redemption mode; exact currency NAV and `Unit::Ratio` measures. |
| Q13 / Q14 | Exchange venue rule for listed products only; instrument, listing/identity and session/time where listed. |
| Q15 / Q16 | `ReferenceData`, `Fundamentals` where admitted; rights `UNKNOWN`. |
| Q17 / Q18 | No retention by this design; corrected NAV or terms append a revision. |
| Q19 / Q20 | `FundTerms` plus typed scheme, plan and option extension; no automatic cross-pack scheme reuse. |

#### IN-04 REITs and InvITs

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Security`, `FinancialInstrument`, trust and sponsor `LegalEntity`, `Listing`; opaque platform identity. |
| Q03 / Q04 | ISIN, exchange symbol, token; trust and sponsor LEI asserted separately with named authorities. |
| Q05 / Q06 | Authority-bounded on regulator and admitting exchange; append-only revisions. |
| Q07 / Q08 | Half-open listing and terms intervals; distribution times apart from `recorded_at_us`. |
| Q09 / Q10 | Registration, listing, distribution, unit or sponsor change, delist; issued-by, sponsor and listing edges. |
| Q11 / Q12 | Distribution frequency, face value and redemption mode in a typed payload; exact currency amounts. |
| Q13 / Q14 | Declared venue rule for ex, record and payment dates; instrument, listing/identity, corporate action. |
| Q15 / Q16 | `ReferenceData`, `CorporateActions`; rights `UNKNOWN`. |
| Q17 / Q18 | No retention or replay grant; each correction appends a revision. |
| Q19 / Q20 | REIT family or NEW typed InvIT extension; no automatic mainland-to-IFSC product reuse. |

#### IN-05 Government securities

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Security`, `FinancialInstrument`, sovereign or agency `LegalEntity`, `Listing` where listed. |
| Q03 / Q04 | ISIN, domestic scrip code, exchange symbol; sovereign identity asserted independently. |
| Q05 / Q06 | Officially enumerable only after an admitted enumeration; re-auction appends a revision. |
| Q07 / Q08 | Half-open terms validity; auction publication and result times apart from `recorded_at_us`. |
| Q09 / Q10 | Auction, issue, list, coupon, buyback, rollover, redeem, mature; issued-by, coupon and listing edges. |
| Q11 / Q12 | `DebtTerms` principal, coupon, maturity, seniority; exact currency or percent measures with day count. |
| Q13 / Q14 | Declared debt-market calendar; instrument and listing/identity where listed, counts `UNKNOWN`. |
| Q15 / Q16 | `ReferenceData`, `MarketStatus`; rights `UNKNOWN` despite public issuance. |
| Q17 / Q18 | No retention, replay or analytics grant; revised results append revisions. |
| Q19 / Q20 | Declared bond, bill or inflation-linked payload; typed extension for other sovereign paper. |

#### IN-06 Corporate and municipal debt

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Security`, `FinancialInstrument`, issuer and guarantor `LegalEntity`, `Listing`, action events. |
| Q03 / Q04 | ISIN, exchange symbol, domestic serial, foreign identifiers; issuer LEI asserted separately. |
| Q05 / Q06 | Authority-bounded on regulator, issuer filings and admitting facility; corrections append revisions. |
| Q07 / Q08 | Half-open terms; filing or trustee notice time apart from `recorded_at_us`. |
| Q09 / Q10 | Placement, list, coupon, redeem, restructure, default, delist; issued-by, successor, guarantor edges. |
| Q11 / Q12 | `DebtTerms` with declared seniority; exact principal, coupon and percent measures. |
| Q13 / Q14 | Declared business-day and day-count rule; instrument, listing/identity and action dimensions. |
| Q15 / Q16 | `ReferenceData`, `CorporateActions`, `Fundamentals` on admitted filings; rights `UNKNOWN`. |
| Q17 / Q18 | No retention grant; restructuring corrections append revisions. |
| Q19 / Q20 | Declared debt payload; typed extension for securitisation and municipal structures. |

#### IN-07 Commercial paper and certificates of deposit

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Security`, `FinancialInstrument`, issuer `LegalEntity`, `IdentifierAssertion`; opaque identity. |
| Q03 / Q04 | ISIN where assigned, domestic serial, programme reference; each scoped by issuer and series. |
| Q05 / Q06 | Provider-bounded on a named source product; rollover is a new assertion, not a rewrite. |
| Q07 / Q08 | Half-open instrument and terms intervals; disclosure time apart from `recorded_at_us`. |
| Q09 / Q10 | Programme establishment, issue, rollover, redeem, mature; issued-by, programme and terms edges. |
| Q11 / Q12 | Principal, discount or coupon, tenor as exact measures with currency and time units. |
| Q13 / Q14 | Declared money-market calendar; instrument and listing/identity only if an admitted source defines them. |
| Q15 / Q16 | `ReferenceData`; rights `UNKNOWN` until the source is rights-qualified. |
| Q17 / Q18 | No retention or replay grant; revised programmes append revisions. |
| Q19 / Q20 | CP/CD payload with programme terms; typed extension for dealer-specific variants. |

#### IN-08 Money markets and repo

| IDs | Answers |
|---|---|
| Q01 / Q02 | `FinancialInstrument` for repo, counterparty `LegalEntity`, `ContractInstance`; collateral remains separate. |
| Q03 / Q04 | Source-scoped deal and programme references, collateral ISIN, counterparty LEI; no global deal keys. |
| Q05 / Q06 | OTC-private with no complete public register; trade amendments append revisions. |
| Q07 / Q08 | Half-open contract and collateral intervals; confirmation and disclosure times apart from `recorded_at_us`. |
| Q09 / Q10 | Initiate, substitute collateral, reset, margin call, close, fail; counterparty and `collateral_of` edges. |
| Q11 / Q12 | Notional, repo rate, haircut and term with declared currency, percent, ratio and time units. |
| Q13 / Q14 | Declared money-market calendar; `UNMEASURABLE` at cohort level, per-scope only. |
| Q15 / Q16 | `ReferenceData` for contract specs; rights `UNKNOWN`, no trade source qualified. |
| Q17 / Q18 | No retention or replay grant; corrections append revisions. |
| Q19 / Q20 | NEW typed repo contract, never a debt-security subtype; cross-pack reuse needs its own assertion. |

#### IN-09 Securities lending, borrowing and collateral

| IDs | Answers |
|---|---|
| Q01 / Q02 | `FinancialInstrument` arrangement, `LegalEntity` parties and agent, `ContractInstance`, loaned `Security`. |
| Q03 / Q04 | Source-scoped loan and programme references, security ISINs and party LEIs; authority on each. |
| Q05 / Q06 | OTC-private with no complete public population; amended loans append revisions. |
| Q07 / Q08 | Half-open loan and collateral intervals; confirmation time apart from `recorded_at_us`. |
| Q09 / Q10 | Open, recall, return, substitute, pass through action, close, fail; distinct lender, borrower and agent edges. |
| Q11 / Q12 | Fee or rebate, quantity, collateral value, haircut with declared currency, percent, ratio and count units. |
| Q13 / Q14 | Declared recall and return calendar; `UNMEASURABLE` without a bounded declared scope. |
| Q15 / Q16 | `ReferenceData`; rights `UNKNOWN`. |
| Q17 / Q18 | No retention grant; amendments append revisions with supersession. |
| Q19 / Q20 | NEW typed lending extension; loaned security identity is copied, never reused by name. |

#### IN-10 Equity and index derivatives

| IDs | Answers |
|---|---|
| Q01 / Q02 | `ContractFamily`, `ContractInstance`, derivative `FinancialInstrument`, `Security` or `Index` underlying. |
| Q03 / Q04 | Exchange product code, contract symbol, ISIN where assigned; underlying id from admitted release. |
| Q05 / Q06 | Authority-bounded on exchange specifications; revised specs append revisions. |
| Q07 / Q08 | Half-open terms and contract life; publication time apart from `recorded_at_us`. |
| Q09 / Q10 | Specify, list, trade, expire, exercise, assign, settle, withdraw; underlying and deliverable edges. |
| Q11 / Q12 | `DerivativeTerms` tick, lot, multiplier, settlement and expiry; exact strike measures. |
| Q13 / Q14 | Declared derivative-segment calendar; contract primary, instrument and listing/identity same release. |
| Q15 / Q16 | `ReferenceData`, `MarketStatus`; rights `UNKNOWN`. |
| Q17 / Q18 | No retention or replay grant; corrected spec appends a revision. |
| Q19 / Q20 | NEW versioned derivative contract; cash-only surface is not widened in another pack. |

#### IN-11 Commodity markets and derivatives

| IDs | Answers |
|---|---|
| Q01 / Q02 | `MarketProduct`, `ContractFamily`, `ContractInstance`, `FinancialInstrument`, `MarketCalendar`, `Source`. |
| Q03 / Q04 | Exchange product and contract codes, MIC, source assessment symbol; each declares its authority. |
| Q05 / Q06 | Authority-bounded for contracts; assessment coverage separate; corrections append revisions. |
| Q07 / Q08 | Half-open contract and session intervals; specification time apart from `recorded_at_us`. |
| Q09 / Q10 | List, trade, expire, deliver, settle, withdraw; product, instance and deliverable edges. |
| Q11 / Q12 | `CommodityTerms` grade, location and unit; declared weight, volume or price-per-unit measures. |
| Q13 / Q14 | MCX venue calendar under a versioned rule; contract and session/time, counts `UNKNOWN`. |
| Q15 / Q16 | `ReferenceData`, `MarketStatus`; rights `UNKNOWN`. |
| Q17 / Q18 | No retention grant; roll and continuous series are projections, not identity rewrites. |
| Q19 / Q20 | NEW typed commodity contract; assessments stay in IN-20(b) in any pack. |

#### IN-12 Currency markets and derivatives

| IDs | Answers |
|---|---|
| Q01 / Q02 | Listed FX derivatives as contract objects plus `Listing`; OTC spot, forward, swap and NDF as counterparty-bounded instances. |
| Q03 / Q04 | ISO 4217 codes as assertions, exchange codes for listed, source deal references for OTC; authorities declared per scope. |
| Q05 / Q06 | Two subpopulations: listed authority-bounded, OTC OTC-private; corrections append revisions. |
| Q07 / Q08 | Half-open terms with dual-calendar value dates; fixing and deal confirmation times held apart. |
| Q09 / Q10 | Quote, deal, fix, settle, roll, cancel; base and quote identities, underlying and counterparty edges. |
| Q11 / Q12 | `FxTerms` base and quote units, pip scale; exact rate and points with declared currency context. |
| Q13 / Q14 | Listed venue calendar; listed denominator contract and listing/identity (`UNKNOWN`), OTC per-scope only (`UNMEASURABLE`). |
| Q15 / Q16 | `ReferenceData`; rights `UNKNOWN`. |
| Q17 / Q18 | No retention or replay grant; corrections append revisions. |
| Q19 / Q20 | Listed contract under a declared exchange payload; OTC tenor and settlement under NEW typed extension; no cross-pack listed inference. |

#### IN-13 Interest-rate markets and derivatives

| IDs | Answers |
|---|---|
| Q01 / Q02 | Listed IR contracts, bilateral instruments, benchmark-linked agreements and other products kept as four object boundaries. |
| Q03 / Q04 | Source deal and confirmation references, ISIN for listed, benchmark id as separate object, LEI for parties. |
| Q05 / Q06 | Four population models (§5, IN-13); no forced single model; corrections append revisions. |
| Q07 / Q08 | Half-open reset and terms intervals; fixing publication apart from confirmation and `recorded_at_us`. |
| Q09 / Q10 | Trade, confirm, fix, reset, pay, compress, novate, terminate; benchmark reference edge, not identity merge. |
| Q11 / Q12 | Fixed and floating legs, spread, notional, day count and frequency with exact currency and basis-point measures. |
| Q13 / Q14 | Declared fixing and payment calendar; listed contract/listing denominators, others per-scope only. |
| Q15 / Q16 | `ReferenceData` for curve and benchmark identity; rights `UNKNOWN`. |
| Q17 / Q18 | No retention grant; corrected fixings append revisions. |
| Q19 / Q20 | NEW typed extension for OIS and resets; benchmark identity is reused only from IN-14 in a scoped pack. |

#### IN-14 Indices and benchmarks

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Index` reference object, `Source`, `Capability`, administrator `LegalEntity`; index is not a security. |
| Q03 / Q04 | Administrator index id, index-family id, source symbol; optionally ISIN for a linked product. |
| Q05 / Q06 | Officially enumerable identities with derived membership; restatements append revisions. |
| Q07 / Q08 | Half-open membership and method intervals; announcement time apart from `recorded_at_us`. |
| Q09 / Q10 | Launch, rebalance, add or remove constituent, method change, discontinue; `constituent_of` edges. |
| Q11 / Q12 | `IndexTerms` count and rebalance frequency; weights as exact ratios, levels as observations. |
| Q13 / Q14 | No venue calendar; index identities and membership intervals, counts `UNKNOWN`. |
| Q15 / Q16 | `ReferenceData` for identity and membership; rights `UNKNOWN`. |
| Q17 / Q18 | No retention or series replay grant; restated membership appends a revision. |
| Q19 / Q20 | `IndexTerms` payload; membership edges reused by packs only with an asserted jurisdiction reference. |

#### IN-15 OTC and privately negotiated instruments

| IDs | Answers |
|---|---|
| Q01 / Q02 | `FinancialInstrument`, `ContractFamily`, `ContractInstance`, counterparty `LegalEntity`, `Source`. |
| Q03 / Q04 | Source deal and confirmation references with named authority and scope; LEI for parties. |
| Q05 / Q06 | OTC-private with no single bounding source; per-family denominators only; amendments append revisions. |
| Q07 / Q08 | Half-open terms; fixing and settlement instants under declared calendars; confirmation apart from `recorded_at_us`. |
| Q09 / Q10 | Negotiate, confirm, amend, fix, settle, exercise, unwind, terminate; underlying and source edges. |
| Q11 / Q12 | Typed payoff, notional, tenor and settlement with exact measures; no universal unit. |
| Q13 / Q14 | Declared calendar per family; `UNMEASURABLE` at cohort level, no I6 roll-up. |
| Q15 / Q16 | `ReferenceData` for specs; rights `UNKNOWN` per family. |
| Q17 / Q18 | No retention grant; amendments append revisions with supersession. |
| Q19 / Q20 | Named typed family only, no generic `Other`; reuse requires a versioned contract in the pack. |

#### IN-16 Unlisted and private securities

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Security`, `FinancialInstrument`, issuer `LegalEntity`; no exchange status assumed. |
| Q03 / Q04 | ISIN where assigned, registry and certificate numbers as source-scoped assertions, issuer LEI. |
| Q05 / Q06 | OTC-private bounded only by a declared registry scope; identifier reuse creates separate intervals. |
| Q07 / Q08 | Half-open identity and terms; filing time apart from `recorded_at_us`. |
| Q09 / Q10 | Incorporate, allot, transfer, issue, buyback, cancel, dissolve; issuer and holder-record edges. |
| Q11 / Q12 | Share class, face value, voting and transfer restrictions with exact currency amounts. |
| Q13 / Q14 | Declared corporate-register date rule; `UNMEASURABLE` without a bounded source. |
| Q15 / Q16 | `ReferenceData` only; rights `UNKNOWN`. |
| Q17 / Q18 | No retention grant; corrections append revisions. |
| Q19 / Q20 | NEW typed extension for private families; no identity reuse from an ISIN text across packs. |

#### IN-17 IFSC products and facilities

| IDs | Answers |
|---|---|
| Q01 / Q02 | `Jurisdiction`, `Authority`, `MarketOperator`, `Venue`, `Segment`, `MarketProduct` plus traded product classes. |
| Q03 / Q04 | ISIN, LEI, MIC as global schemes; IFSC venue and domestic codes scoped with jurisdiction on each assertion. |
| Q05 / Q06 | Authority-bounded in a distinct jurisdiction-scoped partition; rule changes append revisions. |
| Q07 / Q08 | Half-open jurisdiction, authority, venue, segment and product intervals; regulatory publication apart from `recorded_at_us`. |
| Q09 / Q10 | Admit, list, trade, settle, expire, withdraw; jurisdiction-checked and bitemporal edges only. |
| Q11 / Q12 | Product terms from the typed payload; INR and offshore currencies distinct with no implied convertibility. |
| Q13 / Q14 | IFSC venue calendar under its asserted rule; per-product denominators, no mainland-plus-IFSC roll-up. |
| Q15 / Q16 | `ReferenceData` for jurisdiction, venue and product; rights `UNKNOWN`. |
| Q17 / Q18 | No retention grant; rule change appends a revision and preserves the prior interval. |
| Q19 / Q20 | IFSC product family under its own versioned payload; no automatic mainland family reuse. |

#### IN-18 Corporate actions and issuer information

| IDs | Answers |
|---|---|
| Q01 / Q02 | `CorporateAction` event, `LegalEntity`, `Security`, `Source`; platform-assigned action identity. |
| Q03 / Q04 | Issuer LEI, security ISIN, venue symbol as assertions; action identity never read from announcement text. |
| Q05 / Q06 | Authority-bounded on filings and admitting venue; corrections are new revisions, not rewrites. |
| Q07 / Q08 | Half-open action intervals; announcement and publication times apart from `recorded_at_us`. |
| Q09 / Q10 | Announce, ex, record, effective, payment, correct, invalidate; affected-instrument and successor edges. |
| Q11 / Q12 | Ratio, amount per unit, currency, tax basis and dates as exact measures. |
| Q13 / Q14 | Declared venue calendar rule; corporate action per instrument and period, counts `UNKNOWN`. |
| Q15 / Q16 | `CorporateActions` with lineage; rights `UNKNOWN`. |
| Q17 / Q18 | No retention or redistribution grant; earlier revision stays addressable. |
| Q19 / Q20 | Named action-type payload; successor instrument is a separate object in any pack. |

#### IN-19 Financial statements, ratings and credit events

| IDs | Answers |
|---|---|
| Q01 / Q02 | Three independent object contracts (§5, IN-19): statement, rating, credit event; each platform-assigned. |
| Q03 / Q04 | Issuer LEI, rated-instrument ISIN, source document and publisher reference; authority on each assertion. |
| Q05 / Q06 | Statement authority-bounded, rating provider-bounded, event filing- or scope-bounded; each appends revisions. |
| Q07 / Q08 | Half-open reported period, rating and event intervals; publication apart from `recorded_at_us` per object. |
| Q09 / Q10 | Filing, restatement; rating initiation, action, watch; event occurrence, verification, resolution; distinct source edges. |
| Q11 / Q12 | Statement figures and rating scales as exact measures with declared accounting or rating standard. |
| Q13 / Q14 | Reporting facility, not trading venue; per-issuer or per-instrument observation denominator per object contract. |
| Q15 / Q16 | `Fundamentals` and ratings identity where admitted; rights `UNKNOWN` for each object contract. |
| Q17 / Q18 | No retention grant; restatement, rating correction or event correction appends a revision. |
| Q19 / Q20 | Three typed extension payloads; a rating is never a statement and an event is never an issuer observation in another pack. |

#### IN-20 Economic and commodity reference information

| IDs | Answers |
|---|---|
| Q01 / Q02 | Three object contracts (§5, IN-20): published observation, commodity reference object, derived indicator. |
| Q03 / Q04 | Series code, release id, specification and assessment codes; named publishing authority on each. |
| Q05 / Q06 | (a) authority-bounded, (b) authority- or provider-bounded, (c) Derived; revised vintages append revisions. |
| Q07 / Q08 | Reference and observation periods apart from publication; release and correction times apart from `recorded_at_us`. |
| Q09 / Q10 | Release, publication, revision, discontinuation; specification supersession; transformation run and correction; `wasDerivedFrom` for (c) only. |
| Q11 / Q12 | Exact measures with declared unit, scale, timezone, methodology, grade and location. |
| Q13 / Q14 | No venue calendar; denominators per subdomain, no roll-up and no observation counted as derived output. |
| Q15 / Q16 | `EconomicRelease` and `ReferenceData` where admitted; rights `UNKNOWN`. |
| Q17 / Q18 | No retention or replay grant; a revised vintage appends a revision and preserves the prior value. |
| Q19 / Q20 | Observation, specification and transformation payloads under separate typed contracts; no cross-subdomain reuse. |

## 7. Migration sequence: I1–I6 to the twenty cohorts

I1–I6 remains the single migration register from the coverage register. It is reused here as an
ordering of qualification work; it is not a second instrument hierarchy and it is not a coverage
state. A cohort may be entered only when its own versioned contract, typed payload, unit
declarations, rights scope and per-dimension denominator are admitted.

| Phase | Cohorts entered in order | Gate condition | Explicit non-entry |
|---|---|---|---|
| I1 | IN-01, IN-02, IN-03, then IN-18 for action lineage; IN-04 follows under a versioned extension | Canonical IDs, effective-dated venue identifiers, listing terms, action revisions, calendar/session coverage and raw digest in one admitted release | No other family in the cash surface; no `Future`, `Option`, `Bond` or `CurrencyPair` variant presented under v2 |
| I2 | IN-14 | Index identities and effective-dated `constituent_of` edges in an admitted release; index family distinct from any tracked instrument | Index level or return series is a separate observation claim; no index derivative counted here |
| I3 | IN-10 | New versioned derivative contract with family, expiry, strike, option kind, underlying canonical ID and effective terms | No widening of the cash-only v2 surface; no enum variant counted as a contract |
| I4 | IN-11 | New MCX venue/operator assertion, commodity product identities, contract specifications, units and grades in a versioned release | No closed-enum venue reuse; an assessment is not a contract |
| I5 | IN-05, IN-06, IN-07, then IN-08, IN-09, IN-12, IN-13 under typed extensions | Entity/issuer and currency identities, debt specifications and per-family terms in versioned releases; IN-12 enters by listed and OTC subpopulation, IN-13 by its four separated subpopulations | No repo treated as debt security; no OTC population inferred from a listed subset; no single population model forced across IN-12 or IN-13 |
| I6 | IN-15, IN-16, IN-17, IN-19, IN-20, each admitted case by case | Per-domain versioned contract, typed payload, declared units, rights scope, as-of instant and denominator; IN-19 by its three object contracts and IN-20 by its three subdomains | I6 is never a permanent catch-all; no domain enters by roll-up from another cohort or phase; no published observation counted as a derived object |

Retirement of I6 as a phase occurs when every remaining domain has its own admitted typed
contract and denominator. Until then I6 is a list of pending qualifications, not a claim that an
unclassified population exists or is complete.

## 8. Coverage-measurement discipline

The nine dimensions and their denominators remain distinct:

| Dimension | Denominator source | Not established by |
|---|---|---|
| Instrument | Declared point-in-time instrument universe | Listings, contracts, actions or observations |
| Listing / identity | Declared listing and identifier assertions | A symbol, token or ISIN text |
| Contract | Declared derivative or commodity contract set | An in-memory enum variant |
| Corporate action | Declared action universe per instrument and period | An embedded snapshot or local ledger slot |
| Session / time | Declared venue calendar and session intervals | A sparse holiday date list |
| Trade event | Declared trades in scope | Quote, depth or MBO evidence |
| Quote / depth | Declared BBO or MBP levels and snapshots | Trade or order-lifecycle evidence |
| MBO | Declared order lifecycle events | A protocol name or a level count |
| Sequence continuity | Declared sequence ranges and gap policy | Completeness of any other dimension |

No aggregate coverage count is admitted. A dimension that does not apply to a cohort is recorded
as *not applicable* for that cohort; that is neither a pass nor a zero and does not enter another
dimension's denominator. Physical line counts are not logical record counts and never serve as a
denominator.

## 9. Not approved (boundaries and non-claims)

- This is a documentation and owner-decision package. No provider is contacted and no provider,
  exchange, venue, facility, feed or dataset is qualified by naming it here.
- No collection, download, scrape, market-data API call, adapter execution or source retrieval is
  authorised. No code, schema, field, enum, contract version, wire format, transport, storage or
  release artifact is created or widened.
- No right is granted. Rights remain `UNKNOWN`; public availability, a connection, a token or a
  checksum grants nothing. Dataset acceptance stays `BLOCKED` and no admission receipt exists.
- No experiment is registered and no live execution is enabled. Budget remains INR 0; collection
  stays `DISABLED`; experiments stay `BLOCKED`; live execution stays `DISABLED`; D11 remains strict.
- No synthetic market observation, price bar, order book, trade, universe, reference history or
  strategy return is created or used as evidence. No capability claim is a permission claim.
- No second identity system is introduced. All identities remain opaque and platform-assigned
  under the global core; external identifiers remain provenance-bearing assertions.
- **No reference ingestion.** No reference-data ingestion, source qualification, rights approval,
  admission receipt or dataset acceptance is performed or implied. Reference observations in this
  catalogue are declarations of future object contracts, not ingested values.
- **W2.3 remains gated.** W2.3 India implementation stays gated on separate owner ratification of
  the design and of every country-pack version. These documentation amendments do not open it.
- **Design amendments are not authorization.** The subpopulation boundaries, the twenty-question
  set and the three-object contracts record design intent only; they grant no right and admit no
  source, contract, pack version or coverage count.
- This document does not ratify the country pack, a contract version or a coverage number. Those
  remain separate owner decisions.

## 10. Connections

- `engineering/decisions/IN-COUNTRY-001-india-country-pack-design.md` — proposed versioned India
  extension of the global core, with the component evidence model, mainland/IFSC partition rules,
  cohort crosswalk and population-completeness policy.
- `engineering/decisions/WS-SCOPE-2026-11-24-001-global-reference-core-india-first.md` — ratified
  scope, ownership, model rules and execution order.
- `engineering/coverage/india-coverage-register.md` — I1–I6 migration sequence and the nine
  coverage dimensions reused without modification.
- `engineering/architecture/india-domain-ownership-crosswalk.md` — verified findings F1–F12 and
  the ownership rule that Fieldbook owns authority and Nirnay consumes projections.
- `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` — C0 scope containment, bitemporal
  semantics, provenance and denominator rules.
- `README.md` — document map; `CURRENT-STATE.json` — rights, budget and acceptance state;
  `REVIEW-LOG.md` — owner-decision record.
