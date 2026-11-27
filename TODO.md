# TODO

- Keep the three repositories independent; no shared crate, monorepo or source path.
- Keep toolchain and q-style gates byte-identical across Fieldbook and Nirnay.
- Keep bootstrap pins historical; never reset an existing checkout.
- Keep the consistency and package-review gates deterministic and read-only.
- Record each repository's current head only with the CI run that tested it; keep one canonical `ci_evidence` table with exact head SHA, attempt, event, conclusion and GitHub URL, and retain superseded runs only in `historical_ci`.
- Keep provider rights UNKNOWN and collection disabled until owner authorization.
- Keep dataset acceptance blocked, experiments blocked, market data blocked and the data budget at zero.
- Keep the EXP-M4-0001 synthetic holdout recorded as consumed once post-selection and do not reuse it; keep D11 retirements intact.
- Keep synthetic market-shaped paper replays out of the required gate under D11; no fixture amendment or admitted dataset exists, so G4/G5 stay BLOCKED and no paper-engine replay claim is made.
- Keep live execution disabled.
- Keep the e2e paper path fail-closed: exact heads and clean trees, typed rights refusal, deterministic opaque neutral adapter output, and no cross-repository claim beyond the rights-refused fixture.
- Keep release gates G0-G10 and deployment qualification machine-readable; G6 closes only for the neutral, rights-refused fixture via the digest-bound adapter, while G4/G5 and G9 stay BLOCKED until an approved fixture or owner-run deployment qualification and operator authorization exist.
- Keep the workspace record unable to attest its own final commit; the detached post-merge release attestation is the authority for final Workspace CI runs.
- Keep review evidence as self-review plus independent delegated review; never claim GitHub approvals or invent reviewer identities.
