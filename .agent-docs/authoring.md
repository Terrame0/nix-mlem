# Authoring functions

How to *build* a function, once [module-layout.md](module-layout.md) has told you where it lives. These are the implementation habits that keep `sundry.*` small and composable.

## Compose existing `sundry` primitives before hand-rolling

Before writing code that splits, diffs, merges, or loops over a structure, look for a `sundry.*` function that already does it. The library is meant to be composed against itself.

`compare` returns `{ matched, missing, extra }` for two attrsets, so a whole tag-set predicate is two conditions over its output — the [`tag`](../../src/boolean/operands/tag.nix) operand. Reach for [compare](../../src/attrs/compare.nix), [merge](../../src/attrs/merge-fns.nix), [switch](../../src/switch.nix), [range](../../src/range.nix), [list.contains](../../src/list/contains.nix), [list.intersect](../../src/list/intersect.nix) instead of re-deriving them inline.

A pile of small single-use `let` helpers that filter/index/diff a structure is the usual tell that a primitive is being rebuilt by hand.

## Pipe a visible chain

When a value flows through more than one call, write it as a `lib.pipe`, not nested application. Nested calls read inside-out and make the reader match parentheses; a pipe reads top-to-bottom in evaluation order. The bar is low — two nested calls, each with its own arguments, already justify it.

[resolve-tags.nix](../../src/vfs/dir/resolve-tags.nix), [validate.nix](../../src/attrs/validate.nix), and [str/trim.nix](../../src/str/trim.nix) all chain this way instead of nesting calls inside-out.

## One condition, derive the rest

When two functions ask the same question in different shapes — "does it hold?" vs. "where does it hold?" — write the predicate once and derive the others from it.

[src/vfs/file/get-tag-pos.nix](../../src/vfs/file/get-tag-pos.nix) is `findFirst` over [boolean.expr](../../src/boolean/expr.nix): the position is the index where the expr first holds, sharing the [`tag`](../../src/boolean/operands/tag.nix) operand with [filter-within-tag](../../src/vfs/dir/filter.nix) rather than keeping a second copy of the matching logic.

The codebase has a naming convention for the general/specialized split: the fully parameterized function takes a `-base` suffix (kept private in `let`) or a `-matched-until` / `-until` suffix (public, exposing the predicate and/or the stop condition), and the everyday function is that base with the common arguments pre-applied. [trim-left / trim-right](../../src/str/trim.nix) are `trim-base` with the has/remove fns fixed; [compare / compare-until](../../src/attrs/compare.nix) fix or expose the condition. The attrset traversal variants and their predicate contracts are documented in [attrs-traversal.md](attrs-traversal.md). Write the general function and derive its specializations by partial application or argument composition — never copy the body.

Forking the logic per consumer — a separate predicate for filtering and another for positioning — is the anti-pattern: the two copies drift.

## Pick the simplest model the real call sites need

Implement the one model the actual callers require; don't branch for speculative edge semantics (spread vs. joint keys, a sentinel for an undefined case). The [`tag`](../../src/boolean/operands/tag.nix) operand matches a query against a single tag-set — one rule applied uniformly. Where a real distinction *does* surface — universal vs. existential matching across a file's levels — it is resolved by the caller's quantifier ([filter-within-tag](../../src/vfs/dir/filter.nix) matches the merged set, [get-tag-pos](../../src/vfs/file/get-tag-pos.nix) walks levels), not by a branch inside the predicate. See [tag-matching.md](tag-matching.md).

This is [testing.md](testing.md)'s "don't invent exotica" applied to implementation, not just tests: an edge case earns a code branch only when a caller exercises it.

## Few meaningful units, not many fragments

Prefer a small number of named pieces at a meaningful altitude over many one-line fragments. Helper count is a smell, not a virtue — a large `let` block usually traces back to the first rule (a primitive rebuilt by hand) or to one idea split across several bindings.

Whether a helper that *does* survive belongs in this namespace is a separate question — [module-layout.md](module-layout.md) covers it.
