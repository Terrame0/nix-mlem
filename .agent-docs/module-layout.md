# Module layout

How files under `src/` are organized and how that organization maps to the public `sundry.*` namespace.

## File path = namespace path

The framework ([core/glob-functions.nix](../../core/glob-functions.nix)) walks every `.nix` file under `src/` and exposes its attributes (minus `tests`) at `sundry.<dirname>`, where `<dirname>` is the file's directory relative to `src/`. The filename itself is dropped.

| File | Exports at | Function ends up at |
|---|---|---|
| `src/vfs/dir/reform.nix` | `sundry.vfs.dir` | `sundry.vfs.dir.reform` |
| `src/vfs/dir/filter.nix` | `sundry.vfs.dir` | `sundry.vfs.dir.filter`, `sundry.vfs.dir.filter-within-tag` |
| `src/vfs/dir/select.nix` | `sundry.vfs.dir` | `sundry.vfs.dir.select-by-tag` |
| `src/vfs/file/get-tag-pos.nix` | `sundry.vfs.file` | `sundry.vfs.file.get-tag-pos` |
| `src/boolean/operands/tag.nix` | `sundry.boolean.operands` | `sundry.boolean.operands.tag` |
| `src/vfs/tag/faceted-match.nix` | `sundry.vfs.tag` | `sundry.vfs.tag.faceted-match` |
| `src/list/permutations.nix` | `sundry.list` | `sundry.list.permutations` |

Pick the filename to match what's inside: a single function gets the function's name; a cohesive cluster gets a name describing the cluster.

## When to split, when to keep together

The criterion is cohesion, not file count. Keep things together when they're uniform — same input shape, same return shape, same test fixture, same conceptual domain. Reading the file should require holding **one** mental model. Split when it requires two.

Cohesive clusters that live in one file:

- [src/vfs/path/getters.nix](../../src/vfs/path/getters.nix) — `get.{name, stem, ext, str}`, facets of one object.
- [src/vfs/path/setters.nix](../../src/vfs/path/setters.nix) — `set.{name, stem, ext}`, the mirror of `get`; reuses the getters to round-trip a path's name.
- [src/list/accessors.nix](../../src/list/accessors.nix) — `at`, `incl-init`/`incl-tail`, `excl-last`/`excl-head`; list-edge accessors, same shape.
- [src/str/find-after.nix](../../src/str/find-after.nix) — `find-after` and `rfind-after`, mirror functions.
- [src/str/trim.nix](../../src/str/trim.nix) — `trim`, `trim-left`, `trim-right`, same shape.
- [src/attrs/compare.nix](../../src/attrs/compare.nix) — `compare` and `compare-until` (the latter is a generalization).

Cases that earned a split:

- `src/vfs/dir/transforms.nix` (since removed) bundled `reform`, `filter`, `collapse`, `walk` with four different test fixtures in one `tests` block. Now: [reform.nix](../../src/vfs/dir/reform.nix), [filter.nix](../../src/vfs/dir/filter.nix), [collapse.nix](../../src/vfs/dir/collapse.nix), [walk.nix](../../src/vfs/dir/walk.nix).

The split usually pays off when the test block, not the function block, is what's making the file hard to read.

## Where helpers live

A helper goes in the namespace whose domain it operates on, not in the namespace that happens to call it. [src/vfs/file/get-tag-pos.nix](../../src/vfs/file/get-tag-pos.nix) walks a file's `tag-list`, so it lives in `vfs/file/` next to the node fields it reads — not wherever it happens to be called from. [src/vfs/tag/faceted-match.nix](../../src/vfs/tag/faceted-match.nix) is consumed only by the [`tag`](../../src/boolean/operands/tag.nix) boolean operand, yet lives in `vfs/tag/`, not `boolean/` — it is *about* a tag-set matched against a tag-spec, and knows nothing about boolean expressions. Co-locating with the data type beats co-locating with the consumer.

The domain is the side of the signature the function is *about*, not the argument or return type mechanically. [src/vfs/path/from-str.nix](../../src/vfs/path/from-str.nix) (`string → path`) and `get.str` (`path → string`) both live in `vfs/path/`, though one takes and the other returns a plain string — `path` is what each is about, `string` is just raw material. By contrast [src/str/to-segments.nix](../../src/str/to-segments.nix) (empty-aware split, `sep → string → [string]`) knows nothing about paths, so it lives in `str/`; `from-str` reuses it and adds the path-specific `/` and trim. Ask "what type is this *about*?" — not "what type is in the signature?".

## Renaming / restructuring

A split or move usually shifts the public namespace. Check call sites with `grep -rn` first; internal-only callers update in the same commit, external consumers need a deprecation path.
