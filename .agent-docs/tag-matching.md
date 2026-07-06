# Tag matching

How a **tag-spec** queries a file's tags. The tag shape itself — `tag-list`, a per-path-level list of tag attrsets — lives in [data-model.md](data-model.md); this doc is the query semantics over it.

## A spec matches one tag-set: presence and value

[`sundry.vfs.tag.faceted-match`](../../src/vfs/tag/faceted-match.nix) takes a `tag-set` (one `{ key = value; }` attrset) and a `tag-spec`, returning a bool — the per-set predicate every tag operand is built from. Every key in the spec must be **present** in the tag-set; its value entry then says which values count as a match:

| spec entry | the tag-set passes when |
|---|---|
| `key = "1"` or `key = ["1" "2"]` | `key` present **and** values intersect (`∩ ≠ ∅`) |
| `key = []` | `key` present, any value (wildcard) |

Keys combine with **AND** across the spec. Within one key the value list combines with **OR** (hit at least one). Every key still requires presence regardless of its value list. This is faceted-filter semantics: AND across facets, OR within a facet.

Value matching is set **intersection** ([list.intersect](../../src/list/intersect.nix)), not subset: a file tag `hosts = ["desktop" "laptop"]` matches `hosts = "desktop"` because they overlap. Value terms are *additive* — more file values never drop a match. Negation — forbidding a value or requiring a key **absent** — is expressed at the expression level via [boolean.expr](../../src/boolean/expr.nix), not inside the spec: `!(tag { key = []; })` matches when `key` is absent.

## Over levels: which quantifier the operand applies

`tag-list` is a *list* of tag-sets (one per path level); `faceted-match` decides a single set. How that single-set predicate lifts over the levels is fixed by **which operand** you use over the bound `tag-list` — never by a branch inside `faceted-match`, which stays uniform. Every operand is bound the whole `tag-list`; the operand, not the caller, folds it to the set it tests.

**Membership — the [`tag`](../../src/boolean/operands/tag.nix) operand** matches `faceted-match` against the **merged** set (`sundry.attrs.merge.concat tag-list`, a lossless union of every level's tags). Callers like [select-by-tag](../../src/vfs/dir/select.nix) bind the whole `tag-list` and let the operand merge:

```nix
select-by-tag (e: e.tag { b = "1"; }) dir      # file kept iff the merged set matches
```

Merging makes the quantifier fall out right: a value match is **existential** over levels (the value appears at *some* level). Negation over the merged set is therefore **universal** — `!(tag { b = []; })` holds when `b` is on *no* level. Matching per level with `lib.any` instead would let that pass any file with even one level lacking `b` — the bug this design avoids.

**Override — the [`deepest-tag`](../../src/boolean/operands/tag.nix) operand** matches `faceted-match` against `sundry.attrs.merge.override tag-list` instead of `concat`: since `tag-list` is root→leaf, override keeps each key's value from the **deepest level that declares it** (deeper overrides shallower). `tag` and `deepest-tag` share one `match-base` differing only in the merge function. Use it when a shallower level should *lose* to a deeper one rather than union with it — e.g. co-location tags where `desktop{modules:user}/hyprland{modules:system}/x.nix` must resolve `modules` to `system` alone, not `["user" "system"]` (a union would double-import into both the system and Home-Manager module sets).

The two operands agree on **presence** and differ only in **value**: a key present on *any* level is present in both the concat and the override set, so `deepest-tag { k = []; }` ≡ `tag { k = []; }`. Keep presence queries (`{ k = []; }`) on `tag`, and route value discrimination through `deepest-tag`.

`select-by-tag` takes an `expr-fn` over [boolean.expr](../../src/boolean/expr.nix) operands, so disjunction and negation are just `||` and `!`:

```nix
select-by-tag (e: with e; tag { hosts = host.name; } || !(tag { hosts = []; })) dir   # this host OR untagged
```

The same `expr-fn` is the `matches` axis of the ternary [filter-within-tag](../../src/vfs/dir/filter.nix) / `walk-within-tag` / `reform-within-tag`, which restrict a transform to the tag-matched branches and leave the rest in place.

**Position — [get-tag-pos.nix](../../src/vfs/file/get-tag-pos.nix)** is `findFirst` per level: it binds each level as a singleton `tag-list` (`[level]`, whose merge is the level itself) and returns the index of the **first level** whose tag-set matches the expr, or `-1`. It is positional, so its match is per-level by definition.

## Worked example

File `tag-list = [ { a = "1"; } { b = ["1" "2"]; } ]`, merged `{ a = "1"; b = ["1" "2"]; }`:

| query | result |
|---|---|
| `select-by-tag (e: e.tag { b = "2"; })` | kept — `b` present, `["1" "2"] ∩ ["2"] ≠ ∅` |
| `select-by-tag (e: !(e.tag { a = []; }))` | dropped — `a` present in the merged set (universal absence) |
| `select-by-tag (e: !(e.tag { c = []; }))` | kept — `c` on no level |
| `select-by-tag (e: with e; tag { a = "9"; } || !(tag { c = []; }))` | kept — the second term holds (disjunction) |
| `get-tag-pos (e: e.tag { b = "1"; })` | `1` — first level with a matching `b` |
