# Workspace agent rules

1. Read `WORKSPACE.md` and `WORKSPACE.lock.json` before cross-repository work.
2. Record both repository commits, branches, dirty states, remotes and CI runs.
3. Keep changes inside one repository unless the contract requires coordinated
   changes. For an NDC change, prepare paired PRs and preserve compatibility.
4. Never add a parent Git repository, submodule, shared Cargo workspace or
   unapproved shared crate.
5. Fieldbook publishes NDC. Nirnay consumes immutable releases. Nirnay must not
   acquire or archive raw provider data.
6. Do not contact providers, call market-data APIs, download market data,
   scrape websites or run collection commands without written rights and
   explicit owner approval for the exact operation and scope.
7. Never disguise automation, evade bans, bypass CAPTCHA, rotate identities,
   circumvent rate limits, use proxy/VPN paths to evade restrictions or use
   undocumented endpoints.
8. Do not create synthetic market observations, price bars, order books, trades,
   universes, reference histories or strategy returns. Do not treat historical
   synthetic assets as research evidence. Pure mathematical tests are allowed.
9. Do not run Fieldbook's full fixture/e2e suite until its market-shaped
   fixture inventory has been reviewed against the owner policy. Static gates
   are available through this workspace.
10. Keep rights `UNKNOWN` until evidence exists. Public availability, a
    successful connection, a token or a checksum does not grant retention,
    replay, analytics or redistribution rights.
11. Do not claim zero loss, nanosecond precision, HFT, full market coverage,
    profitability or live readiness without a measured and independently
    reviewed evidence package.
12. Keep live order submission disabled. No code or CI task in this workspace
    authorizes it.
13. Each repository's own AGENTS/CONTRIBUTING/Git policy remains binding.
14. Report exact commits, commands, exits, test counts, skipped tests and
    unresolved gates. Never promote `Implemented` to `Verified` by wording.

15. Use `TOOL-MATRIX.md` for canonical versions and commands, `ADR-REGISTRY.md` and
    `NDC-REGISTRY.md` for identities, and `PAIRED-PR-CHECKLIST.md` for any cross-repository
    change. Run `make consistency` before paired work.
16. This repository contains no source code, no vendored checkouts and no build output.
    `fieldbook/` and `nirnay/` are local clones and are never committed here.
17. Do not force byte identity for files classified repository-local in `SHARED-FILES.md`.
18. Standardisation never weakens a gate, changes a test policy, or upgrades a tool beyond
    the shared pins without a paired, reviewed decision.

19. Adopt `engineering/style/DOCUMENTATION-STANDARD.md` for all cross-repository
    documentation: Markdown for human-maintained docs, rustdoc `///` and `//!` for Rust
    API/module contracts, `//` for implementation reasoning, `// SAFETY:` for unsafe
    justification, and Markdown ADRs for permanent decisions. Canonical language
    references: Rust rustdoc https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html
    and https://doc.rust-lang.org/reference/, C++ https://isocpp.org/ and
    https://en.cppreference.com/w/, Python 3 https://docs.python.org/3/, Bash
    https://www.gnu.org/software/bash/manual/. Fix tautologies, banned promotional or
    black-box terms, first-person pronouns and intent adverbs before running gates.
