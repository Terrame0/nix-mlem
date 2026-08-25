# Tag resolution

[`sundry.vfs.dir.resolve-tags`](../src/vfs/dir/resolve-tags.nix) converts annotations embedded in every original VFS path segment into a cleaned logical path and a `tag-list` on each leaf.

## Segment syntax

Each top-level `{...}` block declares one tag. The supported form contains zero or one `:`: text before it is the key, and comma-separated text after it is the value set.

| original segment | cleaned segment | tag-set entry |
|---|---|---|
| `A` | `A` | `{}` |
| `A{a}` | `A` | `{ a = ""; }` |
| `A{a:}` | `A` | `{ a = ""; }` |
| `A{a:1}` | `A` | `{ a = "1"; }` |
| `A{a:1,2}` | `A` | `{ a = ["1" "2"]; }` |
| `A{a:1}{b:2}` | `A` | `{ a = "1"; b = "2"; }` |

Multiple blocks in one segment are merged with `sundry.attrs.merge.no-collision`, so repeating a key in that segment throws. There is no escaping layer or grammar validation: use `{`, `}`, `:`, and `,` only as documented delimiters. An unsupported block with extra colons is not guaranteed to throw; the current parser can discard intermediate components.

The `=` segments used by [test fixtures](test-naming.md) are ordinary directory names, not part of this syntax.

## Path and `tag-list`

Every original segment contributes exactly one tag-set, including `{}` when the segment has no annotations. Entries remain in root-to-leaf order and include the leaf filename:

```nix
["={a:1}" "A" "B{b:2,3}"]
# cleaned path: ["=" "A" "B"]
# tag-list:    [{a = "1";} {} {b = ["2" "3"];}]
```

All annotation blocks are removed from each logical path segment. Existing leaf fields remain, so `origin` continues to name the original physical path with annotations.

`resolve-tags` rebuilds the cleaned tree through generic `attrs.reform`, so cleaned-path overlaps use structural `recursive.no-collision` rather than the VFS-aware `directories` resolver. Collision errors surface only when the relevant rebuilt fields are demanded. The exact overlap hazard and avoidance rule live in [gotchas.md](gotchas.md#reform-collision-handling-is-structural-not-vfs-aware).

Tag-aware functions consume `tag-list` according to [tag-matching.md](tag-matching.md). Run resolution once, before tag queries; see [gotchas.md](gotchas.md#resolve-tags-is-not-idempotent).
