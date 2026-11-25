# NDC v2 semantic model — Proposed

> **CURRENT STATUS: APPROVED BYTES UNDER A HISTORICAL FILENAME.** The "Proposed" suffix is retained; the bytes are ratified.

Status: **Proposed**. This document settles meaning before implementation. It is not an
accepted contract, a data licence, or authorisation to collect. It supersedes the
operation mappings in NDC v1 documents without editing their historical digests.

## External references

| Source | Use | Access |
|---|---|---|
| RFC 8785, JSON Canonicalization Scheme | Canonical manifest bytes for signing | 2026-11-23, https://www.rfc-editor.org/rfc/rfc8785.txt |
| W3C PROV-O Recommendation 2013-04-30 | Provenance vocabulary: Entity, Activity, Agent, derivation, revision, invalidation | 2026-11-23, https://www.w3.org/TR/prov-o/ |
| Fieldbook 14-value Operation enum (W1.1-C) | Producer technical actions | source at `340f829` |
| Nirnay `DataOperation` and `CONSUMER_OPERATIONS` | Consumer operations | source at `e975be9` |

Web search was unavailable (HTTP 402); both standards were fetched directly from their
publishers. No market-data provider was contacted.

## 1. Six separable concepts

No concept may be inferred from another.

| Concept | Question | Example |
|---|---|---|
| Capability | What can a source technically provide? | five-level depth, tick-by-tick |
| Permission | What does the written agreement allow? | non-display historical storage for 365 days |
| Operation | What does the software perform? | retrieve, store, replay |
| Data object | What does the operation act upon? | raw frame, release, research copy |
| Purpose | Why is it performed? | proprietary own-account trading research |
| Evidence | What proves the action or decision? | audit event, reviewed attestation, signature |

A capability is not a permission. A permission is not an operation. An operation on a
raw frame is not the same operation on a research copy. A signature is not a licence.

## 2. Authorization identity

An authorization is evaluated against a full request, never against a command name.

```
Authorization
├── actor                  Fieldbook producer / Nirnay consumer / rights authority / signer
├── action                 technical action from the canonical action vocabulary
├── data_object            object class the action acts upon
├── source_scope           provider, source product, venue, segment, dataset
├── subject_scope          instruments, fields, modality, universe version
├── purpose                exact reviewed purpose wording
├── usage_mode             display / non_display / derived_only
├── recipient              named recipient class and named recipient
├── licensee               named individual or legal entity from the written permission
├── territory              contractual territory
├── data_time_scope        permitted source-observation interval
├── operational_time_scope permission effective_from / effective_until
├── retention              typed retention policy with maximum duration and purge rule
├── delivery_method        API / multicast / file / specified method
├── evidence               document reference, clause, digest, review authority, review date
└── decision               permit / deny / contract_required / revoked, with reason
```

### 2.1 Technical action vocabulary

Canonical actions, each with an object class:

| Action | Typical objects |
|---|---|
| `source_contact` | endpoint, no data object |
| `reference_data_retrieval` | source reference records |
| `historical_data_retrieval` | historical observations |
| `real_time_capture` | source stream observations |
| `store` | raw source record, release, research copy, derived artifact |
| `normalize` | canonical observations |
| `backup` | raw archive |
| `replay` | raw archive, research copy |
| `analyze` | admitted research dataset |
| `create_derived` | derived research artifact |
| `retain` | raw archive, release, derived artifact |
| `delete` | any retained object |
| `display` | display-form data |
| `redistribute` | external report or dataset |

`source_contact` is an egress prerequisite, not a data-producing operation. It does not
belong in `producer_activity` unless it itself produced retained data.

The canonical action names are semantic labels. They are mapped explicitly to the
authoritative enums; neither enum is renamed:

| Canonical action | Fieldbook `Operation` (14 values) |
|---|---|
| `source_contact` | `SourceContact` |
| `reference_data_retrieval` | `ReferenceDataRetrieval` |
| `historical_data_retrieval` | `HistoricalDataRetrieval` |
| `real_time_capture` | `RealTimeCapture` |
| `store` (raw object) | `RawStorage` |
| `normalize` | `Normalization` |
| `backup` | `Backup` |
| `replay` (producer) | `Replay` |
| `retain` | `Retention` |
| `delete` | `Deletion` |
| `analyze` | `InternalAnalytics` |
| `create_derived` | `DerivedDataCreation` |
| `display` | `Display` |
| `redistribute` | `ExternalRedistribution` |

