{
  sundry,
  lib,
  ...
}: rec {
  after = sep: string:
    sundry.str.join-with sep (lib.tail (sundry.str.split sep string));

  tests = [
    [(after "." "A.B") "B"]
    [(after "." "A.B.C") "B.C"]
    [(after "." "A") ""]
  ];
}
