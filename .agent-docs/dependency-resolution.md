# Dependency resolution

The dependency helpers separate graph ordering from value computation: `list.topo-stratify` produces executable layers, and `attrs.resolve-deps` assembles named transform results from those layers.

## Topological layers

[`sundry.list.topo-stratify`](../src/list/topo-stratify.nix) accepts entries with `name` and optional `deps`:

```nix
[
  { name = "A"; }
  { name = "B"; deps = ["A"]; }
  { name = "C"; deps = ["A"]; }
]
# => [[A] [B C]]
```

Each output layer contains every remaining entry whose dependencies occur in earlier layers. Input order is preserved within a layer. An empty input produces `[]`.

A dependency name that never appears and a dependency cycle have the same outcome: no next layer can be formed, so the function throws `unresolvable dependencies` and lists the entries left unresolved. Recursive list concatenation resolves the complete graph structure before even an early layer is observable, so an unresolved tail is not hidden by a valid first layer.

## Named transforms

[`sundry.attrs.resolve-deps`](../src/attrs/resolve-deps.nix) accepts an attrset whose keys are stage names:

```nix
{
  first.transform = _: 1;
  second = {
    deps = ["first"];
    transform = previous: previous.first + 1;
  };
}
```

Each stage has the strict schema:

| field | contract |
|---|---|
| `deps` | optional list of stage-name strings; defaults to `[]` |
| `transform` | required function |

No other stage fields are accepted. Stage keys enter `topo-stratify` in lexicographic order, so ready stages retain that order within a layer.

A transform receives an attrset containing **only** the results named in its own `deps`, all from earlier layers, not the complete accumulated result. Stages in one layer do not receive one another in that argument. After each layer, their outputs are added under the stage names; the final result maps every name to its transform result. Empty input produces `{}`.

`resolve-deps` consumes the complete layer structure, so demanding its result detects unresolved graph tails. Transform bodies and their result values remain lazy: a result attribute or a downstream transform forces only the dependency values it actually consumes.
