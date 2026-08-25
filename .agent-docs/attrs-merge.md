# Attrset merge

`sundry.attrs.merge-with` merges a list of attrsets. Attributes present in only one input pass through unchanged. When the same path occurs in multiple inputs, values are resolved from left to right with a callback:

```nix
path: lhs: rhs: result
```

`path` is a list of exact attribute-name segments. A collision under `{ A."B.C" = ...; }` has the path `["A" "B.C"]`, not the ambiguous string `"A.B.C"`. Paths are formatted as strings only at diagnostic boundaries.

## Resolver composition

A base resolver always produces the collision result:

```nix
path: lhs: rhs: result
```

The base resolvers are `override`, `concat`, `no-conflict`, and `no-collision`.

A conditional resolver either handles a collision or delegates it to the remaining resolver chain:

```nix
resolve-next: path: lhs: rhs: result
```

The conditional resolvers are `concat-lists`, `recursive`, and `directories`. `sundry.attrs.merge-with-resolvers` composes the list so each conditional resolver receives the rest of the chain as `resolve-next`.

[`merge-fns.nix`](../src/attrs/merge-fns.nix) exposes permutations of conditional resolvers followed by a base resolver under `sundry.attrs.merge`. For example:

```nix
sundry.attrs.merge.recursive.override
sundry.attrs.merge.directories.no-conflict
sundry.attrs.merge.concat-lists.recursive.no-collision
```

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
