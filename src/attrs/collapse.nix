{
  lib,
  sundry,
  ...
}: rec {
  collapse-until = halt: fn: set: let
    recurse = path: attrs:
      lib.pipe attrs [
        (lib.mapAttrsToList (name: value: let
          path' = path ++ [name];
        in
          # -- keep this condition aligned with 'attrs.walk-matched-until'
          if !(halt path' value) && lib.isAttrs value
          then recurse path' value
          else [(fn path' value)]))
        lib.concatLists
      ];
  in
    recurse [] set;
  collapse = collapse-until (path: value: false);

  tests = let
    attrs = {
      A = 0;
      B = 1;
      C = {D = 2;};
      E = {F = {G = 0;};};
    };
  in [
    [
      (collapse-until
        (path: value: lib.length path > 1)
        (path: value: path)
        attrs)
      [
        ["A"]
        ["B"]
        ["C" "D"]
        ["E" "F"]
      ]
    ]
    [
      (collapse
        (path: value: path)
        attrs)
      [
        ["A"]
        ["B"]
        ["C" "D"]
        ["E" "F" "G"]
      ]
    ]
    [
      # -- exists to validate that 'halt' is called for non-attrset terminal values
      (sundry.does-throw (collapse-until
        (path: value:
          if lib.isAttrs value
          then false
          else throw "halt called for a scalar at '${lib.concatStringsSep "." path}'")
        (path: value: value)
        {A = 0;}))
      true
    ]
  ];
}
