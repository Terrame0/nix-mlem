{
  lib,
  sundry,
  ...
}: rec {
  resolve-deps = transforms: let
    layers = lib.pipe transforms [
      (lib.mapAttrsToList (name: value': let
        value =
          sundry.attrs.validate {
            deps = {
              default = _: [];
              check = value: lib.isList value && lib.all lib.isString value;
              desc = "must be a list of strings that represent the stage's dependencies";
            };
            transform = {
              check = value: lib.isFunction value;
              desc = "must be a transformation function";
            };
          }
          value';
      in {
        inherit name;
        inherit (value) deps;
        inherit (value) transform;
      }))
      sundry.list.topo-stratify
    ];
  in
    lib.foldl (
      acc: layer:
        acc
        // lib.pipe layer [
          (map (entry: {
            ${entry.name} =
              entry.transform
              (lib.pipe entry.deps [
                (map (dep: {
                  name = dep;
                  value = acc.${dep};
                }))
                lib.listToAttrs
              ]);
          }))
          sundry.attrs.merge.no-collision
        ]
    ) {}
    layers;
  tests = [
    [
      (resolve-deps {
        first = {
          transform = _: 1;
        };
        second = {
          deps = ["first"];
          transform = prev: prev.first + 1;
        };
        third = {
          deps = ["first"];
          transform = prev: prev.first + 2;
        };
        fourth = {
          deps = ["second" "third"];
          transform = prev: prev.second + prev.third;
        };
      })
      {
        first = 1;
        second = 2;
        third = 3;
        fourth = 5;
      }
    ]
    [(resolve-deps {}) {}]
    [
      (sundry.does-throw (resolve-deps {
        A = {
          deps = ["B"];
          transform = _: 1;
        };
        B = {
          deps = ["A"];
          transform = _: 1;
        };
      }))
      true
    ]
  ];
}
