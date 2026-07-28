{
  sundry,
  lib,
  ...
}: rec {
  before = sep: string:
    lib.head (sundry.str.split sep string);

  tests = [
    [(before "." "A.B") "A"]
    [(before "." "AB.C") "AB"]
    [(before "." "A") "A"]
  ];
}
