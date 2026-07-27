# VFS data model

The two shapes everything under `sundry.vfs` operates on: the **node tree** and the **path**.

## Node

A node is an attrset — either a **leaf** (a file) or a **directory** (a subtree). Classified in [src/vfs/node-cond.nix](../../src/vfs/node-cond.nix):

| predicate | returns |
|---|---|
| `is-leaf path node` | `true` when the node has a string `text` or a string-or-derivation `origin` |
| `is-dir path node` | `true` when every value is an attrset (so `{}` is a directory) |
| `is-leaf-node path node` | `true` for a leaf, `false` for a directory, **throws** otherwise — this is the `cond` the traversals use |

Leaf fields:

| field | type | meaning |
|---|---|---|
| `text` | string | file contents, in memory |
| `origin` | string \| derivation | the file's **last physical location on disk** — the import path after [from-src](../../src/vfs/file/from-src.nix), the store path after [materialize](../../src/vfs/dir/materialize.nix). Tracks provenance across transforms independently of the node's key path; survives `resolve-tags` stripping (so it carries the original tagged path even once the key is cleaned). |
| `tag-list` | list of attrsets | per directory-level tags parsed from the filename — one attrset per path segment — present after `resolve-tags`; queried per [tag-matching.md](tag-matching.md) (fixture naming: [test-naming.md](test-naming.md)) |

A directory maps a path segment to a child node:

```nix
{
  "A.txt" = { text = "contents of A.txt"; origin = "/…/A.txt"; };  # imported: in memory + on disk
  "B.css" = { origin = "/nix/store/…-dir/B.css"; };               # materialized: store path only
  sub = { "C.txt" = { text = "…"; }; };        # directory: key = segment, value = node
}
```

`text` and `origin` are **not** mutually exclusive across a node's life — they exclude only as a state transition:

- **Imported** ([from-src](../../src/vfs/file/from-src.nix)) — the leaf carries **both** `text` (read into memory) and `origin` (where it was read from).
- **Materialized** ([materialize](../../src/vfs/dir/materialize.nix)) — `text` is **dropped** and `origin` is overwritten with the new store path, so the materialized leaf carries `origin` alone. Dropping `text` removes any chance of it drifting from the file on disk; to get in-memory contents back, re-import. Materialize is the final step in a pipeline, so overwriting the import path with the store path loses nothing still needed.

## Path

A path is a **list of segments**, not a string; the last segment is the file name.

```nix
["A" "B" "C.txt"]
```

File constructors require a non-empty path. An empty path has no file-name segment and would create a leaf at the tree root, which is not a valid VFS node shape.

Conversions: [from-str](../../src/vfs/path/from-str.nix) (`"A/B/C.txt"` → `["A" "B" "C.txt"]`) and `get.str` (`["A" "B"]` → `"A/B"`).

Accessors mirror as getters ([getters.nix](../../src/vfs/path/getters.nix)) and setters ([setters.nix](../../src/vfs/path/setters.nix)); all take the path last so they compose in a pipe:

| getter | result on `["A" "C.txt"]` | setter | effect |
|---|---|---|---|
| `get.name` | `"C.txt"` | `set.name "x"` | replace the last segment |
| `get.stem` | `"C"` | `set.stem "x"` | replace the stem, keep the ext |
| `get.ext` | `"txt"` (or `""`) | `set.ext "x"` | replace the ext (`""` drops it) |

Stem/ext split on `.` with the **last** component as the ext: `archive.tar.gz` → stem `archive.tar`, ext `gz`.

## Traversals

`sundry.vfs.dir.{walk, collapse, reform, filter, materialize, path-strs}` recurse while a node is a directory and stop at leaves, using `is-leaf-node` as the `cond`. A malformed node (neither leaf nor directory) throws with its path instead of overflowing the stack.
