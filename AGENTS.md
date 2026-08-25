# sundry

A utility Nix library (`sundry.*`), assembled from files under `src/` where the file's directory path becomes its `sundry.*` namespace.

## Before working, read the relevant doc in `.agent-docs/`

- [data-model.md](.agent-docs/data-model.md) — the VFS node shapes (leaf vs. directory, `text`/`src`/`tag-list`) and path shapes (segment lists).
- [attrs-traversal.md](.agent-docs/attrs-traversal.md) — attrset traversal terminal-node semantics, the `halt`/`matches` axes, specialization matrix, and implementation dependencies.
- [attrs-merge.md](.agent-docs/attrs-merge.md) — attrset merge callback paths, resolver composition, and the VFS-aware `directories` resolver.
- [tag-matching.md](.agent-docs/tag-matching.md) — how a tag-spec queries a file's tags: per-key presence/value axes, value intersection, `[]` wildcard, merged-set membership vs. per-level position, and negation via `boolean.expr`.
- [module-layout.md](.agent-docs/module-layout.md) — where a file goes, how it maps to `sundry.*`, and when to split code vs. keep it together.
- [authoring.md](.agent-docs/authoring.md) — how to build a function: compose existing primitives, keep pipe chains visible, derive related conditions from one condition, prefer the simplest model, and use few units.
- [testing.md](.agent-docs/testing.md) — test format (`tests = [ [ actual expected ] ]`) and running tests with `bash eval-result.sh`.
- [test-naming.md](.agent-docs/test-naming.md) — naming conventions for test fixtures.

When you add, rename, or remove a doc under `.agent-docs/`, update this index in the same change so it does not drift from what's on disk.
