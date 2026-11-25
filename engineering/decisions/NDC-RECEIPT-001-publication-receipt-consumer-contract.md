# NDC-RECEIPT-001 — Consumer-side publication receipt contract

<!-- SPDX-License-Identifier: Apache-2.0 -->

Date: 2026-11-25. Work package: WP-9 / NDC-RECEIPT-001. Status:
**PROPOSED / AWAITING OWNER RATIFICATION**. This record is a documentation-only
contract draft. It ratifies nothing, implements nothing and creates no receipt,
no signature, no key and no schema artifact. No production key is generated or
activated by this design phase.

## 1. Authority, source facts and scope

### 1.1 Governing documents

| Authority | Effect on this contract |
|---|---|
| `engineering/conformance/ndc-v2-evidence-audit-2026-11-24.md`, finding 10 and §6 | Publication-receipt consumer integration is a **separate gate**: read-only port, separate signed receipt and registry, no unapproved durability claim in the manifest. No state is promoted by this contract. |
| `engineering/decisions/WS-NDC-2026-11-24-002-ndc-v2-release-serialization-profile-1.md`, Decisions G, H, I | Publication is a durable local state machine; the trusted publisher key registry is out of band; producer and verifier are independent with no shared runtime crate. |
| `engineering/decisions/WS-NDC-2026-11-24-003-canonical-profile-1-wire-schema.md` §3, §4, §8.3, §13, §15 (DP-29), §16 | UTF-8 + RFC 8785 JCS + strict parsing; decimal-string instants; a receipt grants no right; the producer publication receipt and the consumer admission receipt stay separate; any wire form needs its own versioned schema entry; five capability states remain distinct and unclaimed. |
| `engineering/decisions/WS-DUR-001-publication-durability-failure-model.md` §1–§5, §7 (I-09, I-10, I-13) | Durability is a failure model with tiers D0–D4, profile-scoped booleans and no global durability Boolean. The local receipt is a local acknowledgement only; no consumer admission follows. |
| `engineering/conformance/ndc-v2-production-builder-cross-execution-2026-11-24.md` and `engineering/conformance/ndc-v2-evidence-manifest-2026-11-24.md` | The Fieldbook publication receipt `conformance-release-2.receipt.json` is written into the ledger beside the release. `receipt_written: false` in a Nirnay diagnostic means no Nirnay **admission** receipt, not that Fieldbook wrote no publication receipt. |
| `NDC-REGISTRY.md` | Records the active `v2` contract, approved digests and compatibility rules. This contract adds no approved byte and no ratified schema. |

### 1.2 Source facts read (read-only)

Source was read, not modified, at the two exact commits named by the owner.

