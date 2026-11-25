# Agent instructions

This repository coordinates Fieldbook and Nirnay. It contains no product source.

- Use `README.md` to find documents. Use `CURRENT-STATE.json` for current status, permissions and freezes.
- Read `WORKSPACE.md` and `WORKSPACE.lock.json` for ownership, programme boundaries and bootstrap work.
- Read only the contract, decision, implementation and tests that own the task. Do not load the history corpus by default.
- Workspace owns cross-repository decisions and registries. Fieldbook owns source data and NDC publication. Nirnay owns NDC consumption, research, simulation, portfolio and risk.
- Keep the repositories independent. Coordinate interface changes with paired, compatible PRs. Do not create shared source, crates or workspaces without a measured need and an accepted decision.
- Inspect the exact base commit, branch and worktree before editing. Trace callers and tests. Implement the change; do not stop at a plan.
- Make one coherent change per PR. Add regression, boundary and failure tests. Run the owning repository's required gates.
- Do not add Markdown for routine work; behavior belongs in source, tests and the PR. New documents need a contract, decision, procedure or evidence justification.
- Preserve historical evidence and approved contract bytes. Add a new decision or evidence record when state changes; never rewrite history to make it current.
- Use `CURRENT-STATE.json` for authorization. Do not infer data rights or permission from a URL, token, successful connection or checksum. Do not broaden collection, experiments, dataset acceptance or execution authority.
- Keep D11 synthetic-market-data retirements, the M4 holdout and live-execution controls in force. Pure mathematical and abstract protocol tests remain separate from market evidence.
- Do not claim durability, scale, latency, coverage, profitability or readiness without scoped, measured and reviewed evidence.
- Report exact commits, commands, exits, test scope, CI head, evidence and remaining gaps.
