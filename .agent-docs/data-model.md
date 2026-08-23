# VFS data model

The two shapes everything under `sundry.vfs` operates on: the **node tree** and the **path**.

## Node

A node is an attrset — either a **leaf** (a file) or a **directory** (a subtree). Classified in [src/vfs/node-cond.nix](../../src/vfs/node-cond.nix):

| predicate | returns |
|---|---|
| `is-leaf path node` | `true` when the node has a string `text` or a string-or-derivation `origin` |
| `is-dir path node` | `true` when the node is not a leaf and every value is an attrset (so `{}` is a directory) |
| `is-leaf-node path node` | `true` for a leaf, `false` for a directory, **throws** otherwise — this is the `cond` the traversals use |

Leaf fields:

| field | type | meaning |
|---|---|---|
| `text` | string | file contents, in memory |
| `origin` | string \| derivation | the file's **last physical location on disk** — the import path after [from-src](../../src/vfs/file/from-src.nix), the store path after [materialize](../../src/vfs/dir/materialize.nix). Tracks provenance across transforms independently of the node's key path; survives `resolve-tags` stripping (so it carries the original tagged path even once the key is cleaned). |
| `tag-list` | list of attrsets | per directory-level tags parsed from the filename — one attrset per path segment — present after `resolve-tags`; queried per [tag-matching.md](tag-matching.md) (fixture naming: [test-naming.md](test-naming.md)) |
| `expr` | any Nix value | lazy result attached by [load-nix](../../src/vfs/dir/load-nix.nix); `load-nix-with` stores the callback result instead |

`expr` is payload, not a leaf discriminator. A loaded leaf retains `text` or `origin`, which identifies it as a file without forcing `expr`. Treating the presence of `expr` alone as a leaf marker would make an expression whose value is an attrset indistinguishable from a directory named `expr`.

A directory maps a path segment to a child node:

```nix
{
  "A.txt" = { text = "contents of A.txt"; origin = "/…/A.txt"; };  # imported: in memory + on disk
  "B.css" = { origin = "/nix/store/…-dir/B.css"; };               # materialized: store path only
  "C.nix" = { text = "v: v + 1"; origin = "/…/C.nix"; expr = v: v + 1; };
  sub = { "C.txt" = { text = "…"; }; };        # directory: key = segment, value = node
}
```

`text` and `origin` are **not** mutually exclusive across a node's life — they exclude only as a state transition:

- **Imported** ([from-src](../../src/vfs/file/from-src.nix)) — the leaf carries **both** `text` (read into memory) and `origin` (where it was read from).
- **Nix-loaded** ([load-nix](../../src/vfs/dir/load-nix.nix)) — retains the existing leaf fields and adds lazy `expr`. `load-nix-with fn` calls `fn path file expr` and stores its result in that field. Both functions require `origin`, operate on every input leaf regardless of extension, and leave file selection to the caller.
- **Materialized** ([materialize](../../src/vfs/dir/materialize.nix)) — returns `{ drv, dir }`. `dir` is the evaluation-time VFS index; `drv` is the build-time materialization of that index. In `dir`, `text` is **dropped** and `origin` is overwritten with the new store path, so of those two fields each materialized leaf carries `origin` alone. Dropping `text` removes any chance of it drifting from the file on disk; to get in-memory contents back, re-import. The top-level `drv` is the whole materialized directory as a Nix build artifact, while each leaf `origin` is the concrete file path inside it.

`materialize` preserves optional metadata, including `tag-list` and `expr`. Remove derived fields before materialization when they must not outlive the source state from which they were computed.

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

`sundry.vfs.dir.{walk, collapse, reform, filter, path-strs}` recurse while a node is a directory and stop at leaves, using `is-leaf-node` as the `cond`. A malformed node (neither leaf nor directory) throws with its path instead of overflowing the stack.

`sundry.vfs.dir.materialize` consumes a VFS directory and returns `{ drv, dir }`: keep piping through `result.dir` for more VFS directory operations, or use `result.drv` when a Nix derivation for the whole materialized directory is needed.
