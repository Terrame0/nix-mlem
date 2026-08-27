# Attrset comparison and validation

`sundry.attrs.compare` is the asymmetric structural primitive used by tag matching and `sundry.attrs.validate`. Validation adds a template DSL for required fields, defaults, nullability, and value predicates.

## `compare` is asymmetric

```nix
sundry.attrs.compare val ref
# => { matched = ...; missing = ...; extra = ...; }
```

| result field | contains |
|---|---|
| `matched` | paths present on both sides, with each terminal value stored as `[val-value ref-value]` |
| `missing` | paths present only in `ref`, retaining `ref` values |
| `extra` | paths present only in `val`, retaining `val` values |

`matched` means common presence, not value equality. Comparison is driven by `val`, while `ref` supplies the expected shape. At a `val` path, recursion continues only when the corresponding `ref` value exists, is an attrset, and satisfies the recursion predicate. Otherwise the complete `val` subtree is treated as one terminal value.

```nix
sundry.attrs.compare { A.B = 1; C = 2; } { A = 0; D = 3; }
# matched.A = [{ B = 1; } 0]
# extra.C = 2
# missing.D = 3
```

`compare` recurses through every attrset shared by `val` and `ref`. `compare-until halt` exposes an early-stop predicate: when `halt ref-value` is true, the complete `val` subtree and corresponding `ref` subtree are treated as one terminal pair.

## Validation attribute specs

[`sundry.attrs.validate`](../src/attrs/validate.nix) takes a template first and a value attrset second:

```nix
sundry.attrs.validate {
  name = {};
  count = {
    default = _: 1;
    check = lib.isInt;
    desc = "must be an integer";
  };
  note = {
    default = _: null;
    nullable = true;
  };
} attrs
```

A terminal attribute spec is either `{}` or an attrset containing `check` or `default`. Any other non-empty attrset is a nested template branch. A spec may contain only these fields:

| field | contract |
|---|---|
| `default` | function from the final result attrset to a fallback value; makes the input field optional, and the result goes through the same check as input |
| `check` | value predicate; when called, its result is asserted to be a boolean |
| `desc` | required when `check` is about to run; used in the failure message |
| `nullable` | when true, `null` passes before `desc` is required or `check` is called |

An empty spec `{}` therefore means “required, any value”. A field without `default` is required. A spec containing only `desc` or `nullable` is interpreted as a template branch and is invalid once its scalar fields are examined.

`check` and `default` are structural markers, not ordinary nested field names: an attrset containing either is classified as one attribute spec and cannot simultaneously describe child template fields.

Defaults form a lazy fixed point over the completed result. Each default function receives that result as its argument, so it can refer to supplied fields and to other defaults regardless of their template position. The function is called only when its field is absent from the input. Cyclic default dependencies fail when the cycle is forced.

Template validation restricts spec field names but does not eagerly validate the types of `check`, `desc`, or `nullable`. Those contracts are enforced only along the value path that uses them. In particular, an unused default function remains lazy, and a nullable `null` can bypass a missing `desc` and the associated `check`.

Validation rejects input paths absent from the template and required template paths absent from the input. On success it returns the input shape completed with defaults. A `check` result of a non-boolean type fails an assertion.

The same DSL validates stage definitions in [dependency-resolution.md](dependency-resolution.md) and callback results from [`attrs.reform`](attrs-traversal.md#families).
