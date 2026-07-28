{
  lib,
  sundry,
  ...
}: let
  validate-leaf = sundry.attrs.validate {
    path = {
      check = value:
        lib.isList value
        && (lib.all (x: lib.isString x) value);
      desc = "must be a list of strings";
    };
    value = {};
    omit = {
      default = false;
      check = value: lib.isBool value;
      desc = "must be either 'true' or 'false'";
    };
  };
in rec {
  reform-matched-until = matches: halt: fn: attrs:
    lib.pipe attrs [
      (sundry.attrs.collapse-until
        halt
        (path: value: let
          result = validate-leaf (fn path value);
        in
          if matches path value
          then
            if result.omit
            then {}
            else lib.setAttrByPath result.path result.value
          else lib.setAttrByPath path value))
      sundry.attrs.merge.recursive.no-collision
    ];

  reform-until = reform-matched-until (path: value: true);
  reform = reform-until (path: value: false);
  tests = let
    attrs = {
      A = 0;
      B = 1;
      C = {D = 2;};
      E = {F = {G = 0;};};
    };
  in [
    [
      (reform-matched-until
        (path: value: value != 0)
        (path: value: lib.length path > 1)
        (path: value: {
          path = [(sundry.str.join-with "." path)];
          value = "x";
        })
        attrs)
      {
        A = 0;
        B = "x";
        "C.D" = "x";
        "E.F" = "x";
      }
    ]
    [
      (reform-matched-until
        (path: value: value != 0)
        (path: value: false)
        (path: value:
          if value == 1
          then {inherit path value;} // {omit = true;}
          else {inherit path value;})
        attrs)
      {
        A = 0;
        C = {D = 2;};
        E = {F = {G = 0;};};
      }
    ]
    [
      (reform-matched-until
        (path: value: value != 0)
        (path: value: false)
        (path: value:
          if value == 0
          then throw "fn called on non-matched leaf"
          else {inherit path value;})
        attrs)
      attrs
    ]
    [
      (reform-until
        (path: value: lib.length path > 1)
        (path: value: {
          path = [(sundry.str.join-with "." path)];
          value = "x";
        })
        attrs)
      {
        A = "x";
        B = "x";
        "C.D" = "x";
        "E.F" = "x";
      }
    ]
    [
      (reform
        (path: value: {
          path = [(sundry.str.join-with "." path)];
          value = "x";
        })
        attrs)
      {
        A = "x";
        B = "x";
        "C.D" = "x";
        "E.F.G" = "x";
      }
    ]
  ];
}
