# VFS data model

The two shapes everything under `sundry.vfs` operates on: the **node tree** and the **path**.

## Node

A valid node is an attrset — either a **leaf** (a file) or a **directory** (a subtree). Classified in [src/vfs/node-cond.nix](../src/vfs/node-cond.nix):

| predicate | returns |
|---|---|
| `is-leaf path node` | `true` when the node has a string `text` or a string-or-derivation `origin` |
| `is-dir path node` | `true` when the node is not a leaf and every value is an attrset (so `{}` is a directory) |
| `is-leaf-node path node` | `true` for a leaf, `false` for a directory, **throws** for a non-attrset or malformed attrset — this is the `halt` predicate the traversals use |

Leaf fields:

| field | type | meaning |
|---|---|---|
| `text` | string | file contents, in memory |
| `origin` | string \| derivation | the file's last physical location; tracks provenance independently of the node's key path |
| `tag-list` | list of attrsets | root-to-leaf tags, exactly one attrset per original path segment after `resolve-tags` |
| `expr` | any Nix value | lazy imported or derived payload attached by `load-nix` / `load-nix-with` |

Leaf recognition takes precedence over every other field. Once `text` or `origin` has a valid leaf type, the complete attrset is terminal and traversal does not inspect any child-shaped metadata inside it. This keeps a lazy `expr` payload from being forced. `expr` itself is not a discriminator: an attrset-valued expression must remain distinguishable from a directory containing a child segment named `expr`.

A directory maps a path segment to a child node:

```nix
{
  "A.txt" = { text = "contents of A.txt"; origin = "/…/A.txt"; };
  "B.css" = { origin = "/nix/store/…-dir/B.css"; };
  "C.nix" = { text = "v: v + 1"; origin = "/…/C.nix"; expr = v: v + 1; };
  sub = { "C.txt" = { text = "…"; }; };
}
```

Without a valid leaf discriminator, every value must itself be an attrset for the node to be a directory. Consequently `{}` is a directory, `{ text = {}; }` is a directory containing an empty child directory under the segment `text`, and `{ unexpected = 1; }` is malformed. `is-leaf-node` reports malformed nodes with their VFS path.

Field-producing transformations and their preconditions are documented in [vfs-lifecycle.md](vfs-lifecycle.md). The construction of `tag-list` is documented separately in [tag-resolution.md](tag-resolution.md), and its query semantics live in [tag-matching.md](tag-matching.md).

## Path

A path is a **list of segments**, not a string; the last segment is the file name.

```nix
["A" "B" "C.txt"]
```

Conversions: [from-str](../src/vfs/path/from-str.nix) (`"A/B/C.txt"` → `["A" "B" "C.txt"]`) and `get.str` (`["A" "B"]` → `"A/B"`).

Accessors mirror as getters ([getters.nix](../src/vfs/path/getters.nix)) and setters ([setters.nix](../src/vfs/path/setters.nix)); all take the path last so they compose in a pipe:

| getter | result on `["A" "C.txt"]` | setter | effect |
|---|---|---|---|
| `get.name` | `"C.txt"` | `set.name "x"` | replace the last segment |
| `get.stem` | `"C"` | `set.stem "x"` | replace the stem, keep the ext |
| `get.ext` | `"txt"` (or `""`) | `set.ext "x"` | replace the ext (`""` drops it) |

Stem/ext split on `.` with the **last** component as the ext: `archive.tar.gz` → stem `archive.tar`, ext `gz`.

The tree root is always a directory container, never a leaf at `[]`. File constructors therefore require a non-empty path. VFS directory traversals specialize the generic contract from [attrs-traversal.md](attrs-traversal.md) with `is-leaf-node` as `halt`.
