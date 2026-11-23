# siebensterne documentation standard

Status: adopted 2026-11-24. Binding for newly added and changed lines in all three
repositories. Existing prose is improved progressively; this standard does not rewrite
historical dated evidence or approved contract bytes.

## 1. Editable sources

| Purpose | Format |
|---|---|
| Human-maintained project documentation | Markdown |
| Public Rust API contracts | rustdoc `///` |
| Crate and module contracts | rustdoc `//!` |
| Internal implementation reasoning | source comments `//` |
| Unsafe-code justification | `// SAFETY:` |
| Tracked annotations | `// TODO(owner):`, `// FIXME(owner):` |
| Permanent architecture decisions | Markdown ADR |
| Rendered handbook | mdBook (optional) |
| Unix CLI manuals | generated ROFF (only when needed) |
| Publication PDFs | Typst (optional) |

No competing source of documentation. Rustdoc documents what code exposes; Markdown
documents how the system works.

## 2. Official language documentation (binding references)

These URLs are the canonical external references for the listed languages. Local copies,
where a repository retains them, are verified against their reference indexes.

- Rust rustdoc: https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html
- Rust reference: https://doc.rust-lang.org/reference/
- C++: https://isocpp.org/ and https://en.cppreference.com/w/
- Python 3: https://docs.python.org/3/
- Bash: https://www.gnu.org/software/bash/manual/

Style guides remain separate from language references: Google style guides, Linux kernel
Rust guidelines and each repository's own checkers define binding style.

## 3. Comment rules

`///` — public structs, enums, functions, methods, traits, modules, constants, statics
and type aliases; document invariants, `# Errors`, `# Panics`, `# Safety` and examples
where they improve understanding. Important private items may use `///` for non-obvious
invariants.

`//!` — beginning of `lib.rs` / `mod.rs`; state the module's responsibility and
invariants.

`//` — why a decision exists, not a narration of the next line.

`// SAFETY:` — every `unsafe` block must name the actual invariant that makes it sound.

## 4. What must be documented

Contracts, invariants, assumptions and decisions: currency and quantity units,
timestamp semantics and time zones, event ordering, ownership and lifecycle,
serialization compatibility, numeric precision and rounding, replay and recovery
invariants, authorization boundaries, and error/failure semantics.

## 5. Enforcement

- Markdown: repo prose/style gates (tautology, banned terms, first-person pronouns,
  intent adverbs, line length, fenced-block language).
- Rust: `cargo fmt`, `clippy -D warnings`, rustdoc with `broken_intra_doc_links` denied,
  and doc tests.
- Python/Ruff/Pyink, Shell/ShellCheck, JSON/C++/Q: repo-specific checkers.

Missing-docs lints are introduced on public library crates after their current gaps are
reviewed; they are not silently promoted to errors before that review.

## 6. Sweep procedure

The deterministic order is: (1) run full-tree prose/style sweeps in every repository;
(2) fix every confirmed violation; (3) repeat the sweeps; (4) only then run the full gate
suite. No gate is weakened and no violation is whitelisted without a dated rationale.