The complete Fieldbook enum is the authority for producer actions. Canonical labels are
used in this document only to keep actor/object semantics explicit; implementations MUST
store the enum value, not the label.

### 2.2 Purpose

The declared purpose is `proprietary_own_account_trading_research`. It must be preserved
verbatim from the reviewed permission. It is not `academic_research`,
`non_commercial_research`, `internal_analysis` or `historical_archive`. Those values may
be present in an agreement but must not replace the declared purpose.

### 2.3 Scope containment

A request is covered only when every applicable dimension is contained by the grant:

- exact provider, source product, venue, segment, dataset, purpose, recipient, licensee,
  territory, delivery method and usage mode;
- requested instrument, field and modality sets contained in the permitted sets;
- `NotApplicable`, `Named` and `All` are distinct states; an empty `Named` set is not
  `All`; a runtime request must not use `All` as a default;
- time containment uses mathematical infinity: a bounded grant cannot cover an unbounded
  request; `(None, None)` as a request is unbounded and requires an unbounded grant;
- data time and operational time are independent intervals; both require `from <= to`;
- retention is a typed policy with an explicit maximum duration and purge rule; a
  narrower request may be permitted; an indefinite request cannot exceed a bounded grant.

Ambiguous or conflicting grants deny.

### 2.4 Egress intent

The caller supplies the actual request. The gate must not reconstruct it from the proof.

```
EgressIntent
├── provider_id, source_product_id, venue_id, segment_id, dataset_id
├── operation, purpose, usage_mode, licensee, recipient, territory
├── instruments, fields, modalities
├── data_time_window
├── endpoint_identity
└── retention_request
```

Authorization is checked before DNS, TCP, TLS and protocol upgrade. HTTP redirects to a
different authority are reauthorized. WebSocket subscription widening reauthorizes.
No generic defaults such as territory `US`, licensee `fieldbook-operator`, product
`market-data-feed` or segment `history` may produce a permission.

### 2.5 Revocation and active sessions

Revocation is not instantaneous unless an enforcement channel exists. The model uses:

- rights registry revision and immutable grant snapshot identity;
- short-lived authorization lease with a declared maximum duration;
- active session identifier and reauthorization checkpoints;
- cancellation on lease expiry or policy revision invalidation;
- fail-closed behaviour when the authority cannot be refreshed;
- audit events for grant, renewal, expiry, revocation and cancellation.

The maximum revocation propagation time equals the lease duration unless a faster
notification mechanism is implemented and tested. No instantaneous claim is permitted
without that mechanism.

## 3. Producer activity

`producer_activity.performed_operations` describes only actions Fieldbook actually
performed, with object and evidence:

| Action | Object |
|---|---|
| reference_data_retrieval | source reference records |
| historical_data_retrieval | historical observations |
| real_time_capture | source stream observations |
| store | exact source bytes |
| normalize | canonical observations |
| backup | raw archive |
| replay | raw archive |
| retain | raw archive and published release |

`operation_evidence` links each performed action to an audit record or durable receipt.

## 4. Consumer uses

Nirnay submits an admission request rather than inheriting producer operations:

```
AdmissionRequest
├── release_identity
├── actor
├── use_profile
├── requested_actions / requested_objects
├── purpose, licensee, recipient
├── requested_scope
├── requested_retention
└── as_of
```

Versioned use profiles:

| Profile | Required consumer actions |
|---|---|
| `reference_lookup` | verify release, read manifest, read event payloads for reference fields |
| `historical_research` | verify, read, store research copy, replay, analyze |
| `intraday_replay_research` | verify, read, store, replay, analyze with intraday capability |
| `derived_research_dataset` | verify, read, store, analyze, create derived, retain derived |
| `portfolio_simulation` | verify, read, replay, analyze within an admitted dataset |

A job must declare its profile and cannot omit a required action. An extra grant never
authorises an unrequested action. An unpermitted requested action blocks admission.

Nirnay's existing `CONSUMER_OPERATIONS` (`read_release`,
`store_permitted_research_copy`, `replay`, `internal_analytics`,
`retain_permitted_derived_data`) remains the authoritative consumer enumeration. The
profile table above uses descriptive verb phrases; its exact mapping is:

