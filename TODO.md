# TODO

- Keep the three repositories independent; no shared crate, monorepo or source path.
- Keep toolchain and q-style gates byte-identical across Fieldbook and Nirnay.
- Keep bootstrap pins historical; never reset an existing checkout.
- Keep the consistency and package-review gates deterministic and read-only.
- Record each repository's current head only with the CI run that tested it; retain older runs only as historical evidence.
- Keep provider rights UNKNOWN and collection disabled until owner authorization.
- Keep dataset acceptance blocked, experiments blocked, market data blocked and the data budget at zero.
- Keep the EXP-M4-0001 synthetic holdout recorded as consumed once post-selection and do not reuse it; keep D11 retirements intact.
- Keep live execution disabled.
