# sundry

A utility Nix library (`sundry.*`), assembled from files under `src/` (the file's directory path becomes its `sundry.*` namespace).

## Before working, read the relevant doc in `.agent-docs/`

- [data-model.md](.agent-docs/data-model.md) — the VFS node (leaf vs. directory, `text`/`src`/`tag-list`) and path (segment list) shapes.
- [tag-matching.md](.agent-docs/tag-matching.md) — how a tag-spec queries a file's tags: per-key presence/value axes (value intersection, `[]` wildcard), merged-set membership vs. per-level position, negation via boolean.expr.
- [module-layout.md](.agent-docs/module-layout.md) — where a file goes, how it maps to `sundry.*`, when to split vs. keep together.
- [authoring.md](.agent-docs/authoring.md) — how to build a function: compose existing primitives, pipe visible chains, one condition derive the rest, simplest model, few units.
- [testing.md](.agent-docs/testing.md) — test format (`tests = [ [ actual expected ] ]`), run with `bash eval-result.sh`.
- [test-naming.md](.agent-docs/test-naming.md) — naming conventions for test fixtures.
- [docs-style.md](.agent-docs/docs-style.md) — how to write the docs themselves.

When you add, rename, or remove a doc under `.agent-docs/`, update this index — and the import list below — in the same change so neither drifts from what's on disk.

@.agent-docs/data-model.md
@.agent-docs/tag-matching.md
@.agent-docs/module-layout.md
@.agent-docs/authoring.md
@.agent-docs/testing.md
@.agent-docs/test-naming.md
