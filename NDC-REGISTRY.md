# NDC registry — version and ownership

The Nirnay Data Contract is a set of semantic requirements, not a frozen schema. It has
one producer and one consumer. No transport, queue, shared crate or database is chosen.

## Active contract

| Field | Value |
|---|---|
| Active contract version | **`v2`** (approved semantic requirements) |
| Producer | Fieldbook |
| Producer document | `engineering/ndc-producer-requirements-v2-proposed.md` in Fieldbook |
| Producer document digest (approved) | `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c` |
| Consumer | Nirnay |
| Consumer document | `engineering/ndc-consumer-requirements-v2-proposed.md` in Nirnay |
| Consumer document digest (approved) | `22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957` |
| C0 semantic model | `engineering/design/NDC-SEMANTIC-MODEL-V2-PROPOSED.md` in Workspace |
| C0 semantic model digest (approved) | `3dace660c362e683790ba7e56a785ded8af836abda36f6eab06ed284de49eed2` |
| Ownership decision | `NR-ARCH-ADR-0001` — **Accepted 2026-11-23** by owner ratification |
| Ratification reference | `engineering/decisions/OWNER-RATIFICATION-2026-11-23.md` — Decision A (ownership) and Decision B (NDC v1/v2 semantics); roles named there |
| Contract status | NDC v2 **Approved 2026-11-23**; NDC v1 **historical**, superseded by v2 |
| NDC v1 producer document (historical) | `engineering/ndc-producer-requirements-v1.md`, digest `592a1c9043ed2756a3f9d938dbe6e2ee80007166b440cf6f2709d5de11424c33` |
| NDC v1 consumer document (historical) | `engineering/ndc-consumer-requirements-v1.md`, digest `25315c57de753bde33b0f8044e70646f24b19c8af7ca9fdbdd2e53682a53b8bd` |
| Operation sets | producer (8) / consumer (5), distinct; extra grants imply nothing |
| Trust model | detached Ed25519 via Nirnay `dataset-signature.v1.schema.json`; integrity is not authenticity |
| Rights state | all provider rights `UNKNOWN` |
| Release state | no accepted dataset release |

The approved bytes were not modified to make this table consistent. The v1 documents and
the v2 requirement documents keep their original SHA-256 values; only this registry and the
other workspace governance records changed.

## What approval does and does not cover

Approval of NDC v2 semantics is one decision. It does not imply that every implementation
component exists. These layers are recorded separately:

| Layer | Status | Evidence / note |
|---|---|---|
| Approved semantic requirements | **Approved 2026-11-23** | v2 producer requirements, v2 consumer requirements and the C0 model above; six separable concepts (capability, permission, operation, data object, purpose, evidence) |
| Approved implementation-conformance rules | **Approved as requirements** under W1.2 C1/C2 paired PRs #45/#46/#130; enforcement still to be proven | `CURRENT-STATE.json` `reviewed_commit_ids`; W2.1-B/C exists to close runtime gaps, not to reopen the approved semantics |
| JSON schemas | Present as versioned repository artifacts (for example `schemas/research/dataset-manifest.v1.schema.json`), not part of the approved NDC v2 requirement bytes | A schema that compiles is not a verified release |
| Canonical serialization rules | **Ratified as semantics**: RFC 8785 JCS canonical manifest bytes with a detached Ed25519 sidecar; proves publisher-key control and manifest integrity only | Decision B of the ratification record |
| Final NDC serialization schema | **Not yet implemented** | No approved final schema artifact or digest is registered here |
| Runtime implementation | Exists in both repositories; **full semantic enforcement not yet demonstrated** | W2.1 Fieldbook authorization and Nirnay admission conformance work is outstanding |
| Consumer verification capability | Partial; **full release verifier not implemented** | Nirnay admission code and the separate Proposed consumer-use document below are not an approved verifier |

## Separate consumer-use proposal (not approved)

| Document | Digest | Status |
|---|---|---|
| Nirnay `engineering/ndc-consumer-use-v2-proposed.md` | `4b9d1fe7190de08151989fc8895f42e1daa737021e8dae019ddc3325f9603a2c` | **Proposed** — no separate approval record |

The 2026-11-23 ratification explicitly names the C0 model and the v2 producer/consumer
requirements. It does not ratify every separate consumer-use implementation proposal. This
document's semantics are not silently included in the ratified NDC v2 set, and its status is
not changed by approval of the requirement documents.

## Structural rule

Two levels are kept distinct. Dataset-wide facts appear once in the release manifest;
per-observation facts appear in the event envelope.

**Release manifest:** dataset identity and source scope, coverage and completeness,
rights and retention, schema versions, release digest, publication identity.

**Event envelope:** source and instrument identity, event type and typed payload,
source and receive times with clock domain, sequence and continuity, raw digest and
lineage reference, revision and as-of information.

## Compatibility rule

A consumer must reject a release when any required manifest field is absent, denied,
expired, or inconsistent with the event envelope. A producer must not publish a release
that fails its own validator. Version changes follow the semantic rules in each
repository's NDC document. Compatibility is decided by those rules, not by a transport.

## Change procedure

1. Open paired PRs, one per repository, referring to the same NDC version.
2. Keep producer and consumer validators in lockstep; neither may drift ahead.
3. Run `make check-static` in both repositories and `make consistency` here.
4. Obtain independent review for each PR and record CI runs.
5. Register the resulting commits in `REVIEW-LOG.md`.
6. Change an approved digest only through a separately approved revision; never edit the
   approved bytes silently.
