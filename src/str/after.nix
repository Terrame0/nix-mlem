{lib, ...}: rec {
  after = sep: string:
    lib.concatStringsSep sep (lib.tail (lib.splitString sep string));

  tests = [
    [(after "." "A.B") "B"]
    [(after "." "A.B.C") "B.C"]
    [(after "." "A") ""]
  ];
}
