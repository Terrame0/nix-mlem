{lib, ...}: rec {
  before = sep: string:
    lib.head (lib.splitString sep string);

  tests = [
    [(before "." "A.B") "A"]
    [(before "." "AB.C") "AB"]
    [(before "." "A") "A"]
  ];
}
