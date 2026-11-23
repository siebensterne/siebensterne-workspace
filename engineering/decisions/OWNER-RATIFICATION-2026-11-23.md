# Owner ratification — 2026-11-23

Status: **Ratified by owner instruction**. This record approves architecture and contract
semantics only. It is not a data licence, does not authorise provider contact, and does not
accept a dataset.

## Decision A — Ownership

Ratified:

- **Fieldbook** owns provider acquisition, source protocol decoding, raw observation
  storage, source normalization, canonical instrument identity, effective-dated listing and
  reference data, corporate-action source facts and revisions, trading calendars, dataset
  publication and the raw-data lifecycle.
- **Nirnay** owns accepted research datasets, experiment registry, backtesting, simulation,
  portfolio accounting, risk, OMS, paper trading and eventual execution under separate
  authorisation.
- Nirnay does not operate a competing raw collector, source decoder or reference-data
  authority. Fieldbook does not become a quantitative trading application.

### Responsible roles

One person may hold several roles at this stage; that is stated explicitly rather than
inventing organisational separation.

| Role | Responsibility | Holder |
|---|---|---|
| Programme owner | architecture, scope and milestone decisions | Kartik Jangid |
| Data-rights steward | permission evidence and source qualification | Kartik Jangid |
| Fieldbook producer owner | acquisition, raw archive and release | Kartik Jangid |
| NDC contract owner | contract publication and versioning | Kartik Jangid |
| Nirnay consumer owner | admission, research and trading | Kartik Jangid |
| Signing-key custodian | publication signing key and revocation | Kartik Jangid |

Named-role ratification is recorded here. A repository name is not an accountable owner.

## Decision B — NDC v1/v2 semantics

Ratified semantic contract:

- Fieldbook is the NDC producer and publisher. Nirnay is the verifier and consumer.
- Release manifest and event envelope are distinct; dataset-wide facts appear once in the
  manifest, not per event.
- Six separable concepts are binding: capability, permission, operation, data object,
  purpose and evidence. No concept is inferred from another.
- Producer activity records only operations actually performed. Permission grants are a
  separate structure. Consumer uses are declared by Nirnay and evaluated against grants;
  they are never mapped into the producer's operation enum.
- Purpose is `proprietary_own_account_trading_research`, preserved verbatim; it is not
  academic, non-commercial or generic internal analysis.
- Signature verification uses RFC 8785 JCS canonical manifest bytes with a detached Ed25519
  sidecar. It proves publisher-key control and manifest integrity, not source authenticity,
  completeness or data rights.
- Coverage has per-dimension denominators; one successful dimension never implies another.
- Nirnay's research-dataset manifest is a separate object that references the exact
  Fieldbook release identity and digest.

### Approved documents and digests

| Document | SHA-256 |
|---|---|
| C0 semantic model | (workspace doc, see `ENGINEERING-DOC-DIGESTS.json`) |
| Fieldbook NDC v2 producer requirements | `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c` |
| Nirnay NDC v2 consumer requirements | `22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957` |

The v1 documents and W1.1 digests remain historical and unchanged. This approval does not
grant source rights or authorise provider activity.

## Independent decisions still open

| Decision | State |
|---|---|
| Test-data policy | strict prohibition retained; versioned amendment requires separate owner decision |
| Source rights | 21 `UNKNOWN` |
| Dataset acceptance | `BLOCKED` |
| Experiment registration | blocked |
| Live execution | disabled |

## Effect

Nirnay ownership ADR becomes **Accepted**. NDC v2 semantics become **Approved**; NDC v1
remains historical. `ADR-REGISTRY.md` and `NDC-REGISTRY.md` are updated accordingly. No
code, data, collector, adapter, experiment or broker action is authorised by this record.
