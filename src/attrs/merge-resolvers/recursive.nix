{
  lib,
  sundry,
  ...
}: rec {
  recursive = resolve-next: path: acc-value: value:
    if lib.isAttrs acc-value && lib.isAttrs value
    then sundry.attrs.merge-with (next-path: recursive resolve-next (path ++ next-path)) [acc-value value]
    else resolve-next path acc-value value;
  tests = [
    [
      (sundry.attrs.merge.recursive.override [{A = {B = 1;};} {A = {B = 2;};}])
      {A = {B = 2;};}
    ]
    [
      (sundry.attrs.merge.recursive.override [{A = {B = 1;};} {A = {C = 2;};}])
      {
        A = {
          B = 1;
          C = 2;
        };
      }
    ]
  ];
}
