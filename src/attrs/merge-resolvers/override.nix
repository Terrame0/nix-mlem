{sundry, ...}: rec {
  base.override = path: lhs: rhs: rhs;
  tests = [
    [(base.override ["_"] {A = 1;} {A = 2;}) {A = 2;}]
    [
      (sundry.attrs.merge.override [{A = 1;} {B = 2;}])
      {
        A = 1;
        B = 2;
      }
    ]
  ];
}
