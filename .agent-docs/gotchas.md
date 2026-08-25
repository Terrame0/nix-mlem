# Gotchas

These are counter-intuitive mechanics that can silently invalidate an otherwise plausible change.

## Traversal strictness depends on the family

Rule: distinguish structural traversal from forcing the values produced by callbacks.

Why: `walk` is branch-lazy, while evaluating `collapse`, `reform`, or `filter` forces their complete traversal structure. Nested replacement values and leaf payload fields can remain lazy in every family. [attrs-traversal.md](attrs-traversal.md#terminal-nodes) gives the exact boundaries.

Avoid it: use [`sundry.does-throw`](testing.md#does-throw-does-not-catch-everything) when the question is whether the **entire result, including payload**, evaluates. For VFS structure-only validation without forcing lazy `expr`, deeply force a payload-free projection such as `sundry.vfs.dir.path-strs tree` or `sundry.vfs.dir.collapse (_: _: null) tree`.

## Rebuilding traversals lose traversable empty attrsets

Rule: do not use `collapse`, `reform`, or `filter` when an unhalted empty attrset must survive as a structural node.

Why: recursive `collapse` emits no terminal for `{}`. `reform` and `filter` rebuild their result from those emitted terminals, so they also lose that branch. `walk` maps the existing shape and preserves it. In VFS, `{}` is a valid empty directory, making this difference observable.

Avoid it: use `walk`, make the empty attrset terminal through `halt`, or restore required empty branches explicitly.

The physical VFS roundtrip is file-oriented too: `dir.from-src` discovers files, not empty directories, and `materialize.drv` creates only parents needed by files. `materialize.dir` preserves an existing empty branch through `walk`, but that branch has no directory in the derivation.

## `reform` collision handling is structural, not VFS-aware

Rule: do not assume overlapping target paths from `reform` produce a clean VFS collision error.

Why: reform fragments are combined with `recursive.no-collision`. Two attrset fragments recurse and can combine before terminal fields collide. A valid leaf discriminator then takes precedence over the merged directory fields, so a leaf can silently hide a subtree rather than fail validation.

Avoid it: detect incompatible terminal overlaps before rebuilding. For VFS, do not emit two leaves at one target or make a leaf target the ancestor of another emitted path. Shared directory prefixes are safe. A later VFS traversal catches malformed rebuilt nodes, but cannot detect a hidden subtree once `text` or `origin` makes the combined attrset a valid leaf.

## `directories` validates collisions only

Rule: use a separate traversal when complete input-tree validation is required.

Why: merge resolvers run only where two inputs contain the same key. A unique malformed branch passes through `sundry.attrs.merge.directories.*` unchanged.

Avoid it: deeply force `sundry.vfs.dir.path-strs tree` or `sundry.vfs.dir.collapse (_: _: null) tree` when validation outside merge-relevant collisions matters. These projections validate node structure without forcing leaf payload such as `expr`.

## `resolve-tags` is not idempotent

Rule: resolve annotations once, before tag-aware operations.

Why: the first pass removes annotation blocks from logical path segments and records them in `tag-list`. A second pass reads the cleaned names and overwrites every leaf's useful list with empty tag-sets.

Avoid it: retain the already-resolved tree instead of calling `resolve-tags` again.
