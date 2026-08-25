# Attrset traversals

The functions under `sundry.attrs` traverse a root attrset and pass child paths as lists of exact attribute-name segments. The root is the traversal container: `halt`, `matches`, and `fn` receive its children, not the root itself.

## Terminal nodes

For every child value, a traversal evaluates `halt path value` before checking whether the value is an attrset:

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

## Predicate axes

The shape-preserving families have two independent predicate axes:

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

| family | result | terminal operation |
|---|---|---|
| [`walk`](../src/attrs/walk.nix) | attrset with the same paths | replace a value |
| [`collapse`](../src/attrs/collapse.nix) | list | map a terminal node to a list element |
| [`reform`](../src/attrs/reform.nix) | rebuilt attrset | move, replace, or omit a node |
| [`filter`](../src/attrs/filter.nix) | attrset subset | retain or omit a node at its current path |

`collapse` has only `collapse-until` and `collapse`. The `matches` contract leaves unmatched nodes unchanged, which requires an attrset-shaped result. An `attrs -> list` operation has no unchanged location in which to retain an unmatched node.

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