| Descriptive phrase | Nirnay `CONSUMER_OPERATIONS` value |
|---|---|
| verify release / read manifest | `read_release` |
| read event payloads | covered by `read_release`; payload access is a separate stage in §4.1, not a new right |
| store research copy | `store_permitted_research_copy` |
| replay | `replay` |
| analyze | `internal_analytics` |
| create derived / retain derived | `retain_permitted_derived_data` for retention; creation requires an explicit grant and is not implied by retention |

Derived-data creation is a separate requested action; it must appear in the use request
and in a matching grant. No new enum value is invented by this document.

### 4.1 Release verification stages

1. Parse manifest and validate schema/contract version.
2. Verify canonical manifest bytes.
3. Verify detached signature with an out-of-band trusted key.
4. Verify publisher key validity and revocation.
5. Verify actual data and artifact digests.
6. Verify rights evidence and scope.
7. Verify coverage and denominators.
8. Verify producer activity and operation authorization.
9. Verify event envelopes.
10. Verify temporal and correction lineage.
11. Evaluate requested consumer use.
12. Issue an immutable admission receipt with a typed rejection code on any failure.

The current `dataset_admission.py` validates declarations only; it is not a complete
release verifier. It must not be described as one.

## 5. Three independent proofs

| Proof | Establishing | Not establishing |
|---|---|---|
| Publisher integrity | trusted signing key + unchanged signed bytes | source authenticity, coverage, rights |
| Source lineage | raw archive reference, digests, transformation record | truth of observations |
| Rights evidence | reviewed written agreement, exact scope and digest | permission for an unlisted action |

The publication key and rights-review authority are separate trust relationships.

### 5.1 Canonical bytes

Manifest signing uses a detached signature: the signature is a sidecar, not a property
inside the manifest. RFC 8785 JCS is applied to the manifest object itself; no property
removal is needed because no signature property exists in that object. JCS rules applied
here:

- I-JSON subset; no duplicate property names; Unicode strings preserved as-is;
- no whitespace between tokens; recursive property-name sorting by UTF-16 code units;
- array order preserved, so semantically unordered sets require a defined deterministic
  ordering before canonicalization;
- UTF-8 output;
- exact financial decimals and large integers are JSON strings, not IEEE 754 numbers;
- NaN/Infinity/lone surrogates terminate the operation;
- the detached signature sidecar is not part of the canonicalized bytes and never enters
  the manifest digest.

## 6. Coverage dimensions

One count cannot establish all coverage. Each dimension has its own universe and
denominator:

| Dimension | Denominator |
|---|---|
| Instrument coverage | declared point-in-time instrument universe |
| Listing / identity coverage | declared listing and identifier assertions |
| Contract coverage | declared derivative or commodity contract set |
| Corporate-action coverage | declared action universe per instrument and period |
| Session / time coverage | declared venue calendar and session intervals |
| Trade-event coverage | declared trades in scope |
| Quote / depth coverage | declared BBO or MBP levels and snapshots |
| MBO coverage | declared order lifecycle events |
| Sequence continuity | declared sequence ranges and gap policy |

Passing one dimension never implies another.

## 7. Derived research dataset

Identity chain:

```
Fieldbook NDC release (release_id, manifest digest, data digest)
  -> Nirnay admitted dataset (admission receipt id, use profile, as_of)
    -> Nirnay research dataset (research dataset id + digests)
      -> experiment (references research dataset and exact NDC release)
```

Nirnay stores a derived projection and never re-normalizes raw Fieldbook payloads or
maintains a competing raw archive. Changes to release or rights evidence require a new
admission decision.

## 8. Provenance

Provenance follows W3C PROV-O concepts: Entity (source record, release, research copy),
Activity (retrieval, normalization, publication, admission), Agent (producer, consumer,
rights authority, signer), with `wasDerivedFrom`, `wasRevisionOf`, `hadPrimarySource`,
`generatedAtTime`, `invalidatedAtTime` and qualified attribution. PROV semantics describe
lineage; they do not establish permission or truth.

## 9. Implementation order

1. C1 Fieldbook: scope containment, time windows, retention, explicit purpose, exact
   authorization identity.
2. C2 Fieldbook: EgressIntent and active authorization lifecycle.
3. C3 Nirnay: consumer use profiles and permission evaluation.
4. C4 paired documents: new proposed NDC revision with these semantics.
5. No final NDC JSON schema, shared crate, transport or storage choice before ratification.

## 10. Open owner decisions

Ownership ADR, NDC v1 semantics, test-fixture policy, source rights and dataset
acceptance remain open. This document does not ratify any of them. All source rights
remain `UNKNOWN`; no provider contact or data collection is authorised.
