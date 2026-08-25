{sundry, ...}: rec {
  base.no-collision = path: lhs: rhs:
    throw "\nthere is a collision in attrset merge at '${sundry.str.join-with "." path}'";
  tests = [
    [(sundry.does-throw (base.no-collision ["_"] {A = 1;} {A = 1;})) true]
    [
      (sundry.attrs.merge.no-collision [{A = 1;} {B = 2;}])
      {
        A = 1;
        B = 2;
      }
    ]
  ];
}
