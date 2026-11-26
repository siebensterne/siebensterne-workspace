# TODO

- Keep the three repositories independent; no shared crate, monorepo or source path.
- Keep toolchain and q-style gates byte-identical across Fieldbook and Nirnay.
- Keep bootstrap pins historical; never reset an existing checkout.
- Keep the consistency and package-review gates deterministic and read-only.
- Record each repository's current head only with the CI run that tested it.
- Keep provider rights UNKNOWN and collection disabled until owner authorization.
- Keep dataset acceptance blocked, experiments blocked and the data budget at zero.
- Keep the M4 holdout untouched and D11 retirements intact.
- Keep live execution disabled.
