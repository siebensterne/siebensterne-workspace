# Paired PR checklist

Use this for any change that crosses the Fieldbook/Nirnay boundary, especially NDC,
rights, release identity, calendar semantics or dataset admission.

## Before opening PRs

- [ ] State the concrete question and the exact scope.
- [ ] Name the canonical ADR ID and NDC version affected.
- [ ] Confirm no provider contact, collection, download, experiment or live order is involved.
- [ ] Confirm rights and dataset acceptance states are unchanged unless the owner approved them.
- [ ] Confirm the change does not create a shared crate, submodule, parent repository or source copy.

## Per repository

- [ ] Branch from current `main`, not from the lock pin.
- [ ] `make check-static` passes.
- [ ] `make check` passes where applicable, with test counts and deselected counts recorded.
- [ ] Docs, prose and source-style gates pass; no gate weakened or exempted.
- [ ] README doc-map / state block updated where required.
- [ ] Independent review requested and findings resolved or explicitly deferred with owner approval.

## Cross-repository

- [ ] Producer and consumer validators agree on the same version and field semantics.
- [ ] `make consistency` passes in the workspace.
- [ ] Hosted CI conclusion recorded with exact head SHA.
- [ ] `engineering/evidence/REVIEW-LOG.md` updated with both commits and PR numbers.
- [ ] `ADR-REGISTRY.md` and `NDC-REGISTRY.md` updated if identities or versions changed.

## Merge order

1. Producer-side (Fieldbook) change first when the contract is extended.
2. Consumer-side (Nirnay) change second, remaining backward-compatible until the producer lands.
3. Workspace record last, after both heads are known.

Do not merge a paired change with a red CI gate. Do not claim verification from a
green check alone.

## Documentation changes

- [ ] No new Markdown file for routine work; source, tests, the PR and CI carry it.
- [ ] If a new Markdown file is required, the PR states which stable contract,
      decision, procedure or evidence it owns.
- [ ] No duplicated current status; workspace `CURRENT-STATE.json` is the authority.
- [ ] Root `README.md` stays at 100 lines or fewer; root `AGENTS.md` at 2 KB or fewer.
