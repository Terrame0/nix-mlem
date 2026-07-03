{
  sundry,
  lib,
  ...
}: rec {
  apply-between = fn: lsep: rsep: str: let
    insides =
      lib.filter
      (entry: entry.depth == 1)
      (sundry.str.delimit lsep rsep str).inside;
    result =
      sundry.for
      [0 (i: i + 1) (i: i < (lib.length insides))]
      {
        inherit str;
        offset = 0;
      }
      (prev: i: let
        entry = sundry.list.at i insides;
        span = sundry.str.len lsep + sundry.str.len entry.substr + sundry.str.len rsep;
        replacement = fn entry.substr;
      in {
        str =
          sundry.str.replace-at
          (entry.pos - sundry.str.len lsep + prev.offset)
          span
          replacement
          prev.str;
        offset = prev.offset + sundry.str.len replacement - span;
      });
  in
    result.str;

  tests = [
    [
      (apply-between lib.id "[" "]" "A[X]B[Y]C[Z]D")
      "AXBYCZD"
    ]
    [
      (apply-between (str: "-") "[" "]" "[[][]][]")
      "--"
    ]
    [(apply-between (str: "X") "[" "]" "ABC") "ABC"]
  ];
}
