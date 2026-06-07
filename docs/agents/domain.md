# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- `CONTEXT.md` at the repo root, if present.
- `docs/adr/`, if present. Read ADRs that touch the area you're about to work in.

If these files do not exist, proceed silently. Do not suggest creating them upfront; producer skills create them lazily when terms or decisions actually get resolved.

## File structure

This is a single-context repo:

```text
/
├── CONTEXT.md
├── docs/adr/
└── lua/
```

## Use the glossary's vocabulary

When output names a domain concept, use the term as defined in `CONTEXT.md`. Avoid drifting to synonyms the glossary explicitly avoids.

If a needed concept is missing from the glossary, note it as a candidate for `/grill-with-docs` rather than inventing project language casually.

## Flag ADR conflicts

If output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 — but worth reopening because..._
