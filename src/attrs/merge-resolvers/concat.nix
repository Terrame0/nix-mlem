{
  sundry,
  lib,
  ...
}: {
  base.concat = path: lhs: rhs:
    lib.toList lhs ++ lib.toList rhs;
  tests = [
    [
      (sundry.attrs.merge.concat [{A = [1 2];} {A = 3;}])
      {A = [1 2 3];}
    ]
    [
      (sundry.attrs.merge.concat [{A = 1;} {B = 2;}])
      {
        A = 1;
        B = 2;
      }
    ]
  ];
}
