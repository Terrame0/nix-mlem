# sundry

A utility Nix library (`sundry.*`), assembled from files under `src/` where the file's directory path becomes its `sundry.*` namespace.

## Before working, read the relevant doc in `.agent-docs/`

- [data-model.md](.agent-docs/data-model.md) — the VFS node shapes (leaf vs. directory, `text`/`origin`/`tag-list`) and path shapes (segment lists).
- [vfs-lifecycle.md](.agent-docs/vfs-lifecycle.md) — VFS constructors and the import, tag-resolution, Nix-loading, and materialization stages.
- [tag-resolution.md](.agent-docs/tag-resolution.md) — how `{key:value}` annotations in path segments become cleaned paths and per-segment `tag-list` entries.
- [tag-matching.md](.agent-docs/tag-matching.md) — tag-spec query semantics, including `tag` concatenation, `deepest-tag` override, per-level position, and `boolean.expr` binding.
- [attrs-traversal.md](.agent-docs/attrs-traversal.md) — attrset traversal terminal-node semantics, the `halt`/`matches` axes, specialization matrix, and implementation dependencies.
- [attrs-merge.md](.agent-docs/attrs-merge.md) — attrset merge callback paths, resolver composition, and the VFS-aware `directories` resolver.
- [attrs-validation.md](.agent-docs/attrs-validation.md) — asymmetric attrset comparison and the template DSL used by `attrs.validate`.
- [dependency-resolution.md](.agent-docs/dependency-resolution.md) — topological layers and lazy assembly of named transform results from declared dependencies.
- [module-layout.md](.agent-docs/module-layout.md) — where a file goes, how it maps to `sundry.*`, and when to split code vs. keep it together.
- [authoring.md](.agent-docs/authoring.md) — how to build a function: compose existing primitives, keep pipe chains visible, derive related conditions from one condition, prefer the simplest model, and use few units.
- [testing.md](.agent-docs/testing.md) — test format (`tests = [ [ actual expected ] ]`) and running tests with `bash eval-result.sh`.
- [test-naming.md](.agent-docs/test-naming.md) — naming conventions for test fixtures.
- [gotchas.md](.agent-docs/gotchas.md) — counter-intuitive lazy evaluation, empty-branch, reform-collision, and repeated tag-resolution behavior.

When you add, rename, or remove a doc under `.agent-docs/`, update this index in the same change so it does not drift from what's on disk.
