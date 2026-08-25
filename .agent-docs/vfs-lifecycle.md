# VFS lifecycle

VFS operations transform trees of the node shapes defined in [data-model.md](data-model.md). They represent the logical VFS path separately from a leaf's physical `origin`.

## Constructors return trees

[`file.from-text`](../src/vfs/file/from-text.nix) and [`file.from-src`](../src/vfs/file/from-src.nix) return a one-file tree created with `lib.setAttrByPath`, not a bare leaf:

```nix
sundry.vfs.file.from-text ["A" "B.txt"] "contents"
# => { A."B.txt" = { text = "contents"; }; }
```

Both require a non-empty VFS path. `from-text` adds `text`; `from-src` reads the physical file and adds both `text` and `origin`. `from-src` stores its `fs-path` argument unchanged. A raw Nix path therefore produces a path-typed `origin`: the imported node remains a leaf because `text` is present, but that `origin` would not classify it as a leaf on its own. [`dir.from-src`](../src/vfs/dir/from-src.nix) imports every physical file below a directory at its relative VFS path and combines the one-file trees with `recursive.no-collision`.

## Transformation stages

| operation | input requirement | leaf fields after the operation |
|---|---|---|
| `file.from-text` | non-empty VFS path, string contents | `text` |
| `file.from-src` / `dir.from-src` | readable physical file or directory | `text`, `origin` |
| [`dir.resolve-tags`](../src/vfs/dir/resolve-tags.nix) | valid VFS tree | existing fields plus `tag-list`; logical paths are cleaned |
| [`dir.load-nix`](../src/vfs/dir/load-nix.nix) | `origin` when the import is demanded | existing fields plus `expr` |
| `dir.load-nix-with fn` | `origin` when `fn` demands the imported value | existing fields plus `expr = fn path file imported` |
| [`dir.materialize name`](../src/vfs/dir/materialize.nix) | string `text` on every consumed leaf | `text` removed, `origin` replaced with the new store path; other metadata preserved |

`resolve-tags` is explained in [tag-resolution.md](tag-resolution.md). Tag-aware selection and `*-within-tag` transformations require its `tag-list` field; they do not synthesize missing tags.

`load-nix` and `load-nix-with` visit every leaf regardless of its extension. Nix keeps `import file.origin` lazy, so a missing or invalid `origin` surfaces only when the callback or its stored `expr` demands the import. Select the intended files before loading when the tree also contains non-Nix files.

`materialize` returns two related values:

```text
{
  drv = derivation containing all materialized files and their parent directories;
  dir = VFS index whose leaf origins point inside drv;
}
```

Returning this attrset does not yet check every leaf. Demanding `result.drv`, or a materialized leaf `origin` that refers to it, deeply forces the collected `{ path, text }` records before constructing the derivation. Other metadata such as `expr` is preserved without being part of that materialization check.

Continue VFS transformations through `result.dir`; use `result.drv` when a build input needs the physical file tree. Materialization deliberately drops `text` so memory contents cannot drift from the materialized file. A materialized `dir` cannot be materialized again without restoring `text`.

## Traversal boundary

`sundry.vfs.dir.{walk, collapse, reform, filter, path-strs}` use `sundry.vfs.is-leaf-node` as the generic traversal `halt`. They recurse through directories, expose complete leaves to callbacks, and report demanded malformed children with their path. The root attrset remains the directory container and is not passed to `halt`.

See [attrs-traversal.md](attrs-traversal.md) for callback variants and the different strictness of `walk`, `collapse`, `reform`, and `filter`. Physical empty-directory behavior and structure-only validation are covered in [gotchas.md](gotchas.md).
