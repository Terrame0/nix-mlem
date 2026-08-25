{
  sundry,
  lib,
  ...
}: {
  concat-lists = resolve-next: path: lhs: rhs:
    if lib.isList lhs && lib.isList rhs
    then lhs ++ rhs
    else resolve-next path lhs rhs;
  tests = [
    [
      (sundry.attrs.merge.concat-lists.override [{A = [1 2];} {A = [3];}])
      {A = [1 2 3];}
    ]
    [
      (sundry.attrs.merge.concat-lists.override [{A = [1];} {B = [2];}])
      {
        A = [1];
        B = [2];
      }
    ]
  ];
}
