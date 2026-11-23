# NDC registry — version and ownership

The Nirnay Data Contract is a set of semantic requirements, not a frozen schema. It has
one producer and one consumer. No transport, queue, shared crate or database is chosen.

| Field | Value |
|---|---|
| Contract version | `v1` (semantic requirements) |
| Producer | Fieldbook |
| Producer document | `engineering/ndc-producer-requirements-v1.md` in Fieldbook |
| Consumer | Nirnay |
| Consumer document | `engineering/ndc-consumer-requirements-v1.md` in Nirnay |
| Ownership decision | `NR-ARCH-ADR-0001` (Proposed) |
| Producer document digest | `592a1c9043ed2756a3f9d938dbe6e2ee80007166b440cf6f2709d5de11424c33` |
| Consumer document digest | `25315c57de753bde33b0f8044e70646f24b19c8af7ca9fdbdd2e53682a53b8bd` |
| Operation sets | producer (8) / consumer (5), distinct; extra grants imply nothing |
| Trust model | detached Ed25519 via Nirnay dataset-signature.v1.schema.json; integrity is not authenticity |
| NDC v2 producer digest | `215a5b553c6cd51aca8c55d1150eef7ceb7bb6c4d3ea9540d09eb990f415f77c` |
| NDC v2 consumer digest | `22eaef7de012e4f144299bc7fe82a701670531799e7e340e60a2908786a5a957` |
| NDC v2 status | **Approved 2026-11-23** by owner ratification; NDC v1 remains historical |
| Rights state | all provider rights `UNKNOWN` |
| Release state | no accepted dataset release |

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
