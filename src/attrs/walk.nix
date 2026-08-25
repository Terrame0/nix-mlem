{lib, ...}: rec {
  walk-matched-until = matches: halt: fn: set: let
    recurse = path:
      lib.mapAttrs (
        name: value: let
          path' = path ++ [name];
        in
          # -- 'halt' may validate non-attrset values, so we need to evaluate it
          # - before the recursion type guard (lib.isAttrs)
          if !(halt path' value) && lib.isAttrs value
          then recurse path' value
          else if matches path' value
          then fn path' value
          else value
      );
  in
    recurse [] set;
  walk-until = walk-matched-until (path: value: true);
  walk-matched = lib.flip walk-matched-until (path: value: false);
  walk = walk-until (path: value: false);

  tests = let
    attrs = {
      A = 0;
      B = 1;
      C = {D = 2;};
      E = {F = {G = 0;};};
    };
  in [
    [
      (walk-matched-until
        (path: value: value != 0)
        (path: value: lib.length path > 1)
        (path: value: "x")
        attrs)
      {
        A = 0;
        B = "x";
        C = {D = "x";};
        E = {F = "x";};
      }
    ]
    [
      (walk-matched
        (path: value: value != 0)
        (path: value: "x")
        attrs)
      {
        A = 0;
        B = "x";
        C = {D = "x";};
        E = {F = {G = 0;};};
      }
    ]
    [
      (walk-until
        (path: value: lib.length path > 1)
        (path: value: "x")
        attrs)
      {
        A = "x";
        B = "x";
        C = {D = "x";};
        E = {F = "x";};
      }
    ]
    [
      (walk
        (path: value: "x")
        attrs)
      {
        A = "x";
        B = "x";
        C = {D = "x";};
        E = {F = {G = "x";};};
      }
    ]
  ];
}
