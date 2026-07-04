# Test data naming convention

A character-class scheme for test data — fixture paths, inline attrsets, string literals — so the reader can tell at a glance which letter plays which role.

## Roles

| Role | Symbols | Example |
|---|---|---|
| Labels / file names / identifiers | uppercase letters from `A` | file `A.txt`, attrset key `A`, content placeholder `"ABC"` |
| Structural separator (directory step) | `=` | nested directories: `=/=/E.ini` |
| Annotation keys | lowercase letters from `a` | tag key `{a:1}` |
| Annotation values | digits from `1` | tag value `{a:1}` |
| Semantic words (carry domain meaning) | unchanged | `"first"`, `"second"`, `name`, `deps` |
| Numbers, literals outside the scheme | unchanged | `[1 2 3]`, `"/"`, `"["` |

Lambda parameters (`acc`, `i`, `x` in [src/for.nix](../../src/for.nix), [src/while.nix](../../src/while.nix)) are not test data — they describe a role inside the function — so they stay lowercase.

## VFS fixtures

The on-disk fixture at [tests/vfs-test-dir/tags/](../../tests/vfs-test-dir/tags/) is the canonical example:

```
A{a:1}
B{a:2,3}
C{a:1}{b:1}
D{a}{b:}
E
={a:1}/F{a:2}
={a:1}/={b:1}/G{b:2}
={a:1}/={b:1}/={c:1}/H{c:2}
={b:1}/I{c:1}
```

Reading any path is mechanical: uppercase = file, `=` = directory step, lowercase-colon-digit = tag annotation.

File extensions (`.txt`, `.ini`, `.scss`) are allowed when a test needs to distinguish them — see [tests/vfs-test-dir/filtering/](../../tests/vfs-test-dir/filtering/), where the filter predicate keys off `.txt` vs `.ini`. File contents are out of scope: usually `contents of <NAME>`, but tests that match against a specific value (e.g. `override` in `=/=/E.ini`) deviate freely.

### Sort-order caveat

`=` has ASCII codepoint 61; uppercase letters start at 65. Nix sorts attribute names lexicographically, so in a `collapse` traversal, `=`-prefixed (directory) entries are visited **before** any sibling file. Assertions about traversal order must account for this.

## Inline tests

In `tests = [...]` blocks across `src/`, the same scheme applies to attrset keys and string-content placeholders. [src/attrs/compare.nix](../../src/attrs/compare.nix) is the representative example: both keys (`A`, `B`, `C`) and string values (`"A"`, `"B.C.D"`) follow the convention together. Multi-letter groups separated by `.` or `-` are uppercased per letter — `"B.C.D"`, `A-M`.
