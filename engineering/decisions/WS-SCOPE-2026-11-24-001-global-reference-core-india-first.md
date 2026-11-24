# WS-SCOPE-2026-11-24-001 — Global Reference Core, India First

Status: RATIFIED by owner direction, 2026-11-24.
Authority: owner. Supersedes the 2026-11-23 instruction not to begin India
scoping work. Does not alter any W2.1 rights, budget, collection, dataset,
experiment or execution restriction.

## Decision

Build a jurisdiction-aware global financial reference and data platform.
India is the first national implementation, not the centre of the model.

The platform represents three distinct categories without collapsing them:
securities and financial instruments; reference objects such as issuers,
indices, venues and currencies; and financial events and observations.
A listing is not an instrument, a symbol is not an identity, and a derivative
product family is not an individual contract instance.

India scope covers all declared instrument and information domains, including
equity, depositary receipts, funds, trusts, government and corporate debt,
money markets, securities financing, derivatives, commodities, foreign exchange,
indices, corporate information, market information, unlisted instruments and
IFSC products. NSE and BSE alone do not define the Indian universe.

## Ownership

| Repository | Owns |
|---|---|
| Fieldbook | authoritative identity, reference assertions, revisions, publication |
| Nirnay | consumes verified reference data; no competing authoritative identities |
| Workspace | contracts, registries, governance, evidence |

Nirnay does not reconstruct authoritative reference history. Workspace is not
a runtime dependency of processing.

## Model rules

Internal identities are opaque and platform-assigned. External identifiers are
provenance-bearing assertions, never primary keys. Every authoritative
assertion carries separate valid time and knowledge time. Historical values
are revised, never overwritten. Identity resolution returns Resolved,
Ambiguous, Unresolved or Conflict and never selects a first match. Country
packs extend one global core through versioned typed contracts; a jurisdiction
is not a fixed enum of venues or products. Every coverage claim declares its
denominator and source; absent denominators yield UNKNOWN, and an empty scope
grants nothing.

## Execution order

| Order | Work package | Owner |
|---|---|---|
| 1 | FB-REF-001 canonical object and identity core | Fieldbook |
| 2 | bitemporal reference assertions | Fieldbook |
| 3 | instrument and contract domain families | Fieldbook |
| 4 | jurisdiction, venue and product registry | Fieldbook |
| 5 | capability and coverage registry | Fieldbook |
| 6 | final NDC v2 serialization ratification | Workspace |
| 7 | NDC producer serializer | Fieldbook |
| 8 | independent verifier and read projection | Nirnay |
| 9 | India country pack | Fieldbook |
| 10 | source qualification after rights approval | Fieldbook |
| 11 | accepted reference datasets for research | Nirnay |

India design ratification and provider rights qualification remain separate
owner decisions. India data implementation stays gated until that ratification.
This decision authorizes generic core implementation only.

## Non-goals and freeze

No provider contact, collection, rights grant, dataset acceptance, market
experiment, synthetic market-shaped test, live execution or India feed. No
adapter, journal rewrite or universal engine. Rights remain UNKNOWN, dataset
acceptance BLOCKED, budget INR 0, collection DISABLED, experiments BLOCKED and
live execution DISABLED. D11 remains strict.
