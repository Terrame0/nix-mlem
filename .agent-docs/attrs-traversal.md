# Attrset traversals

The functions under `sundry.attrs` traverse a root attrset and pass child paths as lists of exact attribute-name segments. The root is the traversal container: `halt`, `matches`, and `fn` receive its children, not the root itself.

## Terminal nodes

For every child that a traversal visits, it evaluates `halt path value` before checking whether the value is an attrset:

```nix
if !(halt path value) && lib.isAttrs value
then recurse path value
else consume path value
```

The two checks have separate roles:

| check | role |
|---|---|
| `halt path value` | semantic classification or validation; `true` makes the value terminal |
| `lib.isAttrs value` | structural recursion guard; only an attrset can be traversed |

A non-attrset remains a normal terminal value when `halt` returns `false`. A domain-specific `halt` may reject it instead. The VFS traversals pass [`sundry.vfs.is-leaf-node`](../src/vfs/node-cond.nix), which returns `true` for a leaf, returns `false` for a directory, and throws for every other value.

Evaluation strictness differs by family:

| family | what evaluating the result forces |
|---|---|
| `walk` | only demanded attrset branches; reading `result.A` need not visit sibling `B` |
| `collapse` | the complete traversal structure, because `concatLists` must flatten every emitted sublist; callback element values remain lazy |
| `reform` | the collapse structure and callback results far enough to validate and rebuild their paths; nested fields of emitted values can remain lazy |
| `filter` | the collapse structure and each terminal predicate needed to decide omission; retained payload fields can remain lazy |

[`does-throw`](testing.md#does-throw-does-not-catch-everything) uses `deepSeq` when a test needs every produced value forced in addition to the traversal structure.

## Predicate axes

The `walk`, `reform`, and `filter` families have two independent predicate axes:

| predicate | effect |
|---|---|
| `halt path value` | stops descent and exposes the current value as a terminal node |
| `matches path value` | applies `fn` to a terminal node when true; an unmatched node stays at its original path with its original value |

This produces four variants:

| variant | `matches` | `halt` |
|---|---|---|
| `*-matched-until matches halt fn` | caller-supplied | caller-supplied |
| `*-until halt fn` | always true | caller-supplied |
| `*-matched matches fn` | caller-supplied | always false |
| `* fn` | always true | always false |

## Families

| family | callback result | traversal result |
|---|---|---|
| [`walk`](../src/attrs/walk.nix) | replacement value | attrset with each selected terminal replaced in place |
| [`collapse`](../src/attrs/collapse.nix) | list element | flat list |
| [`reform`](../src/attrs/reform.nix) | attrset with required `path` and `value`, plus optional `omit` | attrset rebuilt from emitted fragments |
| [`filter`](../src/attrs/filter.nix) | boolean: retain when true | attrset subset at the original paths |

`collapse` has only `collapse-until` and `collapse`. The `matches` contract leaves unmatched nodes unchanged, which requires an attrset-shaped result. An `attrs -> list` operation has no unchanged location in which to retain an unmatched node.

`reform` validates that `path` is a list of strings, requires `value`, treats missing `omit` as `false`, requires `omit` to be a boolean, and rejects other result fields. It combines non-omitted fragments with `sundry.attrs.merge.recursive.no-collision`; attrset fragments can therefore combine recursively, while a collision between terminal fields throws.

`collapse` emits terminals depth-first. Sibling keys follow Nix's lexicographic attribute-name order, so its output list has a deterministic path order.

## Implementation dependencies

```text
walk-matched-until
├── walk-until
├── walk-matched
└── walk

collapse-until
├── collapse
└── reform-matched-until
    ├── reform-until
    ├── reform-matched
    ├── reform
    └── filter-matched-until
        ├── filter-until
        ├── filter-matched
        └── filter
```

`walk-matched-until` and `collapse-until` are the two recursive implementations. `reform` rebuilds the terminal nodes emitted by `collapse-until`; `filter` specializes `reform` by converting its predicate result into the `omit` field.

The VFS traversal families specialize `halt` to `sundry.vfs.is-leaf-node`. [`path-strs`](../src/vfs/dir/path-strs.nix) and [`materialize`](../src/vfs/dir/materialize.nix) also consume `collapse-until`, while [`resolve-tags`](../src/vfs/dir/resolve-tags.nix) consumes `reform-until`.
