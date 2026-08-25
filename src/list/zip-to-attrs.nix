{
  sundry,
  lib,
  ...
}: rec {
  zip-to-attrs = names: values:
    lib.pipe values [
      (lib.zipListsWith
        (name: value: {${name} = value;})
        names)
      sundry.attrs.merge.no-collision
    ];

  tests = [
    [(zip-to-attrs [] []) {}]
    [(zip-to-attrs ["A" "B" "C"] [1 2 3]) ({A = 1;} // {B = 2;} // {C = 3;})]
    [(zip-to-attrs ["A" "B" "C"] [1 2]) ({A = 1;} // {B = 2;})]
    [(sundry.does-throw (zip-to-attrs ["A" "A"] [1 2])) true]
  ];
}