- Fieldbook `cabf1be3c9df0f267601282ed739e2973afb2931` (merge of PR #73),
  `src/distribution/ndc_release.rs`:
  - `PublicationReceipt` (`ndc_release.rs:417-432`): `schema_version: u32`,
    `release_id`, `manifest_sha256`, `data_sha256`,
    `publication_operation_id`, `commit_position`, `result: PublicationState`,
    `supersedes_release_id: Option<String>`; `#[serde(deny_unknown_fields)]`
    and an RFC 8785 `ToJcs` mapping. `build_release` sets
    `schema_version = MANIFEST_SCHEMA_VERSION` (1) and
    `result = PublicationState::Available`.
  - `PublicationIntentV2` (`ndc_release.rs:589-620`): `schema_version` (2),
    `operation_id`, `release_id`, `manifest_sha256`, `sidecar_sha256`,
    `data_sha256`, `commit_position`, `staging_directory`, `final_directory`,
    `supersedes_release_id`, `expected_receipt: PublicationReceipt`,
    `expected_receipt_sha256`, `artifacts: Vec<IntentArtifact>`,
    `wire_profile`, `resource_profile`, `intent_sha256`; its `ToJcs` excludes
    the self-digest. `IntentArtifact` carries stored and uncompressed digests,
    `expected_receipt` and `receipt_sha256`. `ResourcePolicy` maxima are all
    caller-supplied; the module invents no unmeasured production limit.
  - `PublicationState` (`ndc_release.rs:270-342`) has eight immutable v1
    variants plus four v2 variants; `AVAILABLE` is shared. Journal schema
    version 2 (`JOURNAL_SCHEMA_VERSION = 2`) binds the five-record v2 stage
    order; legacy v1 records remain readable and are not rewritten.
  - The local receipt is written as a durable record in the ledger beside the
    release. It carries no key, no signature and no trust root.
- Nirnay `d3b66f52d500757701f37a21834fde39b89731f4` (merge of PR #144):
  - `crates/release-verifier/src/receipt.rs`: `AdmissionReceipt` has exactly
    one terminal result, `AdmissionResult::Admitted`. `ReceiptInput` binds
    `release_id`, `manifest_sha256`, `data_sha256`, `publisher_id`, `key_id`,
    `trust_registry_revision`, `contract_version`, `contract_revision`,
    `verification_policy_version`, `artifact_set`, `rights_decision`,
    `coverage_decision`, `admission_request`, `consumer_use_profile` and
    `verifier_commit`. Its binding digest is a labelled `label=value\n` byte
    buffer hashed with SHA-256 — an internal verifier digest, not a signed
    cross-boundary receipt.
  - `crates/release-verifier/src/verifier.rs:680-726`: stage six evaluates
    rights; any decision other than `Decision::Permit` returns
    `VerifierError::RightsNotPermitted` (`REJECT_RIGHTS_EVIDENCE`), and the
    admission receipt is constructed only after all twelve stages succeed.
  - `crates/release-verifier/src/error.rs`: typed `VerifierError` variants,
    including `CleanupPending` and `REJECT_RIGHTS_EVIDENCE`; a rejected
    release is not retried under the same identity.
  - `crates/release-verifier/src/trust.rs`: `KeyState` =
    `ACTIVE`/`RETIRED`/`REVOKED`/`COMPROMISED`; `TrustedKeyEntry` carries an
    immutable `key_id`, `public_key_bytes`, `purpose`, validity bounds, state
    and revocation evidence. The registry is injected by the caller; the
    crate creates no key. The only currently defined `KeyPurpose` is
    `ReleaseSigning`.

### 1.3 Non-goals and unchanged freeze

This contract creates no schema ratification, no source change, no release, no
dataset, no right, no provider contact, no collection, no experiment, no India
implementation, no live route and no CI change. It does not promote any
`Implemented` state to `Verified`, and it claims none of `SCHEMA_CONFORMANT`,
`CROSS_EXECUTED`, `CRYPTOGRAPHICALLY_VERIFIED`, `RIGHTS_ADMITTED` or
`DATASET_ACCEPTED`. Freeze unchanged: rights `UNKNOWN`, dataset acceptance
`BLOCKED`, budget INR 0, collection `DISABLED`, experiments `BLOCKED`, live
execution `DISABLED`, D11 strict. All approved digests and historical records
are preserved. No commit is created in this worktree.

## 2. Two separate receipts — never merge

Two distinct artefacts are named by the same English word in current records.
They are different objects with different issuers, evidence, trust roots and
consequences, and they must never be merged into one artefact or one status.

| Property | Fieldbook publication receipt | Nirnay admission receipt |
|---|---|---|
| Issuer | Fieldbook producer local publication transaction | Nirnay independent verifier |
| Source fact | `PublicationReceipt` at FB `cabf1be` | `AdmissionReceipt` at NZ `d3b66f52` |
| Evidence basis | Durable local journal tree, `fsync`/directory sync, receipt written into the ledger, availability marker | Twelve independent verification stages, out-of-band trusted key, strict canonical bytes, injected rights and coverage decisions |
| Authenticity | Local authenticated storage only; no signature, no external trust root | Publisher signature verified; receipt binding digest computed internally |
| Terminal value | `PublicationState` (`AVAILABLE` when produced by `build_release`) | `AdmissionResult::Admitted` only |
| Trust boundary | Producer host and its filesystem | Consumer host and its injected trust registry |
| Consequence | Local acknowledgement that a publication operation reached a durable state | Consumer-side admission after independent verification and PERMIT rights |

Binding rules:

1. A publication receipt is **never** an admission receipt. It proves only that
   the producer acknowledged its own local durable state under a declared
   durability profile.
2. A publication receipt must **not** grant a right, promote `UNKNOWN` rights,
   accept a dataset, enable an experiment or enable execution or live order
   submission. Rights remain `UNKNOWN` and dataset acceptance `BLOCKED` until
   the separate, independently evidenced owner gates exist (I-09, I-10).
3. The consumer retains `publisher_receipt_valid` as **one input only** to its
   own decision. It is neither sufficient nor authoritative for admission.
   Stage six still refuses with `REJECT_RIGHTS_EVIDENCE` under UNKNOWN rights,
   regardless of how valid the publication receipt is.
4. An admission receipt is issued by the consumer only after all twelve stages
   succeed; it is not signed by the producer and is not transported back into
   Fieldbook as publication evidence.
5. Neither receipt is a durability certificate. A local acknowledgement is not
   consumer admission, and a consumer admission is not a D1–D4 durability
   qualification (WS-DUR-001 §5).

## 3. Authenticity model — decision points and recommended resolutions

Each item below is a **decision point for the owner**, not a ratified choice.
The recommendation is the contract's proposed resolution; no item is effective
until ratification.

| ID | Decision point | Options | Recommended resolution and rationale |
|---|---|---|---|
| A1 | Trust boundary for the receipt | (i) rely on Fieldbook local authenticated storage (journal digest chain + `fsync`); (ii) use an independently signed receipt with a dedicated purpose | **(ii) INDEPENDENTLY SIGNED receipt.** A local journal proves facts to the process that wrote it; it is not evidence across a trust boundary to a separate consumer host. The signed receipt is the portable assertion; local storage remains producer-internal evidence. |
| A2 | Signing key separation | reuse the manifest release-signing key; or use a separate receipt-signing key | **Separate receipt-signing key.** Release signing authenticates manifest bytes; receipt signing authenticates a producer-local publication transaction. Conflating the two lets a manifest key assert durability facts it never observed and forces one registry purpose to cover two evidence classes. |
| A3 | Rotation and revocation | encode in the receipt; or use an out-of-band registry | **Out-of-band trusted receipt-key registry**, distinct in purpose from the release-signing registry. Key ids are immutable and never reused; states are `ACTIVE`/`RETIRED`/`REVOKED`/`COMPROMISED`; rotation and revocation carry dated evidence and a registry revision bound into verification. A publisher-supplied timestamp is insufficient (Profile 1 Decision H). |
| A4 | What the consumer inspects | parse Fieldbook journal records / in-memory state; or verify a journal attestation or derived signed wire receipt | **Verify the signed wire receipt and its bindings only.** The consumer does not parse Fieldbook journal internals, does not trust caller memory and does not infer durability from directory presence. A journal attestation is admissible only as authenticated digest values bound inside the signed receipt. |
| A5 | Stale and superseded receipts | accept any well-signed receipt; or bind operation identity and predecessor chain | **Stale/superseded detection via `publication_operation_id` plus the `supersedes_release_id` predecessor chain.** The consumer checks the receipt against the manifest lineage predecessor, rejects cycles, missing predecessors and revision regression, and keeps a seen-register keyed by release identity and operation id so an older commit position or a reissued operation cannot be replayed as current. |
| A6 | Durability claim | accept a generic `durable: true`; or require a verifiable, profile-scoped claim | **Profile-scoped claim only.** `durability_profile_id` names a registered WS-DUR-001 profile (tier D0–D4, platform, filesystem/version, mount, kernel/OS, device class, sync primitive, acknowledgement rule, tested cases, evidence digest). There is no global durability Boolean. A claim outside a qualified profile fails closed; D1–D4 are currently `false` and `PUBLICATION_DURABILITY_VERIFIED` remains NOT ACHIEVED. |
| A7 | Field immutability | allow selective field replacement; or fix a normative immutable field set | **Normative immutable fields.** Every body field in §4 is immutable once signed; a correction creates a new receipt under a new operation id and a new predecessor link. No field is removed, blanked or replaced before canonicalization. |
| A8 | Missing, malformed, stale or unverifiable receipt | fall back to directory presence or to manifest `AVAILABLE`; or typed refusal | **Typed refusal, never admission.** A receipt that is absent, malformed, stale, superseded, unsigned, signed by an untrusted/expired/wrong-purpose key or inconsistent with the manifest is refused with a named code (§5.4). No fallback to in-memory state, directory presence or a manifest declaration. |

## 4. Normative receipt wire fields

The wire receipt is a **new, versioned document** proposed for a future explicit
schema entry. It does **not** alter, extend or version-bump the ratified NDC v2
Profile 1 manifest or sidecar schema. No schema artifact is created here. The
signed receipt is a separate portable document; it is not embedded in the
manifest or release artifacts, so no unapproved durability claim enters the
manifest.

### 4.1 Field table

| Field | Type | Source / binding | Invariant |
|---|---|---|---|
| `receipt_schema_version` | integer | this contract, proposed version `1` | Explicit and registered; an unregistered version fails closed. |
| `publisher_identity` | non-empty string | `manifest.publication_identity.publisher_identity` and sidecar key binding | Must equal the verified publisher identity; no placeholder. |
| `receipt_signer_identity` | non-empty string | identity of the receipt key holder in the receipt registry | May equal `publisher_identity`; its key purpose is still separate (A2). |
| `receipt_key_id` | non-empty immutable string | receipt-key registry | Never reused; resolves to exactly one registry entry. |
| `release_id` | non-empty string | `PublicationReceipt.release_id`, manifest release identity | Byte equality with the verified manifest release identity. |
| `publication_operation_id` | non-empty string | `PublicationIntentV2.operation_id` / receipt field | Immutable operation identity; staleness key (A5). |
| `manifest_sha256` | lowercase hex SHA-256 | receipt field; `intent.manifest_sha256`; sidecar digest | Equals the computed JCS manifest digest and the sidecar value. |
| `signature_sidecar_sha256` | lowercase hex SHA-256 | `intent.sidecar_sha256` | Digest of the exact `signature.json` bytes that verified the manifest. |
| `dataset_sha256` | lowercase hex SHA-256 | receipt field; `intent.data_sha256`; Profile 1 Decision D | Digest over ordered uncompressed canonical record streams; compression independent. |
| `commit_position` | non-empty string | receipt field; `intent.commit_position` | Bound to the operation; participates in staleness comparison. |
| `supersedes_release_id` | string or `null` | receipt field; manifest `lineage.supersedes.supersedes_release_id` | Null for an initial release; otherwise the immediate predecessor, with no cycle or regression. |
| `publication_state` | closed enum | `PublicationReceipt.result` | Terminal local state; only values approved by owner decision are acceptable (OD-06). |
| `journal_schema_version` | integer | Fieldbook journal schema version bound by the intent | `1` legacy readable, `2` qualified evidence path; consumer acceptance policy is OD-07. |
| `wire_profile_id` | non-empty registered string | `intent.wire_profile` | Names NDC v2 Release Serialization Profile 1; unknown profile fails closed. |
| `resource_profile_id` | non-empty registered string | `intent.resource_profile` | Names a registered resource profile; the consumer applies its **own** maxima and never adopts producer-declared limits. |
| `durability_profile_id` | non-empty registered string | WS-DUR-001 profile register | Must name a qualified profile; a generic or unregistered durability claim fails closed (A6). |
| `receipt_created_at` | decimal string | producer clock at receipt commit | Nanosecond instant, §4.2; a semantic ordering input, not a key-validity source. |
| `signature_algorithm` | closed string enum | receipt signature block | Only `Ed25519` is accepted in this version. |
| `signature_b64` | base64 string | receipt signature block | Ed25519 signature over §4.3 canonical body bytes; malformed encoding fails closed. |

The signed body is the set of fields above **except** `signature_algorithm` and
`signature_b64`. Those two are the detached signature block and are excluded so
the signature is not circular.

### 4.2 Decimal-string instant semantics

`receipt_created_at` follows the ratified Profile 1 instant rule
(WS-NDC-2026-003 §4.1): a decimal string matching `^(0|[1-9][0-9]*)$`,
validated to be within the `u64` range, in nanoseconds since the Unix epoch in
UTC. No leading zeros, no sign, no fractional part, no exponent, no integer
coercion from a string and no string coercion from an integer. Field-level
monotonicity and ordering are semantic checks on the parsed value. A
publisher-supplied instant does not establish key validity or revocation time.

### 4.3 Canonicalization and signature input

1. The receipt body is UTF-8 with no BOM, serialized by RFC 8785 JCS. Property
   ordering, string escaping and number serialization follow RFC 8785 exactly.
2. Strict parsing rejects duplicate property names, unknown properties, missing
   required properties and incorrect JSON types. There are no implicit
   defaults, no inferred values, no silent coercions and no unversioned
   extensions.
3. The canonical bytes are the sole input to digesting and signature. No
   property is removed, blanked or replaced before canonicalization; the
   signature block is excluded because it is a separate member, not because a
   body property was withheld.
4. Proposed signature construction (subject to OD-02):
   `S = Ed25519.Sign(K_receipt_private, D_receipt || SHA256(JCS(body)))` with
   `D_receipt = UTF8("NDC-V2-PUBLICATION-RECEIPT-SHA256-V1") || 0x00`. This
   domain separator is distinct from the release-manifest domain
   `NDC-V2-RELEASE-MANIFEST-SHA256-V1`, so a release signature cannot be replayed
   as a receipt signature and vice versa.
5. All §4.1 body fields are immutable once signed. A correction is a new
   receipt with a new operation id, a new `receipt_created_at` and a
   `supersedes_release_id` pointing to the immediate predecessor.

## 5. Verification pipeline and refusals

### 5.1 Ordered checks

The consumer runs these checks in order and stops at the first typed refusal.
None of them evaluates rights, coverage or dataset acceptance.

1. **Parse strict.** UTF-8, RFC 8785 JCS, duplicate/unknown/missing/wrong-type
   rejection, registered `receipt_schema_version`.
2. **Canonical bytes.** Recompute the JCS body bytes; verify the signature block
   shape and base64 decoding.
3. **Verify signature.** Verify Ed25519 over `D_receipt || SHA256(JCS(body))`.
4. **Trusted key validity.** Resolve `receipt_key_id` in the out-of-band receipt
   registry; require `ACTIVE` state, `RECEIPT_SIGNING` purpose, `Ed25519`
   algorithm, a validity window covering the consumer evaluation time (not the
   publisher-supplied `receipt_created_at`), a valid registry revision and no
   key reuse.
5. **Bind identity and digests.** Require byte equality of `publisher_identity`,
   `release_id`, `manifest_sha256`, `signature_sidecar_sha256` and
   `dataset_sha256` against the independently verified manifest and sidecar
   values. `publication_operation_id`, `commit_position` and the profile claims
   are bound as signed receipt fields; the consumer does not read Fieldbook
   intent or journal internals to establish them (A4).
6. **Bind profile claims.** Check `wire_profile_id`, `resource_profile_id`,
   `journal_schema_version` and `publication_state` against the registered and
   consumer-accepted values; apply the consumer's own resource maxima.
7. **Supersession and staleness.** Check `supersedes_release_id` against the
   manifest lineage predecessor; reject cycles, missing predecessors, revision
   regression, self-reference, a replayed operation id and an older commit
   position for an already seen release identity.
8. **Durability qualification.** Resolve `durability_profile_id` in the
   WS-DUR-001 register; accept only a qualified, profile-scoped claim. No
   global durability Boolean exists.
9. **Rights separately.** Continue the existing independent pipeline. Stage six
   evaluates rights evidence and refuses any decision other than `PERMIT`. The
   publication receipt result is recorded as `publisher_receipt_valid` and has
   no authority over the rights verdict.
10. **Admission.** Only if all twelve verifier stages succeed and rights are
    `PERMIT` may the Nirnay admission receipt be constructed. It remains a
    separate object from the signed publication receipt.

### 5.2 Decision-input status

`publisher_receipt_valid` is a boolean **input** to the consumer decision. It
is not `RIGHTS_ADMITTED`, not `DATASET_ACCEPTED`, not `CRYPTOGRAPHICALLY_VERIFIED`
and not a durability state. Rights stage six still refuses under UNKNOWN, and
the private snapshot is discarded on refusal under the NZ #144 cleanup
contract (typed `CleanupReport` or `CleanupPending`; the rights refusal code is
preserved and no admission receipt is written).

### 5.3 Trust and registry requirements

1. A **separate trusted receipt-key registry** is authoritative for receipt
   signatures. It is distinct from the release-signing registry and injected
   from outside the release; a receipt cannot supply its own key.
2. Each entry carries a publisher identity, an immutable and never-reused key
   id, raw Ed25519 public key bytes, the closed algorithm token `Ed25519`, a
   `RECEIPT_SIGNING` purpose, validity begin and end, a state in
   `ACTIVE`/`RETIRED`/`REVOKED`/`COMPROMISED`, a registry revision and a
   reference to rotation/revocation evidence.
3. `ACTIVE` verifies; `RETIRED` verifies historical use only with separately
   trusted pre-retirement evidence; `REVOKED` and `COMPROMISED` fail closed.
   Key ids are never reused, registry updates are versioned and auditable, and
   the registry revision is bound into the verification record.
4. No private key is stored in Git, in a release package, in this worktree or
   in any document produced here. No production key is generated, installed or
   activated in this design phase; only caller-injected test keys are used in
   any later implementation gate.

### 5.4 Typed refusal codes (proposed)

| Condition | Refusal code | Admission possible? |
|---|---|---|
| Receipt file absent | `REJECT_RECEIPT_MISSING` | No |
| Duplicate/unknown/missing/wrong-type field, bad version or bad canonical bytes | `REJECT_RECEIPT_SCHEMA` | No |
| Malformed signature, failed signature check or wrong domain | `REJECT_RECEIPT_SIGNATURE` | No |
| Unknown key id, wrong state, wrong purpose, wrong algorithm, expired validity, invalid registry | `REJECT_RECEIPT_KEY` | No |
| Manifest, sidecar, dataset, operation or profile binding mismatch | `REJECT_RECEIPT_BINDING` | No |
| Supersession cycle, missing predecessor, regression, replayed operation or older commit position | `REJECT_RECEIPT_STALE` | No |
| Unregistered or unqualified durability profile | `REJECT_RECEIPT_DURABILITY` | No |
| Rights decision not `PERMIT` (including UNKNOWN) | `REJECT_RIGHTS_EVIDENCE` (existing stage-6 code) | No |

No refusal code carries a retry suggestion; a rejected receipt is not
re-admitted under the same identity.

## 6. Compatibility and migration

1. The current local `PublicationReceipt` at FB `cabf1be` stays valid **only
   inside Fieldbook** as the producer's local durability acknowledgement. Its
   wire shape and digest are not changed by this contract.
2. A future **signed export adapter**, owned by the producer side and
   authorized by a separate implementation gate, may derive the §4 wire receipt
   from `PublicationIntentV2` (intent fields, `expected_receipt`,
   `expected_receipt_sha256`, `sidecar_sha256`, `wire_profile`,
   `resource_profile`, artifact inventory) and the durable journal evidence.
   The adapter signs with the dedicated receipt key. This contract neither
   implements nor authorizes that adapter.
3. **No ratified NDC wire schema changes.** The Profile 1 manifest and sidecar
   schemas, their digests and the B8 package are untouched. The receipt wire
   form needs a future explicit, versioned schema entry and its own vectors;
   DP-29 remains respected.
4. **No shared runtime crate.** Producer export adapter and consumer verifier
   are independent implementations. Only the proposed receipt schema and
   abstract vectors may be shared, as with the NDC v2 canonical package.
5. Migration is staged: (a) ratify this contract; (b) add the versioned receipt
   schema entry and abstract vectors; (c) implement the producer export adapter
   and the consumer verification path behind a flag with injected test keys;
   (d) run paired cross-execution and record exact commits. No stage promotes
   a capability state by wording.
6. Legacy journal schema v1 remains readable and auditable; no v1 record is
   rewritten and no chain mixes versions.

## 7. Open decisions and acceptance criteria for the implementation gate

### 7.1 Open decisions requiring owner ratification

| ID | Open decision |
|---|---|
| OD-01 | Ratify the independently signed receipt model (A1) instead of local authenticated storage as the cross-boundary assertion. |
| OD-02 | Approve the `RECEIPT_SIGNING` key purpose, the domain separator string `NDC-V2-PUBLICATION-RECEIPT-SHA256-V1` and the Ed25519-only algorithm token. |
| OD-03 | Approve a separate out-of-band receipt-key registry, its entry schema, states, rotation/revocation evidence and revision binding. |
| OD-04 | Approve the §4.1 field set and `receipt_schema_version = 1`, and decide whether to place it in a new versioned schema entry (no ratified schema edit). |
| OD-05 | Decide whether `receipt_created_at` is required or optional and confirm the decimal-string instant grammar for it. |
| OD-06 | Decide the acceptable `publication_state` values (terminal `AVAILABLE` only, or a defined durable-state subset). |
| OD-07 | Decide the `journal_schema_version` policy: v2-only for consumer authenticity, or v1 readable but never sufficient. |
| OD-08 | Approve the `durability_profile_id` register, the profile field set and the owner of qualification evidence. |
| OD-09 | Approve supersession and staleness semantics, including the consumer seen-register key and commit-position comparison. |
| OD-10 | Assign ownership and placement of the producer-side signed export adapter and confirm it is a separate work package. |
| OD-11 | Approve the typed refusal codes and their mapping into the consumer's existing error surface. |
| OD-12 | Decide how `publisher_receipt_valid` enters the consumer decision without becoming a rights or admission input. |

### 7.2 Acceptance criteria for the separate implementation gate

The implementation gate is **not** opened by this document. When opened, it
must satisfy all of the following before any status is claimed:

1. Two independent implementations exist: a producer-side signed export adapter
   and a consumer-side receipt verification path. No shared runtime crate,
   validator, serializer or digest routine is introduced.
2. A versioned receipt schema entry and abstract non-market vectors cover every
   §4.1 field and each adversarial case in §5.4. No secret, market observation,
   provider contact or real release is included in the vectors.
3. Byte-for-byte canonicalization agreement is demonstrated on the same
   canonical receipt bytes from both implementations; no caller-supplied order
   or digest input is trusted.
4. Only injected test keys are used. No production key is generated, installed
   or activated, and no private key appears in a package, Git repository or
   document.
5. The consumer refuses with the §5.4 typed code for every missing, malformed,
   stale, superseded and unverifiable case. No fallback to directory presence,
   in-memory state or a manifest `AVAILABLE` declaration exists.
6. Rights stage six still returns `REJECT_RIGHTS_EVIDENCE` under UNKNOWN; no
   admission receipt is written; the NZ #144 cleanup contract completes or
   reports typed `CleanupPending`; no private snapshot survives a refusal.
7. Durability claims are accepted only under a qualified WS-DUR-001 profile;
   D1–D4 remain `false` and `PUBLICATION_DURABILITY_VERIFIED` remains NOT
   ACHIEVED unless independent D1 evidence is separately ratified.
8. Exact commits, commands, stage results and capability states are recorded in
   a dated evidence record. `SCHEMA_CONFORMANT`, `CROSS_EXECUTED`,
   `CRYPTOGRAPHICALLY_VERIFIED`, `RIGHTS_ADMITTED` and `DATASET_ACCEPTED` are
   reported separately and never collapsed or promoted by wording.
9. Freeze unchanged: rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR
   0, collection `DISABLED`, experiments `BLOCKED`, live execution `DISABLED`,
   D11 strict.

## 8. Effect

This document adds one PROPOSED decision record to the workspace document map
and one entry to `engineering/evidence/REVIEW-LOG.md`. It changes no approved digest, no registered
schema version, no capability state, no source repository, no registry entry
and no freeze term. Ratification, schema entry, implementation and any later
`Implemented` or `Verified` claim are separate owner gates.
