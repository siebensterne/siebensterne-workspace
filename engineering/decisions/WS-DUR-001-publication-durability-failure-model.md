# WS-DUR-001 — Publication durability as a failure model

<!-- SPDX-License-Identifier: Apache-2.0 -->

Status: **RATIFIED by owner direction dated 2026-11-24.** The owner has directed that
publication durability must be scoped to a declared failure model, not counted as a number of
passing tests. This record is the governing programme contract for that scope. It is **not** a
new claim that D1 (OS crash / filesystem crash) is achieved, and it does not promote any
implementation state from `Implemented` to `Verified`.

Authority: the programme-owner direction recorded in `WORKSPACE.md` W3 ("Do not claim zero loss
without a named fault model") and the owner disposition of the publication-durability work
packages. The ratified publication semantics remain `WS-NDC-2026-11-24-002` Decision G and the
bottom-up journal contract recorded in Fieldbook `FB-PUB-019`; this decision adds the failure
model and the claim discipline under which those semantics may be cited.

Scope: documentation only. No source, schema, right, data, provider, India, experiment, release,
key, dataset, collection, live-execution or CI change is authorised here. No commit is created.
All approved digests, the capability states in `CURRENT-STATE.json` and the programme freeze are
unchanged: rights `UNKNOWN`, dataset acceptance `BLOCKED`, budget INR 0, collection `DISABLED`,
experiments `BLOCKED`, live execution `DISABLED`, D11 strict.

## 1. Governing decision

1. Durability is a **failure model**, not a test count and not a single product property. A
   durability claim is meaningful only as `(tier, platform, filesystem, mount, kernel/OS, device
   class, sync primitive, acknowledgement rule, tested failure cases, evidence digest)`.
2. Five tiers are defined: D0 process termination, D1 OS crash / filesystem crash, D2 local
   device failure, D3 host failure, D4 disaster recovery. Each tier is a separate claim. A
   higher tier never follows from a lower tier, and a lower tier is not weakened by a higher
   tier's absence.
3. **No single global durability Boolean exists.** The profile-scoped predicates in §2 are the
   only durability booleans. The programme capability flag `PUBLICATION_DURABILITY_VERIFIED` is
   an aggregate status gate, not a durability guarantee; it stays `false` and is not a substitute
   for a tier predicate.
4. A tier may be claimed only for a profile whose primitive, errors, limitations and evidence
   are documented in a dated record with an exact source commit. `NOT_DECLARED` and
   `NOT_QUALIFIED` are evidence states, not implicit passes.

## 2. Tier profiles and profile-scoped booleans

The ratified predicates are:

| Predicate | Value | Condition / scope |
|---|---|---|
| `D0_PROCESS_RECOVERY_VERIFIED` | `true` | Process-termination tier only; **condition: PUB-020 merged and its gate evidence recorded at an exact Fieldbook commit**. PUB-019 provides the journal-v2 and restart-fault evidence; PUB-020 is the owner-designated process-recovery verification package. Until the PUB-020 merge is evidenced, this predicate has no merged evidence despite its ratified value. |
| `D1_APFS_QUALIFIED` | `false` | macOS/APFS OS-crash or filesystem-crash qualification absent. |
| `D1_EXT4_QUALIFIED` | `false` | Linux/ext4 OS-crash or filesystem-crash qualification absent. |
| `D2_LOCAL_DEVICE_FAILURE_QUALIFIED` | `false` | Local device failure (disk/SSD/NVMedia device fault) not qualified. |
| `D3_HOST_FAILURE_QUALIFIED` | `false` | Host failure (machine lost, no shared storage) not qualified. |
| `D4_DISASTER_RECOVERY_QUALIFIED` | `false` | Site disaster recovery, backup and restore not qualified. |

All six predicates are scoped to the Fieldbook v2 publication path that writes the journal,
staging tree, final directory, receipt and availability marker. None applies to Nirnay admission
or to any provider, market-data or India path.

### 2.1 D0 — process termination

| Field | Record |
|---|---|
| `tier_id` | `D0` — process termination (clean exit, signal, simulated restart); no OS or device fault |
| `failure_model` | The publishing process stops at a journal or filesystem boundary; the OS, filesystem and storage device remain functional. Recovery is a new process reading durable journal evidence. |
| `supported_platforms` | macOS host used for the recorded Fieldbook tests (Darwin primitive `renamex_np(RENAME_EXCL)`); Linux `renameat2(RENAME_NOREPLACE)` is source-qualified only. Exact OS version is not pinned by the cited record. |
| `filesystem` | Local temporary filesystem used by the Fieldbook publication tests; not a qualified production filesystem |
| `filesystem_version` | `NOT_DECLARED` — no production filesystem version is qualified |
| `mount_configuration` | Exclusive sibling staging directory and final directory on the same filesystem and same Unix device id; sibling topology checked by `PublicationTopology` |
| `kernel_or_os_version` | `NOT_DECLARED` for a qualified claim; host version not pinned in the cited gate record |
| `storage_device_class` | Local temporary backing store; device class not inspected or qualified |
| `sync_primitive` | `fsync`/`sync_all` on each regular file, on the `artifacts/` child directory and on the staging directory; parent/root directory sync on provisioning, staging entry, rename, receipt and marker; `F_FULLFSYNC` **not** used (see §4) |
| `acknowledgement_rule` | A publication state is acknowledged only after every sync required by that state succeeded; a failed sync returns a typed `ProducerError` and is never downgraded to a warning; no acknowledgement from in-memory state, directory presence or a manifest declaration |
| `tested_failure_cases` | Process restart at every committed journal stage; journal directory sync failure withholds acknowledgement; boundary faults at staging mkdir, root sync, artifacts mkdir, each file write/sync, both directory syncs, rename, rename root sync, receipt write/sync/ledger sync, marker write/sync/ledger sync; recovery from staging and final directory; v1-record readability and mixed-version refusal |
| `known_limitations` | Process crash only. Not OS crash, power loss, device failure, host failure or disaster recovery. No drive-cache flush qualification. No replication, backup or restore. Local receipt is not consumer admission. |
| `evidence_digest` | `c659dbb8d87369a9cd00e25aa07c8749d980e9d9237e62f44bc3b449620d0c561f` — SHA-256 of `docs/fb-pub-019-directory-durability-2026-11-24.md` at exact Fieldbook commit `eecfe8ca54454245b813867ee273b60675c67025` (PR #69, merged). This is a gate-record digest, not an independent durability certificate. `D0_PROCESS_RECOVERY_VERIFIED` is conditioned on the owner-designated PUB-020 merge, not satisfied by this digest alone. |

### 2.2 D1 — OS crash / filesystem crash

| Field | Record |
|---|---|
| `tier_id` | `D1` — OS crash / filesystem crash, including physical power loss where the storage device and its write cache are in scope |
| `failure_model` | The operating system or filesystem loses volatile state; unflushed page cache, directory entries or device write cache may be lost. Recovery must find only durability operations whose barriers completed before the fault. |
| `supported_platforms` | macOS/APFS and Linux/ext4 are candidate profiles; neither is qualified. All other targets fail closed. |
| `filesystem` | APFS (macOS candidate); ext4 (Linux candidate) |
| `filesystem_version` | `NOT_DECLARED` — no APFS or ext4 version qualified |
| `mount_configuration` | Required for a future claim: journal, staging, final directory and ledger on one explicitly declared filesystem and mount option set; no cross-device staging/final split; mount options and cache policy recorded with the evidence |
| `kernel_or_os_version` | `NOT_DECLARED` — exact kernel and OS build must be recorded with a D1 claim |
| `storage_device_class` | `NOT_DECLARED` — HDD, SATA SSD, NVMe and virtual device caches have different flush semantics |
| `sync_primitive` | Per-platform `fsync` plus required directory syncs; on macOS a drive-cache flush primitive may be `F_FULLFSYNC`, which is **not yet used or qualified** (§4) |
| `acknowledgement_rule` | Same rule as D0, evaluated under the declared OS/filesystem/device failure model; an acknowledgement is valid only for the exact qualified profile |
| `tested_failure_cases` | None. No APFS or ext4 OS-crash or physical power-loss test exists. VM reset is not a D1 case (§4). |
| `known_limitations` | Both `D1_APFS_QUALIFIED=false` and `D1_EXT4_QUALIFIED=false`. Source compilation, process-restart tests and a macOS temporary-filesystem exercise do not establish OS-crash behaviour. Other filesystems and drivers were not measured. |
| `evidence_digest` | `NONE` — no D1 evidence package exists; `PUBLICATION_DURABILITY_VERIFIED` remains `false` |

### 2.3 D2 — local device failure

| Field | Record |
|---|---|
| `tier_id` | `D2` — local device failure (disk/SSD/NVMedia device fault, unreadable sectors or device loss) |
| `failure_model` | The storage device fails; data may be unreadable or the device may disappear. Local barriers cannot repair device loss. |
| `supported_platforms` | `NONE_DECLARED` |
| `filesystem` | `NONE_DECLARED` |
| `filesystem_version` | `NOT_DECLARED` |
| `mount_configuration` | `NOT_DECLARED` — a D2 claim requires a declared redundant device layout |
| `kernel_or_os_version` | `NOT_DECLARED` |
| `storage_device_class` | `NOT_DECLARED` |
| `sync_primitive` | Local `fsync` and directory sync are insufficient for D2; a device-redundancy primitive would be required |
| `acknowledgement_rule` | No D2 acknowledgement is defined; no publication may claim D2 |
| `tested_failure_cases` | None |
| `known_limitations` | `D2_LOCAL_DEVICE_FAILURE_QUALIFIED=false`. No local device-fault injection, redundancy or rebuild evidence. |
| `evidence_digest` | `NONE` |

### 2.4 D3 — host failure

| Field | Record |
|---|---|
| `tier_id` | `D3` — host failure (machine lost, unavailable, or replaced without its local storage) |
| `failure_model` | The publishing host is lost; local files, journal and receipt are unavailable to a consumer. |
| `supported_platforms` | `NONE_DECLARED` |
| `filesystem` | `NONE_DECLARED` |
| `filesystem_version` | `NOT_DECLARED` |
| `mount_configuration` | `NOT_DECLARED` — a D3 claim requires a declared shared or multi-host storage layout |
| `kernel_or_os_version` | `NOT_DECLARED` |
| `storage_device_class` | `NOT_DECLARED` |
| `sync_primitive` | Local barriers are insufficient; a replicated commit protocol would be required |
| `acknowledgement_rule` | No D3 acknowledgement is defined; no publication may claim D3 |
| `tested_failure_cases` | None |
| `known_limitations` | `D3_HOST_FAILURE_QUALIFIED=false`. No replication, failover or multi-host evidence. |
| `evidence_digest` | `NONE` |

### 2.5 D4 — disaster recovery

| Field | Record |
|---|---|
| `tier_id` | `D4` — disaster recovery (site loss, backup restore, business-continuity objective) |
| `failure_model` | The site and its local storage are lost; recovery depends on an independently stored backup and a tested restore path. |
| `supported_platforms` | `NONE_DECLARED` |
| `filesystem` | `NONE_DECLARED` |
| `filesystem_version` | `NOT_DECLARED` |
| `mount_configuration` | `NOT_DECLARED` — a D4 claim requires a declared off-site backup topology |
| `kernel_or_os_version` | `NOT_DECLARED` |
| `storage_device_class` | `NOT_DECLARED` |
| `sync_primitive` | Local barriers are insufficient; a tested backup and restore primitive would be required |
| `acknowledgement_rule` | No D4 acknowledgement is defined; no publication may claim D4 |
| `tested_failure_cases` | None |
| `known_limitations` | `D4_DISASTER_RECOVERY_QUALIFIED=false`. No backup, restore or RTO/RPO evidence exists. |
| `evidence_digest` | `NONE` |

## 3. Acknowledgement contract

1. A publisher may acknowledge a publication state **only after every durability operation
   required by that state succeeded under the declared failure model**. The state label itself,
   directory existence, a manifest `AVAILABLE` declaration and in-memory progress are not
   evidence.
2. A failed sync is an **error, never a warning**. The operation stops with a typed error; no
   successor state is recorded, no receipt is written and no availability marker is created.
   Recovery may only reconcile from validated on-disk journal evidence.
3. Every committed journal record is canonical JSON with its self-consistency digest,
   predecessor link, ordinal and ledger-directory sync. A record is durable evidence only after
   the ledger-directory sync returns.
4. Required semantics for the five acknowledgement states on the Fieldbook v2 path:

| State | Required durability operations before acknowledgement | Acknowledgement effect |
|---|---|---|
| `STAGING_CREATED` | Exclusive sibling staging directory created; release root carrying the staging entry synced; `(operation_id, release_id, manifest_sha256, data_sha256, commit_position, staging/final paths, expected receipt digest)` committed as `OPERATION_INTENT_DURABLE` with ledger sync. | Staging entry may be claimed. No file, child directory, rename, receipt or availability is claimed. (`STAGING_ENTRY_DURABLE` in journal schema v2.) |
| `STAGING_TREE_DURABLE` | Manifest, signature and every declared artifact written; each regular file synced; `artifacts/` child directory synced; staging directory synced; `STAGING_TREE_DURABLE` record committed with ledger sync; staging tree validated against digests and exact file set. | Staging tree may be claimed durable. No rename is claimed. Recovery may continue only from this verified tree. |
| `RENAME_DURABLE` | One atomic no-replace directory rename succeeded; release root carrying the final name synced; `RENAME_DURABLE` record committed with ledger sync. Final directory belongs to this operation. | Final name may be claimed durable. A rename before the root sync is an uncertain-publication case, not an acknowledgement. |
| `PUBLICATION_RECEIPT_DURABLE` | Receipt written with bound release identity, manifest digest, dataset digest, operation identity, commit position and result; receipt file synced; ledger directory synced. | Local receipt may be claimed durable. It is a local acknowledgement only: no source authenticity, coverage, right, dataset entitlement or Nirnay admission follows. |
| `AVAILABLE` | Availability marker written, marker file synced, ledger synced again, `AVAILABLE` journal record committed with ledger sync. | Local availability may be acknowledged. Dataset admission remains a separate consumer decision under UNKNOWN rights. |

5. The ratified eight-state Decision G machine and the five-record journal schema v2 are
   compatible: the eight-state order remains the published semantic machine, and the five states
   above are its acknowledgement-relevant v2 journal records. Version-1 records remain readable
   and auditable as legacy evidence; no v1 record is rewritten and no chain mixes versions.
6. Recovery from a crash between rename and parent-directory sync stays an **uncertain
   publication**: the final directory is quarantined or reconciled from durable evidence, never
   adopted from caller memory, directory presence or another operation's release.

## 4. Platform qualification

| Platform | No-replace primitive | Sync primitive | Drive-cache flush | Qualification state |
|---|---|---|---|---|
| Linux | `renameat2(AT_FDCWD, from, AT_FDCWD, to, RENAME_NOREPLACE)` through `libc::syscall`; kernel and filesystem support required; existing destination returns `EEXIST`; absence of support surfaces as an I/O error | `fsync`/`sync_all` on files and directories | No separate drive-cache flush primitive used | Source-qualified at Fieldbook `FB-NDC-012`; the Linux branch was **not executed** on the recorded macOS host; `D1_EXT4_QUALIFIED=false` |
| macOS | `renamex_np(from, to, RENAME_EXCL)` through `libc`; Darwin and backing filesystem must support `RENAME_EXCL`; otherwise typed I/O error | `fsync`/`sync_all` on files and directories | `F_FULLFSYNC` **may be required** to flush the drive write cache; **not yet used or qualified** | Success and collision cases exercised on the local temporary filesystem used by the tests; other filesystem drivers not measured; `D1_APFS_QUALIFIED=false` |
| Other targets | None; `atomic_no_replace_rename` returns `io::ErrorKind::Unsupported` | Not declared | Not declared | Fail closed; no fallback to `create_dir`, `hard_link` or a replacement-capable `rename` |

1. A **VM reset is not a physical power-loss test**. A VM reset can leave host page cache,
   virtual device caches and the hypervisor's own journal intact; it does not establish that
   bytes survived a loss of device write cache. Only a declared physical power-loss or equivalently
   qualified storage-level fault is D1 evidence.
2. Before a tier is claimed for a platform, a dated record must document: the exact primitive
   and its call site; the exact error behaviour on collision, unsupported filesystem and sync
   failure; the filesystem, filesystem version, mount options, kernel/OS build and storage device
   class; the failure injection used; the evidence digest; and the limitations. Absence of any of
   these keeps the predicate `false`.
3. `fsync` orders bytes into the filesystem's durable state as defined by that filesystem and
   device; it does not by itself prove a drive cache was flushed, and it is not replicated
   durability.

## 5. Permissible claim language

| Permitted | Not permitted |
|---|---|
| "Under the D0 process-termination profile on the declared temporary filesystem, journal stages survive a process restart and an interrupted publication is reconciled from durable evidence." | "Zero data loss." |
| "Under the D1 APFS profile at exact OS/filesystem/device versions, the following power-loss cases were exercised and the following limits remain." (only after `D1_APFS_QUALIFIED=true`) | "RPO = 0" without a declared failure class, or "durable" without a tier. |
| "Local `fsync` and parent-directory sync completed before acknowledgement on this filesystem." | "Local `fsync` gives replicated durability" or "a qualified Mac or Linux filesystem justifies a global durability claim." |
| "The publication receipt is a local acknowledgement; Nirnay admission is a separate decision under UNKNOWN rights." | "A receipt, an `AVAILABLE` declaration or directory presence proves durable publication or dataset admission." |
| "D2/D3/D4 are not qualified; cross-host replication, backup and restore are separate tiers." | "The system is durable" or "production-ready" from process-crash tests alone. |

A qualified profile is a conjunction, not a disjunction: a pass on one platform, one filesystem
or one device class never transfers to another profile.

## 6. Journal, work packages and capability gate

1. **Fieldbook v2 publication journal.** `FB-PUB-017` (Fieldbook commit
   `475dc34c8cc510ac8dfba158dfdedbd91950f219`, PR #68) added digest-chained immutable stage
   records with ledger-directory `fsync` after every committed transition, provisioning parent
   sync, canonical validation of sequence records and restart/crash tests at every stage.
   `FB-PUB-019` (merged at Fieldbook commit `eecfe8ca54454245b813867ee273b60675c67025`, PR #69)
   added bottom-up directory durability: journal schema v2, five-record state machine, separate
   file/child-directory/root sync boundaries, receipt and marker fidelity, and process-restart
   and injected-fault tests. `src/distribution/ndc_release.rs` remains the single producer
   authority; the release layout stays `manifest.json`, `signature.json` and declared paths under
   `artifacts/`.
2. **Pending packages.** PUB-019 is merged at the exact commit above. PUB-020 (owner-designated
   process-recovery verification package) and PUB-021 are pending; this workspace holds no
   evidence of their content, merge state or tests, and this decision claims none of them.
   `D0_PROCESS_RECOVERY_VERIFIED=true` is the ratified predicate **conditioned on PUB-020 being
   merged and its gate evidence recorded at an exact commit**; until that merge is evidenced, no
   D0 claim is made from this document. No pending package is treated as delivered, and no test
   count from a pending package is added to an existing count.
3. **Capability gate.** `PUBLICATION_DURABILITY_VERIFIED` stays `false` in both
   `ndc_profile_status.statuses` and `production_builder_parity.capability_states` of
   `CURRENT-STATE.json`. It remains **NOT ACHIEVED until D1 evidence exists** for a declared
   APFS or ext4 profile (physical power-loss or equivalent qualified fault, exact versions and
   mount settings, documented errors and limitations). The cross-execution record shows only
   structural and cryptographic stages before `REJECT_RIGHTS_EVIDENCE`; the Fieldbook publication
   receipt written into the ledger is distinct from the absent Nirnay admission receipt.
4. This decision changes no digest, no capability state, no release, no right and no freeze term.

## 7. Cross-cutting invariants I-01..I-15 (normative)

These are binding programme invariants from the owner's assignment. "Owner" is the accountable
named role from `OWNER-RATIFICATION-2026-11-23.md` Decision A; a repository name alone is not an
accountable owner. Test gates are cited where known and are evidence pointers, not claims that a
gate has been re-run by this documentation work.

| ID | Normative invariant | Owner | Repository | Test gate / evidence where known |
|---|---|---|---|---|
| I-01 | No publication acknowledgement without durable evidence. | Fieldbook producer owner (Kartik Jangid) | Fieldbook | `FB::receipt_is_bound_to_release_and_digests`; `FB::journal_directory_sync_failure_withholds_the_acknowledgement`; `FB::partial_receipt_or_marker_is_never_acknowledged` |
| I-02 | No recovery from caller memory alone. | Fieldbook producer owner (Kartik Jangid) | Fieldbook | `FB::recovery_without_evidence_is_empty`; `FB::every_committed_journal_stage_survives_a_process_restart` |
| I-03 | No adoption of another operation's release. | Fieldbook producer owner (Kartik Jangid) | Fieldbook | `FB::recovery_does_not_adopt_a_release_from_another_operation`; `FB::forged_rename_stage_does_not_transfer_ownership` |
| I-04 | No receipt from an unverified tree. | Fieldbook producer owner (Kartik Jangid) | Fieldbook; Nirnay (refusal) | `FB::recovery_from_final_directory_writes_receipt`; `FB::incomplete_staging_is_not_promoted_by_recovery`; `FB::receipt_binding_mismatch_fails_closed`; `NZ::missing_artifact_is_refused` |
| I-05 | No symlink-following. | Fieldbook producer owner; Nirnay consumer owner (Kartik Jangid) | Fieldbook; Nirnay | `FB::traversal_path_is_rejected`; `FB::detects_symlink_and_hardlink_output_aliases`; `NZ::symlink_escape_is_refused` |
| I-06 | No ignored cleanup failure. | Nirnay consumer owner (Kartik Jangid) | Nirnay | `NZ::rights_refusal_with_cleanup_failure_keeps_rights_code`; `NZ::rights_refusal_records_completed_cleanup` |
| I-07 | No caller order metadata without byte verification. | NDC contract owner (Kartik Jangid) | Fieldbook; Nirnay | `FB::byte_derived_order_ignores_caller_key`; `FB::sequenced_ordering_is_deterministic`; `NZ::caller_supplied_key_mismatch_is_refused`; `NZ::byte_derived_key_recomputes_from_record_bytes` |
| I-08 | No unbounded buffering in the operational profile. | Fieldbook producer owner; Nirnay consumer owner (Kartik Jangid) | Fieldbook; Nirnay | `FB::buffered_byte_budget_is_enforced`; `FB::buffer_capacity_is_bounded_across_many_lines`; `NZ::reader_streams_large_journal_with_bounded_record_buffer` |
| I-09 | No admission from publication success. | Nirnay consumer owner (Kartik Jangid) | Nirnay; Fieldbook (non-production) | `NZ::rights_unknown_is_refused`; stage 6 `REJECT_RIGHTS_EVIDENCE` in the dated cross-execution; `FB::builder_does_not_invent_rights_grants` |
| I-10 | No rights promotion. | Data-rights steward (Kartik Jangid) | Fieldbook; Nirnay | `FB::builder_does_not_invent_rights_grants`; `FB::rights_unknown_requires_grant_to_promote`; `NZ::unknown_and_prohibited_rights_do_not_grant_store_or_replay` |
| I-11 | No historical pack replacement. | NDC contract owner (Kartik Jangid) | Fieldbook; Nirnay | `FB::pack_update_with_new_version_is_accepted`; `FB::schema_v1_records_remain_readable_and_auditable`; `FB::mixed_schema_journal_chain_fails_closed`; `NZ::revisions_are_immutable_on_update`; `NZ::reference_revisions_and_head_are_immutable` |
| I-12 | No coverage percentage without denominator. | NDC contract owner (Kartik Jangid) | Fieldbook; Nirnay | `NZ::absent_denominator_is_refused`; `NZ::coverage_requires_nonzero_denominator_and_exhaustive_parts`; `FB::unmeasurable_universe_invents_no_denominator`; `FB::zero_denominator_yields_no_ratio` |
| I-13 | No durability claim outside a qualified profile. | Programme owner (Kartik Jangid) | Workspace; Fieldbook | This decision (§2, §4, §5); `FB::no_replace_rename_fails_closed_on_other_platforms`; `make consistency`; `make audit` |
| I-14 | No source-head claim without an exact commit. | Programme owner (Kartik Jangid) | Workspace | `CURRENT-STATE.json` five separately evidenced head concepts; `make status`; `make audit`; exact commits in `REVIEW-LOG.md` |
| I-15 | No silent deletion of uncertain publication evidence. | Fieldbook producer owner (Kartik Jangid) | Fieldbook; Workspace (RRP) | `FB::recovery_without_evidence_is_empty`; `FB::rename_before_root_sync_crash_is_quarantined`; `FB::schema_v1_records_remain_readable_and_auditable`; `RETIREMENT-ACCEPTANCE.md` no-deletion-before-replacement rules |

`FB::` names cite Fieldbook tests at or after the publication-journal work; `NZ::` names cite
Nirnay verifier or domain tests. Exact commits, gate commands and exits belong in the dated
records and `REVIEW-LOG.md`; none is re-run, re-counted or promoted by this decision.

## 8. Effect

`NDC-REGISTRY.md`, `ADR-REGISTRY.md`, `CURRENT-STATE.json`, the `README.md` document map and
`REVIEW-LOG.md` gain pointers to this decision. `CURRENT-STATE.json` gains a `durability_profiles`
field; no existing source-head field, digest, capability state or freeze term is altered. No
commit is created in any repository.
