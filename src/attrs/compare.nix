{
  lib,
  sundry,
  ...
}: let
  compare-base = halt: val: ref:
    sundry.attrs.merge-with-resolvers (with sundry.attrs.merge-resolvers; [
      (resolve-next: path: val: ref:
        if path == ["missing"]
        then sundry.attrs.remove-by-path ref val
        else resolve-next path val ref)
      recursive
      base.no-collision
    ])
    (
      [
        {
          missing = ref;
          matched = {};
          extra = {};
        }
      ]
      ++ (lib.mapAttrsToListRecursiveCond
        # -- only recurse when ref also has an attrset here
        # - otherwise treat val subtree as a leaf
        (path: _: let
          ref-value = lib.getAttrFromPath path ref;
        in
          lib.hasAttrByPath path ref
          && lib.isAttrs ref-value
          && !(halt ref-value))
        (path: value:
          if lib.hasAttrByPath path ref
          then {
            matched = lib.setAttrByPath path [value (lib.getAttrFromPath path ref)];
            missing = path;
          }
          else {extra = lib.setAttrByPath path value;})
        val)
    );
in rec {
  compare = compare-base (_: false);
  compare-until = compare-base;

  tests = [
    [
      (compare {
          A = "A";
          B = {C = {D = "B.C.D";};};
          E = "E";
        } {
          A = "A";
          B = {C = "B.C";};
          D = "D";
        })
      {
        extra = {
          E = "E";
        };
        matched = {
          B = {C = [{D = "B.C.D";} "B.C"];};
          A = ["A" "A"];
        };
        missing = {
          D = "D";
        };
      }
    ]
    [
      (compare {
          A = 1;
          B = 2;
        } {
          A = 1;
          B = 2;
        })
      {
        extra = {};
        matched = {
          A = [1 1];
          B = [2 2];
        };
        missing = {};
      }
    ]
    [
      (compare {A = 1;} {B = 2;})
      {
        extra = {A = 1;};
        matched = {};
        missing = {B = 2;};
      }
    ]
    [
      (compare {} {})
      {
        extra = {};
        matched = {};
        missing = {};
      }
    ]
    [
      (compare-until
        (ref-value: ref-value ? stop)
        {
          A.B = 1;
          C.D = 2;
        }
        {
          A.B = 3;
          C = {
            stop = true;
            D = 4;
          };
        })
      {
        extra = {};
        matched = {
          A.B = [1 3];
          C = [
            {D = 2;}
            {
              stop = true;
              D = 4;
            }
          ];
        };
        missing = {};
      }
    ]
  ];
}
