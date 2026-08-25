# Attrset merge

`sundry.attrs.merge-with` merges a list of attrsets one level at a time. Attributes present in only one input pass through unchanged. Values under the same key are folded from left to right with a callback:

```text
path -> lhs -> rhs -> collision result
```

At the primitive level, `path` is the singleton list containing the collided key. Recursive resolvers accumulate those lists into the complete path. A collision under `{ A."B.C" = ...; }` therefore has the path `["A" "B.C"]`, not the ambiguous string `"A.B.C"`. Paths are formatted as strings only at diagnostic boundaries.

## Resolver composition

A base resolver terminates the chain: it returns the collision result or throws, but never delegates.

```text
path -> lhs -> rhs -> collision result
```

The base resolvers are `override`, `concat`, `no-conflict`, and `no-collision`.

A conditional resolver either handles a collision or delegates it to the remaining resolver chain:

```text
resolve-next -> path -> lhs -> rhs -> collision result
```

The conditional resolvers are `concat-lists`, `recursive`, and `directories`. `sundry.attrs.merge-with-resolvers` composes a non-empty list from left to right: the first conditional resolver gets the first chance to handle a collision, and a base resolver terminates the chain.

| resolver | handles |
|---|---|
| `override` | every collision; keeps `rhs` |
| `concat` | every collision; concatenates `lib.toList lhs` and `lib.toList rhs` |
| `no-conflict` | equal values; throws when they differ |
| `no-collision` | none; always throws |
| `concat-lists` | two lists; otherwise delegates |
| `recursive` | two attrsets; otherwise delegates |
| `directories` | classifies VFS node pairs; delegates leaf/leaf, recurses directory/directory, and throws for mixed or invalid pairs |

[`merge-fns.nix`](../src/attrs/merge-fns.nix) exposes permutations of conditional resolvers followed by a base resolver under `sundry.attrs.merge`. For example:

```nix
sundry.attrs.merge.recursive.override
sundry.attrs.merge.directories.no-conflict
sundry.attrs.merge.concat-lists.recursive.no-collision
```

Every conditional resolver exported under `sundry.attrs.merge-resolvers` participates automatically in all ordered subsets generated under `sundry.attrs.merge.*`. Its attribute name becomes the corresponding path segment in that generated API.

## Recursive resolvers

`recursive` descends whenever both collided values are attrsets. Every nested `merge-with` appends the next singleton path to the accumulated path.

`directories` applies the VFS node contract from [data-model.md](data-model.md) to each collided pair:

| collision | result |
|---|---|
| leaf / leaf | delegate the complete leaf nodes to `resolve-next` |
| directory / directory | recursively merge their children |
| leaf / directory | throw a structural collision error |
| invalid node / any node | throw the `is-leaf-node` validation error |

Resolvers run only for collisions. A unique branch passes through unchanged, so `directories` validates only nodes relevant to the merge rather than validating both complete input trees.

Delegation gives the remaining resolver chain control over leaf collisions. A chain containing `directories.recursive` may deliberately re-enter leaf attrsets after `directories` delegates them.
